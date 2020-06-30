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
import warnings

import matplotlib.pyplot as plt
import numpy as np

from astropy import wcs
from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy
from scipy.signal import medfilt2d

from abscal.common.args import parse
from abscal.common.utils import get_data_file, set_param
from abscal.common.exposure_data_table import AbscalDataTable


def locate_image(input_table, verbose=False, interactive=False):
    """
    Reduces and co-adds grism data
    """
    task = "locate_image"
    if verbose:
        msg = "{}: Starting WFC3 image location check for FILTER data."
        print(msg.format(task))

    known_issues_file = get_data_file("abscal.wfc3", "known_issues.json")
    with open(known_issues_file, 'r') as inf:
        known_issues = json.load(inf)
    input_table.adjust(known_issues['metadata'])
    issues = []
    if "reduction" in known_issues:
        if "locate_image" in known_issues["reduction"]:
            issues = known_issues["reduction"]["locate_image"]
    
    for row in input_table:
        root = row['root']
        target = row['target']
        filter = row['filter']
        preamble = "{}: {}".format(task, root)
        # Only locate filter data in the locate_image function.
        if row['use'] and row['filter'][0] == 'F':
            if verbose:
                print("{}: Locating image for {}".format(task, root))
            input_file = os.path.join(row['path'], row['filename'])
            crval1 = row['crval1']
            crval2 = row['crval2']
            
            xstar = set_param("xstar", 0, row, issues, preamble, {}, 
                              verbose=verbose)
            ystar = set_param("ystar", 0, row, issues, preamble, {}, 
                              verbose=verbose)            
            
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
                
                img_wcs = wcs.WCS(inf['SCI'].header)
                ra = inf[0].header["RA_TARG"]
                dec = inf[0].header["DEC_TARG"]
                targ = img_wcs.wcs_world2pix([ra], [dec], 0, ra_dec_order=True)
                xastr, yastr = targ[0][0], targ[1][0]
                xappr, yappr = int(round(xastr)), int(round(yastr))
                if verbose:
                    msg = "{}: {} has image astrometry position ({},{})"
                    print(msg.format(task, root, xastr, yastr))
                if interactive:
                    fig = plt.figure()
                    ax = fig.add_subplot(111)
                    targ_str = "{} - {} ({})".format(root, target, filter)
                    title_str = "{}: Direct Image with Predicted Source"
                    ax.set_title(title_str.format(targ_str))
                    plt.imshow(np.log10(np.where(data>=0.1, data, 0.1)))
                    plt.plot([xastr, xastr], [yastr-8, yastr-18], color='white')
                    plt.plot([xastr, xastr], [yastr+8, yastr+18], color='white')
                    plt.plot([xastr-8, xastr-18], [yastr, yastr], color='white')
                    plt.plot([xastr+8, xastr+18], [yastr, yastr], color='white')
                    plt.show()
                
                if (xstar == 0) and (ystar == 0):
                    if (xappr <=3) or (xappr >= data.shape[1]-4):
                        row['xc'] = 0
                        row['yc'] = 0
                        if verbose:
                            msg = "{}: {}: target at edge. Set xc=yc=0."
                            print(msg.format(task, root))
                        continue
                
                if xstar != 0 or ystar != 0:
                    xappr = int(round(xstar))
                    yappr = int(round(ystar))
                
                # Set data to zero except around the approximate target location
                data[:,:max(xappr-35,0)] = 0.
                data[:,min(xappr+35,data.shape[1]-1):] = 0.
                data[:max(yappr-35,0),:] = 0.
                data[min(yappr+35,data.shape[0]-1):,:] = 0.
                
#                 print("Data Near Centre")
                np_formatter = {'float_kind':lambda x: "{:10.4f}".format(x)}
                np_opt = {'max_line_width': 175, 'formatter': np_formatter}
#                 print(np.array2string(data[yappr-5:yappr+5,xappr-5:xappr+5], **np_opt))
                
                # Perform a median filter of the data.
                med_data = medfilt2d(data, kernel_size=3)
                # Get the index of the array (as reshaped into a 1D array)
                argmax = np.argmax(med_data, axis=None)
                # Convert the index into a 2D x/y co-ordinate
                position = np.unravel_index(argmax, med_data.shape)
                xpos, ypos = position[1], position[0]
                
#                 print("Max Position", xpos, ypos)
                
                x1 = max(xpos-10, 0)
                x2 = min(x1+22, data.shape[1]-1)
                y1 = max(ypos-10, 0)
                y2 = min(y1+22, data.shape[0]-1)
                
#                 print("X, Y = [{}:{},{}:{}]".format(x1,x2,y1,y2))
                
                subimage = data[y1:y2,x1:x2]
                # IDL code does not supply kernel size, but online documentation
                #   does not seem to indicate what the default is.
#                 print("Initial Subimage")
#                 print(np.array2string(subimage, **np_opt))
                subimage -= np.median(subimage)
                subimage -= subimage.max()/5
                subimage = np.where(subimage>=0., subimage, 0.)
#                 print("Subimage")
#                 print(np.array2string(subimage, **np_opt))
                
                x = np.arange(x1,x2)
                xprofile = np.sum(subimage, axis=0)
#                 print("Xprofile")
#                 print(np.array2string(xprofile, **np_opt))
                xc = np.sum(xprofile*x)/np.sum(xprofile)
                xerr = xc - xastr

                y = np.arange(y1, y2)
                yprofile = np.sum(subimage, axis=1)
#                 print("Yprofile")
#                 print(np.array2string(yprofile, **np_opt))
                yc = np.sum(yprofile*y)/np.sum(yprofile)
                yerr = yc - yastr

#                 # These lines generate StringTruncationWarnings from astropy.
#                 #   This is something that's important, but not in this
#                 #   *particular* case, because the only thing that we're taking
#                 #   out of this particular row is the xc/yc/xerr/yerr values,
#                 #   and those are floats rather than strings. So suppress that
#                 #   warning here.
#                 with warnings.catch_warnings():
#                     from astropy.table import StringTruncateWarning
#                     warnings.simplefilter("ignore", StringTruncateWarning)
                row['xc'] = xc
                row['yc'] = yc
                row['xerr'] = xerr
                row['yerr'] = yerr
                
                if verbose:
                    msg = "{}: {}: image position ({},{}) with error ({},{})"
                    print(msg.format(task, root, xc, yc, xerr, yerr))
                
        elif verbose:
            msg = "{}: Skipping {} because it's been set to don't use "
            msg += "(reason: {})."
            print(msg.format(task, root, row['notes']))
    
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
