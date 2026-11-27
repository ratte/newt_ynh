#!/bin/bash
# Unit test for provision.sh: runs it on the host (no root, no VM) with every
# system command stubbed, and checks which commands it calls in each scenario.
# Run: tests/vagrant/provision_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/provision.sh"

PASS=0
FAIL=0
RED=$'\e[31m'; GREEN=$'\e[32m'; BOLD=$'\e[1m'; RESET=$'\e[0m'

step() { echo; echo "${BOLD}=== $*${RESET}"; }
ok()   { echo "${GREEN}  ✔ $*${RESET}"; PASS=$((PASS + 1)); }
ko()   { echo "${RED}  ✘ $*${RESET}"; FAIL=$((FAIL + 1)); }
check_eq() { if [[ "$3" == "$2" ]]; then ok "$1"; else ko "$1 (got '$3', expected '$2')"; fi; }
called()     { if grep -qxF -- "$2" "$LOG"; then ok "$1"; else ko "$1 (no '$2' in call log)"; fi; }
not_called() { if grep -q -- "^$2" "$LOG"; then ko "$1 ('$2' found in call log)"; else ok "$1"; fi; }

# Creates a stub command that appends "name args..." to the call log.
# An optional body runs after logging.
stub() {
    local name="$1" body="${2:-}"
    cat > "$BIN/$name" <<EOF
#!/bin/bash
echo "$name \$*" >> "$LOG"
$body
EOF
    chmod +x "$BIN/$name"
}

# Fresh sandbox: stub dir, call log, marker path. "with_yunohost" pre-installs
# the yunohost stub (as if the installer already ran in an earlier provision).
setup() {
    TMP="$(mktemp -d)"
    BIN="$TMP/bin"
    LOG="$TMP/calls.log"
    MARKER="$TMP/installed"
    SOURCES="$TMP/yunohost.sources"
    mkdir -p "$BIN"
    : > "$LOG"

    stub apt-get
    stub groupadd
    stub usermod
    # debconf reads its selections from stdin; log them too.
    stub debconf-set-selections 'echo "debconf-stdin $(cat)" >> "'"$LOG"'"'
    # The fake installer script served by "curl ... | bash" logs its args and
    # installs the yunohost stub, like the real installer would.
    stub curl "cat <<'INSTALLER'
echo \"installer \$*\" >> \"$LOG\"
cat > \"$BIN/yunohost\" <<'YNH'
#!/bin/bash
echo \"yunohost \$*\" >> \"$LOG\"
YNH
chmod +x \"$BIN/yunohost\"
printf 'Types: deb\\nURIs: https://repo.yunohost.org/debian/\\nSuites: trixie\\nComponents: stable testing\\n' > \"$SOURCES\"
INSTALLER"
    [[ "${1:-}" == "with_yunohost" ]] && stub yunohost
}

run_provision() {
    OUT="$(env -i HOME="$TMP" PATH="$BIN:/usr/bin:/bin" INSTALLED_MARKER="$MARKER" \
        YNH_APT_SOURCES="$SOURCES" bash "$SCRIPT" 2>&1)"
    RC=$?
}

teardown() { rm -rf "$TMP"; }

POSTINSTALL="yunohost tools postinstall --domain ynh-test.local --username ynhadmin --fullname Admin Test --password Yunohost-Test-1234 --ignore-dyndns --force-diskspace"

step "Syntax"
if bash -n "$SCRIPT"; then ok "bash -n passes"; else ko "bash -n fails"; fi
if command -v shellcheck >/dev/null; then
    if shellcheck "$SCRIPT"; then ok "shellcheck passes"; else ko "shellcheck reports issues"; fi
else
    echo "  (shellcheck not installed, skipped)"
fi

step "Fresh VM: installs YunoHost, then post-installs"
setup
run_provision
check_eq "exit code" 0 "$RC"
called "updates apt index" "apt-get update -qq"
called "installs curl, CA certs and kernel headers" \
    "apt-get install -y -qq curl ca-certificates linux-headers-amd64"
called "presets grub-pc install device" \
    "debconf-stdin grub-pc grub-pc/install_devices multiselect /dev/sda"
called "fetches the trixie installer" "curl -fsSL https://install.yunohost.org/trixie"
called "runs installer non-interactively on testing channel" "installer -a -d testing"
check_eq "testing channel removed from YunoHost APT source" "Components: stable" \
    "$(grep '^Components:' "$SOURCES")"
called "runs postinstall with test credentials" "$POSTINSTALL"
called "creates ssh.app group" "groupadd -f ssh.app"
called "adds vagrant to ssh.app" "usermod -aG ssh.app vagrant"
check_eq "installer runs before postinstall" "installer postinstall" \
    "$(grep -oE '^installer|postinstall' "$LOG" | tr '\n' ' ' | sed 's/ $//')"
check_eq "postinstall runs before the ssh group fix" "yunohost groupadd usermod" \
    "$(grep -oE '^(yunohost|groupadd|usermod)' "$LOG" | tr '\n' ' ' | sed 's/ $//')"
if [[ "$OUT" == *"YunoHost ready: https://192.168.56.10"* ]]; then ok "prints ready message"; else ko "ready message missing"; fi
teardown

step "Installer ran, postinstall did not (re-provision after failure)"
setup with_yunohost
printf 'Components: stable testing\n' > "$SOURCES"
run_provision
check_eq "exit code" 0 "$RC"
not_called "skips apt-get" "apt-get"
not_called "skips installer download" "curl"
check_eq "still removes testing channel" "Components: stable" "$(cat "$SOURCES")"
called "runs postinstall" "$POSTINSTALL"
called "adds vagrant to ssh.app" "usermod -aG ssh.app vagrant"
teardown

step "Already installed: no-op"
setup with_yunohost
touch "$MARKER"
run_provision
check_eq "exit code" 0 "$RC"
check_eq "no commands called" "" "$(cat "$LOG")"
if [[ "$OUT" == *"already installed"* ]]; then ok "says nothing to do"; else ko "missing 'already installed' message"; fi
teardown

step "Failing postinstall aborts provisioning (set -e)"
setup
stub yunohost 'exit 1'
run_provision
check_eq "non-zero exit code" 1 "$RC"
not_called "does not touch ssh groups" "groupadd"
teardown

step "Failing installer download aborts provisioning (pipefail)"
setup
stub curl 'exit 22'
run_provision
# Without pipefail the script would only die later on "yunohost: not found" (127).
check_eq "exits with curl's exit code" 22 "$RC"
not_called "does not run postinstall" "yunohost"
teardown

echo
echo "${BOLD}Result: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}"
[[ "$FAIL" -eq 0 ]]
