FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=fr_BE.UTF-8 \
TZ=Europe/Brussels

RUN adduser --disabled-password --gecos "" osm

RUN apt-get update \
      && apt install -y libboost-all-dev git-core tar unzip lbzip2 wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng-dev libwebp-dev libtiff-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg \
      && apt install -y sudo nano htop git curl bash tzdata locales debconf apt-utils \
      && sudo locale-gen en_US.UTF-8 \
      && echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
      && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
      && apt update \
      && apt upgrade -y \
      && apt install -y osmosis postgresql-10 postgresql-10-postgis-2.4 postgresql-contrib-10 \
      && apt install -y git autoconf libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev g++ libmapnik-dev mapnik-utils python-mapnik \
      && apt install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont fonts-dejavu-core fonts-droid-fallback ttf-unifont fonts-sipa-arundina fonts-sil-padauk fonts-khmeros fonts-beng-extra fonts-gargi fonts-taml-tscu fonts-tibetan-machine

RUN echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections \
      && echo 'tzdata tzdata/Zones/Europe select Brussels' | debconf-set-selections \
      && echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
      && apt-get -y install wget tzdata locales \
      && locale-gen $LANG \
      && export LANG=fr_BE.UTF-8 \
      && dpkg-reconfigure -f noninteractive locales \
      && echo ${TZ} > /etc/timezone \
      && dpkg-reconfigure -f noninteractive tzdata \
      && echo "Contents of /etc/timezone and /etc/default/locale :" \
      && cat /etc/timezone && cat /etc/default/locale

# Tuning de postgresql
RUN sed 's/md5/trust/' /etc/postgresql/10/main/pg_hba.conf \
      && sed 's/peer/trust/' /etc/postgresql/10/main/pg_hba.conf
      
# osm2pgsql 0.95 dev
RUN mkdir ~/src \
      && cd ~/src \
      && git clone git://github.com/openstreetmap/osm2pgsql.git \
      && cd osm2pgsql \
      && sudo apt install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev \
      && mkdir build && cd build \
      && cmake .. \
      && make \
      && make install
      
# mapnik 3.0.19
RUN sudo apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev libmapnik-dev mapnik-utils python-mapnik
# mod-tile
RUN cd ~/src \
      && git clone git://github.com/SomeoneElseOSM/mod_tile.git \
      && cd mod_tile \
      && ./autogen.sh \
      && ./configure \
      && make \
      && sudo make install \
      && sudo make install-mod_tile \
      && sudo ldconfig

# nodejs 8.x
RUN cd ~/src \
      && curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
      && sudo bash nodesource_setup.sh \
      && sudo apt-get install -y nodejs \
      && npm install -g carto 
   
# Tile directories
RUN sudo mkdir -p /var/lib/flat_nodes \
      && sudo chown osm:osm /var/lib/flat_nodes \
      && sudo mkdir /var/lib/mod_tile \
      && sudo chown osm:osm /var/lib/mod_tile \
      && sudo mkdir /var/run/renderd \
      && sudo chown osm:osm /var/run/renderd
      
# pgrouting 2.6.0
RUN apt install -y packaging-dev checkinstall libboost-graph-dev libpq-dev libexpat1-dev postgresql-client libboost-program-options-dev libcgal-dev libpqxx-dev postgresql-server-dev-10 \
      && apt install -y python-sphinx texlive doxygen \
      && wget https://github.com/pgRouting/pgrouting/archive/v2.6.0.zip \
      && unzip v2.6.0.zip \
      && cd pgrouting-2.6.0 \
      && mkdir build \
      && cd build \
      && cmake -DWITH_DOC=ON .. \
      && make \
      && sudo make install 
      
RUN service postgresql start \
      && sudo -u postgres bash -c "psql -c \"CREATE USER osm WITH PASSWORD 'osm';\"" \
      && sudo -u postgres createdb -E utf8 -l en_US.UTF-8 -T template0 -O osm gis \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION hstore;\" -d gis" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION postgis;\" -d gis" \
      && sudo -u postgres createdb -O osm routing \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION postgis;\" -d routing" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION pgrouting;\" -d routing" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION hstore;\" -d routing" \
      && sudo -u postgres createdb -O osm cars \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION postgis;\" -d cars" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION pgrouting;\" -d cars" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION hstore;\" -d cars" \
      && sudo -u postgres createdb -O osm bicycles \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION postgis;\" -d bicycles" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION pgrouting;\" -d bicycles" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION hstore;\" -d bicycles" \
      && sudo -u postgres createdb -O osm pedestrian \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION postgis;\" -d pedestrian" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION pgrouting;\" -d pedestrian" \
      && sudo -u postgres bash -c "psql -c \"CREATE EXTENSION hstore;\" -d pedestrian" \
      && service postgresql stop \
      
# osm2pgrouting
RUN cd ~/src \
      && wget https://github.com/pgRouting/osm2pgrouting/archive/v2.3.5.zip \
      && unzip v2.3.5.zip \
      && cd osm2pgrouting-2.3.5 \
      && cmake -H. -Bbuild \
      && cd build \
      && make \
      && make install      

# openstreetmap-carto 4.12 dev
RUN su - osm \
      && cd ~ \
      && git clone https://github.com/gravitystorm/openstreetmap-carto.git \
      && cd openstreetmap-carto \
      && carto -a "3.0.10" project.mml > style.xml \ 
      && scripts/get-shapefiles.py
      
RUN sed 's/md5/trust/' /etc/postgresql/10/main/pg_hba.conf \
      && sed 's/peer/trust/' /etc/postgresql/10/main/pg_hba.conf \
      && service postgresql start \
      && su - osm \
      && cd ~ \
      && wget -c http://download.geofabrik.de/africa/algeria-latest.osm.pbf \
      && osm2pgsql --create --slim -G -d gis -C 2000 --hstore -S openstreetmap-carto/openstreetmap-carto.style --tag-transform-script openstreetmap-carto/openstreetmap-carto.lua --number-processes 1 --flat-nodes /var/lib/flat_nodes/flat-nodes.bin planet-latest.osm.pbf \
      && rm algeria-latest.osm.pbf \
      && sudo -u postgres bash -c "psql -d gis -f indexes.sql" \
      && exit \
      && cd ~ \ 
      && sed 's/XML=\/home\/renderaccount\/src\/openstreetmap-carto\/mapnik.xml/XML=\/home\/osm\/src\/openstreetmap-carto\/style.xml/' /usr/local/etc/renderd.conf \
      && sudo sh -c 'echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" > /etc/apache2/conf-available/mod_tile.conf' \
      && sudo a2enconf mod_tile \
      && sed 's/<\/VirtualHost>/LoadTileConfigFile \/usr\/local\/etc\/renderd.conf/' /etc/apache2/sites-enabled/000-default.conf \
      && sudo sh -c 'echo "ModTileRenderdSocketName /var/run/renderd/renderd.sock" > /etc/apache2/sites-enabled/000-default.conf' \
      && sudo sh -c 'echo "ModTileRequestTimeout 0" > /etc/apache2/sites-enabled/000-default.conf' \
      && sudo sh -c 'ModTileMissingRequestTimeout 30" > /etc/apache2/sites-enabled/000-default.conf' \
      && sudo sh -c 'echo "</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf' \
      && sudo service apache2 reload \
      && sudo service apache2 reload \
      && sed 's/RUNASUSER=renderaccount/RUNASUSER=osm/' ~/src/mod_tile/debian/renderd.init \
      && sudo cp ~/src/mod_tile/debian/renderd.init /etc/init.d/renderd \
      && sudo chmod u+x /etc/init.d/renderd \
      && sudo cp ~/src/mod_tile/debian/renderd.service /lib/systemd/system/ \
      && sudo /etc/init.d/renderd start \
      && sudo systemctl enable renderd
