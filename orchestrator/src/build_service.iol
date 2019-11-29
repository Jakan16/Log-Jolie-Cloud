type BuildRequest: void {
  code: string
  type: string
  name: string
}

type BuildResponse: void {
  success: bool
}

interface BuildService {
  RequestResponse:
    build( BuildRequest )( BuildResponse )
  OneWay:
}
