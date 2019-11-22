type errorMsg: void {
  info: string
}

type SubmitCodeRequest: void {
  name: string
  code: string
  type: string
  authorization: string
}

type SubmitCodeResponse: void {
    success: bool
}

interface SubmitCodeInterface {
  RequestResponse:
    // Allows a client to submit to the log parse code base
    submitCode( SubmitCodeRequest ) ( SubmitCodeResponse )
      throws
        NoName( errorMsg )
        UnAuthorized( errorMsg )
        InvalidType( errorMsg )
        InvalidCode( errorMsg )
  OneWay:
}
