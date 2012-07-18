#!/bin/bash

# setup a user
echo "creating user {{serviceName}} for redis service..."
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
mkdir -p /home/{{serviceName}}/local/bin

# use our locally installed binaries
cat <<EOF > /home/{{serviceName}}/.profile
export PATH=/home/{{serviceName}}/local/bin:$PATH
EOF

version=`/home/{{serviceName}}/local/bin/redis-server --version`
if [ "$version" = 'Redis server version {{redisVersion}} (00000000:0)' ]
then
  echo "redis {{redisVersion}} is already installed"
else
  # stop the service if it's running
  stop {{serviceName}}

  # Install Redis
  cd /tmp
  wget http://redis.googlecode.com/files/redis-{{redisVersion}}.tar.gz
  tar -zxf redis-{{redisVersion}}.tar.gz
  cd redis-{{redisVersion}}
  make PREFIX=/home/{{serviceName}}/local install
fi

# create a db directory
mkdir -p /home/{{serviceName}}/db

# create a log file
touch /home/{{serviceName}}/redis.log

# TODO: see if you can create defaults like {{ port || '6379' }}

# Configure redis
cat <<'EOF' > /home/{{serviceName}}/redis.conf
daemonize no
pidfile /home/{{serviceName}}/redis.pid
logfile /home/{{serviceName}}/redis.log

port {{port}}
bind {{bindIP}}
timeout 300

loglevel notice

## Default configuration options
databases 16

save 900 1
save 300 10
save 60 10000

rdbcompression yes
dbfilename dump.rdb

dir /home/{{serviceName}}/db
appendonly no

glueoutputbuf yes
EOF

# Set redis to autostart
cat <<'EOF' > /etc/init/{{serviceName}}.conf

start on runlevel [23]
stop on shutdown

exec /usr/local/bin/redis-server /home/{{serviceName}}/redis.conf

respawn
EOF

# own home
chown -R {{serviceName}}:{{serviceName}} /home/{{serviceName}}/

# restart service or machine
<% if (obj.updateOnly) { %>
echo "provisioning complete, restarting redis service..."
stop {{serviceName}}
start {{serviceName}}
<% } else { %>
echo "provisioning complete, restarting host..."
shutdown -r now
<% } %>