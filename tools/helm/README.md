# Helm Chart — my-app

本 Chart 是 kustomize 示例 `tools/kustomize/` 的等效 Helm 实现，演示同一应用在两种工具下的配置对比。

## 目录结构

```
tools/helm/
├── my-app/
│   ├── Chart.yaml              # Chart 元信息
│   ├── values.yaml             # 默认值（对应 kustomize base）
│   ├── values-dev.yaml         # Dev 环境值（对应 overlays/dev）
│   ├── values-prod.yaml        # Prod 环境值（对应 overlays/prod）
│   └── templates/
│       ├── _helpers.tpl        # 模板辅助函数
│       ├── deployment.yaml     # Deployment 模板
│       └── service.yaml        # Service 模板
└── README.md
```

## Release 命名规范

格式：`{Org Name}-{App Name}-{Env Name}`

| 环境 | Release 名称 |
|------|-------------|
| Dev  | `org-myapp-dev` |
| Prod | `org-myapp-prod` |

## Kustomize 与 Helm 概念对照

| Kustomize | Helm | 说明 |
|-----------|------|------|
| `base/kustomization.yaml` | `values.yaml` | 公共默认配置 |
| `overlays/dev/kustomization.yaml` | `values-dev.yaml` | Dev 环境覆盖值 |
| `overlays/prod/kustomization.yaml` | `values-prod.yaml` | Prod 环境覆盖值 |
| `base/deployment.yaml` | `templates/deployment.yaml` | Deployment 资源定义 |
| `base/service.yaml` | `templates/service.yaml` | Service 资源定义 |
| `namePrefix` | Release name（`org-myapp-dev`） | 资源命名前缀 |
| `namespace` | `--namespace` 参数 | 部署命名空间 |
| `labels` / `commonLabels` | `values.labels` + helpers | 公共标签 |
| `images` | `image.repository` / `image.tag` | 镜像替换 |
| `replicas` | `replicaCount` | 副本数 |
| `patches`（env vars） | `env` map | 环境变量 |

## 使用方式

### 预览渲染结果

```bash
# 默认值
helm template org-myapp ./my-app

# Dev 环境
helm template org-myapp-dev ./my-app -f ./my-app/values-dev.yaml

# Prod 环境
helm template org-myapp-prod ./my-app -f ./my-app/values-prod.yaml
```

### 安装到集群

```bash
# Dev 环境（default 命名空间）
helm install org-myapp-dev ./my-app -f ./my-app/values-dev.yaml -n default

# Prod 环境（test-anquan 命名空间）
helm install org-myapp-prod ./my-app -f ./my-app/values-prod.yaml -n test-anquan
```

### List

```bash
helm list -A --filter 'org-myapp'
```

### 升级

```bash
helm upgrade org-myapp-dev ./my-app -f ./my-app/values-dev.yaml -n default
helm upgrade org-myapp-prod ./my-app -f ./my-app/values-prod.yaml -n test-anquan
```

### 卸载

```bash
helm uninstall org-myapp-dev -n default
helm uninstall org-myapp-prod -n test-anquan
```

## Dev 与 Prod 配置对比

| 配置项 | Dev | Prod |
|--------|-----|------|
| Release 名称 | `org-myapp-dev` | `org-myapp-prod` |
| 命名空间 | `default` | `test-anquan` |
| 副本数 | 1 | 2 |
| 镜像 | `m.daocloud.io/.../nginx:1.31` | `m.daocloud.io/.../nginx:1.27` |
| env | `dev` | `prod` |
| databaseURL | `mysql://dev-db:3306/myapp` | `mysql://prod-db:3306/myapp` |
| CPU 请求/限制 | 100m / 200m | 500m / 1000m |
| 内存请求/限制 | 128Mi / 256Mi | 512Mi / 1Gi |


## 关于多K8s集群连接问题

不同的K8s集群使用HELM_KUBECONTEXT, 或者kubeconfig参数：

export HELM_KUBECONTEXT=devops-ack

```bash
helm --kubeconfig=<KubeConfig Path> get ns
```