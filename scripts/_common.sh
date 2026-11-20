#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

_newt_service_add() {
    yunohost service add "$app" \
        --description="Newt - Pangolin site connector" \
        --log="/var/log/$app/$app.log"
}

# Deploy the binary and env file with tight permissions:
# root owns everything, the app user can only read/execute.
_newt_fix_permissions() {
    chown root:"$app" "$install_dir"
    chmod 750 "$install_dir"
    chown root:"$app" "$install_dir/newt"
    chmod 750 "$install_dir/newt"
    chown root:"$app" "$install_dir/newt.env"
    chmod 640 "$install_dir/newt.env"
}

_newt_add_config() {
    ynh_config_add --template="newt.env" --destination="$install_dir/newt.env"
}

# Start the service and make sure it is not crash-looping.
# (Newt runs forever and retries the connection on its own, so a
# running process is the right success criterion here.)
_newt_start() {
    ynh_systemctl --service="$app" --action="start"
    sleep 5
    if ! systemctl is-active --quiet "$app"; then
        journalctl --quiet --no-hostname --no-pager --lines=30 --unit="$app" >&2 || true
        tail --lines=30 "/var/log/$app/$app.log" >&2 || true
        ynh_die "The $app service failed to start, see the log above"
    fi
}
