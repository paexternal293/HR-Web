#!/bin/bash
set -euo pipefail

cd /workspace

log_file="logs/kudos-access.log"
report_dir="reports"
output_file="${report_dir}/critical-access-report.txt"

mkdir -p "$report_dir"

external_tmp=$(mktemp)
failed_tmp=$(mktemp)
: > "$external_tmp"
: > "$failed_tmp"

awk -F'|' -v external="$external_tmp" -v failed="$failed_tmp" '
function is_private(ip) {
    if (ip ~ /^10\./) {
        return 1;
    }
    if (ip ~ /^192\.168\./) {
        return 1;
    }
    if (ip ~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./) {
        return 1;
    }
    return 0;
}
function reset_kv() {
    delete kv;
}
{
    ts = $1;
    reset_kv();
    for (i = 2; i <= NF; i++) {
        split($i, pair, "=");
        key = pair[1];
        value = pair[2];
        kv[key] = value;
    }

    user = kv["user"];
    role = kv["role"];
    action = kv["action"];
    result = kv["result"];
    ip = kv["ip"];

    if (action == "LOGIN" && result == "SUCCESS" && role == "admin" && !is_private(ip)) {
        printf "%s|user=%s|timestamp=%s\n", ip, user, ts >> external;
    }

    if (action == "LOGIN" && result == "FAILED") {
        failures[user]++;
    }
}
END {
    for (user in failures) {
        if (failures[user] >= 3) {
            printf "%s|failed_attempts=%d\n", user, failures[user] >> failed;
        }
    }
}
' "$log_file"

{
    echo "[external_admin_logins]"
    if [ -s "$external_tmp" ]; then
        cat "$external_tmp"
    fi
    echo
    echo "[excessive_failed_logins]"
    if [ -s "$failed_tmp" ]; then
        sort "$failed_tmp"
    fi
} > "$output_file"

rm -f "$external_tmp" "$failed_tmp"
