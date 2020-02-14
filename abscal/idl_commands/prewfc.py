#! /usr/bin/env python
"""
This module acts as an IDL interface (using the IDL 'prewfc' name) to the WFC3
'reduce_grism' script. It calls that script with IDL compatibility set to True.

Author
-------
    - Brian York

Use
---
    This module is intended to be run from the command line.
    ::
        python wfcdir.py <file_path>
"""

__all__ = []

from abscal.wfc3.reduce_grism_coadd import main as do_coadd


def main():

    do_coadd(overrides={'compat': True})


if __name__ == "__main__":
    main()
