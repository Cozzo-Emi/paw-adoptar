"""
PAW — Auth Router
Endpoints para registro, login y refresh de tokens.
"""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.schemas import RefreshTokenRequest, Token, TokenPayload
from app.config import get_settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    get_password_hash,
    verify_password,
)
from app.database import get_db
from app.main import get_rate_limit, limiter
from app.users.models import User
from app.users.schemas import UserCreate, UserRead

router = APIRouter(prefix="/auth", tags=["Auth"])
settings = get_settings()


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
@limiter.limit(get_rate_limit("5/minute"))
async def register_user(user_in: UserCreate, request: Request, db: AsyncSession = Depends(get_db)):
    """
    Registra un nuevo usuario en la plataforma.
    Valida que el email no esté ya registrado.
    """
    # Check if email exists
    stmt = select(User).where(User.email == user_in.email)
    result = await db.execute(stmt)
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this email already exists in the system.",
        )

    # Check if phone exists (if provided)
    if user_in.phone:
        stmt = select(User).where(User.phone == user_in.phone)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The user with this phone already exists in the system.",
            )

    # Create new user
    db_user = User(
        email=user_in.email,
        phone=user_in.phone,
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name,
        avatar_url=user_in.avatar_url,
        role=user_in.role,
        city=user_in.city,
        province=user_in.province,
    )
    
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    return db_user


@router.post("/login", response_model=Token)
@limiter.limit(get_rate_limit("10/minute"))
async def login_access_token(
    request: Request,
    db: AsyncSession = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    OAuth2 compatible token login, requiere username (email) y password en form-data.
    Devuelve access_token y refresh_token.
    """
    stmt = select(User).where(User.email == form_data.username)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password"
        )
    elif not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user"
        )

    return {
        "access_token": create_access_token(user.id),
        "refresh_token": create_refresh_token(user.id),
        "token_type": "bearer",
    }


@router.post("/refresh", response_model=Token)
@limiter.limit(get_rate_limit("10/minute"))
async def refresh_access_token(
    body: RefreshTokenRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Renueva el par de tokens usando un refresh token válido.
    El refresh token debe tener claim type='refresh' (sin eso, se rechaza).
    """
    try:
        payload = jwt.decode(
            body.refresh_token, settings.secret_key, algorithms=[settings.algorithm]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token.",
        )

    if token_data.type != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is not a refresh token.",
        )

    stmt = select(User).where(User.id == token_data.sub)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive.",
        )

    return {
        "access_token": create_access_token(user.id),
        "refresh_token": create_refresh_token(user.id),
        "token_type": "bearer",
    }


@router.post("/send-verification", response_model=dict)
async def send_verification(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Genera un código OTP de 6 dígitos para verificar el email."""
    import random

    if current_user.is_verified_email:
        return {"status": "already_verified", "detail": "Email already verified."}

    token = f"{random.randint(100000, 999999)}"
    current_user.email_verification_token = token
    db.add(current_user)
    await db.commit()

    return {"status": "sent", "token": token, "detail": "Verification code sent."}


@router.post("/verify-email", response_model=dict)
async def verify_email(
    token: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Verifica el email con el código recibido por /send-verification."""
    if current_user.is_verified_email:
        return {"status": "already_verified", "detail": "Email already verified."}

    if not current_user.email_verification_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No verification code requested.",
        )

    if current_user.email_verification_token != token.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification code.",
        )

    current_user.is_verified_email = True
    current_user.verification_level = 1
    current_user.email_verification_token = None
    db.add(current_user)
    await db.commit()

    return {"status": "verified", "detail": "Email verified successfully."}
