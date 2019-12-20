include "auth_interface.iol"
include "time.iol"
include "runtime.iol"
include "console.iol"

execution{ concurrent }

inputPort embedSocket {
  Location: "local"
  Protocol: sodep
  Interfaces: AuthInterface
}

type authReq: void {
  method: string
  token: string
}

type authRes: void {
  companypublic: string
  agentname?: string | void
}

interface AuthenticatorInterface {
  RequestResponse:
    authenticate
  OneWay:
}

outputPort Authenticator {
  Protocol: http {
    .debug = true;
    .debug.showContent = true;
    .osc.authenticate.alias = "auth";
    .osc.authenticate.method = "POST"
    .format = "json";
    .contentType = "application/json";
    .method = "POST"
  }
  Interfaces: AuthenticatorInterface
}

init
{
  getenv@Runtime( "AUTHENTICATOR_HOST" )( AUTHENTICATOR_HOST )
  Authenticator.location = "socket://" + AUTHENTICATOR_HOST
}

main
{
  //token = "eyJhbGciOiJBMjU2S1ciLCJlbmMiOiJBMjU2Q0JDLUhTNTEyIn0.l4vyO8hJ02_U3r0SQZbc8HIJYfghPbxM2dkSDEU8GZMyvyugvCi35jQPHjGoiBXvr2UaR9BKvaYcbYkKuK-pT0PX-XQ7C73y.qdR1wXjBRWdKbmyYQ1p0UQ.CFFQIIoEGai1stm4VWoZo6VbfQ2T0lgXXNhbjjrz5QSLC7MkdPBdJ8BhRB4OH3-jAEIHA-CTva_7ZuufJtbM5UoorPKwl-AcLEN1q4hFGlTuHGAQybza7BRF6iTySzT1DvMSTdS2KzOQbKwAQxJwbHkNIDN5DO1xonJEW7hdDOtoy1hftmM1RNL9-QWdQvCFBxQm1EwZf29uT6utqMckNpk8BBb_f3djr0NRqCtyzik.HvB1aPiALSniCYCnjApkxYx-OIoyPTdEPAD8WAfkn4E"
  //authenticate( token )( global.cached.( token ).user ){
  authenticate( token )( user ){
    println@Console( "verifying" )()
    authenticate@Authenticator( { method = "verify", token = token} )( res )

    println@Console( "verified" )()
    user.id = res.companypublic
    if( res.agentname != void ) {
      user.agent = res.agentname
  }

    /*synchronized( authSync ){
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
          } else if ( token == "valid_agent_token" ) {
            .user.id = "sdighsodgs"
            .user.name = "The cool company"
            .user.agent = "nijsdnisagent"
            .invalid = false
          }else{
            .invalid = true
            throw( UnAuthorized, { .info = "Token could not be authorized" } )
          }
        }else if ( .invalid ) {
          throw( UnAuthorized, { .info = "Token cached as invalid" } )
        }
      }
    }*/
  }
}
