# Copyright (c) Harvard University.
# Distributed under the terms of the Modified BSD License.

# Arch Linux
FROM base/archlinux
MAINTAINER Ista Zahn <izahn@g.harvard.edu>

RUN curl -o /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=all&protocol=https&ip_version=6&use_mirror_status=on" && \
  sed -i 's/^#//' /etc/pacman.d/mirrorlist

RUN pacman-key --populate && \
  pacman-key --refresh-keys && \
  pacman -Sy --noprogressbar --noconfirm && \
  pacman-db-upgrade && \
  pacman -Syyuu --noprogressbar --noconfirm && \
  pacman-db-upgrade && \
  pacman -Suu --noprogressbar --noconfirm && \
  pacman -Rs --noconfirm $(pacman -Qqdt) && \
  pacman -Scc --noprogressbar --noconfirm

# Install build stuff
RUN pacman -S --noconfirm \
    base-devel \
    gcc-fortran \
    cmake \
    git \
    zeromq \
    curl \
    openssl \
    ttf-dejavu \
    glu \
    icu \
    cairo \
    ed && \
    pacman -Scc --noconfirm

# Configure environment
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install R, Julia, and Octave
RUN pacman -S --noconfirm r julia octave && \
    pacman -Scc --noconfirm

# Install jupyter stuff
RUN pacman -S --noconfirm \
    python \
    python2 \
    ipython2-notebook \
    jupyter-notebook \
    python-cairo \
    python-crypto \
    python2-crypto \
    python-yaml \
    python2-yaml \
    python-psutil \
    python2-psutil \
    python-pip \
    python2-pip && \
    pip install \
    octave_kernel \
    bash_kernel && \
    python -m octave_kernel.install && \
    python -m bash_kernel.install && \
    pacman -Scc --noconfirm

# install python packages
RUN pacman -S --noconfirm \
    python-matplotlib \
    python-numpy \
    python-pandas \
    python2-matplotlib \
    python2-numpy \
    python2-pandas && \
    pacman -Scc --noconfirm

# Install R packages

RUN Rscript -e "install.packages(c('directlabels', 'rgl', 'rglwidget', 'ggplot2', 'ggmap', 'ggrepel', 'rvest', 'forecast', 'effects', 'stringi', 'rio'), repos = 'https://cloud.r-project.org')" && \
    Rscript -e "install.packages(c('rzmq','repr','IRkernel','IRdisplay'), repos = c('http://irkernel.github.io/', 'http://cran.rstudio.com'),type = 'source')"

# Create jovyan user with UID=1000
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

USER jovyan
# Install extra kernels and nbextensions as user jovyan
RUN julia -e 'Pkg.add("IJulia")' && \
Rscript -e "IRkernel::installspec()" && \
pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user

# Set up Rprofile
COPY .Rprofile /home/$NB_USER/

# Sync workshop archives
RUN mkdir /home/$NB_USER/work && \
    cd /home/$NB_USER/work && \
    git clone --depth 1 https://github.com/izahn/workshops.git && \
    cd workshops/Python && \
    git clone --depth 1 https://github.com/kareemcarr/IntroductionToPythonWorkshop.git && \
    git clone --depth 1 https://github.com/kareemcarr/IntermediatePython.git

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

# Add local files as late as possible to avoid cache busting
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY start-notebook.sh /usr/local/bin/
RUN chown -R $NB_USER:users /home/$NB_USER/

# Cleanup
RUN pacman --noconfirm -Scc && \
    rm -rf /var/log/journal/* && \
    rm -rf /var/cache/pacman/pkg/* && \
    rm -rf /tmp/*

# Run container as jovyan
USER jovyan

