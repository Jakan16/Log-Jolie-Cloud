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
      res.id = "sdighsodgs"
      res.name = "The cool company"
    }else{
      throw( UnAuthorized, { .info = "Token could not be authorized" } )
    }
  }
}
