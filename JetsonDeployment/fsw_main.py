#!/usr/bin/env python3

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

# Preferred path source:
# jetson-python.sh exports this dynamically from its own location.
PROJECT_ROOT = os.environ.get("FPRIME_SCALES_ROOT")

# Fallback:
# fsw_main.py runs from build-artifacts/python, so repo root is ../..
if PROJECT_ROOT is None:
    PROJECT_ROOT = os.path.abspath(os.path.join(FSW_MAIN_DIR, "..", ".."))

PYTHON_ARTIFACT_DIR = FSW_MAIN_DIR
ML_COMPONENT_DIR = os.path.join(PROJECT_ROOT, "Components", "MLComponent")
RESNET_DIR = os.path.join(ML_COMPONENT_DIR, "Scales-ML", "resnet")


def add_python_paths():
    """
    Add repo-relative Python import paths.

    This supports imports like:
        import resnet_cifar100
        import resnet_inference

    without hardcoding /home/jpl-jetson or any specific device username.
    """
    paths = [
        PYTHON_ARTIFACT_DIR,
        PROJECT_ROOT,
        ML_COMPONENT_DIR,
        RESNET_DIR,
    ]

    for path in paths:
        if os.path.isdir(path) and path not in sys.path:
            sys.path.insert(0, path)

    print("Resolved PROJECT_ROOT:", PROJECT_ROOT, flush=True)
    print("Resolved PYTHON_ARTIFACT_DIR:", PYTHON_ARTIFACT_DIR, flush=True)
    print("Resolved ML_COMPONENT_DIR:", ML_COMPONENT_DIR, flush=True)
    print("Resolved RESNET_DIR:", RESNET_DIR, flush=True)
    print("Python sys.path:", sys.path, flush=True)


def expose_fprime_py_namespaces():
    """
    Expose fprime_py submodules as top-level modules.

    This allows Python components to do:
        import Fw
        import Components
        import Svc
        import Drv
        import Os

    even though the actual bindings live under:
        fprime_py.Fw
        fprime_py.Components
        fprime_py.Svc
        fprime_py.Drv
        fprime_py.Os
    """
    for name in dir(fprime_py):
        if name.startswith("_"):
            continue

        obj = getattr(fprime_py, name)

        # pybind11 submodules are module-like and have __name__.
        if hasattr(obj, "__name__"):
            sys.modules.setdefault(name, obj)


# This must happen before JetsonDeployment.setup(...), because setup loads
# the Python component implementation.
add_python_paths()
expose_fprime_py_namespaces()


# ----------------------------------------------------------------------
# Runtime state
# ----------------------------------------------------------------------

running = True
topology_started = False
topology_state = None


def handle_signal(signum, frame):
    global running
    print(f"Received signal {signum}; shutting down...", flush=True)
    running = False


def make_topology_state():
    """
    Create the JetsonDeployment TopologyState required by:
        fprime_py.JetsonDeployment.setup(topology_state)

    Requires the C++ setup_user_deployment(...) hook to bind:
        fprime_py.TopologyState
    """
    state = fprime_py.TopologyState()

    hostname = "127.0.0.1"
    port = 50000

    state.hostname = hostname
    state.port = port

    return state, hostname, port


def main():
    global topology_started
    global topology_state

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print("JetsonDeployment fprime-python module loaded:", fprime_py, flush=True)
    print("Python executable:", sys.executable, flush=True)
    print("Working directory:", os.getcwd(), flush=True)

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

    try:
        print("Creating JetsonDeployment TopologyState...", flush=True)
        topology_state, hostname, port = make_topology_state()
        print(
            f"TopologyState created: hostname={hostname}, port={port}",
            flush=True,
        )

        print("Initializing F Prime OS layer...", flush=True)
        fprime_py.Os.init()
        print("F Prime OS layer initialized.", flush=True)

        print("Calling fprime_py.JetsonDeployment.setup(topology_state)...", flush=True)
        fprime_py.JetsonDeployment.setup(topology_state)
        topology_started = True
        print("JetsonDeployment setup complete.", flush=True)

        print("Flight software is running. Stop the systemd service to exit.", flush=True)

        heartbeat_count = 0

        while running:
            time.sleep(5)
            heartbeat_count += 1
            print(
                f"Heartbeat {heartbeat_count}: JetsonDeployment Python wrapper alive",
                flush=True,
            )

    except Exception:
        print("ERROR: Python exception from fsw_main.py:", flush=True)
        traceback.print_exc()

    finally:
        if topology_started and topology_state is not None:
            try:
                print("Calling fprime_py.JetsonDeployment.teardown(topology_state)...", flush=True)
                fprime_py.JetsonDeployment.teardown(topology_state)
                print("JetsonDeployment teardown complete.", flush=True)
            except Exception:
                print("ERROR: Exception during JetsonDeployment teardown:", flush=True)
                traceback.print_exc()

        print("Exiting fsw_main.py with os._exit(0).", flush=True)

        # Temporary workaround:
        # The native fprime_py module currently segfaults during normal Python
        # interpreter shutdown. This exits the process without running Python's
        # final native-module cleanup/destructors.
        os._exit(0)


if __name__ == "__main__":
    main()