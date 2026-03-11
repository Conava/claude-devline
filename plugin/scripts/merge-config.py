#!/usr/bin/env python3
"""Merge YAML config files with deep merge semantics.

Loads defaults, user, and project config files in order, deep-merging them
so that later files override earlier ones. Certain safeguard lists use
additive merge (append rather than replace).

Output: merged config as JSON on stdout.
"""

import json
import os
import sys


# ---------------------------------------------------------------------------
# Minimal YAML parser (stdlib-only fallback)
# ---------------------------------------------------------------------------

def _simple_yaml_parse(text):
    """Parse a minimal subset of YAML sufficient for nested dicts, lists,
    and scalar values (strings, ints, bools).  Handles the config format
    we use: nested dicts, lists of scalars, inline comments, and values
    containing colons (e.g. regex patterns, URLs)."""

    root = {}
    stack = [(root, -1)]  # (current_dict_or_list, indent_level)

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        i += 1

        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue

        indent = len(raw) - len(raw.lstrip())

        # Pop stack to find the right parent
        while len(stack) > 1 and stack[-1][1] >= indent:
            stack.pop()

        current = stack[-1][0]

        # List item
        if stripped.startswith("- "):
            value = stripped[2:].strip()
            # Strip inline comments (but not inside quoted strings)
            if not (value.startswith('"') or value.startswith("'")):
                comment_pos = value.find(" #")
                if comment_pos >= 0:
                    value = value[:comment_pos].strip()
            value = _cast_scalar(value)
            if isinstance(current, list):
                current.append(value)
            continue

        # Key: value — use first colon NOT inside quotes as separator
        if ":" in stripped:
            colon_pos = _find_key_colon(stripped)
            if colon_pos < 0:
                continue
            key = stripped[:colon_pos].strip()
            rest = stripped[colon_pos + 1:].strip()

            # Strip inline comments from values (not inside quotes)
            if rest and not (rest.startswith('"') or rest.startswith("'")):
                comment_pos = rest.find(" #")
                if comment_pos >= 0:
                    rest = rest[:comment_pos].strip()

            if rest == "" or rest == "|" or rest == ">":
                # Look ahead to determine if children are list or dict
                next_i = i
                while next_i < len(lines) and not lines[next_i].strip():
                    next_i += 1
                if next_i < len(lines):
                    next_stripped = lines[next_i].strip()
                    next_indent = len(lines[next_i]) - len(lines[next_i].lstrip())
                    if next_indent > indent and next_stripped.startswith("- "):
                        child = []
                        current[key] = child
                        # Use indent (parent key level) so list items don't
                        # get popped prematurely (items are at next_indent)
                        stack.append((child, indent))
                        continue
                # Nested dict
                child = {}
                current[key] = child
                stack.append((child, indent))
            elif rest.startswith("[") and rest.endswith("]"):
                # Inline flow sequence: [item1, item2]
                inner = rest[1:-1].strip()
                if inner:
                    current[key] = [_cast_scalar(s.strip()) for s in inner.split(",")]
                else:
                    current[key] = []
            else:
                current[key] = _cast_scalar(rest)

    return root


def _find_key_colon(line):
    """Find the colon that separates key from value, skipping colons
    inside quoted strings.  Returns the index or -1."""
    in_quote = None
    for idx, ch in enumerate(line):
        if ch in ('"', "'"):
            if in_quote is None:
                in_quote = ch
            elif in_quote == ch:
                in_quote = None
        elif ch == ":" and in_quote is None:
            return idx
    return -1


def _cast_scalar(value):
    """Convert a YAML scalar string to a Python type."""
    if value in ("true", "True", "yes", "Yes"):
        return True
    if value in ("false", "False", "no", "No"):
        return False
    if value in ("null", "Null", "~", ""):
        return None
    # Remove surrounding quotes
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
        return value[1:-1]
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    return value


# ---------------------------------------------------------------------------
# YAML loading
# ---------------------------------------------------------------------------

def load_yaml(path):
    """Load a YAML file, returning a dict.  Returns None if file missing."""
    if not os.path.isfile(path):
        return None
    with open(path, "r") as f:
        text = f.read()
    try:
        import yaml  # Try PyYAML first
        return yaml.safe_load(text) or {}
    except ImportError:
        return _simple_yaml_parse(text)


# ---------------------------------------------------------------------------
# Deep merge
# ---------------------------------------------------------------------------

ADDITIVE_KEYS = frozenset(["blocked_commands", "blocked_patterns"])


def deep_merge(base, override):
    """Deep merge *override* into *base* (mutates base).

    Lists under ``safeguards.blocked_commands`` and
    ``safeguards.blocked_patterns`` are merged additively (appended).
    All other lists are replaced.
    """
    for key, val in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(val, dict):
            deep_merge(base[key], val)
        elif key in ADDITIVE_KEYS and isinstance(base.get(key), list) and isinstance(val, list):
            seen = set(base[key])
            for item in val:
                if item not in seen:
                    base[key].append(item)
                    seen.add(item)
        else:
            base[key] = val
    return base


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    home = os.environ.get("HOME", "")
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")

    if not plugin_root:
        print("Error: CLAUDE_PLUGIN_ROOT is not set", file=sys.stderr)
        sys.exit(1)

    # 1. Defaults (required)
    defaults_path = os.path.join(plugin_root, "config", "defaults.yaml")
    defaults = load_yaml(defaults_path)
    if defaults is None:
        print(f"Error: defaults config not found at {defaults_path}", file=sys.stderr)
        sys.exit(1)

    merged = dict(defaults)

    # 2. User config (optional)
    if home:
        user_cfg = load_yaml(os.path.join(home, ".claude-plugin-config.yaml"))
        if user_cfg:
            deep_merge(merged, user_cfg)

    # 3. Project config (optional) — lives in .claude/ to keep repo root clean
    if project_dir:
        proj_cfg = load_yaml(os.path.join(project_dir, ".claude", ".claude-plugin-config.yaml"))
        if proj_cfg:
            deep_merge(merged, proj_cfg)

    json.dump(merged, sys.stdout, indent=2)
    print()  # trailing newline


if __name__ == "__main__":
    main()
