#!/bin/bash
# Runs oxfmt and oxlint in parallel. Wall-clock drops from sum to max.
set -u

tmpdir=$(mktemp -d)

(oxfmt --check > "$tmpdir/oxfmt.log" 2>&1; echo $? > "$tmpdir/oxfmt.exit") &
pid_fmt=$!
(oxlint > "$tmpdir/oxlint.log" 2>&1; echo $? > "$tmpdir/oxlint.exit") &
pid_lint=$!

wait "$pid_fmt" || true
wait "$pid_lint" || true

fail=0
for t in oxfmt oxlint; do
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
