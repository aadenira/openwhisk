# Dockerfile for Python whisk docker action
FROM openwhisk/dockerskeleton

MAINTAINER abiwaxade@gmail.com

ENV FLASK_PROXY_PORT 8080

RUN apk --no-cache add gcc g++ libgfortran gfortran make cmake

RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
# Install our action's Python dependencies
ADD requirements.txt /action/requirements.txt

#Machine learning packages Install
RUN mkdir -p /tmp/build \
&& cd /tmp/build/ \
&& wget http://www.netlib.org/blas/blas-3.6.0.tgz \
&& wget http://www.netlib.org/lapack/lapack-3.6.1.tgz \
&& tar xzf blas-3.6.0.tgz \
&& tar xzf lapack-3.6.1.tgz \
&& cd /tmp/build/BLAS-3.6.0/ && gfortran -O3 -std=legacy -m64 -fno-second-underscore -fPIC -c *.f \
&& ar r libfblas.a *.o && ranlib libfblas.a && mv libfblas.a /tmp/build/. \
&& cd /tmp/build/lapack-3.6.1/ \
&& sed -e "s/frecursive/fPIC/g" -e "s/ \.\.\// /g" -e "s/^CBLASLIB/\#CBLASLIB/g" make.inc.example > make.inc \
&& make lapacklib \
&& make clean \
&& mv liblapack.a /tmp/build/. \
&& cd / \
&& export BLAS=/tmp/build/libfblas.a \
&& export LAPACK=/tmp/build/liblapack.a \
&& cd /action; pip install -r requirements.txt


RUN rm -r /action/requirements.txt
RUN python -m textblob.download_corpora
RUN python -m nltk.downloader stopwords

#2 Add Edge and bleeding repos
RUN echo -e '@community http://nl.alpinelinux.org/alpine/edge/community\n@edge http://nl.alpinelinux.org/alpine/edge/main\n@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

RUN apk --no-cache add wget libavc1394-dev \
  libtbb@testing  \
  libtbb-dev@testing   \
  libjpeg  \
  libjpeg-turbo-dev \
  libpng-dev \
  libjasper \
  libdc1394-dev \
  clang-dev \
  clang \
  tiff-dev \
  libwebp-dev \
  openblas-dev@community \
  linux-headers

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

#Open CV Install
RUN mkdir /opt && cd /opt && \
  wget https://github.com/opencv/opencv/archive/3.1.0.zip && \
  unzip 3.1.0.zip && \
  cd /opt/opencv-3.1.0 && \
  mkdir build && \
  cd build && \
  cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_FFMPEG=NO \
  -D WITH_IPP=NO -D WITH_OPENEXR=NO .. && \
  make VERBOSE=1 && \
  make && \
  make install

RUN rm -rf /var/cache/apk/* \
&& rm -r /tmp/build


CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]