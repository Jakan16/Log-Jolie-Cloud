include "exec.iol"
include "file.iol"
include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "runtime.iol"

include "builder.iol"
include "../../lib/database/database.iol"
include "parser_deploy.iol"

execution{ concurrent }

inputPort builderService {
  Location: "socket://localhost:8005"
  Protocol: sodep
  Interfaces: BuildService, ParserDeployInterface
  Aggregates: ParserDeploy
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
   [ build( info ) ] {
     tag = info.name

     with( fetchReq ){
       .database = "parsers";
       .collection = info.owner;
       .key = "name";
       .value = tag
     }
     updateReq -> fetchReq

     getByValue@Database( fetchReq )( json )
     getJsonValue@JsonUtils( json )( doc )

     writeFile@File( { .filename = "parsercode.temp", .content = doc.code} )()


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
           gateWayReplicas = 2,
           parserReplicas = 2,
           gatewayImage = "porygom/parsergateway:develop",
           //parserImage = "porygom/example_parser:develop"
           parserImage = repoImageName
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
}
