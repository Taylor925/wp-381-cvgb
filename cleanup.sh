#!/usr/bin/env bash

echo $(cat setngs.json | json)

db_name=$(cat setngs.json | json -a vagrant.db_name)
db_user=$(cat setngs.json | json -a vagrant.db_user)
db_password=$(cat setngs.json | json -a vagrant.db_password)
db_host=$(cat setngs.json | json -a vagrant.db_host)
table_prefix=$(cat setngs.json | json -a vagrant.table_prefix)
filesystem_directory=$(cat setngs.json | json -a vagrant.filesystem_directory)
blog_title=$(cat setngs.json | json -a vagrant.blog_title)
admin_user=$(cat setngs.json | json -a vagrant.admin_user)
admin_email=$(cat setngs.json | json -a vagrant.admin_email)
admin_pass=$(cat setngs.json | json -a vagrant.admin_pass)
wp_domain=$(cat setngs.json | json -a vagrant.wp_domain)

if [ ! -d dbstate ];
then	
	mkdir dbstate
fi
mysqldump -u$db_user -p$db_password $db_name | gzip > dbstate/backup.sql.gz 