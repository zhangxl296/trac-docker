FROM ubuntu
MAINTAINER = xiaolong.zhang<zhangxl296@gmail.com>
ENV TRAC_ADMIN_NAME trac_admin
ENV TRAC_ADMIN_PASSWD passw0rd
ENV TRAC_PROJECT_NAME slg
ENV TRAC_DIR /var/local/trac
ENV TRAC_INI $TRAC_DIR/conf/trac.ini
ENV DB_LINK sqlite:db/trac.db
EXPOSE 8123

ADD sources.list /etc/apt/sources.list

RUN apt update \
   && apt install tzdata \
   && apt install -y apt-utils trac python-babel libapache2-mod-wsgi python-pip && apt -y clean \
   && pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade Babel Trac \
   && trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK \
   && trac-admin $TRAC_DIR deploy $TRAC_DIR/deploy && mv -f $TRAC_DIR/deploy/cgi-bin $TRAC_DIR && mv $TRAC_DIR/deploy/htdocs/*  $TRAC_DIR/htdocs && rm -rf $TRAC_DIR/deploy \
   && htpasswd -b -c $TRAC_DIR/.htpasswd $TRAC_ADMIN_NAME $TRAC_ADMIN_PASSWD \
   && trac-admin $TRAC_DIR permission add $TRAC_ADMIN_NAME TRAC_ADMIN \
   && chown -R www-data: $TRAC_DIR \
   && chmod -R 775 $TRAC_DIR \
   && echo "Listen 8123" >> /etc/apache2/ports.conf 

ADD trac.conf /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$AUTH_NAME|'"$TRAC_PROJECT_NAME"'|g' /etc/apache2/sites-available/trac.conf  && sed -i 's|$TRAC_DIR|'"$TRAC_DIR"'|g' /etc/apache2/sites-available/trac.conf  && a2dissite 000-default && a2ensite trac.conf
CMD service apache2 stop && apache2ctl -D FOREGROUND
