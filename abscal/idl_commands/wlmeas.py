#! /usr/bin/env python
"""
This module acts as an IDL interface to the 'wlmeas' part of the WFC3 
'reduce_wl_process' script. It calls that script with IDL compatibility set to 
True.

Author
-------
    - Brian York

Use
---
    This module is intended to be run from the command line.
    ::
        python wlmeas.py <file_path>
"""

__all__ = []

from abscal.wfc3.reduce_grism_wavelength import main as do_wl_process


def main():

    overrides = {}
#     overrides['compat'] = True

    do_wl_process(overrides=overrides, do_meas=True, do_make=False)


if __name__ == "__main__":
    main()
