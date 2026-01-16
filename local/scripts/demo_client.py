import argparse
import sys
import time
from typing import List

from confluent_kafka import Producer, Consumer, KafkaError
from confluent_kafka.admin import AdminClient, NewTopic


DEFAULT_MESSAGES = ["one", "two", "three"]


def ensure_topic(bootstrap: str, topic: str, partitions: int = 3, replication: int = 1) -> None:
    admin = AdminClient({"bootstrap.servers": bootstrap})
    try:
        fs = admin.create_topics([NewTopic(topic, num_partitions=partitions, replication_factor=replication)])
        for t, f in fs.items():
            try:
                f.result()
                print(f"Created topic '{topic}'")
            except Exception as e:
                if "TopicAlreadyExists" in str(e):
                    print(f"Topic '{topic}' already exists")
                else:
                    raise
    finally:
        admin.close()


def produce_messages(bootstrap: str, topic: str, messages: List[str]) -> None:
    def on_delivery(err, msg):
        if err:
            print(f"Message delivery failed: {err}")
        else:
            print(f"Produced: {msg.value().decode('utf-8')}")

    producer = Producer({"bootstrap.servers": bootstrap, "acks": "all"})
    for msg in messages:
        producer.produce(topic, msg.encode("utf-8"), callback=on_delivery)
    producer.flush()


def consume_messages(bootstrap: str, topic: str, group_id: str, expected: int, timeout: float = 10.0) -> None:
    consumer = Consumer(
        {
            "bootstrap.servers": bootstrap,
            "group.id": group_id,
            "auto.offset.reset": "earliest",
            "enable.auto.commit": True,
        }
    )
    consumer.subscribe([topic])
    deadline = time.time() + timeout
    received = 0

    while received < expected:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            if time.time() > deadline:
                break
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(f"Consumer error: {msg.error()}")
                break
        print(f"Consumed: {msg.value().decode('utf-8')}")
        received += 1

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
