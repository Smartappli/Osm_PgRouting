FROM ubuntu:18.04

RUN apt-get update \
      && sudo apt install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg \
      && sudo apt install -y nano htop git curl bash \
      && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main \
      && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
      && sudo apt update \
      && sudo apt upgrade -y
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
