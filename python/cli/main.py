from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Optional, Sequence

from python.services import snow_cli, verification


def _print_command_result(result: snow_cli.SnowCommandResult, verbose: bool) -> None:
    if verbose or result.returncode != 0:
        print("Command:", " ".join(result.command))
        print("Return code:", result.returncode)
        if result.stdout:
            print("stdout:")
            print(result.stdout)
        if result.stderr:
            print("stderr:")
            print(result.stderr, file=sys.stderr)
    else:
        print("Command executed successfully.")


def cmd_create_token(args: argparse.Namespace) -> int:
    result = snow_cli.run_sql(
        "sql/01_setup/create_token.sql",
        profile=args.profile,
        dry_run=args.dry_run,
    )
    _print_command_result(result, verbose=args.verbose)
    return result.returncode


def cmd_setup_mcp(args: argparse.Namespace) -> int:
    result = snow_cli.run_sql(
        "sql/01_setup/setup_mcp.sql",
        profile=args.profile,
        dry_run=args.dry_run,
    )
    _print_command_result(result, verbose=args.verbose)
    return result.returncode


def cmd_test_connection(args: argparse.Namespace) -> int:
    config_path = Path(args.config).expanduser() if args.config else None
    outcome = verification.test_connection(
        url=args.url,
        hostname=args.hostname,
        token=args.token,
        config_path=config_path,
        server_key=args.server_key,
    )

    summary = {
        "ssl_valid": outcome.ssl_valid,
        "http_status": outcome.http_status,
        "error": outcome.error,
        "response": outcome.response_text,
    }
    print(json.dumps(summary, indent=2))

    return 0 if outcome.error is None else 1


def cmd_master(args: argparse.Namespace) -> int:
    print("Running create-token module...")
    create_rc = cmd_create_token(args)
    if create_rc != 0:
        print("create-token failed; aborting master workflow.", file=sys.stderr)
        return create_rc

    print("Running setup-mcp module...")
    setup_rc = cmd_setup_mcp(args)
    if setup_rc != 0:
        print("setup-mcp failed; aborting master workflow.", file=sys.stderr)
        return setup_rc

    if args.skip_test:
        print("Skipping test-connection as requested.")
        return 0

    if not args.url:
        print(
            "Master workflow requires --url when running verification.", file=sys.stderr
        )
        return 1

    print("Running test-connection module...")
    test_args = argparse.Namespace(
        url=args.url,
        hostname=args.hostname,
        token=args.token,
        config=args.config,
        server_key=args.server_key,
    )
    return cmd_test_connection(test_args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m python.cli.main",
        description="Snowflake MCP automation toolkit.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    common_snow = argparse.ArgumentParser(add_help=False)
    common_snow.add_argument("--profile", help="Snow CLI profile name to use.")
    common_snow.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the Snow CLI command without executing it.",
    )
    common_snow.add_argument(
        "--verbose",
        action="store_true",
        help="Print stdout/stderr even when the command succeeds.",
    )

    create_parser = subparsers.add_parser(
        "create-token",
        parents=[common_snow],
        help="Generate a programmatic access token scoped to the MCP role.",
    )
    create_parser.set_defaults(func=cmd_create_token)

    setup_parser = subparsers.add_parser(
        "setup-mcp",
        parents=[common_snow],
        help="Provision the MCP server and apply least-privilege grants.",
    )
    setup_parser.set_defaults(func=cmd_setup_mcp)

    test_parser = subparsers.add_parser(
        "test-connection",
        help="Validate SSL trust and send an initialize request to the MCP endpoint.",
    )
    test_parser.add_argument("--url", required=True, help="MCP server URL.")
    test_parser.add_argument(
        "--hostname",
        help="Hostname used for SSL validation (org-account.snowflakecomputing.com).",
    )
    test_parser.add_argument(
        "--token",
        help="Bearer token to use. If omitted, reads from configuration.",
    )
    test_parser.add_argument(
        "--config",
        help="Path to MCP configuration file (defaults to ~/.cursor/mcp.json).",
    )
    test_parser.add_argument(
        "--server-key",
        default=verification.DEFAULT_SERVER_KEY,
        help="Server key within the configuration file (default: Snowflake).",
    )
    test_parser.set_defaults(func=cmd_test_connection)

    master_parser = subparsers.add_parser(
        "master",
        parents=[common_snow],
        help="Run the end-to-end workflow (create-token, setup-mcp, test-connection).",
    )
    master_parser.add_argument(
        "--url",
        help="MCP server URL used for the verification step.",
    )
    master_parser.add_argument(
        "--hostname",
        help="Hostname used for SSL validation during verification.",
    )
    master_parser.add_argument(
        "--token",
        help="Bearer token. If omitted, the test step reads from configuration.",
    )
    master_parser.add_argument(
        "--config",
        help="Path to MCP configuration file.",
    )
    master_parser.add_argument(
        "--server-key",
        default=verification.DEFAULT_SERVER_KEY,
        help="Server key within the configuration file.",
    )
    master_parser.add_argument(
        "--skip-test",
        action="store_true",
        help="Skip the final verification step.",
    )
    master_parser.set_defaults(func=cmd_master)

    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
