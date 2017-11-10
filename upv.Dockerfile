ARG ROOT_UPV_TAG
# the root upv framework image, pulled and tagged by ./upv.sh script
FROM ${ROOT_UPV_TAG}

# Pythonz + Python 3.6.3 + related system dependencies
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
            build-essential zlib1g-dev libbz2-dev \
            libssl-dev libreadline-dev libncurses5-dev libsqlite3-dev libgdbm-dev libdb-dev \
            libexpat-dev libpcap-dev liblzma-dev libpcre3-dev &&\
    rm -rf /var/lib/apt/lists/*
RUN curl -kL https://raw.github.com/saghul/pythonz/master/pythonz-install | bash &&\
    /usr/local/pythonz/bin/pythonz install 3.6.3 &&\
    /usr/local/pythonz/pythons/CPython-3.6.3/bin/pip3.6 install --no-cache-dir when-changed pipenv pew
ENV PATH=${PATH}:/usr/local/pythonz/pythons/CPython-3.6.3/bin

# pipenv environment + app dependencies
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY Pipfile /upv/workspace/
COPY Pipfile.lock /upv/workspace/
RUN pipenv install
ENV SHELL=/bin/bash
ENV UPV_BASH="pipenv shell"
