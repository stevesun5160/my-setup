#!/usr/bin/env bash
# Validates skill metadata against agentskills.io rules.
# Exits 0 on success (stdout), 1 on failure (stderr, one error per line).
# Usage: validate-metadata.sh --name NAME --description DESC
#
# Values are read from argv, so quotes/backticks/$() inside NAME or DESC
# are treated as literal characters (no shell re-evaluation).
#
# Description length caps (measured in Unicode characters, not bytes):
#   - Contains any Han character (zh-TW / zh-CN / Japanese kanji): 200
#   - Otherwise: 1024 (agentskills.io spec)
# Requires: bash, tr, perl (perl is preinstalled on macOS / most Linux).

set -u

name=""
description=""
have_name=0
have_description=0

while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      [ $# -ge 2 ] || { printf 'USAGE ERROR: --name requires a value\n' >&2; exit 1; }
      name="$2"
      have_name=1
      shift 2
      ;;
    --description)
      [ $# -ge 2 ] || { printf 'USAGE ERROR: --description requires a value\n' >&2; exit 1; }
      description="$2"
      have_description=1
      shift 2
      ;;
    -h|--help)
      printf 'Usage: %s --name NAME --description DESC\n' "$0"
      exit 0
      ;;
    *)
      printf 'USAGE ERROR: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ "$have_name" -eq 0 ] || [ "$have_description" -eq 0 ]; then
  printf 'USAGE ERROR: both --name and --description are required\n' >&2
  exit 1
fi

errors=()

name_len=${#name}
if [ "$name_len" -lt 1 ] || [ "$name_len" -gt 64 ]; then
  errors+=("NAME ERROR: '$name' is $name_len characters. Must be between 1-64.")
fi

if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  errors+=("NAME ERROR: '$name' contains invalid characters. Use only lowercase letters, numbers, and single hyphens. No consecutive hyphens, and cannot start/end with a hyphen.")
fi

# Character count + Han-presence detection via perl (handles UTF-8 correctly
# regardless of the caller's locale, and uses \p{Han} for CJK classification).
desc_meta=$(perl -CSA -e '
  my $d = $ARGV[0] // "";
  my $n = length($d);
  my $h = ($d =~ /\p{Han}/) ? 1 : 0;
  print "$n $h";
' -- "$description") || {
  printf 'INTERNAL ERROR: perl invocation failed (perl required for UTF-8 length / Han detection)\n' >&2
  exit 1
}
desc_chars="${desc_meta% *}"
desc_has_han="${desc_meta##* }"

if [ "$desc_has_han" -eq 1 ]; then
  desc_limit=200
  desc_limit_reason="contains Han characters, CJK cap applies"
else
  desc_limit=1024
  desc_limit_reason="non-CJK description"
fi

if [ "$desc_chars" -gt "$desc_limit" ]; then
  errors+=("DESCRIPTION ERROR: Description is $desc_chars Unicode characters. Limit: $desc_limit ($desc_limit_reason).")
fi

desc_lower=$(printf '%s' "$description" | LC_ALL=C tr 'A-Z' 'a-z')
normalized=$(printf '%s' "$desc_lower" | LC_ALL=C tr -c 'a-z0-9' ' ')
padded=" $normalized "
found=()
for word in i me my we our you your; do
  case "$padded" in
    *" $word "*) found+=("$word") ;;
  esac
done
if [ "${#found[@]}" -gt 0 ]; then
  errors+=("STYLE ERROR: Description contains first/second person terms: ${found[*]}. Use third-person imperative (e.g., 'Creates...', 'Updates...').")
fi

if [ "${#errors[@]}" -gt 0 ]; then
  for e in "${errors[@]}"; do
    printf '%s\n' "$e" >&2
  done
  exit 1
fi

printf 'SUCCESS: Metadata is valid and optimized for discovery.\n'
exit 0
