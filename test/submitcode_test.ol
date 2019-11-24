include "console.iol"
include "runtime.iol"

include "../src/submit_code_interface.iol"

outputPort Cloud {
  Interfaces: SubmitCodeInterface
}

embedded {
  Jolie:
    "../src/main.ol" in Cloud
}

main
{
  error = 0

  install( TypeMismatch => halt@Runtime( {status = 2} )( ) )
  install( Timeout => halt@Runtime( {status = 3} )( ) )

  /////////////////////////////////////////////////////////////////////
  scope( NoNameTest )
  {
    install( NoName => nullProcess )

    with(req){
      .parser.name = " "
      .parser.code = "some code"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud(req)(res)

    println@Console( "Failed test, accepted empty name" )()
    error += 1
  }

  /////////////////////////////////////////////////////////////////////
  scope( NoCodeTest )
  {
    install( InvalidCode => nullProcess )

    with(req){
      .parser.name = "my awesome code"
      .parser.code = " \n"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud(req)(res)

    println@Console( "Failed test, accepted empty code" )()
    error += 1
  }

  /////////////////////////////////////////////////////////////////////
  scope( NoTypeTest )
  {
    install( InvalidType => nullProcess )

    with(req){
      .parser.name = "my awesome code"
      .parser.code = "some code"
      .parser.type = ""
      .authorization = "valid_token"
    }

    submitCode@Cloud(req)(res)

    println@Console( "Failed test, accepted empty code" )()
    error += 1
  }

  /////////////////////////////////////////////////////////////////////
  scope( InvalidTypeTest )
  {
    install( InvalidType => nullProcess )

    with(req){
      .parser.name = "my awesome code"
      .parser.code = "some code"
      .parser.type = "ThisTypeDoesNotExist!"
      .authorization = "valid_token"
    }

    submitCode@Cloud(req)(res)

    error += 1
    println@Console( "Failed test, accepted empty code" )()
  }

  /////////////////////////////////////////////////////////////////////
  scope( UnAuthorizationTest )
  {
    install( UnAuthorized => nullProcess )
    with(req){
      .parser.name = "my awesome code"
      .parser.code = "some code"
      .parser.type = "jolie"
      .authorization = "invalid_token"
    }

    submitCode@Cloud(req)(res)

    println@Console( "Failed test, invalid authorization accepted" )()
    error += 1
  }

  /////////////////////////////////////////////////////////////////////
  scope( IdealCase )
  {
    with(req){
      .parser.name = "my awesome code"
      .parser.code = "some code"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud(req)(res)

    if( res.success != true ) {
      error += 1
      println@Console( "Failed test, valid request not accepted" )()
    }
  }

//////////////////////////////////////////////////////////////////////
  if( error > 0 ) {
    println@Console( "Error: " + error + " test(s) failed" )()
    halt@Runtime( {status = 1} )( )
  }else{
    println@Console( "Success: all tests passed" )()
  }
}
