#!/bin/bash
# 注意修改 user 和 ip（云服务器公网）
# user=mangosteen
# ip=121.196.236.94
# ip=server1 #已映射
# 带默认值的声明
user=${user:-mangosteen}
ip=${ip:-server1}
# 时间作为唯一的部署版本号
time=$(date +'%Y%m%d-%H%M%S')
# 容器部署临时缓存目录
cache_dir=tmp/deploy_cache
# 压缩包文件名：容器中压缩包的完整输出路径
dist=$cache_dir/mangosteen-$time.tar.gz
# bin 获取当前脚本所在的绝对或相对路径（通常是容器项目 bin 目录）
current_dir=$(dirname $0)
# 远程部署目标：容器中部署目录的完整路径，time 为版本号
deploy_dir=/home/$user/deploys/$time
# 依赖配置文件：容器中 Gemfile 的完整路径
gemfile=$current_dir/../Gemfile
gemfile_lock=$current_dir/../Gemfile.lock
# 本地缓存的依赖包目录：容器中 vendor/cache 目录的完整路径
vendor_cache_dir=$current_dir/../vendor/cache

function title {
  echo
  echo "###############################################################################"
  echo "## $1"
  echo "###############################################################################"
  echo
}

title '打包源代码为压缩文件'
mkdir $cache_dir # 创建本地缓存目录
bundle cache # 将项目依赖的 Gem 包下载并缓存到 vendor/cache 目录，确保依赖不变时，远程机器无需再次联网下载
tar --exclude="tmp/cache/*" --exclude="tmp/deploy_cache/*" -czv -f $dist *

title '创建远程目录'
ssh $user@$ip "mkdir -p $deploy_dir/vendor/cache"  # 在服务器上递归创建部署目录和依赖缓存目录
title '1.上传源码压缩包和依赖配置文件'
scp $dist $user@$ip:$deploy_dir/
yes | rm $dist # 强制删除本地生成的压缩包，释放空间
scp $gemfile $user@$ip:$deploy_dir/  # 上传 Gemfile
scp $gemfile_lock $user@$ip:$deploy_dir/ # 上传 Gemfile.lock
scp -r $vendor_cache_dir $user@$ip:$deploy_dir/vendor/ # 递归上传所有缓存的依赖包 #待改进为上传压缩包后再解压
title '2.上传 Dockerfile'
scp $current_dir/../config/host.Dockerfile $user@$ip:$deploy_dir/Dockerfile # 上传并重命名 Docker 配置文件
title '3.上传 setup 脚本'
scp $current_dir/setup_remote.sh $user@$ip:$deploy_dir/ # 上传在远程服务器执行的安装脚本
title '4.上传版本号'
ssh $user@$ip "echo $time > $deploy_dir/version" # 在远程目录中写入当前版本号文件
title '执行远程脚本'
ssh $user@$ip "export version=$time; /bin/bash $deploy_dir/setup_remote.sh"
