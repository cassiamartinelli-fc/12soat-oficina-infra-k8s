# GitHub Actions Workflows

## Terraform AWS (`terraform.yml`)

Gerencia infraestrutura AWS EC2 + Docker Compose (Kong + NestJS App).

### Triggers

**Automático:**
- **Pull Requests** → `terraform plan` (validação, não cria recursos)

**Manual (workflow_dispatch):**
```
Actions → Terraform AWS → Run workflow
Escolher: plan | apply | destroy
```

### Ações

| Ação | O que faz | Quando usar |
|------|-----------|-------------|
| `plan` | Valida Terraform e mostra mudanças | Antes de aplicar mudanças |
| `apply` | Cria/atualiza EC2 na AWS (~3min) | Iniciar trabalho diário |
| `destroy` | Destrói EC2 (mantém Elastic IP) | Pausar trabalho (economia) |

### Secrets Necessários

**Settings → Secrets → Actions:**

| Secret | Descrição |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `NEON_DATABASE_URL` | Connection string PostgreSQL |
| `NEWRELIC_LICENSE_KEY` | New Relic license key |
| `JWT_SECRET` | Secret para tokens JWT |

### Segurança

- ✅ Secrets nunca expostos nos logs
- ✅ `apply` e `destroy` apenas na branch `main`
- ✅ PRs executam apenas `plan` (read-only)
