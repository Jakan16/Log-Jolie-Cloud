include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "time.iol"

include "auth/auth.iol"
include "database/database.iol"
include "submit_code_interface.iol"

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

init
{
  connect@Database()()
}

embedded {
  Jolie:
    "auth/auth.ol" in Auth
}

main
{
  submitCode( in )( out ){
    {
      authenticate@Auth( in.authorization )( user )
    }
    |
    {
      trim@StringUtils( in.parser.name )( in.parser.name )
      if( in.parser.name == "" ) {
        throw( NoName, { .info = "Name cannot be empty" } )
      }

      trim@StringUtils( in.parser.code )( in.parser.code )
      if( in.parser.code == "" ) {
        throw( InvalidCode, { .info = "Code cannot be empty" } )
      }

      trim@StringUtils( in.parser.type )( in.parser.type )
      if( in.parser.type == "" ) {
        throw( InvalidType, { .info = "Type cannot be empty" } )
      }

      if( in.parser.type != "jolie" ) {
        throw( InvalidType, { .info = "Type: " + in.parser.type + " is not a valid type." } )
      }

      getJsonString@JsonUtils( in.parser )( jsonDoc )
    }

    with( document ){
      .database = "parsers";
      .collection = user.id;
      .document = jsonDoc
    }

    insert@Database( document )( out.success )
  }
}
