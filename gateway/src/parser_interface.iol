type logParseRequest: void {
  agent: string
  timestamp: long
  log: string
}

type logParseResponse: void {
  content: string
  logtype: string
  tag*: string
  discard?: bool
  alert?: void {
    name?: string
    severity?: string
  }
}

interface LogParserInterface {
  RequestResponse:
    parseLog( logParseRequest )( logParseResponse )
  OneWay:
}
