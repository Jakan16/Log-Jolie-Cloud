include "auth.iol"

inputPort embedSocket {
  Location: "local"
  Protocol: sodep
  Interfaces: AuthInterface
}

execution{ concurrent }

main
{
  authenticate( token )( res ){
    //mock
    if( token == "valid_token" ) {
      res.agent.id = "some_agent_id"
      res.owner.id = "some_owner_id"
    }else{
      throw( UnAuthorized, { .info = "Token could not be authorized" } )
    }
  }
}
