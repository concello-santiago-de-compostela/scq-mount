#!/bin/bash


function translate_file {

	# Elimina los retornos de carro en formato Windows
	sed -i -e 's/\r//g' $1
	# Elimina todas las lineas, excepto las que contengan 'net use'
	sed -i -e '/net use/!d' $1
	# Elimina las lineas que contengan la palabra 'delete'
	sed -i -e '/delete/d' $1
	# Elimina el principio de cada linea, incluyendo los dos primeros backslash
	sed -i -e 's|.*\\\\\(.*\)|\1|' $1
	# Sustituye el backslash por los dos puntos
	sed -i -e 's/\\/:/' $1
}

function global_process {

	cp /tmp/netlogon/mapeoUnidades.bat $HOME/.mapeoUnidades.bak
	
	translate_file $HOME/.mapeoUnidades.bak

	for LINEA in $(<$HOME/.mapeoUnidades.bak); do

		add_2_xml $LINEA

	done
}

function user_process {

	cp /tmp/netlogon/$USUARIO.bat $HOME/.$USUARIO.bak
	
	translate_file $HOME/.$USUARIO.bak

	for LINEA in $(<$HOME/.$USUARIO.bak); do

		add_2_xml $LINEA

	done
}

function add_2_xml {

	SERVER=$(echo $1 | cut -d: -f1)
	RUTA=$(echo $1 | cut -d: -f2)
	echo "<volume fstype=\"cifs\" server=\"$SERVER\" path=\"$RUTA\" mountpoint=\"~/$RUTA\" options=\"nodev,nosuid,domain=%(DOMAIN_NAME),actimeo=3,vers=2.1\" />" >> $HOME/.pam_mount.conf.xml

}

[[ -f $HOME/.pam_mount.conf.xml ]] && cp $HOME/.pam_mount.conf.xml $HOME/.pam_mount.conf.xml.bak

USUARIO=${USER##*\\}

exec 3> >(logger -t mountSCQ)

# Comienza la construcción del fichero XML de Usuario

echo -e "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" > $HOME/.pam_mount.conf.xml
echo -e "<pam_mount>\n" >> $HOME/.pam_mount.conf.xml

	[[ -f /tmp/netlogon/mapeoUnidades.bat ]] && global_process || echo "File mapeoUnidades.bat not found in NETLOGON" >&3
	
	[[ -f /tmp/netlogon/$USUARIO.bat ]] && user_process || echo "File $USUARIO.bat not found in NETLOGON" >&3

echo -e "\n</pam_mount>" >> $HOME/.pam_mount.conf.xml

diff $HOME/.pam_mount.conf.xml $HOME/.pam_mount.conf.xml.bak 2>/dev/null 1>&2

[[ $? -ne 0 ]] && notify-send "Unidades de rede" "Inicie unha nova sesión para aplicar os cambios."

