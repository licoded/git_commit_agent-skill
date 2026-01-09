#!/bin/bash
# 分析变更层面 - 检测是否应该按应用层/基础设施层拆分

echo "=== 分析变更层面 ==="

# 统计各层面的文件数量
application_count=0
infrastructure_count=0
config_count=0
docs_count=0

# 分类文件
application_files=""
infrastructure_files=""
config_files=""
docs_files=""

for file in $(git diff --cached --name-only); do
  if [[ "$file" =~ \.(java|py|ts|js|go|rs|c|cpp|h|cs)$ ]]; then
    ((application_count++))
    application_files="$application_files $file"
  elif [[ "$file" =~ (Dockerfile|docker-compose|\.gitignore|\.dockerignore)$ ]]; then
    ((infrastructure_count++))
    infrastructure_files="$infrastructure_files $file"
  elif [[ "$file" =~ (\.yml|\.yaml|\.toml|\.json|config/)$ ]]; then
    ((config_count++))
    config_files="$config_files $file"
  elif [[ "$file" =~ \.(md|txt|rst)$ ]]; then
    ((docs_count++))
    docs_files="$docs_files $file"
  fi
done

echo "应用层: $application_count 个文件"
echo "基础设施层: $infrastructure_count 个文件"
echo "配置层: $config_count 个文件"
echo "文档层: $docs_count 个文件"

# 判断是否需要拆分
should_split=false
reason=""

if [ $application_count -gt 0 ] && [ $infrastructure_count -gt 0 ]; then
  should_split=true
  reason="检测到应用层($application_count) + 基础设施层($infrastructure_count) 变更"
fi

echo ""
echo "=== 拆分建议 ==="
if [ "$should_split" = true ]; then
  echo "建议: 按层面拆分"
  echo "原因: $reason"
  echo ""
  echo "Commit 1: 应用层变更"
  echo "$application_files"
  echo ""
  echo "Commit 2: 基础设施层变更"
  echo "$infrastructure_files"
else
  echo "建议: 单个提交"
fi

# 返回结果（供 Claude 解析）
if [ "$should_split" = true ]; then
  exit 1  # 需要拆分
else
  exit 0  # 单个提交
fi
