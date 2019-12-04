include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "time.iol"

include "../../lib/auth/auth.iol"
include "../../lib/database/database.iol"
include "builder.iol"
include "submit_code_interface.iol"

embedded {
  Jolie:
    "../../lib/auth/auth.ol" in Auth,
}

inputPort http {
  Location: "socket://localhost:8001"
  Protocol: http
  Interfaces: SubmitCodeInterface
}

inputPort sodep {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: SubmitCodeInterface
}

execution{ concurrent }

define createNameIndex
{
  with( createIndex ){
    .database = "parsers";
    .collection = user.id;
    .unique = true;
    .key = "name"
  }

  createTextIndex@Database( createIndex )()
}

init
{
  connect@Database( "mongodb://mongo_db" )()
}

main
{
  [submitCode( in )( out ){
    {
      authenticate@Auth( in.authorization )( user ) |

      with( in.parser ){
        trim@StringUtils( .name )( .name )
        toLowerCase@StringUtils( .name )( .name )
        .name.regex = "[^a-z0-9.]"
        .name.replacement = "_"
        replaceAll@StringUtils( .name )( .name )
        if( .name == "" ) {
          throw( NoName, { .info = "Name cannot be empty" } )
        }
      }


      trim@StringUtils( in.parser.code )( in.parser.code );
      if( in.parser.code == "" ) {
        throw( InvalidCode, { .info = "Code cannot be empty" } )
      }

      trim@StringUtils( in.parser.type )( in.parser.type );
      if( in.parser.type == "" ) {
        throw( InvalidType, { .info = "Type cannot be empty" } )
      }

      if( in.parser.type != "jolie" ) {
        throw( InvalidType, { .info = "Type: " + in.parser.type + " is not a valid type." } )
      }
    }

    in.parser.status = "submitted";
    getJsonString@JsonUtils( in.parser )( jsonDoc );
    undef( in.parser.status )

    with( insertReq ){
      .database = "parsers";
      .collection = user.id;
      .document = jsonDoc
    }
    createNameIndex
    insert@Database( insertReq )( out.success )
  }]{
    build@Builder( {.name = in.parser.name, .owner = user.id} )
  }

  [retrieveCode( in )( out ){
    authenticate@Auth( in.authorization )( user );

    with( pageReq ){
      .database = "parsers";
      .collection = user.id;
      if( in.offset != void ) {
        .offset = in.offset
      }else{
        .offset = 0
      }

      if( in.limit != void ) {
        .limit = in.limit
      }else{
        .limit = 100
      }
    }

    find@Database( pageReq )( pageDetails );

    out.count = pageDetails.count;
    out.offset = pageReq.offset
    out.limit = pageReq.limit
    getJsonValue@JsonUtils( pageDetails.documents )( out.parsers )
  }]

  [deleteCode( in )( out ){
    authenticate@Auth( in.authorization )( user );

    with( deleteReq ){
      .database = "parsers";
      .collection = user.id;
      .key = "name";
      .value = in.name
    }

    delete@Database( deleteReq )( out.success )
  }]
}
