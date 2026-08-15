# Kustomize Pod 模板示例

本目录演示如何使用 [Kustomize](https://kustomize.io/) 的 **base + overlays** 模式对 Kubernetes Pod 资源进行多环境定制化管理。

## 目录结构

```
tools/kustomize/
├── kustomization.yaml          # base 基础配置（所有环境共享）
├── pod.yaml                    # 基础 Pod 资源定义
└── overlays/
    ├── dev/
    │   └── kustomization.yaml  # Dev 环境定制
    └── prod/
        └── kustomization.yaml  # Prod 环境定制
```

## 架构说明

```
                    ┌─────────────────┐
                    │   base (根目录)   │
                    │  kustomization   │
                    │  + pod.yaml      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │  overlays/dev   │           │  overlays/prod  │
     │  namePrefix:dev  │           │  namePrefix:prod │
     │  namespace:default│         │  namespace:test-anquan│
     │  env: dev        │           │  env: prod       │
     └─────────────────┘           └─────────────────┘
```

## 文件说明

### base（根目录）

- **pod.yaml** — 基础 Pod 模板，使用占位默认值（`env-name`、`DatabaseURL`），由 overlays 覆盖
- **kustomization.yaml** — 基础配置，只包含所有环境共享的设置（公共标签、注解、资源引用）

### overlays/dev

| 配置项 | 值 |
|--------|-----|
| `namePrefix` | `dev-` |
| `namespace` | `default` |
| `labels` | `env: dev` |
| `images` | `m.daocloud.io/docker.io/library/nginx:1.27`（国内加速源） |
| `env` | `dev` |
| `databaseURL` | `mysql://dev-db:3306/myapp` |

### overlays/prod

| 配置项 | 值 |
|--------|-----|
| `namePrefix` | `prod-` |
| `namespace` | `test-anquan` |
| `labels` | `env: prod` |
| `images` | `m.daocloud.io/docker.io/library/nginx:1.27`（国内加速源） |
| `env` | `prod` |
| `databaseURL` | `mysql://prod-db:3306/myapp` |
| `resources` | 提升配额（CPU 500m-1000m，内存 512Mi-1Gi） |

## 使用方式

### 预览 Dev 环境

```bash
kubectl kustomize overlays/dev
```

### 预览 Prod 环境

```bash
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

### 查看 Pod 状态

```bash
# Dev 环境
kubectl get pods -n default -l env=dev

# Prod 环境
kubectl get pods -n test-anquan -l env=prod
```

## Dev 与 Prod 配置对比

| 配置项 | Dev | Prod |
|--------|-----|------|
| Pod 名称 | `dev-my-pod` | `prod-my-pod` |
| 命名空间 | `default` | `test-anquan` |
| 镜像 | `m.daocloud.io/.../nginx:1.27` | `m.daocloud.io/.../nginx:1.27` |
| env | `dev` | `prod` |
| databaseURL | `mysql://dev-db:3306/myapp` | `mysql://prod-db:3306/myapp` |
| CPU 请求/限制 | 100m / 200m | 500m / 1000m |
| 内存请求/限制 | 128Mi / 256Mi | 512Mi / 1Gi |

## 扩展建议

- **新增环境**：复制 `overlays/dev/` 为 `overlays/staging/`，修改对应值即可
- **ConfigMap/Secret**：使用 `configMapGenerator` 按环境生成不同配置
- **Patch 精细控制**：可通过多个 patch 文件分别覆盖不同字段


## 关于多K8s集群连接问题

不同的K8s集群引用不同的KubeConfig文件，即使用kubeconfig参数：

```bash
kubectl --kubeconfig=<KubeConfig Path> get ns
```