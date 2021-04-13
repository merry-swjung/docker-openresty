# Dockerfile - alpine
# https://github.com/openresty/docker-openresty

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.13"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

# Openresty's maintainer
LABEL maintainer="Evan Wies <evan@neomantra.net>"
LABEL maintainer="Sunwoo Jung <swjung@cloudbric.com>"

# Docker Build Arguments
ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.13"
ARG RESTY_VERSION="1.19.3.1"
ARG RESTY_OPENSSL_VERSION="1.1.1h"
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
ARG RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
ARG RESTY_PCRE_VERSION="8.44"
ARG RESTY_ZLIB_VERSION="1.2.11"
ARG GEOIP_VERSION="1.6.12"
ARG PYTHON3_VERSION="3.8.8"
ARG RESTY_J="1"
ARG RESTY_PATH="/usr/local/openresty"
ARG RESTY_CONFIG_OPTIONS="\
    --with-http_addition_module \
    --with-http_degradation_module \
    --with-http_flv_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_realip_module \
    --with-http_geoip_module \
    "

ARG RESTY_CONFIG_OPTIONS_MORE="\
    --prefix=/etc/nginx \
    --user=nginx \
    --group=nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --sbin-path=/usr/sbin/nginx \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-log-path=/var/log/access.log \
    --error-log-path=/var/log/error.log \
    "
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_ADD_PACKAGE_BUILDDEPS=""
ARG RESTY_ADD_PACKAGE_RUNDEPS=""
ARG RESTY_EVAL_PRE_CONFIGURE=""
ARG RESTY_EVAL_POST_MAKE=""

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="\
    --with-pcre \
    --with-zlib=/tmp/zlib-${RESTY_ZLIB_VERSION}/ \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include -I/usr/local/openresty/zlib/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -L/usr/local/openresty/zlib/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib:/usr/local/openresty/zlib/lib' \
    "

LABEL resty_image_base="${RESTY_IMAGE_BASE}"
LABEL resty_image_tag="${RESTY_IMAGE_TAG}"
LABEL resty_version="${RESTY_VERSION}"
LABEL resty_openssl_version="${RESTY_OPENSSL_VERSION}"
LABEL resty_openssl_patch_version="${RESTY_OPENSSL_PATCH_VERSION}"
LABEL resty_openssl_url_base="${RESTY_OPENSSL_URL_BASE}"
LABEL resty_pcre_version="${RESTY_PCRE_VERSION}"
LABEL resty_zlib_version="${RESTY_ZLIB_VERSION}"
LABEL geoip_version="${GEOIP_VERSION}"
LABEL python3_version="${PYTHON3_VERSION}"
LABEL resty_config_options="${RESTY_CONFIG_OPTIONS}"
LABEL resty_config_options_more="${RESTY_CONFIG_OPTIONS_MORE}"
LABEL resty_config_deps="${_RESTY_CONFIG_DEPS}"
LABEL resty_add_package_builddeps="${RESTY_ADD_PACKAGE_BUILDDEPS}"
LABEL resty_add_package_rundeps="${RESTY_ADD_PACKAGE_RUNDEPS}"
LABEL resty_eval_pre_configure="${RESTY_EVAL_PRE_CONFIGURE}"
LABEL resty_eval_post_make="${RESTY_EVAL_POST_MAKE}"

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        coreutils \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
        ${RESTY_ADD_PACKAGE_BUILDDEPS} \
    && apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libxslt \
        zlib \
        php7 \
        php7-gd \
        php7-pear \
        ${RESTY_ADD_PACKAGE_RUNDEPS} \
    && adduser --shell /sbin/nologin -D -H nginx \
    && mkdir -p /var/lib/nginx \
    && mkdir -p /var/log/nginx \
    && chown nginx.nginx /var/lib/nginx \
    && cd /tmp \
    && if [ -n "${RESTY_EVAL_PRE_CONFIGURE}" ]; then eval $(echo ${RESTY_EVAL_PRE_CONFIGURE}); fi \
    && cd /tmp \
    && curl -fSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && cd openssl-${RESTY_OPENSSL_VERSION} \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ] ; then \
        echo 'patching OpenSSL 1.1.1 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ] ; then \
        echo 'patching OpenSSL 1.1.0 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1 \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && ./config \
      no-threads shared zlib -g \
      enable-ssl3 enable-ssl3-method \
      --prefix=${RESTY_PATH}/openssl \
      --libdir=lib \
      -Wl,-rpath,${RESTY_PATH}/openssl/lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install_sw \
    && cd /tmp \
    && curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && cd /tmp/pcre-${RESTY_PCRE_VERSION} \
    && ./configure \
        --prefix=${RESTY_PATH}/pcre \
        --disable-cpp \
        --enable-jit \
        --enable-utf \
        --enable-unicode-properties \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && curl -fSL https://zlib.net/zlib-${RESTY_ZLIB_VERSION}.tar.gz -o zlib-${RESTY_ZLIB_VERSION}.tar.gz \
    && tar xzf zlib-${RESTY_ZLIB_VERSION}.tar.gz \
    && cd zlib-${RESTY_ZLIB_VERSION} \
    && ./configure \
        --prefix=${RESTY_PATH}/zlib \
        --libdir=lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && curl -fSL https://github.com/maxmind/geoip-api-c/releases/download/v${GEOIP_VERSION}/GeoIP-${GEOIP_VERSION}.tar.gz -o GeoIP-${GEOIP_VERSION}.tar.gz \
    && tar xzf GeoIP-${GEOIP_VERSION}.tar.gz \
    && mv /tmp/GeoIP-${GEOIP_VERSION} /etc/nginx \
    && cd /tmp \
    && curl -fSL https://www.python.org/ftp/python/${PYTHON3_VERSION}/Python-${PYTHON3_VERSION}.tgz -o Python-${PYTHON3_VERSION}.tgz \
    && tar -zxvf ./Python-${PYTHON3_VERSION}.tgz \
    && cd Python-${PYTHON3_VERSION} \
    && ./configure --with-ssl \
    && make && make install \
    && cd /tmp \
    && if [ -n "${RESTY_EVAL_POST_MAKE}" ]; then eval $(echo ${RESTY_EVAL_POST_MAKE}); fi \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz openssl-${RESTY_OPENSSL_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
        zlib-${RESTY_ZLIB_VERSION}.tar.gz zlib-${RESTY_ZLIB_VERSION} \
        GeoIP-${GEOIP_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        Python-${PYTHON3_VERSION}.tgz Python-${PYTHON3_VERSION} \
    && apk del .build-deps \
    && mkdir -p /var/run/openresty \
    && touch ln -sf /dev/stdout /var/logs/access.log /var/log/error.log \
    && ln -sf /dev/stdout /var/log/access.log \
    && ln -sf /dev/stderr /var/log/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:${RESTY_PATH}/luajit/bin:${RESTY_PATH}/nginx/sbin:${RESTY_PATH}/bin

# Copy nginx configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

CMD ["${RESTY_PATH}/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
