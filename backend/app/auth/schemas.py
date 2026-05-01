from pydantic import BaseModel, ConfigDict, Field


class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class Token(BaseSchema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseSchema):
    sub: str | None = None
    type: str | None = None


class RefreshTokenRequest(BaseSchema):
    refresh_token: str = Field(..., min_length=1)
