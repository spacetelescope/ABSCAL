#! /usr/bin/env python
"""
This file takes two input spectra and determines the best cross-correlation between them.
It uses a correlation algorithm developed by Ralph Bohlin.

Authors
-------
- Brian York (all python code)
- Ralph Bohlin (original IDL code)

Use
---
This file is intended to be called from `reduce_grism_coadd.py`, although it can be 
used by direct import::

    from abscal.wfc3.util_grism_cross_correlate import cross_correlate
    
    offset, correlation_matrix = cross_correlate(spec1, spec2, table_row, args, **kwargs)

The following parameters can be set via the keyword arguments:

ishift: int, default 0
    Approximate initial shift. The correlation search will start here.
width: int, default 15
    Size (in pixels) of the correlation search region
i1: int, default 0
    First pixel of the spectrum to use in correlation search
i2: int, default -1
    Last pixel of the spectrum to use in correlation search. Negative values are counting 
    from the end of the array, as per python convention.
"""

import datetime
import glob
import os
import yaml

import numpy as np

from astropy import wcs
from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy
from scipy import signal

from abscal.common.args import parse
from abscal.common.utils import get_data_file, get_defaults, set_params
from abscal.common.exposure_data_table import AbscalDataTable

def cross_correlate(s1, s2, row, **kwargs):
    """
    Cross-correlates two spectra.
    
    Parameters
    ----------
    s1 : numpy.ndarray
        First spectrum
    s2 : numpy.ndarray
        Second spectrum
    row : astropy.table.Table
        Single-element table with metadata on s1
    kwargs : dict
        Potential overrides to cross-correlation parameters and command-line arguments
        
    Returns
    -------
    offset : float
        Best found pixel offset
    corr : np.ndarray
        Correlation matrix
    """
    verbose = kwargs.get('verbose', False)
    task = "cross_correlate"
    preamble = "{}: {}".format(task, row['root'][0])

    if verbose:
        print("{}: Starting WFC3 cross-correlation of GRISM data.".format(task))

    issues = {}
    exposure_parameter_file = get_data_file("abscal.wfc3", os.path.basename(__file__))
    if exposure_parameter_file is not None:
        with open(exposure_parameter_file, 'r') as inf:
            issues = yaml.safe_load(inf)

    defaults = get_defaults("abscal.wfc3.util_grism_cross_correlate")
    defaults['i2'] = len(s1) - 1
    params = set_params(defaults, row, issues, preamble, kwargs, verbose)
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
