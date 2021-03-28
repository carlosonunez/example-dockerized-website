FROM alpine
LABEL maintainer="Carlos Nunez <dev@carlosnunez.me>"

RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.8/terraform_0.14.8_linux_amd64.zip
RUN unzip terraform.zip -d /

ENTRYPOINT [ "/terraform" ]
RUN mkdir /terraform
USER nobody
