#! /usr/bin/env python
"""
This module takes a file path and file type specification that matches to one
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

from abscal.common.standard_stars import starlist, find_standard_star_by_name
from abscal.common.utils import absdate

def scan_rate_formatter(scan_rate):
    scan_rate_str = "{:6.4f}".format(scan_rate)
    return "{:<9}".format(scan_rate_str)

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


def create_table(directories, file_template, obs_types={}, **kwargs):
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
    obs_types : dict, optional, default {}
        A dictionary of observation types, allowing you to select which
        observation types to use. In particular, you are able to set any of
        three keys to either true or false. If a key is not present, its value
        will be assumed to be True.
            scan : whether to include observations with scan rate > 0
            stare_grism : whether to include stare observations with grism.
            stare : whether to include stare observations with filter.
    
    Returns
    -------
    metadata : astropy Table
        A table containing an entry for each input file and necessary metadata
        obtained from the FITS header of that file.
    """
    idl_strict = kwargs.get('compat', False)

    columns = ['root', 'mode', 'aperture', 'type', 'target', 'img_size', 'date',
               'time', 'propid', 'exptime', 'postarg', 'scan_rate', 'notes']
    column_names = {
                    'img_size': "IMG SIZE",
                    'postarg': "POSTARG X,Y",
                    'scan_rate': "SCAN_RAT",
                    "aperture": "APER"
                   }
    if idl_strict:
        column_formats = {
                            "root": "<10",
                            "mode": "<7",
                            "aperture": "<15",
                            "type": "<5",
                            "target": "<12",
                            "img_size": "<9",
                            "date": "<8",
                            "time": "<8",
                            "propid": "<6",
                            "exptime": "7.1f",
                            "postarg": ">14",
                            "scan_rate": scan_rate_formatter
                         }
    file_data = []
    
    start_time = datetime.datetime.now().strftime("%d-%b-%Y %H:%M:%S.%f")

    for directory in directories:
        all_files = glob.glob(os.path.join(directory, file_template))
        
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
                    file_metadata['mode'] = phdr['filter'].upper()
                    file_metadata['target'] = get_target_name(phdr)
                    file_metadata['type'] = phdr['imagetyp']
                    # ***MAYBE*** seems unused?
#                     instr = phdr["INSTRUME"].strip()
                    if "TEXPTIME" not in phdr or phdr["TEXPTIME"] == 0:
                        file_metadata['exptime'] = phdr['exptime']
                    else:
                        file_metadata['exptime'] = phdr["texptime"]
                    loc = "PARSING DATE"
                    obs_date = Time(phdr['date-obs'])
                    loc = 'FORMATTING DATE'
                    obs_date.format = 'datetime'
                    loc = "PARSED DATE"
                    if idl_strict:
                        file_metadata['date'] = obs_date.strftime('%y-%m-%d')
                        m1 = "{:6.1f}".format(phdr["POSTARG1"])
                        m2 = "{:6.1f}".format(phdr["POSTARG2"])
                        file_metadata['postarg'] = "{}, {}".format(m1, m2)
                        naxis1 = fits_file[1].header["NAXIS1"]
                        naxis2 = fits_file[1].header["NAXIS2"]
                        img_size_str = "{:4d}x{:4d}".format(naxis1, naxis2)
                        file_metadata['img_size'] = img_size_str
                        file_metadata['aperture'] = phdr['aperture'][:15]
                    else:
                        file_metadata['date'] = obs_date
                        m1 = phdr['POSTARG1']
                        m2 = phdr['POSTARG2']
                        file_metadata['postarg'] = (m1, m2)
                        naxis1 = fits_file[1].header["NAXIS1"]
                        naxis2 = fits_file[1].header["NAXIS2"]
                        file_metadata['img_size'] = (naxis1, naxis2)
                        file_metadata['aperture'] = phdr['aperture']
                    file_metadata['time'] = phdr["time-obs"]
                    file_metadata['propid'] = phdr["proposid"]
                    # ***MAYBE*** seems unused?
#                     gain = phdr["CCDGAIN"]
#                     if gain == 0:
#                         gain = phdr["CCDGAIN4"]
#                     amp = ' '
                    
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
                                msg = " SPT header had no SCAN_RAT keyword."
                                file_metadata['notes'] += msg
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
                        new_note = file_metadata['notes'] + ' ' + msg
                        file_metadata['notes'] = new_note
                
                loc = "ASSEMBLING WRITE DATA"
                new_target = (file_metadata['target'], 'Updated by wfcdir.py')
                standard_star = find_standard_star_by_name(file_metadata['target'])
                if standard_star is not None:
                    epoch_ra, epoch_dec = standard_star['ra'], standard_star['dec']
                    pm_ra, pm_dec = standard_star['pm_ra'], standard_star['pm_dec']
                    delta_ra = pm_ra + delta_from_epoch/1000.
                    delta_dec = pm_dec + delta_from_epoch/1000.
                    corrected_ra = epoch_ra + delta_ra/3600.
                    corrected_dec = epoch_dec + delta_dec/3600.
                    new_ra = (corrected_ra, 'Updated for PM by wfcdir.py')
                    new_dec = (corrected_dec, 'Updated for PM by wfcdir.py')
                else:
                    new_target = (file_metadata['target'], "{} not a WFC3 standard star".format(file_metadata['target']))
                    new_ra = (phdr["RA_TARG"], "{} not a WFC3 standard star".format(file_metadata['target']))
                    new_dec = (phdr["DEC_TARG"], "{} not a WFC3 standard star".format(file_metadata['target']))
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
                for key in columns:
                    if key not in file_metadata:
                        print("\t\t{} missing".format(key))
                new_note = "{} ERROR: Exception {} while processing."
                file_metadata['notes'] = new_note.format(file_metadata['notes'], str(e))
            
            file_data.append(file_metadata)
    
    if len(file_data) == 0:
        error_str = "wfcdir error: no files found for filespec {}"
        raise ValueError(error_str.format(file_template))
    
#     max_aper = max([len(a) for a in get_data(file_data, 'aper')])
#     column_formats['aper'] = '<{}'.format(max_aper)

    target_table = Table()
    for column in columns:
        data = get_data(file_data, column)
        name = column_names.get(column, column.upper())
        if idl_strict and column in column_formats:
            format = column_formats[column]
            new_column = Column(data=data, name=name, format=format)
        else:
            new_column = Column(data=data, name=name)
        target_table[column] = new_column
    table_comments = []
    table_comments.append('WFCDIR {}'.format(start_time))
    for directory in directories:
        table_comments.append('SEARCH FOR {}'.format(os.path.join(directory, file_template)))
    target_table.meta['comments'] = table_comments
    target_table.sort(['target', 'date', 'time'])
    target_table.sort(['root'])
    
    scan_table = deepcopy(target_table)
    scan_table.remove_rows(scan_table['scan_rate'] <= 0.)
    
    stare_table = deepcopy(target_table)
    stare_table.remove_rows(stare_table['scan_rate'] > 0.)
    
    filter_table = deepcopy(stare_table)
    filter_table.remove_rows([mode[0] == 'G' for mode in filter_table['mode']])

    grism_table = deepcopy(stare_table)
    grism_table.remove_rows([mode[0] == 'F' for mode in grism_table['mode']])
    grism_check_table = deepcopy(grism_table)
    
    for row in grism_check_table:
        # Get the ipppss (so program+visit) from ipppssoot
        root = row['root'][:6]
        if idl_strict:
            date_string = "{} {}".format(row['date'], row['time'])
        else:
            date_string = row['date'].strftime("%Y-%m-%d")
            date_string += " {}".format(row['time'])
        time = make_dates(date_string, idl_strict)
        
        # Only check filter exposures that are part of the same visit
        check_mask = [r[:6] == root for r in filter_table['root']]
        check_table = filter_table[check_mask]
        if len(check_table) > 0:
            check_dates = make_dates(check_table, idl_strict)
            check_times = [abs(time - t) for t in check_dates]
            mininum_time_index = check_times.index(min(check_times))
            minimum_time_row = check_table[mininum_time_index]
            if minimum_time_row['root'] not in grism_table['root']:
                grism_table.add_row(minimum_time_row)
        else:
            # No corresponding filter for this grism exposure
            # Find the row with the same root value, and add a note.
            row_mask = [r == row['root'] for r in final_grism_table['root']]
            new_note = " No corresponding filter exposure found."
            grism_table[row_mask]["note"] += new_note
    
    grism_table.sort(['root'])
    
    return target_table, filter_table, grism_table, scan_table


def main():

    template_help = "The file template to match, or the directory to search "
    template_help += "and the file template to match within that directory. "
    template_help += "If the '-d' option is used to specify one or more input "
    template_help += "directories, then file file template will be joined to "
    template_help += "each input directory."
    
    dir_help = "A comma-separated list of input directories. This need not be "
    dir_help += "specified if there is only one input directory, and if that "
    dir_help += "directory is specified in the template argument."
    
    out_help = "Output metadata file. The default value is the file name "
    out_help += "created by the original wfcdir.pro"
    
    compat_help = "Activate strict compatibility mode. In this mode, the "
    compat_help += "script will produce output that is as close as possible to "
    compat_help += "indistinguishable from wfcdir.pro"

    description_str = 'Build metadata table from input files.'
    parser = argparse.ArgumentParser(description=description_str)
    parser.add_argument('template', help=template_help)
    parser.add_argument('-d', '--directories', dest='directories', 
                        help=dir_help)
    parser.add_argument('-o', '--output', dest='out_file', help=out_help,
                        default='dirtemp.log')
    parser.add_argument('-s', '--strict_compat', dest="compat", 
                        action='store_true', default=False, help=compat_help)

    res = parser.parse_args()
    
    if res.directories is not None: 
        if "," in res.directories:
            res.directories = res.directories.split(",")
        else:
            res.directories = [res.directories]
    else:
        res.directories = []
    
    if res.template is None:
        res.template = "i*flt.fits"
    
    if os.path.sep in res.template and len(res.directories) == 0:
        (template_path, template_value) = os.path.split(res.template)
        res.directories.append(template_path)
        res.template = template_value
    
    if len(res.directories) == 0:
        res.directories.append(os.getcwd())
    
    tables = create_table(res.directories, res.template, compat=res.compat)
    all_table, scan_table, filter_table, grism_table = tables
    
    base_file, file_ext = os.path.splitext(res.out_file)
    
    table_types = ["all", "filter", "grism", "scan"]
    for table, table_type in zip(tables, table_types):
        if len(table) > 0:
            table_fname = "{}_{}{}".format(base_file, table_type, file_ext)
            if res.compat:
                table.remove_column('notes')
                ascii.write(table,
                            output=table_fname,
                            format='fixed_width',
                            delimiter=' ',
                            delimiter_pad=None,
                            bookend=False,
                            overwrite=True)
            else:
                ascii.write(table, 
                            output=table_fname, 
                            format='ipac', 
                            overwrite=True)


if __name__ == "__main__":
    main()
