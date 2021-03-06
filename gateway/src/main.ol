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
    gateway
}

outputPort LogStore {
  Protocol: http {
    .contentType = "application/json";
    .format = "json";
    .method = "post"
  }
  Interfaces: LogStoreInterface
}

interface AlarmServiceInterface {
  RequestResponse:
    alarms
  OneWay:
}

outputPort AlarmService {
  Protocol: http {
    .contentType = "application/json";
    .format = "json";
    .method = "post"
  }
  Interfaces: AlarmServiceInterface
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

  getenv@Runtime( "ALARMSERVICE_HOST" )( ALARMSERVICE_HOST )
  if( ALARMSERVICE_HOST == void ) {
    println@Console( "ALARMSERVICE_HOST env not set!" )()
    halt@Runtime( {.status = 1} )( )
  }

  AlarmService.location = "socket://" + ALARMSERVICE_HOST

  getenv@Runtime( "OWNER" )( OWNER )
  if( OWNER == void ) {
    println@Console( "OWNER env not set!" )()
    halt@Runtime( {.status = 1} )( )
  }

}

main
{
  [ submitLog( in )( ){
    authenticate@Auth( in.authorization )( user )

    if( user.id != OWNER) {
      throw( UnAuthorized, "This service does not allow access for " + user.id )
    }

    if( user.agent == void ) {
      throw( UnAuthorized, "Access token does not belong to an agent" )
    }
  } ]{
    with( parseReq ){
      .agent = user.agent;
      .timestamp = in.timestamp;
      .log = in.log
    };

    parseLog@Parser( parseReq )( parsedLog )

    log_id = new

    if( parsedLog.discard != true ) {
      with( logToStore.body ){
        .log_id = log_id;
        .customer_id = user.id;
        .agent_id = user.agent;
        .timestamp = in.timestamp;
        .log_type = parsedLog.logtype;
        .tags._ -> parsedLog.tag;
        .content = parsedLog.content;
        println@Console( "Storing log, id: " + .log_id )()
      };
      gateway@LogStore({ .method = "post", .request -> logToStore })( res )
    }

    if( is_defined( parsedLog.alert ) ) {
      with( alertToSend ){
        .name = parsedLog.alert.name;
        .severity = parsedLog.alert.severity;
        .log_id = log_id;
        .customer_id = user.id;
        println@Console( "Raising alart: " + .name )()
      };

      alarms@AlarmService( alertToSend )()
    }
  }


}
