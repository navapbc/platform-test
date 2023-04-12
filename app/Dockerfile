# Simple hello, world image mostly copied
# from https://github.com/crccheck/docker-hello-world
#
# Testing
# -------
# After running `make release-build` (see [Releases](../docs/releases.md)),
# you can verify the image works by running
#
#   docker run -p 80:8000 template-infra-app
#
# then visit localhost in a browser (or can use curl from a terminal)

# Based on the image defined here: https://github.com/AerialTechnologies/docker-alpine-aws-cli/blob/master/Dockerfile
# and here: https://github.com/AerialTechnologies/docker-alpine-aws-cli-postgresql/blob/master/Dockerfile

FROM alpine:latest as builder

RUN apk --no-cache add curl
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install --bin-dir /usr/bin
RUN rm /usr/bin/aws_completer
RUN rm awscliv2.zip
RUN apk del curl

# Adds psql to /usr/bin
RUN apk --update --no-cache add postgresql-client

FROM alpine:latest as release
COPY --from=builder /usr/bin/ /usr/bin/

ADD index.html /www/index.html
ADD health /www/health
ADD start-server.sh /usr/bin/start-server.sh

# Create a basic webserver and run it until the container is stopped
CMD start-server.sh
