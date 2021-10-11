FROM archlinux
MAINTAINER Jayanth Koushik <jnkoushik@gmail.com>

RUN pacman -Syu --noconfirm
RUN pacman -S base-devel --noconfirm

RUN pacman -S python python-pip --noconfirm
RUN pacman -S ruby ruby-bundler --noconfirm
RUN pacman -S nodejs --noconfirm
RUN pacman -S texlive-most --noconfirm
RUN pacman -S pandoc pandoc-crossref --noconfirm
RUN pacman -S imagemagick --noconfirm
RUN pacman -S ghostscript --noconfirm
RUN pacman -S git --noconfirm

RUN pip install shinymdc

ADD Gemfile /bundle/Gemfile
RUN bundle install --gemfile=/bundle/Gemfile --path=/bundle

RUN truncate -s 0 /etc/ImageMagick-7/policy.xml
