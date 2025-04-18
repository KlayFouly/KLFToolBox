#!/bin/bash

function helper() {
    echo " Usage : $0 [ -f | --fresh ] [ -h | --help ]"
    echo " Options :"
    echo "    -p, --path : [default : /usr/bin] Define the PATH directory where the scripts will be installed"
    echo "    -h, --help : Display this help message"
    exit 0
}
function sortArgs(){

    eval set -- "$OPTS"

    while true;do
        case "$1" in
            -h | --help)
                helper
                shift
                break
                ;;
            -p | --path)
                PATH_DIR=$2
                shift 2
                ;;
            --)
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

function variablesInitialize(){
    LOG_DIR=/var/log/klftb/
    LOG_FILE=installer.log
    FILES="Installers/*"
    INSTALLER_DIRECTORY=Installers/
    PATH_DIR=/usr/bin/
    OPTS=$(getopt -o hp: --long help,path: -n 'install' -- "$@")
}

function installScripts(){
    sudo chmod -R +x $FILES 
    for f in $FILES
    do
        echo "Installing $f..."
        mv "${f}" "${f/.sh/}" 
    done

    sudo cp $FILES $PATH_FILES
}

variablesInitialize "$@"
sortArgs
installScripts