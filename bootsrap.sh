#!/usr/bin/env bash

# Update the box
# --------------
# Downloads the package
apt-get Update

#Install vim (if you really want to)
apt-get install -y vim
apt-get install -y nano

#Apache
#-----
apt-get install -y apache2

#Remove /var/www default
rm -rf /var/www

#Symlink /vagrant to /var/www
ln -fs /vagrant /var/www


#cURL & nodejs & jsontool
#----
apt-get install -y curl nodejs

curl -L https://github.com/trentm/json/raw/master/lib/jsontool.js > json
chmod 755 json
mv json /usr/local/bin/json

echo $(cat /vagrant/setngs.json | json)

db_name=$(cat /vagrant/setngs.json | json -a vagrant.db_name)
db_user=$(cat /vagrant/setngs.json | json -a vagrant.db_user)
db_password=$(cat /vagrant/setngs.json | json -a vagrant.db_password)
db_host=$(cat /vagrant/setngs.json | json -a vagrant.db_host)
table_prefix=$(cat /vagrant/setngs.json | json -a vagrant.table_prefix)
filesystem_directory=$(cat /vagrant/setngs.json | json -a vagrant.filesystem_directory)
blog_title=$(cat /vagrant/setngs.json | json -a vagrant.blog_title)
admin_user=$(cat /vagrant/setngs.json | json -a vagrant.admin_user)
admin_email=$(cat /vagrant/setngs.json | json -a vagrant.admin_email)
admin_pass=$(cat /vagrant/setngs.json | json -a vagrant.admin_pass)
wp_domain=$(cat /vagrant/setngs.json | json -a vagrant.wp_domain)
vagrant_port=$(cat /vagrant/setngs.json | json -a vagrant.vagrant_port)

# Add ServerName to httpd.conf
echo "ServerName ${wp_domain}" > /etc/apache2/httpd.conf

#Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
	DocumentRoot "/vagrant"
	ServerName ${wp_domain}
	<Directory "/vagrant">
		Options Indexes Includes FollowSymLinks  
        AllowOverride All
        Order allow,deny
        Allow from all
  #      Require All granted
	</Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default

#enable mod Rewrite
a2enmod rewrite

#PHP 5.4
#-----
apt-get install -y libapache2-mod-php5

#Add apt-repo binary
apt-get install -y python-software-properties

#Install PHP 5.4
#add-apt-repository ppa:ondrej/php5

#Update
apt-get update

apt-get install -y php5
#PHP More stuff
# Command line
apt-get install -y php5-cli
# PHP mysql
apt-get install -y php5-mysql
# cURL
apt-get install -y php5-curl
# GD library
apt-get install -y php5-gd
#MCrypt
apt-get install -y php5-mcrypt

#Restart Apache
service apache2 restart


#mysql
#-----
#ignore post install questions
export DEBIAN_FRONTEND=noninteractive
#install mysql quietly

sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password ghu89ijkm'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password ghu89ijkm'
apt-get -y install mysql-server-5.5

#Install Composer
#-----
curl -s https://getcomposer.org/installer | php
# Make Composer available globally
mv composer.phar /usr/local/bin/composer

#Magento stuff
#----
#cd /var/www
#composer install --dev
# Set up the database

# echo $(cat /vagrant/setngs.json | json)

# db_name=$(cat /vagrant/setngs.json | json -a vagrant.db_name)
# db_user=$(cat /vagrant/setngs.json | json -a vagrant.db_user)
# db_password=$(cat /vagrant/setngs.json | json -a vagrant.db_password)
# db_host=$(cat /vagrant/setngs.json | json -a vagrant.db_host)
# table_prefix=$(cat /vagrant/setngs.json | json -a vagrant.table_prefix)
# filesystem_directory=$(cat /vagrant/setngs.json | json -a vagrant.filesystem_directory)
# blog_title=$(cat /vagrant/setngs.json | json -a vagrant.blog_title)
# admin_user=$(cat /vagrant/setngs.json | json -a vagrant.admin_user)
# admin_email=$(cat /vagrant/setngs.json | json -a vagrant.admin_email)
# admin_pass=$(cat /vagrant/setngs.json | json -a vagrant.admin_pass)
# wp_domain=$(cat /vagrant/setngs.json | json -a vagrant.wp_domain)

if [ ! -f /var/log/databasesetup ];
then	
	echo "CREATE DATABASE IF NOT EXISTS "$db_name
	echo "CREATE USER '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'"
	echo "GRANT ALL PRIVILEGES ON "$db_name".* TO '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'"
	echo "flush privileges"
	echo "CREATE DATABASE IF NOT EXISTS "$db_name | mysql -uroot -pghu89ijkm
	echo "CREATE USER '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'" | mysql -uroot -pghu89ijkm
	echo "GRANT ALL PRIVILEGES ON "$db_name".* TO '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'" | mysql -uroot -pghu89ijkm
	echo "flush privileges" | mysql -uroot -pghu89ijkm
fi

echo "installing wordpress"

# The name of the database for WordPress 
/bin/sed -i "s/database_name_here/$db_name/g" /vagrant/wp-config.php

# MySQL database username 
/bin/sed -i "s/username_here/$db_user/g" /vagrant/wp-config.php

# MySQL database password
/bin/sed -i "s/password_here/$db_password/g" /vagrant/wp-config.php


echo "Options -Indexes
 
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
 
# add a trailing slash to /wp-admin
RewriteRule ^([_0-9a-zA-Z-]+/)?wp-admin$ $1wp-admin/ [R=301,L]
 
RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(wp-(content|admin|includes).*) wp/$2 [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(.*\.php)$ wp/$2 [L]
RewriteRule . index.php [L]" > /vagrant/.htaccess

curl -L https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > wp-cli.phar

chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/bin/wp

if [ ! -f /vagrant/dbstate/backup.sql.gz ];
then
	cd /vagrant
	wp core install --url="$wp_domain:$vagrant_port" --title="$blog_title" --admin_name=$admin_user --admin_password=$admin_pass --admin_email=$admin_email --allow-root
else	
	gunzip < /vagrant/dbstate/backup.sql.gz | mysql -u$db_user -p$db_password $db_name
	echo "Database restored"
fi
#/usr/bin/php -r "include '"$filesystem_directory"/wp/wp-admin/install.php';wp_install('"$blog_title"', 'admin', '"$admin_email"', 1, '', '"$admin_pass"');" > /dev/null 2>&1