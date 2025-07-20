#!/bin/bash

# Este script automatiza la configuración consistente del modem Huawei ME906s LTE M.2 Module en Debian 12.
# Soluciona problemas de inicialización forzando el uso del driver cdc_mbim/qmi_wwan.

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

# --- 2. Configurar módulos del kernel para el Huawei ME906s ---
log_message "2. Configurando módulos del kernel para el módem Huawei ME906s (12d1:15c1)..."

# Contenido del archivo modprobe.d
MODPROBE_CONF_CONTENT='
# Opciones para el modem Huawei ME906s (ID: 12d1:15c1)
# Ignorar por usb-storage para evitar conflictos
options usb-storage quirks=12d1:15c1:i

# Indicar a qmi_wwan que maneje este dispositivo desde el principio
# Esto ayuda a que cdc_mbim, el driver correcto, tome el control.
pre_install qmi_wwan /bin/sh -c '\''echo "12d1 15c1" > /sys/bus/usb/drivers/qmi_wwan/new_id'\''

# Poner en lista negra a cdc_ether para evitar conflictos de drivers
blacklist cdc_ether
'

echo "$MODPROBE_CONF_CONTENT" | sudo tee /etc/modprobe.d/huawei-me906s.conf > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la creación del archivo modprobe.d. Revisa los permisos."
    exit 1
fi
log_message "Archivo /etc/modprobe.d/huawei-me906s.conf creado/actualizado correctamente."

# --- 3. Actualizar initramfs ---
log_message "3. Actualizando initramfs para aplicar cambios en los módulos del kernel..."
sudo update-initramfs -u
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la actualización de initramfs. Revisa el log para más detalles."
    exit 1
fi
log_message "Initramfs actualizado."

# --- 4. Recargar reglas udev y reiniciar servicios de red y módem ---
log_message "4. Recargando reglas udev y reiniciando servicios ModemManager y NetworkManager..."

# La regla udev original puede que ya no sea tan crítica como el modprobe.d,
# pero la mantenemos por si acaso para ModemManager.
# Contenido de la regla udev (simplificada)
UDU_RULE_CONTENT='
# Huawei ME906s LTE M.2 Module (Vendor=12d1 ProdID=15c1)
# Intenta forzar la detección por ModemManager y el uso de qmi_wwan/cdc_mbim
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1", MODE:="0666"

# Si ModemManager y el driver cdc_mbim lo manejan bien, usb_modeswitch ya no debería ser necesario.
# Sin embargo, lo dejamos como fallback extremo si el módem se atascara de nuevo en un modo incompatible.
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", RUN+="/usr/sbin/usb_modeswitch -v 0x12d1 -p 0x15c1 --huawei-new-mode"
'
echo "$UDU_RULE_CONTENT" | sudo tee /etc/udev/rules.d/99-huawei-me906s.rules > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la creación de la regla udev. Revisa los permisos."
    exit 1
fi
log_message "Regla udev creada/actualizada correctamente."


sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl restart ModemManager.service NetworkManager.service
log_message "Reglas udev recargadas y servicios reiniciados."

# --- 5. Paso final: Reinicio del sistema ---
log_message "¡SCRIPT COMPLETADO!"
echo "****************************************************************"
echo "**  Para que los cambios en el kernel surtan efecto completo  **"
echo "**    y el módem Huawei ME906s sea detectado correctamente    **"
echo "** en cada arranque, es NECESARIO REINICIAR EL SISTEMA AHORA. **"
echo "****************************************************************"
echo ""
read -p "¿Deseas reiniciar ahora? (s/n): " confirm_reboot
if [[ "$confirm_reboot" =~ ^[Ss]$ ]]; then
    log_message "Reiniciando el sistema..."
    sudo reboot
else
    echo "Por favor, recuerda reiniciar tu sistema manualmente lo antes posible para aplicar los cambios."
fi
