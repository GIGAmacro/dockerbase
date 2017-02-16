FROM hyperknot/baseimage16:1.0.1
ENV REDIS_VERSION=3.2.8

CMD ["/sbin/my_init"]

ENV DEBIAN_FRONTEND noninteractive


# base

RUN apt-get update && apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"
RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 bash-completion build-essential ca-certificates curl file git htop iproute2 libffi-dev lsof mc nano nasm net-tools netbase nethogs openssh-client psmisc python rsync silversearcher-ag time tmux wget unzip p7zip


# mozjpeg

WORKDIR /tmp
RUN wget -qO out.tgz https://github.com/mozilla/mozjpeg/releases/download/v3.1/mozjpeg-3.1-release-source.tar.gz && \
    tar -xzf out.tgz
WORKDIR /tmp/mozjpeg
RUN ./configure --prefix=/usr/local/opt/mozjpeg && \
    make install


# Python

RUN apt-get update && apt-get install -y --no-install-recommends \
    python python-pip python-pkg-resources python-setuptools python-wheel python-dev \
    libxslt1-dev
RUN pip install virtualenv


# Node

RUN curl --silent --location https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get update && apt-get install -y --no-install-recommends nodejs


# Node yarn
RUN apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
RUN echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y --no-install-recommends yarn


# Redis

RUN groupadd -r redis && useradd -r -g redis redis

WORKDIR /tmp
RUN wget -qO out.tgz http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz
RUN tar -xzf out.tgz
WORKDIR /tmp/redis-$REDIS_VERSION
RUN make
RUN make install

COPY services/redis/redis.run /etc/service/redis/run
RUN touch /etc/service/redis/down

COPY services/redis/redis_custom_32.conf /etc/redis/redis.conf


# PostgreSQL

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-common && \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
    apt-get install -y --no-install-recommends \
    postgresql-9.5 postgresql-contrib-9.5 libpq-dev

COPY services/postgresql/postgresql.run /etc/service/postgresql/run
RUN touch /etc/service/postgresql/down

# running SQL backup on app level
# COPY services/postgresql/backup-postgresql-dump.sh /etc/my_init.pre_shutdown.d/
# COPY services/postgresql/backup-postgresql-rsync.sh /etc/my_init.post_shutdown.d/


# nginx

RUN echo 'deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx' > /etc/apt/sources.list.d/nginx.list
RUN wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN apt-get update && apt-get install -y --no-install-recommends nginx

COPY services/nginx/nginx.run /etc/service/nginx/run
RUN touch /etc/service/nginx/down

COPY services/nginx/nginx.conf /etc/nginx/
COPY services/nginx/mime.types /etc/nginx/


# logs
COPY services/logs/01_init_logs_current.sh /etc/my_init.d/



# cleaning

WORKDIR /
ENV DEBIAN_FRONTEND teletype
ENV TERM xterm

RUN apt-get clean &&\
    rm -rf /root/.cache &&\
    rm -rf /root/.npm &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -rf /tmp/* &&\
    rm -rf /var/tmp/* &&\
    rm -rf /usr/share/doc &&\
    rm -rf /usr/share/man
