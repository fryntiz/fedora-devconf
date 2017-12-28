#!/usr/bin/env bash
# -*- ENCODING: UTF-8 -*-
##
## @author     Raúl Caro Pastorino
## @copyright  Copyright © 2017 Raúl Caro Pastorino
## @license    https://wwww.gnu.org/licenses/gpl.txt
## @email      tecnico@fryntiz.es
## @web        www.fryntiz.es
## @github     https://github.com/fryntiz
## @gitlab     https://gitlab.com/fryntiz
##
##             Guía de estilos aplicada:
## @style      https://github.com/fryntiz/Bash_Style_Guide

############################
##     INSTRUCCIONES      ##
############################

############################
##     IMPORTACIONES      ##
############################

############################
##       CONSTANTES       ##
############################

###########################
##       VARIABLES       ##
###########################

###########################
##       FUNCIONES       ##
###########################
apache2_preconfiguracion() {
    echo -e "$VE Generando Pre-Configuraciones de$RO Apache 2$CL"
    sudo groupadd apache 2>> /dev/null

    generar_www() {
        ## Borrar contenido de /var/www
        sudo systemctl stop apache2 2>> /dev/null
        echo -e "$VE Cuidado, esto puede$RO BORRAR$VE algo valioso$CL"
        read -p " ¿Quieres borrar todo el directorio /var/www/? s/N → " input
        if [[ $input = 's' ]] || [[ $input = 'S' ]]; then
            sudo rm -R /var/www/* 2>> /dev/null
        else
            echo -e "$VE No se borra /var/www$CL"
        fi

        ## Copia todo el contenido WEB a /var/www
        echo -e "$VE Copiando contenido dentro de /var/www$CL"
        sudo cp -R $WORKSCRIPT/servers/Apache2/www/* /var/www/

        ## Copia todo el contenido de configuración a /etc/apache2
        echo -e "$VE Copiando archivos de configuración dentro de /etc/apache2$CL"
        sudo cp -R $WORKSCRIPT/servers/Apache2/etc/apache2/* /etc/httpd/

        ## Crear archivo de usuario con permisos para directorios restringidos
        echo -e "$VE Creando usuario con permisos en apache$CL"
        sudo rm /var/www/.htpasswd 2>> /dev/null
        while [[ -z $input_user ]]; do
            read -p "Nombre de usuario para acceder al sitio web privado → " input_user
        done
        echo -e "$VE Introduce la contraseña para el sitio privado:$RO"
        sudo htpasswd -c /var/www/.htpasswd $input_user

        ## Cambia el dueño
        echo -e "$VE Asignando dueños$CL"
        sudo chown apache:apache -R /var/www
        sudo chown -R root:root /etc/httpd/*

        ## Agrega el usuario al grupo apache
        echo -e "$VE Añadiendo el usuario al grupo$RO www-data$CL"
        sudo usermod -a -G apache "$USER"
    }

    echo -e "$VE Es posible generar una estructura dentro de /var/www"
    echo -e "$VE Ten en cuenta que esto borrará el contenido actual"
    echo -e "$VE También se modificarán archivos en /etc/httpd/*$RO"
    read -p " ¿Quieres Generar la estructura y habilitarla? s/N → " input
    if [[ $input = 's' ]] || [[ $input = 'S' ]]; then
        generar_www
    else
        echo -e "$VE No se genera la estructura predefinida y automática$CL"
    fi

    ## Generar enlaces (desde ~/web a /var/www)
    function enlaces() {
        clear
        echo -e "$VE Puedes generar un enlace en tu home ~/web hacia /var/www/html"
        read -p " ¿Quieres generar el enlace? s/N → " input
        if [[ $input = 's' ]] || [[ $input = 'S' ]]; then
            sudo ln -s '/var/www/html/' "/home/$mi_usuario/web"
            sudo chown -R "$USER:apache" "/home/$USER/web"
        else
            echo -e "$VE No se crea enlace desde ~/web a /var/www/html$CL"
        fi

        clear
        echo -e "$VE Puedes crear un directorio para repositorios GIT en tu directorio personal"
        echo -e "$VE Una vez creado se añadirá un enlace al servidor web"
        echo -e "$VE Este será desde el servidor /var/www/html/Publico/GIT a ~/GIT$RO"
        read -p " ¿Quieres crear el directorio y generar el enlace? s/N → " input
        if [[ $input = 's' ]] || [[ $input = 'S' ]]; then
            mkdir ~/GIT 2>> /dev/null && echo -e "$VE Se ha creado el directorio ~/GIT" || echo -e "$VE No se ha creado el directorio ~/GIT"
            sudo ln -s /home/$USER/GIT /var/www/html/Publico/GIT
            sudo chown -R "$USER:apache" "/home/$USER/GIT"
        else
            echo -e "$VE No se crea enlaces ni directorio ~/GIT$CL"
        fi
    }

    enlaces

    activar_hosts() {
        echo -e "$VE Añadiendo Sitios Virtuales$AM"
        echo "127.0.0.1 privado" | sudo tee -a /etc/hosts
        echo "127.0.0.1 privado.local" | sudo tee -a /etc/hosts
        echo "127.0.0.1 p.local" | sudo tee -a /etc/hosts
        echo "127.0.0.1 publico" | sudo tee -a /etc/hosts
        echo "127.0.0.1 publico.local" | sudo tee -a /etc/hosts
    }

    read -p " ¿Quieres añadir sitios virtuales a /etc/hosts? s/N → " input
    if [[ $input = 's' ]] || [[ $input = 'S' ]]; then
        activar_hosts
    else
        echo -e "$VE No se añade nada a$RO /etc/hosts$CL"
    fi

    ## Cambia los permisos
    permisos() {
        echo -e "$VE Asignando permisos$CL"
        sudo chmod 775 -R /var/www/*
        sudo chmod 700 /var/www/.htpasswd
        sudo chmod 700 /var/www/html/Privado/.htaccess
        sudo chmod 700 /var/www/html/Publico/.htaccess
        sudo chmod 700 /var/www/html/Privado/CMS/.htaccess
        sudo chmod 755 -R /etc/httpd/
    }
    permisos
}

apache2_instalar() {
    echo -e "$VE Instalando$RO Apache2$CL"
    instalarSoftware 'httpd' 'httpd-filesystem' 'httpd-tools' 'system-config-httpd' 'web-assets-httpd'
}

apache2_postconfiguracion() {
    echo -e "$VE Generando Post-Configuraciones$RO Apache2$CL"

    ## Activar Módulos
    echo -e "$VE Activando módulos$CL"
    #sudo a2enmod rewrite

    ## Desactivar Módulos
    echo -e "$VE Desactivando módulos$CL"
    #sudo a2dismod php5

    ## Añadir excepciones al cortafuegos
    sudo firewall-cmd --add-service={http,https} --permanent
    sudo firewall-cmd --reload

    ## Habilitar inicio del servidor al arrancar
    sudo systemctl enable httpd.service

    ## Reiniciar servidor Apache para aplicar configuración
    sudo systemctl start httpd.service || sudo systemctl restart httpd.service
}
###########################
##       EJECUCIÓN       ##
###########################
apache2_Instalador() {
    apache2_instalar
    apache2_preconfiguracion
    apache2_postconfiguracion
}
