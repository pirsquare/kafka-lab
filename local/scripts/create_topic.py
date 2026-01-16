import argparse
import sys

from demo_client import ensure_topic


def main() -> int:
    parser = argparse.ArgumentParser(description="Create Kafka topic (idempotent)")
    parser.add_argument("--bootstrap", default="host.docker.internal:9094", help="Bootstrap host:port")
    parser.add_argument("--topic", default="demo-topic", help="Topic name")
    parser.add_argument("--partitions", type=int, default=3, help="Partition count")
    parser.add_argument("--replication", type=int, default=1, help="Replication factor")
    args = parser.parse_args()

    ensure_topic(args.bootstrap, args.topic, args.partitions, args.replication)
    return 0


if __name__ == "__main__":
    sys.exit(main())
