"""
PAW — Firebase Cloud Messaging (FCM) Integration
Maneja el envío de notificaciones push a los dispositivos móviles.
"""

import firebase_admin
from firebase_admin import credentials, messaging

from app.config import get_settings

settings = get_settings()

# Inicialización diferida del SDK de Firebase
# Asume que tenemos una variable de entorno FIREBASE_CREDENTIALS_JSON o
# un archivo local si es en desarrollo.
# Para el MVP, si no hay credenciales configuradas, solo modeamos el comportamiento.

_firebase_app = None

def init_firebase():
    global _firebase_app
    if not _firebase_app:
        try:
            # En producción se inicializa con el certificado
            # cred = credentials.Certificate("firebase-adminsdk.json")
            # _firebase_app = firebase_admin.initialize_app(cred)
            print("Firebase SDK mocked for development/testing.")
            _firebase_app = "mocked"
        except Exception as e:
            print(f"Error initializing Firebase: {e}")


def send_push_notification(token: str, title: str, body: str, data: dict = None) -> bool:
    """
    Envía una notificación push a un dispositivo específico.
    """
    if not token:
        return False
        
    init_firebase()
    
    if _firebase_app == "mocked":
        print(f"[FCM MOCK] Push to {token[:10]}... | Title: {title} | Body: {body}")
        return True

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending push notification: {e}")
        return False


# Helpers específicos para flujos de PAW

def notify_new_match(fcm_token: str, pet_name: str, adopter_name: str):
    """Notifica al donante que alguien quiere adoptar a su mascota."""
    send_push_notification(
        token=fcm_token,
        title="¡Nuevo interés en tu mascota! 🐾",
        body=f"{adopter_name} quiere adoptar a {pet_name}.",
        data={"type": "new_match"}
    )

def notify_match_accepted(fcm_token: str, pet_name: str):
    """Notifica al adoptante que el donante aceptó el match."""
    send_push_notification(
        token=fcm_token,
        title="¡Match aceptado! 🎉",
        body=f"El donante de {pet_name} aceptó tu solicitud. ¡Ya pueden chatear!",
        data={"type": "match_accepted"}
    )

def notify_new_message(fcm_token: str, sender_name: str, chat_id: str):
    """Notifica un nuevo mensaje de chat."""
    send_push_notification(
        token=fcm_token,
        title=f"Nuevo mensaje de {sender_name}",
        body="Toca para responder",
        data={"type": "new_message", "chat_id": str(chat_id)}
    )
