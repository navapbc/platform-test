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

# This image is based on the docker-aws-cli-postgres image defined in:
# https://github.com/osodevops/docker-aws-cli-postgres/blob/master/Dockerfile

FROM amazonlinux:2 AS installer
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN yum update -y \
  && yum install -y unzip \
  && unzip awscliv2.zip \
  # The --bin-dir is specified so that we can copy the
  # entire bin directory from the installer stage into
  # into /usr/local/bin of the final stage without
  # accidentally copying over any other executables that
  # may be present in /usr/local/bin of the installer stage.
  && ./aws/install --bin-dir /aws-cli-bin/

FROM amazonlinux:2 AS release
RUN yum update -y \
  && yum install -y less groff gzip \
  && yum clean all
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

RUN amazon-linux-extras install -y postgresql10 vim epel

ADD index.html /www/index.html
ADD health /www/health
ADD start-server.sh /bin/start-server.sh

# Create a basic webserver and run it until the container is stopped
CMD start-server.sh
