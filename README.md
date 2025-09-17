# 🔧 Conexão de Sorte - Zookeeper Infrastructure

Infraestrutura Zookeeper standalone para coordenação do Apache Kafka com Docker Swarm.

## 📋 **Características**

- ✅ **Docker Swarm** deployment
- ✅ **Overlay encrypted network** para segurança
- ✅ **Named volumes** com placement constraints
- ✅ **Health checks** otimizados para produção
- ✅ **Workflows CI/CD** baseados no padrão Traefik

## 🚀 **Deployment**

```bash
# Deploy automático via GitHub Actions
git push origin main

# Deploy manual
docker stack deploy -c docker-compose.yml conexao-zookeeper
```

## 🔍 **Health Check**

```bash
# Verificar se Zookeeper responde
docker exec CONTAINER_ID bash -c "echo ruok | nc localhost 2181"
# Resposta esperada: imok
```

## 📊 **Monitoramento**

- **Porta**: 2181 (ZooKeeper client port)
- **Network**: conexao-network-swarm
- **Volumes**: zookeeper_data, zookeeper_logs

## ⚙️ **Configuração**

- **ZOOKEEPER_CLIENT_PORT**: 2181
- **ZOOKEEPER_TICK_TIME**: 2000
- **ZOOKEEPER_SYNC_LIMIT**: 2

---

**Data**: 17/09/2025 às 04:35 BRT
**Versão**: 1.0.0