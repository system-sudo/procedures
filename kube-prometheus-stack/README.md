# Prerequisites
**Install Helm and NGINX_Ingress_Controller**  
Link https://github.com/system-sudo/procedures/blob/main/Ingress_Controller_K8s/nginx.md

# 🧭 Step-by-Step Installation of kube_prometheus_stack with sub path  

## 🧰 Step 1: Add kube-prometheus-stack Repo  
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
## custom_kube_prometheus_stack.yml is in the repo ** change elb DNS Name  
```bash
kubectl get svc  -n ingress-nginx
```
Link https://github.com/system-sudo/procedures/blob/main/kube-prometheus-stack/custom_kube_prometheus_stack.yaml

## 🧰 Step 2: Install kube-prometheus-stack by passing Custom Values  
```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f ./custom_kube_prometheus_stack.yaml
```

## ✅ 3. Access the Services
Once everything is deployed:  
change elb DNS Name  

•	Grafana:  
  http://afc0d7ef8e4864ede924ae05195de1fd-e9e1bd8396e3c2a1.elb.us-east-1.amazonaws.com/grafana  

## To get the Grafana admin password after installing the Kube Prometheus Stack via Helm, follow these steps: Usally the Password is : prom-operator
```bash
kubectl get secret -n monitoring
```
```bash
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```
•	Prometheus:  
  http://afc0d7ef8e4864ede924ae05195de1fd-e9e1bd8396e3c2a1.elb.us-east-1.amazonaws.com/prometheus  
    
•	Alertmanager:  
http://afc0d7ef8e4864ede924ae05195de1fd-e9e1bd8396e3c2a1.elb.us-east-1.amazonaws.com/alert
