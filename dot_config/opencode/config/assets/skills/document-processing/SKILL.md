---
name: document-processing
description: Process, convert, and extract content from EPUB and PDF files — e-books, manuals, reports, papers. Use this whenever the user mentions EPUB, PDF, 電子書, 電子書轉換, 章節擷取, 目錄/TOC, 頁碼範圍, 表格擷取, or asks to read/summarize/convert/analyze a book or PDF file, even if they don't say "convert to markdown" explicitly. Also trigger for batch chapter export, page-range text extraction, and PDF table extraction.
---

# Document Processing (EPUB / PDF)

## Decision tree

1. **Need the whole document as readable Markdown, fast?**
   Use the `markitdown` MCP tool's `convert_to_markdown(uri)`, where `uri` is a `file:///absolute/path/to/book.epub` (or `.pdf`) URI. This is the fastest path and works for both formats natively — try this first for "summarize this book" / "convert this PDF" style requests.

2. **Need something markitdown can't give you** — a specific chapter, a page range, a table, book metadata/TOC, or batch-exporting every chapter as a separate file?
   Use the bundled scripts below. Only read the script for the format you actually need — don't load both up front.

Both scripts are plain Python CLIs (argparse), UTF-8 safe end-to-end, and designed for direct `Bash` invocation.

## EPUB — `scripts/epub_extract.py`

Requires `ebooklib` + `beautifulsoup4` (already installed as part of this skill's setup; if missing: `pip install ebooklib beautifulsoup4`).

```bash
python scripts/epub_extract.py info <book.epub>                          # title, author, language, chapter count
python scripts/epub_extract.py list <book.epub>                          # numbered chapter list (index + title)
python scripts/epub_extract.py extract <book.epub> --chapter 3 --out chapter3.md
python scripts/epub_extract.py extract <book.epub> --all --out-dir chapters/
```

Always run `list` first if you don't already know the chapter index — chapter numbering follows the EPUB's spine (reading order), not the filename or the printed table of contents.

## PDF — `scripts/pdf_extract.py`

Requires `pymupdf` + `pdfplumber` (already installed; if missing: `pip install pymupdf pdfplumber`).

```bash
python scripts/pdf_extract.py info <book.pdf>                                        # page count, metadata, encryption status
python scripts/pdf_extract.py text <book.pdf> --start 5 --end 12 --out excerpt.md    # 1-indexed, inclusive on both ends
python scripts/pdf_extract.py tables <book.pdf> --start 1 --end 20 --out-dir tables/
```

Omit `--start`/`--end` to process the whole document. Page numbers are **1-indexed and inclusive**, matching how humans refer to page numbers (not pymupdf's internal 0-indexing) — page 5 to page 12 means exactly pages 5–12.

## Practical notes

- **Scanned/image-only PDFs**: none of the above extract real text (no OCR involved). If `pdf_extract.py text` returns empty or garbled output, the PDF is likely scanned images — fall back to `markitdown` with an LLM vision client configured, or `ocrmypdf` if installed on the system.
- **Large books**: prefer `extract --all` (EPUB) or a bounded `--start`/`--end` range (PDF) over pulling an entire long book into context at once. Write to files and read the results selectively.
- **Chinese/CJK content**: both scripts are UTF-8 safe throughout; chapter-title-derived filenames keep CJK characters as-is rather than transliterating or stripping them.
- **Encrypted PDFs**: `pdf_extract.py info` reports `Encrypted: True`. Password-protected PDFs are not currently supported by these scripts — ask the user for the password before attempting further extraction, and extend `pdf_extract.py` with `fitz.Document.authenticate()` if this becomes a recurring need.
- **Tables that come back empty**: `pdfplumber`'s table detection relies on visible grid lines or consistent whitespace alignment; borderless tables sometimes aren't detected, and `pdf_extract.py` deliberately filters out single-column "tables" (a common false positive where justified paragraph text gets misread as a one-column table). If `tables` reports "No tables found" but you can see a real table visually, try `text` on that page range and parse it manually instead.
- **Malformed EPUBs**: some EPUBs (especially ones from informal scanning/conversion tools) have non-standard OPF metadata that `ebooklib` can't parse. `epub_extract.py` catches this and reports a clear error instead of a stack trace — when this happens, fall back to the `markitdown` MCP tool, which is more tolerant of malformed files.
