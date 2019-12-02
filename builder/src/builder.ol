include "exec.iol"
include "file.iol"
include "console.iol"
include "string_utils.iol"

include "builder.iol"

execution{ concurrent }

inputPort builderService {
  Location: "socket://localhost:8005"
  Protocol: sodep
  Interfaces: BuildService
}

define exec
{
  command.stdOutConsoleEnable = true
  println@Console( "executing command: " + command )()
  exec@Exec( command )( result )
  println@Console( result.stderr )()
}

main
{
  build( info )

  writeFile@File( { .filename = "parsercode.temp", .content = info.code} )()

  trim@StringUtils( info.name )( tag )
  toLowerCase@StringUtils( tag )( tag )
  tag.regex = "[^a-z0-9.]"
  tag.replacement = "_"
  replaceAll@StringUtils( tag )( tag )

  if( info.type == "jolie" ) {
    command = "docker build -f Dockerfile.jolie -t parsers:" + tag + " ."
    exec
    command = "docker tag parsers:" + tag + " 591632264589.dkr.ecr.eu-central-1.amazonaws.com/parsers:" + tag
    exec
    command = "docker push 591632264589.dkr.ecr.eu-central-1.amazonaws.com/parsers:" + tag
    exec
  }else{
    throw( UnknownType, info.type + " is not a supported type" )
  }

  res = (result.exitCode == 0)
}
