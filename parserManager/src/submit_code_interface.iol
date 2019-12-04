type errorMsg: void {
  info: string
}

type SubmitCodeRequest: void {
  parser: void {
    name: string
    code: string
    type: string
  }
  authorization: string
}

type SubmitCodeResponse: void {
    success: bool
}

type RetrieveCodeRequest: void {
  authorization: string
  limit?: int
  offset?: int
}

type RetrieveCodeResponse: void {
  count: int
  offset: int
  limit: int
  parsers: undefined
}

type DeleteCodeRequest: void {
  authorization: string
  name: string
}

type DeleteCodeResponse: void {
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
        WriteException( undefined ),
    // Allows a client to retrieve from the log parse code base
    retrieveCode( RetrieveCodeRequest ) ( RetrieveCodeResponse )
      throws UnAuthorized( errorMsg ),
    // Allows a client to delete from the log parse code base
    deleteCode( DeleteCodeRequest ) ( DeleteCodeResponse )
      throws UnAuthorized( errorMsg )
  OneWay:
}
