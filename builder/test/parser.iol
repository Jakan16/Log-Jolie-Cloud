type logParseRequest: void {
  agent: string
  timestamp: long
  log: undefined
}

type logParseResponse: void {
  content: undefined
  logtype: string
  tag?: string
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
