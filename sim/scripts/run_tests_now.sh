#!/usr/bin/env bash
# Phase B: run TEST_ID 0..19 (20 separate sims).
# Env: SIMV (default ./simv), SIMV_EXTRA (e.g. +PER_CHK_OFF for gate-level),
#      LOGDIR (default logs; pass logs_ideal / logs_netlist to keep both runs)
set -euo pipefail
SIMDIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SIMDIR"
SIMV="${SIMV:-./simv}"
SIMV_EXTRA="${SIMV_EXTRA:-}"
LOGDIR="${LOGDIR:-logs}"
mkdir -p "$LOGDIR"
if [[ ! -x "$SIMV" ]]; then
  echo "No $SIMV — run: make compile  (or make compile-netlist)"
  exit 1
fi
PASS=0
for id in $(seq 0 19); do
  LOG=$(printf '%s/run_t%02d.log' "$LOGDIR" "$id")
  echo "=== Running TEST_ID=$id -> $LOG ($SIMV) ==="
  # shellcheck disable=SC2086
  "$SIMV" -no_save $SIMV_EXTRA "+TEST_ID=${id}" 2>&1 | tee "$LOG"
  if grep -q "TB_OPENMSP430_MINIMAL: PASS" "$LOG"; then
    echo ">>> PASS: TEST_ID=$id"
    PASS=$((PASS + 1))
  else
    echo ">>> FAIL: TEST_ID=$id"
    exit 1
  fi
done
echo ">>> Done: ${PASS} simulations passed (${LOGDIR}/run_t00.log .. run_t19.log)."
