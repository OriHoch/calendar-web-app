FROM ubuntu:16.04

RUN apt-get update &&\
    apt-get install -y --no-install-recommends jq apt-transport-https ca-certificates gnupg2 software-properties-common curl\
                                               sudo python2.7 python-pip bash uuid-runtime &&\
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - &&\
    apt-key fingerprint 0EBFCD88 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" &&\
    apt-get update && apt-get install -y --no-install-recommends docker-ce &&\
    pip install --upgrade pip setuptools && pip install --no-cache-dir python-dotenv pyyaml &&\
    rm -rf /var/lib/apt/lists/*

RUN echo "source /upv/workspace/upv/functions.sh" >> /root/.bashrc
RUN echo "source /upv/workspace/functions.sh" >> /root/.bashrc
WORKDIR /upv/workspace
ENTRYPOINT ["/upv/workspace/upv/entrypoint.sh"]
