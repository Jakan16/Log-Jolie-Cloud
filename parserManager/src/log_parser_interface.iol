
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


interface LogParseInterface {
  RequestResponse:
    parseLog( logParseRequest )( logParseResponse )
  OneWay:
}
