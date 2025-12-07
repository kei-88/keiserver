# Kei Installation Guide

## Quick Install

```bash
curl -sSL https://yourdomain.com/install-kei.sh | sudo bash
```

## Cara Host Install Script ke Domain Sendiri

### Opsi 1: Static File Server (Paling Simple)

#### A. Pakai Nginx
```bash
# 1. Copy script ke web root
sudo mkdir -p /var/www/html
sudo cp install-kei.sh /var/www/html/

# 2. Install nginx
sudo apt update
sudo apt install nginx

# 3. Configure nginx
sudo tee /etc/nginx/sites-available/install << 'EOF'
server {
    listen 80;
    server_name yourdomain.com;
    
    root /var/www/html;
    
    location /install-kei.sh {
        default_type text/plain;
        add_header Content-Type "text/plain; charset=utf-8";
    }
}
EOF

# 4. Enable site
sudo ln -s /etc/nginx/sites-available/install /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Sekarang bisa akses: `https://yourdomain.com/install-kei.sh`

#### B. Pakai GitHub Pages (GRATIS!)

```bash
# 1. Buat repository baru di GitHub (misal: kei-install)
# 2. Push install script
git init
git add install-kei.sh
git commit -m "Add install script"
git branch -M main
git remote add origin git@github.com:yourusername/kei-install.git
git push -u origin main

# 3. Enable GitHub Pages di Settings > Pages > Source: main branch

# 4. Access via:
# https://yourusername.github.io/kei-install/install-kei.sh
```

#### C. Pakai GitHub Raw (Instant, No Setup!)

```bash
# Setelah push ke GitHub, pakai URL raw:
curl -sSL https://raw.githubusercontent.com/yourusername/kei-install/main/install-kei.sh | sudo bash
```

### Opsi 2: Custom Domain dengan SSL (Production Ready)

#### Setup dengan Caddy (Auto SSL)

```bash
# 1. Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# 2. Copy script
sudo mkdir -p /var/www/install
sudo cp install-kei.sh /var/www/install/

# 3. Configure Caddy (auto SSL!)
sudo tee /etc/caddy/Caddyfile << 'EOF'
install.yourdomain.com {
    root * /var/www/install
    file_server
    
    header /install-kei.sh {
        Content-Type "text/plain; charset=utf-8"
    }
}
EOF

# 4. Reload Caddy
sudo systemctl reload caddy
```

Caddy otomatis setup SSL dari Let's Encrypt!

Access: `https://install.yourdomain.com/install-kei.sh`

### Opsi 3: Pakai CDN (Recommended untuk Production)

#### A. Cloudflare Pages (Gratis + Fast!)

```bash
# 1. Buat repo dengan struktur:
# /public/install-kei.sh

mkdir -p public
cp install-kei.sh public/

# 2. Push ke GitHub
git init
git add .
git commit -m "Initial commit"
git push

# 3. Connect di Cloudflare Pages:
# - Login ke Cloudflare
# - Pages > Create a project
# - Connect GitHub repo
# - Build settings: None (static files)
# - Deploy!

# Access via:
# https://yourproject.pages.dev/install-kei.sh
# atau custom domain: https://install.yourdomain.com/install-kei.sh
```

#### B. Vercel (Gratis + Fast!)

```bash
# 1. Install Vercel CLI
npm i -g vercel

# 2. Setup project
mkdir kei-install
cd kei-install
mkdir public
cp ../install-kei.sh public/

# 3. Deploy
vercel

# Follow prompts, then access:
# https://kei-install.vercel.app/install-kei.sh
```

### Opsi 4: Docker Web Server (Simple)

```bash
# 1. Buat Dockerfile
cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY install-kei.sh /usr/share/nginx/html/
RUN chmod 644 /usr/share/nginx/html/install-kei.sh
EOF

# 2. Build dan run
docker build -t kei-install-server .
docker run -d -p 8080:80 --name kei-install kei-install-server

# 3. Reverse proxy dengan Caddy/Nginx untuk SSL
```

## Cara Terbaik (My Recommendation)

### Untuk Development/Testing:
```bash
# Pakai GitHub Raw - instant, no setup
https://raw.githubusercontent.com/yourusername/kei-install/main/install-kei.sh
```

### Untuk Production:
```bash
# Pakai Cloudflare Pages atau GitHub Pages dengan custom domain
https://install.kei.yourdomain.com/install-kei.sh

# Keuntungan:
# ✅ Gratis
# ✅ Auto SSL
# ✅ CDN global (cepat dari mana aja)
# ✅ Auto deploy dari git push
# ✅ No server maintenance
```

## Update Install Command

Setelah host di domain, update command di README:

```bash
# Single line install
curl -sSL https://install.kei.yourdomain.com/install-kei.sh | sudo bash

# Atau dengan wget
wget -qO- https://install.kei.yourdomain.com/install-kei.sh | sudo bash

# Atau download dulu, review, then run
curl -O https://install.kei.yourdomain.com/install-kei.sh
less install-kei.sh  # review script
sudo bash install-kei.sh
```

## Custom Short URL (Bonus!)

Pakai bit.ly atau custom domain redirect:

```bash
# Caddy config untuk short URL
kei.sh {
    redir / https://install.kei.yourdomain.com/install-kei.sh
}

# Sekarang install jadi super simple:
curl -sSL kei.sh | sudo bash
```

## Contoh Real World

Liat cara project lain melakukannya:

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Node.js (via nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Kei (you!)
curl -sSL https://install.kei.yourdomain.com/install-kei.sh | sudo bash
```
