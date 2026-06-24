#!/usr/bin/env python3

import signal
import sys
import time

import fprime_py


running = True


def handle_signal(signum, frame):
    global running
    print(f"Received signal {signum}; shutting down...", flush=True)
    running = False


def main():
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print("JetsonDeployment fprime-python module loaded:", fprime_py, flush=True)
    print("Keeping process alive. Press Ctrl+C or stop the systemd service to exit.", flush=True)

    while running:
        time.sleep(1)

    print("Exiting fsw_main.py cleanly.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())