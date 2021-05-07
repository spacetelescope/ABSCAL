#! /usr/bin/env python
"""
This module acts as an interface to the 'wlmeas' part of the WFC3 'reduce_wl_process' 
script. 

Author
-------
    - Brian York

Use
---
    This module is intended to be run from the command line.
    ::
        python wfc3_wave_find_lines.py <file_path>
"""

__all__ = []

from abscal.wfc3.reduce_grism_wavelength import main as do_wl_process


def main():

    overrides = {}
#     overrides['compat'] = True

    do_wl_process(overrides=overrides, do_measure=True, do_make=False)


if __name__ == "__main__":
    main()
