#####################################################################################################################################################
# Creates pseudo distributed hadoop 2.7.1
#
# docker build --rm -t rtzan/apache-camel .
# docker build --rm --build-arg http_proxy=$http_proxy -t rtzan/apache-camel .
# 
# docker run -it rtzan/apache-camel /etc/bootstrap.sh -bash
# 
# 
# 
# docker run -it  -v c:/R/STUDY/m2_repo:/tmp/.m2/repository -v c:/R/STUDY/apache-camel:/home/source rtzan/apache-camel -bash
# 
# docker run -it  -v c:/R/STUDY/m2_repo:/tmp/.m2/repository -v c:/R/STUDY/apache-camel:/home/source rtzan/apache-camel /etc/bootstrap.sh -bash
# 
#####################################################################################################################################################
FROM rtzan/pam:centos-6.5
MAINTAINER rtzan
#
USER root
# 
ARG http_proxy
# 
ENV http_proxy $http_proxy
ENV https_proxy $http_proxy
# 
#====================================================================================================================================================
RUN touch /var/lib/rpm/* \
    && yum -y install yum-plugin-ovl
# 
# install dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl which tar sudo openssh-server openssh-clients rsync wget initscripts
# 
# update libselinux. see https://github.com/sequenceiq/hadoop-docker/issues/14
RUN yum update -y libselinux \
    && yum clean all
#====================================================================================================================================================
# PASSWORD-LESS ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
#====================================================================================================================================================
# JAVA    ===========================================================================================================================================
# download/copy JDK. Comment one of these. The curl command can be retrieved
# from https://lv.binarybabel.org/catalog/java/jdk8
#RUN curl --insecure -LOH 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm'
COPY local_files/jdk-8u221-linux-x64.rpm /

RUN rpm -i jdk-8u221-linux-x64.rpm
RUN rm jdk-8u221-linux-x64.rpm

#RUN yum -y install java-1.8.0-openjdk-devel.x86_64 && yum clean all

ENV JAVA_HOME /usr/java/jdk1.8.0_221-amd64
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java
#====================================================================================================================================================
#====================================================================================================================================================
# MAVEN   ===========================================================================================================================================
#RUN curl --insecure -L https://archive.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz | tar -xz -C /usr/local
COPY local_files/apache-maven-3.5.0-bin.tar.gz /tmp/apache-maven-3.5.0-bin.tar.gz
RUN tar -xzf /tmp/apache-maven-3.5.0-bin.tar.gz -C /usr/local

RUN cd /usr/local && ln -s ./apache-maven-3.5.0/ maven
ENV PATH $PATH:/usr/local/maven/bin

COPY config_files/mvn_settings.xml /usr/local/maven/conf/settings.xml

RUN mkdir -p /tmp/.m2/repository

ENV MAVEN_OPTS '-Xms2048m -Xmx3584m'

#====================================================================================================================================================
# SOURCE CODE =======================================================================================================================================

RUN mkdir -p /home/source

#====================================================================================================================================================
# HADOOP  ===========================================================================================================================================
# download native support
RUN mkdir -p /tmp/native
#RUN curl --insecure -L https://github.com/sequenceiq/docker-hadoop-build/releases/download/v2.7.1/hadoop-native-64-2.7.1.tgz | tar -xz -C /tmp/native
COPY local_files/jdk-8u221-linux-x64.rpm /tmp/native
# 
# hadoop
# download/copy hadoop. Choose one of these options
ENV HADOOP_PREFIX /usr/local/hadoop
#RUN curl --insecure -s https://archive.apache.org/dist/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz | tar -xz -C /usr/local/
COPY local_files/hadoop-2.7.1.tar.gz $HADOOP_PREFIX-2.7.1.tar.gz
RUN tar -xzvf $HADOOP_PREFIX-2.7.1.tar.gz -C /usr/local

RUN cd /usr/local \
    && ln -s ./hadoop-2.7.1 hadoop \
    && chown root:root -R hadoop/

#====================================================================================================================================================
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_YARN_HOME $HADOOP_PREFIX
ENV HADOOP_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
# 
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/jdk1.8.0_221-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
# 
RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input
# 
# pseudo distributed
ADD config_files/core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD config_files/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
# 
ADD config_files/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD config_files/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
# 
# prepare tez installation
#ADD config_files/tez-site.xml $HADOOP_PREFIX/etc/hadoop/tez-site.xml
#RUN mkdir -p /root/tez
#RUN curl -s http://www-eu.apache.org/dist/tez/0.8.5/apache-tez-0.8.5-bin.tar.gz | tar -xz -C /root/tez
# 
#RUN $HADOOP_PREFIX/bin/hdfs namenode -format
# 
# fixing the libhadoop.so like a boss
RUN rm -rf /usr/local/hadoop/lib/native
RUN mv /tmp/native /usr/local/hadoop/lib
# 
#====================================================================================================================================================


ADD config_files/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config
# 
# --------------------------------------------------
# # installing supervisord
# RUN yum install -y python-setuptools
# RUN easy_install pip
# RUN curl https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -o - | python
# RUN pip install supervisor
# 
# ADD supervisord.conf /etc/supervisord.conf
# --------------------------------------------------
# 
ENV BOOTSTRAP /etc/bootstrap.sh
ADD bootstrap.sh $BOOTSTRAP
RUN chown root:root $BOOTSTRAP
RUN chmod 700 $BOOTSTRAP
# 
# --------------------------------------------------
# working around docker.io build error
RUN ls -la $HADOOP_PREFIX/etc/hadoop/*-env.sh
RUN chmod +x $HADOOP_PREFIX/etc/hadoop/*-env.sh
RUN ls -la $HADOOP_PREFIX/etc/hadoop/*-env.sh
# --------------------------------------------------

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

#RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
#RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

CMD ["/etc/bootstrap.sh", "-d"]

#====================================================================================================================================================

ENV PS1 '\[\e]0;\w\a\]\n\[\e[32m\]\u@\[\e[33m\][\w]\[\e[0m\] \$'

#====================================================================================================================================================
# HDFS ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
# Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
# SSHD port
EXPOSE 2122
# Other ports
EXPOSE 49707
#####################################################################################################################################################