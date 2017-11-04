FROM ubuntu

RUN apt-get update &&\
    apt-get install -y --no-install-recommends jq apt-transport-https ca-certificates gnupg2 software-properties-common curl\
                                               sudo python2.7 python-pip bash build-essential zlib1g-dev libbz2-dev \
                                               libssl-dev libreadline-dev libncurses5-dev libsqlite3-dev libgdbm-dev libdb-dev \
                                               libexpat-dev libpcap-dev liblzma-dev libpcre3-dev uuid-runtime

RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - &&\
    apt-key fingerprint 0EBFCD88 &&\
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y docker-ce

RUN pip install --upgrade pip setuptools && pip install python-dotenv pyyaml

RUN curl -kL https://raw.github.com/saghul/pythonz/master/pythonz-install | bash
RUN /usr/local/pythonz/bin/pythonz install 3.6.3
ENV PATH=${PATH}:/usr/local/pythonz/pythons/CPython-3.6.3/bin

RUN mkdir -p /upv/workspace
WORKDIR /upv/workspace

RUN pip3.6 install --no-cache-dir when-changed pipenv pew

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY Pipfile /upv/workspace/
COPY Pipfile.lock /upv/workspace/
RUN pipenv install

COPY upv/*.sh /upv/

ENV SHELL=/bin/bash
ENV UPV_BASH="pipenv shell"

RUN echo "source /upv/functions.sh" >> /root/.bashrc
ENTRYPOINT ["/upv/entrypoint.sh"]
