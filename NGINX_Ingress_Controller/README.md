**Install Helm is not already Installed**

https://helm.sh/docs/intro/install/

🧭 Step-by-Step Installation of NGINX Ingress with NLB
1.	Add the NGINX Ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

2.	Install the Ingress Controller with NLB configuration
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
