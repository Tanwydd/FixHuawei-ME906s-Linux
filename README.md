Solución para Módem Huawei ME906s en Debian 12

Este paquete contiene un script diseñado para ayudarte a hacer funcionar tu módem 4G/LTE interno Huawei ME906s en tu portátil Lenovo ThinkPad T560 con Debian 12 de forma consistente en cada arranque.


# ¿Qué hace este script? 🤔

Tu módem Huawei ME906s es un componente interno que, al encender tu portátil, a veces no se "activa" correctamente como un módem de internet. Aunque se detecta, puede que el sistema no le asigne el controlador (driver) adecuado de inmediato, impidiendo su funcionamiento.

Este script es una solución automatizada que realiza varios pasos clave para asegurar que tu sistema Debian 12 reconozca y use tu módem de forma fiable:

* Instala herramientas esenciales: Se asegura de que tengas los programas necesarios (como ModemManager, usb-modeswitch y NetworkManager-gnome) que Debian usa para gestionar módems y conexiones móviles.

* Configura los módulos del kernel: Este es el paso más importante. Modifica directamente la forma en que el kernel de Linux maneja tu módem. Le indica que use el driver cdc_mbim (o qmi_wwan) desde el inicio del sistema y que ignore otros drivers conflictivos como cdc_ether o usb-storage que pueden interferir con la correcta inicialización del módem.

* Actualiza el sistema de arranque (initramfs): Para que los cambios en la configuración de los módulos del kernel sean efectivos, el script actualiza el "mini-sistema" que arranca antes del sistema operativo completo.

* Recarga reglas y reinicia servicios clave: Vuelve a cargar las reglas de detección de hardware (udev) y reinicia los servicios de red (ModemManager, NetworkManager) para aplicar los cambios en la sesión actual.

* Te pide reiniciar: ¡Este es el paso final y fundamental! Después de todas las configuraciones, reiniciar el portátil es crucial para que los cambios en el kernel se apliquen desde cero y el módem se active correctamente en cada inicio.


# ¿Por qué necesito esto? 🧐

Algunos módems internos Huawei (como el ME906s que tienes en tu ThinkPad) tienen un comportamiento particular al arrancar. Aunque el sistema los detecta (con ID 12d1:15c1), a veces no se les asigna el controlador de red móvil correcto (cdc_mbim o qmi_wwan) y, en su lugar, se cargan otros drivers que no permiten su funcionamiento como módem 4G/LTE, o incluso se desregistran poco después.

Este script soluciona ese problema forzando al kernel a utilizar el driver adecuado desde el inicio del sistema, garantizando así que el módem esté listo para usarse para tu conexión a internet cada vez que enciendas tu portátil.


# ¿Cómo usar el script? (Paso a Paso) 🚶‍♂️🚶‍♀️

¡No te preocupes si no eres un experto en tecnología! Solo tienes que seguir estos sencillos pasos:

* Descarga el script: Guarda el archivo configurar_modem_huawei.sh (o el nombre que le hayas dado) en tu ordenador. Puedes ponerlo en tu carpeta personal (/home/tu_usuario).

* Abre una Terminal:
Puedes encontrarla buscando "Terminal" en el menú de aplicaciones de Debian. Es una ventana donde puedes escribir comandos.

* Ve a la carpeta donde guardaste el script:

+ Si lo guardaste en tu carpeta personal, solo escribe:
    ```
    cd ~
    ```
+ Si lo guardaste en otra carpeta (por ejemplo, Descargas), escribe:
    ```
    cd Descargas
    ```
    (Y pulsa Enter)

* Haz que el script sea "ejecutable": Esto le da permiso al sistema para que pueda ejecutar el archivo.
    ```
    chmod +x fix_huawei_modem.sh
    ```
    (Y pulsa Enter)

* Ejecuta el script: ¡Este es el paso principal!
Bash
    ```
    sudo ./fix_huawei_modem.sh
    ```
    (Y pulsa Enter)

* Sigue las instrucciones en la Terminal:

    + El script te pedirá tu contraseña de usuario (la que usas para iniciar sesión) en algún momento. Esto es normal, ya que necesita permisos especiales para instalar programas y cambiar configuraciones.

    + Verás mensajes que te informan lo que está haciendo el script en cada paso.

    + Al final, el script te preguntará si quieres reiniciar tu ordenador. Es muy importante que respondas s (para sí) y pulses Enter para que el sistema se reinicie.


# ¡Después del Reinicio! 🎉

Una vez que tu portátil se haya reiniciado y hayas iniciado sesión, tu módem Huawei ME906s debería estar funcionando correctamente de forma automática. Podrás configurar tu conexión móvil a través de la configuración de red de tu sistema (generalmente accesible desde el icono de red en la barra de tareas) y conectarte a internet usando tu tarjeta SIM.

Recuerda: Necesitarás la APN (Access Point Name) de tu operador de telefonía móvil para configurar la conexión por primera vez. Si no la conoces, búscala en la web de tu operador o en tu contrato.

Si tienes algún problema, puedes volver a ejecutar el script o consultar a alguien con más experiencia en Debian.


# Disclaimer

Este script ha sido creado para ayudar a resolver un problema específico con el módem Huawei ME906s en Debian 12, basado en experiencias de usuario y soluciones comunes.

---

**Úsalo bajo tu propia responsabilidad:** Aunque este script está diseñado para ser seguro, cualquier acción que realices en tu sistema operativo, incluyendo la ejecución de scripts con sudo (permisos de administrador), conlleva ciertos riesgos ¡Usa la cabeza!

**No hay garantías:** No se ofrece ninguna garantía de que este script funcione en todas las configuraciones posibles o que resuelva todos los problemas relacionados con tu módem. Los entornos de software y hardware pueden variar.

**Copia de seguridad:** Siempre es una buena práctica realizar una copia de seguridad de tus datos importantes antes de realizar cambios significativos en la configuración de tu sistema.

**Soporte:** Este script se proporciona "tal cual" y sin soporte técnico formal. Si encuentras problemas persistentes, se recomienda buscar ayuda en los foros de la comunidad de Debian o consultar con un profesional.
