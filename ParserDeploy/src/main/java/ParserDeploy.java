import io.kubernetes.client.ApiClient;
import io.kubernetes.client.ApiException;
import io.kubernetes.client.Configuration;
import io.kubernetes.client.apis.AppsV1Api;
import io.kubernetes.client.apis.CoreV1Api;
import io.kubernetes.client.custom.IntOrString;
import io.kubernetes.client.models.*;
import io.kubernetes.client.util.Config;
import io.kubernetes.client.util.Yaml;

import java.io.IOException;

public class ParserDeploy {

    public static void main(String[] args) {

        try {
            ApiClient client = Config.defaultClient();
            Configuration.setDefaultApiClient(client);
        } catch (IOException e) {
            e.printStackTrace();
        }

        String name = "bsfbns";

        V1Service svc =
                new V1ServiceBuilder()
                        .withNewMetadata()
                        .withName("parser-service-" + name)
                        .endMetadata()
                        .withNewSpec()
                        .addToSelector("app", name + "-gateway")
                        .withNewType("NodePort")
                        .withType("NodePort")
                        .addNewPort()
                        .withProtocol("TCP")
                        .withName("client")
                        .withPort(7999)
                        .withNodePort(30005)
                        .withTargetPort(new IntOrString(7999))
                        .endPort()
                        .endSpec()
                        .build();
        System.out.println(Yaml.dump(svc));

        V1PodTemplateSpec gateway = new V1PodTemplateSpecBuilder()
                .withNewMetadata()
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(
                        new V1PodSpecBuilder().addNewContainer().withName(name + "-gateway").withImage("porygom/parsergateway:develop").addNewPort().withContainerPort(7999).endPort().and().build()
                ).build();

        V1DeploymentSpec gatewaySpec = new V1DeploymentSpecBuilder()
                .withReplicas(2)
                .withNewSelector()
                .addToMatchLabels("app", name + "-gateway")
                .endSelector()
                .withTemplate(gateway)
                .build();

        V1Deployment deployment = new V1DeploymentBuilder()
                .withNewMetadata()
                .withName(name + "-gateway")
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(gatewaySpec)
                .build();

        System.out.println(Yaml.dump(deployment));

        AppsV1Api apiApps = new AppsV1Api();

        CoreV1Api apiCore = new CoreV1Api();


        try {
            //apiCore.createNamespacedService("default", svc, null, null, null);
            apiApps.deleteNamespacedDeployment(name + "-gateway", "default", null, new V1DeleteOptions(), null, null, null, null);
            //apiApps.createNamespacedDeployment("default", deployment, null, null, null);
        } catch (ApiException e) {
            e.printStackTrace();
            System.out.println(e.getResponseBody());
        }


        /*V1PodTemplateSpec parser = new V1PodTemplateSpecBuilder()
                .withNewMetadata()
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(
                        new V1PodSpecBuilder().addNewContainer().withName(name + "-gateway").withImage("porygom/parsergateway").addNewPort().withContainerPort(7999).endPort().and().build()
                ).build();

        V1DeploymentSpec parserSpec = new V1DeploymentSpecBuilder()
                .withReplicas(2)
                .withNewSelector()
                .addToMatchLabels("app", name + "-gateway")
                .endSelector()
                .withTemplate(gateway)
                .build();

        V1Deployment parserDeployment = new V1DeploymentBuilder()
                .withNewMetadata()
                .withName(name + "-gateway")
                .addToLabels("app", name + "-gateway")
                .endMetadata()
                .withSpec(gatewaySpec)
                .build();

        System.out.println(Yaml.dump(deployment));


        V1Service svc =
                new V1ServiceBuilder()
                        .withNewMetadata()
                        .withName("aservice")
                        .endMetadata()
                        .withNewSpec()
                        .withSessionAffinity("ClientIP")
                        .withType("NodePort")
                        .addNewPort()
                        .withProtocol("TCP")
                        .withName("client")
                        .withPort(8008)
                        .withNodePort(8080)
                        .withTargetPort(new IntOrString(8080))
                        .endPort()
                        .endSpec()
                        .build();*/
        //System.out.println(Yaml.dump(svc));
    }

    public void connect(){
        /*try {
            ApiClient client = Config.defaultClient();
            Configuration.setDefaultApiClient(client);
        } catch (IOException e) {
            e.printStackTrace();
        }*/
    }

}
