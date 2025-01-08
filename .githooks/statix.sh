#!/run/current-system/sw/bin/bash
set -euo pipefail

statix check -o errftm || true
