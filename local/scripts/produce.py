import argparse
import sys

from demo_client import produce_messages


def main() -> int:
    parser = argparse.ArgumentParser(description="Produce messages to Kafka")
    parser.add_argument("--bootstrap", default="host.docker.internal:9094", help="Bootstrap host:port")
    parser.add_argument("--topic", default="demo-topic", help="Topic name")
    parser.add_argument("messages", nargs="+", help="Messages to produce")
    args = parser.parse_args()

    produce_messages(args.bootstrap, args.topic, args.messages)
    return 0


if __name__ == "__main__":
    sys.exit(main())
