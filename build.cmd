setlocal
cd /d C:\gitroot\CafeWebApp
call dotnet restore
call dotnet publish -c Debug

REM to local registry
REM call docker build -t suwatch01/coffeewebapp C:\gitroot\CafeWebApp\CoffeeWebApp
REM call docker run --name coffeewebapp --rm -it -p 8080:80 suwatch01/coffeewebapp
REM curl http://127.0.0.1:8080/coffee -v

REM call docker build -t suwatch01/teawebapp C:\gitroot\CafeWebApp\TeaWebApp
REM call docker run --name teawebapp --rm -it -p 8080:80 suwatch01/teawebapp
REM curl http://127.0.0.1:8080/tea -v


REM publish to docker hub registry
REM docker login --username=suwatch01
REM docker push suwatch01/coffeewebapp:latest
REM docker push suwatch01/teawebapp:latest

REM check for current cluster
REM kubectl cluster-info

REM cleanup
REM kubectl delete namespace cafe-apps
REM kubectl delete namespace cafe-ingress
REM kubectl delete clusterrolebinding cafe-ingress
REM kubectl delete clusterrole cafe-ingress

REM add cafe-ingress namespace and add cafe-ingress serviceaccount to cafe-ingress namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\ns-and-sa.yaml

REM add default secret with a TLS certificate and a key for the default server to cafe-ingress namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\default-server-secret.yaml

REM add cafe-config configmap to cafe-ingress namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\cafe-config.yaml

REM add cafe-ingress clusterrole (roleDef) and add cafe-ingress clusterrolebinding (associate roleDef to cafe-ingress serviceaccount)
REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\rbac.yaml

REM deploy cafe-ingress deployment to cafe-ingress namespace
REM pods: 1 container with image: nginx/nginx-ingress:edge, container: cafe-ingress container, labels: app:cafe-ingress
REM replicaSets: replicas: 2, selector matchLabels app:cafe-ingress
REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\cafe-ingress-deployment.yaml

REM verify pod and container running
REM POD naming: <container>_<containerHash>_<instanceId>
REM Each POD has its own external accessible IP address
REM kubectl get pods --namespace=cafe-ingress -o=wide

REM 2 options to expose: NodePort or LoadBalancer
  REM add service of type nodeport to cafe-ingress namespace
  REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\nodeport.yaml
  REM kubectl get service --namespace=cafe-ingress -o wide
  REM CLUSTER-IP: for kubernetes internal communication with all containers
  REM find out nodeport endpoint 
  REM kubectl get endpoints -n=cafe-ingress -o wide
  REM - test from VM: curl https://10.0.0.94/tea -H "HOST: cafe.example.com" -v -k
  REM ENDPOINTS or POD IP: for external access (vnet address).  #endpoints = #replicas = #nodes

  REM add service of type loadbalancer to cafe-ingress namespace
  REM with selector app:cafe-ingress matching cafe-ingress container
  REM Auto-create Azure Public IP: https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/65dbb2c4-1f8d-436f-a431-6b4b27e6a13c/resourceGroups/MC_Kubernetes-RG_suwatch-k8s-02_eastus/providers/Microsoft.Network/publicIPAddresses/kubernetes-a81b56a93290111eaa229dee851ae3da/overview
  REM Add FE config (for Public IP) to existing 'kubernetes' LoadBalancer: https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/65dbb2c4-1f8d-436f-a431-6b4b27e6a13c/resourceGroups/MC_Kubernetes-RG_suwatch-k8s-02_eastus/providers/Microsoft.Network/loadBalancers/kubernetes/overview
  REM with 2 rules (80 and 443) to point to 'kubernetes' backend pool
  REM kubectl apply -f C:\gitroot\CafeWebApp\Ingress\loadbalancer.yaml

  REM verify service of type loadbalancer running
  REM notice external-ip (Azure Public IP)
  REM notice cluster-ip (Test from any container in any pod)
  REM kubectl get services --namespace=cafe-ingress -o wide
  REM - test from external: curl https://20.185.14.92/coffee -H "HOST: cafe.example.com" -v -k

REM create cafe-apps namespace
REM create coffee (2 replicas) and tea (3 replicas) deployments in cafe-apps namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Apps\cafe.yaml
REM create coffee-clusterip and tea-clusterip service in cafe-apps namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Apps\cafe-clusterip.yaml

REM verify everything is running
REM kubectl get all -n=cafe-apps -o wide

REM ENDPOINTS or POD IP: for external access (vnet address).  #endpoints = #replicas = #nodes
REM - you can test from VM with curl 10.0.0.28/coffee -v
REM - you can test from VM with curl 10.0.0.77/tea -v
REM CLUSTER IP: k8s-internal ip address (not vnet)
REM - use for internal communication
REM - you can test bash running in containers
REM kubectl exec -it coffee-5f4946c597-6lhzs --container coffee -n=cafe-apps -- /bin/bash
REM root@coffee-5f4946c597-6lhzs:/app# curl 10.0.1.209/coffee -v
REM root@coffee-5f4946c597-6lhzs:/app# curl 10.0.1.177/tea -v

REM add cafe-secret with a TLS certificate to cafe-apps namespace
REM kubectl apply -f C:\gitroot\CafeWebApp\Apps\cafe-secret.yaml

REM Add routing rules (and cafe-ingress extension ingress config)
REM kubectl apply -f C:\gitroot\CafeWebApp\Apps\cafe-ingress.yaml
REM - test from anywhere with curl http://40.71.237.209/coffee -H "HOST: cafe.example.com" -v -k
REM - test from anywhere with curl https://40.71.237.209/coffee -H "HOST: cafe.example.com" -v -k
REM - test from anywhere with curl http://40.71.237.209/tea -H "HOST: cafe.example.com" -v -k
REM - test from anywhere with curl https://40.71.237.209/tea -H "HOST: cafe.example.com" -v -k

