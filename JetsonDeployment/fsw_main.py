#!/usr/bin/env python3

import fprime_py


def main():
    # This file is the Python-side entrypoint for the Jetson deployment.
    # The exact topology startup call depends on the generated fprime_py API.
    #
    # After building, inspect the generated python/fprime_py*.so API or copy
    # the pattern from fprime-python-reference/ReferenceDeployment/fsw_main.py.
    print("JetsonDeployment fprime-python module loaded:", fprime_py)


if __name__ == "__main__":
    main()