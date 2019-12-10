include "parser.iol"
include "string_utils.iol"
include "console.iol"

execution{ concurrent }

main
{
  parseLog( request ) ( response ){

    println@Console( "Parsing log" )()
    response.content = request.log
    response.logtype = "The loggy type"

    c = request.log
    c.begin = 0
    c.end = 10

    substring@StringUtils( c )( tag )

    response.tag = tag
  }
}
