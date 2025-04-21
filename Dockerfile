# ========================
# 🏗 Stage 1: Build OpenResty with Brotli + Cache Purge
# ========================
FROM ubuntu:22.04 AS builder

# Cài công cụ build & thư viện cần thiết
RUN apt update && apt install -y \
  build-essential git curl cmake automake autoconf libtool \
  libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev \
  ca-certificates unzip wget

# ⚙️ Cài cmake bản mới để tránh lỗi QEMU trên multi-arch
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.25.2/cmake-3.25.2.tar.gz && \
    tar -xzf cmake-3.25.2.tar.gz && cd cmake-3.25.2 && \
    ./bootstrap && make -j$(nproc) && make install

# 📦 Clone Brotli
RUN git clone --depth=1 https://github.com/google/ngx_brotli /usr/local/src/ngx_brotli && \
    cd /usr/local/src/ngx_brotli && git submodule update --init

# 📦 Clone ngx_cache_purge
RUN git clone --depth=1 https://github.com/FRiCKLE/ngx_cache_purge /usr/local/src/ngx_cache_purge

# 🧱 Build Brotli thư viện phụ thuộc
RUN cd /usr/local/src/ngx_brotli/deps/brotli && mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install

# 🔧 Build OpenResty từ source với các module
RUN curl -fsSL https://openresty.org/download/openresty-1.21.4.1.tar.gz | tar xz -C /usr/local/src

RUN cd /usr/local/src/openresty-1.21.4.1 && \
    ./configure \
      --prefix=/usr/local/openresty \
      --with-pcre-jit \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_realip_module \
      --with-http_stub_status_module \
      --add-module=/usr/local/src/ngx_brotli \
      --add-module=/usr/local/src/ngx_cache_purge && \
    make -j$(nproc) && make install

# 📦 Cài LuaRocks (tuỳ chọn nếu bạn cần)
ARG LUAROCKS_VERSION=3.9.2
RUN curl -fsSL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz | tar xz && \
    cd luarocks-${LUAROCKS_VERSION} && \
    ./configure --with-lua=/usr/local/openresty/luajit \
                --lua-suffix=jit \
                --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
    make && make install

# ========================
# 🧼 Stage 2: Final image
# ========================
FROM debian:bookworm-slim

# Cài thư viện runtime cần thiết
RUN apt update && apt install -y \
    libbrotli1 libssl3 libpcre3 zlib1g ca-certificates && \
    apt clean && rm -rf /var/lib/apt/lists/*

# 🧑‍🔧 Tạo user nobody nếu chưa có (fix lỗi phân quyền chia sẻ volume với PHP container)
RUN getent group nogroup || groupadd -g 65534 nogroup && \
    id -u nobody &>/dev/null || useradd -u 65534 -g nogroup -s /usr/sbin/nologin nobody

# 📂 Copy từ builder
COPY --from=builder /usr/local/openresty /usr/local/openresty
COPY --from=builder /usr/local/bin/luarocks /usr/local/bin/luarocks

# Cấu hình PATH
ENV PATH=$PATH:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin:/usr/local/openresty/luajit/bin

# Workdir
WORKDIR /usr/local/openresty/nginx

# Mở port
EXPOSE 80 443

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
