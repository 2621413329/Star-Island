#!/usr/bin/env python3
"""
生成中国版权保护中心「程序鉴别材料（一般交存）」源代码文档。

规则：
- 源码总页数 < 60 页时输出全部；否则输出开头连续 30 页 + 末尾连续 30 页
- 每页正文（代码区）不少于 LINES_PER_PAGE 行（注释、空行均计入）
- 页眉：软件全称 + 版本号；右上角阿拉伯数字连续页码
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

LINES_PER_PAGE = 50

# 按模块分层顺序收集源文件时的排除规则
DEFAULT_EXCLUDE_DIRS = {
    ".git",
    ".venv",
    "node_modules",
    ".dart_tool",
    "build",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    "tests",
    "test",
}

DEFAULT_EXCLUDE_SUFFIXES = {
    ".pyc",
    ".pyo",
    ".pyd",
}


def collect_source_files(
    roots: list[Path],
    extensions: set[str],
    *,
    include_tests: bool = False,
) -> list[Path]:
    """按路径字典序收集源文件，保证模块分层清晰、顺序稳定。"""
    files: list[Path] = []
    exclude_dirs = set(DEFAULT_EXCLUDE_DIRS)
    if include_tests:
        exclude_dirs -= {"tests", "test"}

    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            if path.suffix.lower() not in extensions:
                continue
            if path.suffix.lower() in DEFAULT_EXCLUDE_SUFFIXES:
                continue
            if any(part in exclude_dirs for part in path.parts):
                continue
            # 跳过常见生成文件
            name = path.name
            if any(
                name.endswith(suffix)
                for suffix in (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")
            ):
                continue
            files.append(path)

    # 全局去重并保持顺序
    seen: set[Path] = set()
    ordered: list[Path] = []
    for f in files:
        resolved = f.resolve()
        if resolved not in seen:
            seen.add(resolved)
            ordered.append(f)
    return ordered


def build_source_lines(files: list[Path], base_dir: Path) -> list[str]:
    """将多个源文件合并为连续行列表，文件之间插入分隔注释。"""
    lines: list[str] = []
    for file_path in files:
        rel = file_path.resolve().relative_to(base_dir.resolve())
        ext = file_path.suffix.lower()
        if ext == ".py":
            sep = f"# ---------- {rel.as_posix()} ----------"
        elif ext == ".dart":
            sep = f"// ---------- {rel.as_posix()} ----------"
        else:
            sep = f"/* ---------- {rel.as_posix()} ---------- */"

        if lines:
            lines.append("")
        lines.append(sep)
        try:
            content = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            content = file_path.read_text(encoding="utf-8", errors="replace")
        file_lines = content.splitlines()
        if file_lines:
            lines.extend(file_lines)
        else:
            lines.append("")
    return lines


def paginate_source_lines(source_lines: list[str], lines_per_page: int) -> list[list[str]]:
    """将源码行切分为页，每页恰好 lines_per_page 行。"""
    if not source_lines:
        return [[""] * lines_per_page]

    pages: list[list[str]] = []
    idx = 0
    total = len(source_lines)
    while idx < total:
        chunk = source_lines[idx : idx + lines_per_page]
        if len(chunk) < lines_per_page:
            chunk = chunk + [""] * (lines_per_page - len(chunk))
        pages.append(chunk)
        idx += lines_per_page
    return pages


def select_pages(all_pages: list[list[str]], head: int = 30, tail: int = 30) -> list[list[str]]:
    """选取前 head 页 + 后 tail 页；不足 head+tail 时返回全部。"""
    total = len(all_pages)
    if total <= head + tail:
        return all_pages
    return all_pages[:head] + all_pages[-tail:]


def format_page(
    page_num: int,
    body_lines: list[str],
    software_name: str,
    version: str,
    *,
    header_width: int = 78,
) -> str:
    """格式化单页文本：页眉 + 50 行代码正文。"""
    header_left = f"{software_name} {version}"
    # 右上角页码：用空格将页码推到行尾
    padding = max(1, header_width - len(header_left) - len(str(page_num)))
    header = f"{header_left}{' ' * padding}{page_num}"

    parts = [
        "",
        "=" * header_width,
        header,
        "=" * header_width,
        "",
    ]
    parts.extend(body_lines)
    return "\n".join(parts)


def generate_document(
    source_lines: list[str],
    software_name: str,
    version: str,
    *,
    lines_per_page: int = LINES_PER_PAGE,
) -> tuple[str, dict]:
    """生成完整文档文本及统计信息。"""
    all_pages = paginate_source_lines(source_lines, lines_per_page)
    selected = select_pages(all_pages)
    output_pages: list[str] = []

    for i, body in enumerate(selected, start=1):
        output_pages.append(
            format_page(i, body, software_name, version)
        )

    stats = {
        "source_lines": len(source_lines),
        "total_pages": len(all_pages),
        "output_pages": len(selected),
        "lines_per_page": lines_per_page,
        "truncated": len(all_pages) > len(selected),
    }
    document = "\n".join(output_pages)
    return document, stats


def resolve_preset(preset: str) -> tuple[list[Path], Path, set[str]]:
    """根据预设返回 (源目录列表, 相对路径基准, 扩展名)。"""
    workspace = Path(__file__).resolve().parent.parent
    presets = {
        "dart": (
            [workspace / "stday" / "lib"],
            workspace / "stday",
            {".dart"},
        ),
        "python": (
            [workspace / "backend" / "app"],
            workspace / "backend",
            {".py"},
        ),
        "full": (
            [
                workspace / "stday" / "lib",
                workspace / "backend" / "app",
            ],
            workspace,
            {".dart", ".py"},
        ),
    }
    if preset not in presets:
        raise ValueError(f"未知预设: {preset}，可选: {', '.join(presets)}")
    return presets[preset]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="生成软著程序鉴别材料（一般交存）源代码文档",
    )
    parser.add_argument(
        "--name",
        default="星屿温暖陪伴型成长记录软件",
        help="软件全称（页眉）",
    )
    parser.add_argument(
        "--version",
        default="V1.0.0",
        help="软件版本号（页眉，如 V1.0.0）",
    )
    parser.add_argument(
        "--preset",
        choices=["dart", "python", "full"],
        default="dart",
        help="源码范围预设：dart=Flutter客户端, python=后端, full=前后端合并",
    )
    parser.add_argument(
        "--source-dir",
        action="append",
        dest="source_dirs",
        help="自定义源目录（可多次指定，覆盖 --preset）",
    )
    parser.add_argument(
        "--ext",
        action="append",
        dest="extensions",
        help="自定义扩展名，如 .dart（可多次指定）",
    )
    parser.add_argument(
        "--include-tests",
        action="store_true",
        help="包含 tests 目录中的源文件",
    )
    parser.add_argument(
        "--lines-per-page",
        type=int,
        default=LINES_PER_PAGE,
        help=f"每页代码行数（默认 {LINES_PER_PAGE}，不少于 50）",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="输出文件路径（默认 softcopyright/程序鉴别材料_<preset>.txt）",
    )
    args = parser.parse_args()

    if args.lines_per_page < 50:
        print("错误：每页行数不得少于 50 行（版权中心要求）", file=sys.stderr)
        return 1

    workspace = Path(__file__).resolve().parent.parent

    if args.source_dirs:
        roots = [Path(p).resolve() for p in args.source_dirs]
        base_dir = roots[0].parent
        if args.extensions:
            extensions = {e if e.startswith(".") else f".{e}" for e in args.extensions}
        else:
            extensions = {".dart", ".py", ".js", ".ts", ".java", ".go"}
    else:
        roots, base_dir, extensions = resolve_preset(args.preset)

    files = collect_source_files(
        roots,
        extensions,
        include_tests=args.include_tests,
    )
    if not files:
        print("错误：未找到符合条件的源文件", file=sys.stderr)
        return 1

    source_lines = build_source_lines(files, base_dir)
    document, stats = generate_document(
        source_lines,
        args.name,
        args.version,
        lines_per_page=args.lines_per_page,
    )

    output_path = args.output
    if output_path is None:
        out_dir = workspace / "softcopyright"
        out_dir.mkdir(parents=True, exist_ok=True)
        safe_ver = args.version.replace(".", "_").replace(" ", "")
        output_path = out_dir / f"程序鉴别材料_{args.preset}_{safe_ver}.txt"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(document, encoding="utf-8")

    print(f"软件名称: {args.name}")
    print(f"版本号:   {args.version}")
    print(f"源文件数: {len(files)}")
    print(f"源码行数: {stats['source_lines']}")
    print(f"源码总页: {stats['total_pages']}（每页 {stats['lines_per_page']} 行）")
    if stats["truncated"]:
        print(f"输出页数: {stats['output_pages']}（前 30 页 + 后 30 页）")
    else:
        print(f"输出页数: {stats['output_pages']}（源码不足 60 页，已输出全部）")
    print(f"已写入:   {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
