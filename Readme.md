Jupyter notebooks as a service at IQSS
======================================

[Jupyter notebooks](http://jupyter.org/) allow users to run programs and view output directly in a web browser. The Jupyter project provides docker images for running temporary notebooks on demand. This sub-project of the Jupyter organization is called [tmpnb](https://github.com/jupyter/tmpnb). 

 The Data Science Services team (DSS; formerly known as Research Technology Consulting) has long desired to make workshop materials "live" so that people who cannot attend the workshops in person can modify and run the examples directly on our website. With the development of tmpnb this is now technically feasible.
 
 This repository contains a Dockerfile and other materials that can be used to create a tmpnb service providing interactive versions of DSS workshop notes.


System requirements
-------------------
[docker](http://docker.com) and an open port 8000 are required. [Archlinux](http://archlinux.org) is optionally required if you want to build the docker images yourself (details below).

I actually don't know what the minimum system memory/CPU/disk requirements are. It obviously depends in part on how many people are expected to use the system at any given time. I've tested 10 concurrent connections on a system with 8 Gb of memory and 4 CPUs and it seemed to work fine. As a wild guess I would say that around 20 Gb of disk space may be required.

Quick start
==========

You can deploy this service easily using docker images that I have pre-built. Simply clone this repository, download the docker image from [https://dss.izahn.com//ista/iqss-jupyter-notebook.tar](https://dss.izahn.com//ista/iqss-jupyter-notebook.tar) (md5sum: `5467b12a72d89e2245108de7103d76eb`), load it with `docker load --input iqss-jupyter-notebook.tar`, and start the service by running the included `start-tmpnb.sh` script. Note that the image is about 3 Gb, so loading it into docker is expected to be slow. The `start-tmpnb.sh` script will pull and run additional [docker images from the Jupyter project](https://github.com/jupyter/docker-stacks) and start Jupyter notebook services running on port 8000.

You can stop reading here unless you want to build the images yourself.

Building and deploying
======================

I have chosen [Archlinux](http://www.archlinux.org) as the base upon which to build the docker image running Jupyter. This is because Archlinux provides up-to-date versions of R, Python, Octave etc., unlike most Linux distributions which tend to ship older versions of these packages. This choice creates some difficulties, because Archlinux does not provide an official docker image. 

Acquiring an Archlinux docker image
-----------------------------------
The first step is to build or otherwise acquire an Archlinux docker image. There are at least two approaches. 

I have built an Archlinux docker image that you can download from [https://dss.izahn.com//ista/archlinux.tar](https://dss.izahn.com//ista/archlinux.tar) (md5sum: `d41d8cd98f00b204e9800998ecf8427e`).  You can load this image into docker using `docker load`.

If you want to build the Archlinux image yourself you can do so using the [build script provided by docker](https://github.com/docker/docker/tree/master/contrib). I have included copies the required files in this repository for convenience. This is the approach I recommend because it avoids relying on unofficial docker images, and because it produces a clean and up-to-date base on which to build. The downside is that you need an Archlinux system on which to build the image. If you don't already have an Archlinux installation, install Arch following the [Beginners guide](https://wiki.archlinux.org/index.php/Beginners%27_guide). Then install docker and the build scripts with `pacman -S base-devel git docker arch-install-scripts`. Finally, clone this repository and run 
```
cp /etc/pacman.conf ./mkimage-arch-pacman.conf # or get a pacman.conf from somewhere else 
LC_ALL=C ./mkimage-arch.sh # LC_ALL=C because the script parses the console output
```
to build the image (it will be tagged `Archlinux`). See [the Archlinux wiki](https://wiki.archlinux.org/index.php/Docker#Build_Image) for details about running Archlinux in docker.


Alternatively you can use the unofficial image (`docker pull base/archlinux`) and change `FROM archlinux` to `FROM base/archlinux` in the `Dockerfile`. This is easy but requires relying on the unofficial `base/archlinux` docker image. It is also somewhat less than ideal because `base/archlinux` is not frequently updated.

Build and deploy docker images running Jupyter
----------------------------------------------

Once you have acquired an Archlinux docker image building the image with everything needed to run DSS workshops is easy. Install docker and git, clone this repository and `cd` to it, and build the image with `docker build -t iqss-jupyter-notebook .` Once the image finishes building you can start the service by running the included `start-tmpnb` script.

