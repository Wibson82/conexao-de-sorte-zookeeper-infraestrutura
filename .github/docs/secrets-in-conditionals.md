# Guia: Usando Secrets em Condicionais GitHub Actions

## Problema
O contexto `secrets` não pode ser usado diretamente em condicionais `if` no GitHub Actions. Isso resulta no erro:
```
Unrecognized named-value: 'secrets'
```

## Solução Correta

### Passo 1: Carregar Secrets como Variáveis de Ambiente
```yaml
- name: Load secrets to environment
  id: load-secrets
  run: |
    echo "SECRET_NAME=${{ secrets.SECRET_NAME }}" >> $GITHUB_ENV
    echo "HAS_SECRET=$([[ -n "${{ secrets.SECRET_NAME }}" ]] && echo 'true' || echo 'false')" >> $GITHUB_ENV
```

### Passo 2: Usar Variáveis de Ambiente nos Condicionais
```yaml
- name: Step with conditional
  if: env.HAS_SECRET == 'true'
  run: echo "Secret is available"
```

## Exemplo Completo

### ❌ ERRADO (causa erro)
```yaml
- name: Bad example
  if: secrets.AZURE_KEYVAULT_NAME != ''  # ERRO: Unrecognized named-value: 'secrets'
  run: echo "Key Vault configured"
```

### ✅ CORRETO
```yaml
- name: Load secrets to environment
  id: load-secrets
  run: |
    echo "AZURE_KEYVAULT_NAME=${{ secrets.AZURE_KEYVAULT_NAME }}" >> $GITHUB_ENV
    echo "HAS_AZURE_KEYVAULT_NAME=$([[ -n "${{ secrets.AZURE_KEYVAULT_NAME }}" ]] && echo 'true' || echo 'false')" >> $GITHUB_ENV

- name: Confirm Key Vault usage
  if: env.HAS_AZURE_KEYVAULT_NAME == 'true'  # ✅ Correto: usa variável de ambiente
  run: echo "Key Vault configured"
```

## Vantagens desta Abordagem

1. **Evita erros de sintaxe**: Não usa `secrets` diretamente em condicionais
2. **Mantém segurança**: Os valores ainda vêm de secrets
3. **Flexibilidade**: Permite lógica complexa de validação
4. **Debugging**: Facilita verificar se secrets estão configurados

## Boas Práticas

1. **Sempre carregue secrets no início do job**
2. **Use prefixos descritivos** para variáveis booleanas (`HAS_`, `USE_`)
3. **Adicione máscaras** quando apropriado: `echo "::add-mask::${SECRET}"`
4. **Documente** quais secrets são esperados

## Exemplo do Projeto Zookeeper

Nossos workflows agora usam esta abordagem:

```yaml
# Carrega todos os secrets necessários
- name: Load secrets to environment
  id: load-secrets
  run: |
    echo "AZURE_CLIENT_ID=${{ secrets.AZURE_CLIENT_ID }}" >> $GITHUB_ENV
    echo "AZURE_TENANT_ID=${{ secrets.AZURE_TENANT_ID }}" >> $GITHUB_ENV
    echo "AZURE_SUBSCRIPTION_ID=${{ secrets.AZURE_SUBSCRIPTION_ID }}" >> $GITHUB_ENV
    echo "AZURE_KEYVAULT_NAME=${{ secrets.AZURE_KEYVAULT_NAME }}" >> $GITHUB_ENV
    echo "HAS_AZURE_KEYVAULT_NAME=$([[ -n "${{ secrets.AZURE_KEYVAULT_NAME }}" ]] && echo 'true' || echo 'false')" >> $GITHUB_ENV

# Usa variável de ambiente no conditional
- name: Confirm Key Vault usage
  if: env.HAS_AZURE_KEYVAULT_NAME == 'true'
  run: echo "Key Vault available but not used"
```

## Referências

- [GitHub Actions Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts)
- [GitHub Actions Expressions](https://docs.github.com/en/actions/learn-github-actions/expressions)
- [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)