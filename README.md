## Docker Munki SSL

A container with self-signed certificate to serves static files at http://munki/repo using nginx.
Nginx expects the munki repo content to be located at /munki_repo. Use a data container and the --volumes-from option to add files.

*WARNING* This is in development.

### Versions

* 1.0, latest

## Usage
Creating Client Certs for Nginx:
---
### Using self-signed certificate.
#### Create a Certificate Authority root (which represents this server)
Organization & Common Name: munkiclient

    openssl genrsa -des3 -out ca.key 4096
    openssl req -new -x509 -days 365 -key ca.key -out ca.crt

#### Create the Client Key and CSR
Organization & Common Name = munkiclient

    openssl genrsa -des3 -out client.key 4096
    openssl req -new -key client.key -out client.csr
    # self-signed
    openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt

#### Convert Client Key to PKCS
So that it may be installed in most browsers.

    openssl pkcs12 -export -clcerts -in client.crt -inkey client.key -out client.p12

#### Convert Client Key to (combined) PEM
Combines `client.crt` and `client.key` into a single PEM file for programs using openssl.

    openssl pkcs12 -in client.p12 -out client.pem -clcerts

#### Install Client Key on client device (OS or browser)
Use `client.p12`. Actual instructions vary.

#### Create the Server Key and CRT
Organization & Common Name = munki.example.com

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt

#### Creating a Data Container:
Create a data-only container to host the Munki repo.

    docker run -d --name munki-data --entrypoint /bin/echo ustwo/munki-ssl Data-only container for munki-ssl`

#### Run the Munki container:
Run the container with --volumes-from and data container created and with port 443.

    docker run -d --name munki-ssl --volumes-from munki-data -p 443:443 -h munki-ssl-proxy ustwo/munki-ssl`


#### Munki Client setup
First we need to convert into two pem files as Munki doesn't liked the joined client.pem

    openssl x509 -in client.crt -out client-munki.crt.pem -outform PEM
    openssl rsa -in client.key -out client-munki.key.pem -outform PEM

Transfer the certs to your client in my example I used scp to put them in /tmp/.

    sudo mkdir -p /Library/Managed\ Installs/certs
    sudo chmod 0700 /Library/Managed\ Installs/certs
    sudo cp /tmp/client-munki.crt.pem /Library/Managed\ Installs/certs/client-munki.crt.pem
    sudo cp /tmp/client-munki.key.pem /Library/Managed\ Installs/certs/client-munki.key.pem
    sudo chmod 0600 /Library/Managed\ Installs/certs/client-munki*
    sudo chown root:wheel /Library/Managed\ Installs/certs/client-munki*

Change the ManagedInstalls.plist defaults:

    sudo defaults write /Library/Preferences/ManagedInstalls SoftwareRepoURL "https://munki.example.com/repo"
    sudo defaults write /Library/Preferences/ManagedInstalls ClientCertificatePath "/Library/Managed Installs/certs/client-munki.crt.pem"
    sudo defaults write /Library/Preferences/ManagedInstalls ClientKeyPath "/Library/Managed Installs/certs/client-munki.key.pem"
    sudo defaults write /Library/Preferences/ManagedInstalls UseClientCertificate -bool TRUE

Test out the client:

    sudo /usr/local/munki/managedsoftwareupdate -vvv --checkonly

### Maintainers

* Erik Aulin (erik@aulin.co)

#### Sources

* [afp548](https://www.afp548.com/2015/01/22/building-munki-with-docker)
* [mtigas](https://gist.github.com/mtigas/952344)
* [pravka](https://pravka.net/nginx-mutual-auth)
* [nginx](http://wiki.nginx.org/FullExample)
