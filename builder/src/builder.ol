include "exec.iol"
include "file.iol"
include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "runtime.iol"
include "converter.iol"

include "builder.iol"
include "../../lib/database/database.iol"
include "parser_deploy.iol"
include "../../lib/auth/auth.iol"

embedded {
  Jolie:
    "../../lib/auth/auth.ol" in Auth,
}

execution{ concurrent }

inputPort builderService {
  Location: "socket://localhost:8005"
  Protocol: sodep
  Interfaces: BuildService
}

type GetHostType: void {
  parser_name: string
  token: string
}

interface ParserHostInterface {
  RequestResponse:
    getParserHost( GetHostType )( GatewayIpResponse )
  OneWay:
}
 
inputPort parserService {
  Location: "socket://localhost:8006"
  Protocol: http
  Interfaces: ParserHostInterface
}

define exec
{
  command.stdOutConsoleEnable = true
  println@Console( "executing command: " + command )()
  exec@Exec( command )( result )

  if( result.exitCode != 0 ) {
    throw( ExecutionFault, { .command = command, .result = result} )
  }
}

define updateStatus
{
  updateReq.document = "{\"status\":\"" + status + "\"}"
  update@Database(updateReq)()
}

init
{
  getenv@Runtime( "MONGODB_HOST" )( mongo_host )
  connect@Database( mongo_host )()

  getenv@Runtime( "PARSER_REPO" )( PARSER_REPO )
}

main
{
  [ getParserHost( request )( response ) {
    authenticate@Auth( request.token )( user )

    toLowerCase@StringUtils( user.id )( ownerdns )
    ownerdns.regex = "[^a-z0-9.]"
    ownerdns.replacement = "-"
    replaceAll@StringUtils( ownerdns )( ownerdns )

    tag = request.parser_name + "-" + ownerdns + "a"

    getGatewayIp@ParserDeploy( tag )( response )
    if( !is_defined( response.IPs ) ) {
      // Ensures IPs is always present, even if the array is empty
      getJsonValue@JsonUtils( "{\"IPs\":[]}" )( response )
    }
  } ]

   [ build( info ) ] {

     println@Console( "Building" )()

     toLowerCase@StringUtils( info.owner )( ownerdns )
     ownerdns.regex = "[^a-z0-9.]"
     ownerdns.replacement = "-"
     replaceAll@StringUtils( ownerdns )( ownerdns )

     tag = info.name + "-" + ownerdns + "a"

     println@Console( "tag: " + tag )()

     with( fetchReq ){
       .database = "parsers";
       .collection = info.owner;
       .key = "name";
       .value = info.name
     }
     updateReq -> fetchReq

     getByValue@Database( fetchReq )( json )
     getJsonValue@JsonUtils( json )( doc )

     base64ToRaw@Converter( doc.code )( rawCode )
     rawToString@Converter( rawCode )( code )

     writeFile@File( { .filename = "parsercode.temp", .content = code} )()

     install( ExecutionFault =>
       {
         status = "failed"; updateStatus
         throw( ExecutionFault )
       } )

     install( UnknownType =>
       {
         updateReq.document = "{\"status\":\"failed\"}"
         update@Database( updateReq )()
         throw( UnknownType, doc.type + " is not a supported type" )
       } )

     repoImageName = PARSER_REPO + ":" + tag

     if( doc.type == "jolie" ) {
       status = "building"; updateStatus
       command = "docker build -f builder/Dockerfile.jolie -t parsers:" + tag + " ."
       exec
       status = "pushing"; updateStatus
       command = "docker tag parsers:" + tag + " " + repoImageName
       exec
       command = "docker push " + repoImageName
       exec
       status = "build"; updateStatus

       println@Console( "deploying " + tag )()
       deployWithService@ParserDeploy( {
           name = tag,
           owner = info.owner,
           gateWayReplicas = 2,
           parserReplicas = 2,
           gatewayImage = "porygom/parsergateway:develop",
           //parserImage = "porygom/example_parser:develop"
           parserImage = repoImageName,
           cpuPerInstance = 1000,
           mbMemPerInstance = 300
         } )( success )

      if( success ) {
        println@Console( "deployment " + tag + " launched")()
      }else {
        println@Console( "deployment " + tag + " failed")()
      }

     }else{
       throw( UnknownType, doc.type + " is not supported" )
     }
  }

  [ destroy( info ) ] {
    toLowerCase@StringUtils( info.owner )( ownerdns )
    ownerdns.regex = "[^a-z0-9.]"
    ownerdns.replacement = "-"
    replaceAll@StringUtils( ownerdns )( ownerdns )

    tag = info.name + "-" + ownerdns + "a"
    deleteDeployAndService@ParserDeploy( tag )( result )
  }
}
