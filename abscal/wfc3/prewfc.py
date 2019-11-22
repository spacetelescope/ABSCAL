#! /usr/bin/env python
"""
This module takes a file path and the name of an input metadata table, groups
the exposures in that table by program and visit, and then:
    - calibrates each exposue
    - coadds together all exposures that have the same program/visit/star
    - 

calibrates the exposures
in the metadata table based on the table type (scan, filter, or grism). 

and file type specification that matches to one
or more WFC3 imaging files. In general, these files should be observations of
WFC3 standard stars. The module will open these files, retrieve information from
their headers, and produce an output table of these files. 

For compatibility with the original program, the module can be run from the 
command line directly (and given a file specification as a positional argument). 
In that case, it will work exactly the same as 'wfcdir.pro' as created by Ralph
Bohlin. It also includes additional options that allow the output file name to
be specified, allow the stdout content (and verbosity) to be specified, and 
allow multiple input directories to be specified with the positional argument
acting as a template for files to search for rather than as the full search
path.

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
        python wfcdir.py <file_path>

Dependencies
------------
    - ``astropy``
"""

__all__ = ['create_table']

import argparse
import datetime
import glob
import os

import numpy as np

from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy

from abscal.common.exposure_data_table import ExposureTable
from abscal.common.standard_stars import starlist, find_standard_star_by_name
from abscal.common.utils import absdate

def make_dates(date_string_or_rows, idl_strict):
    """
    Create either a datetime.datetime object from a string (with a known parse
    string) or a list of datetime.datetime objects from a set of table rows with
    columns named 'date' and 'time'.
    
    Parameters
    ----------
    date_string_or_rows : str or astropy.table.Table
        Either a single string or an astropy table row
    idl_strict : bool
        Whether IDL strict compatibility is turned on. If so, years are in
        two-digit format.
    
    Returns
    -------
    date_time : datetime.datetime or list of datetime.datetime
        The string (or rows) parsed into datetime objects.
    """
    if idl_strict:
        parse_str = "%y-%m-%d %H:%M:%S"
    else:
        parse_str = "%Y-%m-%d %H:%M:%S"
    parse_fn = datetime.datetime.strptime
    
    if isinstance(date_string_or_rows, str):
        return parse_fn(date_string_or_rows, parse_str)
    
    dates = date_string_or_rows['date']
    times = date_string_or_rows['time']
    if idl_strict:
        date_time_strings = ["{} {}".format(d,t) for d,t in zip(dates, times)]
    else:
        date_time_strings = ["{} {}".format(d.strftime("%Y-%m-%d"), t) for d,t in zip(dates, times)]
    date_time = [parse_fn(dt, parse_str) for dt in date_time_strings]
    
    return date_time


def get_data(data_dicts, key):
    """
    The create_table function builds up a metadata list-of-dicts, and then these
    are turned into columns to be stored in an astropy table. This function
    takes a list-of-dicts, and returns a list-of-items, where that list contains
    the item corresponding to `key` in each dict of the data_dicts list.
    
    Parameters
    ----------
    data_dicts : list of dict
        List of metadata dictionaries
    key : str
        The key to check
    
    Returns
    -------
    column : list
        a list of metadata_dict[key] for each metadata_dict in data_dicts
    """
    column = [x[key] for x in data_dicts]
    return column


def get_target_name(header):
    """
    Return a standardized target name despite any inconsistencies in target
    naming by different PIs. For now, use the existing wfcdir.pro checks to
    make a standard target name. In the future, potentially use RA and DEC to
    do a lookup to figure out the target and fill in appropriately.
    
    Parameters
    ----------
    header : astropy.io.fits header
        The header containing target information. In this header, the keys
            targname (target name)
            ra_targ (target RA)
            dec_targ (target DEC)
            sclamp (active lamp)
        are (or may be) used by the function.
    
    Returns
    -------
    name : str
        Target name, standardized.
    """
    targname = header['TARGNAME']
    ra = header['RA_TARG']
    dec = header['DEC_TARG']
    lamp = header.get('SCLAMP', None)

    name = None
    for star in starlist:
        if targname == star['name']:
            name = star['name']
        for star_name in star['names']:
            if star_name in targname:
                name = star['name']
        if abs(ra - star['ra']) < 0.01 and abs(dec - star['dec']) < 0.01:
            name = star['name']
        if name is not None:
            break
    
    if name is None:
        if "NONE" in targname:
            if lamp is not None:
                name = lamp
            else:
                name = "LAMP"
        else:
            name = targname
    
    return name


def create_table(paths, file_template, **kwargs):
    """
    Uses glob to search all directories in `directories` for files matching
    `file_template`, and creates an astropy table containing metadata based on
    the files that were found.
    
    Parameters
    ----------
    directories : list of str
        The directories containing input files.
    file_template : str
        A template for the files to be looked at. All files in the input 
        directories that match `file_template` must be WFC3 imaging files.
        Examples of templates include 'i*flt.fits', 'i*drz.fits', 'i*ima.fits'.
    kwargs : dict
        A dictionary of optional keywords. Currently checked keywords are:
            in_file : string or None
                If set, this file will be added to the metadata table before
                any other processing is done.
            handle_duplicates : str
                How to handle duplicate entries (entries with the same
                ipppssoot)
            compat : bool
                Whether to operate in strict IDL compatibility mode
    
    Returns
    -------
    data_table : astropy Table
        A table containing an entry for each input file and necessary metadata
        obtained from the FITS header of that file.
    """
    in_file = kwargs.get('in_file', None)
    duplicates = kwargs.get('duplicates', 'both')
    idl_strict = kwargs.get('compat', False)
    

    data_table = ExposureTable(search_str=file_template,
                               search_dirs=directories,
                               table=in_file,
                               idl_mode=idl_strict,
                               duplicates=duplicates)

    for path in paths:
        all_files = glob.glob(os.path.join(path, file_template))
        
        for file_name in all_files:
            loc = "START"
            file_metadata = {}

            file_path, base_name = os.path.split(file_name)
            file_ext = base_name[-8:-5]
            
            file_metadata['root'] = base_name[:9]
            
            try:
                with fits.open(file_name) as fits_file:
                    phdr = fits_file[0].header
                    
                    file_metadata['notes'] = ''
                    file_metadata['filter'] = phdr['filter'].upper()
                    file_metadata['target'] = get_target_name(phdr)
                    file_metadata['exposure_type'] = phdr['imagetyp']
                    if "TEXPTIME" not in phdr or phdr["TEXPTIME"] == 0:
                        file_metadata['exptime'] = phdr['exptime']
                    else:
                        file_metadata['exptime'] = phdr["texptime"]
                    loc = "PARSING DATE"

                    date = phdr['date-obs']
                    time = phdr['time-obs']
                    date_str = "{}T{}".format(date, time)
                    file_metadata['date'] = Time(date_str)
                    file_metadata['postarg1'] = phdr['POSTARG1']
                    file_metadata['postarg2'] = phdr['POSTARG2']
                    file_metadata['xsize'] = fits_file[1].header["NAXIS1"]
                    file_metadata['ysize'] = fits_file[1].header["NAXIS2"]
                    file_metadata['aperture'] = phdr['aperture']
                    file_metadata['proposal'] = phdr["proposid"]
                    
                    spt_file_name = base_name.replace(file_ext, 'spt')
                    spt_file = os.path.join(file_path, spt_file_name)
                    if os.path.isfile(spt_file):
                        with fits.open(spt_file) as spt_inf:
                            spt_hdr0 = spt_inf[0].header
                            spt_hdr1 = spt_inf[1].header
                            if "SCAN_RAT" in spt_hdr0:
                                rate = spt_hdr0["SCAN_RAT"]
                                file_metadata['scan_rate'] = rate
                            else:
                                file_metadata['scan_rate'] = 0.
                                msg = "SPT header had no SCAN_RAT keyword."
                                file_metadata['notes'] += " {}".format(msg)
                            pstrtime = spt_hdr0['PSTRTIME']
                            delta_from_epoch = absdate(pstrtime) - 2000.
                    else:
                        msg = "Could not find SPT file for " + base_name + ". "
                        msg += "Setting scan rate to 0."
                        print(msg)
                        expstart = Time(phdr["EXPSTART"], format='mjd')
                        pstrtime = expstart.datetime.strftime("%Y.%j:%H:%M:%S")
                        delta_from_epoch = absdate(expstart) - 2000.
                        file_metadata['scan_rate'] = 0.
                        file_metadata['notes'] += " {}".format(msg)
                
                loc = "ASSEMBLING WRITE DATA"
                new_target = (file_metadata['target'], 'Updated by wfcdir.py')
                standard_star = find_standard_star_by_name(new_target[0])
                if standard_star is not None:
                    epoch_ra = standard_star['ra']
                    epoch_dec = standard_star['dec']
                    pm_ra = standard_star['pm_ra']
                    pm_dec = standard_star['pm_dec']
                    delta_ra = pm_ra + delta_from_epoch/1000.
                    delta_dec = pm_dec + delta_from_epoch/1000.
                    corrected_ra = epoch_ra + delta_ra/3600.
                    corrected_dec = epoch_dec + delta_dec/3600.
                    new_ra = (corrected_ra, 'Updated for PM by wfcdir.py')
                    new_dec = (corrected_dec, 'Updated for PM by wfcdir.py')
                else:
                    msg = file_metadata['target'] + " not a WFC3 standard star" 
                    new_target = (file_metadata['target'], msg)
                    new_ra = (phdr["RA_TARG"], msg)
                    new_dec = (phdr["DEC_TARG"], msg)
                new_pstrtime = (pstrtime, "Added by wfcdir.py")
                loc = "WRITING NEW FILE"
                with fits.open(file_name, mode="update") as fits_file:
                    fits_file[0].header["TARGNAME"] = new_target
                    fits_file[0].header["RA_TARG"] = new_ra
                    fits_file[0].header["DEC_TARG"] = new_dec
                    fits_file[0].header["PSTRTIME"] = new_pstrtime
                loc = "DONE"
                    
            except Exception as e:
                print("{}: {} {}".format(file_name, e, loc))
                for key in data_table.columns:
                    if key not in file_metadata:
                        print("\t\t{} missing".format(key))
                msg = "ERROR: Exception {} while processing.".format(str(e))
                file_metadata['notes'] += " {}".format(msg)
            
            data_table.add_exposure(file_metadata)

    if data_table.n_exposures == 0:
        error_str = "wfcdir error: no files found for filespec {}"
        raise ValueError(error_str.format(file_template))
    
    data_table.sort_data(['root'])
    return data_table


def main():

    table_help = "The input metadata table to use."
    
    path_help = "The path containing the input data files."
    
    out_help = "Output metadata file. The default value is dirtemp_<item>.log "
    out_help += "where item is 'all' for all files, 'grism' for grism files "
    out_help += "(and associated filter images), 'filter' is filter files, and "
    out_help += "'scan' is all scan-mode files."
    
    type_help = "File type to process. This can be one of 'grism', 'filter', "
    type_help += "or 'scan'. This will override any type metadata in the input "
    type_help += "table."
    
    compat_help = "Activate strict compatibility mode. In this mode, the "
    compat_help += "script will produce output that is as close as possible to "
    compat_help += "indistinguishable from prewfc.pro"
    
    verbose_help = "Print diagnostic information while running."

    description_str = 'Process files from metadata table.'
    parser = argparse.ArgumentParser(description=description_str)
    parser.add_argument('table', help=table_help)
    parser.add_argument('-p', '--path', dest='path', help=path_help)
    parser.add_argument('-o', '--output', dest='out_file', help=out_help,
                        default='dirtemp.log')
    parser.add_argument('-t', '--file_type', dest='file_type', out=type_help)
    parser.add_argument('-c', '--strict_compat', dest="compat", 
                        action='store_true', default=False, help=compat_help)
    parser.add_argument('-v', '--verbose', dest="verbose",
                        action='store_true', default=False, help=verbose_help)

    res = parser.parse_args()
    
    if res.path is None:
        res.path = os.getcwd()
    
    table = create_table(res.paths, 
                         res.template, 
                         in_file=res.in_file,
                         handle_duplicates=res.duplicates,
                         compat=res.compat)
    
    base_file, file_ext = os.path.splitext(res.out_file)
    
    table_types = ["all", "filter", "grism", "scan"]
    table_filters = {
                        "all": [],
                        "filter": ["stare", "filter"],
                        "grism": ["stare", "grism"],
                        "scan": ["scan"]
                    }
    for table_type in table_types:
        filters = table_filters[table_type]
        table_fname = "{}_{}{}".format(base_file, table_type, file_ext)
        table.write_table(table_fname, res.compat, filters=filters)


if __name__ == "__main__":
    main()
