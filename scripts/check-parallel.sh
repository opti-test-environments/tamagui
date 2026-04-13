#!/bin/bash
# Runs the four `check:*` sub-scripts in parallel and aggregates output/exit codes.
# Wall-clock drops from sum-of-all to max-of-all.
set -u

tasks=(
  "check:deps"
  "check:unused"
  "check:tamagui"
  "check:references"
)

tmpdir=$(mktemp -d)
pids=()

for t in "${tasks[@]}"; do
  (
    bun run "$t" > "$tmpdir/$t.log" 2>&1
    echo $? > "$tmpdir/$t.exit"
  ) &
  pids+=($!)
done

for pid in "${pids[@]}"; do
  wait "$pid" || true
done

fail=0
for t in "${tasks[@]}"; do
  echo "===== $t ====="
  cat "$tmpdir/$t.log"
  code=$(cat "$tmpdir/$t.exit" 2>/dev/null || echo 1)
  if [ "$code" != "0" ]; then
    echo "!! $t failed with exit $code"
    fail=1
  fi
done

rm -rf "$tmpdir"
exit "$fail"
