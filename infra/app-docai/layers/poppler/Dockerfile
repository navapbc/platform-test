FROM --platform=linux/amd64 amazonlinux:2
RUN yum update -y && yum install -y poppler-utils
RUN mkdir -p /opt/bin /opt/lib64
RUN cp /usr/bin/pdf* /opt/bin/

# copy only poppler-related libraries and their dependencies
RUN cp /usr/lib64/libpoppler* /opt/lib64/ || true
RUN cp /usr/lib64/liblcms2* /opt/lib64/ || true
RUN cp /usr/lib64/libfontconfig* /opt/lib64/ || true
RUN cp /usr/lib64/libfreetype* /opt/lib64/ || true
RUN cp /usr/lib64/libjpeg* /opt/lib64/ || true
RUN cp /usr/lib64/libpng* /opt/lib64/ || true
RUN cp /usr/lib64/libtiff* /opt/lib64/ || true
RUN cp /usr/lib64/libz* /opt/lib64/ || true
RUN cp /usr/lib64/libopenjpeg* /opt/lib64/ || true
RUN cp /usr/lib64/libjbig* /opt/lib64/ || true
RUN ls -la /opt/bin/
RUN ls -la /opt/lib64/