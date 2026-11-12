#!/bin/bash
set -eu
export TERM=${TERM:-xterm}
# ncurses starts before we can resize Bochs's private PTY. Use the host's
# dimensions so its scrolling commands agree with the real terminal.
if [ -t 0 ]; then
    read -r LINES COLUMNS < <(stty size)
else
    LINES=${LINES:-25}
    COLUMNS=${COLUMNS:-80}
fi
if [ "$LINES" -eq 0 ]; then LINES=25; fi
if [ "$COLUMNS" -eq 0 ]; then COLUMNS=80; fi
export LINES COLUMNS
emulator_pid=
reader_pid=
tty_state=
cleanup() {
    trap - EXIT HUP INT TERM
    if [ -n "$tty_state" ]; then stty "$tty_state" 2>/dev/null || true; fi
    if [ -n "$reader_pid" ]; then kill "$reader_pid" 2>/dev/null || true; fi
    if [ -n "$emulator_pid" ]; then kill -KILL "$emulator_pid" 2>/dev/null || true; fi
    wait 2>/dev/null || true
    rm -f hdc-0.11.img.lock
}
trap cleanup EXIT HUP INT TERM
# Clear a previous screen path before polling for this instance's PTY.
: > bochs-console.log
bochs "$@" > bochs-console.log 2>&1 &
emulator_pid=$!
screen=
for ((attempt=0; attempt<100; attempt++)); do
    screen=$(sed -n 's/.*Bochs connected to screen "\([^"]*\)".*/\1/p' bochs-console.log | head -n 1)
    if [ -n "$screen" ]; then break; fi
    if ! kill -0 "$emulator_pid" 2>/dev/null; then cat bochs-console.log >&2; exit 1; fi
    sleep 0.1
done
if [ -z "$screen" ]; then cat bochs-console.log >&2; exit 1; fi
stty -F "$screen" raw -echo rows "$LINES" cols "$COLUMNS"
printf 'Linux 0.11: type sync in the guest, then Ctrl+] to close.\n' >&2
if [ -t 0 ]; then tty_state=$(stty -g); stty raw -echo; fi
cat "$screen" &
reader_pid=$!
while IFS= read -r -n 1 -d '' key; do
    if [ "$key" = $'\035' ]; then break; fi
    printf '%s' "$key" > "$screen"
done
