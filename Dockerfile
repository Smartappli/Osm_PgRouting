FROM ubuntu:18.04

RUN apt-get update \
      && sudo apt install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg \
      && sudo apt install -y nano htop git curl bash \
      && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
      && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
      && sudo apt update \
      && sudo apt upgrade -y \
      && sudo apt install -y osmosis postgresql-10 postgresql-10-postgis-2.4 postgresql-contrib-10 \
      && sudo apt install -y git autoconf libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev g++ libmapnik-dev mapnik-utils python-mapnik \
      && sudo apt install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont fonts-dejavu-core fonts-droid-fallback ttf-unifont fonts-sipa-arundina fonts-sil-padauk fonts-khmeros fonts-beng-extra fonts-gargi fonts-taml-tscu fonts-tibetan-machine

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
      
# mapnik 3.0.16
RUN sudo apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik
# mod-tile
RUN cd ~/src \
      && git clone git://github.com/SomeoneElseOSM/mod_tile.git \
      && cd mod_tile \
      && ./autogen.sh \
      && ./configure \
      && make \
      sudo make install \
      sudo make install-mod_tile \
      sudo ldconfig

# nodejs 8.x
RUN cd ~/src \
      && curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
      && sudo bash nodesource_setup.sh \
      && sudo apt-get install -y nodejs \
      && npm install -g carto \
   
# Tile directories
RUN sudo mkdir -p /var/lib/flat_nodes \
      && sudo chown osm:osm /var/lib/flat_nodes \
      && sudo mkdir /var/lib/mod_tile \
      && sudo chown osm:osm /var/lib/mod_tile \
      && sudo mkdir /var/run/renderd \
      && sudo chown osm:osm /var/run/renderd
      
# pgrouting 2.5.2
RUN apt install -y packaging-dev checkinstall libboost-graph-dev libpq-dev libexpat1-dev postgresql-client libboost-program-options-dev libcgal-dev libpqxx-dev postgresql-server-dev-10 \
      && apt install -y python-sphinx texlive doxygen \
      && wget https://github.com/pgRouting/pgrouting/archive/v2.6.0.zip \
      && unzip v2.6.0.zip \
      cd pgrouting-2.6.0 \
      && mkdir build \
      && cd build \
      && cmake -DWITH_DOC=ON .. \
      && make \
      && sudo make install \
      && sudo -u postgres -i createuser osm \
      && sudo -u postgres -i createdb -E utf8 -l en_US.UTF-8 -T template0 -O osm gis
