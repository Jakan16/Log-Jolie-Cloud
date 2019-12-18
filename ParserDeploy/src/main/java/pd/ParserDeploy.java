package pd;

import io.kubernetes.client.ApiClient;
import io.kubernetes.client.ApiException;
import io.kubernetes.client.Configuration;
import io.kubernetes.client.apis.AppsV1Api;
import io.kubernetes.client.apis.CoreV1Api;
import io.kubernetes.client.custom.IntOrString;
import io.kubernetes.client.models.*;
import io.kubernetes.client.util.Config;
import io.kubernetes.client.util.Yaml;
import jolie.runtime.FaultException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;

import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

public class ParserDeploy extends JavaService {
    private AppsV1Api apiApps;

    private CoreV1Api apiCore;

    public static void main(String[] args) throws IOException, FaultException, InterruptedException {
        Value v = Value.create();
        v.getFirstChild( "name" ).setValue( "kage" );
        v.getFirstChild( "gateWayReplicas" ).setValue(1);
        v.getFirstChild( "parserReplicas" ).setValue(1);
        v.getFirstChild( "gatewayImage" ).setValue( "porygom/parsergateway:develop" );
        v.getFirstChild( "parserImage" ).setValue( "porygom/example_parser:develop" );

        ParserDeploy parserDeploy = new ParserDeploy();
        //parserDeploy.deployWithService(v);
        parserDeploy.deleteDeployAndService( "kage" );
        //Thread.sleep(10);
        parserDeploy.getGatewayIp( "kage" );
    }

    public ParserDeploy() throws IOException {
        ApiClient client = Config.defaultClient();
        Configuration.setDefaultApiClient(client);

        apiApps = new AppsV1Api();
        apiCore = new CoreV1Api();
    }

    public Value deployWithService( Value req ) throws FaultException {

        String name = req.getFirstChild( "name" ).strValue();
        int gateWayReplicas = req.getFirstChild( "gateWayReplicas" ).intValue();
        int parserReplicas = req.getFirstChild( "parserReplicas" ).intValue();
        String gatewayImage = req.getFirstChild( "gatewayImage" ).strValue();
        String parserImage = req.getFirstChild( "parserImage" ).strValue();

/////////////////// gatewayService ////////////////////////////
        V1Service gatewayService =
                new V1ServiceBuilder()
                        .withNewMetadata()
                        .withName("parser-gateway-service-" + name)
                        .addToLabels("service", name + "-gateway")
                        .endMetadata()
                        .withNewSpec()
                        .addToSelector("app", name + "-gateway")
                        .withNewType("LoadBalancer")
                        .addNewPort()
                        .withProtocol("TCP")
                        .withName("parser-gateway-port")
                        .withPort(7999)
                        .withTargetPort(new IntOrString(7999))
                        .endPort()
                        .endSpec()
                        .build();

/////////////////// gatewayDeployment ////////////////////////////
        List<V1EnvVar> gatewayEnvironment = new LinkedList<>();

        gatewayEnvironment.add(
                new V1EnvVarBuilder()
                        .withName( "PARSER_HOST" )
                        .withValue( "parser-service-" + name + ":27521" )
                        .build());

        gatewayEnvironment.add(
                new V1EnvVarBuilder()
                        .withName( "LOGSTORE_HOST" )
                        .withValue( "logstore:8080" )
                        .build());

        gatewayEnvironment.add(
                new V1EnvVarBuilder()
                        .withName( "ALARMSERVICE_HOST" )
                        .withValue( "alarmservice:8005" )
                        .build());

        V1PodTemplateSpec gatewayTemplate = new V1PodTemplateSpecBuilder()
                .withNewMetadata()
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(
                        new V1PodSpecBuilder()
                                .addNewContainer()
                                .withName(name + "-gateway")
                                .withImage( gatewayImage )
                                .addNewPort()
                                .withContainerPort(7999)
                                .endPort()
                                .withEnv( gatewayEnvironment )
                                .and().build()
                ).build();

        V1DeploymentSpec gatewaySpec = new V1DeploymentSpecBuilder()
                .withReplicas(gateWayReplicas)
                .withNewSelector()
                .addToMatchLabels("app", name + "-gateway")
                .endSelector()
                .withTemplate( gatewayTemplate )
                .build();

        V1Deployment gatewayDeployment = new V1DeploymentBuilder()
                .withNewMetadata()
                .withName(name + "-gateway")
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(gatewaySpec)
                .build();

/////////////////// parserService ////////////////////////////

        V1Service parserService =
                new V1ServiceBuilder()
                        .withNewMetadata()
                        .withName("parser-service-" + name)
                        .endMetadata()
                        .withNewSpec()
                        .addToSelector("app", name + "-parser")
                        .addNewPort()
                        .withProtocol("TCP")
                        .withName("client")
                        .withPort(27521)
                        .withTargetPort(new IntOrString(27521))
                        .endPort()
                        .endSpec()
                        .build();

/////////////////// parserDeployment ////////////////////////////

        V1PodTemplateSpec parserTemplate = new V1PodTemplateSpecBuilder()
                .withNewMetadata()
                .addToLabels("app", name + "-parser")
                .endMetadata()
                .withSpec(
                        new V1PodSpecBuilder()
                                .addNewContainer()
                                .withName(name + "-parser")
                                .withImage( parserImage )
                                .addNewPort()
                                .withContainerPort( 27521 )
                                .endPort()
                                .and().build()
                ).build();

        V1DeploymentSpec parserSpec = new V1DeploymentSpecBuilder()
                .withReplicas(parserReplicas)
                .withNewSelector()
                .addToMatchLabels("app", name + "-parser")
                .endSelector()
                .withTemplate( parserTemplate )
                .build();

        V1Deployment parserDeployment = new V1DeploymentBuilder()
                .withNewMetadata()
                .withName(name + "-parser")
                .addToLabels("app", name + "-parser")
                .endMetadata()
                .withSpec(parserSpec)
                .build();

///////////////////////////////////////////////////////////////////
        AppsV1Api apiApps = new AppsV1Api();

        CoreV1Api apiCore = new CoreV1Api();

        try {
            apiCore.createNamespacedService("default", parserService, null, null, null);
            apiCore.createNamespacedService("default", gatewayService, null, null, null);

            apiApps.createNamespacedDeployment("default", parserDeployment, null, null, null);
            apiApps.createNamespacedDeployment("default", gatewayDeployment, null, null, null);

            return Value.create(true);
        } catch (ApiException e) {
            System.out.println( e.getResponseBody() );
            throw new FaultException("KubernetesFault", e);
        }
    }

    public Value deleteDeployAndService( String name ) throws FaultException {
        try {

            apiCore.deleteNamespacedService("parser-gateway-service-" + name, "default", null, new V1DeleteOptions(), null, null, null, null);
            apiCore.deleteNamespacedService("parser-service-" + name, "default", null, new V1DeleteOptions(), null, null, null, null);

            apiApps.deleteNamespacedDeployment(name + "-gateway", "default", null, new V1DeleteOptions(), null, null, null, null);
            apiApps.deleteNamespacedDeployment(name + "-parser", "default", null, new V1DeleteOptions(), null, null, null, null);

            return Value.create(true);
        } catch (ApiException e) {
            e.printStackTrace();
            throw new FaultException("KubernetesFault", e);
        }
    }

    public Value getGatewayIp( String name ) throws FaultException {
        try {

            V1ServiceList listNamespacedService = apiCore.listNamespacedService( "default", false, null, null,  null, "service=" + name + "-gateway", 1, null, null, false);

            Value response = Value.create();

            System.out.println( "Printing ips" );

            for (V1Service service: listNamespacedService.getItems()){

                Integer port = null;
                for (V1ServicePort servicePort: service.getSpec().getPorts()){
                    if (servicePort.getName().equals("parser-gateway-port")){
                        port = servicePort.getPort();
                        break;
                    }
                }

                if (port != null){
                    String host = service.getStatus().getLoadBalancer().getIngress().get(0).getHostname();

                    if (host != null){
                        response.getFirstChild("IPs").add(Value.create(host + ":" + port));
                        System.out.println(host + ":" + port);
                    }
                }

            }

            return response;
        } catch (ApiException e) {
            e.printStackTrace();
            throw new FaultException( "KubernetesFault", e );
        }
    }
}
