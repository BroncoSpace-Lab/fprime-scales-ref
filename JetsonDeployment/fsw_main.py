#!/usr/bin/env python3

"""
fsw_main.py

Main entry point for launching the JetsonDeployment F Prime topology from Python.

This version is adapted for the current JetsonDeployment topology, which uses
jetson_comDriver / jetson_comQueue / jetson_comStub / framer / deframer /
fprimeRouter instead of a ReferenceDeployment pythonCom instance.
"""

import argparse
import os
import signal
import sys
import time
import traceback

import fprime_py


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


running = True


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
        default="127.0.0.1",
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
    global running
    print(f"[INFO] Received signal {signum}; shutting down", flush=True)
    running = False


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


def fsw_main():
    global running

    add_python_paths()
    expose_fprime_py_namespaces()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    args = parse_args()

    topology_state = fprime_py.TopologyState()
    topology_state.hostname = args.hostname
    topology_state.port = args.port

    topology_started = False

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

        fprime_py.JetsonDeployment.setup_custom(topology_state)
        topology_started = True

        print("[INFO] JetsonDeployment setup complete", flush=True)
        print("[INFO] Flight software is running. Stop service or press CTRL-C to exit.", flush=True)

        while running:
            time.sleep(1)

    except KeyboardInterrupt:
        print("[INFO] CTRL-C received, shutting down F Prime", flush=True)

    except Exception:
        print("[ERROR] Failed to start JetsonDeployment", flush=True)
        traceback.print_exc()
FWAR
    finally:
        if topology_started:
            try:
                print("[INFO] Tearing down JetsonDeployment", flush=True)
                fprime_py.JetsonDeployment.teardown_custom(topology_state)
                print("[INFO] F Prime shutdown complete", flush=True)
            except Exception:
                print("[ERROR] Exception during JetsonDeployment teardown", flush=True)
                traceback.print_exc()

        # Avoid Python interpreter shutdown problems with native F Prime threads/libs.
        os._exit(0)


if __name__ == "__main__":
    fsw_main()