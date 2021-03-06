#! /bin/bash

fqdn=$1
db_server=$2
db_password=$3
user_firstname=$4
user_lastname=$5
user_email=$6
user_password=$7


apt-get -y update

apt-get -y install wget unzip

if [ "$WEB_SERVER" = "nginx" ]; then
	root_path="/usr/share/nginx/www";

	# TODO : implement nginx installation
else
	logger "Installing Apache + PHP"

	root_path="/var/www/html";

	apt-get -y install apache2 unzip
	apt-get -y install php5 php5-fpm php5-cli php5-mysql php5-mcrypt php5-curl php5-gd
	a2dismod mpm_prefork mpm_event
	a2enmod rewrite actions alias proxy proxy_fcgi mpm_worker expires

	mv ./php.ini /etc/php5/fpm/php.ini
	mv ./000-default.conf /etc/apache2/sites-available/000-default.conf
	sed -i -e 's#listen = /var/run/php5-fpm.sock#listen = 9000#' /etc/php5/fpm/pool.d/www.conf
	
	service php5-fpm restart
	service apache2 restart
fi

logger "Downloading PrestaShop ..."


wget "https://www.prestashop.com/download/latest" -O prestashop.zip

logger "PrestaShop downloaded. Now preparing PrestaShop ..."

unzip -q prestashop.zip
mv prestashop/* $root_path

# rsync -a /tmp/prestashop/ $root_path

rmdir prestashop
rm prestashop.zip
cd $root_path
rm index.html

chown -R www-data:www-data $root_path;
chmod -R g+w $root_path;


logger "Installing PrestaShop, this may take a while ..."

php $root_path/install/index_cli.php --domain=$fqdn --db_server=$db_server --db_name="prestashop" --db_user=root \
			--db_password=$db_password --firstname="$user_firstname" --lastname="$user_lastname" \
			--password=$user_password --email="$user_email" \
			--newsletter=0 --send_email=0

chown www-data:www-data -R $root_path

logger "PrestaShop in installed !"
