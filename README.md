# Configuración de pam-mount

Configuración para montaje de unidades remotas en Ubuntu 16.04

# Configuración de ficheros en PAM

El módulo `pam_mount.so` sólo se ha de ejecutar durante el inicio de la sesión gráfica, por lo que es necesario realizar cambios en los ficheros globales `common-auth` y `common-session`. A continuación, se añade este módulo a los ficheros de `lightdm`.

# Restricción por el UID

Para evitar que se ejecuten los montajes durante los inicios de sesión del usuario `lightdm`, o bien por parte de cualquier usuario local, se añade la restricción en la sección `<volume>` del fichero `pam_mount.conf.xml`.

	<volume [...] > <not> <uid>0-1000</uid> </not> </volume>

