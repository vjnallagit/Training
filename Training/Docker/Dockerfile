From ubuntu:18.04
Label maintainer="vijay.08123@gmail.com"

RUN apt-get update && apt -y install apache2
EXPOSE 80

ENTRYPOINT ["/usr/sbin/apachectl"]
CMD ["-D", "FOREGROUND"]
