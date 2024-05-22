Ordre de Déploiement Recommandé et Bonnes Pratiques

    MongoDB : En tant que base de données, elle devrait être déployée en premier pour assurer que les autres services ayant besoin de stockage de données puissent se connecter dès leur lancement.
    Elasticsearch : Souvent utilisé pour l'indexation et la recherche de données, il peut être déployé après MongoDB.
    Greylog : Comme il peut utiliser Elasticsearch pour le stockage des logs, installez-le après Elasticsearch.
    OpenCTI : En tant qu'application frontale, elle devrait être installée en dernier, une fois que toutes les dépendances de backend sont en place.


========
# Installation d'OpenCTI sur Debian et Ubuntu
========


Ce guide fournit des instructions pour l'installation d'OpenCTI sur les systèmes Debian et Ubuntu en utilisant Docker et Docker Compose.

## Prérequis

- Un système d'exploitation Debian ou Ubuntu.
- Accès à un utilisateur avec les privilèges `sudo`.
- Accès à internet pour le téléchargement des depandance

## Installation

Le script `install_opencti.sh` automatise le processus d'installation d'OpenCTI, y compris l'installation de Docker et Docker Compose si nécessaire. Voici les étapes pour utiliser le script :

1. **Téléchargez le Script**

   Vous pouvez télécharger le script directement depuis un dépôt Git ou le copier depuis un guide en ligne.

2. **Rendez le Script Exécutable**

   Avant d'exécuter le script, vous devez le rendre exécutable. Ouvrez un terminal et naviguez jusqu'au dossier contenant `install_opencti.sh`. Exécutez la commande suivante :

-----------------------------------------
|   ```bash				|
|   chmod +x install_opencti.sh		|
|   sudo ./install_opencti.sh		|
-----------------------------------------

================================
Configuration Post-Installation
================================

Après l'installation:

    - OpenSearch sera accessible via le port 9200 de votre hôte.
    - Graylog sera accessible via le port 9000 de votre hôte.
    - OpenCTI sera accessible via le port 8080 de votre hôte.

URL d'accès : http://<VotreAdresseIP>:port
Identifiants par défaut : L'adresse email et le mot de passe par défaut pour le compte administrateur sont configurés dans le script. Il est fortement recommandé de les changer directement dans le script avant l'installation, ou via l'interface d'administration d'OpenCTI après l'installation.

Sécurité
--------

Assurez-vous de changer les valeurs par défaut telles que OPENCTI_TOKEN, OPENCTI_ADMIN_EMAIL, et OPENCTI_ADMIN_PASSWORD par des valeurs sécurisées avant de procéder à l'installation. De plus, il est recommandé de configurer un pare-feu et d'autres mesures de sécurité selon les besoins de votre environnement.
Support

Pour obtenir de l'aide ou signaler un problème avec le script, veuillez contacter Tamir HADDAD OU Loïc SAUTER