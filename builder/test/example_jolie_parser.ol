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

    response.tag[0] = tag
    response.tag[1] = "example"

    s = request.log
    s.prefix = "alert"
    startsWith@StringUtils( s )( startsWithAlert )

    if( startsWithAlert ) {
      println@Console( "Sending alarm" )()
      splitreq = request.log
      splitreq.regex = ":"
      splitreq.limit = 3
      split@StringUtils( splitreq )( split )

      response.alert.name = split.result[1];
      response.alert.severity = split.result[2]
    }

  }
}
