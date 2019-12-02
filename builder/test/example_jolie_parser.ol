include "parser.iol"

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
