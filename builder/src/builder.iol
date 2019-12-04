type BuildRequest: void {
  name: string
  owner: string
}

interface BuildService {
  RequestResponse:
  OneWay:
    build( BuildRequest )
}
