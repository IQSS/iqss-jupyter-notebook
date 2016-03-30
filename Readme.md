Jupyter notebooks as a service at IQSS
======================================

[Jupyter notebooks](http://jupyter.org/) allow users to run programs and view output directly in a web browser. The Jupyter project provides docker images for running temporary notebooks on demand. This sub-project of the Jupyter organization is called [tmpnb](https://github.com/jupyter/tmpnb). 

 The Data Science Services team (DSS; formerly known as Research Technology Consulting) has long desired to make workshop materials "live" so that people who cannot attend the workshops in person can modify and run the examples directly on our website. With the development of tmpnb this is now technically feasible.
 
 This repository contains a Dockerfile and other materials that can be used to create a tmpnb service providing interactive versions of DSS workshop notes.

Building and deploying
======================

I have chosen [Archlinux](http://www.archlinux.org) as the base upon which to build the docker image running Jupyter. This is because Archlinux provides up-to-date versions of R, Python, Octave etc., unlike most linux distributions which tend to ship older versions of these packages. This choice creates some difficulties, because Archlinux does not provide an official docker image. 

Acquiring an Archlinux docker image
-----------------------------------
The first steo is to build or otherwise aquire an Archlinux docker image. There are at least two approaches. 

You can build an archlinux docker image using the [build script provided by docker](https://github.com/docker/docker/tree/master/contrib). I have included copies the reqiured files in this repository for conveniance. This is the approach I recommend because it avoids relying on unoffficial docker images, and because it produces a clean and up-to-date base on which to build. The downside is that you need an Archlinux system on which to build the image. If you don't already have an Archlinux installition, install Arch following the [Beginners guid](https://wiki.archlinux.org/index.php/Beginners%27_guide). Then install docker and the build scripts with `pacman -S base-devel git docker arch-install-scripts`. Finally, clone this repository and run the `mkimage-arch.sh` script to build the image. 

If this all sounds like too much work you can just download an image that I built from [http://izahn.crabdance.com/iqss-jupyter-notebook.tar](http://izahn.crabdance.com/iqss-jupyter-notebook.tar). You can load this image into docker using `docker load`.
Alterntatively you can use the unofficial image (`docker pull base/archlinux`) and change `FROM archlinux` to `FROM base/archlinux` in the `Dockerfile`. This is easy but requires relying on the unoffficial `base/archlinux` docker image. It is also somewhat less than ideal because `base/archlinux` is not frequently updated.

Build and deploy docker images running jupyter
----------------------------------------------

Once you have aquired an Archlinux docker image building the image with everything needed to run DSS workshops is easy. Install docker and git, clone this repository and `cd` to it, and build the image with `docker build -t iqss-jupyter-notebook .` Once the image finishes building you can start the service by running the included `start-tmpnb` script.


