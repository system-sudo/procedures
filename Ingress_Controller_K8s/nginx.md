**Install Helm if not already Installed**

https://helm.sh/docs/intro/install/

# 🧭 Step-by-Step Installation of NGINX Ingress with NLB
## 1.	Add the NGINX Ingress Helm repository
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
## 2.	Install the Ingress Controller with NLB configuration
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
```
## 3.  Verify the Installation
```bash
kubectl get all -n ingress-nginx
```
Look for a LoadBalancer service named ingress-nginx-controller. The EXTERNAL-IP or HOSTNAME is what you'll use in your Ingress host field.
```bash
kubectl get service/ingress-nginx-controller -n ingress-nginx
```
## 4. To uninstall the ingress-nginx Ingress Controller
```bash
helm uninstall ingress-nginx --namespace ingress-nginx
```
