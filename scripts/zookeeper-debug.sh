#!/bin/bash

# ============================================================================
# 🔧 ZOOKEEPER DEBUG SCRIPT - FASE 1 EMERGENCY
# ============================================================================
# Criado para diagnosticar e corrigir loops infinitos do ZooKeeper
# Data: 19/09/2025
# ============================================================================

set -euo pipefail

echo "🔍 ZOOKEEPER DEBUG & RECOVERY SCRIPT"
echo "====================================="
echo ""

# Função para log colorido
log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[0;33m⚠️  $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }

# 1. DIAGNÓSTICO DE MÚLTIPLAS INSTÂNCIAS
echo "🔍 FASE 1: Verificando múltiplas instâncias..."
log_info "Buscando containers ZooKeeper ativos..."

ZOOKEEPER_CONTAINERS=$(docker ps --filter "name=zookeeper" --format "{{.ID}} {{.Names}} {{.Status}}" || true)

if [[ -n "$ZOOKEEPER_CONTAINERS" ]]; then
    log_warning "Containers ZooKeeper encontrados:"
    echo "$ZOOKEEPER_CONTAINERS"

    # Contar quantos containers
    CONTAINER_COUNT=$(echo "$ZOOKEEPER_CONTAINERS" | wc -l)
    if [[ $CONTAINER_COUNT -gt 1 ]]; then
        log_error "PROBLEMA: $CONTAINER_COUNT containers ZooKeeper rodando simultaneamente!"
        log_info "Isso explica os loops infinitos - conflito de recursos"
    fi
else
    log_info "Nenhum container ZooKeeper ativo encontrado"
fi

echo ""

# 2. VERIFICAR STACK SWARM
echo "🔍 FASE 2: Verificando stack Docker Swarm..."
ZOOKEEPER_STACK=$(docker stack ls --format "{{.Name}}" | grep zookeeper || true)

if [[ -n "$ZOOKEEPER_STACK" ]]; then
    log_success "Stack encontrada: $ZOOKEEPER_STACK"

    # Verificar serviços na stack
    log_info "Serviços na stack:"
    docker stack services "$ZOOKEEPER_STACK" --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}"

    # Verificar tasks
    log_info "Tasks do ZooKeeper:"
    docker service ps "${ZOOKEEPER_STACK}_zookeeper" --no-trunc --format "table {{.ID}}\t{{.CurrentState}}\t{{.Error}}"

else
    log_warning "Nenhuma stack ZooKeeper encontrada"
fi

echo ""

# 3. VERIFICAR VOLUMES E REDE
echo "🔍 FASE 3: Verificando recursos Docker..."

# Volumes
log_info "Verificando volumes ZooKeeper:"
docker volume ls | grep zookeeper || log_warning "Nenhum volume ZooKeeper encontrado"

# Rede
log_info "Verificando rede conexao-network-swarm:"
if docker network ls | grep -q "conexao-network-swarm"; then
    log_success "Rede conexao-network-swarm existe"
else
    log_error "Rede conexao-network-swarm NÃO encontrada!"
fi

echo ""

# 4. ANÁLISE DE LOGS CRÍTICOS
echo "🔍 FASE 4: Analisando logs para identificar causa raiz..."

if [[ -n "$ZOOKEEPER_STACK" ]]; then
    log_info "Últimos logs do ZooKeeper (últimas 50 linhas):"
    docker service logs "${ZOOKEEPER_STACK}_zookeeper" --tail 50 2>/dev/null || log_warning "Não foi possível obter logs"
fi

echo ""

# 5. VERIFICAÇÃO DE SAÚDE DO SISTEMA
echo "🔍 FASE 5: Verificação de saúde do sistema..."

log_info "Uso de memória do Docker:"
docker system df 2>/dev/null || log_warning "Não foi possível obter uso de recursos"

log_info "Serviços Docker Swarm ativos:"
docker service ls --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}" 2>/dev/null || log_warning "Não foi possível listar serviços"

echo ""

# 6. RECOMENDAÇÕES DE CORREÇÃO
echo "🛠️  RECOMENDAÇÕES DE CORREÇÃO:"
echo "=============================="
echo ""

if [[ -n "$ZOOKEEPER_CONTAINERS" ]]; then
    echo "1. 🚨 PARAR TODAS AS INSTÂNCIAS:"
    echo "   docker stack rm $ZOOKEEPER_STACK"
    echo "   # Aguardar 60 segundos para limpeza completa"
    echo ""
fi

echo "2. 🧹 LIMPAR RECURSOS ÓRFÃOS:"
echo "   docker container prune -f"
echo "   docker system prune -f"
echo ""

echo "3. 🔧 RECRIAR VOLUMES (se necessário):"
echo "   docker volume create zookeeper_data"
echo "   docker volume create zookeeper_logs"
echo ""

echo "4. 🚀 REDEPLOY COM NOVA CONFIGURAÇÃO:"
echo "   docker stack deploy -c docker-compose.yml conexao-zookeeper"
echo ""

echo "5. 🔍 MONITORAR SAÚDE:"
echo "   watch 'docker service ls | grep zookeeper'"
echo "   docker service logs conexao-zookeeper_zookeeper -f"
echo ""

log_success "Debug completo! Use as recomendações acima para corrigir o ZooKeeper."