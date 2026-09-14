#!/usr/bin/env bash
# Regression tests for the RAM runner's ISO boot command and serial reporting.
# No ISO build, QEMU installation, root privileges, or real VM required.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
export TEST_ISO="$WORK/Mavind test.iso"
: > "$TEST_ISO"

# Avoid the runner's settle delays. QEMU consumes all input before responding
# so the producer doesn't encounter a broken pipe in this fast mock.
cat > "$WORK/bin/sleep" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$WORK/bin/qemu-system-x86_64" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
args=("$@")
drive=false
serial=false
for ((i=0; i<${#args[@]}; i++)); do
  case "${args[i]}" in
    -append|-kernel)
      echo "unexpected direct-kernel boot argument: ${args[i]}" >&2
      exit 1 ;;
    -drive)
      [[ "${args[i+1]}" == "file=$TEST_ISO,media=cdrom,readonly=on" ]]
      drive=true ;;
    -serial)
      [[ "${args[i+1]}" == "mon:stdio" ]]
      serial=true ;;
  esac
done
[[ "$drive" == true && "$serial" == true ]]
if [[ "${TEST_NO_SERIAL:-0}" == 1 ]]; then
  echo 'Serial login unavailable'
else
  printf 'Mem: 2048 350 1200 10 498 1600\n__MEM__\n'
fi
MOCK
chmod +x "$WORK/bin/sleep" "$WORK/bin/qemu-system-x86_64"
export PATH="$WORK/bin:$PATH"

if ! output=$(bash "$REPO_ROOT/tests/measure-ram.sh" "$TEST_ISO" 0 2>&1); then
  printf 'FAIL: valid ISO boot should produce a RAM report\n%s\n' "$output" >&2
  exit 1
fi
grep -q 'Used: *350 MiB' <<< "$output"
grep -q 'Budget: *700 MiB idle *-> PASS' <<< "$output"
echo 'PASS: ISO boot arguments and captured RAM report (including ISO path with spaces)'

if output=$(TEST_NO_SERIAL=1 bash "$REPO_ROOT/tests/measure-ram.sh" "$TEST_ISO" 0 2>&1); then
  echo 'FAIL: missing serial measurements must not succeed' >&2
  exit 1
fi
grep -q 'Could not read memory over serial' <<< "$output"
echo 'PASS: unavailable serial measurements are reported as failure'
