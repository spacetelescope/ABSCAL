#! /usr/bin/env python
"""
This module acts as an interface to the WFC3 'reduce_grism' script.

Author
-------
    - Brian York

Use
---
    This module is intended to be run from the command line.
    ::
        python wfc3_extract.py <input_table> [options]
"""

__all__ = []

from abscal.wfc3.reduce_grism_coadd import main as do_coadd


def main():

    overrides = {}
#     overrides['compat'] = True

    do_coadd(overrides=overrides)


if __name__ == "__main__":
    main()
