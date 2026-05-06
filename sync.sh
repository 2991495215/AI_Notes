#!/bin/bash
cd /root/openclaw-workspace/AI_Notes

# Git 拉取
git pull origin main

# 同步 memory
rsync -av --update /root/openclaw-workspace/memory/ /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory/

# Git 推送
git add .
git commit -m "定时同步 $(date +%Y-%m-%d_%H:%M)" 2>/dev/null
git push origin main
