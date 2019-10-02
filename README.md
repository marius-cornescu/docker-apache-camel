# Apache Hadoop 2.7.1 Docker image

[![DockerPulls](https://img.shields.io/docker/pulls/rtzan/docker-hadoop.svg)](https://registry.hub.docker.com/u/rtzan/docker-hadoop/)
[![DockerStars](https://img.shields.io/docker/stars/rtzan/docker-hadoop.svg)](https://registry.hub.docker.com/u/rtzan/docker-hadoop/)
[![Docker Build Statu](https://img.shields.io/docker/build/jrottenberg/ffmpeg.svg)](https://hub.docker.com/r/ouyi/hadoop-docker/)
[![Docker Automated buil](https://img.shields.io/docker/automated/jrottenberg/ffmpeg.svg)](https://hub.docker.com/r/ouyi/hadoop-docker/)


_Note: this is the master branch - for a particular Hadoop version always check the related branch_

A few weeks ago we released an Apache Hadoop 2.3 Docker image - this quickly become the most [popular](https://registry.hub.docker.com/search?q=hadoop&s=downloads) Hadoop image in the Docker [registry](https://registry.hub.docker.com/).


Following the success of our previous Hadoop Docker [images](https://registry.hub.docker.com/u/rtzan/docker-hadoop/), the feedback and feature requests we received, we aligned with the Hadoop release cycle, so we have released an Apache Hadoop 2.7.1 Docker image - same as the previous version, it's available as a trusted and automated build on the official Docker [registry](https://registry.hub.docker.com/).


_FYI: All the former Hadoop releases (2.3, 2.4.0, 2.4.1, 2.5.0, 2.5.1, 2.5.2, 2.6.0) are available in the GitHub branches or our [Docker Registry](https://registry.hub.docker.com/u/rtzan/docker-hadoop/) - check the tags._

# Build the image

If you'd like to try directly from the Dockerfile you can build the image as:

```
docker build  -t rtzan/docker-hadoop:2.7.1 .

docker build  -t rtzan/docker-hadoop:2.7.1-7.5 .
```
# Pull the image

The image is also released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.

```
docker pull rtzan/docker-hadoop:2.7.1
```

# Start a container

In order to use the Docker image you have just built or pulled, use:

**Make sure that SELinux is disabled on the host. If you are using boot2docker you don't need to do anything.**

```
docker run -it rtzan/docker-hadoop:2.7.1 /etc/bootstrap.sh -bash

docker run -it rtzan/docker-hadoop:2.7.1-7.5 /etc/bootstrap.sh -bash

```


```
# get container ip:
docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" <container name>


# add a use testuser with password testuser
useradd -p $(openssl passwd -1 testuser) testuser


```


## Testing

You can run one of the stock examples:

```
cd $HADOOP_PREFIX
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```

## Hadoop native libraries, build, Bintray, etc

The Hadoop build process is no easy task - requires lots of libraries and their right version, protobuf, etc and takes some time - we have simplified all these, made the build and released a 64b version of Hadoop nativelibs on this [Bintray repo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.7.0/view/files). Enjoy.

## Automate everything

As we have mentioned previously, a Docker file was created and released in the official [Docker repository](https://registry.hub.docker.com/u/rtzan/docker-hadoop/)
