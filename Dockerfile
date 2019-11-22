FROM jolielang/jolie
EXPOSE 8000
COPY src src
COPY interfaces interfaces
CMD jolie src/main.ol
