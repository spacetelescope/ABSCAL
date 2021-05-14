#! /usr/bin/env python
"""
This module takes a file path and file type specification that matches to one
or more WFC3 exposures. In general, these files should be observations of
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
for flux calibration)::

    python preprocess_table_create.py

Alternately there are a set of python scripts placed in your path by setup.py that will
import and call this module. The general command is::

    wfc3_setup

whilst the IDL version is::

    wfcdir

If you use this module from within python, it is recommended to import the 
`populate_table()` function (if you need any custom table values, you can either pass in 
an AbscalDataTable directly or pass in keyword parameters that will, in turn, be passed 
along to the table creation)::

    from abscal.wfc3 import populate_table
    
    output_table = populate_table(some_arguments=some_values)
"""

__all__ = ['populate_table']

import datetime
import glob
import os

import numpy as np

from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy

from abscal.common.args import parse
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.common.standard_stars import find_star_by_name, find_closest_star
from abscal.common.utils import absdate

def get_target_name(header):
    """
    Find the canonical target name.
    
    Return a standardized target name despite any inconsistencies in target
    naming by different PIs. For now, use the existing wfcdir.pro checks to
    make a standard target name. In the future, potentially use RA and DEC to
    do a lookup to figure out the target and fill in appropriately.
    
    Parameters
    ----------
    header : astropy.io.fits header
        The header containing target information. In this header, the keys
        
        - targname (target name)
        - ra_targ (target RA)
        - dec_targ (target DEC)
        -  sclamp (active lamp)
        
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

    star = find_star_by_name(targname)
    if star is not None:
        return star['name']
    star = find_closest_star(ra, dec, max_distance=0.01)
    if star is not None:
        return star['name']
    if "NONE" in targname:
        if sclamp is not None:
            return sclamp
        return "LAMP"
    return targname


def populate_table(data_table=None, overrides={}, **kwargs):
    """
    Search a directory and produce a table of exposures.
    
    Uses glob to search all directories in the table's `search_dirs` array for
    files matching the table's `search_str` template, and adds rows to the table
    containing metadata based on the files that were found.
    
    Parameters
    ----------
    data_table : abscal.common.exposure_data_table.AbscalDataTable, default None
        The table (which may contain existing data) to which the new data should
        be added.
    kwargs : dict
        A dictionary of optional keywords. Currently checked keywords are:
        
        verbose : bool
            Flag to indicate whether or not the program should print out 
            informative text whilst running.
        compat : bool
            Whether to operate in strict IDL compatibility mode
        
    If data_table is None, a new table will be created in the function. In that case, the 
    kwargs dict will be passed to that table, so any table-creation keywords will be sent 
    through.
    
    Returns
    -------
    data_table : abscal.common.exposure_data_table.AbscalDataTable
        A table containing an entry for each input file and necessary metadata
        obtained from the FITS header of that file.
    """
    if data_table is None:
        data_table = AbscalDataTable(**kwargs)
    
    paths = data_table.search_dirs
    file_template = data_table.search_str
    idl_strict = kwargs.get('compat', False)
    verbose = kwargs.get('verbose', False)
    task = "create_table"

    for path in paths:
        if verbose:
            print("{}: searching {}...".format(task, path))
        all_files = glob.glob(os.path.join(path, file_template))
        
        for file_name in all_files:
            if verbose:
                print("{}: adding {}".format(task, file_name))
            loc = "START"
            file_metadata = {}

            file_path, base_name = os.path.split(file_name)
            file_ext = base_name[-8:-5]
            
            root = base_name[:9]
            file_metadata['root'] = root
            file_metadata['obset'] = base_name[:6]
            file_metadata['path'] = file_path
            file_metadata['filename'] = base_name
            
            try:
                with fits.open(file_name) as fits_file:
                    phdr = fits_file[0].header
                    
                    file_metadata['notes'] = ''
                    file_metadata['filter'] = phdr['filter'].upper()
                    if file_metadata['filter'][0] == 'F':
                        file_metadata['filter_root'] = 'N/A'
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
                    file_metadata['crval1'] = fits_file[1].header["CRVAL1"]
                    file_metadata['crval2'] = fits_file[1].header["CRVAL2"]
                    file_metadata['aperture'] = phdr['aperture']
                    file_metadata['proposal'] = phdr["proposid"]
                    ra = phdr['RA_TARG']
                    dec = phdr['DEC_TARG']
                    
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
                        msg = "{}: Could not find SPT file for {}. "
                        msg += "Setting scan rate to 0."
                        print(msg.format(task, base_name))
                        expstart = Time(phdr["EXPSTART"], format='mjd')
                        pstrtime = expstart.datetime.strftime("%Y.%j:%H:%M:%S")
                        delta_from_epoch = absdate(expstart) - 2000.
                        file_metadata['scan_rate'] = 0.
                        file_metadata['notes'] += " {}".format(msg)
                
                loc = "ASSEMBLING WRITE DATA"
                new_target = (file_metadata['target'], 'Updated by ABSCAL')
                standard_star = find_star_by_name(new_target[0])
                if standard_star is None:
                    # Try by distance
                    standard_star = find_closest_star(ra, dec, max_distance=1.)
                if standard_star is not None:
                    file_metadata['planetary_nebula'] = standard_star['planetary_nebula']
                    epoch_ra = standard_star['ra']
                    epoch_dec = standard_star['dec']
                    pm_ra = standard_star['pm_ra']
                    pm_dec = standard_star['pm_dec']
                    delta_ra = pm_ra * delta_from_epoch/1000.
                    delta_dec = pm_dec * delta_from_epoch/1000.
                    corrected_ra = epoch_ra + delta_ra/3600.
                    corrected_dec = epoch_dec + delta_dec/3600.
                    new_ra = (corrected_ra, 'Updated for PM by ABSCAL')
                    new_dec = (corrected_dec, 'Updated for PM by ABSCAL')
                    if verbose:
                        msg = "{}: {}: Target Star: {}"
                        print(msg.format(task, root, file_metadata['target']))
                        print("\tEpoch RA,DEC = {},{}".format(epoch_ra, epoch_dec))
                        print("\tTime Since Epoch = {}".format(delta_from_epoch))
                        print("\tDelta RA,DEC = {},{}".format(delta_ra, delta_dec))
                        print("\tFinal RA,DEC = {},{}".format(corrected_ra, corrected_dec))
                else:
                    file_metadata['planetary_nebula'] = False
                    msg = file_metadata['target'] + " not a WFC3 standard star" 
                    new_target = (file_metadata['target'], msg)
                    new_ra = (phdr["RA_TARG"], msg)
                    new_dec = (phdr["DEC_TARG"], msg)
                file_metadata['ra_targ'] = new_ra[0]
                file_metadata['dec_targ'] = new_dec[0]
                new_pstrtime = (pstrtime, "Added by ABSCAL")
                loc = "WRITING NEW FILE"
                with fits.open(file_name, mode="update") as fits_file:
                    fits_file[0].header["TARGNAME"] = new_target
                    fits_file[0].header["RA_TARG"] = new_ra
                    fits_file[0].header["DEC_TARG"] = new_dec
                    fits_file[0].header["PSTRTIME"] = new_pstrtime
                loc = "DONE"
                    
            except Exception as e:
                print("{}: {}: ERROR: {} {}".format(task, file_name, e, loc))
                for key in data_table.columns:
                    if key not in file_metadata:
                        print("\t{} missing".format(key))
                msg = "ERROR: Exception {} while processing.".format(str(e))
                file_metadata['notes'] += " {}".format(msg)
            
            data_table.add_exposure(file_metadata)
    
    data_table.set_filter_images()

    if data_table.n_exposures == 0:
        error_str = "Error: no files found for filespec {}"
        raise ValueError(error_str.format(file_template))
    
    data_table.sort(['root'])
    return data_table


def additional_args():
    """
    Adds process-specific command-line arguments.
    
    This function generates arguments (in a form understandable by 
    abscal.common.args.parse) to handle items unique to table creation.

    - How duplicate entries should be handled (important because this is process is the 
      one that adds new entries to a table)
    - The search template
    
    Returns
    -------
    args : dict
        Dictionary of tuples of arguments for building a module command-line argument 
        list.
    """
    args = {}
    
    dup_help = "How to handle duplicate entries (entries defined as "
    dup_help += "duplicates if they have the same ipppssoot). Valid values are "
    dup_help += "'both' (keep both), 'preserve' (keep first), 'replace' (keep "
    dup_help += "second), and 'neither' (delete both). Duplicates should only "
    dup_help += "be an issue if an input table is specified. Default: 'both'"
    dup_args = ['--duplicates']
    dup_kwargs = {'dest': 'duplicates', 'help': dup_help, 'default': 'both'}
    args['duplicates'] = (dup_args, dup_kwargs)
    
    template_help = "The file template to match, or the path to search "
    template_help += "and the file template to match within that directory. "
    template_help += "If the '-p' option is used to specify one or more input "
    template_help += "paths, then file file template will be joined to "
    template_help += "each input path."
    template_args = ['template']
    template_kwargs = {'help': template_help}
    args['template'] = (template_args, template_kwargs)
    
    return args


def parse_args():
    """
    Parse command-line arguments.
        
    Returns
    -------
    res : namespace
        A namespace populated by the command-line arguments.
    """    
    description_str = "Build metadata table from input files."
    default_output_file = 'dirtemp.log'

    additional_args = additional_args()

    res = parse(description_str, default_output_file, additional_args)
    
    if res.paths is not None: 
        if "," in res.paths:
            res.paths = res.paths.split(",")
        else:
            res.paths = [res.paths]
    else:
        res.paths = []
    
    if res.template is None:
        res.template = "i*flt.fits"
    
    if os.path.sep in res.template and len(res.paths) == 0:
        (template_path, template_value) = os.path.split(res.template)
        res.paths.append(template_path)
        res.template = template_value
    
    if len(res.paths) == 0:
        res.paths.append(os.getcwd())
    
    return res


def main(overrides={}):
    """
    Run the process.
    
    This function is called if the script is run directly (i.e. __name__ == "__main__"), 
    and is also imported by the binary command scripts as a way to run this process as a 
    standalone application.
    
    Parameters
    ----------
    overrides : dict
        Contains keys named after keyword parameters (whether command-line arguments or 
        parameters used by table creation) that will override whatever value is set there.
        Note that specific exposure-specific values from data files will still override
        values specified here.
    """

    res = parse_args()
    
    for key in overrides:
        if hasattr(res, key):
            setattr(res, key, overrides[key])
    
    table = AbscalDataTable(search_str=res.template,
                            search_dirs=res.paths,
                            table=res.in_file,
                            idl_mode=res.compat,
                            duplicates=res.duplicates)
    
    table = populate_table(data_table=table, verbose=res.verbose, compat=res.compat,
                           overrides=overrides)
    
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
        table.write_to_file(table_fname, res.compat, filters=filters)


if __name__ == "__main__":
    main()
