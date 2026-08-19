#!/bin/bash

install() {
    kubectl create ns argo
    kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.7.6/install.yaml
    kubectl create serviceaccount argo-workflow -n argo
}


# 定义主函数
main() {
   echo "Start..............."


    install





    echo "End..............."
}

# 脚本入口：执行 main 函数并传递所有参数
main "$@"