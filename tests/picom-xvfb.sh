#!/bin/sh
# Pass an official picom executable; never connects to the running desktop.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
picom_binary=${1:?Pass the official Picom executable}
test_dir=$(mktemp -d /tmp/installdoc-picom-test.XXXXXXXX)
server_pid=
cleanup() {
    if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || :; wait "$server_pid" 2>/dev/null || :; fi
    rm -rf -- "$test_dir"
}
trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM
Xvfb -displayfd 3 -screen 0 800x600x24 -nolisten tcp 3>"$test_dir/display" >"$test_dir/xvfb.log" 2>&1 &
server_pid=$!
attempt=0
while [ ! -s "$test_dir/display" ]; do
    attempt=$((attempt + 1))
    if [ "$attempt" -gt 30 ] || ! kill -0 "$server_pid" 2>/dev/null; then tail -n 30 "$test_dir/xvfb.log"; exit 1; fi
    sleep 0.1
done
display_number=$(cat "$test_dir/display")
result=0
timeout 3s env DISPLAY=":$display_number" XDG_CACHE_HOME="$test_dir/cache" \
    "$picom_binary" --config "$ROOT/config/picom.conf" >"$test_dir/picom.log" 2>&1 || result=$?
cat "$test_dir/picom.log"
[ "$result" -eq 124 ] || { printf 'Picom exited early: %s\n' "$result" >&2; exit 1; }
printf 'Official Picom stayed running on isolated Xvfb with the deployed config.\n'
