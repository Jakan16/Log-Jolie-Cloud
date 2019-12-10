include "console.iol"
include "json_utils.iol"
include "runtime.iol"

include "parser_interface.iol"
include "../../lib/auth/auth.iol"

embedded {
  Jolie:
    "../../lib/auth/auth.ol" in Auth,
}

execution{ concurrent }

type Log: void {
  authorization: string
  log: string
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
  Protocol: sodep
  Interfaces: LogParserInterface
}

interface LogStoreInterface {
  RequestResponse:
    store
}

outputPort LogStore {
  Protocol: http {
    .osc.store.alias = "/gateway";
    .osc.store.method = "POST"
  }
  Interfaces: LogStoreInterface
}

init
{
  println@Console( "Starting gateway" )()
  getenv@Runtime( "PARSER_HOST" )( PARSER_HOST )
  if( PARSER_HOST == void ) {
    println@Console( "PARSER_HOST env not set!" )()
    halt@Runtime( {.status = 1} )( )
  }

  Parser.location = "socket://" + PARSER_HOST

  getenv@Runtime( "LOGSTORE_HOST" )( LOGSTORE_HOST )
  if( LOGSTORE_HOST == void ) {
    println@Console( "LOGSTORE_HOST env not set!" )()
    halt@Runtime( {.status = 1} )( )
  }

  LogStore.location = "socket://" + LOGSTORE_HOST

}

main
{
  [ submitLog( in )( ){
    authenticate@Auth( in.authorization )( user )
    if( user.agent == void ) {
      throw( UnAuthorized, "Access token does not belong to an agent" )
    }
  } ]{
    println@Console( in.log )()

    with( parseReq ){
      .agent = user.agent;
      .timestamp = in.timestamp;
      .log = in.log
    };

    println@Console( "Forwarding to parser" )()
    println@Console( Parser.location )()
    parseLog@Parser( parseReq )( parsedLog )
    println@Console( "Recieved response" )()
    if( parsedLog.discard != true ) {
      if( parsedLog.tag == void ) {
        parsedLog.tag = ""
      }

      with( log ){
        .logId = new
        .customerID = user.id
        .agentID = user.agent
        .timestamp = in.timestamp
        .logType = parsedLog.logtype
        .tags = parsedLog.tag
        .content = parsedLog.content
      }
        println@Console( "Storing log" )()
        store@LogStore({ .method = "post", .request = log })()
    }
  }


}
