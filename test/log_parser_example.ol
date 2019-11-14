include "../interfaces/log_parser_interface.iol"
include "string_utils.iol"

inputPort Parser {
  Location: "socket://localhost:32799"
  Protocol: sodep
  Interfaces: LogParseInterface
}

execution{ concurrent }

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
