# Copyright (c) Harvard University.
# Distributed under the terms of the Modified BSD License.

# Arch Linux
FROM archlinux/base
MAINTAINER Ista Zahn <izahn@g.harvard.edu>
RUN pacman-key --init && \
     pacman -Syy --noprogressbar --noconfirm && \
     pacman -S archlinux-keyring --noconfirm && \
     pacman -Syy --noconfirm && \
     pacman -Suu --noprogressbar --noconfirm && \
     pacman -Scc --noprogressbar --noconfirm

# Install build stuff
RUN pacman -S --noconfirm \
    man-db \
    base-devel \
    gcc-fortran \
    cmake \
    git \
    glu \
    zeromq \
    curl \
    openssl \
    ttf-dejavu \
    icu \
    pandoc \
    ed \
    vim && \
    pacman -Scc --noconfirm

# Configure environment
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install R, Julia
RUN pacman -S --noconfirm r julia octave gnuplot && \
    pacman -Scc --noconfirm

# Install jupyter stuff
RUN pacman -S --noconfirm \
    python \
    python2 \
    ipython2-notebook \
    jupyter-notebook \
    jupyter-nbconvert \
    python-yaml \
    python2-yaml \
    python-pip \
    python2-pip  && \
    pacman -Scc --noconfirm && \
    pip install bash_kernel octave_kernel &&\
    python -m octave_kernel.install && \
    python -m bash_kernel.install

# install python packages
RUN pacman -S --noconfirm \
    python-matplotlib \
    python-numpy \
    python-pandas \
    python-crypto \
    python2-matplotlib \
    python2-numpy \
    python2-pandas \
    python2-crypto && \
    pacman -Scc --noconfirm

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
    Rscript -e "update.packages(lib.loc = .libPaths()[1], ask = FALSE, repos = 'https://cloud.r-project.org')" && \
    Rscript -e "install.packages(c('httr', 'curl', 'tidyverse', 'plotly', 'directlabels', 'rgl', 'ggplot2', 'ggmap', 'ggrepel', 'rvest', 'forecast', 'effects', 'stringi', 'rio', 'repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'devtools', 'uuid', 'digest'), repos = 'https://cloud.r-project.org')" && \
    Rscript -e "devtools::install_github('IRkernel/IRkernel')" && \
    Rscript -e "IRkernel::installspec()"

# Set up jupyter config
RUN pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user && \
    mkdir -p /home/$NB_USER/.jupyter/nbconfig && \
    mkdir -p /home/$NB_USER/.jupyter/custom 
COPY notebook.json /home/$NB_USER/.jupyter/nbconfig/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY custom.css /home/$NB_USER/.jupyter/custom/
COPY logo.png /home/$NB_USER/.jupyter/custom/

# Sync workshop archives
RUN mkdir /home/$NB_USER/work && \
    cd /home/$NB_USER/work && \
    git clone --depth 1 https://github.com/izahn/workshops.git && \
    cd workshops/Python && \
    git clone --depth 1 https://github.com/kareemcarr/IntroductionToPythonWorkshop.git && \
    git clone --depth 1 https://github.com/kareemcarr/IntermediatePython.git && \
    git clone --depth 1 https://github.com/nmbrodnax/iqss-python-scrape.git && \
    git clone --depth 1 https://github.com/nmbrodnax/iqss-python-api.git && \
    git clone --depth 1 https://github.com/nmbrodnax/iqss-python-intro.git

# build tini
RUN gpg --keyserver pgp.mit.edu --recv-keys 456032D717A4CD9C && \
    cd /tmp && \
    git clone https://aur.archlinux.org/tini.git && \
    cd tini && \
    makepkg

USER root
# install tini
RUN cd /tmp/tini && \
    pacman -U --noconfirm tini*.tar.xz && \
    cd /tmp && \
    rm -rf tini

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
RUN pacman --noconfirm -Scc && \
    rm -rf /var/log/journal/* && \
    rm -rf /var/cache/pacman/pkg/* && \
    rm -rf /tmp/*

# Run container as jovyan
USER jovyan

