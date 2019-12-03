include "console.iol"
include "runtime.iol"
include "json_utils.iol"

include "../src/submit_code_interface.iol"

outputPort Cloud {
  Location: "socket://localhost:8001"
  Interfaces: SubmitCodeInterface
  Protocol: http
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
    error++
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
    error++
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
    error++
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

    error++
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
    error++
  }

  /////////////////////////////////////////////////////////////////////
  scope( SubmitCode )
  {
    with( req ){
      .parser.name = "my awesome code"
      .parser.code = "some code"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud( req )( res )

    if( res.success != true ) {
      error++
      println@Console( "Failed test, valid request not accepted" )()
    }

    with( req ){
      .parser.name = "my awesome code2"
      .parser.code = "some code2"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud( req )( res )

    if( res.success != true ) {
      error++
      println@Console( "Failed test, valid request not accepted" )()
    }

    with( req ){
      .parser.name = "my awesome code3"
      .parser.code = "some code3"
      .parser.type = "jolie"
      .authorization = "valid_token"
    }

    submitCode@Cloud( req )( res )

    if( res.success != true ) {
      error++
      println@Console( "Failed test, valid request not accepted" )()
    }
  }

//////////////////////////////////////////////////////////////////////
scope( CheckNumOfEntries )
{
  with( rreq ){
    .authorization = "valid_token"
    .limit = 1
    .offset = 0
  }
  retrieveCode@Cloud( rreq )( res )
  if( res.count != 3 ) {
    error++
    println@Console( "Failed test, expected 3 parsers, found " + res.count )()
  }

  if( #res.parsers != 1 ) {
    println@Console( "Failed test, expected 1 parser returned, got " + #res.parsers )()
    error++
  }
}

//////////////////////////////////////////////////////////////////////
scope( DeleteEntries )
{

  with( rdreq ){
    .authorization = "valid_token"
  }

  retrieveCode@Cloud( rdreq )( res )

  dreq.authorization = "valid_token"
  for ( parser in res.parsers._ ) {
    dreq.id = parser._id.("$oid")
    deleteCode@Cloud( dreq )( out )
  }

  retrieveCode@Cloud( rdreq )( res2 )

  if( #res2.parsers._ > 0 ) {
    println@Console( "Failed test, expected no parsers to be returned, got " + #res2.parsers._ )()
    error++
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
