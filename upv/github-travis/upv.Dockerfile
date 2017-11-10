ARG BASE_UPV_TAG
# the base upv framework image contains project specific dependencies
# it's pulled and tagged by ./upv.sh script
FROM ${BASE_UPV_TAG}

# git, travis
RUN apt-get update &&\
    apt-get install -y --no-install-recommends git ruby ruby-dev &&\
    gem install travis -v 1.8.8 --no-rdoc --no-ri &&\
    rm -rf /var/lib/apt/lists/*
