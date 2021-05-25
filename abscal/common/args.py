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

This module is intended to be imported for argument parsing::

    from abscal.common.args import parse

    description = "Description of the sub-module defined in this file"
    default_out_file = "default_output_file_name.ext"
    arg_list = []
    
    # For each additional (non-common) argument that needs to be available for the
    # sub-module, create a list where the first item is a list of the positional arguments
    # to argparse.ArgumentParser.add_argument(), and the second item is a dictionary of
    # the keyword arguments.
    arg = [<positional arguments to add_argument>, <keyword arguments same>]
    arg_list.append(arg)
    ...
    res = parse(description, default_out_file, arg_list, **kwargs)
"""

import argparse
import os

from .utils import get_defaults

def parse(description, default_out_file, arg_list, **kwargs):
    """
    Create an ArgumentParser, add in the common arguments that everything in ABSCAL uses 
    (along with any custom arguments passed in), parse the provided arguments, and return 
    the results object.
    
    Parameters
    ----------
    description : str
        Description of the sub-module to be printed in --help
    default_out_file : str
        Name of the default output file produced by the sub-module
    arg_list : list
        List of custom arguments, consisting of tuples of (<fixed arguments list>,
        <keyword argument dict>)
    kwargs : dict
        Keyword parameters, including
        
        split_output: bool, default True
            If multiple output files are created based on some characteristic, set this to 
            True
    
    Returns
    -------
    res : populated namespace
        Result of parsing all of the command-line arguments.
    """
    
    default_values = get_defaults('abscal.common.args')
    split_output = kwargs.get('split_output', default_values['split_output'])

    path_help = "A comma-separated list of input paths."
    
    in_help = "Optional additional input table file. If provided, the program "
    in_help += "will begin by reading the input table and adding all of its "
    in_help += "exposures to the metadata table. See the duplicates flag for "
    in_help += "options on processing duplicate entries."
    
    if split_output:
        out_file, out_ext = os.path.splitext(default_out_file)
        out_name = "{}_<item>{}".format(out_file, out_ext)
        out_help = "Output metadata file. The default value is "
        out_help += "{} where item is 'all' for all files, 'grism' for ".format(out_name)
        out_help += "grism files (and associated filter images), 'filter' is filter "
        out_help += "files, and 'scan' is all scan-mode files."
    else:
        out_name = default_out_file
        out_help = "Output metadata file. The default value is {}.".format(out_name)
    
    spec_help = "Subdirectory where extracted and co-added spectra are stored. "
    spec_help += "The default value is 'spec'."
    
    compat_help = "Activate strict compatibility mode. In this mode, the "
    compat_help += "script will produce additional output that is as close as possible "
    compat_help += "to indistinguishable from the IDL code. (default False)"
    
    force_help = "Force steps to run even if output already exists."
    
    verbose_help = "Print diagnostic information while running."

    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--paths', dest='paths', help=path_help)
    parser.add_argument('-i', '--input', dest='in_file', help=in_help,
                        default=default_values['in_file'])
    parser.add_argument('-o', '--output', dest='out_file', help=out_help,
                        default=default_out_file)
    parser.add_argument('-s', '--spec_dir', dest='spec_dir', help=spec_help,
                        default=default_values['spec_dir'])
    parser.add_argument('-c', '--strict_compat', dest="compat", 
                        action='store_true', default=default_values['compat'], 
                        help=compat_help)
    parser.add_argument('-f', '--force', dest="force", action="store_true",
                        default=default_values['force'], help=force_help)
    parser.add_argument('-v', '--verbose', dest="verbose",
                        action='store_true', default=default_values['verbose'], 
                        help=verbose_help)
    for arg_name in arg_list.keys():
        args, kwargs = arg_list[arg_name]
        parser.add_argument(*args, **kwargs)
    
    res = parser.parse_args()
    
    return res
