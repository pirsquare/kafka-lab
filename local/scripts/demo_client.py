import argparse
import sys
import time
from typing import List

from kafka import KafkaConsumer, KafkaProducer
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError


DEFAULT_MESSAGES = ["one", "two", "three"]


def ensure_topic(bootstrap: str, topic: str, partitions: int = 3, replication: int = 1) -> None:
    admin = KafkaAdminClient(bootstrap_servers=bootstrap, client_id="demo-admin")
    try:
        admin.create_topics([NewTopic(name=topic, num_partitions=partitions, replication_factor=replication)])
        print(f"Created topic '{topic}'")
    except TopicAlreadyExistsError:
        print(f"Topic '{topic}' already exists")
    finally:
        admin.close()


def produce_messages(bootstrap: str, topic: str, messages: List[str]) -> None:
    producer = KafkaProducer(bootstrap_servers=bootstrap, acks="all")
    for msg in messages:
        producer.send(topic, msg.encode("utf-8"))
        print(f"Produced: {msg}")
    producer.flush()
    producer.close()


def consume_messages(bootstrap: str, topic: str, group_id: str, expected: int, timeout: float = 10.0) -> None:
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=bootstrap,
        group_id=group_id,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
    )
    deadline = time.time() + timeout
    received = 0
    for message in consumer:
        print(f"Consumed: {message.value.decode('utf-8')}")
        received += 1
        if received >= expected:
            break
        if time.time() > deadline:
            break
    consumer.close()
    if received < expected:
        print(f"Warning: expected {expected} messages, got {received}")
    else:
        print("Consume complete")


def main() -> int:
    parser = argparse.ArgumentParser(description="Simple Kafka produce/consume demo (KRaft, no ZooKeeper)")
    parser.add_argument("--bootstrap", default="host.docker.internal:9094", help="Bootstrap server host:port")
    parser.add_argument("--topic", default="demo-topic", help="Topic name")
    parser.add_argument("--messages", nargs="*", default=DEFAULT_MESSAGES, help="Messages to send")
    parser.add_argument("--group-id", default="demo-group", help="Consumer group id")
    parser.add_argument("--timeout", type=float, default=10.0, help="Consume timeout seconds")
    args = parser.parse_args()

    ensure_topic(args.bootstrap, args.topic)
    produce_messages(args.bootstrap, args.topic, args.messages)
    consume_messages(args.bootstrap, args.topic, args.group_id, expected=len(args.messages), timeout=args.timeout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
