FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update &&\
    apt-get -y install \
        wget &&\
    wget --quiet -O - https://deb.nodesource.com/setup_4.x | /bin/bash &&\
    apt-get update &&\
    apt-get -y install \
        build-essential \
        git-core \
        imagemagick \
        imagemagick-common \
        libcurl4-openssl-dev \
        libffi-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        libpq-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libyaml-dev \
        nodejs \
        postgresql-client \
        python-dev \
        python-pip \
        python-software-properties \
        rlwrap \
        sqlite3 \
        supervisor \
        zlib1g-dev &&\
    pip install bandit

RUN apt-get clean &&\
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*

ADD docker-entrypoint.sh /docker-entrypoint.sh
ADD docker-entrypoint-init.d /docker-entrypoint-init.d

RUN useradd -c 'scumblr' -m -d /home/scumblr -s /bin/bash scumblr
USER scumblr
ENV RBENV_ROOT /home/scumblr/usr/local/rbenv
ENV PATH $RBENV_ROOT/bin:$RBENV_ROOT/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV BUNDLE_GEMFILE /home/scumblr/Scumblr/Gemfile

RUN git clone https://github.com/sstephenson/rbenv.git /home/scumblr/usr/local/rbenv &&\
    git clone https://github.com/sstephenson/ruby-build.git /home/scumblr/usr/local/rbenv/plugins/ruby-build &&\
    rbenv install 2.3.1 &&\
    rbenv global 2.3.1 &&\
    gem install bundler --no-ri --no-rdoc &&\
    gem install sidekiq --no-ri --no-rdoc &&\
    gem install rails -v 4.2.6 --no-ri --no-rdoc &&\
    rbenv rehash

RUN git clone https://github.com/Netflix/Scumblr.git /home/scumblr/Scumblr &&\
    bundle install --gemfile=/home/scumblr/Scumblr/Gemfile --no-cache

RUN sed -i '0,/localhost/{s/localhost/postgres/}' /home/scumblr/Scumblr/config/database.yml
RUN cp /home/scumblr/Scumblr/config/initializers/scumblr.rb.sample /home/scumblr/Scumblr/config/initializers/scumblr.rb
ADD supervisord.conf /home/scumblr/supervisord.conf

WORKDIR /home/scumblr/Scumblr
EXPOSE 3000
ENTRYPOINT ["/docker-entrypoint.sh"]
