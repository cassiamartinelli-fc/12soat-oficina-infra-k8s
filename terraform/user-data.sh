#!/bin/bash
set -e

# Instalar K3s (Kubernetes single-node)
curl -sfL https://get.k3s.io | sh -

# Aguardar K3s estar pronto
sleep 30
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Configurar kubectl para usuário ubuntu
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Criar ConfigMap com config declarativa do Kong
cat > /tmp/kong.yml <<'EOF'
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
        paths: [/os-service/health, /os-service/clientes, /os-service/veiculos, /os-service/pecas, /os-service/servicos, /os-service/ordens-servico]
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
        paths: [/billing-service/health, /billing-service/orcamentos]
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
        paths: [/production-service/health, /production-service/execucoes]
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
kubectl apply -f - <<'YAML'
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

echo "K3s + Kong iniciados em $(date)" > /var/log/user-data.log
