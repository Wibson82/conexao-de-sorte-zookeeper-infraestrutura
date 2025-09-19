# 🔧 Conexão de Sorte – Zookeeper Infrastructure

Infraestrutura Zookeeper utilizada pelo cluster Kafka, executada no Docker Swarm da Hostinger (`srv649924`). O pipeline GitHub Actions utiliza OIDC com Azure, buscando segredos apenas quando necessários (atualmente nenhum).

## 📦 Componentes
- `docker-compose.yml`: contêiner `cp-zookeeper:7.9.0` rodando como usuário não-root (`1000:1000`), com healthcheck sem `nc`, logging rotacionado e políticas de `update_config`/`rollback_config` configuradas.
- `.github/workflows/ci-cd.yml`: workflow dividido em `validate` e `deploy`, ambos rodando no runner `[self-hosted, Linux, X64, srv649924, conexao-de-sorte-zookeeper-infraestrutura]` com `vars.AZURE_*`.
- `.github/actionlint.yaml`: configuração para validar os labels customizados do runner.
- `docs/`: inventário de segredos e checklist de conformidade.

## 🚀 Deploy
```bash
# CI/CD automático (workflow GitHub Actions)
git push origin main

# Deploy manual (Swarm)
docker network create --driver overlay conexao-network-swarm  # se ainda não existir
docker volume create zookeeper_data
docker volume create zookeeper_logs
docker stack deploy -c docker-compose.yml conexao-zookeeper
```

## 🔐 Segredos
- **Repository Variables**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_KEYVAULT_NAME`, `AZURE_KEYVAULT_ENDPOINT` (opcional).
- **Azure Key Vault**: nenhum segredo consumido atualmente (inventário em `docs/secrets-usage-map.md`).
- **GitHub Secrets**: apenas `GITHUB_TOKEN` (padrão).

## 🧪 Validações
- `actionlint -config-file .github/actionlint.yaml --shellcheck=`
- `docker compose -f docker-compose.yml config -q`
- `hadolint`/`docker build` pendentes – executar nos runners autorizados e registrar em `validation-report.md`.

## 🔍 Troubleshooting rápido
```bash
# Logs do serviço
docker service logs conexao-zookeeper_zookeeper --tail 50

# Health manual
zkServer.sh status

# Verificar portas
docker exec $(docker ps -q -f name=conexao-zookeeper_zookeeper) ss -tuln | grep 2181
```

## 📚 Documentação Auxiliar
- `docs/pipeline-checklist.md`
- `HISTORICO-MUDANCAS.md`
- `validation-report.md`

Status atual: inventário e checklist atualizados; pipeline refatorado para OIDC mínimo e deploy seguro.
