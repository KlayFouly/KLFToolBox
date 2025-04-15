#!/bin/bash

# check year

## if year + 1 % 4 = 0 && month > 02 => timestamp 31702400
## if year % 4 = 0 && month < 03 => timestamp 31702400
## else => timestamp 31616000

CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
END_OF_SERVICE=0;
CURRENT_DATE=$(date +%s)

if (( $CURRENT_YEAR % 4 == 0 )) && (( $CURRENT_MONTH > 2 )); then
    EXPIRE_TIMESTAMP=31702400
elif (( $CURRENT_YEAR + 1 % 4 == 0 )) && (( $CURRENT_MONTH < 3 )); then
    EXPIRE_TIMESTAMP=31702400
else
    EXPIRE_TIMESTAMP=31616000
fi

END_OF_SERVICE=$(($CURRENT_DATE + $EXPIRE_TIMESTAMP))

if $(-f /etc/profile.d/expire.sh); then
    echo "Le fichier expire.sh existe déjà."
    echo "Suppression du fichier expire.sh"
    sudo rm -f /etc/profile.d/expire.sh
    echo "Création d'un nouveau fichier expire.sh"
    sudo touch /etc/profile.d/expire.sh
    sudo chmod 755 /etc/profile.d/expire.sh
    sudo chown root:root /etc/profile.d/expire.sh
    echo "Ajout de la variable d'environnement END_OF_SERVICE"
    sudo echo "export END_OF_SERVICE=$END_OF_SERVICE" > /etc/profile.d/expire.sh
    echo "Le fichier expire.sh a été mis à jour avec succès."
else
    echo "Le fichier expire.sh n'existe pas. Création du fichier."
    sudo touch /etc/profile.d/expire.sh
    sudo chmod 755 /etc/profile.d/expire.sh
    sudo chown root:root /etc/profile.d/expire.sh
fi

    sudo echo "export END_OF_SERVICE=$END_OF_SERVICE" > /etc/profile.d/expire.sh

echo $END_OF_SERVICE
echo $(date -d @$END_OF_SERVICE +%d-%m-%Y)



TEMP_PASS=""

function passwordGenerator()
{
    # Génération d'un mot de passe temporaire sécurisé
    TEMP_PASS=$(sudo dmidecode -s system-product-name)-$(sudo dmidecode -s system-serial-number)
    echo "$TEMP_PASS"
}

passwordGenerator



###### OLD ######
#DATEV = "$1"
#NOW = $(date +%Y%m%d)

#if (echo '$NOW' >= echo '$DATEV') then
# Génération d'un mot de passe temporaire sécurisé
#TEMP_PASS="goupilgoupil"  # À remplacer par un générateur en production

# Modification du mot de passe
if echo -e "$TEMP_PASS\n$TEMP_PASS" | passwd "goupil" &>/dev/null; then
    echo "✅ Mot de passe temporaire défini"
else
    echo "❌ Échec du changement de mot de passe" >&2
    exit 1
fi

# Verrouillage des paramètres de sécurité
passwd -e "goupil"  # Expiration immédiate du mot de passe
chage -d 0 "goupil"  # Obligation de changement au prochain login
fi

exit 0

