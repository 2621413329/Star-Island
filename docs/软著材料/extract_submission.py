#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从完整文档中提取交存用前30页+后30页，并重排连续页码为1-60"""

import re

SRC = "/workspace/docs/软著材料/文档鉴别材料_模板.txt"
DST = "/workspace/docs/软著材料/文档鉴别材料_交存版_前30后30.txt"

HEADER_RE = re.compile(
    r"(─{64}\n.*第 \d+ 页\n─{64}\n)",
    re.MULTILINE,
)


def split_pages(text: str) -> list[str]:
    # 跳过文首排版说明，从第一页页眉开始
    m = re.search(r"─{64}\n.*第 1 页\n─{64}", text)
    if not m:
        return []
    body = text[m.start() :]
    # 去掉文末统计信息
    tail = body.rfind("=" * 64)
    if tail > 0:
        body = body[:tail]

    parts = HEADER_RE.split(body)
    pages: list[str] = []
    i = 1
    while i < len(parts):
        if HEADER_RE.match(parts[i] + (parts[i + 1] if i + 1 < len(parts) else "")):
            header = parts[i]
            content = parts[i + 1] if i + 1 < len(parts) else ""
            pages.append((header + content).rstrip())
            i += 2
        else:
            i += 1
    return pages


def renumber(page: str, new_num: int, software: str, version: str) -> str:
    title = f"{software}  {version}"
    right = f"第 {new_num} 页"
    pad = 64 - len(title) - len(right)
    if pad < 2:
        pad = 2
    new_header_line = title + " " * pad + right
    return re.sub(
        r"─{64}\n.*第 \d+ 页\n─{64}",
        f"{'─' * 64}\n{new_header_line}\n{'─' * 64}",
        page,
        count=1,
    )


def main():
    with open(SRC, encoding="utf-8") as f:
        text = f.read()
    pages = split_pages(text)
    total = len(pages)
    print(f"Total pages in source: {total}")

    if total < 60:
        selected = pages
        note = f"全文共 {total} 页，不足 60 页，交存全部内容。"
    else:
        selected = pages[:30] + pages[-30:]
        note = f"交存页：原第1-30页 + 原第{total-29}-{total}页，合并重排为60页。"

    software = "【软件全称】"
    version = "【版本号，如 V1.0】"

    lines = [
        "=" * 64,
        "  软件著作权登记 — 文档鉴别材料（交存合并版）",
        f"  {note}",
        "=" * 64,
        "",
    ]
    for i, p in enumerate(selected, 1):
        lines.append(renumber(p, i, software, version))
        lines.append("")

    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Written {len(selected)} pages -> {DST}")


if __name__ == "__main__":
    main()
