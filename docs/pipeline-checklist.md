# ✅ Checklist de Conformidade – Zookeeper Infrastructure

- [x] Permissões globais mínimas (`contents: read`, `id-token: write`) definidas no workflow.
- [x] Jobs executam em `[self-hosted, Linux, X64, srv649924, conexao-de-sorte-zookeeper-infraestrutura]`.
- [x] `azure/login@v2` usa `${{ vars.AZURE_* }}` e `azure/get-keyvault-secrets@v1` busca apenas segredos documentados (atualmente nenhum).
- [x] Inventário de segredos atualizado em `docs/secrets-usage-map.md`; nenhuma credencial aplicada ao repositório.
- [ ] `actionlint`, `docker compose config`, `hadolint` e `docker build` executados ou registrados em `validation-report.md`.
- [x] Deploy Swarm cria recursos de forma idempotente, aplica `update_config`/`rollback_config` e executa health checks.
- [x] Documentação (`README`, `docs/`) atualizada com requisitos de runner, segredos mínimos e fluxo de validação.
- [ ] Execução em staging/produção registrada com evidências do workflow.
