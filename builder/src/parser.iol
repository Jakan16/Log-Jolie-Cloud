type logParseRequest: void {
  agent: string
  timestamp: long
  log: string
  logtype: string
}

type logParseResponse: void {
  content: undefined
  logtype: string
  tag?: string
  discard?: bool
}

interface LogParserInterface {
  RequestResponse:
    parseLog( logParseRequest )( logParseResponse )
  OneWay:
}

inputPort Parser {
  Location: "socket://localhost:27521"
  Protocol: sodep
  Interfaces: LogParserInterface
}
