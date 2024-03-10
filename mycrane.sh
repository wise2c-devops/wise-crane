#!/bin/bash
# Check if crane and jq commands are installed
if ! command -v crane &> /dev/null; then
    echo "Error: crane command not found. Please install crane first."
    echo "错误: 未找到 crane 命令。请先安装 crane。"
    echo
    echo "Installation instructions for crane:"
    echo "  1. Download the latest release from https://github.com/google/go-containerregistry/releases"
    echo "  2. Extract the archive and add the binary to your PATH"
    echo
    echo "crane 安装方法:"
    echo "  1. 从 https://github.com/google/go-containerregistry/releases 下载最新版本"
    echo "  2. 解压缩并将二进制文件添加到 PATH 环境变量中"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq command not found. Please install jq first."
    echo "错误: 未找到 jq 命令。请先安装 jq。"
    echo
    echo "Installation instructions for jq (on Ubuntu/Debian):"
    echo "在 Ubuntu/Debian 系统上安装 jq 的方法:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install jq"
    echo
    echo "Installation instructions for jq (on CentOS/RHEL):"
    echo "在 CentOS/RHEL 系统上安装 jq 的方法:"
    echo "  sudo yum install jq"
    exit 1
fi

action=$1
arg2=$2

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <pull|push|manifest> <registry_image|tarfile> [<tarfile|registry_image>]"
    echo "e.g.: $0 pull grafana/grafana:10.4.0 grafana-10.4.0.tar"
    echo "      $0 push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0"
    echo "      $0 manifest 192.168.0.1/library/grafana:10.4.0"
    echo "      $0 manifest grafana-10.4.0.tar"
    echo
    echo "命令用法：$0 <pull|push|manifest> <镜像名|tar压缩包文件> [<tar压缩包文件|镜像名>]"
    echo "例如：$0 pull grafana/grafana:10.4.0 grafana-10.4.0.tar"
    echo "      $0 push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0"
    echo "      $0 manifest 192.168.0.1/library/grafana:10.4.0"
    echo "      $0 manifest grafana-10.4.0.tar"
    exit 1
fi

if [ "$action" != "pull" ] && [ "$action" != "push" ] && [ "$action" != "manifest" ]; then
    echo "Invalid action: $action"
    echo "无效的参数: $action"
    exit 1
fi

if [ "$action" = "pull" ] || [ "$action" = "push" ]; then
    if [ "$#" != 3 ]; then
        echo "Usage: $0 <pull|push|manifest> <registry_image|tarfile> [<tarfile|registry_image>]"
        echo "e.g.: $0 pull grafana/grafana:10.4.0 grafana-10.4.0.tar"
        echo "      $0 push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0"
        echo "      $0 manifest 192.168.0.1/library/grafana:10.4.0"
        echo "      $0 manifest grafana-10.4.0.tar"
        echo
        echo "命令用法：$0 <pull|push|manifest> <镜像名|tar压缩包文件> [<tar压缩包文件|镜像名>]"
        echo "例如：$0 pull grafana/grafana:10.4.0 grafana-10.4.0.tar"
        echo "      $0 push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0"
        echo "      $0 manifest 192.168.0.1/library/grafana:10.4.0"
        echo "      $0 manifest grafana-10.4.0.tar"
        exit 1
    fi 
fi

if [ "$action" = "manifest" ]; then
    if [[ "$arg2" == *".tar" ]]; then
        if [ ! -f "$arg2" ]; then
            echo "Error: Tarfile $arg2 does not exist."
            echo "错误: tar压缩包 $arg2 不存在。"
            exit 1
        fi
        temp_dir=$(mktemp -d)
        tar zxf "$arg2" -C "$temp_dir"
        if [ -z "$(find "$temp_dir/" -maxdepth 1 -mindepth 1 -type d)" ]; then
            echo "Error: Invalid tarfile $arg2."
            echo "错误: 无效的tar压缩包 $arg2。"
            rm -rf "$temp_dir"
            exit 1
        fi
        echo "The platform and architecture of $arg2:"
        echo "$arg2 的平台架构信息如下："
        echo
        cat "$(find "$temp_dir/" -maxdepth 1 -mindepth 1 -type d)/index.json" | jq -r '.manifests[] | .platform | "platform of \(.os)/\(.architecture)" + (if .variant then " \(.variant)" else "" end)'
        echo
        rm -rf "$temp_dir"
    else
        if ! crane manifest "$arg2" &> /dev/null; then
            echo "Error: Image $arg2 does not exist."
            echo "错误: 镜像 $arg2 不存在。"
            exit 1
        fi
        echo "The platform and architecture of $arg2:"
        echo "$arg2 的平台架构信息如下："
        echo
        crane manifest "$arg2" | jq -r '.manifests[] | .platform | "platform of \(.os)/\(.architecture)" + (if .variant then " \(.variant)" else "" end)'
        echo
    fi
    exit 0
fi

if [ "$action" = "pull" ]; then
    image=$2
    tarfile=$3
    if ! crane manifest "$image" &> /dev/null; then
        echo "Error: Image $image does not exist or is invalid."
        echo "错误: 镜像 $image 不存在或无效。"
        exit 1
    else
        dir=$(basename "$tarfile" .tar)
        mkdir -p "$dir"
        crane pull --format=oci --platform linux/amd64 "$image" "$dir/"
        crane pull --format=oci --platform linux/arm64 "$image" "$dir/"
        tar zcf "$tarfile" "$dir"
        rm -rf "$dir"
    fi  
elif [ "$action" = "push" ]; then
    tarfile=$2
    image=$3
    if [ ! -f "$tarfile" ]; then
        echo "Error: Tarfile $tarfile does not exist."
        echo "错误: tar压缩包 $tarfile 不存在。"
        exit 1
    fi
    temp_dir=$(mktemp -d)
    tar zxf "$tarfile" -C "$temp_dir"
    if [ -z "$(find "$temp_dir/" -maxdepth 1 -mindepth 1 -type d)" ]; then
        echo "Error: Invalid tarfile $tarfile."
        echo "错误: 无效的tar压缩包 $tarfile。"
        rm -rf "$temp_dir"
        exit 1
    fi
    if ! crane push --index "$(find "$temp_dir/" -maxdepth 1 -mindepth 1 -type d)/" "$image"; then
        echo "Error: Cannot access registry for image $image."
        echo "错误: 无法访问镜像 $image 的仓库。"
        rm -rf "$temp_dir"
        exit 1
    fi
    rm -rf "$temp_dir"
fi
