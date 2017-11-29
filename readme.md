[![Docker Build Status](https://img.shields.io/docker/build/jaaaco/mysql-s3-backup-restore.svg)](https://hub.docker.com/r/jaaaco/mysql-s3-backup-restore/)

# MySql S3 backup (with cron) / restore container

Container can work in cron-mode and wait-mode:

# Cron mode

Default mode, container will make backups according to CRON_SCHEDULE env variable. 

# Wait mode

In this mode cron is disabled, you may make backups / restores with docker exec (see below). 
To enable wait mode add command: /wait to your composition.

# Backup command

Container is making archive **in the same S3 file every time**.

If you want backup file retention enable Versioning on S3 bucket and create S3 Life Cycle Rules to permanently 
delete older version after certain number of days. 

To make backup when container is running in cron-mode or wait-mode:

```
docker exec -it <container-id> backup
```

# Restore command

```
docker exec -it <container-id> backup
```

## Usage

Example docker-compose.yml:

```
version: '3.3'
services:
  app:
    image: wordpress
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_PASSWORD: password
  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: password
  mysql-backup:
    image: mysql-backup
    environment:
      FILEPREFIX: wordpress/default
      S3BUCKET: <your-bucket-name-here>
      AWS_ACCESS_KEY_ID: <your-key-id-here>
      AWS_SECRET_ACCESS_KEY: <your-aws-secret-key-here>
    command: /cron
    depends_on:
      - mysql
```

## Required and optional ENV variables

* AWS_ACCESS_KEY_ID - key for aws user with s3 put-object and get-object permissions
* AWS_SECRET_ACCESS_KEY
* S3BUCKET - S3 bucket name
* FILEPREFIX - (optional) file prefix, defaults to "backup"
* CRON_SCHEDULE - (optional) cron schedule, defaults to 4 4 * * * (at 4:04 am, every day)
* MYSQL_HOST - (optional) database host name, defaults to "mysql"
* MYSQL_USER - (optional) database user, defaults to "root"
* MYSQL_PASSWORD - (optional) password, defaults to "password"
