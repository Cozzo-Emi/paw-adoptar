"""
PAW — Auth Dependencies
Funciones inyectables para FastAPI que verifican el JWT y extraen el usuario actual.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.schemas import TokenPayload
from app.config import get_settings
from app.database import get_db
from app.users.models import User

settings = get_settings()

# Define el endpoint donde los clientes van a pedir el token
reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl="/auth/login",
    scheme_name="JWT"
)


async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: str = Depends(reusable_oauth2)
) -> User:
    """
    Decodifica el JWT, busca el usuario en BD y lo retorna.
    Lanza HTTP 401 si algo falla.
    """
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    stmt = select(User).where(User.id == token_data.sub)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
        
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
        
    return user


async def get_current_active_moderator(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency para endpoints exclusivos de moderadores o admins."""
    if current_user.role.value not in ["moderator", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user doesn't have enough privileges"
        )
    return current_user
