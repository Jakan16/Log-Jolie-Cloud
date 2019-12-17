FROM jolielang/jolie
EXPOSE 27521
COPY builder/src/parser.iol parser.iol
COPY builder/test/example_jolie_parser.ol parser.ol
CMD jolie parser.ol > stdout 2> error
