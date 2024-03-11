#!/bin/bash

set -e

# Update wsrep_node_address and wsrep_node_name in galera.cnf
sed -i "s/^wsrep_node_address=.*$/wsrep_node_address=${HOSTNAME}/" /etc/mysql/conf.d/galera.cnf
sed -i "s/^wsrep_node_name=.*$/wsrep_node_name=${HOSTNAME}/" /etc/mysql/conf.d/galera.cnf



if [[ "$HOSTNAME" != "db1" ]]; then
  # Wait for the first node to start
  echo "Waiting for the first node (db1) to start..."
  MYSQL_STARTUP_TIMEOUT=10
  for i in $(seq 1 $MYSQL_STARTUP_TIMEOUT); do
    if mysql -uroot -p$MYSQL_ROOT_PASSWORD -h db1 -e "SELECT 1" &> /dev/null; then
      echo "First node (db1) is now running"
      break
    fi
    echo "Waiting for first node (db1) to start..."
    sleep 1
  done
fi

if [[ "$HOSTNAME" == "db1" ]]; then
    if [ ! -f /var/lib/mysql/grastate.dat ]; then
        echo "Initializing new cluster..."
        docker-entrypoint.sh mysqld --wsrep-new-cluster 
        
    else
    	echo "Starting node in existing cluster..."
        docker-entrypoint.sh mysqld
    fi
else
    echo "Starting node in existing cluster..."
    docker-entrypoint.sh mysqld
fi

