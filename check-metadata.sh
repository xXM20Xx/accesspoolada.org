#!/usr/bin/env bash
# Validate poolMetaData.json against the limits that matter BEFORE registering.
# Run: bash check-metadata.sh
#
# Counts string lengths directly and strips CR/LF first - jq on Windows emits
# CRLF, which made an earlier version of this script over-count by 2.
set -uo pipefail
F="${1:-poolMetaData.json}"
URL="https://accesspoolada.org/poolMetaData.json"
fail=0

chk() { # label value limit
  if [ "$2" -le "$3" ]; then printf '  OK    %-22s %4s / %s\n' "$1" "$2" "$3"
  else printf '  FAIL  %-22s %4s / %s\n' "$1" "$2" "$3"; fail=1; fi
}
get() { jq -r ".$1" "$F" | tr -d '\r\n'; }

command -v jq >/dev/null || { echo "jq not installed"; exit 1; }
jq empty "$F" 2>/dev/null || { echo "  FAIL  not valid JSON"; exit 1; }

echo "Checking $F"
chk "file size (bytes)"  "$(wc -c < "$F" | tr -d ' ')" 512
chk "metadata URL chars" "${#URL}"                     64

t="$(get ticker)"; n="$(get name)"; d="$(get description)"; h="$(get homepage)"
chk "ticker chars"       "${#t}"   5
chk "name chars"         "${#n}"  50
chk "description chars"  "${#d}" 255
chk "homepage chars"     "${#h}"  64

if [[ "$t" =~ ^[A-Z0-9]{3,5}$ ]]; then echo "  OK    ticker charset        $t"
else echo "  FAIL  ticker charset        $t (3-5 chars, A-Z and 0-9 only)"; fail=1; fi
if [[ "$h" =~ ^https?://[^[:space:]]+$ ]]; then echo "  OK    homepage is a URL    $h"
else echo "  FAIL  homepage is a URL    $h"; fail=1; fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All checks passed."
  echo "Hash that will go in the registration certificate:"
  if command -v cardano-cli >/dev/null; then
    cardano-cli latest stake-pool metadata-hash --pool-metadata-file "$F" 2>/dev/null \
      || cardano-cli stake-pool metadata-hash --pool-metadata-file "$F" 2>/dev/null \
      || echo "  (run on the node: cardano-cli stake-pool metadata-hash --pool-metadata-file $F)"
  else
    echo "  (run on the node: cardano-cli stake-pool metadata-hash --pool-metadata-file $F)"
  fi
else
  echo "FAILURES above - fix before registering."
fi
exit "$fail"
