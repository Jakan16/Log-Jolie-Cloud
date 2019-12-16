import io.kubernetes.client.ApiClient;
import io.kubernetes.client.ApiException;
import io.kubernetes.client.Configuration;
import io.kubernetes.client.apis.AppsV1Api;
import io.kubernetes.client.apis.CoreV1Api;
import io.kubernetes.client.custom.IntOrString;
import io.kubernetes.client.models.*;
import io.kubernetes.client.util.Config;
import jolie.runtime.FaultException;
import jolie.runtime.Value;

import javax.swing.text.html.parser.Parser;
import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

public class ParserDeploy {
    private AppsV1Api apiApps;

    private CoreV1Api apiCore;

    public static void main(String[] args) throws IOException, FaultException, InterruptedException {
        ParserDeploy parserDeploy = new ParserDeploy();

        parserDeploy.deleteDeployAndService( "kage" );
        parserDeploy.deployWithService( "kage", 2, 2, "porygom/parsergateway:develop", "porygom/example_parser:develop");
        Thread.sleep(15000);
        parserDeploy.getGatewayIp( "kage" );
    }

    public ParserDeploy() throws IOException {
        ApiClient client = Config.defaultClient();
        Configuration.setDefaultApiClient(client);

        apiApps = new AppsV1Api();
        apiCore = new CoreV1Api();
    }

    public boolean deployWithService(String name, int gateWayReplicas, int parserReplicas, String gatewayImage, String parserImage) throws FaultException {

/////////////////// gatewayService ////////////////////////////
        V1Service gatewayService =
                new V1ServiceBuilder()
                        .withNewMetadata()
                        .withName("parser-gateway-service-" + name)
                        .addToLabels("service", name + "-gateway")
                        .endMetadata()
                        .withNewSpec()
                        .addToSelector("app", name + "-gateway")
                        .withNewType("NodePort")
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

            return true;
        } catch (ApiException e) {
            e.printStackTrace();
            throw new FaultException("KubernetesFault", e);
        }
    }

    boolean deleteDeployAndService(String name) throws FaultException {
        try {

            apiCore.deleteNamespacedService("parser-gateway-service-" + name, "default", null, new V1DeleteOptions(), null, null, null, null);
            apiCore.deleteNamespacedService("parser-service-" + name, "default", null, new V1DeleteOptions(), null, null, null, null);

            apiApps.deleteNamespacedDeployment(name + "-gateway", "default", null, new V1DeleteOptions(), null, null, null, null);
            apiApps.deleteNamespacedDeployment(name + "-parser", "default", null, new V1DeleteOptions(), null, null, null, null);

            return true;
        } catch (ApiException e) {
            e.printStackTrace();
            throw new FaultException("KubernetesFault", e);
        }
    }

    Value getGatewayIp( String name ) throws FaultException {
        try {

            V1ServiceList listNamespacedService = apiCore.listNamespacedService( "default", false, null, null,  null, "service=" + name + "-gateway", 1, null, null, false);

            Value response = Value.create();
            Value IPs = response.getFirstChild("IPs");

            System.out.println( "Printing ips" );

            for (V1Service service: listNamespacedService.getItems()){

                Integer port = null;
                for (V1ServicePort servicePort: service.getSpec().getPorts()){
                    if (servicePort.getName().equals("parser-gateway-port")){
                        port = servicePort.getNodePort();
                        break;
                    }
                }

                if (port != null) {
                    for (String IPString : service.getSpec().getExternalIPs()) {
                        IPs.add(Value.create(IPString + ":" + port));
                        System.out.println(IPString + ":" + port);
                    }

                    for (String IPString : service.getSpec().getExternalIPs()) {
                        IPs.add(Value.create(IPString + ":" + port));
                        System.out.println(IPString + ":" + port);
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