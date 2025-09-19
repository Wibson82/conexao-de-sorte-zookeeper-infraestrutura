#!/bin/bash

# ============================================================================
# 🚀 ZOOKEEPER RECOVERY SCRIPT - FASE 1 EMERGENCY
# ============================================================================
# Script para recuperação automática do ZooKeeper com single-instance constraint
# Data: 19/09/2025
# ============================================================================

set -euo pipefail

echo "🚀 ZOOKEEPER RECOVERY SCRIPT"
echo "============================="
echo ""

# Função para log colorido
log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[0;33m⚠️  $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }

# Configurações
STACK_NAME="conexao-zookeeper"
SERVICE_NAME="conexao-zookeeper_zookeeper"
NETWORK_NAME="conexao-network-swarm"

# 1. PARAR TODAS AS INSTÂNCIAS EXISTENTES
echo "🛑 FASE 1: Parando todas as instâncias ZooKeeper..."

if docker stack ls | grep -q "$STACK_NAME"; then
    log_warning "Stack $STACK_NAME encontrada - removendo..."
    docker stack rm "$STACK_NAME"

    log_info "Aguardando remoção completa da stack..."
    timeout=120
    elapsed=0
    while docker stack ls | grep -q "$STACK_NAME" && [ $elapsed -lt $timeout ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        echo "⏳ Aguardando... ($elapsed/$timeout segundos)"
    done

    if docker stack ls | grep -q "$STACK_NAME"; then
        log_error "Stack ainda existe após $timeout segundos - intervenção manual necessária"
        exit 1
    else
        log_success "Stack removida com sucesso"
    fi
else
    log_info "Nenhuma stack ZooKeeper encontrada"
fi

# Limpar containers órfãos
log_info "Limpando containers órfãos relacionados ao ZooKeeper..."
ORPHAN_CONTAINERS=$(docker ps -a --filter "name=zookeeper" -q || true)
if [[ -n "$ORPHAN_CONTAINERS" ]]; then
    log_warning "Removendo containers órfãos: $ORPHAN_CONTAINERS"
    docker rm -f $ORPHAN_CONTAINERS || true
else
    log_success "Nenhum container órfão encontrado"
fi

echo ""

# 2. VERIFICAR E CRIAR RECURSOS NECESSÁRIOS
echo "🔧 FASE 2: Verificando recursos necessários..."

# Verificar rede
if docker network ls | grep -q "$NETWORK_NAME"; then
    log_success "Rede $NETWORK_NAME existe"
else
    log_warning "Criando rede $NETWORK_NAME..."
    docker network create --driver overlay "$NETWORK_NAME"
fi

# Verificar/criar volumes
for volume in zookeeper_data zookeeper_logs; do
    if docker volume ls | grep -q "$volume"; then
        log_success "Volume $volume existe"
    else
        log_warning "Criando volume $volume..."
        docker volume create "$volume"
    fi
done

echo ""

# 3. LIMPAR RECURSOS DOCKER
echo "🧹 FASE 3: Limpeza de recursos Docker..."

log_info "Limpando containers parados..."
docker container prune -f --filter "until=1h" || true

log_info "Limpando imagens dangling..."
docker image prune -f || true

log_success "Limpeza concluída"

echo ""

# 4. DEPLOY DA NOVA CONFIGURAÇÃO
echo "🚀 FASE 4: Deploy da nova configuração ZooKeeper..."

# Verificar se docker-compose.yml existe
if [[ ! -f "docker-compose.yml" ]]; then
    log_error "Arquivo docker-compose.yml não encontrado no diretório atual"
    log_info "Certifique-se de estar no diretório conexao-de-sorte-zookeeper-infraestrutura"
    exit 1
fi

log_info "Validando configuração do docker-compose.yml..."
docker-compose config > /dev/null || {
    log_error "Configuração inválida no docker-compose.yml"
    exit 1
}

log_success "Configuração validada"

log_info "Iniciando deploy da stack $STACK_NAME..."
docker stack deploy -c docker-compose.yml "$STACK_NAME"

echo ""

# 5. MONITORAMENTO E VALIDAÇÃO
echo "🔍 FASE 5: Monitoramento e validação..."

log_info "Aguardando serviço ficar disponível..."
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker service ls --format "{{.Name}}" | grep -q "$SERVICE_NAME"; then
        REPLICAS=$(docker service ls --filter name="$SERVICE_NAME" --format "{{.Replicas}}" || echo "0/0")
        RUNNING=$(echo "$REPLICAS" | cut -d'/' -f1)
        DESIRED=$(echo "$REPLICAS" | cut -d'/' -f2)

        echo "⏳ Replicas: $RUNNING/$DESIRED (${elapsed}s)"

        if [[ "$RUNNING" == "$DESIRED" && "$DESIRED" != "0" ]]; then
            log_success "Serviço ZooKeeper está rodando!"
            break
        fi
    fi

    sleep 10
    elapsed=$((elapsed + 10))
done

if [[ $elapsed -ge $timeout ]]; then
    log_error "Timeout: Serviço não ficou disponível em $timeout segundos"
    log_info "Verificando logs para diagnóstico..."
    docker service logs "$SERVICE_NAME" --tail 20 || true
    exit 1
fi

echo ""

# 6. TESTE DE CONECTIVIDADE
echo "🩺 FASE 6: Teste de saúde do ZooKeeper..."

# Aguardar um pouco para o ZooKeeper inicializar completamente
log_info "Aguardando inicialização completa do ZooKeeper..."
sleep 30

# Obter ID do container
CONTAINER_ID=$(docker ps --filter "name=zookeeper" --format "{{.ID}}" | head -1 || true)

if [[ -n "$CONTAINER_ID" ]]; then
    log_info "Testando conectividade do ZooKeeper..."

    # Teste 1: ruok command
    if docker exec "$CONTAINER_ID" sh -c "echo 'ruok' | nc localhost 2181" | grep -q "imok"; then
        log_success "✅ Teste 'ruok': ZooKeeper responde corretamente"
    else
        log_warning "⚠️ Teste 'ruok': ZooKeeper não responde adequadamente"
    fi

    # Teste 2: stats command
    if docker exec "$CONTAINER_ID" sh -c "echo 'stats' | nc localhost 2181" | grep -q "Mode:"; then
        log_success "✅ Teste 'stats': ZooKeeper em modo standalone"
    else
        log_warning "⚠️ Teste 'stats': Problema com modo ZooKeeper"
    fi

    # Mostrar estatísticas
    log_info "Estatísticas do ZooKeeper:"
    docker exec "$CONTAINER_ID" sh -c "echo 'stat' | nc localhost 2181" || log_warning "Não foi possível obter estatísticas"

else
    log_warning "Container ZooKeeper não encontrado para testes"
fi

echo ""

# 7. RELATÓRIO FINAL
echo "📊 RELATÓRIO FINAL"
echo "=================="

log_info "Status dos serviços:"
docker service ls --filter name="zookeeper" --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"

echo ""
log_info "Tasks do serviço ZooKeeper:"
docker service ps "$SERVICE_NAME" --format "table {{.ID}}\t{{.CurrentState}}\t{{.Error}}" | head -5

echo ""
log_info "Logs recentes (últimas 10 linhas):"
docker service logs "$SERVICE_NAME" --tail 10 2>/dev/null || log_warning "Não foi possível obter logs"

echo ""
if docker service ls --filter name="$SERVICE_NAME" --format "{{.Replicas}}" | grep -q "1/1"; then
    log_success "🎉 RECOVERY COMPLETO! ZooKeeper está funcionando corretamente."
    log_info "Próximo passo: Validar conectividade do Kafka"
else
    log_warning "⚠️ Recovery parcial. Verificar logs para diagnóstico adicional."
fi

echo ""
log_info "Para monitoramento contínuo:"
echo "  docker service logs $SERVICE_NAME -f"
echo "  watch 'docker service ls | grep zookeeper'"