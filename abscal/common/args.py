#! /usr/bin/env python
"""
This module includes an argument-parsing function which adds common arguments,
and accepts additional arguments, then returns the parsed arguments. It is 
intended to be imported by modules that are run from the command line.

Authors
-------
    - Brian York

Use
---
    This module is intended to be imported for argument parsing.
    ::
        from abscal.common.args import parse
        
        description = "Description for the module"
        default_out_file = "default_output_file_name.ext"
        arg_list = []
        arg = [{positional arguments to add_argument}, {keyword arguments same}]
        arg_list.append(arg)
        ...
        res = parse(description, default_out_file, arg_list)
"""

import argparse


__all__ = ['parse']


def parse(description_str, default_out_file, arg_list):
    path_help = "A comma-separated list of input paths."
    
    in_help = "Optional input table file. If provided, the program will begin "
    in_help += "by reading the input table and adding all of its exposures to "
    in_help += "the metadata table. See the duplicates flag for options on "
    in_help += "processing duplicate entries."
    
    out_help = "Output metadata file. The default value is "
    out_help += "{} ".format(default_out_file)
    out_help += "where item is 'all' for all files, 'grism' for grism files "
    out_help += "(and associated filter images), 'filter' is filter files, and "
    out_help += "'scan' is all scan-mode files."
    
    spec_help = "Subdirectory where extracted and co-added spectra are stored."
    
    compat_help = "Activate strict compatibility mode. In this mode, the "
    compat_help += "script will produce output that is as close as possible to "
    compat_help += "indistinguishable from the IDL code"
    
    user_help = "Include user interaction, and result plots while running."

    verbose_help = "Print diagnostic information while running."

    parser = argparse.ArgumentParser(description=description_str)
    parser.add_argument('-p', '--paths', dest='paths', help=path_help)
    parser.add_argument('-i', '--input', dest='in_file', help=in_help,
                        default=None)
    parser.add_argument('-o', '--output', dest='out_file', help=out_help,
                        default=default_out_file)
    parser.add_argument('-s', '--spec_dir', dest='spec_dir', help=spec_help,
                        default='spec')
    parser.add_argument('-c', '--strict_compat', dest="compat", 
                        action='store_true', default=False, help=compat_help)
    parser.add_argument('-i', '--interactive', dest="user_interaction",
                        action='store_true', default=False, help=user_help)
    parser.add_argument('-v', '--verbose', dest="verbose",
                        action='store_true', default=False, help=verbose_help)
    for args,kwargs in arg_list:
        parser.add_argument(*args, **kwargs)

    res = parser.parse_args()
    
    return res
