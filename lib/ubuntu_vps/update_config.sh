# ssh keys
echo "adding authorized keys for {{serviceName}}..."
echo "{{authorizedKeys}}" > /home/{{serviceName}}/.ssh/authorized_keys

# create a local nimbus.json config
echo "Creating nimbus.json config file..."
cat <<'EOF' > /home/{{serviceName}}/nimbus.json
{{ nimbusJSON }}
EOF

# restar the node service
echo "restarting node service..."
stop {{serviceName}}
start {{serviceName}}
