# AI_Notes 同步脚本 - stephen-win
# 每6小时自动执行

$ErrorActionPreference = "Continue"
$repo = "K:\openclaw-workspace\AI_Notes"
$memory = "K:\openclaw-workspace\memory"
$memoryTarget = "$repo\OpenClaw_Configuration\stephen-win\memory"
$configTarget = "$repo\OpenClaw_Configuration\stephen-win"

# Step 1: Git 拉取
cd $repo
git pull origin main 2>&1

# Step 2: 同步 memory 文件夹
Copy-Item -Recurse -Force "$memory\*" "$memoryTarget\"
$memFiles = (Get-ChildItem "$memoryTarget" -Filter "*.md").Count
Write-Output "Memory 同步完成：$memFiles 个文件"

# Step 3: 同步我的配置到 stephen-win 目录（脱敏）
if (-not (Test-Path $configTarget)) { New-Item -ItemType Directory -Path $configTarget -Force | Out-Null }
Copy-Item -Force "$env:USERPROFILE\.openclaw\openclaw.json" "$configTarget\openclaw.json" -ErrorAction SilentlyContinue
$configFile = "$configTarget\openclaw.json"
if (Test-Path $configFile) {
    $cfg = Get-Content $configFile -Raw
    $cfg = $cfg -replace '"apiKey":\s*"[^"]*"', '"apiKey": "***REDACTED***"'
    $cfg = $cfg -replace 'sk-or-[a-zA-Z0-9-]*', '***REDACTED***'
    $cfg = $cfg -replace 'sk-[a-zA-Z0-9]{20,}', '***REDACTED***'
    $cfg = $cfg -replace 'apify_api_[a-zA-Z0-9]*', '***REDACTED***'
    $cfg = $cfg -replace '"token":\s*"[^"]*"', '"token": "***REDACTED***"'
    $cfg = $cfg -replace '"bot_token":\s*"[^"]*"', '"bot_token": "***REDACTED***"'
    $cfg = $cfg -replace '\d{10}:[A-Za-z0-9_-]{35}', '***REDACTED***'
    Set-Content $configFile $cfg
}
Write-Output "配置备份完成（已脱敏）"

# Step 4: 敏感信息清理
Get-ChildItem "$memoryTarget" -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $content = $content -replace 'sk-[a-zA-Z0-9]{20,}', '***REDACTED***'
        $content = $content -replace 'ctx7sk[a-zA-Z0-9]*', '***REDACTED***'
        $content = $content -replace '"private_key":\s*"-----BEGIN PRIVATE KEY-----\\n[^"]*"', '"private_key": "***REDACTED***"'
        $content = $content -replace '"private_key_id":\s*"[^"]*"', '"private_key_id": "***REDACTED***"'
        $content = $content -replace '"client_email":\s*"[^"]*litellm[^"]*"', '"client_email": "***REDACTED***"'
        $content = $content -replace '"client_id":\s*"[^"]*"', '"client_id": "***REDACTED***"'
        Set-Content $_.FullName $content
    }
}
Write-Output "敏感信息清理完成"

# Step 5: Git 推送
cd $repo
git add .
git commit -m "定时同步 $(Get-Date -Format 'yyyy-MM-dd_HH:mm')" 2>&1
git push origin main 2>&1
Write-Output "Git 推送完成"
