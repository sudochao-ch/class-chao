#!/bin/bash
PATH=/data/app/apache-maven-3.5.0/bin:/data/app/node-v8.12.0/bin:/data/app/jdk1.8.0_191/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ecs-user/.local/bin:/home/ecs-user/bin
export PATH

function set_project_name(){
#PROJECT 名称
PROJECT_NAME="dangjia_sale"
}

#定义目录
function set_dir(){
#脚本路径
SCRIPT_DIR=$(cd "$(dirname "$0")";pwd)
#CLONE+项目名称完整路径
PROJECT_DIR="${SCRIPT_DIR}/${PROJECT_NAME}"
#输出信息
echo "--->>PATH MOD->SCRIPT_DIR: ${SCRIPT_DIR}"
echo "--->>PATH MOD->PROJECT_NAME: ${PROJECT_NAME}"
echo "--->>PATH MOD->PROJECT_DIR: ${PROJECT_DIR}"
}

#分支
function set_branch_name(){
branchstr="test"
if [[ ${branch_Name} == "develop" ]];then
        branchstr="develop"
elif [[ ${branch_Name} == "test" ]];then
        branchstr="test"
elif [[ ${branch_Name} == "show" ]];then
        branchstr="show"
elif [[ ${branch_Name} == "master" ]];then
        branchstr="master"
fi
echo "--->>SET BRANCH ENV->分支变量为 ${branch_Name} ,设置后为 ${branchstr}"
}

#构建变量
function set_build(){
buildstr="build--test"
if [[ ${build_Name} == "test" ]];then
        buildstr="build--test"
elif [[ ${build_Name} == "prod" ]];then
        buildstr="build--prod"
fi
echo "--->>SET BUILD ENV->构建变量为 ${build_Name} ,设置后为 ${buildstr}"
}

#推送环境
function set_push_name(){
SERVER_NAME=""
case ${toServer_Name} in
	test)
		SERVER_NAME=$(toServer_Name)
	;;
	show)
		SERVER_NAME=$(toServer_Name)
	;;
	pro)
		SERVER_NAME=$(toServer_Name)
	;;
	*)
		SERVER_NAME=""
	;;
esac
}

# NPM 环境变量
function set_exec_env(){
env_node_path=${NODE_PATH}
if [[ $env_node_path ]];then
        echo "--->>PATH MOD->of Profile NODE_PATH :" `env | grep NODE_PATH`
        echo "--->>PATH MOD->of OS load NODE_PATH :" ${env_node_path}
        echo "--->>PATH MOD->exec node :" `whereis node`
        echo "--->>PATH MOD->exec  npm :" `whereis npm`
        echo "--->>PATH MOD->exec  vue :" `whereis vue`
else
        echo "--->>PATH MOD->ERROR. 没有找到 NODE_PATH 变量，请配置先."
        exit 0
fi
}

#获取Sources Code镜像
function main_getClone(){
cd ${SCRIPT_DIR}
if [[ -e ${PROJECT_DIR} ]];then
		echo "--->>SYNC MOD->存在Clone目录: ${PROJECT_DIR}"
		echo "--->>SYNC MOD->删除Clone目录: ${PROJECT_DIR}"
		rm -rf ${PROJECT_DIR}
fi
		cd ${SCRIPT_DIR}
		echo "--->>SYNC MOD->DIR ${PROJECT_DIR} 不存在."
		echo "--->>SYNC MOD->DIR ${SCRIPT_DIR}"
		echo "--->>SYNC MOD->Git Clone..."
		#git clone git@github.com:sudochao-ch/${PROJECT_NAME}.git
		git clone git@codehub-cn-south-1.devcloud.huaweicloud.com:djzx_qingqi00001/dangjia_sale.git
        #根据URL克隆项目地址
        echo "--->>SYNC MOD->Git Clone..."
        cd ${PROJECT_NAME}
        git branch -a
        #拿所有远程分支信息
        git checkout ${branchstr}
        #切换本地分支到远程
        git pull origin ${branchstr}
        #从远程地址更新代码到本地
        echo "--->> SYNC MOD->目录容量状态:" `du -sh`
		echo "--->> SYNC MOD->目录位置状态:" `pwd`
		cd ${SCRIPT_DIR}
		echo "--->> SYNC MOD->回到脚本目录: "`pwd`
        echo "--->> SYNC MOD->Git branch Get ...OK"
}

#构建函数
function main_build(){
cd ${SCRIPT_DIR}
if [[ -e ${PROJECT_NAME}_tmp777build_ ]]
then
        echo "--->> BUILD MOD->临时构建目录存在." ${PROJECT_NAME}_tmp777build_ 
        echo "--->> BUILD MOD->delete old " ${PROJECT_NAME}_tmp777build_
        rm -rf ${PROJECT_NAME}_tmp777build_
        echo "--->> BUILD MOD->拷贝新目录: ${PROJECT_NAME} -->> ${PROJECT_NAME}_tmp777build_"
		echo "--->> BUILD MOD->当前所在目录:"`pwd`
        cp -rf ${PROJECT_NAME} ${PROJECT_NAME}_tmp777build_
else
        echo "--->> BUILD MOD->临时构建目录不存在." ${PROJECT_NAME}_tmp777build_ 
        echo "--->> BUILD MOD->拷贝新目录: ${PROJECT_NAME} -->> ${PROJECT_NAME}_tmp777build_"
        cp -rf ${PROJECT_NAME} ${PROJECT_NAME}_tmp777build_
fi

cd ${PROJECT_NAME}_tmp777build_
# build start
echo "--->> vue-cli install...sources get registry.npm.taobao.org"
npm install -g vue-cli typescript --registry=http://registry.npm.taobao.org
# install dependencies NPM组件安装
echo "--->> npm mode install...sources get registry.npm.taobao.org"
npm install typescript --registry=http://registry.npm.taobao.org
# build for production with minification NPM构建编译
echo "--->> BUILD MOD->RUN BUILD "${buildstr}
npm run ${buildstr}
echo "--->> BUILD MOD->BUILD SUCCESS."

cd ${SCRIPT_DIR}
if [[ -e ${PROJECT_NAME}_${buildstr}_dist ]];then
		echo "--->> PUSH MOD->删除旧推送存储目录:./${PROJECT_NAME}_${buildstr}_dist"
		rm -rf ${PROJECT_NAME}_${buildstr}_dist
		echo "--->> PUSH MOD->从临时构建目录拷贝至推送目录:"
		cp -ra ./${PROJECT_NAME}_tmp777build_/dist ${PROJECT_NAME}_${buildstr}_dist
else
		echo "--->> PUSH MOD->推送目录不存在,从临时构建目录拷贝至推送目录:"
        cp -ra ./${PROJECT_NAME}_tmp777build_/dist ${PROJECT_NAME}_${buildstr}_dist
fi

cd ${SCRIPT_DIR}
echo "--->> PUSH MOD->回退到目录:" `pwd`
}

#推送数据到服务端
function main_pushSer(){
cd ${SCRIPT_DIR}
echo "===>>> PUSH MOD->设置同步推送到SERVER: ${SERVER_NAME}"
case ${SERVER_NAME} in
    test)
        CLIENT_IP="192.168.0.83"
		cd ${SCRIPT_DIR}
		echo "===>>> PUSH MOD->进入推送目录上层:${SCRIPT_DIR}"
        #echo -e "\e[36m===>>> 你选择推送到Server:${SERVER_NAME} . IP address: ${CLIENT_IP}"
        scp -rpq ${PROJECT_NAME}_${buildstr}_dist/* ecs-user@${CLIENT_IP}:/data/project/dangjia-sale/dist/
        echo "===>>> PUSH MOD->推送到远程SERVER...OK"
		ssh ecs-user@${CLIENT_IP} "sudo systemctl restart nginx"
		echo "===>>> PUSH MOD->重启远程SERVER:${SERVER_NAME} nginx...OK"
    ;;
    show)
		CLIENT_IP="192.168.0.48"
        cd ${SCRIPT_DIR}
        echo "===>>> PUSH MOD->进入推送目录上层:${SCRIPT_DIR}"
        #echo -e "\e[36m===>>> 你选择推送到Server:${SERVER_NAME} . IP address: ${CLIENT_IP}"
        scp -rpq ${PROJECT_NAME}_${buildstr}_dist/* ecs-user@${CLIENT_IP}:/data/project/dangjia-sale/dist/
        echo "===>>> PUSH MOD->推送到远程SERVER...OK"
		ssh ecs-user@${CLIENT_IP} "sudo systemctl restart nginx"
		echo "===>>> PUSH MOD->重启远程SERVER:${SERVER_NAME} nginx...OK"
    ;;
	pro)
		CLIENT_IP="192.168.0.229"
		CLIENT_IP1="192.168.0.52"
		cd ${SCRIPT_DIR}
        echo "===>>> PUSH MOD->进入推送目录上层:${SCRIPT_DIR}"
        #echo -e "\e[36m===>>> 你选择推送到Server:${SERVER_NAME} . IP address: ${CLIENT_IP}"
        scp -rpq ${PROJECT_NAME}_${buildstr}_dist/* ecs-user@${CLIENT_IP}:/data/project/dangjia-sale/dist/
		scp -rpq ${PROJECT_NAME}_${buildstr}_dist/* ecs-user@${CLIENT_IP1}:/data/project/dangjia-sale/dist/
        echo "===>>> PUSH MOD->推送到远程SERVER...OK"
		ssh ecs-user@${CLIENT_IP} "sudo systemctl restart nginx"
		ssh ecs-user@${CLIENT_IP1} "sudo systemctl restart nginx"
		echo "===>>> PUSH MOD->重启远程SERVER:${SERVER_NAME} nginx...OK"
    ;;
    *)
        echo "===>>> PUSH MOD->参数可能有错误，不推送."
    ;;  
#    4)
#		echo '你选择了 4'
#    ;;
#    *)
#		echo '你没有输入 1 到 4 之间的数字'
#    ;;
esac
}


###############开始###################
#input parameter
branch_Name=$1
build_Name=$2
toServer_Name=$3
echo "接收分支名 branchName:${branch_Name}"
echo "接收构建名 buildName:${build_Name}"
echo "接收推送名 toclientName:${toServer_Name}"

#setEnv
set_project_name
set_dir
set_branch_name
set_build
set_push_name
set_exec_env

#main
main_getClone
main_build
main_pushSer
echo "===>>>>> 主体程序结束 <<<<<==="
#sleep 10m 30s
#delCloneLocal