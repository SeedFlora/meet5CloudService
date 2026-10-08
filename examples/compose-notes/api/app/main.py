"""Three-tier classroom demo: every note is stored in PostgreSQL."""

import os
from contextlib import asynccontextmanager, contextmanager
from datetime import datetime

import psycopg
from fastapi import FastAPI, HTTPException, Response, status
from psycopg.rows import dict_row
from pydantic import BaseModel, Field, field_validator


@contextmanager
def db_connection():
    """Open a short transaction; commit successful writes and close the connection."""
    try:
        with psycopg.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "5432")),
            dbname=os.getenv("DB_NAME", "cloudnotes"),
            user=os.getenv("DB_USER", "clouduser"),
            password=os.getenv("DB_PASSWORD", "classroom-demo-only-change-me"),
            connect_timeout=3,
            row_factory=dict_row,
        ) as connection:
            yield connection
    except psycopg.Error as exc:
        raise HTTPException(status_code=503, detail="Database belum siap; periksa service db") from exc


@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Compose waits for db to become healthy before starting this API.
    with db_connection() as connection:
        connection.execute(
            "CREATE TABLE IF NOT EXISTS notes ("
            "id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, "
            "title VARCHAR(120) NOT NULL, "
            "content TEXT NOT NULL, "
            "created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)"
        )
    yield


app = FastAPI(title="Cloud Notes · Compose", version="1.0.0", lifespan=lifespan)


class NoteInput(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    content: str = Field(min_length=1, max_length=5000)

    @field_validator("title", "content")
    @classmethod
    def reject_blank_text(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("teks tidak boleh hanya berisi spasi")
        return cleaned


class NoteOutput(NoteInput):
    id: int
    created_at: datetime


@app.get("/health")
def health() -> dict:
    with db_connection() as connection:
        connection.execute("SELECT 1")
    return {"status": "ok", "database": "postgres", "service": "cloud-notes-compose-api"}


@app.get("/runtime")
def runtime() -> dict:
    return {
        "app_env": os.getenv("APP_ENV", "classroom"),
        "storage": "postgres",
        "db_host": os.getenv("DB_HOST", "db"),
        "db_port": int(os.getenv("DB_PORT", "5432")),
        "persistence": "named-volume",
    }


@app.get("/notes", response_model=list[NoteOutput])
def list_notes() -> list[dict]:
    with db_connection() as connection:
        return connection.execute(
            "SELECT id, title, content, created_at FROM notes ORDER BY id DESC"
        ).fetchall()


@app.get("/notes/{note_id}", response_model=NoteOutput)
def get_note(note_id: int) -> dict:
    with db_connection() as connection:
        row = connection.execute(
            "SELECT id, title, content, created_at FROM notes WHERE id = %s", (note_id,)
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Catatan tidak ditemukan")
    return row


@app.post("/notes", response_model=NoteOutput, status_code=status.HTTP_201_CREATED)
def create_note(note: NoteInput) -> dict:
    # Parameters are passed separately from SQL, including quotes in user input.
    with db_connection() as connection:
        return connection.execute(
            "INSERT INTO notes (title, content) VALUES (%s, %s) "
            "RETURNING id, title, content, created_at",
            (note.title, note.content),
        ).fetchone()


@app.delete("/notes/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_note(note_id: int) -> Response:
    with db_connection() as connection:
        row = connection.execute("DELETE FROM notes WHERE id = %s RETURNING id", (note_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Catatan tidak ditemukan")
    return Response(status_code=status.HTTP_204_NO_CONTENT)
