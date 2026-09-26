#!/usr/bin/env bash

set -euo pipefail

VENV_DIR=".venv"
REQUIREMENTS_FILE="requirements.txt"

is_venv_working() {
    if [[ -f "$VENV_DIR/bin/python" ]] && "$VENV_DIR/bin/python" -c "import sys" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

if ! is_venv_working; then
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --upgrade pip --quiet

if [[ -f "$REQUIREMENTS_FILE" ]]; then
    "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"
else
    "$VENV_DIR/bin/pip" install plotext
fi
