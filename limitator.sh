#!/bin/bash

# Script de gestion de l'expiration du mot de passe
# Ce script crée un fichier expire.sh dans /etc/profile.d/
# et y ajoute une variable d'environnement END_OF_SERVICE
# qui contient le timestamp d'expiration du mot de passe


## if year + 1 % 4 = 0 && month > 02 => timestamp 31702400
## if year % 4 = 0 && month < 03 => timestamp 31702400
## else => timestamp 31616000



BIS_TIMESTAMP=31702400
NONBIS_TIMESTAMP=31616000
CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
END_OF_SERVICE=0;
CURRENT_DATE=$(date +%s)
IS_CONNECTED=0
ENV_VAR_DIR=/etc/profile.d/
ENV_VAR_FILE=expire.sh

function check_Internet_Connection()
{
    echo "test internet"
    wget -q --spider http://google.com

    if [ $? -eq 0 ]; then
        echo "Host is connected to internet"
        IS_CONNECTED=1
    else
        echo "No internet connection found, this program need an internet connection to work properly"
        echo "Are you sure you want to continue without an internet connection [y/N] ? (Make sure your timezone is well configured and your system is set to the proper date and time)"
        read ans

        if [[ $ans -eq 'y' ]]; then
            #install
            IS_CONNECTED=0
            echo "starting connectionless installation..."
            sleep 2

        elif [[ $ans -eq 'n' ]]; then
            # no Install
            echo "Cancelling installation"
            sleep 2
            exit 1
        else
            check_Internet_Connection
        fi
    fi
}


check_Internet_Connection

## Enable NTP Synchronization
if [[ $IS_CONNECTED == 1 ]]; then
    echo "Enabling time synchronization..."
    sudo timedatectl set-ntp true
    sleep 5
    echo "Ntp synchronization enabled successfully!"
fi

if (( $CURRENT_YEAR % 4 == 0 )) && (( $CURRENT_MONTH > 2 )); then
    EXPIRE_TIMESTAMP=$BIS_TIMESTAMP
elif (( $CURRENT_YEAR + 1 % 4 == 0 )) && (( $CURRENT_MONTH < 3 )); then
    EXPIRE_TIMESTAMP=$BIS_TIMESTAMP
else
    EXPIRE_TIMESTAMP=$NONBIS_TIMESTAMP
fi

END_OF_SERVICE=$(($CURRENT_DATE + $EXPIRE_TIMESTAMP))

if [[ -f $ENV_VAR_DIR$ENV_VAR_FILE ]]; then
    echo "Le fichier expire.sh existe déjà."
    echo "Suppression du fichier expire.sh"
    sudo rm -f $ENV_VAR_DIR$ENV_VAR_FILE
    sleep 1
    echo "Création d'un nouveau fichier expire.sh"
    sudo touch $ENV_VAR_DIR$ENV_VAR_FILE
    sudo chmod 755 $ENV_VAR_DIR$ENV_VAR_FILE
    sudo chown root:root $ENV_VAR_DIR$ENV_VAR_FILE
    sleep 1
    echo "Ajout de la variable d'environnement END_OF_SERVICE"
    sudo echo "export END_OF_SERVICE=$END_OF_SERVICE" > /$ENV_VAR_DIR$ENV_VAR_FILE
    sleep 2
    echo "Le fichier expire.sh a été mis à jour avec succès."
else
    echo "Le fichier expire.sh n'existe pas. Création du fichier."
    sudo touch $ENV_VAR_DIR$ENV_VAR_FILE
    sudo chmod 755 $ENV_VAR_DIR$ENV_VAR_FILE
    sudo chown root:root $ENV_VAR_DIR$ENV_VAR_FILE
    sleep 1
    echo "Ajout de la variable d'environnement END_OF_SERVICE"
    sleep 2
    sudo echo "export END_OF_SERVICE=$END_OF_SERVICE" > $ENV_VAR_DIR$ENV_VAR_FILE
    echo "Le fichier expire.sh a été mis à jour avec succès."
fi

    sudo echo "export END_OF_SERVICE=$END_OF_SERVICE" > $ENV_VAR_DIR$ENV_VAR_FILE

sleep 5
echo $'\n\n'
echo "End of service timestamp : $END_OF_SERVICE"
echo "Ce pc est activé jusqu'au : "$(date -d @$END_OF_SERVICE +%d-%m-%Y)
