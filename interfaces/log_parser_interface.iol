
type logParseRequest: void {
  agent: string
  timestamp: long
  log: any
}

type logParseResponse: void {
  content: any
  logtype: string
  tag?: string
}


interface LogParseInterface {
  RequestResponse:
    parseLog( logParseRequest )( logParseResponse )
  OneWay:
}
