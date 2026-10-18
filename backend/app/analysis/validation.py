import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Sequence

from app.analysis.models import AnalysisOutcome
from app.analysis.pipeline import ElbowFlexionPipeline


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as video:
        for chunk in iter(lambda: video.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_video(
    video_path: Path,
    *,
    preferred_side: Optional[str] = None,
    pipeline: Optional[ElbowFlexionPipeline] = None,
) -> dict:
    resolved = video_path.expanduser().resolve()
    if not resolved.is_file():
        raise FileNotFoundError(f"Vídeo não encontrado: {video_path}")

    result = (pipeline or ElbowFlexionPipeline()).analyze_video(
        resolved,
        preferred_side=preferred_side,
    )
    return {
        "validationSchema": "movere-elbow-validation-v1",
        "analyzedAt": datetime.now(timezone.utc).isoformat(),
        "video": {
            "fileName": resolved.name,
            "sizeBytes": resolved.stat().st_size,
            "sha256": _sha256(resolved),
        },
        "result": result.to_dict(),
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Valida um vídeo real de flexão de cotovelo no pipeline Movere.",
    )
    parser.add_argument("video", type=Path, help="Caminho do vídeo MP4, MOV ou WebM.")
    parser.add_argument(
        "--side",
        choices=("left", "right"),
        help="Braço esperado; se omitido, o pipeline escolhe o mais visível.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Arquivo JSON de saída; se omitido, imprime no terminal.",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = _parser().parse_args(argv)
    try:
        report = validate_video(args.video, preferred_side=args.side)
    except FileNotFoundError as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=False))
        return 1

    serialized = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        output = args.output.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(f"{serialized}\n", encoding="utf-8")
        print(f"Relatório salvo em {output}")
    else:
        print(serialized)

    status = report["result"]["status"]
    if status == AnalysisOutcome.SUCCESS.value:
        return 0
    if status == AnalysisOutcome.INCONCLUSIVE.value:
        return 2
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
