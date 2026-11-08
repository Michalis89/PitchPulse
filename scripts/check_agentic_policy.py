"""Dependency-free repository policy checks, shared by local validation and CI."""
from pathlib import Path
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = (
    "AGENTS.md", "CLAUDE.md", ".gitignore", ".gitattributes", "README.md", "README-SETUP.md",
    "docs/architecture.md", "docs/decisions.md", "docs/design-system.md",
    "docs/testing-strategy.md", "docs/agent-workflow.md", "docs/mcp-and-hooks.md",
    "docs/progress.md", "docs/setup-remediation.md",
)
EXPECTED_SKILLS = {
    "code-review/SKILL.md", "database-migrations/SKILL.md", "design-system/SKILL.md",
    "feature-implementation/SKILL.md", "football-data-integrity/SKILL.md",
    "release-validation/SKILL.md", "visual-testing/SKILL.md",
}
EXPECTED_REVIEWERS = {"code-reviewer.md", "security-reviewer.md", "ux-reviewer.md"}


def sensitive_path(value):
    path = Path(value)
    name = path.name.lower()
    example = name == ".env.example" or (name.startswith(".env.") and name.endswith(".example"))
    return (
        (name == ".env" or name.startswith(".env.")) and not example
        or name in {"settings.local.json", ".mcp.json", ".mcp.local.json", "credentials.json"}
        or name.startswith("settings.local.") and name.endswith(".json")
        or path.suffix.lower() in {".pem", ".key", ".p12", ".pfx", ".jks", ".keystore", ".ppk"}
        or name in {"id_rsa", "id_dsa", "id_ecdsa", "id_ed25519", "id_ecdsa_sk", "id_ed25519_sk"}
        or name.startswith("service-account") and name.endswith(".json")
        or any(part.lower() in {".aws", ".ssh"} for part in path.parts)
    )


def reviewer_errors(path):
    """Accept only the reviewers' flat, plain-scalar frontmatter subset.

    This is deliberately not a general YAML parser: new fields or YAML constructs
    require a reviewed schema change, including any security-affecting fields.
    """
    content = path.read_text(encoding="utf-8")
    header = re.match(r"\A---\n(.*?)\n---(?:\n|$)", content, re.S)
    fields = {}
    if not header:
        return [f"Invalid reviewer frontmatter: {path.name}"]
    for line in header[1].splitlines():
        match = re.fullmatch(r"([A-Za-z][A-Za-z0-9]*): ([^\n]+)", line)
        if not match or match[1] in fields:
            return [f"Invalid or duplicate reviewer frontmatter field: {path.name}"]
        fields[match[1]] = match[2].strip()
    if set(fields) != {"name", "description", "tools", "model"}:
        return [f"Reviewer fields must be exactly name, description, tools, model: {path.name}"]
    errors = []
    if fields["name"] != path.stem or fields["model"] != "inherit":
        errors.append(f"Reviewer name must match filename and model must inherit: {path.name}")
    description = fields["description"]
    if (not description or description[0] in "[]{}&*!|>'\"%@`#"
            or re.search(r":\s|\s#", description)):
        errors.append(f"Reviewer description must be a plain single-line scalar: {path.name}")
    tools = [t.strip() for t in fields["tools"].split(",")]
    if len(tools) != 3 or set(tools) != {"Read", "Grep", "Glob"}:
        errors.append(f"Reviewer must allow only Read, Grep, Glob: {path.name}")
    return errors


def settings_errors(path, require_hooks=False):
    """Shared settings may restrict reads, but cannot grant tools or run code."""
    try:
        settings = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return [f"Invalid shared settings JSON: {path.name}"]
    if not isinstance(settings, dict) or set(settings) - {"permissions", "hooks"}:
        return [f"Unsupported shared settings fields: {path.name}"]
    errors = []
    if (require_hooks or "hooks" in settings) and settings.get("hooks") != {}:
        errors.append(f"Shared settings hooks must remain explicitly disabled: {path.name}")
    permissions = settings.get("permissions", {})
    if not isinstance(permissions, dict) or set(permissions) - {"deny", "ask"}:
        errors.append(f"Shared permissions may contain only deny/ask rules: {path.name}")
    else:
        for rules in permissions.values():
            if not isinstance(rules, list) or any(not isinstance(rule, str) or not rule.strip() for rule in rules):
                errors.append(f"Shared permission rules must be nonempty strings in lists: {path.name}")
    return errors


def validate(root, tracked_paths):
    errors = []
    for name in REQUIRED:
        path = root / name
        if not path.is_file() or not path.stat().st_size:
            errors.append(f"Missing or empty policy file: {name}")

    def read(name):
        path = root / name
        return path.read_text(encoding="utf-8") if path.is_file() else ""

    if "@AGENTS.md" not in read("CLAUDE.md").splitlines():
        errors.append("CLAUDE.md must import @AGENTS.md on its own line")

    inventories = []
    for directory in (".agents/skills", ".claude/skills"):
        inventory = {
            p.relative_to(root / directory).as_posix(): p.read_text(encoding="utf-8")
            for p in (root / directory).rglob("SKILL.md")
        }
        inventories.append(inventory)
        if not EXPECTED_SKILLS <= inventory.keys():
            errors.append(f"Missing required skills in {directory}")
    if inventories[0].keys() != inventories[1].keys():
        errors.append("Skill inventories differ")
    for name in inventories[0].keys() & inventories[1].keys():
        if inventories[0][name] != inventories[1][name]:
            errors.append(f"Mirrored skill content differs: {name}")

    agents = {p.name: p for p in (root / ".claude/agents").glob("*.md")}
    if not EXPECTED_REVIEWERS <= agents.keys():
        errors.append("Missing required reviewer definitions")
    for name in EXPECTED_REVIEWERS & agents.keys():
        errors.extend(reviewer_errors(agents[name]))

    errors.extend(settings_errors(root / ".claude/settings.example.json", require_hooks=True))
    shared_settings = root / ".claude/settings.json"
    if shared_settings.exists():
        errors.extend(settings_errors(shared_settings))
    if (root / ".claude/hooks/safe-shell-guard.py").exists():
        errors.append("Retired regex shell guard must not be restored")
    for name in tracked_paths:
        if sensitive_path(name):
            errors.append(f"Sensitive/local file is tracked: {name}")
    return errors


def main():
    # Command-scoped trust of this explicit checkout; no global Git settings changed.
    result = subprocess.run(
        ["git", "-c", f"safe.directory={ROOT.as_posix()}", "-c",
         "core.excludesFile=", "ls-files", "-z"],
        cwd=ROOT, capture_output=True, check=True,
    )
    tracked = result.stdout.decode("utf-8").rstrip("\0").split("\0")
    errors = validate(ROOT, tracked)
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    if errors:
        return 1
    print("PASS: required docs, instruction import, mirrored skills, reviewer frontmatter, safe shared settings, disabled hooks and tracked-file policy")
    return 0


if __name__ == "__main__":
    sys.exit(main())
