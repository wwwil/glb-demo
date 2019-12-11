# glb-demo

This is a demo of a container-native multi-cluster global load balancer, with Cloud Armor polices, for Google Cloud Platform (GCP).

It is designed to accompany [this blog post]().

**This is a demo only.**
It should not be used 'as is' in production, or any other shared, long lived, environments.
It is just designed to quickly show off and test what a global load balancer can do.
Many of the configurations and procedures used are not secure or robust.

## Requirements

* The Google Cloud SDK (`gcloud` command)
* `kubectl` command
* `terraform` command, version `0.12.x`


## Step 00 - Auth

Ensure the `gcloud` command is up to date and logged in using the correct Google account and project.
Then generate credentials for Terraform.
This method will set Terraform to use your account.
This is generally bad practise and Terraform should be set to use a service account.

```
gcloud auth application-default login
```

Complete web login in browser, then set the `GOOGLE_CLOUD_KEYFILE_JSON` environment variable to point to the credentials file created.

```
export GOOGLE_CLOUD_KEYFILE_JSON="/Users/wil/.config/gcloud/application_default_credentials.json"
```

## Step 01 - Create the Clusters

Enter the `01-clusters/` directory and apply the Terraform files.

```
terraform apply
```

Ensure the plan looks correct and then enter `yes`.

## Step 02 - Deploy The Apps

Enter the `02-apps/` directory.

Get credentials for the first cluster and apply the manifests for `zone-printer` and `hello-app`.

```
gcloud container clusters get-credentials glb-demo-eu --region europe-west2
kubectl apply -f zone-printer.yaml
kubectl apply -f hello-app.yaml
```

Repeat this for the second cluster.

```
gcloud container clusters get-credentials glb-demo-us --region us-central1
kubectl apply -f zone-printer.yaml
kubectl apply -f hello-app.yaml
```

Ensure the Pods are running in both clusters.

```
kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
hello-app-858d49df47-88cd7      1/1     Running   0          21s
hello-app-858d49df47-gcnnz      1/1     Running   0          21s
hello-app-858d49df47-gcz4c      1/1     Running   0          21s
hello-app-858d49df47-gfgqr      1/1     Running   0          21s
hello-app-858d49df47-j64w2      1/1     Running   0          21s
hello-app-858d49df47-qrg69      1/1     Running   0          21s
hello-app-858d49df47-smrk6      1/1     Running   0          21s
hello-app-858d49df47-srt24      1/1     Running   0          21s
hello-app-858d49df47-xdp2w      1/1     Running   0          21s
zone-printer-7c9568c559-6klrj   1/1     Running   0          23s
zone-printer-7c9568c559-8mf4w   1/1     Running   0          23s
zone-printer-7c9568c559-8pw4p   1/1     Running   0          23s
zone-printer-7c9568c559-csbvk   1/1     Running   0          23s
zone-printer-7c9568c559-drktf   1/1     Running   0          23s
zone-printer-7c9568c559-fmzmq   1/1     Running   0          23s
zone-printer-7c9568c559-rxsth   1/1     Running   0          23s
zone-printer-7c9568c559-vp7dr   1/1     Running   0          23s
zone-printer-7c9568c559-zdpkk   1/1     Running   0          23s
zoneprinter-546c64f489-lm5vd    1/1     Running   0          21h
```

## Step 03 - Create the GLB

Enter the `03-glb/` directory.

For each cluster get the name of the network endpoint groups (NEGs) created for the Services deployed.
The names and zones of these NEGs is added as an annotation to the Service.
The NEG names need to be supplied to Terraform for use in the load balancer.
This is achieved here using the input variables, and a template `.tfvars` file.

```
gcloud container clusters get-credentials glb-demo-eu --region europe-west2
ZONE_PRINTER_NEG_EU=$(kubectl get service zone-printer -o json | jq '.metadata.annotations["cloud.google.com/neg-status"] | fromjson | .network_endpoint_groups["80"]')
HELLO_APP_NEG_EU=$(kubectl get service hello-app -o json | jq '.metadata.annotations["cloud.google.com/neg-status"] | fromjson | .network_endpoint_groups["80"]')
gcloud container clusters get-credentials glb-demo-us --region us-central1
ZONE_PRINTER_NEG_US=$(kubectl get service zone-printer -o json | jq '.metadata.annotations["cloud.google.com/neg-status"] | fromjson | .network_endpoint_groups["80"]')
HELLO_APP_NEG_US=$(kubectl get service hello-app -o json | jq '.metadata.annotations["cloud.google.com/neg-status"] | fromjson | .network_endpoint_groups["80"]')
cp terraform.tfvars.template terraform.tfvars
sed -i.bak "s|ZONE_PRINTER_NEG_EU|$ZONE_PRINTER_NEG_EU|g" terraform.tfvars
sed -i.bak "s|ZONE_PRINTER_NEG_US|$ZONE_PRINTER_NEG_US|g" terraform.tfvars
sed -i.bak "s|HELLO_APP_NEG_EU|$HELLO_APP_NEG_EU|g" terraform.tfvars
sed -i.bak "s|HELLO_APP_NEG_US|$HELLO_APP_NEG_US|g" terraform.tfvars
rm -f terraform.tfvars.bak
```

Now apply the Terraform files.

```
terraform apply
```

Ensure the plan looks correct and then enter `yes`.

## Step 04 - Test the GLB

Once Terraform has finished it will output the value of the global IP address it reserved.
Enter this IP into a browser and you should see the `zone-printer` app, which will show the GCP zone of the instance you are connected to.
If this does not work you may need to wait a bit longer while the load balancer configuration is propagated by Google's network.

The maximum rate for connections is set very low in the load balancer.
this should mean that by aggressively refreshing the connection to the IP in the browser you should see the zone you connect to changes.
This demonstrates the load balancing in effect.

The region should not change, and should always be the region closest to where you connect from.
To verify that the global load balancing is directing traffic correctly we can run `curl` from a remote machine in the other region.

Connect to the cluster in the region you are not currently being served from.
For example if you're in Europe connect to the US cluster.

```
gcloud container clusters get-credentials glb-demo-us --region us-central1
```

Or if you're in the US connect to the Europe cluster.

```
gcloud container clusters get-credentials glb-demo-us --region us-central1
```

Then run `curl` to the global IP address on one of the Nodes over an `ssh` connection.

```
ADDRESS=$(terraform output glb_demo_address)
INSTANCE=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')
ZONE=$(kubectl get nodes -o json | jq -r '.items[0].metadata.labels["failure-domain.beta.kubernetes.io/zone"]')
gcloud compute ssh $INSTANCE --zone $ZONE --command "curl $ADDRESS"
```

This should show one of the zones in the other region.
Repeatedly using curl should cause the zone to change.

The `zone-printer` is shown when visiting the global IP address directly as it is set as the default backend.
Because of the URL Map we can also connect to the `hello-web` app by appending `/hello-app` in the browser.
This should show the `Hello, world!` message.

## Apps

The apps deployed in this demo are [Zone Printer](https://github.com/GoogleCloudPlatform/k8s-multicluster-ingress/tree/master/examples/zone-printer) and [Hello App](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/master/hello-app).
