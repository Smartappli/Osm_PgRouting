This script help you to install pgrouting and openstreetmap automatically on a Ubuntu 18.04 LTS

Tested on VPS XXL Contabo: https://contabo.com/?show=configurator&vserver_id=180

Scripts installed
* Apache 2.4.29
* Gravitystorm-carto 4.12.1
* PgRouting 2.6.0
* Mapnik 3.0.19
* Mod-tile (Fork: SomeoneElseOSM)
* Osm2pgsql 0.9.4 dev
* Osm2pgrouting 2.3.5
* NodeJs 8.x
* node-carto 0.18.2

First create an osm user
sudo adduser osm

Install screen 
sudo apt install -y screen

Create a screen instance
sudo screen -S osm

Download the script
wget https://github.com/Smartappli/Osm_PgRouting/blob/master/install.sh

Apply rights on the file
chmod +x install.sh

Launch the script
sh install.sh
