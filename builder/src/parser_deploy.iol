
type DeployRequest: void {
  name: string
  gateWayReplicas: int
  parserReplicas: int
  gatewayImage: string
  parserImage: string
  cpuPerInstance: int
  mbMemPerInstance: int
  owner: string
}

type GatewayIpResponse: void {
  IPs*: string
}

interface ParserDeployInterface {
  RequestResponse:
    deployWithService( DeployRequest )( bool ),
    deleteDeployAndService( string )( bool ),
    getGatewayIp( string )( GatewayIpResponse )
}

outputPort ParserDeploy {
  Interfaces: ParserDeployInterface
}

embedded {
    Java: "pd.ParserDeploy" in ParserDeploy
}
