from __future__ import annotations

import re
from pathlib import Path


BACKEND_ROOT = Path(r"C:\Users\Al-Buhaira\Desktop\Order-Track\backend")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8", newline="\n")


def replace_once(content: str, needle: str, replacement: str, *, label: str) -> str:
    if needle not in content:
        raise RuntimeError(f"[{label}] needle not found")
    if content.count(needle) != 1:
        raise RuntimeError(f"[{label}] expected 1 occurrence, got {content.count(needle)}")
    return content.replace(needle, replacement)


def insert_before(content: str, marker: str, insert: str, *, label: str) -> str:
    idx = content.find(marker)
    if idx == -1:
        raise RuntimeError(f"[{label}] marker not found")
    return content[:idx] + insert + content[idx:]


def patch_email_service() -> None:
    path = BACKEND_ROOT / "services" / "emailService.js"
    content = read_text(path)

    content = replace_once(
        content,
        "exports.sendEmail = async ({ to, bcc, subject, html, replyTo }) => {",
        "exports.sendEmail = async ({ to, bcc, subject, html, replyTo, attachments }) => {",
        label="emailService signature",
    )

    # Insert attachments into transporter options.
    if "attachments:" not in content:
        content = content.replace(
            "      replyTo: replyTo || DEFAULT_REPLY_TO,\n",
            "      replyTo: replyTo || DEFAULT_REPLY_TO,\n"
            "      attachments: Array.isArray(attachments) && attachments.length ? attachments : undefined,\n",
        )

    write_text(path, content)


def patch_station_routes() -> None:
    path = BACKEND_ROOT / "routes" / "stationRoutes.js"
    content = read_text(path)

    route_line = (
        "router.post('/sessions/:sessionId/report/email', pumpSessionController.emailSessionReportPdf);\n"
    )
    if route_line in content:
        return

    marker = "router.put('/sessions/:sessionId/close', pumpSessionController.closeSession);\n"
    content = content.replace(marker, marker + route_line)
    write_text(path, content)


def patch_pump_session_controller() -> None:
    path = BACKEND_ROOT / "controllers" / "pumpSessionController.js"
    content = read_text(path)

    # Expand session notification roles to include admin + supervisor.
    old_roles = (
        "const SESSION_NOTIFICATION_ROLES = [\n"
        "  'owner',\n"
        "  'manager',\n"
        "  'sales_manager_statiun',\n"
        "];\n"
    )
    new_roles = (
        "const SESSION_NOTIFICATION_ROLES = [\n"
        "  'owner',\n"
        "  'admin',\n"
        "  'manager',\n"
        "  'supervisor',\n"
        "  'sales_manager_statiun',\n"
        "];\n"
    )
    if old_roles in content:
        content = content.replace(old_roles, new_roles)

    # Add new endpoint handler (idempotent).
    if "exports.emailSessionReportPdf" not in content:
        marker = "exports.updateSession = async (req, res) => {\n"
        insert = (
            "\n"
            "// Email session PDF report (sent from frontend)\n"
            "exports.emailSessionReportPdf = async (req, res) => {\n"
            "  try {\n"
            "    const { sessionId } = req.params;\n"
            "    const { pdfBase64, fileName } = req.body || {};\n"
            "\n"
            "    if (!pdfBase64 || typeof pdfBase64 !== 'string') {\n"
            "      return res.status(400).json({ error: 'pdfBase64 مطلوب' });\n"
            "    }\n"
            "\n"
            "    const pdfBuffer = Buffer.from(pdfBase64, 'base64');\n"
            "    if (!pdfBuffer.length) {\n"
            "      return res.status(400).json({ error: 'ملف PDF غير صالح' });\n"
            "    }\n"
            "\n"
            "    if (pdfBuffer.slice(0, 4).toString() !== '%PDF') {\n"
            "      return res.status(400).json({ error: 'الملف المرفق ليس PDF صالح' });\n"
            "    }\n"
            "\n"
            "    const session = await PumpSession.findById(sessionId);\n"
            "    if (!session) {\n"
            "      return res.status(404).json({ error: 'الجلسة غير موجودة' });\n"
            "    }\n"
            "\n"
            "    if (!ensureUserCanAccessStation(req.user, session.stationId)) {\n"
            "      return res.status(403).json({\n"
            "        error: 'غير مصرح لك بالوصول إلى هذه المحطة',\n"
            "      });\n"
            "    }\n"
            "\n"
            "    const station = await Station.findById(session.stationId)\n"
            "      .select('stationName stationCode')\n"
            "      .lean();\n"
            "\n"
            "    const dailySummary = await buildDailyStationSummary({\n"
            "      stationId: session.stationId,\n"
            "      sessionDate: session.sessionDate,\n"
            "    });\n"
            "\n"
            "    const { emailRecipients } = await getCloseSessionNotificationTargets({\n"
            "      stationId: session.stationId,\n"
            "    });\n"
            "\n"
            "    const allRecipients = [...emailRecipients];\n"
            "    if (!allRecipients.includes(DEFAULT_SESSION_REPORT_EMAIL)) {\n"
            "      allRecipients.push(DEFAULT_SESSION_REPORT_EMAIL);\n"
            "    }\n"
            "\n"
            "    const safeFileName =\n"
            "      (typeof fileName === 'string' && fileName.trim()) ||\n"
            "      `session-${session.sessionNumber || session._id}.pdf`;\n"
            "\n"
            "    const emailHtml = generateCloseSessionEmail(session, req.user, station, dailySummary);\n"
            "\n"
            "    await sendEmail({\n"
            "      to: process.env.EMAIL_USER,\n"
            "      bcc: allRecipients,\n"
            "      subject: `📄 تقرير PDF - ${session.sessionNumber} - ${station?.stationName || 'المحطة'} - نظام نبراس`,\n"
            "      html: emailHtml,\n"
            "      replyTo: process.env.EMAIL_USER,\n"
            "      attachments: [\n"
            "        {\n"
            "          filename: safeFileName,\n"
            "          content: pdfBuffer,\n"
            "          contentType: 'application/pdf',\n"
            "        },\n"
            "      ],\n"
            "    });\n"
            "\n"
            "    return res.json({ success: true });\n"
            "  } catch (error) {\n"
            "    console.error('❌ emailSessionReportPdf error:', error);\n"
            "    return res.status(500).json({ error: 'حدث خطأ في السيرفر' });\n"
            "  }\n"
            "};\n"
        )
        content = insert_before(content, marker, insert, label="pumpSessionController insert")

    write_text(path, content)


def main() -> None:
    patch_email_service()
    patch_station_routes()
    patch_pump_session_controller()
    print("✅ Backend patched (email attachments + session PDF endpoint + roles).")


if __name__ == "__main__":
    main()

