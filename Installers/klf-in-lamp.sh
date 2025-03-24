#!/bin/bash
set -e

function helper() {
    echo "Usage : $0 [ -f | --fresh ] [ -h | --help ]"
    echo "Options :"
    echo " -f, --fresh : Fresh installation ( Warning ! Will remove all existing lamp serveurs and databases)"
    echo " -h, --help : Display this help message"
}

function sortArgs() {

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -h | --help)
                echo $0
                helper
                shift 2
                ;;
            -f | --fresh)
                echo $1
                uninstallComponent
                shift 2
                ;;
            --)
                echo $1
                shift
                break
                ;;
            *)
                echo "$1 : Unknown options"
                exit 101
                ;;
        esac
    done
}

function variablesInitialize() {
    LOG_DIR=/var/log/klftb/
    LOG_FILE=lamp-in.log
    DB_PASSWORD=''
    PASSCONFIRM=''
    DATE=$(date --iso-8601)
    OPTS=$(getopt -o hf --long help,fresh -n 'lamp' -- "$@")
}

function adminPasswordCreation() {
    echo "Please enter a password for the root user to connect to mariadb..."
    read -s WP_ADMIN_PASSWORD
    echo "Confirm password"
    read -s PASSCONFIRM

    if [[ ! $DB_PASSWORD = $PASSCONFIRM ]];then
        echo "Password not matching, exiting installation process"
        exit 102
    fi
}

function uninstallComponent(){
    # Complete MariaDB Uninstall
    echo "The -r option"
    read UNINST_CHOICE

    if [[dpkg -l | grep mariadb]];then
        sudo apt-get -qq autoremove mariadb -y 1>$LOG_DIR$LOG_FILE 2>&1
        sudo apt-get -qq autopurge mariadb -y 1>$LOG_DIR$LOG_FILE 2>&1
    fi

    if [[dpkg -l | grep apache2]];then
        sudo apt-get -qq autoremove apache2 -y 1>$LOG_DIR$LOG_FILE 2>&1
        sudo apt-get -qq autopurge apache2 -y 1>$LOG_DIR$LOG_FILE 2>&1
    fi

    if [[dpkg -l | grep php]];
}

function apacheInstall(){
    echo $'starting Apache2 installation...'
    sudo apt-get -qq install apache2 -y 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'done\n'
    sudo systemctl enable apache2 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'Apache2 service started successfully'
}

function apacheModEnabling(){
    echo $'\nEnabling apache2 modules...'
    sudo a2enmod rewrite 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'\trewrite enabled'
    sudo a2enmod ssl 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'\tssl enabled'
    sudo a2enmod headers 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'\theaders enabled'
    sudo a2enmod deflate 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'\tdeflate enabled'
    echo $'done'
}

function mariadbInstall(){
    echo $'\nInstalling MariaDB...'
    sudo apt -qq install -y mariadb-server 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'done'
}

function mariadbSec(){
    echo $'\nSecuring MySQL...'
    sudo mysql -sfu root <<EOS
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS 1>$LOG_DIR$LOG_FILE 2>&1
    echo $'\tNew password set for user root'
    echo $'\tAnonymous users deleted'
    echo $'\tRemote root capabilities deleted'
    echo $'\tTest database dropped'
    echo $'\tTest database permissions deleted'
    echo $'\tChanges applied'

    echo $'MySQL secured successfully'
}

function phpInstall(){
    echo $'\nInstalling PHP...'
    sudo apt -qq install -y apache2-utils 1>$LOG_DIR$LOG_FILE 2>&1
    sudo apt -qq install -y php 1>$LOG_DIR$LOG_FILE 2>&1
    sudo apt -qq install -y php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath 1>$LOG_DIR$LOG_FILE 2>&1
    echo 'done'
}

function handleFiles(){
    if [[ ! -d $LOG_DIR]];then    
        sudo mkdir -p /var/log/lampinstall
    fi
    
    if [[ ! -e $LOG_DIR$LOG_FILE]];then
        sudo touch $LOG_DIR$LOG_FILE
        sudo chmod 777 $LOG_DIR$LOG_FILE
    else
        echo ' >> New LOG Entry :'
        echo " >> Starting to log script at : $DATE"
    fi
}

echo $'Installing LAMP Serveur...\n'
echo $'Updating package list...\n'
sudo apt-get -qq update -y 1>$LOG_DIR$LOG_FILE 2>&1

handleFiles
variablesInitialize
adminPasswordCreation

## Installation process ##
apacheInstall
phpInstall
mariadbInstall
mariadbSec
apacheModEnabling


sudo systemctl restart apache2
echo $'\nApache2 restarted successfully\n'

echo 'MariaDb version: '
echo '  '$(mariadb -V)$'\n'
echo 'PHP version: '
echo '  '$(php -v)$'\n'
echo 'Apache2 version: '
echo '  '$(apache2ctl -v)$'\n'

echo 'LAMP Serveur has been successfully installed and is ready to use'
echo 'You can access your server at http://localhost or http://your_ip_address'
