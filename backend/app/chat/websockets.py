"""
PAW — Chat Connection Manager
Maneja las conexiones WebSocket activas en memoria para mensajería en tiempo real.
"""

from typing import Dict, List
from uuid import UUID

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        # Diccionario que mapea: chat_id -> lista de WebSockets activos
        self.active_connections: Dict[UUID, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, chat_id: UUID):
        await websocket.accept()
        if chat_id not in self.active_connections:
            self.active_connections[chat_id] = []
        self.active_connections[chat_id].append(websocket)

    def disconnect(self, websocket: WebSocket, chat_id: UUID):
        if chat_id in self.active_connections:
            try:
                self.active_connections[chat_id].remove(websocket)
                if not self.active_connections[chat_id]:
                    del self.active_connections[chat_id]
            except ValueError:
                pass

    async def broadcast_to_chat(self, message_data: dict, chat_id: UUID):
        """
        Envía un mensaje a todos los usuarios conectados en un chat específico.
        """
        if chat_id in self.active_connections:
            for connection in self.active_connections[chat_id]:
                await connection.send_json(message_data)


# Instancia global del manager
manager = ConnectionManager()
