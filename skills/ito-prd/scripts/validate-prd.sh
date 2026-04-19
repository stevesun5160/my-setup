#!/usr/bin/env bash
# Validate PRD markdown file structure.
# Usage: bash scripts/validate-prd.sh <file>
# Exit 0 = valid, Exit 1 = invalid (errors on stderr)

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "USAGE ERROR: file path required" >&2
  echo "Usage: bash scripts/validate-prd.sh <path-to-prd.md>" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "FILE ERROR: '$FILE' not found" >&2
  exit 1
fi

ERRORS=0

required_sections=("## 問題描述" "## User Stories" "## Out of Scope" "## 已知侷限")
for section in "${required_sections[@]}"; do
  if ! grep -qF "$section" "$FILE"; then
    echo "SECTION ERROR: missing required section '${section}'" >&2
    ERRORS=$((ERRORS + 1))
  fi
done

if ! grep -qE '^\*\*US-[0-9]{2} ' "$FILE"; then
  echo "US ERROR: no User Story found matching format '**US-XX [title]'" >&2
  ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "INVALID: $ERRORS error(s) found in '$FILE'" >&2
  exit 1
fi

echo "SUCCESS: '$FILE' passes all PRD validation checks."
