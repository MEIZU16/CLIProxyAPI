#!/bin/sh
set -eu

APP_DIR="/CLIProxyAPI"
CONFIG_FILE="${CLI_PROXY_CONFIG_FILE:-${APP_DIR}/config/config.yaml}"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"
AUTH_DIR="${CLI_PROXY_AUTH_DIR:-/root/.cli-proxy-api}"
LOG_DIR="${CLI_PROXY_LOG_DIR:-${APP_DIR}/logs}"
APP_PORT="${PORT:-${CPA_PORT:-8317}}"

mkdir -p "$CONFIG_DIR" "$AUTH_DIR" "$LOG_DIR"

if [ ! -s "$CONFIG_FILE" ]; then
	if [ -n "${CPA_API_KEY:-}" ] || [ -n "${CPA_MANAGEMENT_KEY:-}" ]; then
		cat >"$CONFIG_FILE" <<EOF
host: ""
port: ${APP_PORT}

remote-management:
  allow-remote: true
  secret-key: "${CPA_MANAGEMENT_KEY:-}"

auth-dir: "${AUTH_DIR}"

api-keys:
  - "${CPA_API_KEY:-your-api-key-1}"

request-log: false
logging-to-file: false
logs-max-total-size-mb: 100
EOF
	else
		cp "${APP_DIR}/config.example.yaml" "$CONFIG_FILE"
	fi
fi

if [ "${CLI_PROXY_SYNC_CONFIG_PORT:-true}" != "false" ]; then
	if grep -q '^port:' "$CONFIG_FILE"; then
		sed -i "s/^port:.*/port: ${APP_PORT}/" "$CONFIG_FILE"
	else
		printf "\nport: %s\n" "$APP_PORT" >>"$CONFIG_FILE"
	fi
fi

if [ "$#" -eq 0 ]; then
	set -- "${APP_DIR}/CLIProxyAPI"
elif [ "${1#-}" != "$1" ]; then
	set -- "${APP_DIR}/CLIProxyAPI" "$@"
elif [ "$1" = "CLIProxyAPI" ]; then
	shift
	set -- "${APP_DIR}/CLIProxyAPI" "$@"
elif [ "$1" = "./CLIProxyAPI" ]; then
	shift
	set -- "${APP_DIR}/CLIProxyAPI" "$@"
fi

if [ "$1" = "${APP_DIR}/CLIProxyAPI" ]; then
	has_config_arg=0
	for arg in "$@"; do
		if [ "$arg" = "-config" ] || [ "$arg" = "--config" ]; then
			has_config_arg=1
			break
		fi
	done
	if [ "$has_config_arg" -eq 0 ]; then
		set -- "$@" -config "$CONFIG_FILE"
	fi
fi

exec "$@"
