#!/bin/bash

# Redis on K8s 部署脚本

set -e

NAMESPACE="redis"

echo "=========================================="
echo "🚀 部署 Redis 集群到 Kubernetes"
echo "=========================================="

# 部署
deploy() {
    echo "📦 创建命名空间..."
    kubectl apply -f namespace.yaml
    
    echo "📦 创建配置..."
    kubectl apply -f configmap.yaml
    
    echo "📦 部署 Master..."
    kubectl apply -f master/
    
    echo "⏳ 等待 Master 就绪..."
    kubectl wait --for=condition=ready pod -l role=master -n ${NAMESPACE} --timeout=120s
    
    echo "📦 部署 Replica..."
    kubectl apply -f replica/
    
    echo "⏳ 等待 Replica 就绪..."
    kubectl wait --for=condition=ready pod -l role=replica -n ${NAMESPACE} --timeout=120s
    
    echo "📦 部署 Sentinel..."
    kubectl apply -f sentinel/
    
    echo "⏳ 等待 Sentinel 就绪..."
    kubectl wait --for=condition=ready pod -l role=sentinel -n ${NAMESPACE} --timeout=120s
    
    echo ""
    echo "✅ 部署完成！"
    echo ""
    status
}

# 查看状态
status() {
    echo "📊 Pod 状态:"
    kubectl get pods -n ${NAMESPACE} -o wide
    echo ""
    echo "📊 Service 状态:"
    kubectl get svc -n ${NAMESPACE}
    echo ""
    echo "📊 主从信息:"
    kubectl exec redis-master-0 -n ${NAMESPACE} -- redis-cli -a redis123 INFO replication 2>/dev/null | grep -E "role|connected_slaves|slave[0-9]"
}

# 测试连接
test() {
    echo "🧪 测试 Redis 连接..."
    echo ""
    
    echo "1. 测试 Master 写入:"
    kubectl exec redis-master-0 -n ${NAMESPACE} -- redis-cli -a redis123 SET test_key "hello from k8s"
    
    echo "2. 测试 Master 读取:"
    kubectl exec redis-master-0 -n ${NAMESPACE} -- redis-cli -a redis123 GET test_key
    
    echo "3. 测试 Replica 读取:"
    kubectl exec redis-replica-0 -n ${NAMESPACE} -- redis-cli -a redis123 GET test_key
    
    echo "4. 测试 Sentinel:"
    kubectl exec redis-sentinel-0 -n ${NAMESPACE} -- redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
    
    echo ""
    echo "✅ 测试完成！"
}

# 清理
cleanup() {
    echo "🧹 清理 Redis 集群..."
    kubectl delete -f sentinel/ 2>/dev/null || true
    kubectl delete -f replica/ 2>/dev/null || true
    kubectl delete -f master/ 2>/dev/null || true
    kubectl delete -f configmap.yaml 2>/dev/null || true
    kubectl delete pvc -l app=redis -n ${NAMESPACE} 2>/dev/null || true
    kubectl delete -f namespace.yaml 2>/dev/null || true
    echo "✅ 清理完成！"
}

# 扩容 Replica
scale_replica() {
    replicas=${1:-3}
    echo "📈 扩容 Replica 到 ${replicas} 个..."
    kubectl scale statefulset redis-replica --replicas=${replicas} -n ${NAMESPACE}
    kubectl get pods -n ${NAMESPACE} -w
}

# 帮助
help() {
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  deploy   部署 Redis 集群"
    echo "  status   查看状态"
    echo "  test     测试连接"
    echo "  cleanup  清理资源"
    echo "  scale N  扩容 Replica 到 N 个"
    echo ""
}

case "$1" in
    deploy)
        deploy
        ;;
    status)
        status
        ;;
    test)
        test
        ;;
    cleanup)
        cleanup
        ;;
    scale)
        scale_replica $2
        ;;
    *)
        help
        ;;
esac
