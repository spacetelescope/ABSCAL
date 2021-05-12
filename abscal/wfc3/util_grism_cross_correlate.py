#! /usr/bin/env python
"""
This module takes the name of an input metadata table, groups the exposures in 
that table by program and visit, and then:
    - calibrates each exposue
    - coadds together all exposures that have the same program/visit/star

Authors
-------
    - Brian York (all python code)
    - Ralph Bohlin (original IDL code)

Use
---
    This module is intended to be either run from the command line or used by
    other module code as the first step (creating an annotated list of files 
    for flux calibration).
    ::
        python coadd_grism.py <input_file>

Dependencies
------------
    - ``astropy``
"""

__all__ = ['coadd']

import datetime
import glob
import json
import os

import numpy as np

from astropy import wcs
from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy
from scipy import signal

from abscal.common.args import parse
from abscal.common.utils import get_data_file, set_params
from abscal.common.exposure_data_table import AbscalDataTable

def cross_correlate(s1, s2, row, arg_list, overrides={}):
    """
    Reduces and co-adds grism data
    """
    verbose = arg_list.verbose
    interactive = arg_list.trace
    task = "cross_correlate"
    preamble = "{}: {}".format(task, row['root'][0])

    if verbose:
        print("{}: Starting WFC3 cross-correlation of GRISM data.".format(task))

    known_issues_file = get_data_file("abscal.wfc3", "known_issues.json")
    with open(known_issues_file, 'r') as inf:
        known_issues = json.load(inf)
    issues = []
    if "reduction" in known_issues:
        if "cross_correlate" in known_issues["reduction"]:
            issues = known_issues["reduction"]["cross_correlate"]
    
    defaults = {
                'ishift': 0,
                'width': 15,
                'i1': 0,
                'i2': -1
               }
    defaults['i2'] = len(s1) - 1
    params = set_params(defaults, row, issues, preamble, overrides, verbose)
    approx = int(round(params['ishift']))

    # extract template from spectrum 2 (s2)
    ns2 = len(s1)//2
    width2 = int(params['width']//2)
    it2_start = int(max((params['i1'] - approx + width2), 0))
    it2_end = int(min((params['i2'] - approx - width2), len(s1)-1))
    nt = it2_end - it2_start + 1
    if nt < 1:
        if verbose:
            msg = "{}: region too small, width too large, or ishift too large."
            print(msg.format(task))
        return 0., None
    template2 = s2[it2_start:it2_end+1]
    
    # Correlation Time!
    corr = np.zeros(int((params['width']),), dtype='float64')
    mean2 = np.sum(template2)/nt
    sig2 = np.sqrt(np.sum((template2-mean2)**2))
    diff2 = template2 - mean2
    
    for i in range(int(params['width'])):
        # Find region in first spectrum
        it1_start = it2_start - width2 + approx + i
        it1_end = it1_start + nt
        template1 = s1[it1_start:it1_end]
        mean1 = np.sum(template1)/nt
        sig1 = np.sqrt(np.sum((template1-mean1)**2))
        diff1 = template1 - mean1
        if (sig1 == 0) or (sig2 == 0):
            if verbose:
                print("{}: zero variance computed".format(task))
            return 0., None
        corr[i] = np.sum(diff1*diff2)/(sig1*sig2)
    
    # Find maximum
    maxc, maxi = np.max(corr), np.argmax(corr)
    if maxi == 0 or maxi == params['width']-1:
        if verbose:
            print("{}: maximum found at edge of search area".format(preamble))
        return 0., None
    
    # Refine with the power of QUADRATICS!
    kmin = (corr[maxi-1]-corr[maxi])/(corr[maxi-1]+corr[maxi+1]-2*corr[maxi])-0.5
    offset = maxi + kmin - width2 + approx
    
    if verbose:
        print("{}: offset {} from translated code.".format(preamble, offset))

    np_corr = np.correlate(s1, s2, mode='same')
    np_maxc = np.max(np_corr)
    np_maxi = np.argmax(np_corr)
    np_kmin = (np_corr[np_maxi-1] - np_corr[np_maxi])
    np_kmin /= (np_corr[np_maxi-1] + np_corr[np_maxi+1] - 2*np_corr[np_maxi])
    np_kmin -= 0.5
    np_offset = np_maxi + np_kmin - len(np_corr)//2 + approx
    
    if verbose:
        print("{}: numpy offset calculated as {}.".format(preamble, np_offset))
    
    return offset, corr


def parse_args():
    """
    Parse command-line arguments.
    """
    description_str = 'Process files from metadata table.'
    default_output_file = 'ir_image_stare_location.log'
    
    table_help = "The input metadata table to use."
   
    table_args = ['table']
    table_kwargs = {'help': table_help}
    
    additional_args = [(table_args, table_kwargs)]
    
    res = parse(description_str, default_output_file, additional_args)
    
    if res.paths is not None: 
        if "," in res.paths:
            res.paths = res.paths.split(",")
        else:
            res.paths = [res.paths]
    else:
        res.paths = []
    
    if res.table is None:
        res.table = "dirtemp.log"
    
    if len(res.paths) == 0:
        res.paths.append(os.getcwd())
    
    return res


def main(overrides={}):
    res = parse_args()
    
    for key in overrides:
        if hasattr(res, key):
            setattr(res, key, overrides[key])
    
    input_table = AbscalDataTable(table=res.table,
                                  duplicates=res.duplicates,
                                  search_str='',
                                  search_dirs=res.paths)

    output_table = cross_correlate(input_table, overrides, res)
    
    table_fname = res.out_file
    output_table.write_to_file(table_fname, res.compat)


if __name__ == "__main__":
    main()
