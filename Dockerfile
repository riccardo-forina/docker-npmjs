# Apache CouchDB 1.4

FROM ubuntu:14.10
MAINTAINER Sam Bisbee <sam@sbisbee.com>

RUN apt-get update
RUN apt-get upgrade -y

# CouchDB dependencies
RUN apt-get install -y make g++
RUN apt-get install -y erlang-dev erlang-manpages erlang-base-hipe erlang-eunit erlang-nox erlang-xmerl erlang-inets
RUN apt-get install -y libmozjs185-dev libicu-dev libcurl4-gnutls-dev libtool

# Docker image dependencies
RUN apt-get install -y wget

# Set up our build environment
RUN bash -c 'cd /tmp && wget http://www.carfab.com/apachesoftware/couchdb/source/1.4.0/apache-couchdb-1.4.0.tar.gz && tar -zxvf apache-couchdb-1.4.0.tar.gz'

# Build and install CouchDB
RUN bash -c 'cd /tmp/apache-couchdb-1.4.0 && ./configure --prefix=/usr/local && make && make install'
RUN touch /usr/local/var/log/couchdb/couch.log

# Configure SSL
ADD ssl.ini /usr/local/etc/couchdb/local.d/ssl.ini
ADD key.pem /usr/local/etc/couchdb/key.pem
ADD cert.pem /usr/local/etc/couchdb/cert.pem

# Set up our users and permissions
RUN useradd -d /usr/local/lib/couchdb couchdb
RUN chown -R couchdb:couchdb /usr/local/var/lib/couchdb /usr/local/var/log/couchdb
RUN chown -R root:couchdb /usr/local/etc/couchdb
RUN chmod 664 /usr/local/etc/couchdb/*.ini
RUN chmod 775 /usr/local/etc/couchdb/*.d

# Start
CMD /usr/local/etc/init.d/couchdb start && tail -f /usr/local/var/log/couchdb/couch.log
ENV PATH /opt/node/bin/:$PATH

# Install curl
RUN apt-get install -y curl git

# Setup nodejs
RUN mkdir -p /opt/node
RUN curl -L# http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz|tar -zx --strip 1 -C /opt/node

# Download npmjs project
RUN git clone https://github.com/isaacs/npmjs.org /opt/npmjs
RUN cd /opt/npmjs; git checkout ea8e7a533ea595db79b24f12c76b62c3889b43e8
RUN npm install couchapp@0.10.x -g
RUN cd /opt/npmjs; npm link couchapp; npm install semver

# Allow insecure rewrites
RUN echo "[httpd]\nsecure_rewrites = false" >> /usr/local/etc/couchdb/local.d/secure_rewrites.ini

# Configuring npmjs.org
RUN cd /opt/npmjs; couchdb -b; sleep 5; curl -X PUT http://localhost:5984/registry; sleep 5; couchdb -d;
RUN cd /opt/npmjs; couchdb -b; sleep 5; couchapp push registry/shadow.js http://localhost:5984/registry; sleep 5; couchapp push registry/app.js http://localhost:5984/registry; sleep 5; couchdb -d
RUN cd /opt/npmjs; npm set _npmjs.org:couch=http://localhost:5984/registry
RUN cd /opt/npmjs; couchdb -b; sleep 5; npm run load; sleep 5; curl -k "http://localhost:5984/registry/_design/scratch" -X COPY -H destination:'_design/app'; sleep 5; couchdb -d
## Resolve isaacs/npmjs.org#98
RUN cd /opt/npmjs; /usr/local/bin/couchdb -b; sleep 5; curl http://isaacs.iriscouch.com/registry/error%3A%20forbidden | curl -X PUT -d @- http://localhost:5984/registry/error%3A%20forbidden?new_edits=false; sleep 5; couchdb -d

# Install npm-delegate
RUN npm install -g kappa@0.14.x

# Start
ADD config/kappa.json.default /opt/npmjs/kappa.json.default
ADD scripts/startup.sh /root/startup.sh
CMD /root/startup.sh
