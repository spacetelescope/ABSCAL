#! /usr/bin/env python
"""
This module takes the name of an input metadata table, groups the exposures in 
that table by program and visit, and then:
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

__all__ = ['wlprocess']

import datetime
import glob
import json
import os

import matplotlib.pyplot as plt
import numpy as np

from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy
from pathlib import Path
from scipy.stats import mode

from abscal.common.args import parse
from abscal.common.utils import air2vac, get_data_file, set_params, smooth_model
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.wfc3.reduce_grism_extract import reduce
from abscal.wfc3.reduce_grism_extract import additional_args as extract_args
from abscal.wfc3.util_grism_cross_correlate import cross_correlate


def wlmeas(initial_table, arg_list, overrides={}):
    """
    Measures planetary nebula emission lines for wavelength fitting
    """
    task = "wlmeas"
    verbose = arg_list.verbose
    interactive = arg_list.trace
    
    fwhm = [80., 40, 120., 60]
    
    # lab reference line wavelengths
    wl_air = np.array([9068.6, 9532.5, 10830., 12818.1, 16109.3, 16407.2])
    wl_vac = air2vac(wl_air)
    
    # Get wavelength reference file
    cal_data = get_data_file("abscal.wfc3", "calibration_files.json")
    with open(cal_data, 'r') as inf:
        cal_files = json.load(inf)
    pn_ref_name = cal_files["ic5117_data"]["wfc3"]
    pn_ref = get_data_file("abscal.wfc3", pn_ref_name)
    
    # Columns are 'wavelength' and 'flux'
    pn_ref_table = Table.read(pn_ref, format="ascii.basic")
    
    input_table = deepcopy(initial_table)
    input_table = input_table[input_table["planetary_nebula"] == True]

    if verbose:
        msg = "{}: Starting WFC3 wavelength measurement for GRISM data."
        print(msg.format(task))
        print("{}: Input table is:".format(task))
        print(input_table)
    
    known_issues_file = get_data_file("abscal.wfc3", "known_issues.json")
    with open(known_issues_file, 'r') as inf:
        known_issues = json.load(inf)
    input_table.adjust(known_issues['wlmeas'])
    issues = []
    if "wlmeas" in known_issues:
        issues = known_issues["wlmeas"]
    
    for row in input_table:
        
        file = os.path.join(row["path"], row["filename"])
        with fits.open(file) as inf:
            wl = inf[1].data['wave']
            net = inf[1].data['net']
            dq = inf[1].data['eps']
            zxpos = inf[1].header['xzorder']
            zypos = inf[1].header['yzorder']
            grat = inf[0].header['filter']
            star = inf[0].header['targname']
        
        pltnet = deepcopy(net)
        
        # Bad DQ values are 256 (saturated), 516 (FF glitches),
        # and 32 (CTE tail) as per Table 2.5
        bad = np.where((dq & (32|256|512)) != 0)
        nbad = len(bad[0])
        if nbad > 0:
            pltnet[bad] = 1.6e38
        
        name = row['root'][5:9]
        
        if grat == 'G102':
            wrang = [8900., 11100.]
        elif grat == 'G141':
            wrang = [10800., 17500.]
        else:
            raise ValueError("Unknown Grating/Filter {}".format(grat))
        
        # -71.2 radial velocity for IC-5117?
        pnvel = -71.2
        
        if "G111" in star:
            pnvel = -5.
        
        # PN velocity - radial velocity of -26.1
        vel = pnvel + 26.1
        
        wrud = pn_ref_table['wavelength'] * (1. + vel/3.e5)
        wlref = wlvac * (1. + pnvel/3.e5)
        
        for iord in [-1, 1, 2]:
        
            fwhm_index = abs(iord) - 1
            if grat == 'G141':
                fwhm_index += 2
            
            dlam = fwhm[fwhm_index]
            
            # 3rd order 10830 at 32490 dominates 2nd order beyond ~16245 
            # (32490/2)
            if iord == 2 and grat == 'G141':
                wrang[1] = 13000.
            
            xline = wlref * 0.
            
            for ilin in range(len(wlref)):
                wv = wlvac[ilin]
                wl_line = wl/iord
                wlr = wlref[ilin]
                
                # All of these indicate that the line we're looking for isn't
                # in the order we're looking at.
                if wrang[1] > max(wl_line) or wv < wrang[0] or wv > wrang[1]:
                    continue
                
                # smoothed lines
                smorud = smooth_model(wrud, pn_ref_table['flux'], dlam)
                if grat == 'G102':
                    dw = 150/abs(iord)
                else:
                    dw = 250/abs(iord)
                
                xgdrud = np.where((wrud > wlr - dw) and (wl/iord < wlr+dw))

        params = set_params(defaults, row, issues, preamble, overrides, verbose)
    

            if verbose:
                print("{}: Finished filter.".format(preamble))
        if verbose:
            print("{}: {}: Finished obs".format(task, obs))
    if verbose:
        print("{}: finished wavelength measurement.".format(task))
    
    return input_table
        


def additional_args():
    """
    Additional command-line arguments. Used when a single command may run
    another command, and need to add arguments from it.
    """
    
    additional_args = {}
    
    table_help = "The input metadata table to use."
    table_args = ['table']
    table_kwargs = {'help': table_help}
    additional_args['table'] = (table_args, table_kwargs)

    double_help = "Subsample output wavelength vector by a factor of 2."
    double_args = ["-d", "--double"]
    double_kwargs = {'help': double_help, 'default': False, 
                     'action': 'store_true', 'dest': 'double'}
    additional_args['double'] = (double_args, double_kwargs)
    
    prefix_help = "Prefix for co-added spectra"
    prefix_args = ['--prefix']
    prefix_kwargs = {'help': prefix_help, 'default': None,
                     'dest': 'prefix'}
    additional_args['prefix'] = (prefix_args, prefix_kwargs)

    trace_help = "Include result plots while running."
    trace_args = ["-t", "--trace"]
    trace_kwargs = {'dest': 'trace', 'action': 'store_true', 'default': False,
                    'help': trace_help}
    additional_args['trace'] = (trace_args, trace_kwargs)
        
    return additional_args


def parse_args():
    """
    Parse command-line arguments.
    """
    description_str = 'Process files from metadata table.'
    default_output_file = 'wlmeastmp.log'
    
    args = additional_args()
    # Add in extraction args because coadd can call extraction and thus may
    #   need to supply arguments to it.
    extracted_args = extract_args()
    for key in extracted_args.keys():
        if key not in args:
            args[key] = extracted_args[key]
    
    res = parse(description_str, default_output_file, args)
    
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
    parsed = parse_args()
    
    for key in overrides:
        if hasattr(parsed, key):
            setattr(parsed, key, overrides[key])
    
    input_table = AbscalDataTable(table=parsed.table,
                                  duplicates='both',
                                  search_str='',
                                  search_dirs=parsed.paths,
                                  idl=parsed.compat)

    output_table = wlprocess(input_table, parsed, overrides)
    
    table_fname = parsed.out_file
    output_table.write_to_file(table_fname, parsed.compat)


if __name__ == "__main__":
    main()
