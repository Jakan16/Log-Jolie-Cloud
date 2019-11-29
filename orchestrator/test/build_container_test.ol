
include "../src/build_service.iol"

outputPort Orchestrator {
  Interfaces: BuildService
}

embedded {
  Jolie: "../src/main.ol" in Orchestrator
}

main
{

  with( buildInfo ){
    .type = "jolie"
    .code = "bad code"
    .name = "example_image"
  }

  build@Orchestrator( buildInfo )( res )
}
