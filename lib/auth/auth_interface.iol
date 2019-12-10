type errorMsg: string | void {
  info?: string
}

type UserInfo: void {
  name: string
  id: string
  agent?: string
}

interface AuthInterface {
  RequestResponse:
    authenticate( string )( UserInfo ) throws UnAuthorized( errorMsg )
}
