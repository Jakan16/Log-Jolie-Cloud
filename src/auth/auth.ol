include "auth.iol"
include "time.iol"

inputPort embedSocket {
  Location: "local"
  Protocol: sodep
  Interfaces: AuthInterface
}

execution{ concurrent }

main
{
  authenticate( token )( global.cached.( token ).user ){
    synchronized( authSync ){
      with( global.cached.( token ) ){
        getCurrentTimeMillis@Time( )( currentTime )
        if( !.defined || currentTime - .atTime > 30*60*1000) {
          //mock
          .defined = true
          getCurrentTimeMillis@Time( )( .atTime )
          if( token == "valid_token" ) {
            .user.id = "sdighsodgs"
            .user.name = "The cool company"
            .invalid = false
          }else{
            .invalid = true
            throw( UnAuthorized, { .info = "Token could not be authorized" } )
          }
        }else if ( .invalid ) {
          throw( UnAuthorized, { .info = "Token cached as invalid" } )
        }
      }
    }
  }
}
