
import os

import anthropic
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

# Carrega a chave de services/api/.env
ENV_FILE = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", ".env")
)
load_dotenv(ENV_FILE)

app = FastAPI(
    title="ALFRED X API",
    description="API central do assistente ALFRED X",
    version="0.3.0",
)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


@app.get("/")
def home():
    return {
        "name": "ALFRED X",
        "status": "online",
        "message": "O núcleo inicial está funcionando.",
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/chat")
def chat(request: ChatRequest):
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Escreva uma mensagem para começar.",
        )

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="A chave da API não está configurada no servidor.",
        )

    try:
        client = anthropic.Anthropic(api_key=api_key)

        result = client.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=800,
            messages=[
                {
                    "role": "user",
                    "content": message,
                }
            ],
        )

        answer = "\n".join(
            block.text
            for block in result.content
            if block.type == "text"
        )

        return {
            "name": "ALFRED X",
            "received": True,
            "response": answer,
            "model": result.model,
        }

    except anthropic.APIError:
        raise HTTPException(
            status_code=502,
            detail=(
                "Não foi possível obter uma resposta do serviço de IA. "
                "Verifique a chave, o acesso à API e a faturação."
            ),
        )
