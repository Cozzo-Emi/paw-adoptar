"""
PAW — Configuración centralizada de la aplicación.
Carga variables de entorno con validación via Pydantic Settings.
"""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración global de la app, cargada desde .env"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # --- App ---
    app_name: str = "PAW"
    app_env: str = "development"
    debug: bool = True
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080"]

    # --- Base de datos ---
    postgres_user: str = "paw_user"
    postgres_password: str = "paw_secret_dev"
    postgres_db: str = "paw_db"
    postgres_host: str = "db"
    postgres_port: int = 5432
    database_url: str = "postgresql+asyncpg://paw_user:paw_secret_dev@db:5432/paw_db"

    # --- JWT / Auth ---
    secret_key: str = "CAMBIAR_POR_UN_SECRET_SEGURO_DE_AL_MENOS_32_CHARS"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # --- Cloudinary ---
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    # --- Firebase ---
    firebase_credentials_path: str = ""


@lru_cache
def get_settings() -> Settings:
    """Singleton cacheado de la configuración."""
    return Settings()
