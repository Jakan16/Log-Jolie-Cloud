include "console.iol"
include "json_utils.iol"

include "parser_interface.iol"
include "../../lib/auth/auth.iol"

execution{ concurrent }

type Log: void {
  authentication: string
  log: string
  logtype: string
  timestamp: long
}

interface GatewayInterface {
  RequestResponse:
    submitLog( Log )( void ) throws UnAuthorized( errorMsg )
  OneWay:
}

inputPort Gateway {
  Location: "socket://localhost:7999"
  Protocol: http
  Interfaces: GatewayInterface
}

outputPort Parser {
Location: "socket://localhost:27521"
Protocol: sodep
Interfaces: LogParserInterface
}

main
{
  [ submitLog( in )( ){
    authenticate@Auth( in.authorization )( user )
    if( user.agent_id == void ) {
      throw( UnAuthorized, "Not an agent id" )
    }
  } ]{
    println@Console( in.log )()

    with( parseReq ){
      .agent = user.agent
      .timestamp = in.timestamp
      .logtype = in.logtype
      .log = in.log
    }

    // forward TODO figure out where
    parseLog@Parser( parseReq )( parsedLog )


    if( parsedLog.discard != true ) {
      if( parsedLog.tag == void ) {
        parsedLog.tag = ""
      }

      with( log ){
        .agent = user.agent
        .timestamp = in.timestamp
        .content = parsedLog.content
        .logtype = in.logtype
        .tag = parsedLog.tag
      }
    }
  }
}
