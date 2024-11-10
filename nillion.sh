#!/bin/bash

# 设置版本号
current_version=20241109007

update_script() {
    # 指定URL
    update_url="https://raw.githubusercontent.com/breaddog100/nillion/main/nillion.sh"
    file_name=$(basename "$update_url")

    # 下载脚本文件
    tmp=$(date +%s)
    timeout 10s curl -s -o "$HOME/$tmp" -H "Cache-Control: no-cache" "$update_url?$tmp"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo "命令超时"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        echo "下载失败"
        return 1
    fi

    # 检查是否有新版本可用
    latest_version=$(grep -oP 'current_version=([0-9]+)' $HOME/$tmp | sed -n 's/.*=//p')

    if [[ "$latest_version" -gt "$current_version" ]]; then
        clear
        echo ""
        # 提示需要更新脚本
        printf "\033[31m脚本有新版本可用！当前版本：%s，最新版本：%s\033[0m\n" "$current_version" "$latest_version"
        echo "正在更新..."
        sleep 3
        mv $HOME/$tmp $HOME/$file_name
        chmod +x $HOME/$file_name
        exec "$HOME/$file_name"
    else
        # 脚本是最新的
        rm -f $tmp
    fi

}

# 部署节点
function install_node(){
    read -p "节点名称: " NODE_NAME

    # 安装Docker
	if ! command -v docker &> /dev/null; then
	    echo "Docker未安装，正在安装..."
	    # 更新包列表
	    sudo apt-get update
	    # 安装必要的包
	    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	    # 添加Docker的官方GPG密钥
	    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
	    # 添加Docker的APT仓库
	    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	    # 再次更新包列表
	    sudo apt-get update
	    # 安装Docker
	    sudo apt-get install -y docker-ce
        sudo groupadd docker
	    sudo usermod -aG docker $USER
	    echo "Docker安装完成。"
	else
        sudo groupadd docker
        sudo usermod -aG docker $USER
	    echo "Docker已安装。"
	fi
	
    # 初始化
    docker pull nillion/verifier:v1.0.1
    mkdir -p $HOME/nillion/verifier
    docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
    echo "请记录上面的Verifier account id和Verifier public key，用于注册"

    # 输出信息
    cat $HOME/nillion/verifier/credentials.json
    echo ""
    echo "请安装Keplr钱包并用上方秘钥恢复钱包，然后到https://faucet.testnet.nillion.com/领水"
    echo "查看钱包，水到账后打开：https://verifier.nillion.com/verifier 进行注册，然后启动节点"
}

# 启动节点
function start_node(){
    read -p "节点名称: " NODE_NAME
    RPC="https://testnet-nillion-rpc.lavenderfive.com"
    docker run --name $NODE_NAME -v $HOME/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint $RPC
}

# 停止节点
function stop_node(){
    read -p "节点名称: " NODE_NAME
    docker stop $NODE_NAME
}

# 节点日志
function logs_node(){
    read -p "节点名称: " NODE_NAME
    docker logs $NODE_NAME
}

# 查看块高度
function check_block(){
    curl -s https://testnet-nillion-rpc.lavenderfive.com/status |jq .result.sync_info
}

# 卸载节点
function uninstall_node(){
    echo "你确定要卸载节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            read -p "节点名称: " NODE_NAME
            echo "开始卸载节点程序..."
            sudo docker rm -f $NODE_NAME
            echo "节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 主菜单
function main_menu() {
	while true; do
	    clear
	    echo "===================Nillion 一键部署脚本==================="
		echo "当前版本：$current_version"
		echo "沟通电报群：https://t.me/lumaogogogo"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点 install_node"
        echo "2. 启动节点 start_node"
        echo "3. 停止节点 stop_node"
	    echo "4. 节点日志 logs_node"
        echo "5. 块高度 check_block"
        echo "6. 节点日志 logs_node"
        echo "1618. 卸载节点 uninstall_node"
	    echo "0. 退出脚本 exit"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_node ;;
        2) start_node ;;
        3) stop_node ;;
	    4) logs_node ;;
        5) check_block ;;
        6) logs_node ;;
        1618) uninstall_node ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 检查更新
update_script

# 显示主菜单
main_menu
