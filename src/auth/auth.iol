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

outputPort Auth {
  Interfaces: AuthInterface
}

embedded {
  Jolie:
    "auth/auth.ol" in Auth
}
