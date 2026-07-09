#!/usr/bin/env python3
"""EPUB extraction helper: metadata, chapter listing, and chapter-to-Markdown export.

Usage:
    python epub_extract.py info <book.epub>
    python epub_extract.py list <book.epub>
    python epub_extract.py extract <book.epub> --chapter <index> [--out <file>]
    python epub_extract.py extract <book.epub> --all [--out-dir <dir>]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import ebooklib
from bs4 import BeautifulSoup
from ebooklib import epub


def load_book(path: str) -> epub.EpubBook:
    return epub.read_epub(path)


def get_metadata(book: epub.EpubBook) -> dict[str, str | None]:
    def first(field: str) -> str | None:
        values = book.get_metadata("DC", field)
        return values[0][0] if values else None

    return {
        "title": first("title"),
        "author": first("creator"),
        "language": first("language"),
        "publisher": first("publisher"),
    }


def extract_title(soup: BeautifulSoup) -> str | None:
    for tag in ("h1", "h2", "title"):
        found = soup.find(tag)
        if found and found.get_text(strip=True):
            return found.get_text(strip=True)
    return None


def get_chapters(book: epub.EpubBook) -> list[dict]:
    """Return spine-ordered chapter list: index, id, title, and the source item."""
    chapters = []
    for index, (item_id, _linear) in enumerate(book.spine):
        item = book.get_item_with_id(item_id)
        if item is None or item.get_type() != ebooklib.ITEM_DOCUMENT:
            continue
        soup = BeautifulSoup(item.get_content(), "html.parser")
        title = extract_title(soup) or item.get_name()
        chapters.append({"index": index, "id": item_id, "title": title, "item": item})
    return chapters


def html_to_markdown(html: bytes) -> str:
    """Rough HTML -> Markdown: headings, paragraphs, list items, blockquotes, in reading order."""
    soup = BeautifulSoup(html, "html.parser")
    prefixes = {"h1": "# ", "h2": "## ", "h3": "### ", "h4": "#### ", "li": "- ", "blockquote": "> "}
    lines = []
    for el in soup.find_all(list(prefixes) + ["p"]):
        text = el.get_text(strip=True)
        if text:
            lines.append(prefixes.get(el.name, "") + text)
    return "\n\n".join(lines)


def sanitize_filename(name: str) -> str:
    keep_chars = "-_.() "
    cleaned = "".join(ch if ch.isalnum() or ch in keep_chars else "_" for ch in name)
    return cleaned.strip()[:80] or "untitled"


def cmd_info(args: argparse.Namespace) -> None:
    book = load_book(args.path)
    meta = get_metadata(book)
    chapter_count = len(get_chapters(book))
    print(f"Title:      {meta['title']}")
    print(f"Author:     {meta['author']}")
    print(f"Language:   {meta['language']}")
    print(f"Publisher:  {meta['publisher']}")
    print(f"Chapters:   {chapter_count}")


def cmd_list(args: argparse.Namespace) -> None:
    book = load_book(args.path)
    for chapter in get_chapters(book):
        print(f"[{chapter['index']:>3}] {chapter['title']}  ({chapter['id']})")


def write_chapter(chapter: dict, out_path: Path) -> None:
    markdown = html_to_markdown(chapter["item"].get_content())
    out_path.write_text(markdown, encoding="utf-8")


def cmd_extract(args: argparse.Namespace) -> None:
    book = load_book(args.path)
    chapters = get_chapters(book)

    if args.all:
        out_dir = Path(args.out_dir or "epub_chapters")
        out_dir.mkdir(parents=True, exist_ok=True)
        for chapter in chapters:
            out_path = out_dir / f"{chapter['index']:03d}_{sanitize_filename(chapter['title'])}.md"
            write_chapter(chapter, out_path)
            print(f"Wrote {out_path}")
        return

    matches = [c for c in chapters if c["index"] == args.chapter]
    if not matches:
        print(f"No chapter found at index {args.chapter}. Run `list` to see valid indices.", file=sys.stderr)
        sys.exit(1)

    chapter = matches[0]
    if args.out:
        write_chapter(chapter, Path(args.out))
        print(f"Wrote {args.out}")
    else:
        print(html_to_markdown(chapter["item"].get_content()))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="EPUB extraction helper")
    sub = parser.add_subparsers(dest="command", required=True)

    p_info = sub.add_parser("info", help="Show book metadata and chapter count")
    p_info.add_argument("path")
    p_info.set_defaults(func=cmd_info)

    p_list = sub.add_parser("list", help="List chapters in reading (spine) order")
    p_list.add_argument("path")
    p_list.set_defaults(func=cmd_list)

    p_extract = sub.add_parser("extract", help="Extract chapter(s) to Markdown")
    p_extract.add_argument("path")
    p_extract.add_argument("--chapter", type=int, help="Chapter index from `list`")
    p_extract.add_argument("--all", action="store_true", help="Extract every chapter")
    p_extract.add_argument("--out", help="Output file (single-chapter mode)")
    p_extract.add_argument("--out-dir", help="Output directory (--all mode, default: epub_chapters)")
    p_extract.set_defaults(func=cmd_extract)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "extract" and not args.all and args.chapter is None:
        parser.error("extract requires --chapter <index> or --all")
    try:
        args.func(args)
    except Exception as error:  # noqa: BLE001 - CLI boundary: report and exit cleanly
        print(f"Failed to process '{args.path}': {error}", file=sys.stderr)
        print(
            "This EPUB may have non-standard/malformed metadata that ebooklib can't parse. "
            "Fallback: use the markitdown MCP tool's convert_to_markdown(uri) instead.",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
