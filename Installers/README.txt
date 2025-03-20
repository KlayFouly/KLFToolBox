Les scripts sont encore en construction, et peuvent contenir des erreurs.

Vous pouvez tout de même les essayer et faire des retours sur d'eventuels bug.




Installation : (procédure a suivre en attendant la création d'un installer)


Copier / coller les script sur votre system

Ajouter la possibilité de les executer :
    sudo chmod +x nom_du_script.sh

déplacer et renommer le(s) script(s) dans votre dossier /usr/bin/
    sudo mv nom_du_script.sh /usr/bin/nom_du_script

vous pouvez maintenant les executer en tappant le nom du script dans votre terminal, comme pour toute autre application
    sudo nom_du_script





Utilisation :

    lamp.sh :
        
        Installation d'un serveur web lamp (Linux, Apache2, Mariadb, php)

        Un message vous avertis de la fin de l'installation, votre serveur web est maintenant installé et accessible a l'addresse : http://localhost/



    wordpress.sh :

        Installation de wordpress sur votre serveur Web

        il est possible en l'etat actuelle d'ajouter l'option -l a la commande afin de lancer le script lamp.sh qui automatise l'installation du serveur lamp (voir consigne d'utilisation du script lamp.sh)

        pour plus d'info sur l'utilisation du script executez le script avec l'option -h ou --help

            wordpress -h   OU   wordpress --help




