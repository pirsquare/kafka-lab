import subprocess
import sys
from pathlib import Path


def main() -> int:
    result = subprocess.run(["docker", "compose", "down", "-v"], cwd=Path(__file__).parent.parent, check=False)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
