# Oficina Mecânica — Infraestrutura K8s (Fase 4)

Infraestrutura AWS com K3s (Kubernetes single-node) e Kong Gateway para os microsserviços da Fase 4.

## Tecnologias

- **AWS EC2 t3.small** — Instância Ubuntu 22.04 com K3s
- **K3s** — Kubernetes single-node (leve, custo reduzido)
- **Kong Gateway** — API Gateway com validação JWT (modo declarativo, sem banco)
- **Terraform** — Infraestrutura como código (estado remoto no S3)

## Arquitetura

```
Cliente
   │ HTTP :30080
   ▼
EC2 t3.small
├── K3s (Kubernetes)
│   ├── Kong Gateway (NodePort 30080)
│   │   ├── /os-service/*        → os-service:3000 (JWT para POST/PUT/PATCH/DELETE)
│   │   ├── /billing-service/*   → billing-service:3001 (JWT para POST/PUT/PATCH/DELETE)
│   │   └── /production-service/*→ production-service:3002 (JWT para POST/PUT/PATCH/DELETE)
│   ├── os-service (ClusterIP :3000)
│   ├── billing-service (ClusterIP :3001)
│   └── production-service (ClusterIP :3002)
└── K3s API Server (:6443, para kubectl remoto)
```

## Setup via GitHub Actions

### Provisionar infraestrutura

```
Actions → Terraform AWS → Run workflow → action: apply
```

Aguardar ~3 minutos para K3s e Kong iniciarem.

### Obter IP público e kubeconfig

Após o apply, o summary da Action exibe o IP público e instruções para obter o kubeconfig:

```bash
ssh -i ~/.ssh/oficina-key.pem ubuntu@<EC2_IP> 'cat /home/ubuntu/.kube/config'
```

Salvar o conteúdo como secret **KUBECONFIG** nos repos dos serviços.

### Destruir infraestrutura (economia de custos)

```
Actions → Terraform AWS → Run workflow → action: destroy
```

## Secrets necessários (Settings → Secrets → Actions)

| Secret | Descrição |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `JWT_SECRET` | Chave secreta para validação JWT no Kong |

## Validação após deploy

```bash
# Verificar K3s e Kong
curl http://<EC2_IP>:30080/os-service/health
curl http://<EC2_IP>:30080/billing-service/health
curl http://<EC2_IP>:30080/production-service/health
```

## Repositórios relacionados

- [12soat-oficina-os-service](https://github.com/cassiamartinelli-fc/12soat-oficina-os-service)
- [12soat-oficina-billing-service](https://github.com/cassiamartinelli-fc/12soat-oficina-billing-service)
- [12soat-oficina-production-service](https://github.com/cassiamartinelli-fc/12soat-oficina-production-service)
- [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth)

## Licença

MIT — Tech Challenge 12SOAT Fase 4
