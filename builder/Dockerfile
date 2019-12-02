FROM jolielang/jolie
EXPOSE 8000
RUN apk add docker
WORKDIR /aws
RUN apk -v --update add \
        python \
        py-pip \
        groff \
        less \
        mailcap \
        && \
    pip install --upgrade awscli s3cmd==2.0.1 python-magic && \
    apk -v --purge del py-pip && \
    rm /var/cache/apk/*
WORKDIR /builder
COPY src src
COPY test test
ADD Dockerfile.jolie .
CMD $(aws ecr get-login --no-include-email --region eu-central-1) && jolie src/builder.ol
