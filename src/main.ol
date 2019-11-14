include "console.iol"
include "string_utils.iol"
include "../interfaces/submit_code_interface.iol"

inputPort in {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: SubmitCodeInterface
}

execution{ concurrent }

main
{
  submitCode( in )( out ){
    trim@StringUtils( in.name )( trimmed_name )
    if( trimmed_name == "" ) {
      throw( NoName, { .info = "Name cannot be empty" } )
    }

    trim@StringUtils( in.code )( trimmed_code )
    if( trimmed_code == "" ) {
      throw( InvalidCode, { .info = "Code cannot be empty" } )
    }

    trim@StringUtils( in.type )( trimmed_type )
    if( trimmed_type == "" ) {
      throw( InvalidType, { .info = "Type cannot be empty" } )
    }

    if( trimmed_type != "jolie" ) {
      throw( InvalidType, { .info = "Type: " + trimmed_type + " is not a valid type." } )
    }

    out.success = true
  }
}
