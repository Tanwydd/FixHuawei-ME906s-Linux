#!/bin/bash

# Este script intenta configurar y activar el modem Huawei ME906s LTE M.2 Module en Debian 12.

# --- Función para mostrar mensajes de estado ---
log_message() {
    echo "--- $1 ---"
}

# --- 1. Instalar herramientas esenciales ---
log_message "1. Actualizando lista de paquetes e instalando herramientas necesarias..."
sudo apt update
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la actualización de paquetes. Revisa tu conexión a internet o los repositorios."
    exit 1
fi
sudo apt install -y usb-modeswitch modemmanager network-manager-gnome
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la instalación de paquetes. Asegúrate de tener permisos sudo."
    exit 1
fi
log_message "Herramientas instaladas/actualizadas correctamente."

# --- 2. Crear o actualizar la regla udev para el Huawei ME906s ---
log_message "2. Creando/actualizando regla udev para el módem Huawei ME906s (12d1:15c1)..."

# Contenido de la regla udev
UDU_RULE_CONTENT='
# Huawei ME906s LTE M.2 Module (Vendor=12d1 ProdID=15c1)
# Intenta forzar el uso de qmi_wwan y la detección por ModemManager
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1", MODE:="0666", KERNEL=="cdc-wdm*", SYMLINK+="modem/qmi0", GOTO="huawei_qmi_end"
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1", MODE:="0666", KERNEL=="ttyUSB*", SYMLINK+="modem/ttyUSB%n", GOTO="huawei_tty_end"
# Fallback para el caso de que necesite un cambio de modo específico al arrancar
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ATTR{bInterfaceNumber}=="00", ATTR{bInterfaceClass}=="02", ATTR{bInterfaceSubClass}=="06", ATTR{bInterfaceProtocol}=="00", DRIVER=="cdc_ether", RUN+="/usr/sbin/usb_modeswitch -v 0x12d1 -p 0x15c1 --huawei-new-mode"
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", RUN+="/usr/sbin/usb_modeswitch -v 0x12d1 -p 0x15c1 --huawei-new-mode"

LABEL="huawei_qmi_end"
LABEL="huawei_tty_end"
'

echo "$UDU_RULE_CONTENT" | sudo tee /etc/udev/rules.d/99-huawei-me906s.rules > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la creación de la regla udev. Revisa los permisos."
    exit 1
fi
log_message "Regla udev creada correctamente."

# --- 3. Recargar reglas udev y forzar el reescaneo de dispositivos ---
log_message "3. Recargando reglas udev y disparando eventos..."
sudo udevadm control --reload-rules
sudo udevadm trigger
log_message "Reglas udev recargadas."

# --- 4. Reiniciar servicios de red y módem ---
log_message "4. Reiniciando servicios ModemManager y NetworkManager..."
sudo systemctl restart ModemManager.service NetworkManager.service
log_message "Servicios reiniciados."

# --- 5. Paso final: Reinicio del sistema ---
log_message "¡SCRIPT COMPLETADO!"
echo "****************************************************************"
echo "** Para que los cambios surtan efecto completamente y el módem **"
echo "** Huawei ME906s sea detectado correctamente, **"
echo "** es NECESARIO REINICIAR EL SISTEMA AHORA. **"
echo "****************************************************************"
echo ""
read -p "¿Deseas reiniciar ahora? (s/n): " confirm_reboot
if [[ "$confirm_reboot" =~ ^[Ss]$ ]]; then
    log_message "Reiniciando el sistema..."
    sudo reboot
else
    echo "Por favor, recuerda reiniciar tu sistema manualmente lo antes posible para aplicar los cambios."
fi
