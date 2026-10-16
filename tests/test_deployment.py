#!/usr/bin/python3
"""Behavioral checks for the development plugin registration workflow."""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DevelopmentDeploymentTests(unittest.TestCase):
    def _run(self, registered: bool) -> tuple[subprocess.CompletedProcess[str], str]:
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            checkout = temporary / "omarchy-plus-keychron-profiles"
            checkout.mkdir()
            checkout.joinpath(".git").mkdir()
            checkout.joinpath("scripts").mkdir()
            shutil.copy2(ROOT / "scripts/dev-deploy", checkout / "scripts/dev-deploy")
            shutil.copy2(ROOT / "runtime-files.txt", checkout / "runtime-files.txt")
            for line in (ROOT / "runtime-files.txt").read_text().splitlines():
                if not line:
                    continue
                destination = checkout / line
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / line, destination)
            validate = checkout / "scripts/validate"
            validate.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            validate.chmod(validate.stat().st_mode | stat.S_IXUSR)

            binary = temporary / "bin"
            binary.mkdir()
            log = temporary / "commands.log"

            omarchy = binary / "omarchy"
            omarchy.write_text(
                "#!/usr/bin/env bash\n"
                "printf 'omarchy %s\\n' \"$*\" >>\"$COMMAND_LOG\"\n"
                "if [[ \"$*\" == 'plugin list --json' ]]; then\n"
                f"  printf '%s\\n' '{'[{\"id\":\"io.github.ol4vr.keychron-profiles\"}]' if registered else '[]'}'\n"
                "fi\n",
                encoding="utf-8",
            )
            shell = binary / "omarchy-shell"
            shell.write_text(
                "#!/usr/bin/env bash\n"
                "printf 'omarchy-shell %s\\n' \"$*\" >>\"$COMMAND_LOG\"\n",
                encoding="utf-8",
            )
            qmllint = binary / "qmllint"
            qmllint.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            git = binary / "git"
            git.write_text(
                "#!/usr/bin/env bash\n"
                "if [[ \"$*\" == *'branch --show-current' ]]; then\n"
                "  printf '%s\\n' feature/test\n"
                "fi\n",
                encoding="utf-8",
            )
            sleep = binary / "sleep"
            sleep.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            for path in (omarchy, shell, qmllint, git, sleep):
                path.chmod(path.stat().st_mode | stat.S_IXUSR)

            environment = os.environ | {
                "PATH": f"{binary}:{os.environ['PATH']}",
                "COMMAND_LOG": str(log),
                "HOME": str(temporary / "home"),
                "XDG_CONFIG_HOME": str(temporary / "config"),
            }
            result = subprocess.run(
                [checkout / "scripts/dev-deploy"],
                env=environment,
                check=False,
                text=True,
                capture_output=True,
            )
            return result, log.read_text(encoding="utf-8")

    def test_deploy_rescans_and_verifies_registration_without_shell_restart(self):
        result, commands = self._run(registered=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("omarchy-shell shell rescanPlugins", commands)
        self.assertIn("omarchy plugin list --json", commands)
        self.assertNotIn("restart shell", commands)

    def test_deploy_fails_clearly_when_registration_never_appears(self):
        result, commands = self._run(registered=False)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("registration did not become ready", result.stderr)
        self.assertIn("omarchy-shell shell rescanPlugins", commands)


if __name__ == "__main__":
    unittest.main()
