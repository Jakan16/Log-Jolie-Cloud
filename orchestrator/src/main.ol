include "exec.iol"
include "file.iol"
include "console.iol"

include "build_service.iol"

execution{ concurrent }

inputPort local {
  Location: "local"
  Interfaces: BuildService
}

main
{
  [ build( info )( res ){

    writeFile@File( { .filename = "parsercode.temp", .content = info.code} )()

    if( info.type == "jolie" ) {
      command = "docker build . -f Dockerfile.jolie -t parser/" + info.name + ":latest"
      command.stdOutConsoleEnable = true
      exec@Exec( command )( result )
      println@Console( result.stderr )()
    }

    res.success = (result.exitCode == 0)
  } ]
}
