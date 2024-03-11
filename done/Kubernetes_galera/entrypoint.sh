#!/bin/bash

set -e

# Update wsrep_node_address and wsrep_node_name in galera.cnf
sed -i "s/^wsrep_node_address=.*$/wsrep_node_address=${HOSTNAME}/" /etc/mysql/conf.d/galera.cnf
sed -i "s/^wsrep_node_name=.*$/wsrep_node_name=${HOSTNAME}/" /etc/mysql/conf.d/galera.cnf



if [[ "$HOSTNAME" != "galera-cluster-0" ]]; then
  # Wait for the first node to start
  echo "Waiting for the first node (galera-cluster-0) to start..."
  MYSQL_STARTUP_TIMEOUT=10
  for i in $(seq 1 $MYSQL_STARTUP_TIMEOUT); do
    if mysql -uroot -p$MYSQL_ROOT_PASSWORD -h galera-cluster-0 -e "SELECT 1" &> /dev/null; then
      echo "First node (galera-cluster-0) is now running"
      break
    fi
    echo "Waiting for first node (galera-cluster-0) to start..."
    sleep 1
  done
fi

if [[ "$HOSTNAME" == "galera-cluster-0" ]]; then
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

