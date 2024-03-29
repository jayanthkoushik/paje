FROM archlinux
MAINTAINER Jayanth Koushik <jnkoushik@gmail.com>

RUN pacman -Syu --noconfirm
RUN pacman -S base-devel --noconfirm

RUN pacman -S python python-pip --noconfirm
RUN pacman -S ruby ruby-bundler --noconfirm
RUN pacman -S nodejs --noconfirm
RUN pacman -S texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-fontsextra texlive-xetex texlive-luatex texlive-bibtexextra --noconfirm
RUN pacman -S pandoc pandoc-crossref --noconfirm
RUN pacman -S imagemagick --noconfirm
RUN pacman -S ghostscript --noconfirm
RUN pacman -S git --noconfirm
RUN pacman -S rsync --noconfirm
RUN pacman -S python-pipx --noconfirm

RUN truncate -s 0 /etc/ImageMagick-7/policy.xml

RUN pipx install shiny-mdc

ADD main.sh /main.sh
ADD www /www

RUN bundle install --gemfile=/www/Gemfile --path=/www/.bundle
