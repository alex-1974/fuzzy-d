#!/usr/bin/env bash
set -euo pipefail

echo "== fuzzy-d: DMD library tests =="
dub test --compiler=dmd --force

echo "== fuzzy-d: LDC library tests =="
dub test --compiler=ldc2 --force

echo "== fuzzy-d: DMD consumer smoke =="
dub run --root=tests/consumer --compiler=dmd --build=release --force

echo "== fuzzy-d: LDC consumer smoke =="
dub run --root=tests/consumer --compiler=ldc2 --build=release --force

echo "== fuzzy-d: representative release benchmarks =="
dub run --root=benchmarks --compiler=ldc2 --build=release --force

echo "== fuzzy-d: qualification passed =="

