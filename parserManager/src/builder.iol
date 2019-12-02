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

outputPort Builder {
  Location: "socket://builder:8005"
  Protocol: sodep
  Interfaces: BuildService
}
