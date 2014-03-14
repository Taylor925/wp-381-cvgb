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

ln -fs /vagrant/theme/app/design/frontend/default/whitmor/ /vagrant/app/design/frontend/default/whitmor
ln -fs /vagrant/theme/skin/frontend/default/whitmor/ /vagrant/skin/frontend/default/whitmor

# Add ServerName to httpd.conf
echo "ServerName whitmor.am.io" > /etc/apache2/httpd.conf

#Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
	DocumentRoot "/vagrant"
	ServerName whitmor.am.io
	<Directory "/vagrant">
		 AllowOverride All
	     Order Allow,Deny
		 Allow From All
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
add-apt-repository ppa:ondrej/php5

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

#cURL & jsawk & resty
#----
apt-get install -y curl

curl -L http://github.com/micha/jsawk/raw/master/jsawk > jsawk
chmod 755 jsawk && mv jsawk ~/bin/

curl -L http://github.com/micha/resty/raw/master/resty > resty
chmod 755 jsawk && mv resty ~/bin/

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
cd /var/www
#composer install --dev
# Set up the database

echo $(cat /vagrant/setngs.json | jsawk)

db_name = $(cat /vagrant/setngs.json | jsawk 'return this.db_name')
db_user = $(cat /vagrant/setngs.json | jsawk 'return this.db_user')
db_password = $(cat /vagrant/setngs.json | jsawk 'return this.db_password')
db_host = $(cat /vagrant/setngs.json | jsawk 'return this.db_host')
table_prefix = $(cat /vagrant/setngs.json | jsawk 'return this.table_prefix')
filesystem_directory = $(cat /vagrant/setngs.json | jsawk 'return this.filesystem_directory')
blog_title = $(cat /vagrant/setngs.json | jsawk 'return this.blog_title')
admin_email = $(cat /vagrant/setngs.json | jsawk 'return this.admin_email')
admin_pass = $(cat /vagrant/setngs.json | jsawk 'return this.admin_pass')

if [ ! -f /var/log/databasesetup ];
then	
	echo "CREATE DATABASE IF NOT EXISTS "$db_name
	echo "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '"$db_password"'"
	echo "GRANT ALL PRIVILEGES ON "$db_name".* TO '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'"
	echo "flush privileges"
	echo "CREATE DATABASE IF NOT EXISTS "$db_name | mysql -uroot -pghu89ijkm
	echo "CREATE USER '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'" | mysql -uroot -pghu89ijkm
	echo "GRANT ALL PRIVILEGES ON "$db_name".* TO '"$db_user"'@'localhost' IDENTIFIED BY '"$db_password"'" | mysql -uroot -pghu89ijkm
	echo "flush privileges" | mysql -uroot -pghu89ijkm
fi

echo "installing wordpress"

/usr/bin/php -r "include '"$filesystem_directory"/wp/wp-admin/install.php'; wp_install('"$blog_title"', 'admin', '"$admin_email"', 1, '', '"$admin_pass"');" > /dev/null 2>&1