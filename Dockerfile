FROM debian:jessie-slim

RUN apt-get update && apt-get install -y cron python-pip
RUN pip install awscli

ADD backup.sh /
RUN chmod +x backup.sh
CMD ["./backup.sh"]