# Kubernetes with some tools to better vision of your application.

## For now, using Istio, Prometheus, Grafana, Zipkin, dotviz and WeaveScope.


#### Step-by-Step

First of all, you'll need an running kubernetes cluster, an easy way is using kops on aws and in minutes you have a running cluster:

## Install some tools to use Kubernetes on aws

### Install Kubectl

How-to Install [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Install kops
`$ wget https://github.com/kubernetes/kops/releases/download/1.7.1/kops-linux-amd64 `

`$ chmod +x kops-linux-amd64 `

`$ mv kops-linux-amd64 /usr/local/bin/kops `

### Install aws CLI

`$ pip install awscli --upgrade --user `

### Prepare your Cluster

`$ aws configure` - configure your credentials to access aws

`$ export S3_BUCKET=SomeGoodName` - The name of a bucket to store your cluster config files

`$ export REGION=us-west-1` - The name of aws region where your cluster will be created

`$ export NAME=GoodNameForYourCluster` - Your Cluster Name

`$ export KOPS_STATE_STORE=s3://$S3_BUCKET` - s3 storage name

`$ aws s3api create-bucket --bucket $S3_BUCKET --acl private --create-bucket-configuration LocationConstraint=$REGION` - Create s3 bucket

`$ kops create cluster --zones us-west-1b --name $NAME` - Create files to create the k8s cluster
##### Now you can change the size and others details of your cluster.


### Apply/Create your Cluster
`$ kops update cluster $NAME --yes`

##
### Now access you cluster, and let's get ready to rumble !
##

### Install Istio CLI

`$ curl -L http://assets.joinscrapbook.com/istio/getLatestIstio | sh - `

Remember to export it to your PATH

### Deploy Istio on k8s

#### Insert IMAGE of Istio Infra


`$ kubectl apply -f istio.yaml`


### Deploy Prometheus
`$ kubectl apply -f prometheus.yaml`

### Deploy Grafana
`$ kubectl apply -f grafana.yaml`

### Deploy ServiceGraph
`$ kubectl apply -f servicegraph.yaml`

### Deploy Zipkin
`$ kubectl apply -f zipkin.yaml`


### Check all running pods
`$ kubectl get pods -n istio-system`

##

#### Now with all components running, let's deploy a sample application


`$ kubectl apply -f <(istioctl kube-inject -f istio/bookinfo/bookinfo.yaml)`

###### You can get the source <i>[here](https://github.com/istio/istio/tree/release-0.1/samples/apps/bookinfo)</i>

##### This will create the application and his LoadBalancer, now access the application

`$ kubectl describe ingress`
###### This show the address to access the application



### Now you gave the weel of your application for <b>istio</b> and this is a good thing, it main feature is <i>traffic management</i>, and now its is avaiable to you.

#### Let's make some tests
* In the app we have user "jason" and we can redirect his traffic to other version, and for this we use <i>istio routes</i> with this file:

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-test-v2
spec:
  destination:
    name: reviews
  precedence: 2
  match:
    request:
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
  route:
  - labels:
      version: v2
```
`$ istioctl create -f route-rule-jason.yaml`
##### The difference in this version is the black ratting starts. 

* The ability to split traffic to A/B site for canary release can be done in <i>istio</i> to, so let's try it.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  precedence: 1
  route:
  - labels:
      version: v1
    weight: 50
  - labels:
      version: v3
    weight: 50
```
`$ istioctl create -f route-rule-50-50.yaml`
 ##### Note that this is not round robin, so multiple requests could go to the same version.
 
 * User the same endpoint to point another release. In istio you can change all the traffic to new version, like this :

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  precedence: 1
  route:
  - labels:
      version: v3
    weight: 100
```
`$ istioctl replace -f route-rule-reviews-v3.yaml`

##### Note that this rule "reviews-default" is just updated now

#### List all istio route rules

`$ istioctl get routerules`


.... still writing...



##WEAVE##
kubectl apply --namespace istio-system -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl port-forward -n istio-system "$(kubectl get -n istio-system pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040


pod=$(kubectl get pod --selector=name=weave-scope-app -o jsonpath={.items..metadata.name} -n istio-system)

kubectl expose pod $pod --external-ip="172.17.0.70" --port=4040 --target-port=4040 --type=LoadBalancer -n istio-system