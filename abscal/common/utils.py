#! /usr/bin/env python
"""
This module includes utility functions that might be used by any instrument.

Authors
-------
    - Brian York

Use
---
    Individual functions from this module are intended to be imported where
    needed.
    ::
        from abscal.common.utils import absdate
"""

__all__ = ['absdate', 'get_data_file']

import os

from astropy.time import Time
from copy import deepcopy
from datetime import datetime

from .standard_stars import starlist


def absdate(pstrtime):
    # '2013.057:04:24:48'
    # pstrtime is in the format yyyy.ddd:hh:mm:ss where 'ddd' is the decimal 
    #   date (i.e. January 1 is 001, January 31 is 031, February 1 is 032,
    #   December 31 is 365 or 366 depending on leap year status)
    if isinstance(pstrtime, datetime):
        dt = pstrtime
    elif isinstance(pstrtime, Time):
        dt = pstrtime.datetime
    else:
        dt = datetime.strptime(pstrtime, "%Y.%j:%H:%M:%S")
    next_year = datetime(year=dt.year+1, month=1, day=1)
    this_year = datetime(year=dt.year, month=1, day=1)
    year_part = dt - this_year
    year_length = next_year - this_year
    return dt.year + year_part/year_length


def get_data_file(module, fname):
    """
    Returns the path to a file named `fname` in the data directory of the
    (sub)module named `module`.
    
    Parameters
    ----------
    module : str
        The module to search in, using standard dot separators (e.g.
        abscal.wfc3)
    fname : str
        The file name of interest
    
    Returns
    -------
    data_file : str
        Full path to the data file.
    """
    # /path/to/module/common
    current_loc = os.path.dirname(os.path.abspath(__file__))
    
    # /path/to/module
    base_loc = os.path.dirname(current_loc)
    base_loc = os.path.dirname(base_loc)
    
    # Replace '.' with path separator
    module_path = module.replace(".", "/")
    
    data_file = os.path.join(base_loc, module_path, "data", fname)
    return data_file


def set_param(param, default, row, issues, pre, overrides={}, verbose=False):
    """
    Given a parameter name, that parameter's default value, a data table
    row, and a JSON dictionary which may have an entry for the current row that
    will override the parameter, return the parameter value that should be used.
    
    Parameters
    ----------
    param : str
        The parameter to check and return
    default : object
        The default value for that parameter
    row : abscal.common.exposure_data_table.AbscalDataTable
        A single-row table containing the data of interest.
    issues : dict
        A dictionary containing a set of parameters (one of which may be
        param), along with information to identify files whose parameters
        should be adjusted .
    overrides : dict
        A dictionary containing any parameters whose value is being overridden
        by the user.
    verbose : bool
        Whether or not informational output should be printed.
    
    Returns
    -------
    value : object
        The appropriate value for the parameter given 
    """
    value = default
    if param in issues:
        issue_list = issues[param]
        for item in issue_list:
            val_len = len(item["value"])            
            if row[item["column"]][:val_len] == item["value"]:
                value = item["param_value"]
                if verbose:
                    reason = item["reason"]
                    source = item["source"]
                    msg = "{}: changed {} to {} because {} from {}"
                    print(msg.format(pre, param, value, reason, source))
    if param in overrides:
        value = overrides[param]
        
    return value


def set_params(defaults, row, issues, pre, overrides={}, verbose=False):
    """
    Given a dictionary of default values, a metadata row, a dictionary of
    known issues and overrides, a dictionary of user-supplied overrides,
    and a verbose flag, produce a dictionary of parameters (all with the
    appropriate value) which also contains a 'set' key (an array of all
    the parameters that have been overridden from their default values).
    
    Parameters
    ----------
    defaults : dict
        A dictionary of default values (also names the parameters)
    row : abscal.common.exposure_data_table.AbscalDataTable
        A single-row table containing the data of interest.
    issues : dict
        A dictionary containing a set of parameters, along with information to 
        identify files whose parameters should be adjusted.
    overrides : dict
        A dictionary containing any parameters whose value is being overridden
        by the user.
    verbose : bool
        Whether or not informational output should be printed.
    
    Returns
    -------
    params : dict
        The supplied parameters, each with its value. 
    """
    params = {'set': []}
    
    for param in defaults:
        default = defaults[param]
        value = set_param(param, default, row, issues, pre, overrides, verbose)
        params[param] = value
        if value != default:
            params['set'].append(param)
    
    return params

def set_image(images, row, issues, pre, overrides={}, verbose=False):
    """
    Given an image, image metadata, and a set of known issues, determine if any
    of the known issues apply to the image in question and, if they do, make
    the appropriate edits to the image.
    
    Parameters
    ----------
    images : dict
        Dict of (SCI, ERR, DQ) np.ndarray images
    row : abscal.common.exposure_data_table.AbscalDataTable
        A single-row table containing metadata on the image
    issues : dict
        A dictionary containing a set of parameters, along with information to 
        identify files whose parameters should be adjusted.
    overrides : dict
        A dictionary containing any parameters whose value is being overridden
        by the user.
    verbose : bool
        Whether or not informational output should be printed.
    
    Returns
    -------
    image : tuple
        Tuple of (SCI, ERR, DQ) np.ndarray images, as edited.
    """
#     print("set_image with {}, {}, {}, {}".format(images, row, issues, overrides))
    
    for issue in issues:
#         print(issue)
#         print(issue["column"], type(issue["column"]))
#         print(row)
        found = False
        if issue["column"] in row:
            if isinstance(issue["column"], str):
                issue_len = len(issue["value"])
                if issue["value"] == row[issue["column"]][:issue_len]:
                    found = True
            else:
                if issue["value"] == row[issue["column"]]:
                    found = True
        if found:
            if len(issue["x"]) > 1:
                x1, x2 = issue["x"][0], issue["x"][1]
            else:
                x1, x2 = issue["x"][0], issue["x"][0]+1
            if len(issue["y"]) > 1:
                y1, y2 = issue["y"][0], issue["y"][1]
            else:
                y1, y2 = issue["y"][0], issue["y"][0]+1
            images[issue["ext"]][y1:y2,x1:x2] = issue["value"]
            if verbose:
                reason = issue["reason"]
                source = issue["source"]
                value = issue["value"]
                msg = "{}: changed ({}:{},{}:{}) to {} because {} from {}"
                print(msg.format(pre, y1, y2, x1, x2, value, reason, source))
                
    
    return images


def air2vac(air):
    """
    Convert a set of wavelengths from air to vacuum.
    
    Parameters
    ----------
    air : array-like
        Air wavelengths
    
    Returns
    -------
    vac : array-like
        Vacuum wavelengths
    """
    vac = []
    c0 = 0.00008336624212083
    c1 = 0.02408926869968
    c2 = 0.0001599740894897
    
    for wl_air in air:
        s = 1.e4/wl_air
        n = 1 + c0 + c1 / (130.1065924522 - s*s) + c2 / (38.92568793293 - s*s)
        wl_vac = wl_air * n
        vac.append(wl_vac)
    
    return vac


def smooth_model(wave, flux, fwhm):
    """
    Smooth a model spectrum with a non-uniform sampling interval. Based on Ralph
    Bohlin's "smomod.pro", which itself references "tin.pro"
    
    Parameters
    ----------
    wave : array-like
        Wavelength array
    
    flux : array-like
        Flux array
    fwhm : float
        FWHM of delta function.
    
    Returns
    -------
    smoothed : array-like
        Smoothed flux array.
    """
    wmin = wave - dlam/2.
    wmax = wave + dlam/2.
    
    good = np.where((wmin > np.min(wave)) and (wmax < np.max(wave)))
    smoothed = deepcopy(flux)
    smoothed[good] = trapezoidal(wave, flux, wmin[good], wmax[good])
    smoothed[good] = trapezoidal(wave, smoothed, wmin[good], wmax[good])
    
    return smoothed

def trapezoidal(wave, flux, wmin, wmax):
    """
    Trapezoidal 'integral' (really an average) from Ralph Bohlin's 'tin.pro'
    and 'integral.pro'. Uses wmin and wmax to set limits
    
    Parameters
    ----------
    wave : array-like
        Wavelength array
    flux : array-like
        Flux array
    wmin : array-like
        Wavelength array shifted bluewards by FWHM/2
    wmax : array-like
        Wavelength array shifted redwards by FWHM/2
    
    Returns
    trapint : array-like
        Flux array after trapezoidal integral
    """
    trapint = integral(wave, flux, wmin, wmax)/(wmax - wmin)
    return trapint

def integral(x, y, xmin, xmax):
    rmin = tabinv(x, xmin)
    rmax = tabinv(x, xmax)
    n = len(x)
    dx = np.roll(x, -1) - x
    if (np.max(xmin) > np.max(xmax)) or (np.min(xmax) < np.min(xmin)) or (np.min(xmax - xmin) < 0.):
        raise ValueError("Invalid integral limits")
    dx = np.roll(x, -1) - x
    dy = np.roll(y, -1) - y
    
    dint = (np.roll(y, -1) + y)/(2.*dx)
    imin = int(np.floor(rmin))
    imax = int(np.floor(rmax))
    
    dxmin = xmin - x[imin]
    ymin = y[imin] + dxmin*(y[imin+1]-y[imin])/(dx[imin] + np.where(dx[imin]==0, 1, 0))
    dxmax = xmax - x[imax]
    ymax = y[imax] + dxmax*(y[np.min(imax+1, len(y)-1)] - y[imax])/(dx[imax]+np.where(dx[imax]==0, 1, 0))
    
    int = np.zeros_like(xmin)
    for i in range(len(xmin)):
        if imax[i] != imin[i]:
            int[i] = np.sum(dint[imin[i]:imax[i]]-1)
    
    int -= (y[imin] + ymin)/(2.*dxmin)
    int += (y[imax] + ymax)/(2.*dxmax)
    
    return int

def tabinv(xarr, xv):
    """
    Find the effective index in xarr of each element in xv. The effective index
    is the value i such that xarr[i] <= xv <= xarr[i+1], to which is added an
    interpolation
    """
    indl = np.searchsorted(xarr, xv, side='left')
    ieff = deepcopy(indl).astype(np.float32)
    indr = np.searchsorted(xarr, xv, side='right')
    good = np.where((indr > 0) and (indl < len(xarr)))
    if len(good[0]) > 0:
        neff = indl[good]
        x0 = xarr[neff]
        diff = xv[good]
        ieff[good] = neff + diff / (xarr[neff+1] - x0)
    
    return ieff
