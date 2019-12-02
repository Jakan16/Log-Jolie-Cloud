type errorMsg: void {
  info: string
}

type UserInfo: void {
  name: string
  id: string
}

interface AuthInterface {
  RequestResponse:
    authenticate( string )( UserInfo ) throws UnAuthorized( errorMsg )
}
