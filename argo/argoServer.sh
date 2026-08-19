#!/bin/bash

install() {
    kubectl create ns argo
    kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.7.6/install.yaml
    kubectl create serviceaccount argo-workflow -n argo
}

updateServer() {
    kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server",
  "--secure=false"
]},
{"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value": "HTTP"}
]'
}

forward() {
    kubectl -n argo port-forward --address 0.0.0.0 svc/argo-server 2746:2746 > /dev/null &
}


# 定义主函数
main() {
   echo "Start..............."


    updateServer





    echo "End..............."
}

# 脚本入口：执行 main 函数并传递所有参数
main "$@"