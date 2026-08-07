---
name: office-documents
description: Use when creating, reading, editing, formatting, exporting, or converting DOCX, XLSX, or PPTX files. Route Office document work through the local office-mcp tools.
---

# Office Documents

Use the local `office-mcp` tools for `.docx`, `.xlsx`, and `.pptx` work.

## Workflow

1. Confirm the input and output paths. Relative paths resolve under `C:/Users/tc_tseng/Documents` unless the tool call supplies a folder.
2. Inspect an existing document before changing it with `get_document_info` and the format-specific read/list tool.
3. For new documents, use a new explicit output path. Creation tools refuse overwrites; do not delete or overwrite a file to work around that safeguard.
4. Apply the smallest set of format-specific changes. Validate the result by reading its relevant paragraphs, cells, or slides.
5. Report the produced path and any limitation.

## Export Limits

- DOCX to HTML works without LibreOffice.
- PDF export and XLSX/PPTX HTML export require LibreOffice 7+.
- If an export fails with `ERR_LIBREOFFICE_MISSING`, report the missing local prerequisite. Do not silently substitute a paid or cloud service.

## Safety

- Treat user documents as local data; do not upload them to a third-party service.
- Do not modify a document until the requested target is unambiguous.
- For destructive requests such as deleting sheets or slides, state the affected item and follow the normal approval policy.
