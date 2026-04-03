#!/usr/bin/env bash
# =============================================================================
# huawei-me906s-setup.sh — Configura el módem Huawei ME906s LTE M.2 en Debian 12
# Driver: cdc_mbim (MBIM protocol)
# Uso: sudo ./huawei-me906s-setup.sh [-v] [-n] [-p PIN] [-h]
# =============================================================================

set -euo pipefail

# ── Constantes ────────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "$0")"
readonly VENDOR_ID="12d1"
readonly PRODUCT_ID="15c1"
readonly MODPROBE_CONF="/etc/modprobe.d/huawei-me906s.conf"
readonly UDEV_RULES="/etc/udev/rules.d/99-huawei-me906s.rules"
readonly PACKAGES=(usb-modeswitch modemmanager network-manager-gnome libmbim-utils)
VERBOSE=0
NO_REBOOT=0
SIM_PIN=""

# ── Colores ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null; then
  RED=$(tput setaf 1); GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

# ── Funciones de log ──────────────────────────────────────────────────────────
log_step()    { echo; echo "${CYAN}══ $* ══${RESET}"; }
log_info()    { echo "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo "${YELLOW}[AVISO]${RESET} $*" >&2; }
log_error()   { echo "${RED}[ERROR]${RESET} $*" >&2; }
log_verbose() { [[ $VERBOSE -eq 1 ]] && echo "        $*" || true; }

# ── Ayuda ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Uso: sudo $SCRIPT_NAME [opciones]

Configura el módem Huawei ME906s (${VENDOR_ID}:${PRODUCT_ID}) en Debian 12
usando el driver cdc_mbim (protocolo MBIM).

Opciones:
  -v        Modo verbose
  -n        No preguntar sobre reinicio al finalizar
  -p PIN    PIN de la SIM (se guarda en el perfil de NetworkManager)
  -h        Muestra esta ayuda

Archivos generados:
  $MODPROBE_CONF
  $UDEV_RULES
EOF
  exit 0
}

# ── Verificaciones ────────────────────────────────────────────────────────────
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse como root: sudo $SCRIPT_NAME"
    exit 1
  fi
}

check_debian() {
  if [[ ! -f /etc/debian_version ]]; then
    log_warn "Este script está diseñado para Debian/Ubuntu."
  fi
}

run() {
  if [[ $VERBOSE -eq 1 ]]; then
    "$@"
  else
    "$@" &>/dev/null
  fi
}

# ── Paso 1: Instalar paquetes ─────────────────────────────────────────────────
install_packages() {
  log_step "1/4  Instalando herramientas necesarias"

  if ! run apt-get update; then
    log_error "Falló apt update."
    exit 1
  fi

  if ! run apt-get install -y "${PACKAGES[@]}"; then
    log_error "Falló la instalación de paquetes."
    exit 1
  fi

  log_info "Paquetes instalados: ${PACKAGES[*]}"
}

# ── Paso 2: Configurar modprobe.d ─────────────────────────────────────────────
configure_modprobe() {
  log_step "2/4  Configurando módulos del kernel (${VENDOR_ID}:${PRODUCT_ID})"

  cat > "$MODPROBE_CONF" <<EOF
# Huawei ME906s (${VENDOR_ID}:${PRODUCT_ID}) — generado por $SCRIPT_NAME
# Driver: cdc_mbim (protocolo MBIM)

# Evitar que usb-storage reclame el dispositivo
options usb-storage quirks=${VENDOR_ID}:${PRODUCT_ID}:i

# Bloquear drivers conflictivos
# NOTA: cdc_mbim NO debe estar en blacklist — es el driver correcto
blacklist cdc_ether
EOF

  if ! run update-initramfs -u; then
    log_error "Falló update-initramfs."
    exit 1
  fi

  log_info "modprobe.d configurado → $MODPROBE_CONF"
  log_info "initramfs actualizado"
}

# ── Paso 3: Configurar udev ───────────────────────────────────────────────────
configure_udev() {
  log_step "3/4  Configurando reglas udev y reiniciando servicios"

  cat > "$UDEV_RULES" <<EOF
# Huawei ME906s (${VENDOR_ID}:${PRODUCT_ID}) — generado por $SCRIPT_NAME

# Asegurar que ModemManager procese el dispositivo en modo MBIM
ATTRS{idVendor}=="${VENDOR_ID}", ATTRS{idProduct}=="${PRODUCT_ID}", \
  ENV{ID_MM_DEVICE_PROCESS}="1"
ATTRS{idVendor}=="${VENDOR_ID}", ATTRS{idProduct}=="${PRODUCT_ID}", \
  ENV{ID_MM_TTY_BLACKLIST}="1"
SUBSYSTEM=="usb", ATTRS{idVendor}=="${VENDOR_ID}", ATTRS{idProduct}=="${PRODUCT_ID}", \
  ENV{ID_MM_HUAWEI_USE_MBIM}="1"
EOF

  run udevadm control --reload-rules
  run udevadm trigger

  if ! run systemctl restart ModemManager.service NetworkManager.service; then
    log_warn "Algún servicio no se reinició correctamente."
  fi

  log_info "Reglas udev → $UDEV_RULES"
  log_info "Servicios reiniciados"

  # Esperar a que ModemManager inicialice el módem
  log_verbose "Esperando inicialización del módem (30s)..."
  local retries=12
  while [[ $retries -gt 0 ]]; do
    if mmcli -L 2>/dev/null | grep -q "Modem"; then
      log_info "Módem detectado por ModemManager"
      break
    fi
    sleep 5
    ((retries--))
  done

  if [[ $retries -eq 0 ]]; then
    log_warn "ModemManager no detectó el módem en 60s. Puede que necesite reiniciar."
  fi
}

# ── Paso 4: Configurar perfil NetworkManager ──────────────────────────────────
configure_nm_profile() {
  log_step "4/5  Configurando perfil de conexión en NetworkManager"

  # Buscar perfil gsm existente
  local profile
  profile=$(nmcli -t -f NAME,TYPE connection show | grep ":gsm" | cut -d: -f1 | head -1)

  if [[ -z "$profile" ]]; then
    log_warn "No se encontró perfil GSM en NetworkManager."
    log_warn "Crea la conexión manualmente desde el gestor de red."
    return 0
  fi

  log_info "Perfil GSM encontrado: $profile"

  # Asegurar autoconexión
  nmcli connection modify "$profile" connection.autoconnect yes
  nmcli connection modify "$profile" connection.autoconnect-priority 0
  log_info "Autoconexión activada en perfil '$profile'"

  # Guardar PIN si se proporcionó
  if [[ -n "$SIM_PIN" ]]; then
    nmcli connection modify "$profile" gsm.pin "$SIM_PIN"
    nmcli connection modify "$profile" gsm.pin-flags 0
    log_info "PIN guardado en perfil '$profile'"
  fi
}

# ── Paso 5: Reinicio ──────────────────────────────────────────────────────────
prompt_reboot() {
  log_step "5/5  Reinicio del sistema"

  echo
  echo "  Los cambios en el kernel requieren un reinicio completo."
  echo "  El módem tardará ~30s en conectarse tras el arranque."
  echo

  if [[ $NO_REBOOT -eq 1 ]]; then
    log_warn "Reinicio omitido (-n). Recuerda reiniciar manualmente."
    return
  fi

  local confirm
  read -r -p "  ¿Reiniciar ahora? [s/N]: " confirm
  if [[ "${confirm,,}" =~ ^s$ ]]; then
    log_info "Reiniciando..."
    reboot
  else
    log_warn "Recuerda reiniciar manualmente para aplicar los cambios del kernel."
  fi
}

# ── Punto de entrada ──────────────────────────────────────────────────────────
main() {
  while getopts ":vnp:h" opt; do
    case $opt in
      v) VERBOSE=1 ;;
      n) NO_REBOOT=1 ;;
      p) SIM_PIN="$OPTARG" ;;
      h) usage ;;
      *) log_error "Opción desconocida: -$OPTARG"; exit 1 ;;
    esac
  done

  check_root
  check_debian

  install_packages
  configure_modprobe
  configure_udev
  configure_nm_profile
  prompt_reboot

  echo
  log_info "Configuración completada para Huawei ME906s (${VENDOR_ID}:${PRODUCT_ID})"
  log_info "Driver: cdc_mbim | Protocolo: MBIM | Operador: detectado automáticamente"
}

main "$@"
