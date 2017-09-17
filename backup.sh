#!/usr/bin/env bash

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID must be set"
  HAS_ERRORS=true
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY must be set"
  HAS_ERRORS=true
fi

if [ -z "$S3BUCKET" ]; then
  echo "S3BUCKET must be set"
  HAS_ERRORS=true
fi

if [ $HAS_ERRORS ]; then
  echo "Exiting.... "
  exit 1
fi

if [ -z "$MYSQL_USER" ]; then
  MYSQL_USER='root'
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  MYSQL_PASSWORD='password'
fi

if [ -z "$MYSQL_HOST" ]; then
  MYSQL_HOST='mysql'
fi

if [ -z "$FILEPREFIX" ]; then
  FILEPREFIX='backup'
fi

if [ -z "$DELAY" ]; then
  DELAY='30'
fi

FILENAME=$FILEPREFIX.latest.sql.gz

if [ "$1" == "backup" ] ; then
  echo "Starting backup (v4) ... $(date)"
  mysqldump --protocol tcp -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD --all-databases > latest.sql
  gzip latest.sql
  aws s3api put-object --bucket $S3BUCKET --key $FILENAME --body latest.sql.gz
  echo "Cleaning up..."
  rm latest.sql.gz
  exit 0
fi

echo "Restoring latest backup after initial delay: $DELAY (sec)"
sleep $DELAY
aws s3api get-object --bucket $S3BUCKET --key $FILENAME latest.sql.gz
if [ -e latest.sql.gz ] ; then
    gunzip latest.sql.gz
    cat latest.sql | mysql --protocol tcp -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD
    echo "Cleaning up..."
    rm latest.sql
else
    echo "No backup to restore"
fi

CRON_SCHEDULE=${CRON_SCHEDULE:-3 3 * * *}

LOGFIFO='/var/log/cron.fifo'
if [[ ! -e "$LOGFIFO" ]]; then
    touch "$LOGFIFO"
fi

CRON_ENV="MYSQL_USER='$MYSQL_USER'"
CRON_ENV="$CRON_ENV\nAWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY_ID'"
CRON_ENV="$CRON_ENV\nAWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY'"
CRON_ENV="$CRON_ENV\nS3BUCKET='$S3BUCKET'"
CRON_ENV="$CRON_ENV\nMYSQL_PASSWORD='$MYSQL_PASSWORD'"
CRON_ENV="$CRON_ENV\nMYSQL_HOST='$MYSQL_HOST'"
CRON_ENV="$CRON_ENV\nPATH=$PATH"
CRON_ENV="$CRON_ENV\nFILEPREFIX=$FILEPREFIX"

echo -e "$CRON_ENV\n$CRON_SCHEDULE /backup.sh backup > $LOGFIFO 2>&1" | crontab -
crontab -l
cron
tail -f "$LOGFIFO"