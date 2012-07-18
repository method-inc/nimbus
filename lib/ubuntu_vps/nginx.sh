#!/bin/bash

# setup a user
echo "creating user {{serviceName}} for nginx service..."
useradd -U -s /bin/bash -m {{serviceName}}

# ssh directory
mkdir -p /home/{{serviceName}}/.ssh
touch /home/{{serviceName}}/.ssh/authorized_keys
touch /home/{{serviceName}}/.ssh/known_hosts

# ssh keys
echo "adding authorized keys for {{serviceName}}..."
echo "{{authorizedKeys}}" > /home/{{serviceName}}/.ssh/authorized_keys

# chmod authorized_keys
chmod 600 /home/{{serviceName}}/.ssh/authorized_keys

# sudoer capability just for this project
cat <<EOF > /etc/sudoers.d/{{serviceName}}
{{serviceName}}     ALL=NOPASSWD: /sbin/restart {{serviceName}}
{{serviceName}}     ALL=NOPASSWD: /sbin/stop {{serviceName}}
{{serviceName}}     ALL=NOPASSWD: /sbin/start {{serviceName}}
EOF
chmod 0440 /etc/sudoers.d/{{serviceName}}

# create a local directory for installations
mkdir -p /home/{{serviceName}}/local

# use our locally installed binaries
cat <<EOF > /home/{{serviceName}}/.profile
export PATH=/home/{{serviceName}}/local/bin:$PATH
EOF

# create our git repository
<% if (!obj.updateOnly) { %>
rm -rf /home/{{serviceName}}/repo
<% } %>
mkdir -p /home/{{serviceName}}/repo

# create a post-receive hook for pushes to our repository
# repo -> slugs -> live
mkdir -p /home/{{serviceName}}/slugs
mkdir -p /home/{{serviceName}}/live
cd /home/{{serviceName}}/repo
git init --bare
cat <<'EOF' > hooks/post-receive
read oldrev newrev refname
. /home/{{serviceName}}/.profile
action="git: receiving $refname, rev. $oldrev => $newrev"
echo $action
echo $action >> /home/{{serviceName}}/deployment.log
mkdir -p /home/{{serviceName}}/slugs/$newrev
GIT_WORK_TREE=/home/{{serviceName}}/slugs/$newrev git checkout -f
cd /home/{{serviceName}}/slugs/$newrev
unset GIT_DIR
unset GIT_WORK_TREE
echo "deploying commit $newrev"
rm -rf /home/{{serviceName}}/live
mkdir /home/{{serviceName}}/live
cp -r /home/{{serviceName}}/slugs/$newrev/* /home/{{serviceName}}/live
sudo stop {{serviceName}}
sudo start {{serviceName}}
EOF
chmod +x hooks/post-receive

# install nginx
echo "installing nginx..."
mkdir -p /home/{{serviceName}}/local/tmp/nginx/client
mkdir -p /home/{{serviceName}}/local/tmp/nginx/client/
mkdir -p /home/{{serviceName}}/local/tmp/nginx/proxy
mkdir -p /home/{{serviceName}}/local/tmp/nginx/fcgi
mkdir -p /home/{{serviceName}}/local/run
version=`/home/{{serviceName}}/local/bin/nginx -v 2>&1`
if [ "$version" = "nginx version: nginx/{{nginxVersion}}" ] ; then
  echo "nginx {{nginxVersion}} is already installed"
else
  rm -rf ~/tmp
  mkdir ~/tmp
  cd ~/tmp
  wget http://nginx.org/download/nginx-{{nginxVersion}}.tar.gz
  tar xzvf nginx-{{nginxVersion}}.tar.gz
  cd nginx-{{nginxVersion}}
  ./configure --prefix=/home/{{serviceName}}/local  \
  --sbin-path=/home/{{serviceName}}/local/bin/nginx \
  --conf-path=/home/{{serviceName}}/nginx.conf  \
  --error-log-path=/home/{{serviceName}}/error.log \
  --http-log-path=/home/{{serviceName}}/access.log \
  --pid-path=/home/{{serviceName}}/local/run/nginx.pid \
  --lock-path=/home/{{serviceName}}/local/run/nginx.lock \
  --http-client-body-temp-path=/home/{{serviceName}}/local/tmp/nginx/client/ \
  --http-proxy-temp-path=/home/{{serviceName}}/local/tmp/nginx/proxy/  \
  --http-fastcgi-temp-path=/home/{{serviceName}}/local/tmp/nginx/fcgi/ \
  --with-http_flv_module \
  --with-http_ssl_module \
  --with-http_gzip_static_module
  make
  make install
fi

# configure nginx
cat <<'EOF' > /home/{{serviceName}}/nginx.conf
user {{serviceName}};
worker_processes 4;
pid /home/{{serviceName}}/local/nginx.pid;

events {
  worker_connections 768;
  # multi_accept on;
}

http {
  access_log /home/{{serviceName}}/access.log;
  error_log /home/{{serviceName}}/error.log;

  include /home/{{serviceName}}/mime.types;
  default_type application/octet-stream;

  sendfile on;
  keepalive_timeout 65;

  expires 1h;

  gzip on;
  gzip_comp_level 6;
  gzip_vary on;
  gzip_min_length  1000;
  gzip_proxied any;
  gzip_types text/plain text/html text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
  gzip_buffers 16 8k;

  ssl_certificate /home/{{serviceName}}/live/{{sslCertPath}};
  ssl_certificate_key /home/{{serviceName}}/live/{{sslKeyPath}};

  server {
    listen 80;
    listen 443 ssl;

    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
    ssl_prefer_server_ciphers on;

    server_name {{domainName}};

    root /home/{{serviceName}}/live/{{publicPath}};

    location / {
      try_files $uri $uri/;
    }
  }
}
EOF

# keep nginx alive
cat <<'EOF' > /etc/init/{{serviceName}}.conf
description "{{serviceName}} service"

start on (filesystem and net-device-up IFACE=lo)
stop on runlevel [!2345]

exec /home/{{serviceName}}/local/bin/nginx

expect fork
respawn
EOF

# own home
chown -R {{serviceName}}:{{serviceName}} /home/{{serviceName}}/

# restart service or machine
<% if (obj.updateOnly) { %>
echo "provisioning complete, restarting nginx service..."
stop {{serviceName}}
start {{serviceName}}
<% } else { %>
echo "provisioning complete, restarting host..."
shutdown -r now
<% } %>
