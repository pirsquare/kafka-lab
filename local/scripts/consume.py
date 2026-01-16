import argparse
import sys

from demo_client import consume_messages


def main() -> int:
    parser = argparse.ArgumentParser(description="Consume messages from Kafka")
    parser.add_argument("--bootstrap", default="host.docker.internal:9094", help="Bootstrap host:port")
    parser.add_argument("--topic", default="demo-topic", help="Topic name")
    parser.add_argument("--group-id", default="demo-group", help="Consumer group id")
    parser.add_argument("--max-messages", type=int, default=10, help="Maximum messages to consume")
    parser.add_argument("--timeout", type=float, default=15.0, help="Timeout seconds")
    args = parser.parse_args()

    consume_messages(args.bootstrap, args.topic, args.group_id, args.max_messages, args.timeout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
