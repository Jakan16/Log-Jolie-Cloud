FROM jolielang/jolie
EXPOSE 7999
WORKDIR /root
COPY gateway gateway
COPY lib/auth lib/auth
CMD jolie gateway/src/main.ol
