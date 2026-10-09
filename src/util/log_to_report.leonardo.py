#!/usr/bin/env python3
"""
log_to_report.py

Parse a CMCC/Leonardo SPS4 forecast log file and generate a clear, organized
PDF report. Unlike free-text sentence clustering, this script understands the
structure of these operational logs: timestamped lines describing IC
production, forecast submissions, recovery events, monthly completion
progress, and diagnostics.

HOW IT WORKS
------------
1. Parses each line into (timestamp, message).
2. Classifies each message into a category:
   - IC Production      (e.g. "CAM IC 01 correctly produced...")
   - Forecast Submission (initial submission + "already submitted" pings)
   - Recovery Events     ("RECOVER STARTING...")
   - Progress Updates    ("number of member with completed month N is X")
   - Diagnostics         (diagnostics submitted/completed, with links)
   - Other               (anything unrecognized, kept for completeness)
3. Repetitive noise (e.g. dozens of "FORECAST already submitted" pings) is
   collapsed into a single summary line with a time range and count, instead
   of repeating it dozens of times.
4. Progress updates are rendered as a small table (time -> month: member count).
5. Builds a PDF with a title, run summary, and one section per category.

USAGE
-----
    python3 log_to_report.py input.txt -o report.pdf --title "SPS4 Forecast Run Report"
"""

import argparse
import re
import sys
from collections import OrderedDict

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem,
    Table, TableStyle
)
from reportlab.lib import colors

TIMESTAMP_RE = re.compile(
    r"^(?P<ts>\w{3} \w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2} CEST \d{4})\s+(?P<msg>.*)$"
)


def parse_log(path: str) -> list[dict]:
    """Parse the log file into a list of {timestamp, message} dicts, skipping blank lines."""
    entries = []
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line:
                continue
            match = TIMESTAMP_RE.match(line)
            print(f"match {match}")
            if match:
                entries.append({"ts": match.group("ts"), "msg": match.group("msg").strip()})
            else:
                # Line without a recognizable timestamp; attach to previous entry if any.
                if entries:
                    entries[-1]["msg"] += " " + line
    return entries


def classify(entries: list[dict]) -> "OrderedDict[str, list]":
    """Sort entries into categories, collapsing repetitive noise."""
    ic_production = []
    submissions = []
    already_submitted_pings = []
    recover_events = []
    progress_updates = []
    diagnostics = []
    other = []

    for e in entries:
        msg = e["msg"]
        if "correctly produced and back-up removed" in msg:
            ic_production.append(e)
        elif "already submitted" in msg:
            already_submitted_pings.append(e)
        elif msg.startswith("Submitted") and "startdates" in msg:
            submissions.append(e)
        elif "RECOVER STARTING" in msg:
            recover_events.append(e)
        elif "number of member with completed month" in msg:
            progress_updates.append(e)
        elif "Diagnostics" in msg or "diag.sh" in msg or "launch_forecast_diag" in msg:
            diagnostics.append(e)
        elif msg == "":
            continue
        else:
            other.append(e)

    sections = OrderedDict()
    sections["IC Production"] = ic_production
    sections["Forecast Submission"] = submissions
    sections["Resubmission Pings"] = already_submitted_pings
    sections["Recovery Events"] = recover_events
    sections["Forecast Progress"] = progress_updates
    sections["Diagnostics"] = diagnostics
    if other:
        sections["Other Events"] = other
    return sections


def summarize_ic_production(entries: list[dict]) -> list[str]:
    """Group IC production lines by IC family (CAM, CLM/HYDROS, NEMO/CICE, etc.) into summary bullets."""
    groups = OrderedDict()
    for e in entries:
        # Strip the trailing "NN correctly produced and back-up removed" to get the family name.
        m = re.match(r"^(.*?)\s+\d+\s+correctly produced and back-up removed$", e["msg"])
        family = m.group(1) if m else e["msg"]
        groups.setdefault(family, []).append(e)

    bullets = []
    for family, items in groups.items():
        first_ts, last_ts = items[0]["ts"], items[-1]["ts"]
        bullets.append(f"{family}: {len(items)} files produced ({first_ts} to {last_ts})")
    return bullets


def summarize_pings(entries: list[dict]) -> list[str]:
    """Collapse repeated 'already submitted' pings into one summary line."""
    if not entries:
        return []
    first_ts, last_ts = entries[0]["ts"], entries[-1]["ts"]
    return [
        f"FORECAST resubmission was blocked {len(entries)} times between {first_ts} and {last_ts} "
        f"because a submission marker file already existed (routine monitoring behavior, not an error)."
    ]


def summarize_submission(entries: list[dict]) -> list[str]:
    """Parse the 'Submitted N startdates' line into a readable summary."""
    bullets = []
    for e in entries:
        msg = e["msg"]
        n_match = re.search(r"Submitted (\d+) startdates", msg)
        clim_match = re.search(r"Climatological start-date:\s*(\S+)", msg)
        submittable_match = re.search(r"Submittable\s+(\d+)", msg)
        skipped_match = re.search(r"Total skipped\s+(\d+)", msg)
        bullets.append(f"At {e['ts']}: {n_match.group(1) if n_match else '?'} startdates submitted.")
        if clim_match:
            bullets.append(f"Climatological start-date: {clim_match.group(1)}")
        if submittable_match:
            bullets.append(f"Submittable: {submittable_match.group(1)}")
        if skipped_match:
            bullets.append(f"Total skipped: {skipped_match.group(1)}")
    return bullets


def summarize_recover(entries: list[dict]) -> list[str]:
    bullets = []
    for e in entries:
        file_match = re.search(r"(sps4_forecast_recover0_list\.\S+)", e["msg"])
        fname = file_match.group(1) if file_match else "details attached"
        bullets.append(f"{e['ts']}: recovery started — see {fname}")
    return bullets


def summarize_diagnostics(entries: list[dict]) -> list[str]:
    bullets = []
    for e in entries:
        bullets.append(f"{e['ts']}: {e['msg']}")
    return bullets


def build_progress_table(entries: list[dict]):
    """Build a Table flowable showing month-by-month completion progress over time."""
    rows = [["Date", "Time", "Month 1", "Month 2", "Month 3", "Month 4"]]
    for e in entries:
        counts = {m: "-" for m in range(1, 5)}
        for month_str, count_str in re.findall(r"month (\d+) is (\d+)", e["msg"]):
            counts[int(month_str)] = count_str
        # ts format: "Thu Jul  2 00:04:08 CEST 2026" -> split into date part and time part
        parts = e["ts"].split()
        date_part = f"{parts[0]} {parts[1]} {parts[2]}"  # "Thu Jul 2"
        time_part = parts[3]  # "00:04:08"
        rows.append([date_part, time_part, counts[1], counts[2], counts[3], counts[4]])
    return rows


def render_pdf(sections: "OrderedDict[str, list]", output_path: str, title: str, source_file: str) -> None:
    doc = SimpleDocTemplate(
        output_path, pagesize=letter,
        topMargin=0.8 * inch, bottomMargin=0.8 * inch,
        leftMargin=0.8 * inch, rightMargin=0.8 * inch,
    )
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("ReportTitle", parent=styles["Title"], fontSize=20, spaceAfter=6)
    subtitle_style = ParagraphStyle("Subtitle", parent=styles["Normal"], fontSize=10, textColor=colors.grey, spaceAfter=18)
    heading_style = ParagraphStyle("SectionHeading", parent=styles["Heading2"], spaceBefore=16, spaceAfter=6)
    body_style = ParagraphStyle("Body", parent=styles["Normal"], fontSize=10.5, leading=15, alignment=TA_LEFT)
    note_style = ParagraphStyle("Note", parent=styles["Normal"], fontSize=9.5, leading=13, textColor=colors.HexColor("#555555"))

    story = [
        Paragraph(title, title_style),
        Paragraph(f"Source log: {source_file}", subtitle_style),
    ]

    total_events = sum(len(v) for v in sections.values())
    overview_items = [f"{name}: {len(items)} event(s)" for name, items in sections.items() if items]
    story.append(Paragraph("Run Overview", heading_style))
    story.append(Paragraph(f"Total log lines parsed: {total_events}", body_style))
    story.append(ListFlowable(
        [ListItem(Paragraph(i, body_style)) for i in overview_items],
        bulletType="bullet", leftIndent=18, spaceBefore=4
    ))

    for name, entries in sections.items():
        if not entries:
            continue
        story.append(Paragraph(name, heading_style))

        if name == "IC Production":
            bullets = summarize_ic_production(entries)
        elif name == "Resubmission Pings":
            bullets = summarize_pings(entries)
        elif name == "Forecast Submission":
            bullets = summarize_submission(entries)
        elif name == "Recovery Events":
            bullets = summarize_recover(entries)
        elif name == "Diagnostics":
            bullets = summarize_diagnostics(entries)
        elif name == "Forecast Progress":
            rows = build_progress_table(entries)
            table = Table(rows, hAlign="LEFT", colWidths=[0.9 * inch, 0.7 * inch] + [0.85 * inch] * 4)
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2d2d2d")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#cccccc")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f4f4f4")]),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ]))
            story.append(table)
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                "Each row shows a snapshot in time of how many ensemble members had "
                "completed each forecast month so far.", note_style
            ))
            continue
        else:
            bullets = [f"{e['ts']}: {e['msg']}" for e in entries]

        story.append(ListFlowable(
            [ListItem(Paragraph(b, body_style)) for b in bullets],
            bulletType="bullet", leftIndent=18, spaceBefore=4, spaceAfter=4
        ))

    doc.build(story)


def main():
    parser = argparse.ArgumentParser(description="Parse a CMCC/Leonardo forecast log into a readable PDF report.")
    parser.add_argument("input", help="Path to the log .txt file.")
    parser.add_argument("-o", "--output", default="log_report.pdf", help="Output PDF path.")
    parser.add_argument("-t", "--title", default="Forecast Run Report", help="Report title.")
    args = parser.parse_args()

    try:
        entries = parse_log(args.input)
    except FileNotFoundError:
        print(f"Error: could not find input file '{args.input}'", file=sys.stderr)
        sys.exit(1)

    if not entries:
        print("Error: no parseable log entries found.", file=sys.stderr)
        sys.exit(1)

    sections = classify(entries)
    render_pdf(sections, args.output, args.title, source_file=args.input.split("/")[-1])
    print(f"Report written to {args.output} ({len(entries)} log entries parsed).")


if __name__ == "__main__":
    main()
