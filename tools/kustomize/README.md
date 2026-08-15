# Kustomize Deployment + Service 模板示例

本目录演示如何使用 [Kustomize](https://kustomize.io/) 的 **base + overlays** 模式对 Kubernetes Deployment + Service 进行多环境定制化管理。

## 目录结构

```
tools/kustomize/
├── base/                           # 基础配置（所有环境共享）
│   ├── kustomization.yaml          # 公共标签、注解、资源引用
│   ├── deployment.yaml             # Deployment 资源定义
│   └── service.yaml                # Service 资源定义
└── overlays/                       # 环境特定覆盖
    ├── dev/
    │   └── kustomization.yaml      # Dev 环境定制
    └── prod/
        └── kustomization.yaml      # Prod 环境定制
```

## 架构说明

```
                    ┌─────────────────────────┐
                    │      base (base/)        │
                    │  deployment + service    │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                                     │
     ┌────────▼─────────┐               ┌──────────▼────────┐
     │  overlays/dev    │               │  overlays/prod    │
     │  namePrefix:dev-  │               │  namePrefix:prod- │
     │  namespace:default │               │  namespace:test-  │
     │  env: dev         │               │  anquan           │
     │  nginx:1.31       │               │  env: prod        │
     │                   │               │  replicas: 2      │
     │                   │               │  nginx:1.27       │
     └──────────────────┘               └───────────────────┘
```

## 文件说明

### base

- **deployment.yaml** — 基础 Deployment 模板（nginx 容器，含占位环境变量 `env-name`、`DatabaseURL`，由 overlays 覆盖）
- **service.yaml** — 基础 Service 模板（ClusterIP，端口 80）
- **kustomization.yaml** — 基础配置，包含公共标签（`managed-by: kustomize`）、注解、资源引用

### overlays/dev

| 配置项 | 值 |
|--------|-----|
| `namePrefix` | `dev-` |
| `namespace` | `default` |
| `labels` | `env: dev` |
| `images` | `m.daocloud.io/docker.io/library/nginx:1.31`（国内加速源） |
| `env` | `dev` |
| `databaseURL` | `mysql://dev-db:3306/myapp` |

### overlays/prod

| 配置项 | 值 |
|--------|-----|
| `namePrefix` | `prod-` |
| `namespace` | `{Prod}` |
| `labels` | `env: prod` |
| `images` | `m.daocloud.io/docker.io/library/nginx:1.27` |
| `replicas` | `2` |
| `env` | `prod` |
| `databaseURL` | `mysql://prod-db:3306/myapp` |
| `resources` | 提升配额（CPU 500m-1000m，内存 512Mi-1Gi） |

## 使用方式

### 预览渲染结果

```bash
# Dev 环境
kubectl kustomize overlays/dev

# Prod 环境
kubectl kustomize overlays/prod
```

### 应用到集群

```bash
# 部署 Dev 环境
kubectl apply -k overlays/dev

# 部署 Prod 环境
kubectl apply -k overlays/prod
```

### 删除资源

```bash
# 删除 Dev 环境资源
kubectl delete -k overlays/dev

# 删除 Prod 环境资源
kubectl delete -k overlays/prod
```

### 查看资源状态

```bash
# Dev 环境
kubectl get deploy,svc,pods -n default -l env=dev

# Prod 环境
kubectl get deploy,svc,pods -n {Prod} -l env=prod
```

## Dev 与 Prod 配置对比

| 配置项 | Dev | Prod |
|--------|-----|------|
| Deployment 名称 | `dev-my-app` | `prod-my-app` |
| Service 名称 | `dev-my-app` | `prod-my-app` |
| 命名空间 | `default` | `{Prod}` |
| 副本数 | 1 | 2 |
| 镜像 | `m.daocloud.io/.../nginx:1.31` | `m.daocloud.io/.../nginx:1.27` |
| env | `dev` | `prod` |
| databaseURL | `mysql://dev-db:3306/myapp` | `mysql://prod-db:3306/myapp` |
| CPU 请求/限制 | 100m / 200m | 500m / 1000m |
| 内存请求/限制 | 128Mi / 256Mi | 512Mi / 1Gi |

## 扩展建议

- **新增环境**：复制 `overlays/dev/` 为 `overlays/staging/`，修改对应值即可
- **ConfigMap/Secret**：使用 `configMapGenerator` 按环境生成不同配置
- **Patch 精细控制**：可通过多个 patch 文件分别覆盖不同字段
- **Components 复用**：公共能力（如监控 sidecar）封装为 component，多 overlay 共享


## 关于多 K8s 集群连接问题

不同的 K8s 集群引用不同的 KubeConfig 文件，即使用 kubeconfig 参数：

```bash
kubectl --kubeconfig=<KubeConfig Path> get ns
```
