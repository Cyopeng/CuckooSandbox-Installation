

# Cuckoo Sandbox Installation
# Author: Tyler Tenlen

sudo adduser --disabled-password --gecos "" cuckoo
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
wget https://cuckoo.sh/win7ultimate.iso
sudo mkdir /mnt/win7
sudo mount -o ro,loop win7ultimate.iso /mnt/win7
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
sudo apt-get update
sudo apt-get install virtualbox-5.2
sudo usermod -a -G vboxusers cuckoo
sudo apt-get -y install build-essential libssl-dev libffi-dev python-dev genisoimage
sudo apt-get -y install zlib1g-dev libjpeg-dev
sudo apt-get -y install python-pip python-virtualenv python-setuptools swig
sudo su cuckoo
virtualenv ~/cuckoo
. ~/cuckoo/bin/activate
pip install -U cuckoo vmcloak
vmcloak-vboxnet0
# Syntax:  vmcloak init <os flag> <vmname> <options>
vmcloak init --verbose --win7x64 win7x64base --cpus 4 --ramsize 4096


vmcloak clone win7x64base win7x64cuckoo
#List software packages to install: vmcloak list deps
vmcloak install win7x64cuckoo adobepdf pillow dotnet java flash vcredist vcredist.version=2015u3 wallpaper
#Optional to install IE11: vmcloak install win7x64cuckoo ie11
#Optional to install Office Products: vmcloak install win7x64cuckoo office office.version=2007 office.isopath=/path/to/office2007.iso office.serialkey=XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# Snapshot command syntac: vmcloak snapshot <options> <image name> <vmname> <ip to use>
vmcloak snapshot --count 4 win7x64cuckoo 192.168.56.101 #This will creat 4 snapshots with IPs 192.168.56.101-104
#Command to list VM's: vmcloak list vms
cuckoo init
cuckoo --cwd /tmp/cuckoo init
sudo apt-get install postgresql postgresql-contrib
sudo apt-get install python-psycopg2
sudo apt-get install libpq-dev

sudo -u postgres psql
CREATE DATABASE cuckoo;
CREATE USER cuckoo WITH ENCRYPTED PASSWORD '*';
GRANT ALL PRIVILEGES ON DATABASE cuckoo TO cuckoo;
\q
#Open the $CWD/conf/cuckoo.conf file and find the [database] section. Change the connection = line to: connection = postgresql://cuckoo:password@localhost/cuckoo
while read -r vm ip; do cuckoo machine --add $vm $ip; done < <(vmcloak list vms)
#Reminder eth0 could be a different adapter name. Check your active adapter using: ifconfig -a
sudo sysctl -w net.ipv4.conf.vboxnet0.forwarding=1
sudo sysctl -w net.ipv4.conf.eth0.forwarding=1
sudo iptables -t nat -A POSTROUTING -o wlp3s0 -s 192.168.56.0/24 -j MASQUERADE
sudo iptables -P FORWARD DROP
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -s 192.168.56.0/24 -j ACCEPT

cuckoo rooter --sudo --group cuckoo
/home/cuckoo/cuckoo/bin/cuckoo rooter --sudo --group cuckoo

sudo apt-get install mongodb


pip install uwsgi
sudo apt-get install uwsgi uwsgi-plugin-python nginx

cuckoo web --uwsgi > cuckoo-web.ini
sudo cp cuckoo-web.ini /etc/uwsgi/apps-available/cuckoo-web.ini
sudo ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/cuckoo-web
sudo adduser www-data cuckoo
sudo systemctl restart uwsgi

cuckoo web --nginx > cuckoo-web.conf
sudo cp cuckoo-web.conf /etc/nginx/sites-available/cuckoo-web.conf
sudo ln -s /etc/nginx/sites-available/cuckoo-web.conf /etc/nginx/sites-enabled/cuckoo-web.conf
sudo systemctl restart nginx