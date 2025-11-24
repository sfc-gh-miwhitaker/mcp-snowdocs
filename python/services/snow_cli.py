from __future__ import annotations

import shlex
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Mapping, Optional, Sequence


def project_root() -> Path:
    """Return the repository root directory."""
    return Path(__file__).resolve().parents[2]


def _format_variable(name: str, value: str) -> str:
    """Return a Snow CLI session variable assignment."""
    return f"{name}={value}"


def build_command(
    script_path: Path,
    profile: Optional[str] = None,
    variables: Optional[Mapping[str, str]] = None,
    extra_args: Optional[Sequence[str]] = None,
) -> List[str]:
    """Construct the command that invokes the Snow CLI for the provided script."""
    if not script_path.exists():
        raise FileNotFoundError(f"SQL script not found: {script_path}")

    cmd: List[str] = ["snow", "sql", "-f", str(script_path)]

    if profile:
        cmd.extend(["--profile", profile])

    if variables:
        for key, value in variables.items():
            cmd.extend(["--variable", _format_variable(key, value)])

    if extra_args:
        cmd.extend(extra_args)

    return cmd


@dataclass(frozen=True)
class SnowCommandResult:
    command: Sequence[str]
    returncode: int
    stdout: str
    stderr: str

    def __str__(self) -> str:
        cmd = " ".join(shlex.quote(part) for part in self.command)
        return (
            f"Command: {cmd}\n"
            f"Return code: {self.returncode}\n"
            f"stdout:\n{self.stdout}\n"
            f"stderr:\n{self.stderr}"
        )


def run_sql(
    script_relative_path: str,
    profile: Optional[str] = None,
    variables: Optional[Mapping[str, str]] = None,
    dry_run: bool = False,
    extra_args: Optional[Sequence[str]] = None,
) -> SnowCommandResult:
    """Execute a SQL script using the Snow CLI."""
    script_path = project_root() / script_relative_path
    command = build_command(
        script_path=script_path,
        profile=profile,
        variables=variables,
        extra_args=extra_args,
    )

    if dry_run:
        return SnowCommandResult(command=command, returncode=0, stdout="", stderr="")

    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )

    return SnowCommandResult(
        command=command,
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )
