FROM nginx
RUN mkdir -p /munki_repo
Run mkdir -p /etc/nginx/sites-enabled/
ADD nginx.conf /etc/nginx/nginx.conf
ADD munki-repo-ssl.conf /etc/nginx/sites-enabled/
ADD server.crt /etc/nginx/certs/server.crt
ADD server.key /etc/nginx/certs/server.key
ADD ca.crt /etc/nginx/certs/
VOLUME /munki_repo
EXPOSE 443
