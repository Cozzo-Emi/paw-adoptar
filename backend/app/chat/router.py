"""
PAW — Chat Router
Maneja las salas de chat y la conexión WebSocket P2P.
"""

from typing import List
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    WebSocket,
    WebSocketDisconnect,
    status,
)
import asyncio
from jose import JWTError, jwt
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.schemas import TokenPayload
from app.core.firebase import notify_new_message
from app.chat.models import Chat, Message
from app.chat.schemas import ChatRead, MessageRead
from app.chat.websockets import manager
from app.config import get_settings
from app.database import get_db, async_session
from app.auth.dependencies import get_current_user
from app.matching.models import Match, MatchStatus
from app.users.models import User

router = APIRouter(prefix="/chats", tags=["Chat"])
settings = get_settings()


async def get_user_from_token(token: str, db: AsyncSession) -> User:
    """Extrae el usuario a partir del token para la conexión WebSocket."""
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValueError):
        return None

    stmt = select(User).where(User.id == token_data.sub)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


@router.post("", response_model=ChatRead, status_code=status.HTTP_201_CREATED)
async def create_chat(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Inicia una sala de chat a partir de un Match aceptado.
    """
    # Verificar que el match existe y está aceptado
    stmt = select(Match).where(Match.id == match_id)
    result = await db.execute(stmt)
    match = result.scalar_one_or_none()

    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Match not found"
        )
    if match.status != MatchStatus.ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only start a chat for an accepted match.",
        )

    # Validar permisos
    if current_user.id not in [match.adopter_id, match.donor_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not part of this match.",
        )

    # Verificar si el chat ya existe
    chat_stmt = select(Chat).where(Chat.match_id == match_id)
    chat_result = await db.execute(chat_stmt)
    existing_chat = chat_result.scalar_one_or_none()

    if existing_chat:
        return existing_chat

    # Crear chat
    new_chat = Chat(
        match_id=match_id,
        adopter_id=match.adopter_id,
        donor_id=match.donor_id,
        is_active=True,
    )
    db.add(new_chat)
    await db.commit()
    await db.refresh(new_chat)

    return new_chat


@router.get("", response_model=List[ChatRead])
async def list_chats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista todos los chats activos del usuario.
    """
    stmt = (
        select(Chat)
        .where(
            and_(
                Chat.is_active == True,
                or_(
                    Chat.adopter_id == current_user.id, Chat.donor_id == current_user.id
                ),
            )
        )
        .order_by(Chat.created_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{chat_id}/messages", response_model=List[MessageRead])
async def get_chat_history(
    chat_id: UUID,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Obtiene el historial de mensajes de un chat específico.
    """
    # Verificar acceso al chat
    chat_stmt = select(Chat).where(Chat.id == chat_id)
    chat_result = await db.execute(chat_stmt)
    chat = chat_result.scalar_one_or_none()

    if not chat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Chat not found"
        )
    if current_user.id not in [chat.adopter_id, chat.donor_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Access denied to this chat"
        )

    # Obtener mensajes ordenados cronológicamente inverso
    msg_stmt = (
        select(Message)
        .where(Message.chat_id == chat_id)
        .order_by(Message.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    msg_result = await db.execute(msg_stmt)
    return msg_result.scalars().all()


@router.websocket("/{chat_id}/ws")
async def websocket_endpoint(websocket: WebSocket, chat_id: UUID, token: str):
    """
    Endpoint WebSocket para mensajería P2P en tiempo real.
    """
    # Como los websockets no pueden usar Depends() fácilmente para DB asíncrona,
    # abrimos una sesión manual para validar el token y el acceso.
    async with async_session() as db:
        user = await get_user_from_token(token, db)
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        chat_stmt = select(Chat).where(Chat.id == chat_id)
        chat_result = await db.execute(chat_stmt)
        chat = chat_result.scalar_one_or_none()

        if not chat or user.id not in [chat.adopter_id, chat.donor_id]:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Aceptar la conexión
        await manager.connect(websocket, chat_id)

        try:
            while True:
                # Esperar texto del cliente
                data = await websocket.receive_text()

                # Guardar el mensaje en la BD
                new_msg = Message(
                    chat_id=chat_id,
                    sender_id=user.id,
                    content=data,
                    is_read=False,
                )
                db.add(new_msg)
                await db.commit()
                await db.refresh(new_msg)

                # Broadcast a ambos clientes en el chat
                await manager.broadcast_to_chat(
                    {
                        "id": str(new_msg.id),
                        "chat_id": str(chat_id),
                        "sender_id": str(user.id),
                        "content": new_msg.content,
                        "created_at": new_msg.created_at.isoformat(),
                    },
                    chat_id,
                )

                # Fetch recipient to get FCM token
                recipient_id = (
                    chat.donor_id if user.id == chat.adopter_id else chat.adopter_id
                )
                recipient_stmt = select(User).where(User.id == recipient_id)
                recipient_result = await db.execute(recipient_stmt)
                recipient = recipient_result.scalar_one_or_none()

                # If recipient is not connected to this chat via WS, send Push
                if recipient and recipient.fcm_token:
                    active_connections = manager.active_connections.get(chat_id, [])
                    # Very basic check: ideally we track which user is which socket
                    # For MVP, just send it asynchronously.
                    if len(active_connections) < 2:
                        asyncio.create_task(
                            asyncio.to_thread(
                                notify_new_message,
                                fcm_token=recipient.fcm_token,
                                sender_name=user.full_name,
                                chat_id=str(chat_id),
                            )
                        )

        except WebSocketDisconnect:
            manager.disconnect(websocket, chat_id)
