# DOCKER-VERSION 0.4.x
FROM ubuntu:12.10
MAINTAINER Terin Stock <terinjokes@gmail.com>

ADD scripts/setup.sh /root/setup-npm.sh
RUN /root/setup-npm.sh
# Install npm-delegate
#RUN npm install -g npm-delegate

# Start npm-delegate
#CMD couchdb & sleep 3; npm-delegate -p 1337 http://127.0.0.1:5984/registry https://registry.npmjs.org
ADD scripts/startup.sh /root/startup-npm.sh
CMD /root/startup-npm.sh

# Expose couchdb
EXPOSE :5984
EXPOSE :1337
