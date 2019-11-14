/*
* An adapter interface that allows external access using the http protocol.
*/

include "../interfaces/submit_code_interface.iol"

interface adapterInterface {
  RequestResponse:
    stopAdapter(any)(void)
}

outputPort target {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: SubmitCodeInterface
}

inputPort in {
  Location: "socket://localhost:8001"
  Protocol: http {.format = "json"}
  Interfaces: adapterInterface
  Aggregates: target
}

main
{
  // need something so the program does not exit immediatly
  // Calling this function closes the adapter
  stopAdapter()()
}
