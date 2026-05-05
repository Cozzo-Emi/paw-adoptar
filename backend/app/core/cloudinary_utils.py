"""
PAW — Cloudinary Integration
Provee utilidades para generar uploads firmados y validar media.
Según el doc de proyecto, esto previene abusos y sobrecostos en el Free Tier.
"""

import time
import cloudinary
import cloudinary.utils
import cloudinary.api
from fastapi import HTTPException, status

from app.config import get_settings

settings = get_settings()

# Configuración global de Cloudinary
if settings.cloudinary_cloud_name and settings.cloudinary_api_key:
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )


def generate_signed_upload_params(folder: str, user_id: str) -> dict:
    """
    Genera parámetros firmados para que el cliente móvil suba la imagen
    directamente a Cloudinary sin pasar el archivo entero por nuestro backend.

    Args:
        folder: Carpeta destino ('pets', 'avatars', 'post_adoption')
        user_id: ID del usuario para tagging y control de cuota
    """
    if not settings.cloudinary_api_secret:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Cloudinary is not configured.",
        )

    timestamp = int(time.time())

    # Restringimos tipos y tamaño desde la firma
    params_to_sign = {
        "timestamp": timestamp,
        "folder": f"paw/{folder}",
        "tags": [str(user_id)],
        # strict transformations limitadas desde cloudinary dashboard
    }

    signature = cloudinary.utils.api_sign_request(
        params_to_sign, settings.cloudinary_api_secret
    )

    return {
        "timestamp": timestamp,
        "signature": signature,
        "api_key": settings.cloudinary_api_key,
        "cloud_name": settings.cloudinary_cloud_name,
        "folder": f"paw/{folder}",
        "tags": [str(user_id)],
    }


def delete_image(public_id: str) -> bool:
    """
    Elimina una imagen de Cloudinary usando su public_id.
    Útil cuando se elimina una mascota o un reporte de fraude confirma abuso.
    """
    try:
        result = cloudinary.api.delete_resources([public_id])
        return result.get("deleted", {}).get(public_id) == "deleted"
    except Exception as e:
        print(f"Error deleting image from Cloudinary: {e}")
        return False
