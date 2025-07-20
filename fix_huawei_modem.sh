#!/bin/bash

# Este script automatiza la configuración consistente del modem Huawei ME906s LTE M.2 Module en Debian 12.
# Soluciona problemas de inicialización forzando el uso del driver qmi_wwan/cdc_mbim de forma fiable.

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
# usb-modeswitch se mantiene por si acaso, aunque la solución principal ahora es via modprobe.d
# modemmanager y network-manager-gnome son esenciales para la gestión del modem
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

# Indicar explícitamente a qmi_wwan que maneje este ID de dispositivo USB.
# Esta es la directiva clave para la solución consistente.
options qmi_wwan quirks=12d1:15c1

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

# La regla udev se mantiene, aunque la configuración de modprobe.d es la principal.
# Esta regla asegura que ModemManager procese el dispositivo.
UDU_RULE_CONTENT='
# Huawei ME906s LTE M.2 Module (Vendor=12d1 ProdID=15c1)
# Asegura que ModemManager procese este dispositivo.
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1", MODE:="0666"

# usb_modeswitch como fallback, aunque con la solucion del modprobe.d no deberia ser necesario.
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
echo "** Para que los cambios en el kernel surtan efecto completo   **"
echo "** y el módem Huawei ME906s sea detectado correctamente       **"
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
