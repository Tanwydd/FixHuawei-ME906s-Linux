#!/usr/bin/env bash
# =============================================================================
# reiniciar_modem.sh — Relanza el módem Huawei ME906s cuando se queda sin detectar
# Uso: sudo ./reiniciar_modem.sh [-v] [-h]
# =============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VENDOR_ID="12d1"
readonly PRODUCT_ID="15c1"
readonly WAIT_TIMEOUT=60
VERBOSE=0

# ── Colores ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null; then
  RED=$(tput setaf 1); GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

log_info()  { echo "${GREEN}[OK]${RESET}    $*"; }
log_warn()  { echo "${YELLOW}[AVISO]${RESET} $*" >&2; }
log_error() { echo "${RED}[ERROR]${RESET} $*" >&2; }
log_step()  { echo; echo "${CYAN}══ $* ══${RESET}"; }

usage() {
  cat <<EOF
Uso: sudo $SCRIPT_NAME [-v] [-h]

Relanza el módem Huawei ME906s (${VENDOR_ID}:${PRODUCT_ID}) cuando
ModemManager no lo detecta tras el arranque.

Opciones:
  -v    Modo verbose
  -h    Muestra esta ayuda
EOF
  exit 0
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "Ejecuta como root: sudo $SCRIPT_NAME"
    exit 1
  fi
}

check_modem_hardware() {
  if ! lsusb | grep -q "${VENDOR_ID}:${PRODUCT_ID}"; then
    log_error "Módem no detectado a nivel hardware (lsusb). Comprueba la conexión física."
    exit 1
  fi
  log_info "Módem detectado a nivel hardware"
}

reload_udev() {
  log_step "Recargando reglas udev"
  udevadm control --reload-rules
  udevadm trigger --subsystem-match=usb
  sleep 3
  log_info "Reglas udev recargadas"
}

restart_modemmanager() {
  log_step "Reiniciando ModemManager"
  systemctl restart ModemManager.service
  log_info "ModemManager reiniciado, esperando detección del módem..."

  local elapsed=0
  while [[ $elapsed -lt $WAIT_TIMEOUT ]]; do
    if mmcli -L 2>/dev/null | grep -q "Modem"; then
      log_info "Módem detectado por ModemManager"
      return 0
    fi
    sleep 5
    ((elapsed += 5))
    [[ $VERBOSE -eq 1 ]] && echo "        Esperando... ${elapsed}s"
  done

  log_warn "ModemManager no detectó el módem en ${WAIT_TIMEOUT}s"
  return 1
}

restart_networkmanager() {
  log_step "Reiniciando NetworkManager"
  systemctl restart NetworkManager.service
  sleep 5
  log_info "NetworkManager reiniciado"
}

check_connection() {
  log_step "Verificando conexión"
  local modem_index
  modem_index=$(mmcli -L 2>/dev/null | grep -oP '/Modem/\K[0-9]+' | head -1)

  if [[ -z "$modem_index" ]]; then
    log_warn "No se pudo obtener el índice del módem"
    return 1
  fi

  local state
  state=$(mmcli -m "$modem_index" 2>/dev/null | grep "state:" | awk '{print $NF}')
  log_info "Estado del módem: ${state}"

  if [[ "$state" == "connected" ]]; then
    log_info "Módem conectado correctamente"
  else
    log_warn "Módem detectado pero no conectado (estado: ${state})"
    log_warn "NetworkManager debería conectar automáticamente en unos segundos"
  fi
}

main() {
  while getopts ":vh" opt; do
    case $opt in
      v) VERBOSE=1 ;;
      h) usage ;;
      *) log_error "Opción desconocida: -$OPTARG"; exit 1 ;;
    esac
  done

  check_root
  check_modem_hardware
  reload_udev
  restart_modemmanager || { log_error "Fallo al detectar el módem"; exit 1; }
  restart_networkmanager
  check_connection

  echo
  log_info "Proceso completado"
}

main "$@"
