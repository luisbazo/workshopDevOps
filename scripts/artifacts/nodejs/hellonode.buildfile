FROM debian:10

RUN apt-get -y update && apt-get install -y curl

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

RUN mkdir /app
ADD ./nodejs/app.js /app
ADD ./nodejs/package.json /app
RUN cd /app && npm install

ENV PORT 8080
EXPOSE 8080
WORKDIR "/app"
CMD ["npm", "start"]

