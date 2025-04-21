# 🚀 WP Docker OpenResty Image – Brotli + Cache Purge Ready

[![Build & Push to GHCR](https://github.com/your-username/wp-docker-openresty/actions/workflows/docker-build.yml/badge.svg)](https://github.com/your-username/wp-docker-openresty/actions)
[![Docker Image Size](https://img.shields.io/docker/image-size/ghcr.io/your-username/wp-docker-openresty/latest)](https://ghcr.io/your-username/wp-docker-openresty)
[![GitHub License](https://img.shields.io/github/license/your-username/wp-docker-openresty)](./LICENSE)

A **custom multi-arch OpenResty Docker image** with Brotli compression and `ngx_cache_purge` module – built for WordPress and NGINX reverse proxy environments.

---

## 🌟 Features

- 🔥 **Based on OpenResty** `1.21.4.1`
- 🧼 **Brotli compression** – for better performance over Gzip
- ♻️ **ngx_cache_purge** – purge FastCGI cache by URL
- 🧰 **Multi-arch** support: `linux/amd64`, `linux/arm64`
- 📂 Optimized for use with `WP Docker` stack

---

## 📦 Usage

### 🐳 Pull from GitHub Container Registry

```bash
docker pull ghcr.io/your-username/wp-docker-openresty:latest
```

### 🧪 Run directly:

```bash
docker run --rm -it \
  -p 8080:80 \
  ghcr.io/your-username/wp-docker-openresty:latest nginx -V
```

> Replace `your-username` with your actual GitHub username.

---

## 🔧 NGINX Configuration Examples

### 🧊 FastCGI Cache

```nginx
fastcgi_cache_path /usr/local/openresty/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;

server {
    set $no_cache 0;
    if ($http_cookie ~* "wordpress_logged_in|comment_author") {
        set $no_cache 1;
    }

    location ~ \.php$ {
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        add_header X-FastCGI-Cache $upstream_cache_status;
    }
}
```

---

### ♻️ Cache Purge Endpoint

```nginx
location ~ /purge(/.*) {
    allow 127.0.0.1;
    deny all;
    fastcgi_cache_purge WORDPRESS "$scheme$request_method$host$1";
}
```

---

### 💨 Brotli Compression

```nginx
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/font-woff2;
```

---

## 🏗️ Build Locally

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t wpdocker/openresty:latest \
  --push . 
```

### Or for local test (no push):

```bash
docker buildx build --platform linux/arm64 \
  -t wpdocker-openresty-arm-local \
  --load .
```

---

## 📂 Project Structure

```
.
├── Dockerfile             # Custom OpenResty build (Brotli + ngx_cache_purge)
└── .github/workflows/
    └── docker-build.yml   # GHCR build & push workflow
```

---

## 📄 License

[MIT](./LICENSE) – feel free to fork and improve!

---

## 🙌 Credits

- [OpenResty](https://openresty.org/)
- [ngx_brotli](https://github.com/google/ngx_brotli)
- [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge)

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
