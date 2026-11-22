#!/bin/bash
# Full lifecycle test of newt_ynh on a real YunoHost:
# install, permissions/sandbox checks, settings change + upgrade, config panel,
# published domain (blueprint), real client IPs + fail2ban, diagnosis filters,
# backup, remove, restore, multi-instance, final cleanup.
# Run as root inside the test VM: sudo /vagrant/tests/vagrant/lifecycle.sh
set -euo pipefail

PKG="${PKG:-/vagrant}"
EP="${EP:-https://pangolin.example.org}"
ID="${ID:-31frd0uzbjvp721}"
SECRET="${SECRET:-h51mmlknrvrwv8s4r1i210azhumt6isgbpyavxodibx1k2d6}"
BACKUP_NAME="newt-lifecycle-test"
TEST_DOMAIN="newt-lifecycle.example.org"

PASS=0
FAIL=0
RED=$'\e[31m'; GREEN=$'\e[32m'; BOLD=$'\e[1m'; RESET=$'\e[0m'

step() { echo; echo "${BOLD}=== $*${RESET}"; }
ok()   { echo "${GREEN}  ✔ $*${RESET}"; PASS=$((PASS + 1)); }
ko()   { echo "${RED}  ✘ $*${RESET}"; FAIL=$((FAIL + 1)); }
check() { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$desc"; else ko "$desc"; fi; }
check_not() { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then ko "$desc"; else ok "$desc"; fi; }
check_eq() { if [[ "$3" == "$2" ]]; then ok "$1"; else ko "$1 (got '$3', expected '$2')"; fi; }

is_installed() { test -d "/etc/yunohost/apps/$1"; }

perm_is() { [[ "$(stat -c '%U:%G %a' "$1")" == "$2" ]]; }

check_instance() {
    local app="$1"
    local dir="/var/www/$app"
    check "[$app] service active" systemctl is-active --quiet "$app"
    check "[$app] process runs as user $app" pgrep -u "$app" -x newt
    check "[$app] registered as YunoHost service" yunohost service status "$app"
    check "[$app] install dir root:$app 750" perm_is "$dir" "root:$app 750"
    check "[$app] binary root:$app 750" perm_is "$dir/newt" "root:$app 750"
    check "[$app] env file root:$app 640" perm_is "$dir/newt.env" "root:$app 640"
    check_not "[$app] app user can NOT write install dir (self-update blocked)" \
        sudo -u "$app" touch "$dir/.write_test"
    check "[$app] self-updater switched off" grep -q '^NEWT_SYSTEM_SUBSTRATE=CONTAINER$' "$dir/newt.env"
    check "[$app] env contains endpoint" grep -q "^PANGOLIN_ENDPOINT=$EP\$" "$dir/newt.env"
    check "[$app] NO_CLOUD and DISABLE_SSH set" \
        bash -c "grep -q '^NO_CLOUD=true' '$dir/newt.env' && grep -q '^DISABLE_SSH=true' '$dir/newt.env'"
    check "[$app] log file written" grep -q "Newt version" "/var/log/$app/$app.log"
    check "[$app] logrotate config present" test -f "/etc/logrotate.d/$app"
    check "[$app] NO_CLOUD=true for a self-hosted endpoint" grep -q '^NO_CLOUD=true$' "$dir/newt.env"
    check "[$app] nginx real_ip config present" test -f /etc/nginx/conf.d/newt-realip.conf
    check "[$app] nginx config valid" nginx -t
    check "[$app] fail2ban yunohost jail bans in nginx" \
        bash -c "fail2ban-client get yunohost actions | grep -q newt-nginx-deny"
}

realip_gone() {
    check_not "real_ip nginx config removed" test -f /etc/nginx/conf.d/newt-realip.conf
    check_not "fail2ban jail override removed" test -f /etc/fail2ban/jail.d/newt-realip.conf
    check_not "fail2ban action removed" test -f /etc/fail2ban/action.d/newt-nginx-deny.conf
}

diagnosis_ignores() { grep -q "domain: $TEST_DOMAIN" /etc/yunohost/diagnosis.yml; }

# HTTPS request through localhost, as Newt delivers it, with a client IP set by Pangolin
via_tunnel() {
    curl -sk -o /dev/null -w "%{http_code}" --resolve "$TEST_DOMAIN:443:127.0.0.1" \
        -H "X-Forwarded-For: $1" "https://$TEST_DOMAIN/yunohost/sso/"
}

check_gone() {
    local app="$1"
    check_not "[$app] app no longer listed" is_installed "$app"
    check_not "[$app] systemd unit removed" test -f "/etc/systemd/system/$app.service"
    check_not "[$app] system user removed" id "$app"
    check_not "[$app] install dir removed" test -d "/var/www/$app"
}

install_args() {
    echo "pangolin_endpoint=$EP&newt_id=$ID&newt_secret=$SECRET&log_level=$1"
}

#-------------------------------------------------
step "Cleanup of previous runs"
for app in newt newt__2; do
    if is_installed "$app"; then yunohost app remove "$app"; fi
done
yunohost backup delete "$BACKUP_NAME" >/dev/null 2>&1 || true
if ! yunohost domain list --output-as plain | grep -qxF "$TEST_DOMAIN"; then
    yunohost domain add "$TEST_DOMAIN"
fi

#-------------------------------------------------
step "1. Install"
if yunohost app install "$PKG" --force --args "$(install_args DEBUG)"; then
    ok "install succeeded"
    check_instance newt
    check "log_level DEBUG applied" grep -q '^LOG_LEVEL=DEBUG$' /var/www/newt/newt.env
else
    ko "install failed"
fi

#-------------------------------------------------
step "2. Change setting + forced upgrade"
yunohost app setting newt log_level -v INFO
if yunohost app upgrade newt -u "$PKG" --force; then
    ok "upgrade succeeded"
    check "log_level INFO applied after upgrade" grep -q '^LOG_LEVEL=INFO$' /var/www/newt/newt.env
    check "secret preserved after upgrade" grep -q "^NEWT_SECRET=$SECRET\$" /var/www/newt/newt.env
    check_instance newt
else
    ko "upgrade failed"
fi

#-------------------------------------------------
step "2b. Config panel"
check "secret not exposed by config panel" \
    bash -c "! yunohost app config get newt --full --output-as json | grep -qF '$SECRET'"
if yunohost app config set newt --args "pangolin_endpoint=$EP/&newt_id=$ID&newt_secret=&log_level=WARN"; then
    ok "config panel apply succeeded"
    check "log_level WARN applied by config panel" grep -q '^LOG_LEVEL=WARN$' /var/www/newt/newt.env
    check "trailing slash stripped from endpoint" grep -q "^PANGOLIN_ENDPOINT=$EP\$" /var/www/newt/newt.env
    check "empty secret field keeps secret" grep -q "^NEWT_SECRET=$SECRET\$" /var/www/newt/newt.env
    check_instance newt
else
    ko "config panel apply failed"
fi

#-------------------------------------------------
step "2c. Published domain, real client IPs, diagnosis"
check_not "config panel rejects a non-YunoHost domain" \
    yunohost app config set newt main.publish.published_domains -v "not-a-ynh-domain.example.net"
if yunohost app config set newt main.publish.published_domains -v "$TEST_DOMAIN"; then
    ok "domain published"
    check "blueprint written" grep -q "full-domain: \"$TEST_DOMAIN\"" /var/www/newt/blueprint.yaml
    check "blueprint root:newt 640" perm_is /var/www/newt/blueprint.yaml "root:newt 640"
    check "Pangolin SSO off by default" grep -q "sso-enabled: false" /var/www/newt/blueprint.yaml
    check "BLUEPRINT_FILE set" grep -q '^BLUEPRINT_FILE=/var/www/newt/blueprint.yaml$' /var/www/newt/newt.env
    check "diagnosis ignores the published domain" diagnosis_ignores
    via_tunnel "6.6.6.6, 203.0.113.7" >/dev/null
    check_eq "real client IP logged (spoofed entry ignored)" 203.0.113.7 \
        "$(tail -1 "/var/log/nginx/$TEST_DOMAIN-access.log" | cut -d' ' -f1)"
    fail2ban-client set yunohost banip 203.0.113.7 >/dev/null
    sleep 2
    check_eq "fail2ban ban answered with 403 by nginx" 403 "$(via_tunnel 203.0.113.7)"
    check_eq "other clients not affected" 200 "$(via_tunnel 198.51.100.9)"
    fail2ban-client set yunohost unbanip 203.0.113.7 >/dev/null
    sleep 2
    check_eq "unban lifts the nginx ban" 200 "$(via_tunnel 203.0.113.7)"
else
    ko "publishing a domain failed"
fi

#-------------------------------------------------
step "3. Backup"
if yunohost backup create --apps newt --name "$BACKUP_NAME"; then
    ok "backup created"
else
    ko "backup failed"
fi

#-------------------------------------------------
step "4. Remove"
if yunohost app remove newt; then
    ok "remove succeeded"
    check_gone newt
    realip_gone
    check_not "diagnosis ignore filters removed" diagnosis_ignores
else
    ko "remove failed"
fi

#-------------------------------------------------
step "5. Restore"
if yunohost backup restore "$BACKUP_NAME" --apps newt --force; then
    ok "restore succeeded"
    check_instance newt
    check "secret restored" grep -q "^NEWT_SECRET=$SECRET\$" /var/www/newt/newt.env
    check "blueprint restored" test -f /var/www/newt/blueprint.yaml
    check "diagnosis ignore filters restored" diagnosis_ignores
else
    ko "restore failed"
fi

#-------------------------------------------------
step "6. Second instance (multi_instance)"
if yunohost app install "$PKG" --force --args "$(install_args INFO)"; then
    ok "second instance installed"
    check_instance newt__2
    check "first instance still active" systemctl is-active --quiet newt
    yunohost app remove newt__2 && check_gone newt__2
else
    ko "second instance install failed"
fi

#-------------------------------------------------
step "7. Final cleanup"
yunohost app remove newt && check_gone newt
realip_gone
yunohost backup delete "$BACKUP_NAME" >/dev/null 2>&1 || true
yunohost domain remove "$TEST_DOMAIN" >/dev/null 2>&1 || true

#-------------------------------------------------
echo
echo "${BOLD}Result: ${GREEN}$PASS passed${RESET}${BOLD}, ${RED}$FAIL failed${RESET}"
[[ "$FAIL" -eq 0 ]]
