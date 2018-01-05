#!/bin/bash
sudo apt install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg
sudo apt install -y nano htop git curl bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt upgrade -y
sudo apt install -y osmosis postgresql-10 postgresql-10-postgis-2.4 postgresql-contrib-10
sudo apt install -y git autoconf libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev g++ libmapnik-dev mapnik-utils python-mapnik
sudo apt install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont fonts-dejavu-core fonts-droid-fallback ttf-unifont fonts-sipa-arundina fonts-sil-padauk fonts-khmeros fonts-beng-extra fonts-gargi fonts-taml-tscu fonts-tibetan-machine
# Tuning de postgresql
sed 's/md5/trust/' /etc/postgresql/10/main/pg_hba.conf
sed 's/peer/trust/' /etc/postgresql/10/main/pg_hba.conf
# osm2pgsql 0.95 dev
mkdir ~/src
cd ~/src
git clone git://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql
sudo apt install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev
mkdir build && cd build
cmake ..
make
make install
# mapnik 3.0.16
sudo apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik
# mod-tile
cd ~/src
git clone git://github.com/SomeoneElseOSM/mod_tile.git
cd mod_tile
./autogen.sh
./configure
make
sudo make install
sudo make install-mod_tile
sudo ldconfig
# nodejs 8.x
cd ~/src
curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs
npm install -g carto
carto -v
# répertoire des tuiles
sudo mkdir -p /var/lib/flat_nodes
sudo chown osm:osm /var/lib/flat_nodes
sudo mkdir /var/lib/mod_tile
sudo chown osm:osm /var/lib/mod_tile
sudo mkdir /var/run/renderd
sudo chown osm:osm /var/run/renderd
# pgrouting 2.5.2
apt install -y packaging-dev checkinstall libboost-graph-dev libpq-dev libexpat1-dev postgresql-client libboost-program-options-dev libcgal-dev libpqxx-dev postgresql-server-dev-10
apt install -y python-sphinx texlive doxygen 
wget https://github.com/pgRouting/pgrouting/archive/v2.5.2.zip
unzip v2.5.2.zip
cd pgrouting-2.5.2
mkdir build
cd build
cmake -DWITH_DOC=ON ..
make
sudo make install
sudo -u postgres -i
createuser osm
createdb -E utf8 -l en_US.UTF-8 -T template0 -O osm gis
psql -c "CREATE EXTENSION hstore;" -d gis
psql -c "CREATE EXTENSION postgis;" -d gis
createdb -O osm routing
psql -c "CREATE EXTENSION postgis;" -d routing
psql -c "CREATE EXTENSION pgrouting;" -d routing
psql -c "CREATE EXTENSION hstore;" -d routing
createdb -O osm cars
psql -c "CREATE EXTENSION postgis;" -d cars
psql -c "CREATE EXTENSION pgrouting;" -d cars
psql -c "CREATE EXTENSION hstore;" -d cars
createdb -O osm bicycles
psql -c "CREATE EXTENSION postgis;" -d bicycles
psql -c "CREATE EXTENSION pgrouting;" -d bicycles
psql -c "CREATE EXTENSION hstore;" -d bicycles
createdb -O osm pedestrian
psql -c "CREATE EXTENSION postgis;" -d pedestrian
psql -c "CREATE EXTENSION pgrouting;" -d pedestrian
psql -c "CREATE EXTENSION hstore;" -d pedestrian
exit
# osm2pgrouting
cd ~/src
wget https://github.com/pgRouting/osm2pgrouting/archive/v2.3.3.zip
unzip v2.3.3.zip
cd osm2pgrouting-2.3.3
cmake -H. -Bbuild
cd build/
make
make install
# openstreetmap-carto 4.6.0 dev
su - osm
cd ~
git clone https://github.com/gravitystorm/openstreetmap-carto.git
cd openstreetmap-carto
carto -a "3.0.16" project.mml > style.xml 
scripts/get-shapefiles.py
exit
# On charge les données pgrouting
sudo apt-get install -y lbzip2
cd /opt
wget -c http://planet.osm.org/planet/planet-latest.osm.bz2
sudo lbzip2 -d planet-latest.osm.bz2
osm2pgrouting --f planet-latest.osm --conf /usr/share/osm2pgrouting/mapconfig.xml --dbname routing --username postgres --addnodes --attributes --tags --clean
osm2pgrouting --f planet-latest.osm --conf /usr/share/osm2pgrouting/mapconfig_for_cars.xml --dbname cars --username postgres --addnodes --attributes --tags --clean
osm2pgrouting --f planet-latest.osm --conf /usr/share/osm2pgrouting/mapconfig_for_bicycles.xml --dbname bicycles --username postgres --addnodes --attributes --tags --clean
osm2pgrouting --f planet-latest.osm --conf /usr/share/osm2pgrouting/mapconfig_for_pedestrian.xml --dbname pedestrian --username postgres --addnodes --attributes --tags --clean
rm planet-latest.osm
# On charge les données carto
su - osm
cd ~
wget -c http://planet.osm.org/pbf/planet-latest.osm.pbf
osm2pgsql --create --slim -G -d gis -C 40000 --hstore -S openstreetmap-carto/openstreetmap-carto.style --tag-transform-script openstreetmap-carto/openstreetmap-carto.lua --number-processes 8 --flat-nodes /var/lib/flat_nodes/flat-nodes.bin planet-latest.osm.pbf
rm planet-latest.osm.pbf
psql -d gis -f indexes.sql
exit
cd ~
sed 's/XML=\/home\/renderaccount\/src\/openstreetmap-carto\/mapnik.xml/XML=\/home\/osm\/src\/openstreetmap-carto\/style.xml/' /usr/local/etc/renderd.conf 
sudo sh -c 'echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" > /etc/apache2/conf-available/mod_tile.conf'
sudo a2enconf mod_tile
sed 's/<\/VirtualHost>/LoadTileConfigFile \/usr\/local\/etc\/renderd.conf/' /etc/apache2/sites-enabled/000-default.conf
sudo sh -c 'echo "ModTileRenderdSocketName /var/run/renderd/renderd.sock" > /etc/apache2/sites-enabled/000-default.conf'
sudo sh -c 'echo "ModTileRequestTimeout 0" > /etc/apache2/sites-enabled/000-default.conf'
sudo sh -c 'ModTileMissingRequestTimeout 30" > /etc/apache2/sites-enabled/000-default.conf'
sudo sh -c 'echo "</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf'
sudo service apache2 reload
sudo service apache2 reload
sed 's/RUNASUSER=renderaccount/RUNASUSER=osm/' ~/src/mod_tile/debian/renderd.init
sudo cp ~/src/mod_tile/debian/renderd.init /etc/init.d/renderd
sudo chmod u+x /etc/init.d/renderd
sudo cp ~/src/mod_tile/debian/renderd.service /lib/systemd/system/
sudo /etc/init.d/renderd start
sudo systemctl enable renderd
