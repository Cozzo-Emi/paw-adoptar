"""
PAW — Firebase Cloud Messaging (FCM) Integration
Maneja el envío de notificaciones push a los dispositivos móviles.
"""

import firebase_admin
from firebase_admin import credentials, messaging

from app.config import get_settings

settings = get_settings()

_firebase_app = None


def init_firebase():
    global _firebase_app
    if _firebase_app:
        return

    cred_path = settings.firebase_credentials_path

    if cred_path and cred_path.strip():
        try:
            cred = credentials.Certificate(cred_path.strip())
            _firebase_app = firebase_admin.initialize_app(cred)
            print(f"Firebase SDK initialized from {cred_path}")
        except Exception as e:
            print(f"Error initializing Firebase: {e} — falling back to mock")
            _firebase_app = "mocked"
    else:
        print("Firebase SDK mocked for development/testing.")
        _firebase_app = "mocked"


def send_push_notification(
    token: str, title: str, body: str, data: dict = None
) -> bool:
    if not token:
        return False

    init_firebase()

    if _firebase_app == "mocked":
        print(f"[FCM MOCK] Push to {token[:10]}... | Title: {title} | Body: {body}")
        return True

    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending push notification: {e}")
        return False


def notify_new_match(fcm_token: str, pet_name: str, adopter_name: str):
    send_push_notification(
        token=fcm_token,
        title="¡Nuevo interés en tu mascota! 🐾",
        body=f"{adopter_name} quiere adoptar a {pet_name}.",
        data={"type": "new_match"},
    )


def notify_match_accepted(fcm_token: str, pet_name: str):
    send_push_notification(
        token=fcm_token,
        title="¡Match aceptado! 🎉",
        body=f"El donante de {pet_name} aceptó tu solicitud. ¡Ya pueden chatear!",
        data={"type": "match_accepted"},
    )


def notify_new_message(fcm_token: str, sender_name: str, chat_id: str):
    send_push_notification(
        token=fcm_token,
        title=f"Nuevo mensaje de {sender_name}",
        body="Toca para responder",
        data={"type": "new_message", "chat_id": str(chat_id)},
    )


def notify_post_adoption_reminder(fcm_token: str, pet_name: str, match_id: str):
    send_push_notification(
        token=fcm_token,
        title="¿Cómo está tu mascota? 🐾",
        body=f"Subí una foto de {pet_name} para confirmar su bienestar y sumar puntos.",
        data={"type": "post_adoption_reminder", "match_id": str(match_id)},
    )
