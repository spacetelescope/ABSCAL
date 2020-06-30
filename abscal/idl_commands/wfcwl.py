#! /usr/bin/env python
"""
This module acts as an IDL interface (using the newly created 'wfcwl' name) 
to the WFC3 'reduce_wl_process' script. It calls that script with IDL 
compatibility set to True.

Author
-------
    - Brian York

Use
---
    This module is intended to be run from the command line.
    ::
        python wlprocess.py <file_path>
"""

__all__ = []

from abscal.wfc3.reduce_grism_wavelength import main as do_wl_process


def main():

    do_wl_process(overrides={'compat': True})


if __name__ == "__main__":
    main()
