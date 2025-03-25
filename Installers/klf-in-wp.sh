#!/bin/bash
set -e

function helper() {
    echo " Usage : $0 [ -d | --database DATABASE ] [ -u | username ADMINNAME ] [ -l | --lamp ] [ -h | --help ]"
    echo " Options :"
    echo "    -d, --database DATABASE : Database name"
    echo "    -u, --username ADMINNAME : Username of the database administrator"
    echo "    -l, --lamp : This will install a lamp server on this host"
    echo "    -h, --help : Display this help message"
    exit 0
}

function adminPasswordCreation() {
    echo "Please enter a new password for the database administration account"
    read -s WP_ADMIN_PASSWORD
    echo "Confirm password"
    read -s PASSCONFIRM

    if [[ ! $PASSCONFIRM == $WP_ADMIN_PASSWORD ]];then
        echo "Password not matching, exiting installation process"
        exit 102
    fi
}

function initializeVariables() {
    WP_DB_NAME=''
    WP_ADMIN=''
    WP_ADMIN_PASSWORD=''
    LAMP_INSTALL=false
    DATE=$(date --iso-8601)
    TMP_FOLDER=/tmp/wp
    LOG_FOLDER=/var/log/klftb/
    LOG_FILE=wp-in.log
    APACHE_PATH=/var/www/html
    OPTS=$(getopt -o hld:u: --long help,lamp,database:,username: -n 'wordpress' -- "$@")
}

function sortArgs() {

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -d | --database)
                echo $1
                WP_DB_NAME=$2
		shift 2
                ;;
            -l | --lamp)
                echo $1
                LAMP_INSTALL=TRUE
		shift
                ;;
            -u | --username)
                echo $1
                WP_ADMIN=$2
		shift 2
                ;;
            -h | --help)
                echo $0
                helper
		shift
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

function handleFiles() {
    if [[ ! -d $LOG_FOLDER ]];then
        sudo mkdir -p $LOG_FOLDER
        if [[ ! -f $LOG_FOLDER/$LOG_FILE ]]; then
            sudo touch $LOG_FOLDER/$LOG_FILE
        fi
    fi
    
    if [[ ! -d $TMP_FOLDER ]];then
        sudo mkdir -p $TMP_FOLDER 1>$LOG_FOLDER/$LOG_FILE 2>&1
    else
        sudo rm -r $TMP_FOLDER/
        sudo mkdir -p $TMP_FOLDER 1>$LOG_FOLDER/$LOG_FILE 2>&1
    fi
}

initializeVariables "$@"
sortArgs
handleFiles

    if [[ -z $WP_DB_NAME || -z $WP_ADMIN ]]; then
        echo 'Missing options'
        helper
        exit 101
    fi
adminPasswordCreation

if [[ $LAMP_INSTALL == true ]];then
    echo 'The lamp server installation will start soon'
    if [[ $(command -v klf-in-lamp) ]];then
        klf-in-lamp
    else
        echo "The lamp installation program could not be found on your system, make sure it exist in your '/usr/bin' directory or reinstall the program"

    fi
fi

if [[ -e /var/log/wordpressinstall ]]; then
    sudo rm -rf /var/log/wordpressinstall
fi

echo "before dl"
sudo wget -c https://wordpress.org/latest.zip -O $TMP_FOLDER/latest.zip 1>$LOG_FOLDER/$LOG_FILE 2>&1
echo "after dl"
sudo mysql -su root -p<<EOS
CREATE DATABASE $WP_DB_NAME;
CREATE USER '$WP_ADMIN'@'localhost' IDENTIFIED BY '$WP_ADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO $WP_ADMIN@localhost;
FLUSH PRIVILEGES;
EOS

sudo rm $APACHE_PATH/index.html 1>$LOG_FOLDER/$LOG_FILE 2>&1

sudo apt update

if [[ ! $(command -v zip) ]];then
    sudo apt install zip -y
fi

sudo unzip $TMP_FOLDER/latest.zip -d $APACHE_PATH 1>$LOG_FOLDER/$LOG_FILE 2>&1
sudo mv $APACHE_PATH/wordpress/* $APACHE_PATH/ 1>$LOG_FOLDER/$LOG_FILE 2>&1
sudo rm $APACHE_PATH/wordpress/ -Rf 1>$LOG_FOLDER/$LOG_FILE 2>&1

sudo chown -R www-data:www-data $APACHE_PATH/ 1>$LOG_FOLDER/$LOG_FILE 2>&1

echo 'The latest version of wordpress has been succesfully installed'
echo 'You can now access your wordpress web interfaces at :'
echo 'http://localhost/wp-admin/'
