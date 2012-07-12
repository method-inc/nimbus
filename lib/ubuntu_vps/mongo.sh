#!/bin/bash

# setup a user
echo "creating user {{serviceName}} for mongo service..."
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

# use our locally installed mongo binary
cat <<EOF > /home/{{serviceName}}/.profile
export PATH=/home/{{serviceName}}/local/bin:$PATH
EOF

# stop this process if it's running
stop {{serviceName}}

# install mongo
version=`/home/{{serviceName}}/local/bin/mongo --version`
if [ "$version" = 'MongoDB shell version: 2.0.6' ]
then
  echo "mongo 2.0.6 is already installed"
fi
if [ "$version" != 'MongoDB shell version: 2.0.6' ]
then
  # Uninstall mongodb
  apt-get remove --yes mongodb-10gen

  # Install mongodb
  apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
  echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
  apt-get update --yes
  apt-get install --yes mongodb-10gen

  # stop mongo so we can configure it (otherwise until reboot it will run with /var/lib/mongodb)
  stop mongodb

  # delete the default upstart file
  rm /etc/init/mongodb.conf

  # move binaries into local
  mv /usr/bin/mongo* /home/{{serviceName}}/local/bin
fi

# create db directory
mkdir -p /home/{{serviceName}}/db

#create log
touch /home/{{serviceName}}/mongodb.log

# create mongo configuration file
echo "building /home/{{serviceName}}/mongodb.conf..."
cat <<'EOF' > /home/{{serviceName}}/mongodb.conf
logappend=true
dbpath=/home/{{serviceName}}/db
bind_ip = {{bindIP}}
oplogSize = 10000
journal = true
logpath=/home/{{serviceName}}/mongodb.log
EOF

# create the mongodb service and upstart scripts
echo "creating upstart service..."
cat <<'EOF' > /etc/init/{{serviceName}}.conf
limit nofile 20000 20000

kill timeout 300 # wait 300s between SIGTERM and SIGKILL.

start on runlevel [2345]
stop on runlevel [06]

script
  exec start-stop-daemon --start --quiet --chuid {{serviceName}} --exec /home/{{serviceName}}/local/bin/mongod -- --config /home/{{serviceName}}/mongodb.conf
end script
EOF

# own home
chown -R {{serviceName}}:{{serviceName}} /home/{{serviceName}}/

# restart the machine
echo "provisioning complete, restarting..."
shutdown -r now

