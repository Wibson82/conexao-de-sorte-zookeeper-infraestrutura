# Secrets Usage Map – Zookeeper Infrastructure

## Repository Variables (`vars`)
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_KEYVAULT_NAME`
- `AZURE_KEYVAULT_ENDPOINT` *(opcional)*

> Apenas identificadores Azure permanecem no GitHub como vars. Segredos sensíveis são obtidos do Key Vault durante os jobs que precisarem.

## GitHub Secrets
- `GITHUB_TOKEN` – token padrão do GitHub Actions.

## Azure Key Vault
- Nenhum segredo é consumido atualmente. Documente novos segredos aqui antes de incluí-los no workflow.

## Jobs × Secret Usage
| Job | Propósito | Segredos/Variáveis | Observações |
| --- | --- | --- | --- |
| `validate` | Compose/YAML lint e verificações básicas | `AZURE_*` (vars), `GITHUB_TOKEN` | Não consulta o Key Vault. |
| `deploy` | Deploy Swarm e health checks | `AZURE_*` (vars), `GITHUB_TOKEN` | Lista de segredos vazia (confirmada durante o job). |

## Notas Operacionais
- Atualize este arquivo sempre que novos segredos forem introduzidos.
- Utilize `::add-mask::` ao manipular valores sensíveis retornados do Key Vault.
- Configure `MAX_VERSIONS_TO_KEEP` / `MAX_AGE_DAYS` / `PROTECTED_TAGS` se passar a usar limpeza de imagens no GHCR.
