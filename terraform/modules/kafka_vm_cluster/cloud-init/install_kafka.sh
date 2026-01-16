#cloud-config
runcmd:
  - bash /tmp/install_kafka.sh

write_files:
  - path: /tmp/install_kafka.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/bin/bash
      set -euo pipefail

      NODE_ID="${node_id}"
      PRIVATE_IP="${private_ip}"
      ADVERTISED_HOST="${advertised_host}"
      CONTROLLER_VOTERS="${controller_voters}"
      CLUSTER_ID="${cluster_id}"
      DATA_DIR="${data_dir}"
      BROKER_PORT="${broker_port}"
      CONTROLLER_PORT="${controller_port}"
      EXTERNAL_PORT="${external_port}"
      KAFKA_VERSION="${kafka_version}"
      SCALA_VARIANT="${scala_variant}"
      KAFKA_BASE_URL="${kafka_download_base_url}"
      HEAP_OPTS="${heap_opts}"
      ENABLE_JMX="${enable_jmx}"
      JMX_PORT="${jmx_port}"
      CLUSTER_NAME="${cluster_name}"

      KAFKA_TGZ_URL="${KAFKA_BASE_URL}/${KAFKA_VERSION}/kafka_${SCALA_VARIANT}-${KAFKA_VERSION}.tgz"
      KAFKA_HOME="/opt/kafka"
      KAFKA_CONFIG_DIR="/etc/kafka"
      LOG_DIR="${DATA_DIR}/logs"

      mkdir -p "$DATA_DIR" "$LOG_DIR" "$KAFKA_CONFIG_DIR"

      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y curl tar openjdk-17-jre-headless

      if [ ! -d "$KAFKA_HOME" ]; then
        echo "Downloading Kafka ${KAFKA_VERSION}..."
        curl -sfL "$KAFKA_TGZ_URL" -o /tmp/kafka.tgz
        tar -xf /tmp/kafka.tgz -C /opt
        mv "/opt/kafka_${SCALA_VARIANT}-${KAFKA_VERSION}" "$KAFKA_HOME"
      fi

      cat >"${KAFKA_CONFIG_DIR}/server.properties" <<EOF
process.roles=broker,controller
node.id=${NODE_ID}
controller.listener.names=CONTROLLER
controller.quorum.voters=${CONTROLLER_VOTERS}
listeners=PLAINTEXT://0.0.0.0:${BROKER_PORT},CONTROLLER://0.0.0.0:${CONTROLLER_PORT},EXTERNAL://0.0.0.0:${EXTERNAL_PORT}
advertised.listeners=PLAINTEXT://${PRIVATE_IP}:${BROKER_PORT},EXTERNAL://${ADVERTISED_HOST}:${EXTERNAL_PORT}
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=PLAINTEXT
log.dirs=${LOG_DIR}
num.partitions=3
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
default.replication.factor=1
EOF

      cat >"${KAFKA_CONFIG_DIR}/logging.properties" <<EOF
log4j.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%d] %p %m (%c)%n
EOF

      if [ ! -f "${DATA_DIR}/meta.properties" ]; then
        echo "Formatting storage for cluster ${CLUSTER_ID}..."
        ${KAFKA_HOME}/bin/kafka-storage.sh format -t ${CLUSTER_ID} -c ${KAFKA_CONFIG_DIR}/server.properties --ignore-formatted
      fi

      cat >/etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka (KRaft)
After=network.target

[Service]
Type=simple
Environment=KAFKA_HEAP_OPTS=${HEAP_OPTS}
Environment=KAFKA_JMX_PORT=${JMX_PORT}
Environment=KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:${KAFKA_CONFIG_DIR}/logging.properties"
ExecStart=${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_CONFIG_DIR}/server.properties
Restart=on-failure
RestartSec=5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

      systemctl daemon-reload
      systemctl enable --now kafka

      if [ "$ENABLE_JMX" = "true" ]; then
        echo "JMX enabled on ${JMX_PORT}"
      fi

      echo "Kafka node ${NODE_ID} installed (${CLUSTER_NAME})"
