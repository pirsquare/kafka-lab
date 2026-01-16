import argparse
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Start Kafka (KRaft) via docker compose")
    parser.add_argument("--env-file", default=str(Path(__file__).parent.parent / ".env"), help="Path to .env file")
    args = parser.parse_args()

    env_path = Path(args.env_file)
    if not env_path.exists():
        print(f"Env file not found at {env_path}. Copy .env.example to .env first.", file=sys.stderr)
        return 1

    result = subprocess.run(
        ["docker", "compose", "--env-file", str(env_path), "up", "-d"],
        cwd=Path(__file__).parent.parent,
        check=False,
    )
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
