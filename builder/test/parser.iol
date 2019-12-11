type logParseRequest: void {
  agent: string
  timestamp: long
  log: string
}

type logParseResponse: void {
  content: undefined
  logtype: string
  tag*: string
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

inputPort ParserHttp {
  Location: "socket://localhost:27522"
  Protocol: http
  Interfaces: LogParserInterface
}
