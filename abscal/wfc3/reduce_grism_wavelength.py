#! /usr/bin/env python
"""
This module takes a table of exposures, finds all exposures tagged as planetary nebula 
exposures, and:

- For each grism
    - For each spectral order
        - For each file
            - Determines which emission lines fall in that order of that file
            - Attempts to automatically fit the line location
            - Allows the user to override the result of the automatic fit
            - Records the resulting fit location and status (good/bad/custom/etc.)

The module then saves a table of the results.

In addition, the module can take the result table above and use it to derive an overall 
wavelength fit for each grism/order value of the inputs, and produce yet another output 
table given the results of that fit.

Authors
-------
- Brian York (all python code)
- Ralph Bohlin (original IDL code)

Use
---
This module can be run from the command line (although one of the `abscal.commands` or 
`abscal.idl_commands` scripts would be preferred for that), but is mostly intended to be 
imported, either by binary scripts or for use from within python::

    from abscal.wfc3.reduce_grism_wavelength import wlmeas, wlmake
    
    interim_table = wlmeas(input_table, command_line_arg_namespace, override_dict)
    final_table = wlmake(input_table, interim_table, command_line_arg_namespace, override_dict)

The override dict allows for many of the default input parameters to be overriden (as 
defaults -- individual per-exposure overrides defined in the data files will still take 
priority). There are currently no default parameters that can be overriden in this module.
"""

# *****TODO*****
#   The following things could potentially be overridable parameters:
#       - wlmeas
#           - search region size around emission line
#           - order wavelength search ranges (wrang)

import datetime
import glob
import json
import os
import yaml

import matplotlib.pyplot as plt
import numpy as np

from astropy import constants as consts
from astropy.io import ascii, fits
from astropy.table import Table, Column, unique
from astropy.time import Time
from copy import deepcopy
from matplotlib.widgets import TextBox
from pathlib import Path
from photutils.detection import DAOStarFinder
from scipy.linalg import lstsq
from scipy.stats import mode

from abscal.common.args import parse
from abscal.common.standard_stars import find_star_by_name
from abscal.common.utils import air2vac, get_data_file, get_defaults, linecen
from abscal.common.utils import smooth_model, tabinv
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.wfc3.reduce_grism_extract import reduce

def wlimaz(root, y_arr, wave_arr, directory, verbose):
    """
    Find a line from the IMA zero-read.
    
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


def wlmeas(input_table, **kwargs):
    """
    Measure planetary nebula emission line locations.
    
    There are six planetary nebula emission lines that fall neatly into the WFC3 grism 
    spectral orders, and this function uses the approximate wavelength solution to find 
    the rough location of these lines, and then uses flux-weighting to determine the line 
    centre. The user is able to override a given fit if the script is run with the 
    show_plots flag.
    
    Parameters
    ----------
    input_table : abscal.common.exposure_data_table.AbscalDataTable
        Table of exposures with emission lines to fit.
    kwargs : dict
        Dictionary of overrides to the default reduction parameters, and command-line 
        option selections.
    
    Returns
    -------
    output_table : astropy.table.Table
        Table of emission line locations
    """
    task = "wfc3: grism: wlmeas"
    default_values = get_defaults('abscal.common.args')
    base_defaults = default_values | get_defaults(kwargs.get('module_name', __name__))
    verbose = kwargs.get('verbose', base_defaults['verbose'])
    show_plots = kwargs.get('plots', base_defaults['plots'])
    if 'out_file' in kwargs:
        out_file = kwargs['out_file']
        out_dir, out_table = os.path.split(out_file)
        if out_dir == '':
            out_dir = os.getcwd()
    else:
        out_dir = os.getcwd()
    spec_name = kwargs.get('spec_dir', base_defaults['spec_dir'])
    spec_dir = os.path.join(out_dir, spec_name)

    issues = {}
    exposure_parameter_file = get_data_file("abscal.wfc3", os.path.basename(__file__))
    if exposure_parameter_file is not None:
        with open(exposure_parameter_file, 'r') as inf:
            issues = yaml.safe_load(inf)
    
    fwhm = {
                'G102': {
                            -1: 80.,
                            1: 80.,
                            2: 40.
                        },
                'G141': {
                            -1: 120.,
                            1: 120.,
                            2: 60
                        }
            }

    # lab reference line wavelengths
    wl_air = np.array([9068.6, 9532.5, 10830., 12818.1, 16109.3, 16407.2])
    wl_vac = air2vac(wl_air)

    # Get wavelength reference file
    cal_data = get_data_file("abscal.wfc3", "calibration_files.yaml")
    with open(cal_data, 'r') as inf:
        cal_files = yaml.safe_load(inf)
    pn_ref_name = cal_files["ic5117_data"]
    pn_ref = get_data_file("abscal.wfc3", pn_ref_name)

    # Columns are 'wavelength' and 'flux'
    pn_ref_table = Table.read(pn_ref, format="ascii.basic")
    
    input_table = deepcopy(input_table)
    input_table = input_table[input_table["planetary_nebula"] == True]

    xpx = np.arange(1014, dtype=np.float64)

    if verbose:
        msg = "{}: Starting WFC3 wavelength measurement for GRISM data."
        print(msg.format(task))

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
        root_filter = input_table["root"]==row["root"]
        # Imaging files shouldn't be processed
        if row["filter"][0] == 'F':
            continue
        # Files without spectra (i.e. have no "extracted" entry) shouldn't be processed.
        if hasattr(row["extracted"], "mask") and row["extracted"].mask:
            continue

        spec_file = os.path.join(row['path'], row['extracted'])
        if not os.path.isfile(spec_file):
            # look for default extracted file
            extracted_name = "{}_{}_x1d.fits".format(row['root'], row['target'])
            print("Extracted Name: {}".format(extracted_name))
            extracted_dest = os.path.join(spec_dir, extracted_name)
            print("Extracted File: {}".format(extracted_dest))
            
            if os.path.isfile(extracted_dest):
                spec_file = extracted_dest
                extracted_value = os.path.join(spec_name, extracted_name)
                input_table['extracted'][root_filter] = extracted_value
                row['extracted'] = extracted_value
            else:
                msg = "{}: Unable to find extracted spectrum '{}'. Extracting."
                print(msg.format(task, row['extracted']))
                extract_table = input_table[input_table['root']==row['root']]
                output_row = reduce(extract_table, **kwargs)
                for item in ['path', 'extracted', 'xc', 'yc', 'xerr', 'yerr']:
                    input_table[item][root_filter] = output_row[item][0]
                    row[item] = output_row[item][0]
                spec_file = os.path.join(output_row['path'][0], 
                                         output_row['extracted'][0])
                if not os.path.isfile(spec_file):
                    msg = "{}: {}: ERROR: EXTRACTION FAILED. SKIPPING ROW"
                    print(msg.format(task, row['root']))
                    continue
        # END search for the 1d extracted spectrum.

        if verbose:
            print("{}: reducing {}".format(task, root))
            print("\tpath is {}".format(path))
            print("\textracted is {}".format(row["extracted"]))
            print("\tfile is {}".format(spec_file))
            print("\trow: ")
            print(row)
        star = row["target"]
        grat = row["filter"]
        preamble = "wlmeas: {} ({}) ({})".format(root, grat, star)
        with fits.open(spec_file) as inf:
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

        pnvel = 0. # radial velocity            
        target_star = find_star_by_name(row['target'])
        if target_star is not None:
            pnvel = target_star['radial_velocity']

        wrud = pn_ref_table['wavelength'] * (1. + pnvel/consts.c.to('km/s').value)
        wlref = wl_vac * (1. + pnvel/consts.c.to('km/s').value)

        for iord in [-1, 1, 2]:

            dlam = fwhm[grat][iord]

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

                if show_plots:
                    wl_good = np.where((wl > min_x-1000.) & (wl < max_x+1000.))

                    fig = plt.figure()
                    ax = fig.add_subplot(111)
                    title_str = "{} {} order={} line={} Search Range"
                    ax.set_title(title_str.format(grat, root, iord, wlr))
                    plt.plot(wl[wl_good], net[wl_good])
                    plt.plot([min_x, min_x], [net_min*0.5, net_max*1.5])
                    plt.plot([max_x, max_x], [net_min*0.5, net_max*1.5])
                    plt.show()

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

                if nbad > 0 and xline[ilin] == 0.:
                    print("WARNING: Centred using bad DQ")

                if root in issues:
                    siord = str(iord)
                    silin = str(ilin)
                    if siord in issues[root]:
                        if silin in issues[root][siord]:
                            xline[ilin] = float(issues[root][siord][silin]["xcentr"])
                            fit_status = "hardcoded"

                # Only do the centroiding if the line hasn't been set
                #   to a value yet.
                if xline[ilin] == 0 or fit_status == "ima":
                    xmin = np.min(xgood)
                    xmax = np.max(xgood)
                    search_range = (np.max(xgood) - np.min(xgood))/5
                    cont_low = np.where((xpx >= xmin) & (xpx <= xmin + search_range))
                    cont_hi = np.where((xpx >= xmax - search_range) & (xpx <= xmax))
                    cont = (np.mean(net[cont_low]) + np.mean(net[cont_hi]))/2
                    xcentr, fit = linecen(xgood[0], net[xgood], cont)
                    if fit == "good" or xline[ilin] == 0:
                        xline[ilin] = xcentr
                        if fit_status == "ima":
                            fit_status = "good (ima)"
                        else:
                            fit_status = fit


                cmd = {"choice": "unknown", "fit_status": fit_status, "msg": "",
                       "finished": False, "submitted": False}

                if show_plots or (("good" not in cmd["fit_status"]) and \
                                  ("hardcoded" not in cmd["fit_status"])):
                
                    while not cmd["finished"]:
    
                        cmd["submitted"] = False
    
                        fig, ax = plt.subplots()
                        fig.subplots_adjust(bottom=0.2)
    
                        title_str = "{} {} order={} line={}"
                        ax.set_title(title_str.format(grat, root, iord, wlr))
                        xrud = tabinv((wl/iord), wrud[xgdrud])
                        min_y = 0.
                        max_y = np.max(net[xgood])*1.1
#                         plt.plot(xrud, smorud[xgdrud], linestyle='--', label='WFC3 FWHM')
                        plt.scatter(wl[good_dq], net[good_dq], label='Good DQ')
                        plt.scatter(wl[bad_dq], net[bad_dq], label='Bad DQ')
                        if cmd["fit_status"] in ["custom", "rejected"]:
                            x_int = np.floor(cmd["choice"]).astype(np.int32)
                            xwl = wl[x_int] + (cmd["choice"]-x_int)*(wl[x_int+1]-wl[x_int])
                        else:
                            x_int = np.floor(xcentr).astype(np.int32)
                            xwl = wl[x_int] + (xcentr-x_int)*(wl[x_int+1]-wl[x_int])
                        if cmd["fit_status"] == "good" or cmd["fit_status"] == "good (ima)":
                            plt.plot([xwl, xwl], [0., 1.e10], color='green', label='Fit')
                        elif cmd["fit_status"] == "bad" or cmd["fit_status"] == "rejected":
                            plt.plot([xwl, xwl], [0., 1.e10], color='red',
                                     label='Bad Fit, Rejected Fit, or Not Found')
                        elif cmd["fit_status"] == "ima":
                            plt.plot([xwl, xwl], [0., 1.e10], color='blue',
                                     label='IMA zeroth read.')
                        elif cmd["fit_status"] == "hardcoded":
                            plt.plot([xwl, xwl], [0., 1.e10], color='grey',
                                     label='Hardcoded from Known Issues.')
                        elif cmd["fit_status"] == "custom":
                            plt.plot([xwl, xwl], [0., 1.e10], color='grey',
                                     label='User Custom')
                        else:
                            plt.plot([xwl, xwl], [0., 1.e10], color='red',
                                     label='UNKNOWN FIT')
                        plt.xlim(min_x, max_x)
                        plt.ylim(min_y, max_y)
                        plt.legend()

                        text_axes = fig.add_axes([0.75, 0.05, 0.15, 0.075])
                        msg = "Empty to accept fit, X to reject all fits, Wavelength "
                        msg += "for custom fit:"
                        text_box = TextBox(text_axes, msg, initial=cmd["msg"])

                        def submit(choice):
                            if choice == "":
                                cmd["finished"] = True
                                cmd["submitted"] = True
                            elif choice in ['x', 'X']:
                                wl_choice = wl[xgood][(len(xgood[0])-1)//2]
                                pix = np.searchsorted(wl, wl_choice)
                                cmd["choice"] = pix
                                cmd["fit_status"] = "rejected"
                                cmd["submitted"] = True
                            else:
                                try:
                                    custom_wl = float(choice)
                                    pix = np.searchsorted(wl, custom_wl)
                                    remainder = (custom_wl - wl[pix])/(wl[pix+1]-wl[pix])
                                    cmd["choice"] = pix + remainder
                                    cmd["fit_status"] = "custom"
                                    cmd["msg"] = ""
                                    cmd["submitted"] = True
                                except Exception as e:
                                    msg = "Enter nothing to accept fit, a floating point "
                                    msg += "value to choose a custom fit, or 'X' to reject"
                                    msg += "any fit."
                                    cmd["msg"] = msg
                                    cmd["fit_status"] = fit_status
                                    cmd["submitted"] = True
                            plt.close("all")

                        text_box.on_submit(submit)

                        def handle_close(evt):
                            if not cmd["submitted"]:
                                submit(text_box.text)

                        fig.canvas.mpl_connect('close_event', handle_close)
                        plt.show()
                # end if showing the plot.

                if cmd["fit_status"] == "custom":
                    fit_status = "custom"
                    xcentr = cmd["choice"]
                elif cmd["fit_status"] == "rejected":
                    fit_status = "rejected"
                    xcentr = cmd["choice"]

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
    output_table['root'] = Column(data=roots)
    output_table['star'] = Column(data=stars)
    output_table['grism'] = Column(data=gratings)
    output_table['X_0_ORD'] = Column(data=x_ords)
    output_table['Y_0_ORD'] = Column(data=y_ords)
    output_table['order'] = Column(data=orders)
    for float_key in wl_vac:
        key = int(float_key)
        key_data = []
        for line_dict in lines:
            if key in line_dict:
                key_data.append(line_dict[key])
            else:
                key_data.append(-1.)
        note_data = []
        for note_dict in notes:
            if key in note_dict:
                note_data.append(note_dict[key])
            else:
                note_data.append("")
        output_table["{}_pos".format(key)] = Column(data=key_data, format='.3f')
        output_table["{}_notes".format(key)] = Column(data=note_data)

    return output_table


def wlmake(input_table, wl_table, **kwargs):
    """
    Derives a grism wavelength fit.
    
    Once planetary nebula emission lines have been located and fit, it is possible to use
    them as input in creating a full wavelength fit for the grism detector. ABSCAL fits 
    the wavelength set with a linear slope and intercept, where both the slope and the 
    intercept have constant terms, linear terms in X, and linear terms in y.
    
    Once the fit has been calculated, the script prints out fit errors based on the input 
    exposures, and creates an output table with all of the fit terms. A separate fit is 
    derived for each order of each grism.

    Parameters
    ----------
    input_table : abscal.common.exposure_data_table.AbscalDataTable
        Table of exposures to be fit.
    wl_table : astropy.table.Table
        Output of wlmeas.
    kwargs : dict
        Dictionary of overrides to the default reduction parameters, and command-line 
        option selections.
    
    Returns
    -------
    output_table : astropy.table.Table
        Table of wavelength fit values
    """
    task = "wfc3: grism: wlmake"
    default_values = get_defaults('abscal.common.args')
    base_defaults = default_values | get_defaults(kwargs.get('module_name', __name__))
    verbose = kwargs.get('verbose', base_defaults['verbose'])
    show_plots = kwargs.get('plots', base_defaults['plots'])
    if 'out_file' in kwargs:
        out_file = kwargs['out_file']
        out_dir, out_table = os.path.split(out_file)
        if out_dir == '':
            out_dir = os.getcwd()
    else:
        out_dir = os.getcwd()
    spec_name = kwargs.get('spec_dir', base_defaults['spec_dir'])
    spec_dir = os.path.join(out_dir, spec_name)
    
    if verbose:
        print("Starting {}\nInput data:\n{}".format(task, wl_table))

    line_array = [9071, 9535, 10832, 12821, 16411] #16113, 16411]
    visible_lines = {
                        'G102': [9071, 9535, 10832],
                        'G141': [10832, 12821, 16411] #16113, 16411]
                    }
    wl_vac = np.array([[ 9070.0,  9070.0,  9071.4,  9070.5],
                       [ 9535.1,  9535.1,  9535.1,  9535.2],
                       [10833.5, 10834.6, 10833.4, 10833.4],
                       [12820.8, 12820.8, 12821.6, 12821.0],
                       # WHERE IS 16113?
#                       [],
                       [16413.2, 16414.0, 16412.1, 16412.7]])

    bad = np.where(wl_table['X_0_ORD'] == 0.)
    if len(bad) > 0:
        nbad = len(bad[0])
    
    results = {
                'grism': [],
                'order': [],
                'b_constant': [],
                'b_x': [],
                'b_y': [],
                'm_constant': [],
                'm_x': [],
                'm_y': []
              }

    for grism_index,grism in enumerate(['G102', 'G141']):
        if verbose:
            print("{}: starting grism {}".format(task, grism))

        mask = [g == grism for g in wl_table['grism']]
        grism_table = wl_table[mask]

        for iord in [-1, 1, 2]:
            if verbose:
                print("{}: {}: starting order {}".format(task, grism, iord))
            ord_mask = [o == iord for o in grism_table['order']]
            current_table = grism_table[ord_mask]
            xord_mask = [x > 0 for x in current_table['X_0_ORD']]
            current_table = current_table[xord_mask]
            emline_mask = []
            for row in current_table:
                is_any_valid = False
                for col in ["{}_pos".format(l) for l in line_array]:
                    if row[col] > 0:
                        is_any_valid = True
                emline_mask.append(is_any_valid)
            current_table = current_table[emline_mask]
            ngood = len(current_table)
            if ngood <= 0:
                continue
            if verbose:
                print("{}: {}: {}: Found {} good rows".format(task, grism, iord, ngood))
            dofil = current_table['root']
            dostr = current_table['star']
            doord = current_table['order'].data
            dozx = current_table['X_0_ORD'].data
            dozy = current_table['Y_0_ORD'].data
            wl_index = grism_index + 2*(abs(iord) - 1)
            results['grism'].append(grism)
            results['order'].append(iord)

            # Set up line offsets due to standard star radial velocity
            radial_velocity = np.zeros((ngood,), dtype=np.float64)
            rvc_p1 = np.zeros((ngood,), dtype=np.float64)
            for i,row in enumerate(current_table):
                star = find_star_by_name(row['star'])
                radial_velocity[i] = star['radial_velocity']
                rvc_p1[i] = 1 + star['radial_velocity']/consts.c.to('km/s').value
            
            good_fits = {}
            good_lines = []
            print(current_table)
            for line in visible_lines[grism]:
                print("Checking line {}".format(line),end='')
                good_fits[line] = 0
                for row in current_table:
                    notes_col = '{}_notes'.format(line)
                    if ('good' in row[notes_col]) or ('custom' in row[notes_col]):
                        good_fits[line] += 1
                        print(" good ",end='')
                    else:
                        print(" bad ",end='')
                print("{} good of {} ".format(good_fits[line], ngood),end='')
                if good_fits[line] > 0.5*ngood:
                    print("adding line {}.".format(line))
                    good_lines.append(line)
                else:
                    print("rejected.")
            nline = len(good_lines)
            low_line, high_line = min(good_lines), max(good_lines)
            low_idx, high_idx = line_array.index(low_line), line_array.index(high_line)
            doxi = np.zeros((ngood, nline), dtype=np.float64)
            for i,line in enumerate(good_lines):
                doxi[:,i] = current_table['{}_pos'.format(line)].data
            dox1 = current_table['{}_pos'.format(low_line)].data
            dox2 = current_table['{}_pos'.format(high_line)].data
            ref_line = np.full((ngood,), wl_vac[low_idx, wl_index])
            disp = (wl_vac[high_idx, wl_index] - wl_vac[low_idx, wl_index]) * doord
            disp *= rvc_p1/(dox2 - dox1)
            ref_line *= rvc_p1

            # Make polynomial fit to WL = b + m*delpx, spit out coefficient, and
            #   iterate to check results. Where delpx = x - x0, b = b1 + b2*x + b3*y,
            #   m = m1 + m2*x + m3*y, x0 is the z-order reference pixel location.
            xpx = np.arange(1014, dtype=np.float64)
            fit_good = np.where(((dox1 > 0.) & (dox2 > 0.)))
            n_fit_good = len(fit_good[0])

            #b3rd is 3rd element of b array. First 2 are X,Y of z-order.
            b3rd = ref_line[fit_good]*iord
            b3rd -= disp[fit_good]*(dox1[fit_good] - dozx[fit_good])
            b = np.zeros((n_fit_good,3), dtype=np.float64)
            b[:,0] = dozx[fit_good]
            b[:,1] = dozy[fit_good]            
            m = deepcopy(b)
            b[:,2] = b3rd[:]
            if verbose:
                print("b matrix is {}".format(b))
            b_fit,_,_,_ = lstsq(np.c_[b[:,0], b[:,1], np.ones(b.shape[0])], b[:,2])
            b_x, b_y, b_const = b_fit
            bfit = [b_const + b_x*x + b_y*y for x,y in zip(b[:,0], b[:,1])]
            results['b_constant'].append(b_const)
            results['b_x'].append(b_x)
            results['b_y'].append(b_y)
            bval = b_const + b_x*506 + b_y*506 # b at (x,y) = (506,506)
            xr = [np.min(dozx[fit_good]), np.max(dozx[fit_good])] # range of 0-order points
            if verbose:
                print("{}: {}: {}: Z0 x-range is {}".format(task, grism, iord, xr))
                print("\t b1={}, b2={}, b3={}".format(b_const, b_x, b_y))
            m[:,2] = disp[fit_good]
            if verbose:
                print("m matrix is {}".format(m))
            m_fit,_,_,_ = lstsq(np.c_[m[:,0], m[:,1], np.ones(m.shape[0])], m[:,2])
            m_x, m_y, m_const = m_fit
            mfit = [m_const + m_x*x + m_y*y for x,y in zip(m[:,0], m[:,1])]
            results['m_constant'].append(m_const)
            results['m_x'].append(m_x)
            results['m_y'].append(m_y)
            mval = m_const + m_x*xpx * m_y*506
            mval = m_const + m_x*xpx * m_y*106
            mval = m_const + m_x*xpx * m_y*906
            if verbose:
                print("\t m1={}, m2={}, m3={}".format(m_const, m_x, m_y))
            
            line = []
            for em_line in visible_lines[grism]:
                line.append(wl_vac[line_array.index(em_line), wl_index])

            for ilin in range(nline):
                line_good = np.where((doord == iord) & (dox1 > 0.) & (dox2 > 0) & \
                                     (doxi[:,ilin] > 0))
                n_line_good = len(line_good[0])
                if n_line_good <= 0:
                    break # in theory break from the entire order, but we do what we can.
                wlerr = np.zeros((n_line_good,), np.float64)
                if verbose:
                    msg = "{}: {}: {}: File      Xmeas (px)  Xfit   err (A)"
                    print(msg.format(task, grism, iord))
                for igd in range(n_line_good):
                    indx = line_good[0][igd]
                    row = current_table[indx]
                    bval = b_const + b_x*dozx[indx] + b_y*dozy[indx]
                    mval = m_const + m_x*dozx[indx] + m_y*dozy[indx]
                    wnew = bval + mval*(xpx - dozx[indx])
                    xfit = tabinv(wnew, line[ilin]*iord*rvc_p1[indx])
                    wlerr[igd] = (doxi[indx,ilin] - xfit)*mval
                    if verbose:
                        msg = "                 {} {:8.2f} {:8.2f} {:8.2f} YZO={:8.2f}"
                        print(msg.format(row['root'], doxi[indx,ilin], xfit[0], 
                                         wlerr[igd], dozy[indx]))
                if verbose:
                    msg = "Line, rms (A) and avg={}, {}, {}, #Obs={}"
                    print(msg.format(line[ilin], np.std(wlerr), np.mean(wlerr), 
                                     n_line_good))
            
            dmeas = m[:,2]
            bmeas = b[:,2]
            xpos, ypos = dozx, dozy
            berr = bmeas - bfit
            merr = dmeas - mfit
            if verbose:
                msg = "{}: {}: {}: File     ZX (px)    ZY    b fit (A)     bmeas     berr"
                print(msg.format(task, grism, iord))
                for i in range(ngood):
                    row = current_table[i]
                    msg = "               {} {:8.2f} {:8.2f} {:8.2f} {:8.2f}  {:8.2f}"
                    print(msg.format(row['root'], xpos[i], ypos[i], bfit[i], bmeas[i], 
                                     berr[i]))
                print("b rms={}".format(np.std(bmeas-bfit)))
                print("m rms={}".format(np.std(dmeas-mfit)))
            
            if show_plots:
                for igd in range(ngood):
                    row = current_table[igd]
                    full_row = input_table[input_table['root']==row['root']]
                    full_file = os.path.join(full_row["path"].data[0], 
                                             full_row["extracted"].data[0])
                    if not os.path.isfile(full_file):
                        full_name = "{}_{}_x1d.fits".format(row['root'], 
                                                            full_row['target'].data[0])
                        full_file = os.path.join(spec_dir, full_name)
                    if os.path.isfile(full_file):
                        star = find_star_by_name(row['star'])
                        rvc = star['radial_velocity']/consts.c.to('km/s').value
                        with fits.open(full_file) as inf:
                            wl = inf[1].data['wavelength']
                            net = inf[1].data['net']
                            angle = inf[0].header["angle"]
                
                        fig, ax = plt.subplots()
                        title_str = "{} {} order={} Fitted vs. Measured Line Positions"
                        ax.set_title(title_str.format(row['root'], grism, iord))

                        bval = b_const + b_x*dozx[igd] + b_y*dozy[igd]
                        mval = m_const + m_x*dozx[igd] + m_y*dozy[igd]
                        wnew = bval + mval*(xpx - dozx[igd])
                        plt.plot(wl/iord, net, 'b', label='Initial Wavelength Estimate')
                        plt.plot(wnew/iord, net, 'g', label='Fitted Wavelength')
                        for i in range(len(wl_vac[:,wl_index])):
                            plt.plot([wl_vac[i,wl_index], wl_vac[i,wl_index]*(1+rvc)],
                                     [0., 1.e5], 'r', linestyle='dashed')
                        msg = "Zero-order at ({:.2f},{:.2f})"
                        plt.figtext(0.2,0.2,msg.format(dozx[igd], dozy[igd]))
                        plt.legend()
                        # Figure out X and Y limits
                        if grism == "G102":
                            wave_low, wave_high = 9000, 11000
                        elif grism == "G141":
                            wave_low, wave_high = 10500, 17500
                        plt.xlim(wave_low, wave_high)
                        ind_low = np.searchsorted(wnew/iord, wave_low, side='left')
                        ind_high = np.searchsorted(wnew/iord, wave_high, side='right')
                        net_region = net[ind_low:ind_high]
                        plt.ylim(0, np.max(net_region)*1.1)
                        plt.show()
                
                        if verbose:
                            print("{}: {}: {}: {}".format(task, grism, iord, row['root']))
                            print("b={}, m={}".format(bval, mval))
                            print("Measured Dispersion = {}".format(dmeas[igd]))
                            print("Measured b={}".format(bmeas[igd]))
                            print("b,m errors={}, {}".format(bval-bmeas[igd], mval-dmeas[igd]))
                            print("Angle={}".format(angle))
            # done interactive plot
        # DONE ORDER LOOP
    # DONE GRISM LOOP

    output_table = Table()
    output_table['grism'] = Column(data=results['grism'])
    output_table['order'] = Column(data=results['order'])
    output_table['b_constant'] = Column(data=results['b_constant'])
    output_table['b_x'] = Column(data=results['b_x'])
    output_table['b_y'] = Column(data=results['b_y'])
    output_table['m_constant'] = Column(data=results['m_constant'])
    output_table['m_x'] = Column(data=results['m_x'])
    output_table['m_y'] = Column(data=results['m_y'])

    return output_table


def wl_offset(input_table, **kwargs):
    """
    Derives wavelength offsets for white dwarf exposures.
    
    Cross-correlates flux and net from white dwarf exposures against one another to derive 
    offsets

    Parameters
    ----------
    input_table : abscal.common.exposure_data_table.AbscalDataTable
        Table of exposures to have offsets generated.
    kwargs : dict
        Dictionary of overrides to the default reduction parameters, and command-line 
        option selections.
    
    Returns
    -------
    output_table : astropy.table.Table
        Updated table
    """
    task = "wfc3: grism: wloffset"
    default_values = get_defaults('abscal.common.args')
    base_defaults = default_values | get_defaults(kwargs.get('module_name', __name__))
    verbose = kwargs.get('verbose', base_defaults['verbose'])
    show_plots = kwargs.get('plots', base_defaults['plots'])
    if 'out_file' in kwargs:
        out_file = kwargs['out_file']
        out_dir, out_table = os.path.split(out_file)
        if out_dir == '':
            out_dir = os.getcwd()
    else:
        out_dir = os.getcwd()
    spec_name = kwargs.get('spec_dir', base_defaults['spec_dir'])
    spec_dir = os.path.join(out_dir, spec_name)
    
    return input_table


def additional_args(**kwargs):
    """
    Additional command-line arguments. 
    
    Provides additional command-line arguments that are unique to the wavelength fitting 
    process.
    
    Returns
    -------
    additional_args : dict
        Dictionary of tuples in the form (fixed,keyword) that can be passed to an argument 
        parser to create a new command-line option
    """
    module_name = kwargs.get('module_name', __name__)
    base_defaults = get_defaults(module_name)

    additional_args = {}

    table_help = "The input metadata table to use."
    table_args = ['table']
    table_kwargs = {'help': table_help}
    additional_args['table'] = (table_args, table_kwargs)

    plots_help = "Include result plots while running."
    plots_args = ["-p", "--plots"]
    plots_kwargs = {'dest': 'plots', 'action': 'store_true', 
                    'default': base_defaults['plots'], 'help': plots_help}
    additional_args['plots'] = (plots_args, plots_kwargs)

    return additional_args


def parse_args(**kwargs):
    """
    Parse command-line arguments.
    
    Gets the custom arguments from wavelength fitting, and passes them to the common 
    command-line option function.
    
    Returns
    -------
    res : namespace
        parsed argument namespace
    """
    description_str = 'Process files from metadata table.'
    default_out_file = kwargs.get('default_input_file', 'dirirstare.log')
    default_in_file = kwargs.get('default_input_file', 'dirirstare.log')

    args = additional_args(**kwargs)

    res = parse(description_str, default_out_file, args, **kwargs)

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


def main(do_measure=True, do_make=True, **kwargs):
    """
    Run the wavelength fitting function(s).
    
    Runs the wavelength fitting function(s) if called from the command line, with 
    command-line arguments added in. Can run wlmeas, wlmake, or both.
    
    Parameters
    ----------
    do_measure : bool, default True
        Run wlmeas function
    do_make : bool, default, True
        Run wlmake function
    kwargs : dict
        Dictionary of parameters to override when running.
    """
    kwargs['default_output_file'] = 'wlmeastmp.log'
    parsed = parse_args(**kwargs)

    for key in kwargs:
        if hasattr(parsed, key):
            setattr(parsed, key, kwargs[key])

    input_table = AbscalDataTable(table=parsed.table,
                                  duplicates='both',
                                  search_str='',
                                  search_dirs=parsed.paths)

    measure_fname = parsed.out_file
    if do_measure:
        wl_calib_table = wlmeas(input_table, **vars(parsed), **kwargs)
        wl_calib_table.write(measure_fname, format='ascii.ipac', overwrite=True)
    else:
        wl_calib_table = Table.read(measure_fname, format='ascii.ipac')
    
    if do_make:
        final_wave_table = wlmake(input_table, wl_calib_table, **vars(parsed), **kwargs)
        (table_file, table_ext) = os.path.splitext(parsed.out_file)
        final_fname = table_file + "_final" + table_ext
        final_wave_table.write(final_fname, format='ascii.ipac', overwrite=True)
    # Done.


if __name__ == "__main__":
    main(module_name='abscal.wfc3.reduce_grism_wavelength')
