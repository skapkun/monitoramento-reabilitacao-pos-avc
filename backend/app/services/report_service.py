import base64
from html import escape
from io import BytesIO

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Image, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.schemas.report import LongitudinalReportRequest


class ReportService:
    def longitudinal_pdf(self, request: LongitudinalReportRequest) -> bytes:
        output = BytesIO()
        document = SimpleDocTemplate(
            output,
            pagesize=A4,
            rightMargin=1.6 * cm,
            leftMargin=1.6 * cm,
            topMargin=1.6 * cm,
            bottomMargin=1.6 * cm,
            title="Relatório longitudinal Movere",
            author="Movere",
        )
        styles = getSampleStyleSheet()
        story = [
            Paragraph("Relatório longitudinal — Movere", styles["Title"]),
            Spacer(1, 0.4 * cm),
            Paragraph(f"Paciente: <b>{escape(request.patient_name)}</b>", styles["BodyText"]),
            Paragraph(f"Identificador: {escape(request.patient_id)}", styles["BodyText"]),
            Spacer(1, 0.5 * cm),
        ]

        completed = sum(session.status == "completed" for session in request.sessions)
        repetitions = sum(session.repetitions for session in request.sessions)
        review = sum(session.requires_review for session in request.sessions)
        story.extend(
            [
                Paragraph(
                    f"Sessões registradas: {len(request.sessions)} | "
                    f"Concluídas: {completed} | Repetições observadas: {repetitions} | "
                    f"Para revisão: {review}",
                    styles["BodyText"],
                ),
                Spacer(1, 0.5 * cm),
            ]
        )

        chart = self._progress_chart(request)
        if chart is not None:
            story.extend(
                [
                    Paragraph("Evolução observada", styles["Heading2"]),
                    Image(chart, width=16 * cm, height=7 * cm),
                    Spacer(1, 0.5 * cm),
                ]
            )

        rows = [["Data", "Exercício", "Rep.", "Amplitude", "Tempo", "Relato"]]
        for session in request.sessions:
            rows.append(
                [
                    session.date.astimezone().strftime("%d/%m/%Y %H:%M"),
                    session.exercise,
                    self._repetitions_summary(session),
                    self._amplitude_summary(session),
                    "—" if session.average_duration_seconds is None else f"{session.average_duration_seconds:.2f}s",
                    self._subjective_summary(session),
                ]
            )
        if len(rows) == 1:
            rows.append(["—", "Nenhuma sessão registrada", "0", "—", "—", "—"])

        table = Table(rows, repeatRows=1, colWidths=[3 * cm, 4 * cm, 1.5 * cm, 2.4 * cm, 2.2 * cm, 2.3 * cm])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#145C63")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B8C4C6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F2F7F7")]),
                    ("LEFTPADDING", (0, 0), (-1, -1), 5),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        story.extend(
            [
                table,
                Spacer(1, 0.7 * cm),
                Paragraph("Métricas técnicas e revisão profissional", styles["Heading2"]),
                self._technical_metrics_table(request),
                Spacer(1, 0.7 * cm),
                Paragraph("Calibração da detecção", styles["Heading2"]),
                self._calibration_table(request),
                Spacer(1, 0.7 * cm),
                Paragraph("Momentos técnicos destacados", styles["Heading2"]),
                self._movement_events_table(request),
                Spacer(1, 0.7 * cm),
                Paragraph("Capturas técnicas autorizadas", styles["Heading2"]),
                *self._evidence_content(request),
                Spacer(1, 0.7 * cm),
                Paragraph("Orientações do fisioterapeuta", styles["Heading2"]),
                self._professional_comments_table(request),
                Spacer(1, 0.7 * cm),
                Paragraph(
                    "Documento descritivo gerado por protótipo acadêmico. "
                    "Não constitui laudo, diagnóstico ou avaliação clínica e não substitui o fisioterapeuta.",
                    styles["Italic"],
                ),
            ]
        )
        document.build(story)
        return output.getvalue()

    def _technical_metrics_table(self, request: LongitudinalReportRequest) -> Table:
        rows = [["Sessão", "Velocidade", "Simetria", "Distância", "Avaliação", "Conduta"]]
        conduct_labels = {
            "maintain_training": "Manter treino",
            "adjust_load": "Ajustar carga",
            "schedule_reassessment": "Agendar reavaliação",
        }
        for index, session in enumerate(request.sessions, start=1):
            rows.append(
                [
                    str(index),
                    "—" if session.average_velocity_degrees_per_second is None else f"{session.average_velocity_degrees_per_second:.1f}°/s",
                    "—" if session.average_symmetry_difference_degrees is None else f"{session.average_symmetry_difference_degrees:.1f}°",
                    "—" if session.average_distance is None else f"{session.average_distance:.3f}",
                    "—" if session.professional_rating is None else f"{session.professional_rating}/5",
                    conduct_labels.get(session.professional_conduct, "—"),
                ]
            )
        if len(rows) == 1:
            rows.append(["—", "—", "—", "—", "—", "—"])
        table = Table(
            rows,
            repeatRows=1,
            colWidths=[1.3 * cm, 2.8 * cm, 2.4 * cm, 2.3 * cm, 2.2 * cm, 4.4 * cm],
        )
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#145C63")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B8C4C6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F2F7F7")]),
                ]
            )
        )
        return table

    def _calibration_table(self, request: LongitudinalReportRequest) -> Table:
        styles = getSampleStyleSheet()
        rows = [["Sessão", "Configuração", "Justificativa"]]
        for index, session in enumerate(request.sessions, start=1):
            if session.custom_detection_applied:
                start = session.detection_start_threshold
                change = session.detection_change_threshold
                configuration = (
                    f"{start:g} → {change:g} → {start:g}"
                    if start is not None and change is not None
                    else "Calibração informada sem valores disponíveis"
                )
                reason = session.calibration_reason or "Não informada"
            else:
                configuration = "Padrão do algoritmo"
                reason = "—"
            rows.append(
                [
                    str(index),
                    configuration,
                    Paragraph(escape(reason), styles["BodyText"]),
                ]
            )
        if len(rows) == 1:
            rows.append(["—", "—", "—"])
        table = Table(rows, repeatRows=1, colWidths=[1.5 * cm, 4.5 * cm, 10 * cm])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#145C63")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B8C4C6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]
            )
        )
        return table

    def _evidence_content(self, request: LongitudinalReportRequest) -> list:
        styles = getSampleStyleSheet()
        content = []
        total_bytes = 0
        for session_index, session in enumerate(request.sessions, start=1):
            for evidence in session.evidence[:4]:
                try:
                    raw = base64.b64decode(evidence.image_base64, validate=True)
                except (ValueError, TypeError):
                    continue
                if not raw or len(raw) > 100_000:
                    continue
                total_bytes += len(raw)
                if total_bytes > 4_000_000:
                    break
                title = escape(evidence.title)
                seconds = evidence.timestamp_seconds
                caption = (
                    f"Sessão {session_index} — {title} — "
                    f"{int(seconds // 60)}:{int(seconds % 60):02d}"
                )
                content.extend(
                    [
                        Image(BytesIO(raw), width=10.5 * cm, height=7 * cm, kind="proportional"),
                        Paragraph(caption, styles["BodyText"]),
                        Spacer(1, 0.4 * cm),
                    ]
                )
        if not content:
            return [Paragraph("Nenhuma captura autorizada disponível.", styles["BodyText"])]
        return content

    def _professional_comments_table(self, request: LongitudinalReportRequest) -> Table:
        styles = getSampleStyleSheet()
        rows = [["Sessão", "Orientação registrada"]]
        for index, session in enumerate(request.sessions, start=1):
            if session.review_comment:
                rows.append(
                    [str(index), Paragraph(escape(session.review_comment), styles["BodyText"])]
                )
        if len(rows) == 1:
            rows.append(["—", "Nenhuma orientação registrada"])
        table = Table(rows, repeatRows=1, colWidths=[2 * cm, 14 * cm])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#145C63")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B8C4C6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]
            )
        )
        return table

    def _movement_events_table(self, request: LongitudinalReportRequest) -> Table:
        rows = [["Sessão", "Momento", "Observação", "Revisão"]]
        review_labels = {
            "confirmed": "Confirmada",
            "not_confirmed": "Não confirmada",
            "insufficient_video": "Vídeo insuficiente",
            "pending": "Pendente",
        }
        for session_index, session in enumerate(request.sessions, start=1):
            for event in session.movement_events[:8]:
                title = escape(str(event.get("title", "Momento da análise")))
                seconds = float(
                    event.get("startSeconds", event.get("start_seconds", 0)) or 0
                )
                minute = int(seconds // 60)
                second = int(seconds % 60)
                event_type = str(event.get("type", "information"))
                key = f"{event_type}_{round(seconds * 1000)}"
                review = review_labels.get(session.event_reviews.get(key), "Pendente")
                rows.append([str(session_index), f"{minute}:{second:02d}", title, review])
        if len(rows) == 1:
            rows.append(["—", "—", "Nenhum momento destacado", "—"])
        table = Table(
            rows, repeatRows=1, colWidths=[1.5 * cm, 2 * cm, 8.5 * cm, 4 * cm]
        )
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#145C63")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B8C4C6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]
            )
        )
        return table

    @staticmethod
    def _subjective_summary(session) -> str:
        values = []
        if session.wellbeing_score is not None:
            values.append(f"Bem-estar {session.wellbeing_score}/5")
        if session.pain_score is not None:
            values.append(f"Dor {session.pain_score}/10")
        if session.fatigue_score is not None:
            values.append(f"Fadiga {session.fatigue_score}/10")
        return "\n".join(values) if values else "—"

    @staticmethod
    def _repetitions_summary(session) -> str:
        if session.prescribed_repetitions is None:
            return str(session.repetitions)
        sets = session.prescribed_sets or 1
        return f"{session.repetitions} / {sets}x{session.prescribed_repetitions}"

    @staticmethod
    def _amplitude_summary(session) -> str:
        observed = "—" if session.average_amplitude_degrees is None else f"{session.average_amplitude_degrees:.1f}°"
        if session.prescribed_amplitude_degrees is None:
            return observed
        return f"{observed} / meta {session.prescribed_amplitude_degrees:.0f}°"

    def _progress_chart(self, request: LongitudinalReportRequest):
        sessions = sorted(request.sessions, key=lambda item: item.date)
        if len(sessions) < 2:
            return None
        labels = [item.date.strftime("%d/%m") for item in sessions]
        repetitions = [item.repetitions for item in sessions]
        figure, axis = plt.subplots(figsize=(8, 3.5))
        axis.plot(labels, repetitions, marker="o", color="#145C63")
        axis.set_ylabel("Repetições")
        axis.set_xlabel("Sessão")
        axis.grid(alpha=0.25)
        figure.tight_layout()
        image = BytesIO()
        figure.savefig(image, format="png", dpi=140)
        plt.close(figure)
        image.seek(0)
        return image
