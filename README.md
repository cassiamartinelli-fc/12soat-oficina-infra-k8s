# Oficina Mecânica — Infraestrutura Kubernetes (Fase 4)

Infraestrutura AWS com K3s e Kong Gateway para arquitetura de microsserviços com Saga Pattern. Este README é o ponto de partida para rodar o projeto completo da Fase 4.

## 📋 Índice

- [🔗 Links Úteis](#-links-úteis)
- [🎯 Arquitetura](#-arquitetura)
- [🛠️ Tecnologias](#️-tecnologias)
- [🚀 Provisionamento e Deploy](#-provisionamento-e-deploy-completo)
- [📊 Microsserviços](#-microsserviços)
- [🔄 Saga Pattern](#-saga-pattern)
- [💳 Integração Mercado Pago](#-integração-mercado-pago)
- [🗄️ Bancos de Dados](#️-bancos-de-dados)
- [📡 Comunicação entre Serviços](#-comunicação-entre-serviços)
- [🔐 Autenticação JWT](#-autenticação-jwt)
- [⚙️ Comandos Essenciais](#️-comandos-essenciais)
- [🧪 Testes e Qualidade](#-testes-e-qualidade)
- [📈 Observabilidade](#-observabilidade)
- [🔧 CI/CD](#-cicd)
- [📝 Licença](#-licença)

## 🔗 Links Úteis

### Repositórios da Fase 4

#### Microsserviços
- [12soat-oficina-os-service](https://github.com/cassiamartinelli-fc/12soat-oficina-os-service) — Gestão de Ordens de Serviço
- [12soat-oficina-billing-service](https://github.com/cassiamartinelli-fc/12soat-oficina-billing-service) — Orçamento e Pagamento
- [12soat-oficina-production-service](https://github.com/cassiamartinelli-fc/12soat-oficina-production-service) — Execução e Produção

#### Infraestrutura
- [12soat-oficina-infra-k8s](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-k8s) — Infraestrutura Kubernetes (este repositório)
- [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth) — Lambda de Autenticação JWT

### Deploy Ativo
- **Kong Gateway:** Execute workflow `Terraform AWS` → `output` para obter `<KONG_URL>`
- **API Docs:** `<KONG_URL>/{service-name}/api-docs`
- **Health Check:** `<KONG_URL>/{service-name}/health`
- **New Relic APM:** https://one.newrelic.com

### Documentação
- **Vídeo Demonstração Fase 4:** [Em breve]
- **Postman Collections:** [Oficina Mecânica API](https://www.postman.com/cassia-martinelli-9397607/workspace/cassia-s-workspace/request/46977418-4a758cc9-d08a-4ca6-ab97-b522149755d5?action=share&creator=46977418&ctx=documentation)
- **Arquitetura Completa:** Ver seção [Arquitetura](#-arquitetura-da-fase-4)

## 🎯 Arquitetura

### Visão Geral

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ HTTPS
       ▼
┌────────────────────────────────────────┐
│         AWS Lambda Auth                │
│  (Geração de Token JWT)                │
└────────────────────────────────────────┘
       │
       ▼
┌────────────────────────────────────────┐
│         Kong Gateway (EC2)             │
│  - Validação JWT                       │
│  - Roteamento de Serviços              │
│  - NodePort :30080                     │
└──────┬─────────────┬──────────┬────────┘
       │             │          │
       ▼             ▼          ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ OS Service   │ │ Billing Svc  │ │Production Svc│
│ (Port 3000)  │ │ (Port 3001)  │ │ (Port 3002)  │
│              │ │              │ │              │
│ MongoDB      │ │ PostgreSQL   │ │ PostgreSQL   │
│ (NoSQL)      │ │ (SQL)        │ │ (SQL)        │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┴────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │     SQS      │
              │ (Mensageria) │
              └──────────────┘
                     │
                     ▼
              ┌───────────────┐
              │  New Relic    │
              │(Observability)│
              └───────────────┘
```

### Decisões Arquiteturais

**Divisão de Microsserviços:**
- **OS Service:** Gerencia ciclo de vida das ordens de serviço (abertura, status, histórico)
- **Billing Service:** Responsável por orçamentos, integração Mercado Pago e pagamentos
- **Production Service:** Controla fila de execução

**Justificativa:** Separação clara de responsabilidades seguindo domínios de negócio independentes, permitindo escalabilidade e deploy isolado.

## 🛠️ Tecnologias

### Infraestrutura
- **AWS EC2 t3.small** — Instância Ubuntu 22.04
- **K3s** — Kubernetes single-node (leve, produtivo)
- **Kong Gateway** — API Gateway com JWT (modo declarativo)
- **Terraform** — IaC com estado remoto S3
- **RabbitMQ** — Message broker para comunicação assíncrona

### Microsserviços
- **NestJS** — Framework Node.js com TypeScript
- **MongoDB** — Banco NoSQL (OS Service)
- **PostgreSQL (Neon)** — Banco SQL gerenciado (Billing e Production)
- **TypeORM** — ORM para PostgreSQL
- **Mongoose** — ODM para MongoDB
- **New Relic** — APM e observabilidade

## 🚀 Provisionamento e Deploy Completo

### Pré-requisitos

- Conta AWS com credenciais configuradas
- Secrets configurados em cada repositório (detalhes abaixo)
- Chave SSH `oficina-key` criada no AWS EC2 Console (região us-east-1)

### Passo 1: Provisionar Infraestrutura Kubernetes

**Repositório:** [12soat-oficina-infra-k8s](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-k8s)

1.1. Executar workflow `Terraform AWS` → `apply` (aguardar ~3 min)

1.2. Obter informações da infraestrutura:
```bash
# Execute workflow: Terraform AWS → output
# Ou via terraform local:
cd terraform
terraform output kong_url
terraform output public_ip
```

1.3. Obter kubeconfig para deploy dos serviços:
```bash
ssh -i ~/.ssh/oficina-key.pem ubuntu@<PUBLIC_IP> 'cat /home/ubuntu/.kube/config'
```

1.4. Salvar kubeconfig como secret `KUBECONFIG` nos 3 repositórios de microsserviços.

**Secrets necessários (Settings → Secrets → Actions):**
- `AWS_ACCESS_KEY_ID` — AWS Access Key
- `AWS_SECRET_ACCESS_KEY` — AWS Secret Key
- `JWT_SECRET` — Chave secreta para validação JWT

### Passo 2: Deploy dos Microsserviços

**IMPORTANTE:** Seguir ordem de deploy para garantir dependências.

#### 2.1. OS Service
**Repositório:** [12soat-oficina-os-service](https://github.com/cassiamartinelli-fc/12soat-oficina-os-service)

```bash
# Execute workflow: Deploy to K3s
```

**Secrets necessários:**
- `KUBECONFIG` — Obtido no Passo 1.3
- `MONGODB_URI` — Connection string MongoDB Atlas
- `RABBITMQ_URL` — URL do RabbitMQ (CloudAMQP ou local)
- `NEW_RELIC_LICENSE_KEY` — License key New Relic
- `JWT_SECRET` — Mesma chave usada na infraestrutura

#### 2.2. Billing Service
**Repositório:** [12soat-oficina-billing-service](https://github.com/cassiamartinelli-fc/12soat-oficina-billing-service)

```bash
# Execute workflow: Deploy to K3s
```

**Secrets necessários:**
- `KUBECONFIG` — Obtido no Passo 1.3
- `NEON_DATABASE_URL` — Connection string PostgreSQL (Neon)
- `RABBITMQ_URL` — URL do RabbitMQ (mesma do OS Service)
- `MERCADO_PAGO_ACCESS_TOKEN` — Token de acesso Mercado Pago
- `NEW_RELIC_LICENSE_KEY` — License key New Relic
- `JWT_SECRET` — Mesma chave usada na infraestrutura

#### 2.3. Production Service
**Repositório:** [12soat-oficina-production-service](https://github.com/cassiamartinelli-fc/12soat-oficina-production-service)

```bash
# Execute workflow: Deploy to K3s
```

**Secrets necessários:**
- `KUBECONFIG` — Obtido no Passo 1.3
- `NEON_DATABASE_URL` — Connection string PostgreSQL (Neon)
- `RABBITMQ_URL` — URL do RabbitMQ (mesma dos outros serviços)
- `NEW_RELIC_LICENSE_KEY` — License key New Relic
- `JWT_SECRET` — Mesma chave usada na infraestrutura

### Passo 3: Deploy Lambda de Autenticação

**Repositório:** [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth)

```bash
# Execute workflow: CD - Deploy Lambda to AWS
```

**Secrets necessários:**
- `AWS_ACCESS_KEY_ID` — AWS Access Key
- `AWS_SECRET_ACCESS_KEY` — AWS Secret Key
- `NEON_DATABASE_URL` — Connection string PostgreSQL (Neon)
- `JWT_SECRET` — Mesma chave usada na infraestrutura

### Passo 4: Validação do Deploy

```bash
# Substituir <KONG_URL> pela URL obtida no Passo 1.2

# Health check dos serviços
curl <KONG_URL>/os-service/health
curl <KONG_URL>/billing-service/health
curl <KONG_URL>/production-service/health

# Validar Kong Gateway
curl <KONG_URL>
```

## 📊 Microsserviços

### OS Service (Ordem de Serviço)

**Responsabilidades:**
- Abertura de ordens de serviço
- Atualização de status
- Consulta de status e histórico
- Orquestração do fluxo Saga

**Banco de Dados:** MongoDB (NoSQL)

**Endpoints principais:**
- `POST /ordens-servico` — Criar OS (inicia Saga)
- `GET /ordens-servico` — Listar OS
- `GET /ordens-servico/:id` — Obter OS por ID
- `PATCH /ordens-servico/:id/status` — Atualizar status

**Eventos publicados:**
- `os.criada` — OS criada com sucesso
- `os.cancelada` — OS cancelada (compensação)

### Billing Service (Orçamento e Pagamento)

**Responsabilidades:**
- Geração de orçamentos
- Envio para aprovação do cliente
- Integração com Mercado Pago
- Registro e verificação de pagamentos
- Atualização de status da OS após pagamento

**Banco de Dados:** PostgreSQL (SQL)

**Endpoints principais:**
- `POST /orcamentos` — Criar orçamento
- `GET /orcamentos/:osId` — Obter orçamento por OS
- `POST /pagamentos/webhook` — Webhook Mercado Pago
- `GET /pagamentos/:osId` — Verificar status pagamento

**Eventos consumidos:**
- `os.criada` — Gera orçamento automaticamente

**Eventos publicados:**
- `orcamento.criado` — Orçamento gerado
- `pagamento.aprovado` — Pagamento confirmado
- `pagamento.recusado` — Pagamento recusado (compensação)

### Production Service (Execução e Produção)

**Responsabilidades:**
- Gerenciar fila de execução
- Atualizar status durante diagnóstico
- Controlar reparos e execução
- Comunicar finalização ao OS Service

**Banco de Dados:** PostgreSQL (SQL)

**Endpoints principais:**
- `POST /execucoes` — Iniciar execução
- `GET /execucoes/fila` — Obter fila de execução
- `PATCH /execucoes/:id/status` — Atualizar status execução
- `POST /execucoes/:id/finalizar` — Finalizar execução

**Eventos consumidos:**
- `pagamento.aprovado` — Inicia execução da OS

**Eventos publicados:**
- `execucao.iniciada` — Execução iniciada
- `execucao.finalizada` — Serviço concluído
- `execucao.falhada` — Erro na execução (compensação)

## 🔄 Saga Pattern

### Estratégia: Orquestração

**Justificativa:**
- Fluxo complexo com múltiplas etapas sequenciais
- Necessidade de controle centralizado de compensações
- Facilita rastreamento e debugging
- Menor complexidade em comparação à coreografia para este cenário

### Orquestrador

O **OS Service** atua como orquestrador central, coordenando o fluxo:

1. Cliente cria OS → OS Service
2. OS Service publica `os.criada`
3. Billing Service consome e gera orçamento
4. Billing Service publica `orcamento.criado`
5. Cliente aprova → Mercado Pago processa pagamento
6. Billing Service publica `pagamento.aprovado`
7. Production Service consome e inicia execução
8. Production Service publica `execucao.finalizada`
9. OS Service atualiza status para `FINALIZADA`

### Fluxo de Compensação

**Cenário 1: Pagamento Recusado**
```
1. Billing Service detecta falha no pagamento
2. Publica evento pagamento.recusado
3. OS Service consome e atualiza status para CANCELADA
4. Production Service ignora (não iniciou execução)
```

**Cenário 2: Falha na Execução**
```
1. Production Service detecta erro durante reparo
2. Publica evento execucao.falhada
3. OS Service consome e atualiza status para EM_DIAGNOSTICO
4. Billing Service pode gerar novo orçamento se necessário
```

**Cenário 3: Cliente Rejeita Orçamento**
```
1. Billing Service registra rejeição
2. Publica evento orcamento.rejeitado
3. OS Service atualiza status para CANCELADA
4. Nenhum pagamento é processado
```

### Garantias de Consistência

- **Idempotência:** Todos os handlers de eventos são idempotentes
- **Retry automático:** RabbitMQ com Dead Letter Queue (DLQ)
- **Timeouts:** Cada etapa possui timeout configurado
- **Auditoria:** Todos os eventos são registrados no New Relic

## 💳 Integração Mercado Pago

**Implementação no Billing Service:**

### Fluxo de Pagamento

1. Cliente aprova orçamento
2. Billing Service cria preferência de pagamento no Mercado Pago
3. Cliente é redirecionado para checkout Mercado Pago
4. Mercado Pago processa pagamento
5. Webhook notifica Billing Service
6. Billing Service valida pagamento e publica `pagamento.aprovado`

### Configuração

**Variável de ambiente:**
```bash
MERCADO_PAGO_ACCESS_TOKEN=APP_USR-xxxxx
```

**Endpoint de webhook:**
```
POST <KONG_URL>/billing-service/pagamentos/webhook
```

**Documentação oficial:** https://www.mercadopago.com.br/developers/pt/docs

## 🗄️ Bancos de Dados

### OS Service — MongoDB (NoSQL)

**Justificativa:**
- Esquema flexível para diferentes tipos de veículos e serviços
- Alto volume de leitura (consultas de status)
- Histórico de mudanças armazenado como documento

**Collections:**
- `ordens_servico` — Dados da OS
- `historico_status` — Transições de status

**Provider:** MongoDB Atlas (gerenciado)

### Billing Service — PostgreSQL (SQL)

**Justificativa:**
- Transações ACID críticas para pagamentos
- Relacionamentos entre orçamentos, itens e pagamentos
- Integridade referencial obrigatória

**Tabelas:**
- `orcamentos` — Dados do orçamento
- `itens_orcamento` — Peças e serviços
- `pagamentos` — Registro de pagamentos

**Provider:** Neon (PostgreSQL gerenciado)

### Production Service — PostgreSQL (SQL)

**Justificativa:**
- Controle de fila com priorização
- Registro de tempo de execução (SLA)
- Relacionamentos entre OS e etapas de produção

**Tabelas:**
- `execucoes` — Fila de execução
- `diagnosticos` — Resultados de diagnóstico
- `reparos` — Registro de reparos realizados

**Provider:** Neon (PostgreSQL gerenciado)

### Regra de Isolamento

**Nenhum serviço acessa diretamente o banco de outro.** Toda comunicação ocorre via:
- APIs REST (síncronas)
- Mensageria RabbitMQ (assíncronas)

## 📡 Comunicação entre Serviços

### Síncrona (REST API)

**Quando usar:**
- Consultas simples e rápidas
- Necessidade de resposta imediata
- Validações em tempo real

**Exemplos:**
- Cliente consulta status de OS via Kong → OS Service
- Production Service consulta dados de orçamento via Billing Service

### Assíncrona (RabbitMQ)

**Quando usar:**
- Processos longos (pagamento, execução)
- Desacoplamento entre serviços
- Necessidade de retry e tolerância a falhas

**Eventos principais:**

| Evento | Publisher | Consumer |
|--------|-----------|----------|
| `os.criada` | OS Service | Billing Service |
| `orcamento.criado` | Billing Service | OS Service |
| `pagamento.aprovado` | Billing Service | Production Service |
| `execucao.finalizada` | Production Service | OS Service |
| `*.compensacao` | Qualquer | OS Service (orquestrador) |

**Configuração RabbitMQ:**
- Exchange: `oficina.events` (topic)
- Queues: `os-service-queue`, `billing-service-queue`, `production-service-queue`
- DLQ (Dead Letter Queue) para mensagens falhadas
- TTL: 30 segundos para retry automático

**Provider:** CloudAMQP (gerenciado)

## 🔐 Autenticação JWT

### Fluxo de Autenticação

1. Cliente envia CPF para Lambda Auth
2. Lambda valida CPF no banco de clientes
3. Lambda gera token JWT assinado com `JWT_SECRET`
4. Cliente usa token no header `Authorization: Bearer <token>`
5. Kong Gateway valida token antes de rotear para serviços

### Rotas Públicas (GET)

- `GET /os-service/*` — Consultas de OS
- `GET /billing-service/*` — Consultas de orçamentos
- `GET /production-service/*` — Consultas de execução

### Rotas Protegidas (POST, PUT, PATCH, DELETE)

**Requerem token JWT válido:**
- `POST /os-service/ordens-servico` — Criar OS
- `PATCH /os-service/ordens-servico/:id` — Atualizar OS
- `POST /billing-service/orcamentos` — Criar orçamento
- `PATCH /production-service/execucoes/:id` — Atualizar execução

### Obter Token JWT

```bash
# Substituir <LAMBDA_URL> pela URL obtida no deploy da Lambda

curl -X POST <LAMBDA_URL> \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}'

# Resposta:
# {"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

### Usar Token em Requisições

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST <KONG_URL>/os-service/ordens-servico \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "clienteId": "123",
    "veiculoId": "456",
    "descricao": "Troca de óleo"
  }'
```

## ⚙️ Comandos Essenciais

### Obter URL da Infraestrutura

```bash
# Via GitHub Actions
# Execute workflow: Terraform AWS → output

# Via Terraform local
cd terraform
terraform output kong_url
terraform output public_ip
```

### Testar Serviços (Rotas Públicas)

```bash
# Substituir <KONG_URL> pela URL obtida

# Health checks
curl <KONG_URL>/os-service/health
curl <KONG_URL>/billing-service/health
curl <KONG_URL>/production-service/health

# Listar OS
curl <KONG_URL>/os-service/ordens-servico

# Obter orçamento por OS
curl <KONG_URL>/billing-service/orcamentos/os/12345

# Verificar fila de execução
curl <KONG_URL>/production-service/execucoes/fila
```

### Criar OS Completa (com autenticação)

```bash
# 1. Obter token
TOKEN=$(curl -X POST <LAMBDA_URL> \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}' | jq -r '.token')

# 2. Criar OS
OS_ID=$(curl -X POST <KONG_URL>/os-service/ordens-servico \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "clienteId": "123",
    "veiculoId": "456",
    "descricao": "Revisão completa",
    "servicos": ["Troca de óleo", "Balanceamento"]
  }' | jq -r '.id')

# 3. Verificar orçamento (gerado automaticamente via Saga)
curl <KONG_URL>/billing-service/orcamentos/os/$OS_ID

# 4. Aprovar orçamento e processar pagamento
curl -X POST <KONG_URL>/billing-service/orcamentos/$OS_ID/aprovar \
  -H "Authorization: Bearer $TOKEN"

# 5. Acompanhar execução
curl <KONG_URL>/production-service/execucoes/os/$OS_ID
```

### Acesso SSH e Logs

```bash
# SSH na instância EC2
ssh -i ~/.ssh/oficina-key.pem ubuntu@<PUBLIC_IP>

# Verificar pods Kubernetes
kubectl get pods

# Logs dos serviços
kubectl logs -f deployment/os-service
kubectl logs -f deployment/billing-service
kubectl logs -f deployment/production-service
kubectl logs -f deployment/kong-gateway

# Verificar RabbitMQ (se rodando no cluster)
kubectl port-forward svc/rabbitmq 15672:15672
# Acessar: http://localhost:15672
```

### Destruir Infraestrutura

```bash
# Via GitHub Actions
# Execute workflow: Terraform AWS → destroy

# Via Terraform local
cd terraform
terraform destroy -auto-approve
```

## 🧪 Testes e Qualidade

### Cobertura de Testes

**Requisito:** Mínimo 80% de cobertura por serviço

**Verificação:**
```bash
# Em cada repositório de microsserviço
npm run test:cov

# Relatório de cobertura em: coverage/lcov-report/index.html
```

### Testes Unitários

Todos os microsserviços possuem testes unitários para:
- Use cases / serviços
- Repositories
- Controllers
- Validações de domínio

**Executar testes:**
```bash
npm run test
```

### Testes BDD (Behavior-Driven Development)

**Fluxo testado:** Criação de OS com Saga completo

**Cenário:**
```gherkin
Feature: Criação de Ordem de Serviço com Saga

  Scenario: Cliente cria OS e paga com sucesso
    Given um cliente autenticado
    And um veículo cadastrado
    When o cliente cria uma OS
    Then um orçamento é gerado automaticamente
    And o status da OS é AGUARDANDO_APROVACAO
    When o cliente aprova e paga o orçamento
    Then o status da OS muda para EM_EXECUCAO
    And a OS entra na fila de produção
    When a execução é finalizada
    Then o status da OS muda para FINALIZADA

  Scenario: Falha no pagamento (compensação)
    Given uma OS criada com orçamento
    When o pagamento é recusado
    Then o status da OS muda para CANCELADA
    And a execução não é iniciada
```

**Executar testes BDD:**
```bash
# No repositório OS Service
npm run test:e2e
```

### Validação de Qualidade (SonarQube)

**Pipeline CI/CD inclui:**
- Análise estática de código
- Detecção de code smells
- Verificação de duplicação
- Análise de segurança

**Verificar no GitHub Actions:**
```
Actions → CI/CD → Ver step "SonarQube Analysis"
```

### Evidências de Cobertura

**Links nos READMEs de cada serviço:**
- OS Service: `coverage/` → ver prints no README
- Billing Service: `coverage/` → ver prints no README
- Production Service: `coverage/` → ver prints no README

## 📈 Observabilidade

### New Relic APM

**Dashboards implementados:**

#### Performance
- Latência média por endpoint
- Throughput (requisições/minuto)
- Uso de CPU e memória por serviço
- Tempo de resposta do banco de dados

#### Métricas de Negócio
- OS criadas (últimas 24h)
- Taxa de conversão de orçamentos
- Tempo médio de execução por tipo de serviço
- Taxa de pagamentos aprovados vs recusados

#### Saga Pattern
- Tempo total do fluxo Saga (criação → finalização)
- Taxa de compensação (% de Sagas revertidas)
- Eventos por tipo (os.criada, pagamento.aprovado, etc.)
- Latência de processamento de eventos

#### Erros e Disponibilidade
- Taxa de erro por serviço (%)
- Disponibilidade (uptime %)
- Erros de integração (Mercado Pago, RabbitMQ)
- Mensagens na Dead Letter Queue

### Custom Events

**Registrados no New Relic:**

```javascript
// OS Service
newrelic.recordCustomEvent('OrdemServicoCriada', {
  osId: '12345',
  clienteId: '123',
  valorEstimado: 500.00
})

// Billing Service
newrelic.recordCustomEvent('PagamentoProcessado', {
  osId: '12345',
  valor: 500.00,
  status: 'aprovado',
  metodoPagamento: 'mercadopago'
})

// Production Service
newrelic.recordCustomEvent('ExecucaoFinalizada', {
  osId: '12345',
  tempoExecucao: 120, // minutos
  status: 'concluida'
})

// Saga Orchestrator
newrelic.recordCustomEvent('SagaCompensacao', {
  osId: '12345',
  etapaFalha: 'pagamento',
  motivo: 'cartao_recusado'
})
```

### Acessar Dashboards

1. Login: https://one.newrelic.com
2. APM & Services → Selecionar serviço (os-service, billing-service, production-service)
3. Dashboards → "Oficina Mecânica - Fase 4"

## 🔧 CI/CD

### Proteção de Branches

**Todos os repositórios:**
- Branch `main` protegida
- Pull Request obrigatório
- Aprovação mínima: 1 revisor
- Checks automáticos devem passar:
  - Testes unitários
  - Cobertura mínima 80%
  - SonarQube Quality Gate
  - Build com sucesso

### Pipeline de CI (Pull Request)

```yaml
1. Checkout do código
2. Setup Node.js
3. Instalar dependências
4. Executar testes unitários
5. Verificar cobertura (>= 80%)
6. Build da aplicação
7. Análise SonarQube
8. Build da imagem Docker (sem push)
```

### Pipeline de CD (Merge para main)

```yaml
1. Executar pipeline de CI
2. Build da imagem Docker
3. Push para Docker Hub / GitHub Container Registry
4. Deploy no Kubernetes (K3s)
   - Aplicar manifests
   - Aguardar rollout completo
   - Verificar health check
5. Notificar New Relic do deploy
```

### Secrets Necessários por Repositório

#### Infraestrutura (infra-k8s)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `JWT_SECRET`

#### OS Service
- `KUBECONFIG`
- `MONGODB_URI`
- `RABBITMQ_URL`
- `NEW_RELIC_LICENSE_KEY`
- `JWT_SECRET`
- `DOCKER_USERNAME` (opcional, se usar Docker Hub)
- `DOCKER_PASSWORD` (opcional)

#### Billing Service
- `KUBECONFIG`
- `NEON_DATABASE_URL`
- `RABBITMQ_URL`
- `MERCADO_PAGO_ACCESS_TOKEN`
- `NEW_RELIC_LICENSE_KEY`
- `JWT_SECRET`
- `DOCKER_USERNAME` (opcional)
- `DOCKER_PASSWORD` (opcional)

#### Production Service
- `KUBECONFIG`
- `NEON_DATABASE_URL`
- `RABBITMQ_URL`
- `NEW_RELIC_LICENSE_KEY`
- `JWT_SECRET`
- `DOCKER_USERNAME` (opcional)
- `DOCKER_PASSWORD` (opcional)

#### Lambda Auth
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `NEON_DATABASE_URL`
- `JWT_SECRET`

### Rollback

**Em caso de falha no deploy:**

```bash
# Via kubectl (com kubeconfig configurado)
kubectl rollout undo deployment/os-service
kubectl rollout undo deployment/billing-service
kubectl rollout undo deployment/production-service

# Verificar status
kubectl rollout status deployment/os-service
```

## 📝 Licença

MIT — Tech Challenge 12SOAT Fase 4
