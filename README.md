# FixHuawei-ME906s-Linux

# 🚀 Solución para Módem Huawei ME906s en Debian 12

Este paquete contiene un script diseñado para ayudarte a hacer funcionar tu módem 4G/LTE interno Huawei ME906s en tu portátil Lenovo ThinkPad T560 con Debian 12.

# ¿Qué hace este script? 🤔

Tu módem Huawei ME906s es un componente interno especial que, al encender tu portátil, a veces no se "activa" automáticamente como un módem de internet. En su lugar, puede aparecer como un dispositivo de almacenamiento o algo más genérico.

Este script es como un pequeño "asistente" que hace varias cosas automáticamente para que tu sistema Debian 12 reconozca y use tu módem correctamente:

* Instala las herramientas necesarias: Se asegura de que tengas los programas correctos que Debian usa para gestionar módems y conexiones móviles.

* Crea una "regla especial": Le dice a tu sistema operativo cómo debe tratar a tu módem Huawei ME906s para que siempre sepa que es un módem y no otra cosa. Esto ayuda a que el módem cambie al modo correcto.

* Reinicia los servicios clave: Vuelve a iniciar los programas de tu sistema que se encargan de las conexiones de red y los módems, para que puedan "ver" la nueva configuración.

* Te pide reiniciar: ¡Este es el paso más importante! Después de todo lo anterior, reiniciar el portátil es fundamental para que todos los cambios se apliquen desde cero y el módem se active correctamente.

# ¿Por qué necesito esto? 🧐

Algunos módems internos Huawei (como el ME906s que tienes en tu ThinkPad) tienen un comportamiento un tanto ... particular. Inicialmente se presentan al sistema operativo de una manera que no es la de un módem. Este script ayuda a tu sistema a "entender" lo que realmente es y a activarlo para que puedas usar tu conexión 4G/LTE.

Sin este script, es posible que el módem sea detectado, pero no funcione para conectarte a internet, o que aparezca y desaparezca rápidamente.

# ¿Cómo usar el script? (Paso a Paso) 🚶‍♂️🚶‍♀️

¡No te preocupes si no eres un experto en tecnología! Solo tienes que seguir estos sencillos pasos:

* Descarga el script: Guarda el archivo fix_huawei_modem.sh en tu ordenador. Puedes ponerlo en tu carpeta personal (/home/tu_usuario).

    + Abre una Terminal:

        Puedes encontrarla buscando "Terminal" en el menú de aplicaciones de Debian. Es una ventana donde puedes escribir comandos.

    + Ve a la carpeta donde guardaste el script:

        Si lo guardaste en tu carpeta personal, solo escribe:
        ```
        Bash
        cd ~
        ```

        Si lo guardaste en otra carpeta (por ejemplo, Descargas), escribe:
        ```
        Bash
        cd Descargas
        ```

        (Y pulsa Enter)

* Haz que el script sea "ejecutable": Esto le da permiso al sistema para que pueda ejecutar el archivo.
    ```
    Bash

    chmod +x fix_huawei_modem.sh
    ```

    (Y pulsa Enter)

* Ejecuta el script: ¡Este es el paso principal!
    ```
    Bash

    ./fix_huawei_modem.sh
    ```

    (Y pulsa Enter)

* Sigue las instrucciones en la Terminal:

    * El script te pedirá tu contraseña de usuario (la que usas para iniciar sesión) en algún momento. Esto es normal, ya que necesita permisos especiales para instalar programas y cambiar configuraciones.

    * Verás mensajes que te informan lo que está haciendo el script.

    * Al final, el script te preguntará si quieres reiniciar tu ordenador. Es muy importante que respondas s (para sí) y pulses Enter para que el sistema se reinicie.

# ¡Después del Reinicio! 🎉

Una vez que tu portátil se haya reiniciado y hayas iniciado sesión, tu módem Huawei ME906s debería estar funcionando correctamente. Podrás configurar tu conexión móvil a través de la configuración de red de tu sistema (generalmente accesible desde el icono de red en la barra de tareas) y conectarte a internet usando tu tarjeta SIM.

Recuerda: Necesitarás la APN (Access Point Name) de tu operador de telefonía móvil para configurar la conexión por primera vez. Si no la conoces, búscala en la web de tu operador o en tu contrato.

Si tienes algún problema, puedes volver a ejecutar el script o consultar a alguien con más experiencia en Debian.

# Disclaimer

Este script ha sido creado para ayudar a resolver un problema específico con el módem Huawei ME906s en Debian 12, basado en experiencias de usuario y soluciones comunes.

------

+ Úsalo bajo tu propia responsabilidad: Aunque este script está diseñado para ser seguro, cualquier acción que realices en tu sistema operativo, incluyendo la ejecución de scripts con sudo (permisos de administrador), conlleva ciertos riesgos. Usa la cabeza.

+ No hay garantías: No se ofrece ninguna garantía de que este script funcione en todas las configuraciones posibles o que resuelva todos los problemas relacionados con tu módem. Los entornos de software y hardware pueden variar.

+ Copia de seguridad: Siempre es una buena práctica realizar una copia de seguridad de tus datos importantes antes de realizar cambios significativos en la configuración de tu sistema.

+ Soporte: Este script se proporciona "tal cual" y sin soporte técnico formal. Si encuentras problemas persistentes, se recomienda buscar ayuda en los foros de la comunidad de Debian o consultar con un profesional.

