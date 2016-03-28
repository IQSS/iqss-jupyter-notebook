# Copyright (c) Harvard University.
# Distributed under the terms of the Modified BSD License.

# Debian testing image
FROM debian:testing
MAINTAINER Ista Zahn <izahn@g.harvard.edu>

# Install all OS dependencies for fully functional notebook server

# Configure environment
ENV DEBIAN_FRONTEND noninteractive
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update && apt-get upgrade -y

# Install build stuff
RUN apt-get install -y --no-install-recommends --fix-missing \
    ed \
    git \
    wget \
    build-essential \
    libzmq3 \
    libzmq3-dev \
    ca-certificates \
    bzip2 \
    unzip \
    libsm6 \
    sudo \
    locales \
    fonts-dejavu \
    gfortran \
    gcc \
    libav-tools \
    libgl1-mesa-glx \
    libglu1 \
    libpng12-0\
    libgl1-mesa-dev \
    libglu-dev \
    libpng-dev \
    libx11-dev \
    pkgconf \
    libfreetype6 \
    libfreetype6-dev \
    cdbs \
    autotools-dev \
    libxml2 \
    zlib1g \
    libxml2-dev \
    libcurl3 \
    libcurl4-openssl-dev \
    icu-devtools \
    libicu-dev \
    libicu55 \
    libssl-dev

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen


# Install R, Julia
RUN apt-get install -y --no-install-recommends --fix-missing r-base r-base-dev julia octave gnuplot

# Install jupyter stuff

RUN apt-get install -y --no-install-recommends --fix-missing \
    python \
    python3 \
    python-pip\
    python3-pip \
    python-dev \
    python3-dev

# install python packages
RUN pip3 install pexpect pickleshare simplegeneric zmq pandas jupyter ipykernel matplotlib numpy pycrypto octave_kernel bash_kernel && \
    pip install pexpect pickleshare simplegeneric zmq pandas matplotlib numpy pycrypto ipykernel octave_kernel && \
    python3 -m octave_kernel.install && \
    python3 -m bash_kernel.install && \
    python2 -m ipykernel install && \
    python3 -m ipykernel install

# Create jovyan user with UID=1000
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

USER jovyan

# Install julia packages
RUN julia -e 'Pkg.add("IJulia")' && \
    julia -e 'Pkg.add("DataFrames")' && \
    julia -e 'Pkg.add("Gadfly")' && \
    julia -e 'Pkg.update()'

# Install R packages
COPY .Rprofile /home/$NB_USER/
RUN cd /home/$NB_USER && \
    mkdir R && \
    Rscript -e "install.packages(c('directlabels', 'rgl', 'rglwidget', 'ggplot2', 'ggmap', 'ggrepel', 'rvest', 'forecast', 'effects', 'stringi', 'rio'), repos = 'https://cloud.r-project.org')" && \
    Rscript -e "update.packages(lib.loc = '~/R', ask = FALSE, repos = 'https://cloud.r-project.org')" && \
    Rscript -e "install.packages(c('rzmq','repr','IRkernel','IRdisplay'), repos = c('http://irkernel.github.io/', 'http://cran.rstudio.com'),type = 'source')" && \
     Rscript -e "IRkernel::installspec()"

# Set up jupyter config
RUN pip3 install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user && \
    mkdir -p /home/$NB_USER/.jupyter/nbconfig
COPY notebook.json /home/$NB_USER/.jupyter/nbconfig/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/

# Sync workshop archives
RUN mkdir /home/$NB_USER/work && \
    cd /home/$NB_USER/work && \
    git clone --depth 1 https://github.com/izahn/workshops.git && \
    cd workshops/Python && \
    git clone --depth 1 https://github.com/kareemcarr/IntroductionToPythonWorkshop.git && \
    git clone --depth 1 https://github.com/kareemcarr/IntermediatePython.git

USER root
# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure container startup as root
EXPOSE 8888
WORKDIR /home/$NB_USER/work
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Make sure jovyan has correct permissions 
RUN chown -R $NB_USER:users /home/$NB_USER/

# Install notebook startup script
COPY start-notebook.sh /usr/local/bin/

# Cleanup
RUN apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/journal/* && \
    rm -rf /var/cache/pacman/pkg/* && \
    rm -rf /tmp/*

# Run container as jovyan
USER jovyan

