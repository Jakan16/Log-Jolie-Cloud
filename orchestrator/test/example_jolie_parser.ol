include "parser.iol"

inputPort Parser {
  Location: "socket://localhost:27521"
  Protocol: sodep
  Interfaces: LogParserInterface
}

main
{
  parseLog( request ) ( response ){
    response.content = request.log
    response.logtype = "The loggy type"

    c = request.log
    c.begin = 0
    c.end = 10

    substring@StringUtils( c )( tag )

    response.tag = tag
  }
}
