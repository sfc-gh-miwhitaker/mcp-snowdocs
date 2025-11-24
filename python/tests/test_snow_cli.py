from __future__ import annotations

from pathlib import Path
from unittest import mock

from python.services import snow_cli


def test_build_command_with_profile_and_variables(tmp_path: Path) -> None:
    # Given a SQL script on disk
    script = tmp_path / "script.sql"
    script.write_text("SELECT 1;")

    # When building the Snow CLI command
    command = snow_cli.build_command(
        script_path=script,
        profile="demo",
        variables={"TOKEN": "abc123"},
        extra_args=["--format", "json"],
    )

    # Then the command includes the profile, variables, and extras
    assert command == [
        "snow",
        "sql",
        "-f",
        str(script),
        "--profile",
        "demo",
        "--variable",
        "TOKEN=abc123",
        "--format",
        "json",
    ]


def test_run_sql_supports_dry_run(tmp_path: Path) -> None:
    # Given a repository with a SQL script
    repo_root = tmp_path
    script_rel = "sql/01_setup/sample.sql"
    script_path = repo_root / script_rel
    script_path.parent.mkdir(parents=True, exist_ok=True)
    script_path.write_text("SELECT 1;")

    # When running in dry-run mode
    with mock.patch("python.services.snow_cli.project_root", return_value=repo_root):
        result = snow_cli.run_sql(script_rel, profile=None, dry_run=True)

    # Then the command is returned without execution
    assert result.returncode == 0
    assert result.command[:4] == ["snow", "sql", "-f", str(script_path)]


def test_run_sql_invokes_subprocess(tmp_path: Path) -> None:
    # Given a repository with a SQL script
    repo_root = tmp_path
    script_rel = "sql/01_setup/sample.sql"
    script_path = repo_root / script_rel
    script_path.parent.mkdir(parents=True, exist_ok=True)
    script_path.write_text("SELECT 1;")

    # And subprocess.run is patched
    completed_process = mock.Mock(returncode=0, stdout="ok", stderr="")
    with mock.patch(
        "python.services.snow_cli.project_root", return_value=repo_root
    ), mock.patch(
        "subprocess.run",
        return_value=completed_process,
    ) as run_mock:
        # When executing the script
        result = snow_cli.run_sql(script_rel, profile="demo", dry_run=False)

    # Then subprocess.run is called with the expected command
    run_mock.assert_called_once()
    assert result.returncode == 0
    assert result.stdout == "ok"
