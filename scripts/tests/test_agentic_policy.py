"""Regression checks for policy failures; no application scaffold required."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("policy", ROOT / "scripts/check_agentic_policy.py")
policy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(policy)


class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in policy.REQUIRED:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        for name in (".agents/skills", ".claude/skills", ".claude/agents"):
            shutil.copytree(ROOT / name, self.root / name)
        shutil.copyfile(ROOT / ".claude/settings.example.json", self.root / ".claude/settings.example.json")

    def test_current_policy(self):
        self.assertEqual([], policy.validate(self.root, ["README.md", ".env.example"]))

    def test_skill_drift_and_missing_mirror(self):
        path = self.root / ".claude/skills/code-review/SKILL.md"
        path.write_text("changed", encoding="utf-8")
        self.assertTrue(any("content differs" in e for e in policy.validate(self.root, [])))
        path.unlink()
        self.assertTrue(any("inventories differ" in e for e in policy.validate(self.root, [])))

    def test_both_skill_trees_missing_is_failure(self):
        shutil.rmtree(self.root / ".agents/skills")
        shutil.rmtree(self.root / ".claude/skills")
        self.assertTrue(any("Missing required skills" in e for e in policy.validate(self.root, [])))

    def test_reviewer_shell_is_failure(self):
        path = self.root / ".claude/agents/code-reviewer.md"
        path.write_text(path.read_text(encoding="utf-8").replace("tools: Read, Grep, Glob", "tools: Read, Grep, Glob, Bash"), encoding="utf-8")
        self.assertTrue(any("Reviewer must allow only" in e for e in policy.validate(self.root, [])))

    def test_reviewer_security_overrides_are_rejected(self):
        path = self.root / ".claude/agents/code-reviewer.md"
        original = path.read_text(encoding="utf-8")
        for field in ("permissionMode: bypassPermissions", "hooks: {}", "mcpServers: [github]", "disallowedTools: Read",
                      "skills: anything", "memory: project", "unknownField: value",
                      "tools: Read, Grep, Glob, Bash", "name: other-agent"):
            with self.subTest(field=field):
                path.write_text(original.replace("model: inherit", "model: inherit\n" + field), encoding="utf-8")
                self.assertTrue(policy.validate(self.root, []))
        path.write_text(original.replace("name: code-reviewer", "name: different-reviewer"), encoding="utf-8")
        self.assertTrue(policy.validate(self.root, []))

    def test_nonreviewer_can_have_implementation_tools(self):
        (self.root / ".claude/agents/implementer.md").write_text(
            "---\nname: implementer\ndescription: Implementation helper\ntools: Read, Edit, Bash\nmodel: inherit\n---\n",
            encoding="utf-8",
        )
        self.assertEqual([], policy.validate(self.root, []))

    def test_reviewer_schema_rejects_yaml_constructs_and_wrong_model(self):
        path = self.root / ".claude/agents/code-reviewer.md"
        original = path.read_text(encoding="utf-8")
        for content in (
            original.replace("model: inherit", "model: other"),
            original.replace("model: inherit\n", ""),
            original.replace("description: Read-only", "description: &alias Read-only"),
            original.replace("tools: Read, Grep, Glob", "tools:\n  - Read\n  - Grep\n  - Glob"),
            original.replace("tools: Read, Grep, Glob", "tools: Read, Grep, Glob\n<<: *permissions"),
        ):
            with self.subTest(content=content):
                path.write_text(content, encoding="utf-8")
                self.assertTrue(policy.validate(self.root, []))

    def test_shared_settings_allow_restrictions_but_reject_execution_and_grants(self):
        path = self.root / ".claude/settings.json"
        for settings in ({}, {"permissions": {"deny": ["Read(**/.env)"], "ask": ["Bash"]}, "hooks": {}}):
            with self.subTest(settings=settings):
                path.write_text(json.dumps(settings), encoding="utf-8")
                self.assertEqual([], policy.validate(self.root, [".claude/settings.json"]))
        for settings in ([], {"hooks": {"PreToolUse": []}}, {"env": {"TOKEN": "placeholder"}},
                         {"permissions": {"defaultMode": "bypassPermissions"}},
                         {"permissions": {"allow": ["Bash"]}}, {"permissions": {"deny": "Read(**/.env)"}}):
            with self.subTest(settings=settings):
                path.write_text(json.dumps(settings), encoding="utf-8")
                self.assertTrue(policy.validate(self.root, [".claude/settings.json"]))

    def test_missing_import_and_enabled_hook_are_failures(self):
        (self.root / "CLAUDE.md").write_text("Read AGENTS.md", encoding="utf-8")
        (self.root / ".claude/settings.example.json").write_text('{"hooks":{"PreToolUse":[]}}', encoding="utf-8")
        errors = policy.validate(self.root, [])
        self.assertTrue(any("import" in e for e in errors))
        self.assertTrue(any("hooks" in e for e in errors))

    def test_sensitive_tracked_files(self):
        for name in (".env", "server/.env.production", ".claude/settings.local.json", ".claude/settings.local.dev.json", ".mcp.json", "server/signing.key", "service-account-prod.json", "keys/id_rsa", "keys/id_dsa", "keys/id_ecdsa", "keys/id_ed25519", "keys/id_ecdsa_sk", "keys/id_ed25519_sk", "keys/private.ppk"):
            with self.subTest(name=name):
                self.assertTrue(policy.validate(self.root, [name]))
        self.assertEqual([], policy.validate(self.root, [".env.example", "server/.env.test.example", "client/package-lock.json", ".claude/settings.json", "keys/id_rsa.pub", "keys/id_ed25519.pub"]))

    def test_gitignore_protects_locals_and_preserves_shared_files(self):
        subprocess.run(["git", "init", "--quiet", str(self.root)], check=True, capture_output=True)
        ignored = [".env", "server/.env.production", ".mcp.json", ".claude/settings.local.json", ".claude/settings.local.dev.json", ".claude/worktrees/task/file", ".worktrees/task/file", "worktrees/task/file", ".codex/config.toml", "server/target/file", "client/node_modules/file", "client/.angular/cache/file", "server/signing.key", "pgdata/file", "test-results/file"]
        ignored += [f"keys/{name}" for name in ("id_rsa", "id_dsa", "id_ecdsa", "id_ed25519", "id_ecdsa_sk", "id_ed25519_sk", "private.ppk")]
        kept = [".env.example", "server/.env.test.example", ".claude/settings.json", ".claude/settings.example.json", ".claude/skills/code-review/SKILL.md", ".agents/skills/code-review/SKILL.md", "client/package-lock.json", "server/.mvn/wrapper/maven-wrapper.jar", "server/mvnw.cmd", "compose.yaml", "server/src/main/resources/db/migration/V1__init.sql"]
        kept += ["keys/id_rsa.pub", "keys/id_ed25519.pub"]
        for name, expected in [(n, 0) for n in ignored] + [(n, 1) for n in kept]:
            with self.subTest(name=name):
                result = subprocess.run(["git", "-c", "core.excludesFile=", "check-ignore", "--quiet", "--no-index", name], cwd=self.root, capture_output=True)
                self.assertEqual(expected, result.returncode, name)
        result = subprocess.run(
            ["git", "check-attr", "text", "eol", "--", "AGENTS.md", "scripts/check_agentic_policy.py", "image.png"],
            cwd=self.root, capture_output=True, text=True, check=True,
        )
        self.assertIn("AGENTS.md: eol: lf", result.stdout)
        self.assertIn("scripts/check_agentic_policy.py: eol: lf", result.stdout)
        self.assertIn("image.png: text: unset", result.stdout)


if __name__ == "__main__":
    unittest.main()
