# Terraform - AWS Infrastructure

Infraestrutura como código para provisionar EC2 + Kong Gateway + New Relic na AWS.

## 🚀 Uso Local

### 1. Configurar AWS CLI

```bash
# Verificar se AWS CLI está instalado
aws --version

# Configurar credenciais AWS
aws configure
# Fornecer: AWS Access Key ID, AWS Secret Access Key, região: us-east-1
```

**Obter credenciais AWS:** IAM Console → Users → Security credentials → Create access key

### 2. Criar chave SSH na AWS

```bash
# Console AWS: EC2 → Key Pairs → Create key pair
# Nome: oficina-key
```

### 3. Configurar variáveis do Terraform

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com seus valores
```

**Variáveis obrigatórias:**
- `neon_database_url` — Connection string do PostgreSQL
- `newrelic_license_key` — License key do New Relic
- `jwt_secret` — Chave secreta para JWT

**Variáveis opcionais (já têm defaults):**
- `aws_region` — us-east-1
- `instance_type` — t3.small
- `app_image` — ghcr.io/cassiamartinelli-fc/12soat-oficina-app:latest

**Onde obter credenciais:**
- Neon: https://console.neon.tech → Selecionar projeto → Connection Details
- New Relic: https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher
- JWT Secret: Usar a mesma de [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth)

⚠️ `terraform.tfvars` está no `.gitignore` - **nunca commitá-lo!**

### 4. Provisionar

```bash
terraform init
terraform plan              # Revisar mudanças
terraform apply             # Criar infraestrutura
```

### 5. Obter URL pública

```bash
terraform output kong_url
# Ou
terraform output next_steps
```

### 6. Destruir (quando não precisar mais)

```bash
terraform destroy  # Deleta toda a infraestrutura
```

## 📦 Recursos Criados

- **Security Group** — Regras de firewall (portas 8000, 8001, 22)
- **Elastic IP** — IP público (muda a cada destroy/apply)
- **EC2 Instance** — t3.small com Ubuntu 22.04
- **Docker Compose** — Kong Gateway + Aplicação NestJS

## 🔧 Outputs

| Output | Descrição |
|--------|-----------|
| `kong_url` | URL completa do Kong Gateway |
| `public_ip` | IP público da instância |
| `instance_id` | ID da instância EC2 |
| `next_steps` | Instruções pós-deploy |

## 🔄 CI/CD via GitHub Actions

Use o workflow **Terraform AWS** para provisionar via GitHub Actions.

**Vantagens:**
- Não precisa configurar AWS CLI localmente
- Secrets gerenciados pelo GitHub
- Logs de execução salvos

**Opções:**
- **plan** — Valida configuração
- **apply** — Provisiona infraestrutura
- **output** — Exibe URL pública
- **destroy** — Deleta infraestrutura
