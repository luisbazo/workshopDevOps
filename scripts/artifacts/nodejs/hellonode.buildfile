FROM debian:10

RUN apt-get -y update && apt-get install -y curl

#RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -

RUN apt-get install -y ca-certificates curl gnupg; \
 mkdir -p /etc/apt/keyrings; \
 curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
 NODE_MAJOR=18; \
 echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
  > /etc/apt/sources.list.d/nodesource.list;

RUN apt-get install -y nodejs npm

RUN mkdir /app
ADD ./nodejs/app.js /app
ADD ./nodejs/package.json /app
RUN cd /app && npm install

ENV PORT 8080
EXPOSE 8080
WORKDIR "/app"
CMD ["npm", "start"]
