#!/bin/bash
set -e

if [[ -e /var/log/lampinstall ]]; then
    sudo rm -rf /var/log/lampinstall
fi

function apacheInstall(){
    echo $'starting Apache2 installation...'
    sudo apt-get -qq install apache2 -y 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'done\n'
    sudo systemctl enable apache2 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'Apache2 service started successfully'
}

function apacheModEnabling(){
    echo $'\nEnabling apache2 modules...'
    sudo a2enmod rewrite 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'\trewrite enabled'
    sudo a2enmod ssl 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'\tssl enabled'
    sudo a2enmod headers 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'\theaders enabled'
    sudo a2enmod deflate 1>/var/log/lampinstall/lamp.log 2>&1
    echo $'\tdeflate enabled'
    echo $'done'
}

function mariadbInstall(){
    echo $'\nInstalling MariaDB...'
    sudo apt -qq install -y mariadb-server 1>/var/log/lampinstall/lamp.log 2>&1
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
EOS
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
    sudo apt -qq install -y apache2-utils 1>/var/log/lampinstall/lamp.log 2>&1
    sudo apt -qq install -y php 1>/var/log/lampinstall/lamp.log 2>&1
    sudo apt -qq install -y php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath 1>/var/log/lampinstall/lamp.log 2>&1
    echo 'done'
}

function createFiles(){
    sudo mkdir -p /var/log/lampinstall
    sudo touch /var/log/lampinstall/lamp.log
    sudo chmod 777 /var/log/lampinstall/lamp.log
}

if [[ -z "${DB_PASSWORD}" ]]; then
    echo "DB_PASSWORD variable is required"
    echo "use: export DB_PASSWORD=your_password"
    exit 1
fi

echo "Please enter a password for the root user to connect to mariadb..."
read -s DB_PASSWORD
echo "Confirm password..."
read -s PASSCONFIRM

if [[ $DB_PASSWORD = $PASSCONFIRM ]];then
    echo "Password not matching, exiting installation process"
    exit 102
fi

echo $'Installing LAMP Serveur...\n'
echo $'Updating package list...\n'
sudo apt-get -qq update -y 1>/var/log/lampinstall/lamp.log 2>&1

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
