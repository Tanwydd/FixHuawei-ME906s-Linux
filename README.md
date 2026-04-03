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
4. Crea `/etc/udev/rules.d/99-huawei-me906s.rules` — fuerza modo MBIM en ModemManager
5. Espera activamente a que ModemManager detecte el módem (hasta 60s)
6. Configura el perfil GSM en NetworkManager con `autoconnect: yes`
7. Guarda el PIN de la SIM si se proporciona (evita el diálogo en cada arranque)

**Uso:**

```bash
sudo chmod +x huawei-me906s-setup.sh

# Uso básico
sudo ./huawei-me906s-setup.sh

# Con PIN de SIM (recomendado, evita diálogos al arrancar)
sudo ./huawei-me906s-setup.sh -p 1234

# Modo verbose (muestra salida de todos los comandos)
sudo ./huawei-me906s-setup.sh -v -p 1234

# Sin reinicio automático al finalizar (para scripts de automatización)
sudo ./huawei-me906s-setup.sh -n -p 1234
```

**Opciones:**

| Opción | Descripción |
|---|---|
| `-v` | Modo verbose — muestra salida detallada de cada comando |
| `-n` | No preguntar sobre reinicio al finalizar |
| `-p PIN` | PIN de la SIM — se guarda cifrado en el perfil de NetworkManager |
| `-h` | Muestra la ayuda |

---

### `reiniciar_modem.sh`

Reinicia los servicios `ModemManager` y `NetworkManager`. Útil cuando el módem pierde la conexión sin necesidad de reiniciar el sistema.

**Uso:**

```bash
sudo chmod +x reiniciar_modem.sh

# Uso básico
sudo ./reiniciar_modem.sh

# Modo verbose
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
         └─ ModemManager detecta el módem via udev (~20s)
              └─ NetworkManager lee perfil "Vodafone" (autoconnect: yes)
                   └─ Envía PIN → se registra en red → conexión establecida (~30-40s)
```

No se requiere ninguna intervención manual. La conexión estará disponible unos 30-40 segundos después del arranque.

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
