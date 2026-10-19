#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import stat
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


PROJECT_ID = "movere-dc610"
DEFAULT_API_KEY = "AIzaSyD_7LrlT3Nch2_sI95YW-QtenVJXjWcE3g"
PATIENT_EMAIL = "paciente.apresentacao@movere.app"
THERAPIST_EMAIL = "profissional.apresentacao@movere.app"
SECONDARY_PATIENTS = (
    ("João Pereira", "joao.apresentacao@movere.app", "joao-pereira"),
    ("Lúcia Santos", "lucia.apresentacao@movere.app", "lucia-santos"),
    ("Carla Mendes", "carla.apresentacao@movere.app", "carla-mendes"),
)
CREDENTIALS_PATH = Path(__file__).resolve().parents[1] / "docs" / "APRESENTACAO_CREDENCIAIS.md"


class SeedError(RuntimeError):
    pass


def timestamp(value: datetime) -> dict[str, str]:
    normalized = value.astimezone(timezone.utc).isoformat(timespec="milliseconds")
    return {"timestampValue": normalized.replace("+00:00", "Z")}


def firestore_value(value: Any) -> dict[str, Any]:
    if value is None:
        return {"nullValue": None}
    if isinstance(value, bool):
        return {"booleanValue": value}
    if isinstance(value, int):
        return {"integerValue": str(value)}
    if isinstance(value, float):
        return {"doubleValue": value}
    if isinstance(value, datetime):
        return timestamp(value)
    if isinstance(value, str):
        return {"stringValue": value}
    if isinstance(value, list):
        return {"arrayValue": {"values": [firestore_value(item) for item in value]}}
    if isinstance(value, dict):
        return {
            "mapValue": {
                "fields": {key: firestore_value(item) for key, item in value.items()}
            }
        }
    raise TypeError(f"Tipo não suportado pelo Firestore: {type(value).__name__}")


def document(data: dict[str, Any]) -> dict[str, Any]:
    return {"fields": {key: firestore_value(value) for key, value in data.items()}}


class FirebaseClient:
    def __init__(self, project_id: str, api_key: str) -> None:
        self.project_id = project_id
        self.api_key = api_key
        self.firestore_base = (
            f"https://firestore.googleapis.com/v1/projects/{project_id}"
            "/databases/(default)/documents"
        )

    def _request(
        self,
        url: str,
        *,
        method: str = "GET",
        payload: dict[str, Any] | None = None,
        token: str | None = None,
        allow_not_found: bool = False,
        allow_conflict: bool = False,
    ) -> dict[str, Any] | None:
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        request = Request(
            url,
            method=method,
            headers=headers,
            data=None if payload is None else json.dumps(payload).encode("utf-8"),
        )
        try:
            with urlopen(request, timeout=30) as response:
                body = response.read()
                return json.loads(body) if body else {}
        except HTTPError as error:
            body = error.read().decode("utf-8", errors="replace")
            if allow_not_found and error.code == 404:
                return None
            if allow_conflict and error.code in {409, 412}:
                return None
            try:
                details = json.loads(body)["error"]
                message = details.get("message", body)
            except (KeyError, TypeError, json.JSONDecodeError):
                message = body or str(error)
            raise SeedError(f"Firebase respondeu {error.code}: {message}") from error

    def authenticate(self, email: str, password: str) -> dict[str, str]:
        payload = {"email": email, "password": password, "returnSecureToken": True}
        signup_url = (
            "https://identitytoolkit.googleapis.com/v1/accounts:signUp?"
            + urlencode({"key": self.api_key})
        )
        try:
            result = self._request(signup_url, method="POST", payload=payload)
        except SeedError as error:
            if "EMAIL_EXISTS" not in str(error):
                raise
            signin_url = (
                "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?"
                + urlencode({"key": self.api_key})
            )
            result = self._request(signin_url, method="POST", payload=payload)
        assert result is not None
        return {"uid": result["localId"], "token": result["idToken"]}

    def get(self, path: str, token: str) -> dict[str, Any] | None:
        return self._request(
            f"{self.firestore_base}/{quote(path, safe='/')}",
            token=token,
            allow_not_found=True,
        )

    def create_if_missing(
        self,
        path: str,
        data: dict[str, Any],
        token: str,
        *,
        blind: bool = False,
    ) -> bool:
        if not blind and self.get(path, token) is not None:
            return False
        if blind:
            collection, document_id = path.rsplit("/", 1)
            url = (
                f"{self.firestore_base}/{quote(collection, safe='/')}?"
                + urlencode({"documentId": document_id})
            )
            method = "POST"
        else:
            url = f"{self.firestore_base}/{quote(path, safe='/')}"
            method = "PATCH"
        result = self._request(
            url,
            method=method,
            payload=document(data),
            token=token,
            allow_conflict=blind,
        )
        return result is not None

    def update_fields(
        self, path: str, data: dict[str, Any], token: str
    ) -> None:
        query = urlencode(
            [("updateMask.fieldPaths", field) for field in data], doseq=True
        )
        self._request(
            f"{self.firestore_base}/{quote(path, safe='/')}?{query}",
            method="PATCH",
            payload=document(data),
            token=token,
        )


def profile_data(*, name: str, email: str, role: str, now: datetime) -> dict[str, Any]:
    common: dict[str, Any] = {
        "name": name,
        "email": email,
        "role": role,
        "active": True,
        "createdAt": now,
        "updatedAt": now,
    }
    if role == "patient":
        common.update(
            {
                "phone": "(69) 99999-1001",
                "affectedSide": "right",
                "strokeType": "not_informed",
                "mobility": "independent",
                "ageRange": "50_59",
                "monthsSinceStroke": 0,
                "dominantSide": "right",
                "assistiveDevice": "none",
                "participantContext": "healthy_volunteer",
            }
        )
    else:
        common.update(
            {
                "phone": "(69) 99999-2002",
                "professionalRegistration": "Registro fictício — apresentação acadêmica",
            }
        )
    return common


def session_data(
    patient_id: str,
    created_at: datetime,
    *,
    exercise_type: str,
    repetitions: int,
    amplitude: float | None,
    confidence: float,
    requires_review: bool = False,
) -> dict[str, Any]:
    details = [
        {
            "number": index,
            "startSeconds": float(index * 2 - 2),
            "endSeconds": float(index * 2),
            "amplitudeDegrees": amplitude or 0.0,
            "durationSeconds": 2.0,
            "classification": "regular",
        }
        for index in range(1, repetitions + 1)
    ]
    return {
        "patientId": patient_id,
        "exerciseType": exercise_type,
        "status": "completed",
        "repetitions": repetitions,
        "averageAmplitudeDegrees": amplitude,
        "confidence": confidence,
        "averageDurationSeconds": 2.0,
        "averageVelocityDegreesPerSecond": None,
        "averageSymmetryDifferenceDegrees": None,
        "averageDistance": None,
        "requiresReview": requires_review,
        "simulated": True,
        "message": "Registro sintético preparado para a apresentação.",
        "prescriptionVersion": 1,
        "prescribedSets": 1,
        "prescribedRepetitions": 3,
        "prescribedSessionsPerWeek": 3,
        "prescribedAmplitudeDegrees": amplitude,
        "prescribedTrainingSide": "right",
        "prescribedCadenceSeconds": 2.0,
        "prescribedRestSeconds": 60,
        "customDetectionApplied": False,
        "detectionStartThreshold": None,
        "detectionChangeThreshold": None,
        "calibrationReason": None,
        "movementEvents": [],
        "repetitionDetails": details,
        "affectedSideAtAnalysis": "right",
        "unaffectedSideAtAnalysis": "left",
        "averageAffectedAngleDegrees": amplitude,
        "averageUnaffectedAngleDegrees": amplitude,
        "analysisParametersVersion": "presentation-seed-v1",
        "validFrames": 118,
        "totalFrames": 120,
        "detectionRatio": 0.983,
        "analysisEvidence": [],
        "evidenceConsentAt": None,
        "evidenceConsentVersion": None,
        "createdAt": created_at,
    }


def ensure_profile(
    client: FirebaseClient,
    *,
    uid: str,
    token: str,
    data: dict[str, Any],
) -> None:
    path = f"users/{uid}"
    if client.get(path, token) is None:
        client.create_if_missing(path, data, token)
        return
    mutable = {
        key: value
        for key, value in data.items()
        if key not in {"email", "role", "active", "createdAt"}
    }
    client.update_fields(path, mutable, token)


def ensure_link(
    client: FirebaseClient,
    *,
    patient: dict[str, str],
    therapist: dict[str, str],
    now: datetime,
) -> None:
    link_path = f"careLinks/{therapist['uid']}_{patient['uid']}"
    created = client.create_if_missing(
        link_path,
        {
            "therapistId": therapist["uid"],
            "therapistName": "Dra. Ana Souza",
            "patientId": patient["uid"],
            "status": "pending",
            "createdAt": now,
            "updatedAt": now,
        },
        therapist["token"],
        blind=True,
    )
    if created:
        status = "pending"
    else:
        link = client.get(link_path, therapist["token"])
        assert link is not None
        status = link.get("fields", {}).get("status", {}).get("stringValue")
    if status == "rejected":
        client.update_fields(
            link_path, {"status": "pending", "updatedAt": now}, therapist["token"]
        )
        status = "pending"
    if status == "pending":
        client.update_fields(
            link_path, {"status": "accepted", "updatedAt": now}, patient["token"]
        )


def write_local_credentials(patient_password: str, therapist_password: str) -> None:
    content = f"""# Credenciais locais da apresentação

Este arquivo é ignorado pelo Git. Não o envie nem compartilhe publicamente.

## Paciente — Maria Oliveira

- E-mail: `{PATIENT_EMAIL}`
- Senha: `{patient_password}`

## Fisioterapeuta — Dra. Ana Souza

- E-mail: `{THERAPIST_EMAIL}`
- Senha: `{therapist_password}`
"""
    CREDENTIALS_PATH.write_text(content, encoding="utf-8")
    CREDENTIALS_PATH.chmod(stat.S_IRUSR | stat.S_IWUSR)


def seed(
    client: FirebaseClient, patient_password: str, therapist_password: str
) -> None:
    now = datetime.now(timezone.utc)
    patient = client.authenticate(PATIENT_EMAIL, patient_password)
    therapist = client.authenticate(THERAPIST_EMAIL, therapist_password)
    print("Contas autenticadas.")

    ensure_profile(
        client,
        uid=patient["uid"],
        token=patient["token"],
        data=profile_data(
            name="Maria Oliveira", email=PATIENT_EMAIL, role="patient", now=now
        ),
    )
    print("Perfil do paciente preparado.")
    ensure_profile(
        client,
        uid=therapist["uid"],
        token=therapist["token"],
        data=profile_data(
            name="Dra. Ana Souza", email=THERAPIST_EMAIL, role="therapist", now=now
        ),
    )
    print("Perfil profissional preparado.")

    ensure_link(client, patient=patient, therapist=therapist, now=now)
    print("Vínculo preparado.")

    plan_specs = [
        ("elbow_flexion", "Flexão de cotovelo", "Execute devagar e mantenha o braço inteiro visível.", 95.0),
        ("squat", "Agachamento", "Use apoio quando orientado e mantenha o corpo inteiro no quadro.", 100.0),
        ("pinch", "Movimento de pinça", "Aproxime polegar e indicador lentamente diante da câmera.", None),
    ]
    for exercise, title, instructions, amplitude in plan_specs:
        client.create_if_missing(
            f"plans/{patient['uid']}_{exercise}",
            {
                "patientId": patient["uid"],
                "therapistId": therapist["uid"],
                "exerciseType": exercise,
                "title": title,
                "instructions": instructions,
                "sessionsPerWeek": 3,
                "targetRepetitions": 3,
                "version": 1,
                "sets": 1,
                "targetAmplitudeDegrees": amplitude,
                "trainingSide": "right" if exercise != "pinch" else "affected",
                "cadenceSeconds": 2.0,
                "restSeconds": 60,
                "customDetectionEnabled": False,
                "detectionStartThreshold": None,
                "detectionChangeThreshold": None,
                "calibrationReason": None,
                "startDate": now - timedelta(days=14),
                "endDate": now + timedelta(days=30),
                "active": True,
                "updatedAt": now,
            },
            therapist["token"],
            blind=True,
        )
    print("Planos preparados.")

    sessions = [
        ("apresentacao-cotovelo-1", "elbow_flexion", 3, 94.0, 0.91, 1, False),
        ("apresentacao-agachamento-1", "squat", 3, 102.0, 0.87, 3, False),
        ("apresentacao-pinca-1", "pinch", 3, None, 0.84, 5, True),
    ]
    for doc_id, exercise, repetitions, amplitude, confidence, days, review in sessions:
        client.create_if_missing(
            f"sessions/{doc_id}-{patient['uid']}",
            session_data(
                patient["uid"],
                now - timedelta(days=days),
                exercise_type=exercise,
                repetitions=repetitions,
                amplitude=amplitude,
                confidence=confidence,
                requires_review=review,
            ),
            patient["token"],
            blind=True,
        )
    print("Sessões sintéticas preparadas.")

    client.create_if_missing(
        f"notes/apresentacao-orientacao-{patient['uid']}",
        {
            "patientId": patient["uid"],
            "therapistId": therapist["uid"],
            "text": "Mantenha os movimentos confortáveis e interrompa se sentir desconforto.",
            "visibleToPatient": True,
            "createdAt": now - timedelta(hours=4),
        },
        therapist["token"],
        blind=True,
    )
    print("Orientação preparada.")
    client.create_if_missing(
        f"messages/apresentacao-paciente-{patient['uid']}",
        {
            "patientId": patient["uid"],
            "therapistId": therapist["uid"],
            "senderId": patient["uid"],
            "senderRole": "patient",
            "recipientId": therapist["uid"],
            "participants": [patient["uid"], therapist["uid"]],
            "text": "Posso realizar os movimentos mais devagar durante a gravação?",
            "category": "movement_question",
            "sessionId": None,
            "createdAt": now - timedelta(hours=3),
            "readAt": None,
        },
        patient["token"],
        blind=True,
    )
    print("Mensagem do paciente preparada.")
    client.create_if_missing(
        f"messages/apresentacao-profissional-{patient['uid']}",
        {
            "patientId": patient["uid"],
            "therapistId": therapist["uid"],
            "senderId": therapist["uid"],
            "senderRole": "therapist",
            "recipientId": patient["uid"],
            "participants": [patient["uid"], therapist["uid"]],
            "text": "Sim. Priorize um movimento confortável e mantenha-se no enquadramento.",
            "category": "general",
            "sessionId": None,
            "createdAt": now - timedelta(hours=2),
            "readAt": None,
        },
        therapist["token"],
        blind=True,
    )
    print("Mensagem profissional preparada.")

    secondary_records = []
    for index, (name, email, slug) in enumerate(SECONDARY_PATIENTS):
        secondary = client.authenticate(email, patient_password)
        profile = profile_data(name=name, email=email, role="patient", now=now)
        profile.update(
            {
                "phone": f"(69) 99999-10{index + 2:02d}",
                "affectedSide": "left" if index == 0 else "right",
                "strokeType": "ischemic" if index != 1 else "hemorrhagic",
                "mobility": "with_support" if index < 2 else "independent",
                "ageRange": ("60_69", "70_79", "50_59")[index],
                "monthsSinceStroke": (14, 26, 10)[index],
                "dominantSide": "right",
                "assistiveDevice": ("cane", "walker", "none")[index],
                "participantContext": "post_stroke",
            }
        )
        ensure_profile(
            client,
            uid=secondary["uid"],
            token=secondary["token"],
            data=profile,
        )
        ensure_link(client, patient=secondary, therapist=therapist, now=now)
        client.create_if_missing(
            f"plans/{secondary['uid']}_elbow_flexion",
            {
                "patientId": secondary["uid"],
                "therapistId": therapist["uid"],
                "exerciseType": "elbow_flexion",
                "title": "Flexão de cotovelo",
                "instructions": "Execute devagar e mantenha o braço inteiro visível.",
                "sessionsPerWeek": 3,
                "targetRepetitions": 3,
                "version": 1,
                "sets": 1,
                "targetAmplitudeDegrees": 95.0,
                "trainingSide": "right",
                "cadenceSeconds": 2.0,
                "restSeconds": 60,
                "customDetectionEnabled": False,
                "detectionStartThreshold": None,
                "detectionChangeThreshold": None,
                "calibrationReason": None,
                "startDate": now - timedelta(days=14),
                "endDate": now + timedelta(days=30),
                "active": True,
                "updatedAt": now,
            },
            therapist["token"],
            blind=True,
        )
        secondary_records.append((secondary, slug))

    joao, joao_slug = secondary_records[0]
    client.create_if_missing(
        f"sessions/apresentacao-{joao_slug}-1-{joao['uid']}",
        session_data(
            joao["uid"],
            now - timedelta(days=6),
            exercise_type="elbow_flexion",
            repetitions=2,
            amplitude=78.0,
            confidence=0.72,
            requires_review=True,
        ),
        joao["token"],
        blind=True,
    )
    carla, carla_slug = secondary_records[2]
    for number, days in enumerate((1, 3, 5), start=1):
        client.create_if_missing(
            f"sessions/apresentacao-{carla_slug}-{number}-{carla['uid']}",
            session_data(
                carla["uid"],
                now - timedelta(days=days),
                exercise_type="elbow_flexion",
                repetitions=3,
                amplitude=96.0 + number,
                confidence=0.9,
            ),
            carla["token"],
            blind=True,
        )
    print("Três pacientes adicionais e cenários de acompanhamento preparados.")

    write_local_credentials(patient_password, therapist_password)
    print("Seed concluído com dados sintéticos de apresentação.")
    print(f"Paciente: {PATIENT_EMAIL}")
    print(f"Profissional: {THERAPIST_EMAIL}")
    print(f"Credenciais locais: {CREDENTIALS_PATH}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-id", default=PROJECT_ID)
    parser.add_argument(
        "--api-key", default=os.getenv("MOVERE_FIREBASE_API_KEY", DEFAULT_API_KEY)
    )
    args = parser.parse_args()
    common_password = os.getenv("MOVERE_SEED_PASSWORD")
    patient_password = os.getenv("MOVERE_PATIENT_PASSWORD", common_password or "")
    therapist_password = os.getenv("MOVERE_THERAPIST_PASSWORD", common_password or "")
    if len(patient_password) < 8 or len(therapist_password) < 8:
        print(
            "Defina MOVERE_SEED_PASSWORD para uma senha compartilhada ou "
            "MOVERE_PATIENT_PASSWORD e MOVERE_THERAPIST_PASSWORD para senhas "
            "diferentes, sempre com pelo menos 8 caracteres. As senhas não "
            "serão versionadas.",
            file=sys.stderr,
        )
        return 2
    try:
        seed(
            FirebaseClient(args.project_id, args.api_key),
            patient_password,
            therapist_password,
        )
    except SeedError as error:
        print(f"Falha ao criar seed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
