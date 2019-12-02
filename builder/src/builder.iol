type BuildRequest: void {
  name: string
  code: string
  type: string
}

interface BuildService {
  RequestResponse:
  OneWay:
    build( BuildRequest )
}
