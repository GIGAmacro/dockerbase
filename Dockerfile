FROM hyperknot/baseimage16:1.0.6

ENV REDIS_VERSION=3.2.11
ENV MOZJPEG_VERSION=3.2
ENV POSTGRESQL_VERSION=9.6

CMD ["/sbin/my_init"]

ENV DEBIAN_FRONTEND noninteractive


# base

RUN apt-get update && apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"
RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 bash-completion build-essential ca-certificates curl file git htop iproute2 libffi-dev lsof mc nano nasm net-tools netbase openssh-client psmisc python rsync silversearcher-ag time tmux wget unzip p7zip-full libssl-dev nethogs nload iftop ncdu pkg-config


# mozjpeg

WORKDIR /tmp
RUN wget -qO out.tgz https://github.com/mozilla/mozjpeg/releases/download/v$MOZJPEG_VERSION/mozjpeg-$MOZJPEG_VERSION-release-source.tar.gz && \
    tar -xzf out.tgz
WORKDIR /tmp/mozjpeg
RUN ./configure --prefix=/usr/local/opt/mozjpeg && \
    make install


# Python 2.7

RUN apt-get update && apt-get install -y --no-install-recommends \
    python python-pip python-pkg-resources python-setuptools python-wheel python-dev \
    libxslt1-dev
RUN pip install virtualenv --disable-pip-version-check --no-cache-dir


# Python 3.6

RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3.6 python3.6-dev python3.6-venv && \
    wget -qO get-pip.py 'https://bootstrap.pypa.io/get-pip.py' && \
    python3.6 get-pip.py --no-cache-dir && \
    rm get-pip.py && \
    rm /usr/local/bin/pip && \
    pip --version && pip3.6 --version
        
# RUN add-apt-repository ppa:jonathonf/python-3.6 -y && \
#    apt-get update && \
#    apt-get install -y --no-install-recommends python3.6 python3.6-dev python3.6-venv && \
#    wget -qO get-pip.py 'https://bootstrap.pypa.io/get-pip.py' && \
#    python3.6 get-pip.py --no-cache-dir && \
#    rm get-pip.py && \
#    rm /usr/local/bin/pip && \
#    pip --version && pip3.6 --version


# Node

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs


# Yarnpkg

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends yarn


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
    postgresql-$POSTGRESQL_VERSION postgresql-contrib-$POSTGRESQL_VERSION libpq-dev pgtop

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
