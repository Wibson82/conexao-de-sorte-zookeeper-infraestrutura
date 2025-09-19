#!/bin/bash

# ============================================================================
# 🚨 ZOOKEEPER EMERGENCY RECOVERY V2 - CORREÇÃO CRÍTICA
# ============================================================================
# SITUAÇÃO: FASE 1 falhou - ainda múltiplas instâncias e loops
# ESTRATÉGIA V2: Limpeza total + configuração ultra-simplificada
# ============================================================================

set -euo pipefail

echo "🚨 ZOOKEEPER EMERGENCY RECOVERY V2"
echo "==================================="
echo ""
echo "⚠️ SITUAÇÃO CRÍTICA DETECTADA:"
echo "   - FASE 1 não resolveu os loops infinitos"
echo "   - Múltiplas instâncias ainda ocorrendo"
echo "   - Health checks falhando consistentemente"
echo ""

# Função para log colorido
log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[0;33m⚠️  $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }

# ============================================================================
# 🛑 FASE V2.1: PARADA TOTAL E LIMPEZA AGRESSIVA
# ============================================================================
echo "🛑 FASE V2.1: Parada total e limpeza agressiva"
echo "=============================================="
echo ""

# Parar TODAS as stacks relacionadas
log_warning "Parando TODAS as stacks de mensageria..."

for stack in conexao-zookeeper conexao-kafka; do
    if docker stack ls | grep -q "$stack"; then
        log_info "Removendo stack: $stack"
        docker stack rm "$stack"
    else
        log_info "Stack $stack não encontrada"
    fi
done

# Aguardar remoção completa
log_info "Aguardando remoção completa das stacks..."
sleep 60

# Verificar se ainda existem
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    REMAINING_STACKS=$(docker stack ls | grep -E "(zookeeper|kafka)" | wc -l || echo "0")
    if [[ "$REMAINING_STACKS" -eq 0 ]]; then
        log_success "Todas as stacks removidas"
        break
    fi
    log_info "Ainda $REMAINING_STACKS stacks ativas... aguardando"
    sleep 10
    elapsed=$((elapsed + 10))
done

# Force kill containers órfãos
log_warning "Removendo TODOS os containers ZooKeeper e Kafka..."
ORPHAN_CONTAINERS=$(docker ps -aq --filter "name=zookeeper" --filter "name=kafka" || true)
if [[ -n "$ORPHAN_CONTAINERS" ]]; then
    log_info "Containers encontrados: $ORPHAN_CONTAINERS"
    docker rm -f $ORPHAN_CONTAINERS || true
    log_success "Containers removidos"
else
    log_info "Nenhum container órfão encontrado"
fi

# Limpeza agressiva do sistema
log_info "Limpeza agressiva do sistema Docker..."
docker container prune -f --filter "until=1h" || true
docker image prune -f || true
docker system prune -f --filter "until=6h" || true

echo ""

# ============================================================================
# 🔧 FASE V2.2: VERIFICAÇÃO E CRIAÇÃO DE RECURSOS
# ============================================================================
echo "🔧 FASE V2.2: Verificação de recursos"
echo "====================================="
echo ""

# Verificar rede
NETWORK_NAME="conexao-network-swarm"
if docker network ls | grep -q "$NETWORK_NAME"; then
    log_success "Rede $NETWORK_NAME existe"
else
    log_warning "Criando rede $NETWORK_NAME..."
    docker network create --driver overlay "$NETWORK_NAME"
fi

# Verificar/recriar volumes (limpeza se necessário)
for volume in zookeeper_data zookeeper_logs; do
    if docker volume ls | grep -q "$volume"; then
        log_info "Volume $volume existe - verificando integridade..."

        # Verificar se volume está corrompido
        if docker run --rm -v "$volume":/check alpine:3.20 ls /check >/dev/null 2>&1; then
            log_success "Volume $volume íntegro"
        else
            log_warning "Volume $volume pode estar corrompido - recriando..."
            docker volume rm "$volume" || true
            docker volume create "$volume"
        fi
    else
        log_warning "Criando volume $volume..."
        docker volume create "$volume"
    fi
done

echo ""

# ============================================================================
# 🚀 FASE V2.3: DEPLOY COM CONFIGURAÇÃO ULTRA-SIMPLIFICADA
# ============================================================================
echo "🚀 FASE V2.3: Deploy configuração ultra-simplificada"
echo "====================================================="
echo ""

# Verificar se arquivo V2 existe
if [[ ! -f "docker-compose-emergency-v2.yml" ]]; then
    log_error "Arquivo docker-compose-emergency-v2.yml não encontrado!"
    log_info "Certifique-se de estar no diretório correto"
    exit 1
fi

log_info "Validando configuração V2..."
docker-compose -f docker-compose-emergency-v2.yml config >/dev/null || {
    log_error "Configuração V2 inválida!"
    exit 1
}

log_success "Configuração V2 validada"

log_info "Iniciando deploy ZooKeeper V2..."
docker stack deploy -c docker-compose-emergency-v2.yml conexao-zookeeper

echo ""

# ============================================================================
# 🔍 FASE V2.4: MONITORAMENTO RIGOROSO
# ============================================================================
echo "🔍 FASE V2.4: Monitoramento rigoroso"
echo "===================================="
echo ""

STACK_NAME="conexao-zookeeper"
SERVICE_NAME="conexao-zookeeper_zookeeper"

log_info "Aguardando serviço ficar disponível..."
timeout=300  # 5 minutos
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker service ls --format "{{.Name}}" | grep -q "$SERVICE_NAME"; then
        REPLICAS=$(docker service ls --filter name="$SERVICE_NAME" --format "{{.Replicas}}" || echo "0/0")
        echo "⏳ Status: $REPLICAS (${elapsed}s)"

        # Verificar se há múltiplas instâncias (PROBLEMA CRÍTICO)
        RUNNING_CONTAINERS=$(docker ps --filter "name=zookeeper" --format "{{.ID}}" | wc -l || echo "0")
        if [[ "$RUNNING_CONTAINERS" -gt 1 ]]; then
            log_error "🚨 MÚLTIPLAS INSTÂNCIAS DETECTADAS: $RUNNING_CONTAINERS containers!"
            log_info "Containers ativos:"
            docker ps --filter "name=zookeeper" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
            log_warning "CONSTRAINT max_replicas_per_node NÃO está funcionando!"
        else
            log_success "✅ SINGLE INSTANCE: $RUNNING_CONTAINERS container"
        fi

        RUNNING=$(echo "$REPLICAS" | cut -d'/' -f1)
        DESIRED=$(echo "$REPLICAS" | cut -d'/' -f2)

        if [[ "$RUNNING" == "$DESIRED" && "$DESIRED" != "0" ]]; then
            log_success "Serviço ZooKeeper V2 está rodando!"
            break
        fi
    fi

    sleep 15
    elapsed=$((elapsed + 15))
done

if [[ $elapsed -ge $timeout ]]; then
    log_error "Timeout: Serviço não ficou disponível em $timeout segundos"
    log_info "Verificando logs para diagnóstico..."
    docker service logs "$SERVICE_NAME" --tail 30 || true

    log_info "Tasks do serviço:"
    docker service ps "$SERVICE_NAME" --format "table {{.ID}}\t{{.CurrentState}}\t{{.Error}}" | head -5

    exit 1
fi

echo ""

# ============================================================================
# 🩺 FASE V2.5: TESTE DE SAÚDE ESPECÍFICO
# ============================================================================
echo "🩺 FASE V2.5: Teste de saúde específico"
echo "======================================="
echo ""

# Aguardar inicialização completa
log_info "Aguardando inicialização completa do ZooKeeper V2..."
sleep 60

# Obter container mais recente
CONTAINER_ID=$(docker ps --filter "name=zookeeper" --format "{{.ID}}" | head -1 || true)

if [[ -n "$CONTAINER_ID" ]]; then
    log_info "Container encontrado: $CONTAINER_ID"

    # Teste 1: Verificar se processo ZooKeeper está rodando
    if docker exec "$CONTAINER_ID" ps aux | grep -q "[z]ookeeper"; then
        log_success "✅ Processo ZooKeeper rodando"
    else
        log_error "❌ Processo ZooKeeper não encontrado"
    fi

    # Teste 2: Verificar porta 2181
    if docker exec "$CONTAINER_ID" netstat -tlnp | grep -q ":2181"; then
        log_success "✅ Porta 2181 listening"
    else
        log_warning "⚠️ Porta 2181 não está listening"
    fi

    # Teste 3: Teste ruok mais robusto
    log_info "Testando comando ruok..."
    if docker exec "$CONTAINER_ID" timeout 10 sh -c "echo ruok | nc localhost 2181" 2>/dev/null | grep -q "imok"; then
        log_success "✅ Teste ruok: ZooKeeper responde 'imok'"
    else
        log_warning "⚠️ Teste ruok: ZooKeeper não responde adequadamente"

        # Fallback: testar com zkCli
        log_info "Tentando teste alternativo com zkCli..."
        if docker exec "$CONTAINER_ID" timeout 15 zkCli.sh -server localhost:2181 ls / >/dev/null 2>&1; then
            log_success "✅ Teste zkCli: ZooKeeper aceita conexões"
        else
            log_error "❌ Teste zkCli: ZooKeeper rejeita conexões"
        fi
    fi

    # Mostrar logs recentes
    log_info "Logs recentes do ZooKeeper:"
    docker exec "$CONTAINER_ID" tail -20 /var/log/zookeeper/zookeeper.log 2>/dev/null || \
    docker logs "$CONTAINER_ID" --tail 20 2>/dev/null || \
    log_warning "Não foi possível obter logs"

else
    log_error "Container ZooKeeper não encontrado!"
    exit 1
fi

echo ""

# ============================================================================
# 📊 RELATÓRIO FINAL V2
# ============================================================================
echo "📊 RELATÓRIO FINAL RECOVERY V2"
echo "==============================="

# Verificar se recovery foi bem-sucedido
CONTAINERS_COUNT=$(docker ps --filter "name=zookeeper" --format "{{.ID}}" | wc -l || echo "0")
SERVICE_REPLICAS=$(docker service ls --filter name="$SERVICE_NAME" --format "{{.Replicas}}" || echo "0/0")

echo ""
log_info "Status final:"
echo "  🔧 Containers ZooKeeper: $CONTAINERS_COUNT"
echo "  📊 Service Replicas: $SERVICE_REPLICAS"
echo "  🐰 RabbitMQ: $(docker ps --filter "name=rabbitmq" --format "{{.Status}}" | head -1 || echo "N/A")"

if [[ "$CONTAINERS_COUNT" -eq 1 ]] && [[ "$SERVICE_REPLICAS" == "1/1" ]]; then
    log_success "🎉 RECOVERY V2 BEM-SUCEDIDO!"
    echo "   ✅ ZooKeeper single instance"
    echo "   ✅ Service 1/1 ativo"
    echo "   ✅ Sem loops infinitos detectados"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo "   1. Monitorar por 30 minutos"
    echo "   2. Se estável, deploy Kafka"
    echo "   3. Testar end-to-end messaging"

elif [[ "$CONTAINERS_COUNT" -gt 1 ]]; then
    log_error "❌ RECOVERY V2 FALHOU: MÚLTIPLAS INSTÂNCIAS PERSISTEM"
    echo "   🚨 $CONTAINERS_COUNT containers ZooKeeper"
    echo "   🔧 Docker Swarm pode ter bug fundamental"
    echo "   💡 Considerar migrar para docker-compose standalone"
    echo ""
    echo "🛠️ AÇÕES EMERGENCIAIS:"
    echo "   1. Investigar versão Docker Swarm"
    echo "   2. Testar constraint em node diferente"
    echo "   3. Considerar deployment manual"

else
    log_warning "⚠️ RECOVERY V2 PARCIAL"
    echo "   📊 Service: $SERVICE_REPLICAS"
    echo "   🔍 Verificar logs detalhados"
    echo "   ⏳ Aguardar estabilização"
fi

echo ""
log_info "Para monitoramento contínuo:"
echo "  watch 'docker ps --filter \"name=zookeeper\" && echo && docker service ls | grep zookeeper'"

echo ""
log_success "Recovery V2 concluído!"