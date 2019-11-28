include "console.iol"
include "runtime.iol"

include "../src/auth/auth.iol"

embedded {
  Jolie:
    "../src/auth/auth.ol" in Auth
}

main
{

  error = 0

  install( TypeMismatch => halt@Runtime( {status = 2} )( ) )

  scope( sendValidToken )
  {
    authenticate@Auth( "valid_token" )( user )
    if( user.id == "" ) {
      println@Console( "Recieved empty id!" )()
      error++
    }

    if( user.name == "" ) {
      println@Console( "Recieved empty name!" )()
      error++
    }

    for( i = 0, i < 10, i++ ) {
      authenticate@Auth( "valid_token" )( user2 )

      if( user.id != user2.id ) {
        println@Console( "User id changed!" )()
        error++
      }

      if( user.name != user2.name ) {
        println@Console( "User name changed! from: " + user.name + " to: " + user2.name )()
        error++
      }
    }
  }

  scope( sendInvalidToken )
  {
    token = "invalid_token"
    for ( c = 0, c < 3, c++ ) {
      install( UnAuthorized => {
        if( sendInvalidToken.UnAuthorized.info != "Token could not be authorized" ) {
          error++
          println@Console( "unexpected fault message" )()
        }
      } )
      authenticate@Auth( token )( user )

      for( i = 0, i < 10, i++ ) {
        install( UnAuthorized => {
          if( sendInvalidToken.UnAuthorized.info != "Token cached as invalid" ) {
            error++
            println@Console( "unexpected 2nd fault message" )()
          }
          } )
          authenticate@Auth( token )( user )
      }

      // modify token
      token += "_"
    }
  }

  if( error > 0 ) {
    println@Console( "Error: " + error + " test(s) failed" )()
    halt@Runtime( {status = 1} )( )
  }else{
    println@Console( "Success: all tests passed" )()
  }
}
