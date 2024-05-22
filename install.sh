#!/bin/bash

# v final

# Définition des couleurs
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # Pas de couleur (normal)



# Variables globales
URL="https://glevents.sharepoint.com/:u:/s/CyberscuritGLSI-ProjectManagement/EcYpvByvTthPnGwpnCK71vABsbB-U81s-bgXZ-TYIfdbmQ?e=WuMpW9"
CURRENT_VERSION_FILE="current_version.txt"
export SCRIPT_LAST_MODIFIED="2024-04-28 20:20:00"


# import le script d'installation des utilitaires
source ./common/install_utils.sh

################################################################################
##                                                                            ##
## Fonctions communes utilisées dans l'ensemble des scripts                   ##
##                                                                            ##
################################################################################

# Fonction pour logger les messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE # Affiche le message avec la date et l'heure actuelle, et ajoute le message au fichier de log.
}

show_logo(){
    echo -e "\e[95m
          ____ _          _____                 _      
         / ___| |        | ____|_   _____ _ __ | |_ ___ 
        | |   _| |   _____| _| \ \ / / _ \ '_ \| __/ __|
        | |_| | |__|_____| |___ \ V /  __/ | | | |_\__ \\
         \____|_____|    |_____| \_/ \___|_| |_|\__|___/
    \e[0m"
    sleep 0 # Pause le script pendant 5 secondes pour que le logo soit visible
}



# Fonction pour afficher les informations du script avec des longueurs spécifiques
# Fonction pour normaliser la longueur de chaque ligne
normalize_line_length() {
    local line="$1"
    local desired_length="$2"
    printf "%-${desired_length}s" "$line"
}

# Fonction pour colorier les titres avant les deux points, les mettre en gras, colorer '--docker' et '--portainer' en rose foncé, et 'yes' ou 'no' en vert fluo
color_and_normalize_line() {
    local line="$1"
    local length="$2"
    if [[ "$line" == "Exemple d'utilisation du script;" ]]; then
        # Appliquer la couleur jaune spécifiquement à cette ligne
        local special_color=$(echo "$line" | sed -E "s/(Exemple d'utilisation du script;)/$(tput setaf 3)$(tput bold)\1$(tput sgr0)/")
        normalize_line_length "$special_color" "$length"
    else
        # Appliquer la couleur bleue et gras pour les titres, sauf pour "Exemple d'utilisation du script;"
        local color_title=$(echo "$line" | sed -E "s/([^:]+):(.*)/$(tput setaf 4)$(tput bold)\1$(tput sgr0):\\2/")
        # Appliquer la couleur rose foncé (tput setaf 5) et gras pour '--docker' et '--portainer'
        local color_modifications=$(echo "$color_title" | sed -E "s/(--docker|--portainer)/$(tput setaf 5)$(tput bold)\1$(tput sgr0)/g")
        # Appliquer la couleur vert fluo (tput setaf 2) pour 'yes' après les deux-points
        local color_yes=$(echo "$color_modifications" | sed -E "s/(: *)(yes)/\\1$(tput setaf 2)\\2$(tput sgr0)/g")
        # Appliquer la couleur rouge (tput setaf 1) pour 'no' après les deux-points
        local color_no=$(echo "$color_yes" | sed -E "s/(: *)(no)/\\1$(tput setaf 1)\\2$(tput sgr0)/g")
        normalize_line_length "$color_no" "$length"
    fi
}

# Fonction pour afficher les informations du script avec des longueurs spécifiques
afficher_infos_script() {
    local order=(
        "Nom du Script: install.sh"
        "Auteur: Imineti"
        "Date de Création:      10/04/2024"
        "Dernière Modification: 21/05/2024 à 15:12"
        "Version: 1.3.10"
        "Description: Script pour installer et gérer des outils Dockerisés."
        "Notes: Informations supplémentaires telles que les dépendances, les exigences, etc."
    )

    declare -A lengths=(
        ["Nom du Script: install.sh"]=101
        ["Auteur: Imineti"]=101
        ["Date de Création:      10/04/2024"]=102
        ["Dernière Modification: 21/05/2024 à 15:12"]=103
        ["Version: 1.3.10"]=101
        ["Description: Script pour installer et gérer des outils Dockerisés."]=103
        ["Notes: Informations supplémentaires telles que les dépendances, les exigences, etc."]=103
    )

    # Bordure supérieure et inférieure du cadre en jaune
    echo "$(tput setaf 3)+$(printf '%0.s-' {1..90})+$(tput sgr0)"

    for line in "${order[@]}"; do
        normalized_line=$(color_and_normalize_line "${line}" "${lengths[$line]}")
        echo "$(tput setaf 3)| $(tput sgr0)$normalized_line $(tput setaf 3)|$(tput sgr0)"
    done

    echo "$(tput setaf 3)+$(printf '%0.s-' {1..90})+$(tput sgr0)"
}

# Fonction de vérification des privilèges administratifs
checkAdminPrivileges() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Ce script doit être exécuté avec des privilèges administratifs.${NC}"
        echo -e "${YELLOW}Voulez-vous relancer ce script avec 'sudo'? (y/n)${NC}"
        read -r -p "Réponse: " answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Relancement du script avec 'sudo'...${NC}"
            exec sudo bash "$0" "$@"
        else
            echo -e "${RED}Le script n'a pas été relancé avec 'sudo'. Arrêt du script.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Exécution en tant qu'administrateur vérifiée.${NC}"
    fi
}

# Fonction pour installer des dépendances
installDependencies() {
    echo -e "${CYAN}Lancement de l'installation des dépendances...${NC}"
	installWgetAndCurl
	# Installation d'autres services ou logiciels si nécessaire
    # Exemple: sudo apt-get install -y apache2
    echo -e "${GREEN}Toutes les dépendances et les services ont été installés avec succès.${NC}"
}

# Fonction pour installer wget et curl
installWgetAndCurl() {
    # Détection du système de gestion de paquets
    if command -v apt-get >/dev/null; then
        PACKAGE_MANAGER="apt-get"
    elif command -v yum >/dev/null; then
        PACKAGE_MANAGER="yum"
    else
        echo -e "${RED}Gestionnaire de paquets non supporté. Veuillez installer wget et curl manuellement.${NC}"
        return 1
    fi

    # Vérification de l'installation de wget
    if ! command -v wget >/dev/null; then
        echo "Installation de wget..."
        sudo $PACKAGE_MANAGER install wget -y
    else
        echo -e "${GREEN}wget est déjà installé.${NC}"
    fi

    # Vérification de l'installation de curl
    if ! command -v curl >/dev/null; then
        echo "Installation de curl..."
        sudo $PACKAGE_MANAGER install curl -y
    else
        echo -e "${GREEN}curl est déjà installé.${NC}"
    fi
}

# Fonction pour vérifier la connectivité Internet
checkInternetConnection() {
    echo -e "${CYAN}Vérification de la connectivité Internet...${NC}"
    # Ping Google DNS
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}Connexion Internet vérifiée.${NC}"
    else
        echo -e "${RED}Aucune connexion Internet. Veuillez vérifier votre réseau.${NC}"
        exit 1
    fi
}

# Vérifier l'accessibilité de l'URL
# Fonction pour vérifier l'accessibilité de l'URL et la disponibilité du fichier
checkURLAccessibility() {
    echo -e "${CYAN}Tentative de connexion à l'URL : $URL${NC}"
    # Utilisation de wget avec un timeout et un nombre d'essais limité
    response=$(wget --spider --timeout=10 --tries=1 "$URL" 2>&1)
    
    if echo "$response" | grep -q '200 OK'; then
        echo -e "${GREEN}L'URL est accessible et le fichier est disponible.${NC}"
    elif echo "$response" | grep -q '404 Not Found'; then
        echo -e "${RED}Erreur : Le fichier n'a pas été trouvé à l'URL spécifiée. Abandon de l'opération.${NC}"
        exit 1
    else
        echo -e "${RED}Erreur : L'URL n'est pas accessible. Vérifiez si le site est disponible ou si l'URL est correcte.${NC}"
        exit 1
    fi
}

# Fonction pour mettre à jour le système d'exploitation
updateOS() {
    echo -e "${CYAN}Mise à jour du système d'exploitation...${NC}"
    sudo apt-get update && sudo apt-get -y upgrade
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}La mise à jour du système a été effectuée avec succès.${NC}"
    else
        echo -e "${RED}Erreur lors de la mise à jour du système.${NC}"
        exit 1
    fi
}

# Fonction pour obtenir la dernière date de modification du fichier ZIP
getLastModifiedFromServer() {
    local server_response=$(wget --spider --server-response "$URL" 2>&1)
    local last_modified=$(echo "$server_response" | grep -i "Last-Modified" | awk '{print $2, $3, $4, $5, $6, $7}')
    date -d "$last_modified" +"%s"
}

# Fonction pour lire la date de la version locale ou la variable d'environnement
getLocalLastModified() {
    # Vérifie si le fichier existe et n'est pas vide
    if [ -f "$CURRENT_VERSION_FILE" ] && [ -s "$CURRENT_VERSION_FILE" ]; then
        local local_last_modified=$(cat "$CURRENT_VERSION_FILE")
        date -d "$local_last_modified" +"%s"
    else
        # Utilisation de la variable d'environnement comme solution de repli
        if [ -n "$SCRIPT_LAST_MODIFIED" ]; then
            date -d "$SCRIPT_LAST_MODIFIED" +"%s"
        else
            echo -e "${RED}Erreur : Aucune information de version locale disponible et la variable d'environnement est non définie.${NC}"
            exit 1
        fi
    fi
}

# Fonction pour vérifier la variable d'environnement comme solution de repli
checkFallback() {
    if [ -n "$SCRIPT_LAST_MODIFIED" ]; then
        echo -e "${YELLOW}Utilisation de la date de version de la variable d'environnement comme solution de repli.${NC}"
        echo "$SCRIPT_LAST_MODIFIED"
    else
        echo -e "${RED}Erreur : Aucune information de version locale disponible et la variable d'environnement est non définie.${NC}"
        exit 1
    fi
}

# Fonction pour vérifier la mise à jour
checkForUpdates() {
    checkURLAccessibility
    local last_modified_server=$(getLastModifiedFromServer)
    local local_last_modified=$(getLocalLastModified)
    if [[ "$last_modified_server" -gt "$local_last_modified" ]]; then
        echo -e "${GREEN}Une nouvelle version du fichier a été détectée.${NC}"
        updateAndRestart
    else
        echo -e "${YELLOW}Aucune mise à jour nécessaire.${NC}"
        sleep 4
		clear
		ask_install
		exit 0
    fi
}

# Fonction pour télécharger et mettre à jour le script
updateAndRestart() {
    # Déterminez le répertoire parent
    PARENT_DIR="$(dirname "$(pwd)")/.."

    # Téléchargez le fichier ZIP dans le répertoire parent
    wget -O "$PARENT_DIR/imineti.zip" "$URL"

    # Sauvegardez le fichier install.sh temporairement
    if [ -f "./install.txt" ]; then
        mv "./install.txt" "$PARENT_DIR/install.txt.backup"
    fi

    # Supprimez tous les fichiers et dossiers à l'exception de install.sh
    find . -mindepth 1 ! -name "install.txt.backup" -exec rm -rf {} +

    # Décompressez le ZIP dans le répertoire parent
    unzip -o "$PARENT_DIR/imineti.zip" -d "$PARENT_DIR"
    rm "$PARENT_DIR/imineti.zip"

    # Restaurez le fichier install.sh à son emplacement original
    if [ -f "$PARENT_DIR/install.txt.backup" ]; then
        mv "$PARENT_DIR/install.txt.backup" "./install.txt"
    fi

    echo "$LAST_MODIFIED" > "$CURRENT_VERSION_FILE"
    echo -e "${YELLOW}Redémarrage du script avec la version mise à jour...${NC}"

    # Assurez-vous que le script d'installation ou de mise à jour est présent et exécutable
    if [ -f "./install.sh" ]; then
        chmod +x ./install.sh
        #exec ./install.sh "$@"
    else
        echo -e "${RED}Erreur : Le script mis à jour n'a pas été trouvé.${NC}"
        exit 1
    fi
}



















################################################################################
##                                                                            ##
## Fonction 	Install GIT 							                      ##
##                                                                            ##
################################################################################



# Charger les variables d'environnement depuis le fichier install.env
if [ -f "./install.env" ]; then
    source ./install.env
else
    echo -e "${RED}Fichier de configuration 'install.env' introuvable. Assurez-vous qu'il est présent dans le même dossier que ce script.${NC}"
    exit 1
fi

# Fonction pour demander les informations d'authentification si elles ne sont pas définies
prompt_for_credentials() {
    if [ -z "$GIT_LOGIN" ] || [ -z "$GIT_PASSWORD" ]; then
        echo "Les informations d'authentification ne sont pas complètes dans 'install.env'."
        if [ -z "$GIT_LOGIN" ]; then
            read -p "Entrez votre login Git : " GIT_LOGIN
        fi
        if [ -z "$GIT_PASSWORD" ]; then
            read -s -p "Entrez votre mot de passe Git : " GIT_PASSWORD
            echo
        fi
    fi
}


# Fonction pour cloner le dépôt Git configuré dans install.env dans un dossier temporaire et nettoyer après
clone_git_repo() {
    prompt_for_credentials
    echo -e "${CYAN}URL du dépôt Git : ${BLUE}$REPO_URL${NC}"
    echo -e "${GREEN}Clonage du dépôt $REPO_URL avec l'utilisateur $GIT_LOGIN...${NC}"

    # Création d'un dossier temporaire pour le clonage
    temp_dir=$(mktemp -d)
    GIT_ASKPASS="echo $GIT_PASSWORD" git clone https://$GIT_LOGIN:$GIT_PASSWORD@$REPO_URL "$temp_dir"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Dépôt cloné avec succès dans un dossier temporaire.${NC}"
        # Déplacer le contenu du dépôt cloné dans le répertoire parent
        echo -e "${CYAN}Transfert des fichiers clonés vers le dossier parent...${NC}"
        rsync -av --remove-source-files "$temp_dir/"* "./"  # Utilisation de rsync pour transférer les fichiers
        # Suppression de tout fichier et dossier restant dans le répertoire temporaire
        rm -rf "$temp_dir"
        echo -e "${GREEN}Les fichiers ont été transférés avec succès et le répertoire temporaire a été entièrement supprimé.${NC}"
    else
        echo -e "${RED}Échec du clonage du dépôt. Vérifiez les informations et réessayez.${NC}"
        # Suppression du répertoire temporaire en cas d'échec de clonage
        rm -rf "$temp_dir"
    fi
}



################################################################################
##                                                                            ##
## Fonction 	Menu 0 									                      ##
##                                                                            ##
################################################################################

ask_install() {
    # Présentation des choix disponibles à l'utilisateur avec coloration
    echo -e "${CYAN}Menu Principal : Sélectionnez l'option désirée	:${NC}\n"
    echo -e "${YELLOW}1) Mettre à jour du script${NC}"
    echo -e "${YELLOW}2) Installer l'éditeur Micro${NC}"
    echo -e "${YELLOW}3) Menu d'installation des produits dockerisés${NC}"
	echo -e "${YELLOW}4) Désinstaller les produits dockerisés${NC}"
    echo -e "${YELLOW}5) Configurer le fichier .env (via envConf)${NC}"
    echo -e "${YELLOW}6) Éditer le fichier .env${NC}"
    echo -e "${YELLOW}7) Installer Docker et Portainer${NC}"
    echo -e "${YELLOW}8) Installer Docker${NC}"
    echo -e "${YELLOW}9) Afficher l'aide${NC}"
    echo -e "${YELLOW}10) Quitter l'application${NC}\n"

    # Lecture du choix de l'utilisateur avec prompt coloré
    read -p "$(echo -e "${CYAN}Choisissez une option (1-10) : ${NC}")" choice

    # Traitement du choix de l'utilisateur
    case $choice in
        1)
            log_message "Démarrage de la mise à jour du script."
            clear
			ask_maj_install
            sleep 4
			clear
			ask_install
			;;
        2)
            log_message "Démarrage de l'installation de l'éditeur Micro."
            clear
            check_micro
            sleep 4
			clear
			ask_install
			;;
		3)
            log_message "Démarrage du menu d'installation des produits dockerisés."
            clear
            install_menu_product
            sleep 6 
			clear
			ask_install
			;;
        4)
            log_message "Démarrage de la désinstallation des produits dockerisés."
            clear
            uninstall_docker_products
            sleep 6 
			clear
			ask_install
			;;
        5)
            log_message "Configuration du fichier .env via envConf."
            chmod +x envconf.sh
            sudo ./envconf.sh
            sleep 6 
			clear
			ask_install
			;;
        6)
            log_message "Ouverture de l'éditeur pour le fichier .env."
            check_micro
            sudo micro env.conf
            clear
			ask_install
			;;
        7)
            log_message "Installation de Docker et Portainer"
            sleep 2 
			clear
            install_portainer_with_docker
			sleep 2
            clear
			ask_install
			;;
        8)
            log_message "Installation de Docker"
            sleep 2 
			clear
			prepare_docker_environment
			sleep 2
            clear
			ask_install
			;;
        9)
            log_message "Affichage de l'aide."
            echo -e "${GREEN}Aide : Ce script permet de gérer les configurations système et logicielles.${NC}"
            sleep 2 
			clear
			display_help
			sleep 2
            clear
			ask_install
			;;
        10)
            log_message "Fermeture de l'application."
            echo -e "${GREEN}Quitter l'application.${NC}"
			exit 0
            ;;
        *)
            echo -e "${RED}Option invalide détectée. Veuillez choisir une option entre 1 et 7.${NC}"
            sleep 2  # Petite pause avant de réafficher le menu
            clear
            ask_install  # Répète la demande si l'option est invalide.
            ;;
    esac
}

################################################################################
##                                                                            ##
## Fonction 	Menu 1 									                      ##
##                                                                            ##
################################################################################

ask_maj_install() {
    # Présentation des choix disponibles à l'utilisateur avec coloration
    echo -e "${CYAN}Menu Mis à jour : Sélectionnez l'option désirée	:${NC}\n"
    echo -e "${YELLOW}1) Mettre à jour le script Mode téléchargement (HTTPS) ${NC}"
    echo -e "${YELLOW}2) Mettre à jour le script Via GIT ${NC}"
    echo -e "${YELLOW}3) Menu Principal${NC}"
    echo -e "${YELLOW}9) Quitter l'application${NC}\n"

    # Lecture du choix de l'utilisateur avec prompt coloré
    read -p "$(echo -e "${CYAN}Choisissez une option (1-7) : ${NC}")" choice

    # Traitement du choix de l'utilisateur
    case $choice in
        1)
            log_message "Démarrage de la mise à jour du script."
            clear
            checkAdminPrivileges
            checkInternetConnection
            installDependencies
            updateOS
            checkForUpdates
            sleep 4
			clear
			ask_install
			;;
        2)
            log_message "Démarrage de la mise à jour du script via GIT."
            clear
            clone_git_repo
            sleep 4
			clear
			ask_install
			;;
		3)
            log_message "Démarrage du menu d'installation des produits dockerisés."
            clear
            ask_install
			;;
        9)
            log_message "Fermeture de l'application."
            echo -e "${GREEN}Quitter l'application.${NC}"
			exit 0
            ;;
        *)
            echo -e "${RED}Option invalide détectée. Veuillez choisir une option entre 1 et 7.${NC}"
            sleep 2  # Petite pause avant de réafficher le menu
            clear
            ask_install  # Répète la demande si l'option est invalide.
            ;;
    esac
}


check_micro(){
    if ! command -v micro &> /dev/null; then
        install_micro_editor
    else
         echo -e "${GREEN}Micro est installé.${NC}"
    fi
}

install_micro_editor() {
    echo -e "${CYAN}Installation de Micro, l'éditeur de texte pour terminal...${NC}"
    # Installation de l'éditeur de texte Micro sans interaction utilisateur
    sudo apt-get install -y micro
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Micro a été installé avec succès.${NC}"
    else
        echo -e "${RED}Erreur lors de l'installation de Micro.${NC}"
    fi
}

# Fonction pour désinstaller les produits dockerisés
uninstall_docker_products() {
   echo -e "${CYAN}Désinstallation des produits dockerisés en cours...${NC}"

    # Vérifie si Docker est installé
    if ! command -v docker >/dev/null; then
        echo -e "${RED}Docker n'est pas installé sur ce système. Aucune action requise.${NC}"
        return
    fi

    # Arrêtez tous les conteneurs Docker en cours d'exécution
    echo -e "${CYAN}Arrêt de tous les conteneurs Docker...${NC}"
    docker stop $(docker ps -aq)

    # Vérifiez si tous les conteneurs sont bien arrêtés
    local running_containers=$(docker ps -q)
    if [ -n "$running_containers" ]; then
        echo "${RED}Certains conteneurs n'ont pas pu être arrêtés. Réessayez ou vérifiez manuellement.${NC}"
        return 1
    else
        echo -e "${GREEN}Tous les conteneurs ont été arrêtés.${NC}"
    fi

    # Suppression de tous les conteneurs
    echo -e "${GREEN}Suppression de tous les conteneurs...${NC}"
    sudo docker rm $(sudo docker ps -aq)
    
    # Suppression de tous les volumes
    echo -e "${GREEN}Suppression de tous les volumes...${NC}"
    sudo docker volume rm $(sudo docker volume ls -q)


    # Optionnel: Supprimer toutes les images Docker
    echo -e "${CYAN}Voulez-vous également supprimer toutes les images Docker ? (y/n)${NC}"
    read -p "Réponse: " remove_images
    if [[ "$remove_images" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Suppression de toutes les images Docker...${NC}"
        sudo docker rmi $(sudo docker images -q)
    fi

    echo -e "${GREEN}Les produits dockerisés ont été désinstallés avec succès.${NC}"
}


# Fonction pour mettre à jour toutes les images Docker installées
update_docker_images() {
    # Afficher un message d'avertissement en rouge
    echo -e "${RED}ATTENTION: Cette opération va arrêter, mettre à jour et redémarrer tous les conteneurs Docker utilisant les images à mettre à jour. Voulez-vous continuer? (Yes/No)${NC}"

    # Demander une confirmation à l'utilisateur
    read -p "$(echo -e "${CYAN}Confirmez-vous l'opération ? (Y/N): ${NC}")" response
    case "$response" in
        [Yy][Ee][Ss]|[Yy])
            echo -e "${GREEN}Lancement de la mise à jour des images Docker...${NC}"
            ;;
        *)
            echo -e "${YELLOW}Mise à jour annulée.${NC}"
            return
            ;;
    esac

    # Récupère la liste des images uniques sans les tags de version
    local images=$(docker images --format "{{.Repository}}" | sort | uniq)

    # Parcours chaque image pour la mettre à jour
    for image in $images; do
        echo -e "${CYAN}Mise à jour de l'image $image...${NC}"
        # Pull la dernière version de l'image
        docker pull $image

        # Trouver tous les conteneurs utilisant cette image, les arrêter, les mettre à jour, et les redémarrer
        docker ps -a --format "{{.ID}}:{{.Image}}" | grep $image | while read container; do
            local container_id=${container%:*}
            local container_image=${container#*:}

            echo -e "${YELLOW}Redémarrage du conteneur $container_id utilisant l'image $container_image...${NC}"
            # Arrêt du conteneur
            docker stop $container_id
            # Suppression du conteneur
            docker rm $container_id
            # Recréation du conteneur avec la même configuration mais avec la nouvelle image
            docker run --name $container_id $(docker inspect --format '{{range .Config.Env}}{{println "-e" .}}{{end}}{{range .HostConfig.Binds}}{{println "-v" .}}{{end}} --restart {{.HostConfig.RestartPolicy.Name}}' $container_id) -d $image
        done
    done

    echo -e "${GREEN}Nettoyage des images Docker non utilisées...${NC}"
    docker image prune -f
    echo -e "${GREEN}Mise à jour terminée.${NC}"
}



################################################################################
##                                                                            ##
## Fonction 	Menu 2 									                      ##
##                                                                            ##
################################################################################


# Fonction d'affichage du menu
install_menu_product() {
    echo -e "${CYAN}Sous-menu d'Installation : Sélectionnez l'action que vous souhaitez exécuter :${NC}\n"
    echo -e "${YELLOW}1) Installer OpenCTI${NC}"
    echo -e "${YELLOW}2) Installer Elasticsearch${NC}"
    echo -e "${YELLOW}3) Installer Graylog${NC}"
    echo -e "${YELLOW}4) Installer OpenSearch${NC}"
    echo -e "${YELLOW}5) Mettre à jour toutes les images Docker installées${NC}"
	echo -e "${YELLOW}6) Menu de Test de Déploiement ${NC}"
	echo -e "${YELLOW}7) Menu Principal${NC}\n"
    echo -e "${YELLOW}9) Quitter${NC}\n"
    read -p "$(echo -e "${CYAN}Choisissez une option (1-5) : ${NC}")" choice
    case $choice in
        1)
            cd OpenCTI
			chmod +x install_opencti.sh
			sudo ./install_opencti.sh
            ;;
        2)
            cd Elasticsearch
			chmod +x install_Elasticsearch.sh
			sudo ./install_Elasticsearch.sh
            ;;
        3)
            cd Graylog
			chmod +x install_graylog.sh
			sudo ./install_graylog.sh
            ;;
        4)
            cd OpenSearch
			chmod +x install_opensearch.sh
			sudo ./install_opensearch.sh
            ;;
		5)
			echo -e "${GREEN}Mettre à jour toutes les images Docker installées${NC}"
            update_docker_images
            ;;
		6)
			echo -e "${GREEN}Menu de Test de Déploiement${NC}"
            clear
			install_menu_test
            ;;
		7)
			echo -e "${GREEN}Menu Principal de l'application.${NC}"
            clear
			ask_install
            ;;
        9)
            echo -e "${GREEN}Quitter l'application.${NC}"
            exit 0
            ;;
			
        *)
            echo -e "${RED}Option invalide. Veuillez choisir une option entre 1 et 5.${NC}"
            sleep 2
            clear
            install_menu_product
            ;;
    esac
}

################################################################################
##                                                                            ##
## Fonction 	Menu 3 									                      ##
##                                                                            ##
################################################################################


# Fonction d'affichage du menu
install_menu_test() {
    echo -e "${CYAN}Sous-menu de Test de Déploiement : Sélectionnez l'action que vous souhaitez exécuter :${NC}\n"
    echo -e "${YELLOW}1) Tester le déploiement de OpenCTI${NC}"
    echo -e "${YELLOW}2) Tester le déploiement de Elasticsearch${NC}"
    echo -e "${YELLOW}3) Tester le déploiement de Graylog${NC}"
    echo -e "${YELLOW}4) Tester le déploiement de Opensearch${NC}"
	echo -e "${YELLOW}5) Menu Principal${NC}\n"
    echo -e "${YELLOW}9) Quitter${NC}\n"
    read -p "$(echo -e "${CYAN}Choisissez une option (1-5) : ${NC}")" choice
    case $choice in
        1)
            # OpenCTI
            echo "Sélectionnez la solution à tester:"
            echo "1. OpenCTI en HTTP"
            echo "2. OpenCTI en HTTPS"
            read -p "Entrez le numéro de la solution: 1/2 " solution_number

            # Détermination du chemin en fonction de la sélection de l'utilisateur
            case $solution_number in
                1) SOLUTION_PATH="../OpenCTI/VM_HTTP/opencti-docker-compose.yml";;
                2) SOLUTION_PATH="../OpenCTI/VM_HTTPS/opencti-docker-compose.yml" ;;
                *) echo -e "${RED}Sélection invalide${NC}"; exit 1 ;;
            esac
            ;;
        2)
            # ElasticSearch
            echo "Sélectionnez la solution à tester:"
            echo "1. ElasticSearch avec 3 clusters"
            echo "2. ElasticSearch avec 1 cluster"
            echo "3. ElasticSearch avec 1 cluster sans Certificat"
            read -p "Entrez le numéro de la solution: 1/2 " solution_number

            # Détermination du chemin en fonction de la sélection de l'utilisateur
            case $solution_number in
                1) SOLUTION_PATH="../Elasticsearch/VM_Principale_Elasticsearch/elasticsearch-docker-compose.yml" ;;
                2) SOLUTION_PATH="../Elasticsearch/VM_Principale_Elasticsearch/single-elasticsearch-docker-compose copy.yml" ;;
                3) SOLUTION_PATH="../Elasticsearch/VM_Principale_Elasticsearch/without-ca-elasticsearch-docker-compose.yml" ;;
                *) echo -e "${RED}Sélection invalide${NC}"; exit 1 ;;
            esac
            ;;
        3)
            # Graylog
            echo "Sélectionnez la solution à tester:"
            echo "1. Graylog avec ElasticSearch"
            echo "2. Graylog avec OpenSearch"
            read -p "Entrez le numéro de la solution: 1/2 " solution_number

            # Détermination du chemin en fonction de la sélection de l'utilisateur
            case $solution_number in
                1) SOLUTION_PATH="../Graylog/VM_ElasticSearch_Graylog/graylog-docker-compose.yml" ;;
                2) SOLUTION_PATH="../Graylog/VM_OpenSearch_Graylog/graylog-docker-compose.yml" ;;
                *) echo -e "${RED}Sélection invalide${NC}"; exit 1 ;;
            esac
            ;;
        4)
            # OpenSearch
            echo "Sélectionnez la solution à tester:"
            echo "1. OpenSearch en https"
            echo "2. OpenSearch en http"
            read -p "Entrez le numéro de la solution: 1/2 " solution_number

            # Détermination du chemin en fonction de la sélection de l'utilisateur
            case $solution_number in
                1) SOLUTION_PATH="../OpenSearch/VM_HTTP/opensearch-docker-compose.yml"
                    sudo curl "https://admin:admin@10.0.10.35:9200" --cacert ./OpenSearch/VM_HTTPS/certs/ca/ca.pem -v
                ;;
                2) SOLUTION_PATH="../OpenSearch/VM_HTTPS/opensearch-docker-compose.yml"
                    sudo curl "http://10.0.10.35:9200" -v
                ;;
                *) echo -e "${RED}Sélection invalide${NC}"; exit 1 ;;
            esac
            sleep 3
            return
            ;;
		5)
			echo -e "${GREEN}Menu Principal de l'application.${NC}"
            clear
			ask_install
            ;;
        9)
            echo -e "${GREEN}Quitter l'application.${NC}"
            exit 0
            ;;
			
        *)
            echo -e "${RED}Option invalide. Veuillez choisir une option entre 1 et 5.${NC}"
            sleep 2
            clear
            install_menu_test
            ;;
    esac
    cd common
    chmod +x ./deploy_test.sh
    sudo ./deploy_test.sh $SOLUTION_PATH
}

display_help() {
    echo -e "${GREEN}Aide du Script:${NC}"
    echo "Ce texte est une introduction à l'aide pour le script."
    echo "L'aide complète est disponible dans le guide d'utilisation accompagnant le script."
    echo "Vous pouvez également trouver des informations détaillées dans la documentation fournie dans le dossier 'doc' du script."
}

# Fonction principale
main() {
    clear
	show_logo
    afficher_infos_script
	checkAdminPrivileges
    ask_install
}

main
