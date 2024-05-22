#!/bin/bash

################################################################################
##                                                                            ##
## Fonctions communes utilisées dans l'ensemble des scripts                   ##
##                                                                            ##
################################################################################

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

clear

# Chemin absolu du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Configuration initiale avec des chemins absolus
CONFIG_FILE="$SCRIPT_DIR/env.conf"
ENV_DIR="$SCRIPT_DIR"
LOG_FILE="$SCRIPT_DIR/log/env_update.log"

# Validation du fichier de configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Le fichier de configuration spécifié n'existe pas : $CONFIG_FILE ${NC}"
    exit 1
fi

# Demander confirmation
read -p "$(echo -e "${CYAN}Êtes-vous sûr de vouloir modifier tous les fichiers .env trouvés ? (y/n) ${NC}")" response
if [[ "$response" != "y" ]]; then
    echo -e "${RED}Annulation des modifications.${NC}"
    exit 0
fi

# Préparation de la journalisation
echo -e "${GREEN}Début de la mise à jour : $(date)${NC}" > $LOG_FILE

# Traitement des variables d'environnement
while IFS='=' read -r key value
do
    key=$(echo $key | xargs)
    value=$(echo $value | xargs)
    value="${value//"/"/"\/"}" # change le "/" à "\/" pour etre compatible avec 'sed'
    # Trouver et traiter chaque fichier .env
    find $ENV_DIR -type f -name "*.env" -print0 | while IFS= read -r -d $'\0' file
    do
        # Sauvegarde du fichier avant modification
        cp "$file" "${file}.bak"
        line=$(grep -n "^$key=" "$file" | cut -d ":" -f 1)
        if [ ! -z "$line" ]; then
            if [ "$key" == "REPOSITORY_PATH" ]; then
                value=$(pwd)
            fi
           
            sed -i "${line}s/.*/$key=$value/" "$file"
        fi
        echo -e "${GREEN}Ajouté dans le fichier $file: $key avec la valeur '$value'${NC}" | tee -a $LOG_FILE  
    done
done < "$CONFIG_FILE"

# Résumé des modifications
echo -e "${YELLOW}Mise à jour terminée. Les modifications ont été effectuées.${NC}" | tee -a $LOG_FILE
echo -e "${YELLOW}Total de fichiers modifiés: $(grep -c 'Mise à jour du fichier' $LOG_FILE)${NC}" | tee -a $LOG_FILE
