#!/bin/bash

# setup a user
echo "creating user {{serviceName}} for node service..."
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

# use our locally installed node binary
cat <<EOF > /home/{{serviceName}}/.profile
export PATH=/home/{{serviceName}}/local/bin:$PATH
EOF

# install node
echo "installing node if necessary..."
version=`/home/{{serviceName}}/local/bin/node --version`
if [ "$version" = "v{{nodeVersion}}" ]
then
  echo "node v{{nodeVersion}} is already installed"
fi
if [ "$version" != "v{{nodeVersion}}" ]
then
  rm -rf ~/tmp
  mkdir ~/tmp
  cd ~/tmp
  wget http://nodejs.org/dist/v{{nodeVersion}}/node-v{{nodeVersion}}.tar.gz
  tar xzvf node-v{{nodeVersion}}.tar.gz
  cd node-v{{nodeVersion}}
  export JOBS=4
  ./configure --prefix=/home/{{serviceName}}/local
  make install
fi

echo "creating repo, slugs, and live directories..."

# create our git repository

<% if (!obj.updateOnly) { %>
rm -rf /home/{{serviceName}}/repo
<% } %>

mkdir -p /home/{{serviceName}}/repo

# create our version storage
mkdir -p /home/{{serviceName}}/slugs

# create our live app directory
mkdir -p /home/{{serviceName}}/live

# create the node service and upstart scripts
echo "creating upstart service..."
cat <<'EOF' > /etc/init/{{serviceName}}.conf
description "{{serviceName}} service"

start on filesystem or runlevel [2345]
stop on runlevel [!2345]

respawn
respawn limit 10 5
umask 022

pre-start script
  # if there is no live package.json, then we have nothing to start
  if [ ! -e "/home/{{serviceName}}/live/package.json" ] ; then
    echo "can't start {{serviceName}}: /home/{{serviceName}}/live/package.json doesn't exist" >> /home/{{serviceName}}/{{serviceName}}.log
    stop ; exit 0
  fi
end script

script
  . /home/{{serviceName}}/.profile
  cd /home/{{serviceName}}/live
  npm start >> /home/{{serviceName}}/{{serviceName}}.log 2>&1
end script
EOF

# create a post-receive hook for pushes to our repository
# repo -> slugs -> live
echo "Creating git post-receive hook..."
cd /home/{{serviceName}}/repo
git init --bare
cat <<'EOF' > hooks/post-receive
read oldrev newrev refname
. /home/{{serviceName}}/.profile
action="git: receiving $refname, rev. $oldrev => $newrev"
echo $action
echo $action >> /home/{{serviceName}}/{{serviceName}}.log
mkdir -p /home/{{serviceName}}/slugs/$newrev
GIT_WORK_TREE=/home/{{serviceName}}/slugs/$newrev git checkout -f
cd /home/{{serviceName}}/slugs/$newrev
unset GIT_DIR
unset GIT_WORK_TREE
npm install
echo "deploying commit $newrev"
rm -rf /home/{{serviceName}}/live
mkdir /home/{{serviceName}}/live
cp -r /home/{{serviceName}}/slugs/$newrev/* /home/{{serviceName}}/live
sudo stop {{serviceName}}
sudo start {{serviceName}}
EOF
chmod +x hooks/post-receive

# create a local nimbus.json config
echo "Creating nimbus.json config file..."
cat <<'EOF' > /home/{{serviceName}}/nimbus.json
{{ nimbusJSON }}
EOF

# own home
chown -R {{serviceName}}:{{serviceName}} /home/{{serviceName}}/

# restart the machine or service

<% if (obj.updateOnly) { %>
echo "provisioning complete, restarting node service..."
stop {{serviceName}}
start {{serviceName}}
<% } else { %>
echo "provisioning complete, restarting host..."
shutdown -r now
<% } %>


