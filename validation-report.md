# ✅ Pipeline Validation Report – Zookeeper Infrastructure

## Static Checks
- `actionlint -config-file .github/actionlint.yaml --shellcheck=` → executado (sucesso).
- `docker compose -f docker-compose.yml config -q` → executado (sucesso).
- `hadolint` → pendente (ferramenta indisponível neste ambiente; executar posteriormente no runner autorizado).
- `docker build` → pendente (daemon indisponível; registrar resultado após execução no host de deploy).

## Observações
- Nenhum segredo é buscado atualmente no Key Vault; o job de deploy apenas confirma a lista vazia.
- Volumes `zookeeper_data` e `zookeeper_logs` têm permissões ajustadas para UID/GID 1000 antes do deploy.
- Health checks verificam logs, porta 2181 e processo `QuorumPeerMain`.

## Próximos Passos
1. Rodar `hadolint` e `docker build` no runner Hostinger e atualizar este relatório.
2. Disparar o workflow em staging para registrar evidências de deploy.
