from __future__ import annotations

import json
from types import SimpleNamespace
from unittest import mock

from python.cli import main as cli_main


def test_cmd_create_token_invokes_snow_cli() -> None:
    # Given run_sql returns success
    run_result = cli_main.snow_cli.SnowCommandResult(
        command=["snow", "sql", "-f", "script.sql"],
        returncode=0,
        stdout="ok",
        stderr="",
    )
    with mock.patch(
        "python.cli.main.snow_cli.run_sql", return_value=run_result
    ) as run_mock:
        # When executing the create-token command
        args = SimpleNamespace(profile="demo", dry_run=False, verbose=False)
        rc = cli_main.cmd_create_token(args)

    # Then the Snow CLI wrapper is invoked with the expected script
    run_mock.assert_called_once()
    assert rc == 0


def test_cmd_test_connection_prints_summary(capsys) -> None:
    # Given verification returns a successful response
    verification_result = cli_main.verification.VerificationResult(
        ssl_valid=True,
        http_status=200,
        response_text='{"result":"ok"}',
        error=None,
    )
    with mock.patch(
        "python.cli.main.verification.test_connection", return_value=verification_result
    ):
        # When running the test command
        args = SimpleNamespace(
            url="https://example",
            hostname="example.snowflakecomputing.com",
            token="abc123",
            config=None,
            server_key="Snowflake",
        )
        rc = cli_main.cmd_test_connection(args)

    # Then a JSON summary is printed
    captured = capsys.readouterr()
    payload = json.loads(captured.out)
    assert payload["http_status"] == 200
    assert rc == 0


def test_cmd_master_runs_all_steps(monkeypatch) -> None:
    # Given create-token and setup-mcp succeed
    monkeypatch.setattr(cli_main, "cmd_create_token", lambda args: 0)
    monkeypatch.setattr(cli_main, "cmd_setup_mcp", lambda args: 0)
    monkeypatch.setattr(cli_main, "cmd_test_connection", lambda args: 0)

    # When running master workflow
    args = SimpleNamespace(
        profile="demo",
        dry_run=False,
        verbose=False,
        skip_test=False,
        url="https://example/api",
        hostname="example.snowflakecomputing.com",
        token=None,
        config=None,
        server_key="Snowflake",
    )
    rc = cli_main.cmd_master(args)

    # Then the workflow completes successfully
    assert rc == 0


def test_main_dispatches_to_subcommand(monkeypatch) -> None:
    # Given the create-token command is selected
    monkeypatch.setattr(cli_main, "build_parser", cli_main.build_parser)
    monkeypatch.setattr(
        cli_main.snow_cli,
        "run_sql",
        lambda *args, **kwargs: cli_main.snow_cli.SnowCommandResult([], 0, "", ""),
    )

    # When invoking main
    rc = cli_main.main(["create-token", "--dry-run"])

    # Then execution succeeds
    assert rc == 0
