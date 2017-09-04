This script help you to install pgrouting and openstreetmap automatically on a Ubuntu 16.04.3 LTS

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
