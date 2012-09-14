# ssh keys
echo "adding authorized keys for {{serviceName}}..."
echo "{{authorizedKeys}}" > /home/{{serviceName}}/.ssh/authorized_keys

# create a local config on remote
echo "Creating local.config.json config file..."
cat <<'EOF' > /home/{{serviceName}}/local.config.json
{{ nimbusJSON }}
EOF

# restar the node service
echo "restarting node service..."
stop {{serviceName}}
start {{serviceName}}
