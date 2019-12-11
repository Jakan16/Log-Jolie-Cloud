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
