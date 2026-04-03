# Huawei ME906s LTE M.2 — Configuración en Debian 12

Scripts para configurar y gestionar el módem **Huawei ME906s** (ID USB `12d1:15c1`) en Debian 12 (Bookworm), resolviendo los problemas de detección automática mediante el driver `cdc_mbim` y el protocolo MBIM.

---

## Contexto del problema

El módem Huawei ME906s puede no ser detectado correctamente al arrancar porque el kernel de Linux compite entre varios drivers (`cdc_mbim`, `cdc_ether`, `usb-storage`) sin saber cuál usar. Además, ModemManager necesita ser informado explícitamente de que este dispositivo debe gestionarse en modo MBIM.

Los síntomas típicos son:

- `mmcli -L` devuelve `No modems were found`
- El módem aparece en `lsusb` pero sin driver asignado (`Driver=`)
- NetworkManager muestra el módem como no disponible
- La conexión no se establece automáticamente al arrancar
- Los logs de ModemManager muestran: `could not grab port cdc-wdm1: unhandled port type`

---

## Solución implementada

| Componente | Configuración |
|---|---|
| Driver kernel | `cdc_mbim` |
| Protocolo | MBIM |
| Gestión | ModemManager + NetworkManager |
| Archivo modprobe | `/etc/modprobe.d/huawei-me906s.conf` |
| Regla udev | `/etc/udev/rules.d/99-huawei-me906s.rules` |

---

## Scripts

### `huawei-me906s-setup.sh`

Configuración inicial completa del módem. Ejecutar **una sola vez** tras instalar Debian o si se reinstala el sistema.

**Qué hace:**

1. Instala `modemmanager`, `libmbim-utils`, `usb-modeswitch` y `network-manager-gnome`
2. Crea `/etc/modprobe.d/huawei-me906s.conf` — asigna `cdc_mbim` y bloquea drivers conflictivos
3. Actualiza `initramfs` para que los cambios persistan desde el arranque
4. Crea `/etc/udev/rules.d/99-huawei-me906s.rules` — fuerza modo MBIM en ModemManager via `ID_MM_HUAWEI_USE_MBIM`
5. Espera activamente a que ModemManager detecte el módem (hasta 60s)
6. Configura el perfil GSM en NetworkManager con `autoconnect: yes`
7. Guarda el PIN de la SIM si se proporciona (evita el diálogo en cada arranque)

**Uso:**

```bash
sudo chmod +x huawei-me906s-setup.sh

# Uso básico
sudo ./huawei-me906s-setup.sh

# Con PIN de SIM (recomendado — evita diálogos al arrancar)
sudo ./huawei-me906s-setup.sh -p 1234

# Modo verbose
sudo ./huawei-me906s-setup.sh -v -p 1234

# Sin reinicio automático al finalizar
sudo ./huawei-me906s-setup.sh -n -p 1234
```

**Opciones:**

| Opción | Descripción |
|---|---|
| `-v` | Modo verbose — muestra salida detallada de cada comando |
| `-n` | Omitir pregunta de reinicio al finalizar |
| `-p PIN` | PIN de la SIM — se guarda cifrado en el perfil de NetworkManager |
| `-h` | Muestra la ayuda |

---

### `reiniciar_modem.sh`

Despierta el módem cuando ModemManager no lo detecta tras el arranque o se queda sin responder. Es el script a ejecutar cuando `mmcli -L` devuelve `No modems were found` a pesar de que el módem es visible en `lsusb`.

**Qué hace:**

1. Comprueba que el módem es visible a nivel hardware via `lsusb`
2. Recarga las reglas udev y dispara el subsistema USB (soluciona el error `unhandled port type`)
3. Reinicia ModemManager y espera hasta 60s a que detecte el módem
4. Reinicia NetworkManager
5. Verifica el estado final de la conexión

**Uso:**

```bash
sudo chmod +x reiniciar_modem.sh

# Uso básico
sudo ./reiniciar_modem.sh

# Modo verbose (muestra el progreso de espera)
sudo ./reiniciar_modem.sh -v
```

**Opciones:**

| Opción | Descripción |
|---|---|
| `-v` | Modo verbose |
| `-h` | Muestra la ayuda |

---

## Requisitos

- Debian 12 (Bookworm) — también compatible con Ubuntu 22.04+
- ModemManager 1.20.4 o superior
- Privilegios `sudo`
- Tarjeta SIM insertada en el módulo M.2

---

## Comportamiento tras la instalación

Una vez ejecutado `huawei-me906s-setup.sh` y reiniciado el sistema, la secuencia automática en cada arranque es:

```
Kernel arranca
    └─ cdc_mbim se carga → /dev/cdc-wdm1 disponible
         └─ udev aplica la regla ID_MM_HUAWEI_USE_MBIM
              └─ ModemManager detecta el módem (~20s)
                   └─ NetworkManager lee el perfil (autoconnect: yes)
                        └─ Envía PIN → se registra en red → conexión establecida (~30-40s)
```

No se requiere ninguna intervención manual. La conexión estará disponible unos 30-40 segundos después del arranque.

Si el módem no se detecta tras ~60s, ejecuta `sudo ./reiniciar_modem.sh`.

---

## Archivos de configuración clave

### `/etc/modprobe.d/huawei-me906s.conf`

```
# Huawei ME906s (12d1:15c1) — driver cdc_mbim

options usb-storage quirks=12d1:15c1:i
blacklist cdc_ether
```

### `/etc/udev/rules.d/99-huawei-me906s.rules`

```
# Huawei ME906s (12d1:15c1) — forzar modo MBIM en ModemManager

ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_DEVICE_PROCESS}="1"
ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_TTY_BLACKLIST}="1"
SUBSYSTEM=="usb", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="15c1", ENV{ID_MM_HUAWEI_USE_MBIM}="1"
```

---

## Diagnóstico

Si el módem no conecta, estos comandos ayudan a identificar el problema:

```bash
# ¿El kernel ve el hardware?
lsusb | grep -i huawei

# ¿Qué driver tiene asignado?
lsusb -t

# ¿ModemManager lo detecta?
mmcli -L

# Estado completo del módem
mmcli -m 0

# ¿El dispositivo MBIM responde?
mbimcli -d /dev/cdc-wdm1 --query-device-caps

# Logs de ModemManager
sudo journalctl -u ModemManager -n 50 --no-pager
```

**Problema más frecuente:** los logs de ModemManager muestran `could not grab port cdc-wdm1: unhandled port type`. Solución: verifica que `/etc/udev/rules.d/99-huawei-me906s.rules` contiene la línea `ID_MM_HUAWEI_USE_MBIM`, y ejecuta `sudo ./reiniciar_modem.sh`.

---

## Hardware probado

| Campo | Valor |
|---|---|
| Módulo | Huawei ME906s (`ML1ME906SM`) |
| USB ID | `12d1:15c1` |
| Firmware | `11.617.00.00.11` |
| Redes | GSM / UMTS / LTE (HSPA+) |
| Operador probado | Vodafone ES |
| Sistema | Debian 12 Bookworm (kernel 6.x) |

---

## Licencia

MIT
