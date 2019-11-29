include "console.iol"
include "json_utils.iol"

execution{ concurrent }

interface GatewayInterface {
  RequestResponse:
    storeLog( undefined )( void )
  OneWay:
}

inputPort Gateway {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: GatewayInterface
}

main
{
  [ storeLog( log )(){
    getJsonString@JsonUtils( log )( json )
    println@Console( json )()
  } ]
}
