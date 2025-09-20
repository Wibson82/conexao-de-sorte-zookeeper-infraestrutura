# Configuração do Repositório - Zookeeper Infrastructure

## 🔧 Configuração Necessária (Repository Variables)

Este workflow requer as seguintes **Repository Variables** (não secrets, conforme política):

### Identificadores Azure (OIDC)
- `AZURE_CLIENT_ID` - Client ID da aplicação Azure para autenticação OIDC
- `AZURE_TENANT_ID` - Tenant ID do Azure AD
- `AZURE_SUBSCRIPTION_ID` - Subscription ID da Azure

### Configurações Opcionais
- `AZURE_KEYVAULT_NAME` - Nome do Key Vault (opcional, não utilizado neste projeto)
- `AZURE_KEYVAULT_ENDPOINT` - Endpoint customizado do Key Vault (opcional)

## 🚨 Importante: Não usar Secrets para IDs

Conforme a política de segurança:
- **AZURE_CLIENT_ID**, **AZURE_TENANT_ID**, **AZURE_SUBSCRIPTION_ID** devem ser **Variables** (não Secrets)
- Estes são identificadores, não segredos
- Usar Secrets apenas quando a política explicitamente exigir

## 📝 Como Configurar

1. Vá para Settings → Secrets and variables → Actions
2. Clique na aba "Variables"
3. Adicione as variáveis listadas acima
4. **NÃO** adicione estas como Secrets

## 🔒 Segurança

- O workflow aplica `::add-mask::` mesmo para IDs como proteção adicional
- Nenhum segredo real é exposto nos logs
- Zookeeper não requer segredos externos para este deploy básico

## ✅ Verificação

O workflow validará automaticamente se as variáveis estão configuradas corretamente.
Se faltar alguma, o erro será claro sobre quais variáveis estão ausentes.