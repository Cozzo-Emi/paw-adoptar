from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import get_settings
from app.database import engine

settings = get_settings()

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Backend para PAW - App de Adopción de Mascotas",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


def get_rate_limit(default: str) -> str:
    return default if settings.app_env != "testing" else "1000/minute"


# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.app_env == "development" else settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok",
        "app_name": settings.app_name,
        "environment": settings.app_env,
    }


from app.auth.router import router as auth_router  # noqa: E402
from app.users.router import router as users_router  # noqa: E402
from app.pets.router import router as pets_router  # noqa: E402
from app.matching.router import router as matching_router  # noqa: E402
from app.chat.router import router as chat_router  # noqa: E402
from app.moderation.router import router as moderation_router  # noqa: E402

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(pets_router)
app.include_router(matching_router)
app.include_router(chat_router)
app.include_router(moderation_router)
