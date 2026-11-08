r"""Thin CLI wrapper around the official Microsoft Learn MCP server, built on `fastmcp.Client`.

The server (https://learn.microsoft.com/api/mcp) needs no auth and exposes three
tools as of this writing: ``microsoft_docs_search``, ``microsoft_docs_fetch``,
``microsoft_code_sample_search``. This wrapper gives each a friendly subcommand,
plus a generic ``call`` passthrough (so a renamed/new tool never blocks usage)
and a ``tools`` subcommand that lists what the server currently advertises
instead of trusting a hardcoded list (the server's own docs warn tools can change).

Every subcommand supports ``--json``, which switches from human-readable stdout
to a single JSON object on stdout and skips any file writing -- the point being
to let this pipe into `jq` or another CLI for further reshaping, per the whole
reason this wrapper exists instead of just using the official Agent Skill.

PowerShell example:
    python .\.codex\skills\microsoft-learn\scripts\mslmcp_cli.py search "Azure Functions timeout"

bash example:
    python ./Azure/.codex/skills/microsoft-learn/scripts/mslmcp_cli.py fetch https://learn.microsoft.com/azure/azure-functions/functions-versions
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

EXIT_SUCCESS = 0
EXIT_RUNTIME_ERROR = 1
EXIT_TOOL_ERROR = 3
EXIT_EMPTY_RESULT = 4

DEFAULT_ENDPOINT = "https://learn.microsoft.com/api/mcp"
ENDPOINT_ENV = "MSLEARN_MCP_ENDPOINT"
OUTPUT_DIR_ENV = "MSLEARN_MCP_OUTPUT_DIR"
DEFAULT_OUTPUT_DIR = "temp/mslearn_mcp"
DEFAULT_TIMEOUT = 30.0

_SLUG_SEPARATOR = re.compile(r"[^\w]+", re.UNICODE)
_SEQUENCE_PREFIX = re.compile(r"^(\d{4})")
_MARKDOWN_TITLE = re.compile(r"^#\s+(.+)$", re.MULTILINE)


def build_endpoint(base: str, max_token_budget: int | None) -> str:
    """Append `?maxTokenBudget=N` (search-only, per the server's own docs) if set."""
    if max_token_budget is None:
        return base
    separator = "&" if "?" in base else "?"
    return f"{base}{separator}maxTokenBudget={max_token_budget}"


def resolve_endpoint(args: argparse.Namespace) -> str:
    base = args.endpoint or os.environ.get(ENDPOINT_ENV, "").strip() or DEFAULT_ENDPOINT
    return build_endpoint(base, getattr(args, "max_token_budget", None))


def _import_client():
    """Deferred import: keeps --help/argparse failures fast, and turns a missing
    fastmcp install into an actionable message instead of a bare ImportError."""
    try:
        from fastmcp import Client
    except ImportError as exc:
        raise ImportError(f"{exc}. Install with: pip install -e .") from exc
    return Client


async def _call_tool_async(endpoint: str, timeout: float, tool_name: str, arguments: dict[str, Any]):
    Client = _import_client()

    client = Client(endpoint, timeout=timeout)
    async with client:
        return await client.call_tool(tool_name, arguments, raise_on_error=False)


async def _list_tools_async(endpoint: str, timeout: float):
    Client = _import_client()

    client = Client(endpoint, timeout=timeout)
    async with client:
        return await client.list_tools()


def call_tool(endpoint: str, timeout: float, tool_name: str, arguments: dict[str, Any]):
    return asyncio.run(_call_tool_async(endpoint, timeout, tool_name, arguments))


def list_tools(endpoint: str, timeout: float):
    return asyncio.run(_list_tools_async(endpoint, timeout))


def content_text(result) -> str:
    """Concatenate any TextContent blocks in a CallToolResult (fetch has no structured_content)."""
    return "\n".join(block.text for block in result.content if hasattr(block, "text"))


def slugify(text: str | None, *, max_length: int = 50) -> str:
    lowered = (text or "").strip().lower()
    slug = _SLUG_SEPARATOR.sub("-", lowered).strip("-")
    if len(slug) > max_length:
        slug = slug[:max_length].rstrip("-")
    return slug or "item"


def get_output_dir() -> Path:
    value = os.environ.get(OUTPUT_DIR_ENV, "").strip()
    return Path(value or DEFAULT_OUTPUT_DIR)


def next_sequence(directory: Path) -> int:
    if not directory.exists():
        return 1
    highest = 0
    for entry in directory.iterdir():
        match = _SEQUENCE_PREFIX.match(entry.name)
        if match:
            highest = max(highest, int(match.group(1)))
    return highest + 1


def write_fetch_file(*, url: str, markdown: str) -> Path:
    title_match = _MARKDOWN_TITLE.search(markdown)
    title = title_match.group(1).strip() if title_match else url.rstrip("/").rsplit("/", 1)[-1]

    output_dir = get_output_dir()
    output_dir.mkdir(parents=True, exist_ok=True)
    sequence = next_sequence(output_dir)
    file_path = output_dir / f"{sequence:04d}-{slugify(title)}.md"
    file_path.write_text(markdown, encoding="utf-8")
    return file_path


def format_search_results(results: list[dict[str, Any]]) -> str:
    blocks = []
    for i, item in enumerate(results, start=1):
        blocks.append(
            f"## {i}. {item.get('title', '(untitled)')}\n"
            f"URL: {item.get('contentUrl', '')}\n\n"
            f"{item.get('content', '')}"
        )
    return "\n\n---\n\n".join(blocks)


def format_code_results(results: list[dict[str, Any]]) -> str:
    blocks = []
    for i, item in enumerate(results, start=1):
        language = item.get("language", "")
        blocks.append(
            f"## {i}. {item.get('description', '(no description)')}\n"
            f"Language: {language}\n"
            f"Link: {item.get('link', '')}\n\n"
            f"```{language}\n{item.get('codeSnippet', '')}\n```"
        )
    return "\n\n---\n\n".join(blocks)


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--json", action="store_true", help="Print a single JSON object to stdout instead of human-readable text (for piping into jq etc.); never writes a file.")
    parser.add_argument("--endpoint", help=f"Override the MCP endpoint (default: {ENDPOINT_ENV} env var, else {DEFAULT_ENDPOINT}).")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT, help=f"Request timeout in seconds (default: {DEFAULT_TIMEOUT}).")


def cmd_search(args: argparse.Namespace) -> int:
    endpoint = resolve_endpoint(args)
    result = call_tool(endpoint, args.timeout, "microsoft_docs_search", {"query": args.query})
    if result.is_error:
        print(f"microsoft_docs_search failed: {content_text(result)}", file=sys.stderr)
        return EXIT_TOOL_ERROR

    results = (result.structured_content or {}).get("results", [])
    if not results:
        print("No results.", file=sys.stderr)
        return EXIT_EMPTY_RESULT

    if args.json:
        print(json.dumps({"query": args.query, "results": results}, ensure_ascii=False, indent=2))
    else:
        print(format_search_results(results))
    return EXIT_SUCCESS


def cmd_code_search(args: argparse.Namespace) -> int:
    endpoint = resolve_endpoint(args)
    arguments: dict[str, Any] = {"query": args.query}
    if args.language:
        arguments["language"] = args.language

    result = call_tool(endpoint, args.timeout, "microsoft_code_sample_search", arguments)
    if result.is_error:
        print(f"microsoft_code_sample_search failed: {content_text(result)}", file=sys.stderr)
        return EXIT_TOOL_ERROR

    results = (result.structured_content or {}).get("results", [])
    if not results:
        print("No results.", file=sys.stderr)
        return EXIT_EMPTY_RESULT

    if args.json:
        print(json.dumps({"query": args.query, "language": args.language, "results": results}, ensure_ascii=False, indent=2))
    else:
        print(format_code_results(results))
    return EXIT_SUCCESS


def cmd_fetch(args: argparse.Namespace) -> int:
    endpoint = resolve_endpoint(args)
    result = call_tool(endpoint, args.timeout, "microsoft_docs_fetch", {"url": args.url})
    if result.is_error:
        print(f"microsoft_docs_fetch failed: {content_text(result)}", file=sys.stderr)
        return EXIT_TOOL_ERROR

    markdown = content_text(result)
    if not markdown.strip():
        print(f"Fetched empty content from {args.url}", file=sys.stderr)
        return EXIT_EMPTY_RESULT

    if args.json:
        print(json.dumps({"url": args.url, "content": markdown}, ensure_ascii=False))
    else:
        file_path = write_fetch_file(url=args.url, markdown=markdown)
        print(f"Wrote page content to {file_path}")
    return EXIT_SUCCESS


def cmd_tools(args: argparse.Namespace) -> int:
    endpoint = resolve_endpoint(args)
    tools = list_tools(endpoint, args.timeout)

    if args.json:
        print(json.dumps([t.model_dump(mode="json") for t in tools], ensure_ascii=False, indent=2))
        return EXIT_SUCCESS

    for tool in tools:
        print(f"## {tool.name}\n{tool.description or ''}\nSchema: {json.dumps(tool.inputSchema, ensure_ascii=False)}\n")
    return EXIT_SUCCESS


def cmd_call(args: argparse.Namespace) -> int:
    endpoint = resolve_endpoint(args)
    try:
        arguments = json.loads(args.args) if args.args else {}
    except json.JSONDecodeError as exc:
        print(f"--args is not valid JSON: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR

    result = call_tool(endpoint, args.timeout, args.tool_name, arguments)

    if args.json:
        print(json.dumps({
            "is_error": result.is_error,
            "structured_content": result.structured_content,
            "content_text": content_text(result),
        }, ensure_ascii=False, indent=2))
    else:
        print(content_text(result))

    return EXIT_TOOL_ERROR if result.is_error else EXIT_SUCCESS


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mslmcp",
        description="fastmcp-based CLI for the official Microsoft Learn MCP server.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_search = subparsers.add_parser("search", help="Semantic search over Microsoft/Azure docs.")
    p_search.add_argument("query")
    p_search.add_argument("--max-token-budget", type=int, help="Cap search-result token size (server-side; see maxTokenBudget in the MCP docs).")
    add_common_args(p_search)
    p_search.set_defaults(func=cmd_search)

    p_code = subparsers.add_parser("code-search", help="Search official Microsoft/Azure code samples.")
    p_code.add_argument("query")
    p_code.add_argument("--language", help="Restrict to one language, e.g. python, csharp, typescript.")
    p_code.add_argument("--max-token-budget", type=int, help="Cap search-result token size (server-side).")
    add_common_args(p_code)
    p_code.set_defaults(func=cmd_code_search)

    p_fetch = subparsers.add_parser("fetch", help="Fetch one Learn page as Markdown.")
    p_fetch.add_argument("url")
    add_common_args(p_fetch)
    p_fetch.set_defaults(func=cmd_fetch)

    p_tools = subparsers.add_parser("tools", help="List the tools the server currently advertises (not hardcoded).")
    add_common_args(p_tools)
    p_tools.set_defaults(func=cmd_tools)

    p_call = subparsers.add_parser("call", help="Call any tool by name directly (fallback for new/renamed tools).")
    p_call.add_argument("tool_name")
    p_call.add_argument("--args", help='Tool arguments as a JSON object, e.g. \'{"query": "..."}\'.')
    add_common_args(p_call)
    p_call.set_defaults(func=cmd_call)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        return args.func(args)
    except Exception as exc:  # connection/transport failures, ToolError, unexpected shapes
        print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR


if __name__ == "__main__":
    raise SystemExit(main())
