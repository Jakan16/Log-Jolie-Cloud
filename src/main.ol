include "console.iol"
include "string_utils.iol"

include "auth/auth.iol"
include "../interfaces/submit_code_interface.iol"

inputPort in {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: SubmitCodeInterface
}

inputPort embedSocket {
  Location: "local"
  Protocol: sodep
  Interfaces: SubmitCodeInterface
}

execution{ concurrent }

main
{
  submitCode( in )( out ){

    authenticate@Auth( in.authorization )( user )

    trim@StringUtils( in.name )( in.name )
    if( in.name == "" ) {
      throw( NoName, { .info = "Name cannot be empty" } )
    }

    trim@StringUtils( in.code )( in.code )
    if( in.code == "" ) {
      throw( InvalidCode, { .info = "Code cannot be empty" } )
    }

    trim@StringUtils( in.type )( in.type )
    if( in.type == "" ) {
      throw( InvalidType, { .info = "Type cannot be empty" } )
    }

    if( in.type != "jolie" ) {
      throw( InvalidType, { .info = "Type: " + in.type + " is not a valid type." } )
    }

    out.success = true
  }
}
