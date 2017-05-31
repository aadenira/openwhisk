FROM ubuntu:17.04

ENV FLASK_PROXY_PORT 8080

RUN apt-get update \
    && apt-get install -y software-properties-common curl \
    && apt-get install -y python3.6-dev \
    && curl -o /tmp/get-pip.py "https://bootstrap.pypa.io/get-pip.py" \
    && python3.6 /tmp/get-pip.py \
    && apt-get remove -y curl \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Upgrade and install basic Python dependencies
RUN apt-get clean autoclean \
 && apt-get autoremove -y \
 && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN mkdir -p /actionProxy

ADD actionproxy.py /actionProxy/

RUN mkdir -p /action

#RUN add-apt-repository --remove ppa:jonathonf/python-3.6

RUN apt-get update  && apt-get install -y \
libopencv-dev wget unzip cmake make opencv-data

ADD requirements.txt requirements.txt

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.6 10
RUN update-alternatives --config python
RUN update-alternatives --remove-all python

RUN ln -s python3.6 /usr/bin/python
RUN python -m pip install -r requirements.txt
RUN python -m textblob.download_corpora
RUN python -m nltk.downloader stopwords

CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]
