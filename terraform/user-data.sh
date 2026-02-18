#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

# Obter IP público da EC2
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Instalar K3s com IP público no certificado TLS
curl -sfL https://get.k3s.io | sh -s - --tls-san "$PUBLIC_IP"

# Aguardar K3s estar pronto (até 3 minutos)
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for i in $(seq 1 18); do
  if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    echo "K3s pronto!"
    break
  fi
  echo "Aguardando K3s... tentativa $i/18"
  sleep 10
done

# Gerar kubeconfig com IP público (para uso externo via kubectl)
mkdir -p /home/ubuntu/.kube
sed "s|server: https://.*:6443|server: https://$PUBLIC_IP:6443|g" /etc/rancher/k3s/k3s.yaml > /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Criar config declarativa do Kong
# Nota: usar EOF sem aspas para permitir interpolação do jwt_secret
cat > /tmp/kong.yml <<EOF
_format_version: "3.0"

consumers:
  - username: oficina-client
    jwt_secrets:
      - key: oficina-mecanica-secret-key-2025
        secret: ${jwt_secret}
        algorithm: HS256

services:
  - name: os-service
    url: http://os-service.default.svc.cluster.local:3000
    routes:
      - name: os-public
        paths: [/os-service/health]
        methods: [GET]
        strip_path: true
      - name: os-protected
        paths: [/os-service]
        strip_path: true
        plugins:
          - name: jwt
            config:
              key_claim_name: key

  - name: billing-service
    url: http://billing-service.default.svc.cluster.local:3001
    routes:
      - name: billing-public
        paths: [/billing-service/health]
        methods: [GET]
        strip_path: true
      - name: billing-protected
        paths: [/billing-service]
        strip_path: true
        plugins:
          - name: jwt
            config:
              key_claim_name: key

  - name: production-service
    url: http://production-service.default.svc.cluster.local:3002
    routes:
      - name: production-public
        paths: [/production-service/health]
        methods: [GET]
        strip_path: true
      - name: production-protected
        paths: [/production-service]
        strip_path: true
        plugins:
          - name: jwt
            config:
              key_claim_name: key
EOF

kubectl create configmap kong-config --from-file=kong.yml=/tmp/kong.yml --dry-run=client -o yaml | kubectl apply -f -

# Deploy Kong Gateway
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kong-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kong-gateway
  template:
    metadata:
      labels:
        app: kong-gateway
    spec:
      containers:
      - name: kong
        image: kong:3.5
        env:
        - name: KONG_DATABASE
          value: "off"
        - name: KONG_DECLARATIVE_CONFIG
          value: /kong/kong.yml
        - name: KONG_PROXY_LISTEN
          value: "0.0.0.0:8000"
        - name: KONG_ADMIN_LISTEN
          value: "0.0.0.0:8001"
        - name: KONG_PLUGINS
          value: "bundled,jwt"
        ports:
        - containerPort: 8000
        - containerPort: 8001
        volumeMounts:
        - name: kong-config
          mountPath: /kong
      volumes:
      - name: kong-config
        configMap:
          name: kong-config
---
apiVersion: v1
kind: Service
metadata:
  name: kong-gateway
spec:
  type: NodePort
  selector:
    app: kong-gateway
  ports:
  - name: proxy
    port: 8000
    targetPort: 8000
    nodePort: 30080
  - name: admin
    port: 8001
    targetPort: 8001
    nodePort: 30081
YAML

echo "K3s + Kong iniciados com sucesso em $(date)"
