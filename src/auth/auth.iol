type errorMsg: void {
  info: string
}

type UserInfo: void {
  agent: void {
    id: string
  }
  owner: void {
    id: string
  }
}

interface AuthInterface {
  RequestResponse:
    authenticate( string )( UserInfo ) throws UnAuthorized( errorMsg )
}

outputPort Auth {
  Interfaces: AuthInterface
}

embedded {
  Jolie:
    "auth/auth.ol" in Auth
}
