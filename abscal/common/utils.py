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
    
    # Replace '.' with path separator
    module_path = module.replace(".", os.pathsep)
    
    data_file = os.path.join(base_loc, module_path, "data", fname)
    return data_file


def set_param(param, default, row, issue_dict, override_dict={}, verbose=False):
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
    issue_dict : dict
        A dictionary containing a set of parameters (one of which may be
        param), along with information to identify files whose parameters
        should be adjusted .
    override_dict : dict
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
    if param in issue_dict:
        issue_list = issue_dict[param]
        for item in issue_list:
            val_len = len(item["value"])
            if row[item["column"][:val_len]] == item["value"]:
                value = item["param_value"]
                 if verbose:
                    reason = item["reason"]
                    source = item["source"]
                    msg = "{} changed xstar to {} because {} from {}"
                    print(msg.format(root, xstar, reason, source))
    if param in override_dict:
        value = override_dict[param]
        
    return value


def set_params(defaults, row, issues, overrides={}, verbose=False):
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
        value = set_param(param, default, row, issues, overrides, verbose)
        params[param] = value
        if value != default:
            params['set'].append(param)
    
    return params

def set_image(images, row, issues, overrides={}, verbose=False):
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
    
    for issue in issues:
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
                msg = "{} changed ({}:{},{}:{}) to {} because {} from {}"
                print(msg.format(root, y1, y2, x1, x2, value, reason, source))
                
    
    return images
