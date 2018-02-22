FROM centos:7

MAINTAINER Naftuli Kay <me@naftuli.wtf>

ENV CIRCLECI_USER=circleci
ENV CIRCLECI_HOME=/home/${CIRCLECI_USER}

# install epel
RUN yum install -y epel-release >/dev/null && yum clean all

# install python dev packages
RUN yum install -y sudo unzip git openssl-devel kernel-devel which make gcc python-devel python34-devel python-pip && \
  yum clean all

# install and upgrade pip and utils
RUN pip install --upgrade pip && pip install awscli ansible

# create sudo group and add sudoers config
COPY conf/sudoers.d/50-sudo /etc/sudoers.d/
RUN groupadd sudo

# create the user
RUN adduser -G sudo -m ${CIRCLECI_USER}

# deploy our tfenv command
RUN install -o ${CIRCLECI_USER} -g ${CIRCLECI_USER} -m 0700 -d ${CIRCLECI_HOME}/.local/bin
COPY bin/tfenv ${CIRCLECI_HOME}/.local/bin
RUN chmod 0755 ${CIRCLECI_HOME}/.local/bin/tfenv && \
  chown ${CIRCLECI_USER}:${CIRCLECI_USER} ${CIRCLECI_HOME}/.local/bin/tfenv

# deploy our ansible
RUN mkdir /tmp/docker
COPY ansible.cfg docker.yml requirements-docker.yml /tmp/docker/
RUN ( cd /tmp/docker && ansible-galaxy install --force -r requirements-docker.yml && \
  ansible-playbook -c local -i 127.0.0.1, -e circleci_user=${CIRCLECI_USER} docker.yml )

USER ${CIRCLECI_USER}
WORKDIR /home/${CIRCLECI_USER}/circleci
ENTRYPOINT ["/bin/bash", "-l"]
