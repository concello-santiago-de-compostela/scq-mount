# Montaje de  unidades remotas en Ubuntu 16.04

Configuración de `pam_mount` para montaje de unidades remotas en Ubuntu 16.04.

## Escenario

Una vez que el equipo se ha añadido al dominio a través de la herramienta [pbis-open](https://github.com/BeyondTrust/pbis-open/wiki), tenemos que realizar el montaje de las unidades remotas que tenga definido el usuario dentro del directorio **NETLOGON** de los servidores Windows.

En el directorio **NETLOGON** existe un fichero de alcance global para todos los usuarios (`mapeoUnidades.bat`), que indica las unidades a montar para todo usuario de dominio, y luego, exite un fichero para cada usuario cuyo nombre coincide con el del usuario, que se donde están las unidades que se deben montar a nivel de usuario (`nombreusuario.bat`). El tratamiento de estos dos ficheros se diferencia en que desde `pam_mount` se monta el directorio **NETLOGON** de forma obligatoria en el inicio de sesión en Ubuntu, y luego hay que procesar el fichero del usuario concreto.
La ventaja de reutilizar estos ficheros, es que los administradores de Windows podrán realizar cambios en dichos ficheros, y los cambios se verán aplicados cuando el usuario inicie sesión en un equipo con Windows o Ubuntu.

Los servidores donde se almacenan dichos directorios, tienen versiones de Windows Server diferentes (de 2003 a 2012), por lo que será necesario adaptar la versión de Samba en el montaje de las unidades.

Será necesario realizar un análisis de los ficheros para filtrar aquellas líneas donde se detallen las unidades remotas a montar. En dichas líneas se indica tanto el servidor remoto como la ruta.

### Requisitos previos

Para poder ejecutar las configuraciones incluídas, deben estar instalados los siguientes paquetes:
* libpam-mount
* cifs-utils
tal y como se define en el fichero `control`.

## Configuración en `pam-mount`

Esta librería se configura de forma global a través del fichero `/etc/security/pam_mount.conf.xml`, que es donde se añadirá la sección para montar el directorio **NETLOGON**. Y luego, se activa la configuración a nivel de usuario a través del fichero `~/.pam_mount.conf.xml`, que habrá que construir durante el inicio de sesión de dicho usuario a través de un script que se guardará en `/etc/profile.d`.

Las modificaciones del fichero `/etc/security/pam_mount.conf.xml` se realizan a través del script `postinst` que se ejecuta durante la instalación del paquete DEB.

### Restricción por servicios/aplicaciones

Para evitar que las unidades sean montadas durante los inicios de sesión de comandos como `sudo`, `su`, o incluso durante la sesión gráfica con el usuario `lightdm` se deben realizar cambios en la localización de las referencias a la librería `pam_mount.so`.
En este caso, se eliminan las referencias presentes en los ficheros `common-auth` y `common-session`, y se añaden a los ficheros correspondientes de `lightdm`.

```
sed -i '/pam_mount.so/d' /etc/pam.d/common-auth /etc/pam.d/common-session

sed -i '/include common-auth/a auth\toptional\tpam_mount.so' /etc/pam.d/lightdm
sed -i '/include common-session/a session\toptional\tpam_mount.so' /etc/pam.d/lightdm
sed -i '/include common-session/a session\toptional\tpam_mount.so' /etc/pam.d/lightdm-greeter
```

### Restricción por el UID

Para evitar que se ejecuten los montajes durante los inicios de sesión del usuario `lightdm`, o bien por parte de cualquier usuario local, se añade la restricción en la sección `<volume>` del fichero `pam_mount.conf.xml`.

```
<volume [...] > <not> <uid>0-1000</uid> </not> </volume>
```

## Montaje a nivel de usuario

Cada usuario que inicia sesión dispondrá de un fichero en su directorio personal:

```
 `~/.pam_mount.conf.xml`
```
 el cual será construido a través del script `/etc/profile.d/luserconf.sh`. Por lo tanto, durante el primer inicio de sesión en un equipo nuevo, se deberá construír dicho fichero, el cual, comprueba las posibles diferencias con la versión anterior, y avisa al usuario de que debe iniciar sesión de nuevo para poder aplicar los cambios.
En este script, se procesa el fichero `mapeoUnidades.bat` para poder montar las unidades que están disponibles para todos los usuarios del dominio, y luego el fichero con su nombre de usuario, para el montaje de las unidades remotas propias del usuario.

## Desmontaje de las unidades

La propia librería `pam_mount` se encarga de realizar los desmontajes de las unidades remotas durante el cierre de sesión.

