#!/usr/bin/env python3

"""
fsw_main.py

Main entry point for launching QualcommDeployment F Prime topology from Python.

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
