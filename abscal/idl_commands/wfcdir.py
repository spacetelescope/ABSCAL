#! /usr/bin/env python
"""
This module acts as an IDL interface (using the IDL 'wfcdir' name) to the WFC3
'create_table' script. It calls that script with IDL compatibility set to True.

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

from abscal.wfc3.preprocess_table_create import main as do_create


def main():

    overrides = {}
#     overrides['compat'] = True

    do_create(overrides=overrides)


if __name__ == "__main__":
    main()
