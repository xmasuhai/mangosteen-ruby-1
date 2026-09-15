#!/bin/bash

### 检查目标目录并动态设置基础路径
if [ -d "/IdeaProjects" ]; then
  BASE_DIR="/IdeaProjects"
elif [ -d "/workspaces" ]; then
  BASE_DIR="/workspaces"
else
  echo "错误: 未找到 /workspaces 或 /IdeaProjects 目录，脚本退出。"
  exit 1
fi
echo "检测到有效目录，使用基础路径: ${BASE_DIR}"

# 注意修改 oh-my-env 目录名为你的目录名
dir=oh-my-env-2
# 日期时间格式作为版本号
time=$(date +'%Y%m%d-%H%M%S')
# 压缩包文件名称
dist=tmp/mangosteen-$time.tar.gz
current_dir=$(dirname $0)
deploy_dir=$BASE_DIR/$dir/mangosteen_deploy

yes | rm tmp/mangosteen-*.tar.gz;
yes | rm $deploy_dir/mangosteen-*.tar.gz;

# 打包排除目录
tar --exclude="tmp/cache/*" -czv -f $dist *
mkdir -p $deploy_dir
cp $current_dir/../config/host.Dockerfile $deploy_dir/Dockerfile
cp $current_dir/setup_host.sh $deploy_dir/
mv $dist $deploy_dir
echo $time > $deploy_dir/version
echo 'DONE!'
