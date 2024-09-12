FROM postgres:15
ENV POSTGRE_USER postgres
ENV POSTGRES_PASSWORD B@nLgU4qz*9?D~3n83
ENV POSTGRES_DB cogip

# Mise à jour du système
# RUN apt update 

# Installation du client Git
# RUN apt install -yq git

# INstallation des outils de build pour compilation du plugin debugger
# RUN apt install -yq build-essential
# On se déoplace dans le dossier dans lequel nous allons vouloir télécharger le code source du plugin
# RUN cd /usr/local/src
# RUN git clone git://git.postgresql.org/git/pldebugger.git

# copie du fichier de création de BDD dans le conteneur
# lancement automatique du script
COPY cogip-supply-postgre.sql /docker-entrypoint-initdb.d/