# acme.sh 通配符 SSL 证书申请教程

## 前置条件

- 已有域名（如 trent30.com）
- Cloudflare 托管域名
- Cloudflare API Token

## 1. 安装 acme.sh

```bash
curl https://get.acme.sh | sh -s email=your@email.com
```

## 2. 设置 Cloudflare API

```bash
export CF_Token="你的Cloudflare_API_Token"
export CF_Zone_ID="你的Zone_ID"  # 可选
```

### 获取 Cloudflare API Token

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 点击右上角头像 → My Profile → API Tokens
3. 点击 "Create Token"
4. 选择 "Edit zone DNS" 模板
5. 配置权限：
   - Zone - DNS - Edit
   - Zone - Zone - Read
6. 选择目标域名
7. 创建并复制 Token

### 获取 Zone ID

1. 进入 Cloudflare Dashboard
2. 选择目标域名
3. 右侧 "Overview" 页面底部找到 "Zone ID"

## 3. 申请证书

### 申请通配符证书（推荐）

```bash
acme.sh --issue --dns dns_cf -d example.com -d "*.example.com"
```

### 使用 Let's Encrypt（推荐）

```bash
# 设置默认 CA 为 Let's Encrypt
acme.sh --set-default-ca --server letsencrypt

# 申请证书
acme.sh --issue --dns dns_cf -d example.com -d "*.example.com"
```

### 使用 ZeroSSL（默认）

```bash
acme.sh --issue --dns dns_cf -d example.com -d "*.example.com"
```

## 4. 证书文件位置

申请成功后，证书保存在：

```bash
~/.acme.sh/example.com_ecc/
├── example.com.cer      # 证书
├── example.com.key      # 私钥
├── ca.cer              # CA 证书
├── fullchain.cer       # 完整证书链（推荐使用）
└── example.com.csr     # CSR 文件
```

## 5. 部署证书

### 部署到 Nginx

```bash
acme.sh --install-cert -d example.com --ecc \
  --key-file /etc/nginx/ssl/example.com.key \
  --fullchain-file /etc/nginx/ssl/fullchain.cer \
  --reloadcmd "systemctl reload nginx"
```

### 手动复制

```bash
# 复制到目标服务器
scp ~/.acme.sh/example.com_ecc/fullchain.cer root@server:/etc/ssl/
scp ~/.acme.sh/example.com_ecc/example.com.key root@server:/etc/ssl/
```

## 6. 自动续期

acme.sh 会自动添加 cron 任务，每天检查证书有效期，到期前 30 天自动续期。

### 手动续期

```bash
acme.sh --renew -d example.com --force
```

### 查看 cron 任务

```bash
crontab -l | grep acme
```

## 7. 常用命令

```bash
# 查看已申请的证书
acme.sh --list

# 手动续期
acme.sh --renew -d example.com --force

# 删除证书
acme.sh --remove -d example.com

# 更换 CA
acme.sh --set-default-ca --server letsencrypt
acme.sh --set-default-ca --server zerossl
```

## 8. 故障排除

### DNS 验证失败

```bash
# 增加 DNS 等待时间
acme.sh --issue --dns dns_cf -d example.com --dnssleep 60

# 禁用 DNS 检查
acme.sh --issue --dns dns_cf -d example.com --dnssleep 0
```

### 查看详细日志

```bash
acme.sh --issue --dns dns_cf -d example.com --debug
```

### 常见错误

1. **"Too many certificates already issued"**
   - Let's Encrypt 限制：每周 50 个证书
   - 解决：使用 ZeroSSL 或等待一周

2. **"DNS problem: NXDOMAIN"**
   - DNS 记录未生效
   - 解决：等待 DNS 传播或增加 `--dnssleep`

3. **"Invalid API Token"**
   - 检查 Token 权限
   - 确保有 DNS Edit 权限

## 9. 实战案例

### trent30.com 证书申请

```bash
# 安装 acme.sh
curl https://get.acme.sh | sh -s email=admin@trent30.com

# 设置 Let's Encrypt
acme.sh --set-default-ca --server letsencrypt

# 设置 Cloudflare API
export CF_Token="3CVZVnEu0gzmkq9tbVf-dKsIYGMnNDQVrLwZN7xj"

# 申请通配符证书
acme.sh --issue --dns dns_cf -d trent30.com -d "*.trent30.com" --force

# 证书位置
ls ~/.acme.sh/trent30.com_ecc/
```

## 参考链接

- [acme.sh 官方文档](https://github.com/acmesh-official/acme.sh)
- [Cloudflare API 文档](https://developers.cloudflare.com/api/)
- [Let's Encrypt 文档](https://letsencrypt.org/docs/)
