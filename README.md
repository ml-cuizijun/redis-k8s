# Redis on Kubernetes 部署示例

## 目录结构

```
redis-k8s/
├── namespace.yaml
├── configmap.yaml
├── master/
│   ├── statefulset.yaml
│   └── service.yaml
├── replica/
│   ├── statefulset.yaml
│   └── service.yaml
├── sentinel/
│   ├── statefulset.yaml
│   └── service.yaml
└── README.md
```

## 快速部署

```bash
# 一键部署
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f master/
kubectl apply -f replica/
kubectl apply -f sentinel/

# 查看状态
kubectl get pods -n redis
kubectl get svc -n redis
```

## 连接测试

```bash
# 连接 Master
kubectl exec -it redis-master-0 -n redis -- redis-cli -a redis123

# 查看主从信息
INFO replication

# 通过 Sentinel 获取 Master 地址
kubectl exec -it redis-sentinel-0 -n redis -- redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

## 应用连接字符串

```
# Sentinel 模式连接（推荐）
sentinel://redis123@redis-sentinel.redis.svc.cluster.local:26379/mymaster

# 直连 Master（不推荐，无法自动故障转移）
redis://:redis123@redis-master.redis.svc.cluster.local:6379
```
