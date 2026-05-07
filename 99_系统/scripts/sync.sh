#!/bin/bash
cd /root/openclaw-workspace/AI_Notes

# Git 拉取
git pull origin main

# 同步 memory
rsync -av --update /root/openclaw-workspace/memory/ /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory/

# 清理敏感信息
cd /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory
for file in *.md; do
  sed -i 's/"apiKey": "[^"]*"/"apiKey": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/sk-[a-zA-Z0-9]\{20,\}/***REDACTED***/g' "$file" 2>/dev/null
  sed -i 's/ctx7sk[a-zA-Z0-9]*/***REDACTED***/g' "$file" 2>/dev/null
  sed -i 's/"private_key": "[^"]*"/"private_key": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"private_key_id": "[^"]*"/"private_key_id": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"client_email": "[^"]*"/"client_email": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"client_id": "[^"]*"/"client_id": "***REDACTED***"/g' "$file" 2>/dev/null
done

cd /root/openclaw-workspace/AI_Notes

# Git 推送
git add .
git commit -m "定时同步 $(date +%Y-%m-%d_%H:%M)" 2>/dev/null
git push origin main
