#!/usr/bin/env python3
"""PDF extraction helper: page/metadata info, page-range text, and page-range table export.

Usage:
    python pdf_extract.py info <book.pdf>
    python pdf_extract.py text <book.pdf> [--start N] [--end N] [--out <file>]
    python pdf_extract.py tables <book.pdf> [--start N] [--end N] [--out-dir <dir>]

Page numbers for --start/--end are 1-indexed and inclusive on both ends.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import fitz  # pymupdf
import pdfplumber


def resolve_range(start: int | None, end: int | None, page_count: int) -> tuple[int, int]:
    """Convert 1-indexed inclusive --start/--end into a 0-indexed [lo, hi) range."""
    lo = max((start - 1) if start else 0, 0)
    hi = min(end if end else page_count, page_count)
    if lo >= hi:
        raise ValueError(f"Empty page range: start={start}, end={end}, page_count={page_count}")
    return lo, hi


def cmd_info(args: argparse.Namespace) -> None:
    with fitz.open(args.path) as doc:
        meta = doc.metadata
        print(f"Pages:      {doc.page_count}")
        print(f"Title:      {meta.get('title') or '-'}")
        print(f"Author:     {meta.get('author') or '-'}")
        print(f"Encrypted:  {doc.is_encrypted}")


def cmd_text(args: argparse.Namespace) -> None:
    with fitz.open(args.path) as doc:
        lo, hi = resolve_range(args.start, args.end, doc.page_count)
        pages = [doc[i].get_text() for i in range(lo, hi)]

    output = "\n\n---\n\n".join(pages)
    if args.out:
        Path(args.out).write_text(output, encoding="utf-8")
        print(f"Wrote {args.out} ({hi - lo} pages)")
    else:
        print(output)


def table_to_markdown(table: list[list[str | None]]) -> str:
    rows = [[cell or "" for cell in row] for row in table]
    header, *body = rows
    lines = ["| " + " | ".join(header) + " |", "| " + " | ".join(["---"] * len(header)) + " |"]
    lines += ["| " + " | ".join(row) + " |" for row in body]
    return "\n".join(lines)


def is_real_table(table: list[list[str | None]]) -> bool:
    """Filter out single-column false positives from pdfplumber's heuristic detector,
    which sometimes mistakes justified paragraph text for a one-column table."""
    return bool(table) and bool(table[0]) and len(table[0]) >= 2


def cmd_tables(args: argparse.Namespace) -> None:
    out_dir = Path(args.out_dir or "pdf_tables")
    found = 0
    with pdfplumber.open(args.path) as pdf:
        lo, hi = resolve_range(args.start, args.end, len(pdf.pages))
        for page_index in range(lo, hi):
            for table_index, table in enumerate(pdf.pages[page_index].extract_tables()):
                if not is_real_table(table):
                    continue
                found += 1
                out_dir.mkdir(parents=True, exist_ok=True)
                out_path = out_dir / f"page{page_index + 1:03d}_table{table_index + 1}.md"
                out_path.write_text(table_to_markdown(table), encoding="utf-8")
                print(f"Wrote {out_path}")

    if found == 0:
        print("No tables found in range", file=sys.stderr)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="PDF extraction helper")
    sub = parser.add_subparsers(dest="command", required=True)

    p_info = sub.add_parser("info", help="Show page count, metadata, encryption status")
    p_info.add_argument("path")
    p_info.set_defaults(func=cmd_info)

    p_text = sub.add_parser("text", help="Extract text from a page range")
    p_text.add_argument("path")
    p_text.add_argument("--start", type=int, help="First page, 1-indexed (default: 1)")
    p_text.add_argument("--end", type=int, help="Last page, inclusive (default: last page)")
    p_text.add_argument("--out", help="Output file")
    p_text.set_defaults(func=cmd_text)

    p_tables = sub.add_parser("tables", help="Extract tables from a page range as Markdown")
    p_tables.add_argument("path")
    p_tables.add_argument("--start", type=int, help="First page, 1-indexed (default: 1)")
    p_tables.add_argument("--end", type=int, help="Last page, inclusive (default: last page)")
    p_tables.add_argument("--out-dir", help="Output directory (default: pdf_tables)")
    p_tables.set_defaults(func=cmd_tables)

    return parser


def main() -> None:
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
