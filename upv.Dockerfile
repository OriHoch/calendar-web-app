FROM ubuntu:16.04

# Base
RUN apt-get update &&\
    apt-get install -y --no-install-recommends jq apt-transport-https ca-certificates gnupg2 software-properties-common curl\
                                               sudo python2.7 python-pip bash build-essential zlib1g-dev libbz2-dev \
                                               libssl-dev libreadline-dev libncurses5-dev libsqlite3-dev libgdbm-dev libdb-dev \
                                               libexpat-dev libpcap-dev liblzma-dev libpcre3-dev uuid-runtime &&\
    rm -rf /var/lib/apt/lists/*

# Docker
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - &&\
    apt-key fingerprint 0EBFCD88 &&\
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends docker-ce &&\
    rm -rf /var/lib/apt/lists/*

# Travis
RUN apt-get update &&\
    apt-get install -y --no-install-recommends ruby ruby-dev &&\
    gem install travis -v 1.8.8 --no-rdoc --no-ri &&\
    rm -rf /var/lib/apt/lists/*

# system python dependencies
RUN pip install --upgrade pip setuptools && pip install python-dotenv pyyaml when-changed

# Pythonz + Python 3.6.3
RUN curl -kL https://raw.github.com/saghul/pythonz/master/pythonz-install | bash
RUN /usr/local/pythonz/bin/pythonz install 3.6.3
ENV PATH=${PATH}:/usr/local/pythonz/pythons/CPython-3.6.3/bin

# python 3.6 dependencies
RUN pip3.6 install --no-cache-dir when-changed pipenv pew

# Additional dependencies should be added here, and moved later to previous layer, when they were used for a while
RUN apt-get update &&\
    apt-get install -y --no-install-recommends git &&\
    rm -rf /var/lib/apt/lists/*

# upv workspace - will be volume mounted with project root
RUN mkdir -p /upv/workspace
WORKDIR /upv/workspace

# pipenv
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY Pipfile /upv/workspace/
COPY Pipfile.lock /upv/workspace/
RUN pipenv install

# upv framework
COPY upv/*.sh /upv/

ENV SHELL=/bin/bash
ENV UPV_BASH="pipenv shell"

RUN echo "source /upv/functions.sh" >> /root/.bashrc
RUN echo "source /upv/workspace/functions.sh" >> /root/.bashrc
ENTRYPOINT ["/upv/entrypoint.sh"]
