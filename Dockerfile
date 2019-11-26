FROM ubuntu:18.04 AS build
ARG AGENT_VERSION=2.160.1
ARG KUBECTL_VERSION=1.16.2
ARG DOCKER_VERSION=18.06.2-ce
ADD https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz .
ADD https://dl.k8s.io/v${KUBECTL_VERSION}/kubernetes-client-linux-amd64.tar.gz .
ADD https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz .
RUN tar xzf vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz --directory /tmp
RUN tar xzf kubernetes-client-linux-amd64.tar.gz --strip-components=3 --directory /tmp
RUN tar xzf docker-${DOCKER_VERSION}.tgz docker/docker --directory /tmp


FROM ubuntu:18.04
LABEL maintainer="alexey.miasoedov@gmail.com"

RUN useradd --system --home /opt/vstsagent --uid 1000 --create-home vstsagent

WORKDIR /opt/vstsagent

COPY Intermedia_Root_Certificate_Authority.pem /usr/local/share/ca-certificates/
COPY entrypoint.sh /usr/local/bin/
COPY --from=build --chown=vstsagent:vstsagent /tmp .

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl \
                                                                              git \
                                                                              liblttng-ust0 \
                                                                              ca-certificates \
                                                                              python-pip \
                                                                              openssh-client \
                                                                              rsync && \
    rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates && \
    ln -s /opt/vstsagent/kubectl /usr/local/bin/ && \
    ln -s /opt/vstsagent/docker /usr/local/bin/ && \
#    pip, then pip2 to avoid system pip shell path hashing
    pip install --upgrade --no-cache-dir pip && \
    pip2 install --no-cache-dir setuptools && \
    pip2 install --no-cache-dir awscli

#RUN ./bin/installdependencies.sh

USER vstsagent
ENTRYPOINT ["entrypoint.sh"]
