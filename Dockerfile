FROM ubuntu:20.04

# Let's start with some basic stuff.
RUN apt-get update && apt-get install -qqy \
    python3-pip \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    lxc \
    wget \
    && curl -sSL https://get.docker.com/ | sh

# Install the wrapper script from https://raw.githubusercontent.com/docker/docker/master/hack/dind.
ADD ./dind /usr/local/bin/dind
ADD ./wrapdocker /usr/local/bin/wrapdocker

RUN chmod +x /usr/local/bin/dind \
    && chmod +x /usr/local/bin/wrapdocker

# Install Jenkins
RUN wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add - \
    && sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list' \
    && apt-get update && apt-get install -y openjdk-8-jdk-headless zip supervisor jenkins && rm -rf /var/lib/apt/lists/* \
    && usermod -a -G docker jenkins && mkdir /tmp/hsperfdata_jenkins

ENV JENKINS_HOME /var/lib/jenkins
VOLUME /var/lib/jenkins

# get plugins.sh tool from official Jenkins repo
# this allows plugin installation
ENV JENKINS_UC https://updates.jenkins.io

RUN curl -o /usr/local/bin/plugins.sh \
  https://raw.githubusercontent.com/jenkinsci/docker/master/plugins.sh && \
  chmod +x /usr/local/bin/plugins.sh
#COPY plugins.sh /usr/local/bin/plugins.sh
#RUN chmod +x /usr/local/bin/plugins.sh

# Define additional metadata for our image.
VOLUME /var/lib/docker

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# copy files onto the filesystem
COPY files/ /
RUN chmod +x /docker-entrypoint /usr/local/bin/*

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

# set the entrypoint
ENTRYPOINT ["/docker-entrypoint"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
