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
from abscal.common.utils import get_data_file, set_param
from abscal.common.exposure_data_table import AbscalDataTable

def locate_image(input_table, verbose=False):
    """
    Reduces and co-adds grism data
    """
    if verbose:
        print("Starting WFC3 image location check for FILTER data.")
    
    known_issues = json.loads(get_data_file("abscal.wfc3", "known_issues.json"))
    input_table.adjust(known_issues['metadata'])
    issues = known_issues["reduction"]["locate_image"]
    
    for row in input_table:
        root = row['root']
        # Only locate filter data in the locate_image function.
        if row['use'] and row['filter'][0] == 'F':
            if verbose:
                print("Locating image for {}".format(root))
            input_file = os.path.join(row['path'], row['filename'])
            crval1 = row['crval1']
            crval2 = row['crval2']
            
            xstar = set_param("xstar", 0, row, issues, verbose)
            ystar = set_param("ystar", 0, row, issues, verbose)            
            
            with fits.open(input_file) as inf:
                data = inf['SCI'].data
                dq = inf['DQ'].data
                data[np.where(dq&32 != 0)] = 0.
                
                orig = deepcopy(data)
                
                # Set data edges to zero
                data[:20,:] = 0.
                data[-30:,:] = 0.
                data[:,:10] = 0.
                data[:,-10:] = 0.
                
                wcs = wcs.WCS(inf['SCI'].header)
                ra = inf[0].header["RA_TARG"]
                dec = inf[0].header["DEC_TARG"]
                targ = wcs.wcs_world2pix([ra, dec], 0)
                xastr, yastr = targ[1], targ[0]
                xappr, yappr = xastr, yastr
                if verbose:
                    msg = "{} has image astrometry position ({},{})"
                    print(msg.format(root, xastr, yastr))
                
                if (xstar == 0) and (ystar == 0) and ((xappr <= 3) or (xappr >= data.shape[1]-4)):
                    row['xc'] = 0
                    row['yc'] = 0
                    if verbose:
                        msg = "{}: target at edge. Set xc=yc=0.".format(root)
                        print(msg)
                    continue
                if xstar != 0 or ystar != 0:
                    xappr = xstar
                    yappr = ystar
                
                # Set data to zero except around the approximate target location
                data[:,:max(xappr-35,0)] = 0.
                data[:,min(xappr+35,data.shape[1]-1):] = 0.
                data[:max(yappr-35,0),:] = 0.
                data[min(yappr+35,data.shape[0]-1):,:] = 0.
                
                # Perform a median filter of the data.
                med_data = signal.median2d(data, kernel_size=3)
                # Get the index of the array (as reshaped into a 1D array)
                argmax = np.argmax(med_data, axis=None)
                # Convert the index into a 2D x/y co-ordinate
                position = np.unravel_index(argmax, med_data.shape)
                
                x1 = max(position[1]-10, 0)
                x2 = min(position[1]+21, data.shape[1]-1)
                y1 = max(position[0]-10, 0)
                y2 = min(position[0]+21, data.shape[0]-1)
                
                subimage = data[y1:y2,x1:x2]
                # IDL code does not supply kernel size, but online documentation
                #   does not seem to indicate what the default is.
                subimage -= signal.median2d(subimage, kernel_size=3)
                subimage -= subimage.max()/5
                subimage = np.where(subimage>=0., subimage, 0.)
                
                x = np.arange(x2-x1+1) + x1
                xprofile = np.sum(subimage, axis=1)
                xc = np.sum(xprofile*x)/np.sum(xprofile)
                xerr = xc - xastr

                y = np.arange(y2-y1+1) + y1
                yprofile = np.sum(subimage, axis=0)
                yc = np.sum(yprofile*y)/np.sum(yprofile)
                yerr = yc - yastr
                
                input_table[input_table['root']==root]['xc'] = xc
                input_table[input_table['root']==root]['yc'] = yc
                input_table[input_table['root']==root]['xerr'] = xerr
                input_table[input_table['root']==root]['yerr'] = yerr
                
                if verbose:
                    msg = "{} image position ({},{}) with error ({},{})"
                    print(msg.format(root, xc, yc, xerr, yerr))
                
        elif verbose:
            msg = "Skipping {} because it's been set to don't use (reason: {})."
            print(msg.format(root, row['notes']))
    
    return input_table


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
    
    input_table = AbscalDataTable(table=parsed_args.table,
                                  duplicates=parsed_args.duplicates,
                                  search_str='',
                                  search_dirs=parsed_args.paths,
                                  idl=parsed_args.compat)

    output_table = locate_image(input_table, parsed_args.verbose)
    
    table_fname = res.out_file
    output_table.write_to_file(table_fname, res.compat)


if __name__ == "__main__":
    main()
