include "file.iol"
include "console.iol"
include "runtime.iol"

include "../src/builder.iol"

outputPort Builder {
Location: "socket://localhost:8000"
Protocol: sodep
Interfaces: BuildService
}

main
{

  readFile@File( { filename = "test/example_jolie_parser.ol"} )( buildInfo.code )

  with( buildInfo ){
    .type = "jolie"
    .name = "example_image"
  }

  build@Builder( buildInfo )

}
