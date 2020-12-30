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
from photutils.detection import DAOStarFinder
from scipy.stats import mode

from abscal.common.args import parse
from abscal.common.utils import air2vac
from abscal.common.utils import get_data_file
from abscal.common.utils import linecen
from abscal.common.utils import smooth_model
from abscal.common.utils import tabinv
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.wfc3.reduce_grism_extract import reduce
from abscal.wfc3.reduce_grism_extract import additional_args as extract_args
from abscal.wfc3.util_grism_cross_correlate import cross_correlate

def wlimaz(root, y_arr, wave_arr, directory, verbose):
    """
    If the very bright 10380A line falls in the first order, you can end up 
    trying to centre a saturated line. In this case, use the _ima.fits file,
    which holds all of the individual reads, and measure the line centre from
    the zero-read ima file in the first order.
    
    Parameters
    ----------
    root : str
        The file name to be checked
    y_arr : np.ndarray
        The y-values (flux values) from the flt file
    wave_arr : np.ndarray
        The approximate wavelength values from the flt file
    directory : str
        The directory where the flt file is located (and where the ima file
        should be located)
    
    Returns
    -------
    star_x : float
        The x centre of the line
    star_y : float
        The y centre of the line
    """
    file_name = os.path.join(directory, root+"_ima.fits")
    with fits.open(file_name) as in_file:
        hd = in_file[0].header
        nexten = hd['NEXTEND']
        ima = in_file[nexten-4].data    # zero read
        ima = ima[5:1019,5:1019]        # trim to match flt
        dq = in_file[nexten-2].data     # DQ=8 is unstable in Zread
        dq = dq[5:1019,5:1019]          # trim to match flt
        
        # Get approximate position from preliminary extraction
        xlin = tabinv(wave_arr, np.array((10830.,)))
        xapprox = np.floor(xlin + .5).astype(np.int32)
        if isinstance(xapprox, np.ndarray):
            xapprox = xapprox[0]
        yapprox = np.floor(y_arr[xapprox] + .5).astype(np.int32)
        if isinstance(yapprox, np.ndarray):
            yapprox = yapprox[0]
        if verbose:
            print(type(xapprox), type(yapprox))
            msg = "WLIMAZ: 10830 line at approx ({},{})"
            print(msg.format(xapprox, yapprox))
        
        # Fix any DQ=8 pixels
        ns = 11 # for an 11x11 search area
        sbimg = ima[yapprox-ns//2:yapprox+ns//2+1,xapprox-ns//2:xapprox+ns//2+1]
        sbdq = dq[yapprox-ns//2:yapprox+ns//2+1,xapprox-ns//2:xapprox+ns//2+1]
        bad = np.where((sbdq & 8) != 0)
        if len(bad) > 0:
            nbad = len(bad[0])
        # from wlimaz.pro comment:
        # ; I see up to nbad=5 in later data, eg ic6906bzq, but ima NOT zeroed & looks OK
        # ; no response from SED abt re-fetching new OTF processings
        totbad = np.sum(sbimg[bad])
        
        # If all bad pixels have been zeroed, interpolate them.
        if totbad == 0:
            if verbose:
                print("WLIMAZ: {} bad pixels repaired".format(nbad))
            for i in range(nbad):
                xbad = bad[0][i] % ns
                ybad = bad[0][i] / ns
                if xbad != 0 and xbad != ns-1 and ybad != 0 and ybad != ns-1:
                    bad_val = (sbimg[ybad,xbad-1] + sbimg[ybad,xbad+1] + 
                               sbimg[ybad-1,xbad] + sbimg[ybad+1,sbad])/4
                    sbimg[ybad,xbad] = bad_val

        indmx = np.unravel_index(np.argmax(sbimg, axis=None), sbimg.shape)
        xmx, ymx = indmx[1], indmx[0]
        xpos = xmx % ns
        ypos = ymx / ns

        # Threshold of 10 counts, FWHM of 2. Only return brightest result.
        star_finder = DAOStarFinder(10., 2., brightest=1)
        star_table = star_finder.find_stars(sbimg)
        star_x = star_table['xcentroid'][0]
        star_y = star_table['ycentroid'][0]
        if star_x < 0 or star_y < 0:
            print("WLIMAZ: Peak too close to edge: using approximate position.")
            star_x = xpos
            star_y = ypos
        
        star_x = star_x + xapprox - ns//2
        star_y = star_y + yapprox - ns//2
        if verbose:
            print("\tDAOFind: xc={}, yc={}".format(star_x, star_y))

        if nbad > 0:
            print("WLIMAZ: nbad={}, total bad counts={}".format(nbad, totbad))
        return star_x, star_y


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
    input_table = input_table[input_table["planetary_nebula"] == "True"]
    
    xpx = np.arange(1014, dtype=np.float64)

    if verbose:
        msg = "{}: Starting WFC3 wavelength measurement for GRISM data."
        print(msg.format(task))
        print("{}: Input table is:".format(task))
        print(input_table)
    
    known_issues_file = get_data_file("abscal.wfc3", "known_issues.json")
    with open(known_issues_file, 'r') as inf:
        known_issues = json.load(inf)
    issues = []
    if "wlmeas" in known_issues:
        issues = known_issues["wlmeas"]
    
    roots = []
    stars = []
    gratings = []
    x_ords = []
    y_ords = []
    orders = []
    lines = []
    notes = []
    
    for row in input_table:        
        root = row["root"]
        path = row["path"]
        file = os.path.join(row["path"], row["extracted"])
        star = row["target"]
        grat = row["filter"]
        preamble = "wlmeas: {} ({}) ({})".format(root, grat, star)
        with fits.open(file) as inf:
            wl = inf[1].data['wavelength']
            net = inf[1].data['net']
            dq = inf[1].data['eps'].astype(np.uint32)
            y_fit = inf[1].data['y_fit']
            if "xzorder" in inf[0].header:
                zxpos = inf[0].header['xzorder']
            else:
                zxpos = inf[0].header['xactual']
            if "yzorder" in inf[0].header:
                zypos = inf[0].header['yzorder']
            else:
                zypos = inf[0].header['yactual']
        
        # Bad DQ values are 256 (saturated), 516 (FF glitches),
        # and 32 (CTE tail) as per Table 2.5
        bad_dq = np.where((dq & (32|256|512)) != 0)
        good_dq = np.where((dq & (32|256|512)) == 0)
        
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
        wlref = wl_vac * (1. + pnvel/3.e5)
        
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
            
            line_dict = {}
            note_dict = {}
            
            for ilin in range(len(wlref)):
                wv = wl_vac[ilin]
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
                
                xgdrud = np.where((wrud > wlr - dw) & (wrud < wlr + dw))
                
                xgood = np.where((wl/iord > wlr - dw) & (wl/iord < wlr + dw))

                min_x = wl[np.min(xgood)] - 50
                net_min = np.min(net[xgood])
                max_x = wl[np.max(xgood)] + 50
                net_max = np.min(net[xgood])
                
                if interactive:
                    wl_good = np.where((wl > min_x-1000.) & (wl < max_x+1000.))
                    
                    fig = plt.figure()
                    plt.ion()
                    plt.show()
                    ax = fig.add_subplot(111)
                    title_str = "Search Range for {} {} order={} line={}"
                    ax.set_title(title_str.format(grat, root, iord, wlr))
                    plt.plot(wl[wl_good], net[wl_good])
                    plt.plot([min_x, min_x], [net_min*0.5, net_max*1.5])
                    plt.plot([max_x, max_x], [net_min*0.5, net_max*1.5])
                    plt.pause(0.001)
                    msg = "Press enter to continue."
                    cmd = input(msg)
                    plt.close("all")
                
                fit_status = "auto"
                cmd = "unknown"
                maxpos = np.argmax(net[xgood])
                bad = np.where(dq[maxpos-1:maxpos+2] & (32|256|512) != 0)
                if len(bad) > 0:
                    nbad = len(bad[0])
                
                # This case handles the very bright 10830A line falling in
                #   the first order
                if ilin == 2 and iord == 1:
                    xcentr, ycentr = wlimaz(root, y_fit, wl, path, verbose)
                    xline[2] = xcentr
                    fit_status = "ima"
                else:
                    if nbad > 0 and xline[ilin] == 0.:
                        print("WARNING: Centred using bad DQ")
                        
                    if root in issues:
                        if iord in issues[root]:
                            if ilin in issues[root][iord]:
                                xline[ilin] = issues[root][iord][ilin]["xcentr"]
                                fit_status = "hardcoded"
                    
                    # Only do the centroiding if the line hasn't been set
                    #   to a value yet.
                    if xline[ilin] == 0:
                        x_range = np.max(xgood) - np.min(xgood)
                        xmin = np.min(xgood)
                        xmax = np.max(xgood)
                        rng = x_range/5
                        cont_low = np.where((xpx >= xmin) & (xpx <= xmin + rng))
                        cont_hi = np.where((xpx >= xmax - rng) & (xpx <= xmax))
                        cont = (np.mean(net[cont_low]) + np.mean(net[cont_hi]))/2
                        xcentr, fit_status = linecen(xpx[xgood], net[xgood], cont)
                        xline[ilin] = xcentr
                
                while cmd != "":
                    if cmd != "unknown":
                        val = input("Enter central wavelength")
                        try:
                            xcentr = float(val)
                            fit_status = "custom"
                        except Exception as e:
                            print("Must enter a floating point value.")
                    fig = plt.figure()
                    plt.ion()
                    plt.show()
                    ax = fig.add_subplot(111)
                    title_str = "{} {} order={} line={}"
                    ax.set_title(title_str.format(grat, root, iord, wlr))
                    xrud = tabinv((wl/iord), wrud[xgdrud])
                    min_y = 0.
                    max_y = np.max(net[xgood])*1.1
#                     plt.plot(xrud, smorud[xgdrud], linestyle='--', label='WFC3 FWHM')
                    plt.scatter(wl[good_dq], net[good_dq], label='Good DQ')
                    plt.scatter(wl[bad_dq], net[bad_dq], label='Bad DQ')
                    x_int = np.floor(xcentr).astype(np.int32)
                    xwl = wl[x_int] + (xcentr-x_int)*(wl[x_int+1]-wl[x_int])
                    if fit_status == "good":
                        plt.plot([xwl, xwl], [0., 1.e10], label='Fit')
                    elif fit_status == "bad":
                        plt.plot([xwl, xwl], [0., 1.e10], label='Bad Fit or Not Found')
                    elif fit_status == "ima":
                        plt.plot([xwl, xwl], [0., 1.e10], label='From IMA zeroth read.')
                    elif fit_status == "hardcoded":
                        plt.plot([xwl, xwl], [0., 1.e10], label='From Known Issues.')
                    elif fit_status == "custom":
                        plt.plot([xwl, xwl], [0., 1.e10], label='User Custom')
                    plt.xlim(min_x, max_x)
                    plt.ylim(min_y, max_y)
                    plt.legend()
                    plt.pause(0.001)
                    print(xcentr)
                    msg = "Press enter to accept fit. Anything else to override"
                    cmd = input(msg)
                    plt.close("all")
                
                xline[ilin] = xcentr
                
                line_dict[int(wv)] = xcentr
                note_dict[int(wv)] = fit_status

                if verbose:
                    print("{}: Finished line {}".format(preamble, wv))
            
            roots.append(root)
            stars.append(star)
            gratings.append(grat)
            x_ords.append(zxpos)
            y_ords.append(zypos)
            orders.append(iord)
            lines.append(line_dict)
            notes.append(note_dict)
            
            if verbose:
                print("{}: Finished order {}.".format(preamble, iord))
        if verbose:
            print("{}: Finished obs {}".format(preamble, root))
    if verbose:
        print("{}: finished wavelength measurement.".format(preamble))
    
    output_table = Table()
    output_table['ROOT'] = Column(data=roots)
    output_table['STAR'] = Column(data=stars)
    output_table['GRAT'] = Column(data=gratings)
    output_table['X_0_ORD'] = Column(data=x_ords)
    output_table['Y_0_ORD'] = Column(data=y_ords)
    output_table['ORD'] = Column(data=orders)
    for float_key in wl_vac:
        key = int(float_key)
        key_data = []
        for line_dict in lines:
            if key in line_dict:
                key_data.append(line_dict[key])
            else:
                key_data.append(None)
        note_data = []
        for note_dict in notes:
            if key in note_dict:
                note_data.append(note_dict[key])
            else:
                note_data.append("")
        output_table["{}_pos".format(key)] = Column(data=key_data)
        output_table["{}_notes".format(key)] = Column(data=note_data)
    
    return output_table
    
    
def wlmake(initial_table, wl_table, arg_list, overrides={}):
    """
    Measures planetary nebula emission lines for wavelength fitting
    """
    task = "wlmake"
    verbose = arg_list.verbose
    interactive = arg_list.trace

    
    wl_vac = np.array([[ 9070.0,  9070.0,  9071.4,  9070.5], 
                       [ 9535.1,  9535.1,  9535.1,  9535.2],    
                       [10833.5, 10834.6, 10833.4, 10833.4], 
                       [12820.8, 12820.8, 12821.6, 12821.0], 
                       [16413.2, 16414.0, 16412.1, 16412.7]])
    
    bad = np.where(wl_table['X_0-ORD'] == 0.)
    if len(bad) > 0:
        nbad = len(bad[0])
    
    for grism in ['G102', 'G141']:
        nline = 3

        mask = [g == grism for g in wl_table['GRAT']]
        wl_table_grism = initial_table[mask]
        
        for iord in [-1, 1, 2]:
            ord_mask = [o == iord for o in wl_table_grism['ORD']]
            wl_table_ord = wl_table_grism[ord_mask]
            xord_mask = [x > 0 for x in wl_table_ord['X_0-ORD']]
            wl_table_good = wl_table_ord[xord_mask]
            ngood = len(wl_table_good)
            dofil = wl_table_good['ROOT']
            dostr = wl_table_good['STAR']
            doord = wl_table_good['ORD']
            dozx = wl_table_good['X_0-ORD']
            dozy = wl_table_good['Y_0-ORD']
            
            line_columns = []
            for column in wl_table_good.columns:
                try:
                    i = int(column)
                    line_columns.append(i)
                except Exception as e:
                    pass
            
            
#            dox1 = 
    
    output_table = Table()
    output_table['ROOT'] = Column(data=roots)
    output_table['STAR'] = Column(data=stars)
    output_table['GRAT'] = Column(data=gratings)
    output_table['X_0-ORD'] = Column(data=x_ords)
    output_table['Y_0-ORD'] = Column(data=y_ords)
    output_table['ORD'] = Column(data=orders)
    for key in lines:
        key_data = [item[key] for item in lines]
        output_table[key] = Column(data=key_data)
        note_data = [item[key] for item in notes]
        output_table["{}_notes".format(key)] = Column(data=note_data)
    
    return output_table


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


def main(overrides={}, do_meas=True, do_make=True):
    parsed = parse_args()
    
    for key in overrides:
        if hasattr(parsed, key):
            setattr(parsed, key, overrides[key])
    
    input_table = AbscalDataTable(table=parsed.table,
                                  duplicates='both',
                                  search_str='',
                                  search_dirs=parsed.paths,
                                  idl=parsed.compat)

    if do_meas:
        wl_calib_table = wlmeas(input_table, parsed, overrides)
    
        table_fname = parsed.out_file
        wl_calib_table.write(table_fname, format='ascii.ipac', overwrite=True)
    else:
        wl_calib_table = input_table
    
    if do_make:
        pass


if __name__ == "__main__":
    main()
