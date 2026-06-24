#!/usr/bin/env python3

import os
import signal
import time
import traceback

import fprime_py


running = True
topology_started = False


def handle_signal(signum, frame):
    global running
    print(f"Received signal {signum}; shutting down...", flush=True)
    running = False


def main():
    global topology_started

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print("JetsonDeployment fprime-python module loaded:", fprime_py, flush=True)
    print(
        "Available JetsonDeployment bindings:",
        [x for x in dir(fprime_py.JetsonDeployment) if not x.startswith("_")],
        flush=True,
    )

    try:
        print("Calling fprime_py.JetsonDeployment.setup()...", flush=True)
        fprime_py.JetsonDeployment.setup()
        topology_started = True
        print("JetsonDeployment setup complete.", flush=True)

        print("Flight software is running. Stop the systemd service to exit.", flush=True)

        while running:
            time.sleep(1)

    except Exception:
        print("ERROR: Python exception from fsw_main.py:", flush=True)
        traceback.print_exc()

    finally:
        if topology_started:
            try:
                print("Calling fprime_py.JetsonDeployment.teardown()...", flush=True)
                fprime_py.JetsonDeployment.teardown()
                print("JetsonDeployment teardown complete.", flush=True)
            except Exception:
                print("ERROR: Exception during JetsonDeployment teardown:", flush=True)
                traceback.print_exc()

        print("Exiting fsw_main.py with os._exit(0).", flush=True)

        # Required for now:
        # fprime_py currently segfaults during normal Python interpreter cleanup.
        # This exits the process without running Python/native module destructors.
        os._exit(0)


if __name__ == "__main__":
    main()