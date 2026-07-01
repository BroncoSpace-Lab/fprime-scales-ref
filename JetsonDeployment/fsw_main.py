#!/usr/bin/env python3

"""
fsw_main.py

Main entry point for launching the JetsonDeployment F Prime topology from Python.

This version:
  - Calls setup_custom(), which initializes and starts F Prime active tasks.
  - Uses the native C++ Drv.TcpServer communication driver.
  - Starts the blocking C++ LinuxTimer in a Python thread.
  - Keeps Python alive while the C++ topology runs.
"""

import argparse
import os
import signal
import sys
import threading
import time
import traceback

import fprime_py

SHUTDOWN_REQUESTED = False


# ----------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------

FSW_MAIN_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_ROOT = os.environ.get("FPRIME_SCALES_ROOT")
if PROJECT_ROOT is None:
    PROJECT_ROOT = os.path.abspath(os.path.join(FSW_MAIN_DIR, "..", ".."))

PYTHON_ARTIFACT_DIR = FSW_MAIN_DIR
ML_COMPONENT_DIR = os.path.join(PROJECT_ROOT, "Components", "MLComponent")
RESNET_DIR = os.path.join(ML_COMPONENT_DIR, "Scales-ML", "resnet")


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

def add_python_paths():
    paths = [
        PYTHON_ARTIFACT_DIR,
        PROJECT_ROOT,
        ML_COMPONENT_DIR,
        RESNET_DIR,
    ]

    for path in reversed(paths):
        if os.path.isdir(path) and path not in sys.path:
            sys.path.insert(0, path)


def expose_fprime_py_namespaces():
    """
    Some generated Python components expect generated fprime_py namespaces
    to be importable as top-level modules.
    """
    for name in dir(fprime_py):
        if name.startswith("_"):
            continue

        obj = getattr(fprime_py, name)

        if hasattr(obj, "__name__"):
            sys.modules.setdefault(name, obj)


def parse_args():
    parser = argparse.ArgumentParser(
        description="JetsonDeployment F Prime Python Flight Software Entry Point"
    )

    parser.add_argument(
        "--hostname",
        type=str,
        default="0.0.0.0",
        help="Hostname/address used by JetsonDeployment TopologyState",
    )

    parser.add_argument(
        "--port",
        type=int,
        default=50000,
        help="Port used by JetsonDeployment TopologyState",
    )

    return parser.parse_args()


def handle_signal(signum, frame):
    global SHUTDOWN_REQUESTED

    print(f"[INFO] Received signal {signum}; shutting down", flush=True)
    SHUTDOWN_REQUESTED = True


def print_available_bindings():
    print(
        "Available fprime_py bindings:",
        [x for x in dir(fprime_py) if not x.startswith("_")],
        flush=True,
    )

    print(
        "Available JetsonDeployment bindings:",
        [x for x in dir(fprime_py.JetsonDeployment) if not x.startswith("_")],
        flush=True,
    )

    if hasattr(fprime_py.JetsonDeployment, "Instances"):
        print(
            "Available JetsonDeployment instances:",
            [x for x in dir(fprime_py.JetsonDeployment.Instances) if not x.startswith("_")],
            flush=True,
        )


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

def fsw_main():
    add_python_paths()
    expose_fprime_py_namespaces()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    args = parse_args()

    topology_state = fprime_py.TopologyState()
    topology_state.hostname = args.hostname
    topology_state.port = args.port

    topology_started = False
    rate_groups_started = False
    rate_group_thread = None

    try:
        print("[INFO] JetsonDeployment fprime-python module loaded:", fprime_py, flush=True)
        print("[INFO] Python executable:", sys.executable, flush=True)
        print("[INFO] Working directory:", os.getcwd(), flush=True)
        print("[INFO] PROJECT_ROOT:", PROJECT_ROOT, flush=True)
        print("[INFO] PYTHON_ARTIFACT_DIR:", PYTHON_ARTIFACT_DIR, flush=True)
        print("[INFO] ML_COMPONENT_DIR:", ML_COMPONENT_DIR, flush=True)
        print("[INFO] RESNET_DIR:", RESNET_DIR, flush=True)

        print_available_bindings()

        print("[INFO] Initializing F Prime OS layer", flush=True)
        fprime_py.Os.init()

        print(
            f"[INFO] Launching JetsonDeployment with hostname={args.hostname}, port={args.port}",
            flush=True,
        )

        # setup_custom calls JetsonDeployment::setupTopology(topology_state).
        # It initializes, wires, configures, registers commands, loads
        # parameters, starts active component tasks, and starts the TCP server.
        fprime_py.JetsonDeployment.setup_custom(topology_state)
        topology_started = True

        print("[INFO] JetsonDeployment setup complete", flush=True)
        print("[INFO] Starting C++ timer/rate groups", flush=True)
        rate_group_thread = threading.Thread(
            target=fprime_py.JetsonDeployment.start_rate_groups_custom,
            name="JetsonRateGroups",
            daemon=True,
        )
        rate_group_thread.start()
        rate_groups_started = True

        print("[INFO] C++ TCP server and timer are running", flush=True)
        print("[INFO] Python launcher is staying alive", flush=True)

        while not SHUTDOWN_REQUESTED:
            time.sleep(1)

    except Exception:
        print("[ERROR] Failed to start JetsonDeployment", flush=True)
        traceback.print_exc()

    finally:
        if rate_groups_started:
            try:
                print("[INFO] Stopping rate groups", flush=True)
                fprime_py.JetsonDeployment.stop_rate_groups_custom()
                if rate_group_thread is not None:
                    rate_group_thread.join(timeout=5.0)
                rate_groups_started = False
            except Exception:
                print("[ERROR] Exception while stopping rate groups", flush=True)
                traceback.print_exc()

        if topology_started:
            try:
                print("[INFO] Tearing down JetsonDeployment", flush=True)
                fprime_py.JetsonDeployment.teardown_custom(topology_state)
                print("[INFO] F Prime shutdown complete", flush=True)
            except Exception:
                print("[ERROR] Exception during JetsonDeployment teardown", flush=True)
                traceback.print_exc()

        os._exit(0)


if __name__ == "__main__":
    fsw_main()