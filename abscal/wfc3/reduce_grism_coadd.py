#! /usr/bin/env python
"""
Extract and co-add a group of WFC3 grism spectra.

This submodule

- Takes an input exposure table (from `preprocess_table_create`)
- Groups the exposures by grating
- Finds and extracts the standard star spectrum from each exposure
- Groups the extracted spectra by program and visit
- Co-adds together each group

While it can produce substantial output, both in logging and plots, it can also run 
without user intervention. User intervention is only asked for in choosing the best 
centroid fit for the zeroth order image.

Authors
-------
- Brian York (all python code)
- Ralph Bohlin (original IDL code)

Use
---
This module can be run from the command line (although one of the `abscal.commands` or 
`abscal.idl_commands` scripts would be preferred for that), but is mostly intended to be 
imported, either by binary scripts or for use from within python::

    from abscal.wfc3.reduce_grism_coadd import coadd
    
    output_table = coadd(input_table, command_line_arg_namespace, override_dict)

The override dict allows for many of the default input parameters to be overriden (as 
defaults -- individual per-exposure overrides defined in the data files will still take 
priority). Parameters that can be overriden in coadd are:

width: default 22
    The width (in pixels) of the cross-correlation search region
wbeg: default 7500 (G102), 10000 (G141)
    The lowest valid wavelength
wend: default 11800 (G102), 17500 (G141)
    The highest valid wavelength
regbeg_m1: default -13500 (G102), -19000 (G141)
    The start of the -1st spectral order region
regend_m1: default -3800 (G102), -5100 (G141)
    The end of the -1st spectral order region
regbeg_p1: default -3800 (G102), -5100 (G141)
    The start of the 1st spectral order region
regend_p1: default 13500 (G102), 19000 (G141)
    The end of the 1st spectral order region
regbeg_p2: default 13500 (G102), 19000 (G141)
    The start of the 2nd spectral order region
regend_p2: default 27000 (G102), 38000 (G141)
    The end of the 2nd spectral order region
"""

import datetime
import glob
import os
import sys
import yaml

import matplotlib.pyplot as plt
import numpy as np

from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy
from pathlib import Path
from scipy.stats import mode

from abscal.common.args import parse
from abscal.common.utils import get_data_file, get_defaults, set_params
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.wfc3.reduce_grism_extract import reduce
from abscal.wfc3.reduce_grism_extract import additional_args as extract_args
from abscal.wfc3.util_grism_cross_correlate import cross_correlate


def coadd(input_table, **kwargs):
    """
    Co-adds grism data
    
    Takes the input table, and 
    
    - filters out the grism exposures, then for each
    
        - looks for an extracted spectrum
        - if none is found, call reduce_grism_extract to make one
    
    - groups the grism exposures by program/visit/grism, then for each group
    
        - co-adds the spectra in that group
        - creates a FITS file (and an ASCII table) for each co-added spectrum
    
    - writes out a new version of the input table with updated values (if any)
    
    Parameters
    ----------
    input_table : abscal.common.exposure_data_table.AbscalDataTable
        The initial table of exposures
    kwargs : dict
        A dictionary of overrides to the default command-line arguments and to the default 
        co-add parameters.
    
    Returns
    -------
    input_table : abscal.common.exposure_data_table.AbscalDataTable
        The updated table of exposures
    """
    print(kwargs)
    task = "wfc3: grism: coadd"
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
        print("{}: Starting WFC3 coadd for GRISM data.".format(task))
        print("{}: Input table is:".format(task))
        print(input_table)

    # 32 and 512 OK "per icqv02i3q RCB 2015may26"
    flags = 4 | 8 | 16 | 64 | 128 | 256
    filters = ['G102', 'G141']

    issues = {}
    exposure_parameter_file = get_data_file("abscal.wfc3", os.path.basename(__file__))
    if exposure_parameter_file is not None:
        with open(exposure_parameter_file, 'r') as inf:
            issues = yaml.safe_load(inf)

    unique_obs = sorted(list(set(input_table['obset'])))
    
    if verbose:
        print("{}: Found {} unique obsets: {}".format(task, len(unique_obs), unique_obs))
    
    output_table = deepcopy(input_table)

    for obs in unique_obs:
        obs_mask = [r == obs for r in input_table['obset']]
        obs_table = input_table[obs_mask]
        mask = [((g == 'G102') or (g == 'G141')) for g in obs_table['filter']]
        masked_table = obs_table[mask]
        target = masked_table[0]['target']
        if len(masked_table) == 0:
            continue

        for filter in filters:
            filter_mask = [g == filter for g in masked_table['filter']]
            filter_table = masked_table[filter_mask]
            preamble = "{}: {}: {}".format(task, obs, filter)
            if len(filter_table) == 0:
                continue
            n_obs = len(filter_table)
            
            if os.path.isfile(os.path.join(out_dir, filter_table[0]['coadded'])):
                if verbose:
                    coadded_file = filter_table[0]['coadded']
                    msg = "{}: {} co-added file {} found. Skipping."
                    print(msg.format(task, obs, coadded_file))
                continue
            else:
                # Manually check for file name
                prefix = kwargs.get('prefix', target)
                if prefix is None:
                    prefix = target
                out_file_name = '{}_{}_{}.fits'.format(prefix, filter, obs)
                out_file = os.path.join(spec_dir, out_file_name)
                
                if os.path.isfile(out_file):
                    if verbose:
                        msg = "{}: {} co-added file {} found. Skipping."
                        print(msg.format(task, obs, out_file_name))
                        out_mask = (output_table['obset'] == obs) & \
                                   (output_table['filter'] == filter)
                    output_table["coadded"][out_mask] = out_file
                    continue

            if verbose:
                print("{}: Co-adding {}".format(task, obs))
                print("{}: {} table for {} is:".format(task, obs, filter))
                print(filter_table)
            st = ''

            spec_files = []
            roots = []
            spec_wave = np.array((), dtype='float64')
            spec_net = np.array((), dtype='float64')
            spec_err = np.array((), dtype='float64')
            spec_yfit = np.array((), dtype='float64')
            spec_eps = np.array((), dtype='int32')
            spec_back = np.array((), dtype='float64')
            spec_gross = np.array((), dtype='float64')
            spec_time = np.array((), dtype='float64')

            for row in filter_table:
                roots.append(row['root'])
                root_filter = output_table['root']==row['root']
                defaults = get_defaults("abscal.wfc3.reduce_grism_coadd", filter.lower())
                params = set_params(defaults, row, issues, preamble, kwargs, verbose)

                spec_file = os.path.join(row['path'], row['extracted'])
                if not os.path.isfile(spec_file):
                    # look for default extracted file
                    extracted_name = "{}_{}_x1d.fits".format(row['root'], row['target'])
                    extracted_dest = os.path.join(spec_dir, extracted_name)
                    
                    if os.path.isfile(extracted_dest):
                        spec_file = extracted_dest
                        extracted_value = os.path.join(spec_name, extracted_name)
                        output_table['extracted'][root_filter] = extracted_value
                        row['extracted'] = extracted_value
                    else:
                        msg = "{}: Unable to find extracted spectrum '{}'. Extracting."
                        print(msg.format(preamble, row['extracted']))
                        extract_table = input_table[input_table['root']==row['root']]
                        output_row = reduce(extract_table, **kwargs)
                        print("Extraction Output is:")
                        print(output_row)
                        for item in ['path', 'extracted', 'xc', 'yc', 'xerr', 'yerr']:
                            output_table[item][root_filter] = output_row[item][0]
                            row[item] = output_row[item][0]
                        spec_file = os.path.join(output_row['path'][0], 
                                                 output_row['extracted'][0])
                        if not os.path.isfile(spec_file):
                            msg = "{}: {}: ERROR: EXTRACTION FAILED. SKIPPING ROW"
                            print(msg.format(preamble, row['root']))
                            continue
                # END search for the 1d extracted spectrum.
                
                spec_files.append(spec_file)

                if row['scan_rate'] > 0:
                    pass
                    # Scanned data

#   if ckscan eq '' then begin
#       ; SCANNED DATA: Sum up all the good lines for ea spectrum
#       ; for now assume rows 500-950 are good and that bkg=0 & statistical err~0
#       img=a.scimage
#       err=a.err
#       dq=a.dq
#       ybeg=500  &  yend=950   ; good Y range of scan
#       gross=fltarr(1014)      ; re-initialize ea scan
#       tim=gross
#       timcon=tim+0.13/sxpar(h,'scan_rat') ; exptime/row
#       for iy=ybeg,yend do begin
#           mask=(dq(*,iy) and flags) eq 0  ;mask of good px
#           gross=gross+img(*,iy)*mask  ;tot good signal
#           tim=tim+timcon*mask     ;total good time
#       endfor
# ; Corr spectrum in e/s to good exp time. Assume Bkg=0
#       f(0,nout) =  gross*(yend-ybeg+1)*timcon/(tim>1)
#       e(0,nout) =  gross*0.
#       y(0,nout) =  gross*0        ; not used?
#       eps(0,nout)= gross*0
#       b(0,nout) =  gross*0
#       g(0,nout) = gross       ; NO wgt, curiously?
#       time(0,nout)=tim
#   end else begin

                else:
                    # Stare data
                    with fits.open(spec_file) as spec_fits:
                        w = spec_fits[1].data['wavelength']
                        f = spec_fits[1].data['net']
                        e = spec_fits[1].data['err']
                        y = spec_fits[1].data['y_fit']
                        eps = spec_fits[1].data['eps'].astype('int32')
                        b = spec_fits[1].data['background']
                        g = spec_fits[1].data['gross']
                        time = spec_fits[1].data['time']

                    if spec_wave.ndim == 1 and len(spec_wave) == 0:
                        spec_wave = np.append(spec_wave, w)
                        spec_net = np.append(spec_net, f)
                        spec_err = np.append(spec_err, e)
                        spec_yfit = np.append(spec_yfit, y)
                        spec_eps = np.append(spec_eps, eps)
                        spec_back = np.append(spec_back, b)
                        spec_gross = np.append(spec_gross, g)
                        spec_time = np.append(spec_time, time)
                    elif spec_wave.ndim > 1:
                        spec_wave = np.append(spec_wave, [w], axis=0)
                        spec_net = np.append(spec_net, [f], axis=0)
                        spec_err = np.append(spec_err, [e], axis=0)
                        spec_yfit = np.append(spec_yfit, [y], axis=0)
                        spec_eps = np.append(spec_eps, [eps], axis=0)
                        spec_back = np.append(spec_back, [b], axis=0)
                        spec_gross = np.append(spec_gross, [g], axis=0)
                        spec_time = np.append(spec_time, [time], axis=0)
                    else:
                        spec_wave = np.append([spec_wave], [w], axis=0)
                        spec_net = np.append([spec_net], [f], axis=0)
                        spec_err = np.append([spec_err], [e], axis=0)
                        spec_yfit = np.append([spec_yfit], [y], axis=0)
                        spec_eps = np.append([spec_eps], [eps], axis=0)
                        spec_back = np.append([spec_back], [b], axis=0)
                        spec_gross = np.append([spec_gross], [g], axis=0)
                        spec_time = np.append([spec_time], [time], axis=0)
            # end of for row in filter_table

            if len(spec_wave) == 0:
                msg = "{}: ERROR: No spectra found for {} {}"
                print(msg.format(preamble, filter, target))
                continue
            f_good = deepcopy(spec_net)
            mask = np.where((spec_eps & flags) == 0, 1, 0).astype('int32')
            for ii in range(mask.shape[0]):
                for jj in range(1, mask[ii].shape[0]):
                    if mask[ii,jj] == 0:
                        if (mask[ii,jj-1] > 0) and (mask[ii,jj+1] > 0):
                            f_good[ii,jj] = (f_good[ii,jj-1]+f_good[ii,jj+1])/2
                        elif (mask[ii,jj-1] > 0) and (mask[ii,jj+2] > 0):
                            f_good[ii,jj] = (f_good[ii,jj-1]+f_good[ii,jj+2])/2
                            f_good[ii,jj+1] = (f_good[ii,jj-1]+f_good[ii,jj+2])/2
            regbeg = [params['regbeg_m1'], params['regbeg_p1'],
                      params['regbeg_p2']]
            regend = [params['regend_m1'], params['regend_p1'],
                      params['regend_p2']]
            wbeg, wend = params['wbeg'], params['wend']
            regbeg[0] = max(min(spec_wave[:,0]), regbeg[0])
            regend[2] = min(max(spec_wave[:,-1]), regend[2])
            ireg = -1       # WL region init.

            wmrg = np.array((), dtype='float64')    # merged wave array
            gmrg = np.array((), dtype='float64')    # merged gross counts array
            bmrg = np.array((), dtype='float64')    # merged bkg array
            nmrg = np.array((), dtype='float64')    # merged net counts array
            simrg = np.array((), dtype='float64')   # merged stdev array
            stmrg = np.array((), dtype='float64')   # merged stat. err. array
            emrg = np.array((), dtype='float64')    # merged error array
            npmrg = np.array((), dtype='float64')   # merged #-good-points array
            tmrg = np.array((), dtype='float64')    # merged exptime array

            for iord in [-1, 1, 2]:
                if verbose:
                    msg = "{}: Starting Co-Add for Order {}"
                    print(msg.format(preamble, iord))
                ireg += 1
                wb = wbeg * iord
                we = wend * iord
                if iord == -1:
                    wb = -wend
                    we = -wbeg

                # Find indices of spectra covering each order at 90% level
                #   Actually 86% level?
                d10 = (we-wb)*.14 # per IDL "2018may19-.10->.14 for ibwib6m8q"
                jgood = -np.ones((mask.shape[0]), dtype='int16')
                for j in range(mask.shape[0]):
                    # j is # of spectra w/ data in region at 90% level.
                    if (np.max(spec_wave[j,:]) >= (we-d10)) and (spec_wave[j,0] <= (wb+d10)):
                        jgood[j] = j
                if np.max(jgood) < 0:
                    msg = "{}: No Good Data in wavelength range ({},{}) "
                    msg += "for order {}"
                    print(msg.format(preamble, wbeg, wend, iord))
                    continue
                igood = np.where(jgood>=0)[0]
                if verbose:
                    msg = "{}: {} spectra to cross-correlate for order={}."
                    print(msg.format(preamble, len(igood), iord))

                # find approximate offset between spectra using input wavelength scales
                # and actual offsets using cross correlation
                ngood = len(igood)
                wcor = np.zeros((ngood, len(f_good[0])), dtype='float64')
                wcor[0,:] = spec_wave[igood[0],:]
                if ngood != 1:
                    wl1 = spec_wave[igood[0],:]
                    # IDL is doing another filter, and currently we're not.
                    # The reasoning is:
                    #   - IDL
                    #       - Makes a bunch of 1014-point arrays, and then
                    #         fills in wavelength data starting from the 0th
                    #         index
                    #       - Pre-sets the arrays to -1e20, ensuring that if
                    #         there is no wavelength value to fill in the array,
                    #         that point will have a large negative value
                    #       - Filters out points with large negative values.
                    #   - Python
                    #       - Copies the wavelength arrays directly out of the
                    #         FITS file, thus ensuring that all points in the
                    #         array will have valid wavelength values.
                    #       - Does not need to filter.
                    #   IDL Code:
                    #   wl1=w(*,igood(0))           ; 1-D 1st good WL arr
                    #   good=where(wl1 gt -1e10)    ; elim -1e20 no-data flags
                    #   wl1=wl1(good)
                    net1 = f_good[igood[0],:]
                    wcent = (wb+we)/2
                    icen1 = np.searchsorted(wl1, wcent) # px of central WL
                    delam = wl1[icen1+1] - wl1[icen1]   # dispersion
                    wb = max(wb, min(wl1))
                    we = min(we, max(wl1))

                    # Cross-correlate remaining good spectra to net1 of 1st
                    #   good spectrum.
                    for i in range(1, ngood):
                        wli = spec_wave[igood[i],:]
                        # See the comment starting on line 253. Same thing here.
                        flxi = f_good[igood[i],:]
                        # Put both approx. net on same px scale
                        neti = np.interp(wl1, wli, flxi)
                        # Find px range for common wl coverage
                        wbcm, wecm = wb, we
                        if iord == 2 and filter == 'G102':
                            wbcm, wecm = 15500., 18000.
                        wbcm = max(wbcm, min(wli))
                        wecm = min(wecm, max(wli))
                        ib = np.searchsorted(wl1, wbcm)
                        ie = np.searchsorted(wl1, wecm)
                        if ib > ie:
                            raise ValueError("Wavelength range start>end.")
                        if verbose:
                            msg = "{}: Cross-correlate WL range {}-{} for "
                            msg += "order {}"
                            print(msg.format(preamble, wbcm, wecm, iord))

                        # Cross-correlate
                        # 
                        # Get data row for spectrum to cross-correlate
                        row = input_table[input_table['root']==roots[igood[i]]]
                        if 'width' not in kwargs:
                            kwargs['width'] = params['width']
                        try:
                            offset, arr = cross_correlate(net1[ib:ie+1],
                                                          neti[ib:ie+1],
                                                          row,
                                                          **kwargs)
                        except Exception as e:
                            msg = "{}: ERROR in Cross-correlation: {}"
                            print(msg.format(preamble, e))
                            # Maybe should just exclude? If so, how?
                            offset = 0
                            arr = []

                        # If more than 1000A missing from cross-correlation,
                        #   not enough coverage, so offset -> 0.
                        if (wend-wbeg) - abs((we-wb)/iord) > 1000:
                            offset = 0
                        if verbose:
                            msg = "{}: {} vs. {} shift={} for order {}"
                            f0 = os.path.basename(spec_files[igood[0]])
                            f1 = os.path.basename(spec_files[igood[i]])
                            print(msg.format(preamble, f0, f1, offset, iord))

                        if abs(offset) > 2.7 and show_plots:
                            fig = plt.figure()
                            ax = fig.add_subplot(111)
                            plot_title = '{} {} spectra {} and {} for order {} '
                            plot_title += 'with offset {}'
                            plot_title = plot_title.format(obs, filter,
                                                           igood[0]+1,
                                                           igood[i]+1,
                                                           iord, offset)
                            ax.set_title(plot_title)
                            plt.xlim(wb, we)
                            spec_label = "Spectrum {}".format(igood[0]+1)
                            ax.plot(wl1, net1, label=spec_label)
                            spec_label = "Spectrum {} with wave from {}"
                            spec_label = spec_label.format(igood[i]+1,
                                                           igood[0]+1)
                            ax.plot(wl1, neti, label=spec_label)
                            w = spec_wave[igood[i],:][0]
                            f = f_good[igood[i],:][0]
                            spec_label = "Spectrum {} with wave from {}"
                            spec_label = spec_label.format(igood[i]+1,
                                                           igood[i]+1)
                            ax.plot((w + offset*delam), f, label=spec_label)
                            ax.legend()
                            plt.show()
                            msg = "{}: offset {} found is too high, so "
                            msg += "cross-correlation offset set to zero for "
                            msg += "order={}"
                            print(msg.format(preamble, offset, iord))
                            offset = 0

                        wcor[i,:] = spec_wave[igood[i],:] + offset*delam

                        # Based on "; corners in ibwt01(uqq)"
                        if abs(offset) > 12:
                            raise ValueError("Offset > 12.")
                        if arr is None: #error in cross-correlation fn.
                            raise ValueError("Error in cross-correlation.")

                    # Output Plots
                    if show_plots:

                        rb, re = regbeg[ireg], regend[ireg]


                        # First Plot -- uncorrected wavelengths
                        wmin = max(np.min(spec_wave), rb)
                        wmax = min(np.max(spec_wave), re)
                        xrang = np.array([wmin,wmax])/1.e4
                        w = spec_wave[igood[0],:]
                        ind = np.where((w >= rb) & (w < re))
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        title = 'Uncorrected Wavelengths for {} ({}) order {}'
                        ax.set_title(title.format(obs, filter, iord))
                        plt.xlim(xrang)
                        plt.ylim(0, np.max(spec_net[igood[0],ind]))
                        w = spec_wave[igood[0],ind][0]
                        n = spec_net[igood[0],ind][0]
                        ax.plot(w/1.e4, n, label='Spectrum 1')
                        for i in range(1, ngood):
                            w = spec_wave[igood[i],:]
                            ind = np.where((w >= rb) & (w < re))
                            w = spec_wave[igood[i],ind][0]
                            n = spec_net[igood[i],ind][0]
                            ax.plot(w/1.e4, n, label='Spectrum {}'.format(i+1))
                        ax.legend()
                        plt.show()

                        # Second Plot -- corrected wavelengths
                        ind = np.where((wcor[0,:] >= rb) & (wcor[0,:] < re))
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        title = 'Corrected Wavelengths for {} ({}) order {}'
                        ax.set_title(title.format(obs, filter, iord))
                        w = wcor[0,ind][0]
                        n = spec_net[igood[0],ind][0]
                        plt.xlim(xrang)
                        plt.ylim(0, np.max(n))
                        spec_label = 'Spectrum {}'.format(igood[0]+1)
                        ax.plot(w/1.e4, n, label=spec_label)
                        for i in range(1, ngood):
                            ind = np.where((wcor[i,:] >= rb) & (wcor[i,:] < re))
                            w = wcor[i,ind]
                            n = spec_net[igood[i],ind]
                            spec_label = 'Spectrum {}'.format(igood[i]+1)
                            ax.plot(w[0]/1.e4, n[0], label=spec_label)
                        ax.legend()
                        plt.show()

                        # Third Plot -- remove bad data
                        good_mask = np.where(mask[0,:]>0)
                        bad_mask = np.where(mask[0,:]==0)
                        wl_cor = wcor[0,good_mask]
                        wl_bad = wcor[0,bad_mask]
                        fcor1 = spec_net[igood[0],good_mask]
                        fbad = spec_net[igood[0],bad_mask]
                        ind = np.where((wl_cor >= rb) & (wl_cor < re))
                        ind_bad = np.where((wl_bad >= rb) & (wl_bad < re))
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        title = 'DQ Plot for {} ({}) order {}'
                        ax.set_title(title.format(obs, filter, iord))
                        plt.xlim(xrang)
                        w, f = wl_cor[ind], fcor1[ind]
                        spec_label = 'Spectrum {}'.format(igood[0]+1)
                        ax.scatter(w/1.e4, f, s=1., marker='.', label=spec_label)
                        wb, fb = wl_bad[ind_bad], fbad[ind_bad]
                        spec_label = 'Spectrum {} bad DQ'.format(igood[0]+1)
                        ax.scatter(wb/1.e4, fb, s=1., marker='x', c='r', label='Bad DQ')
                        for i in range(1, ngood):
                            good_mask = np.where(mask[igood[i],:]>0)
                            bad_mask = np.where(mask[igood[i],:]==0)
                            wl_cor = wcor[i, good_mask]
                            wl_bad = wcor[0,bad_mask]
                            fcor1 = spec_net[igood[i],good_mask]
                            fbad = spec_net[igood[i],bad_mask]
                            ind = np.where((wl_cor >= rb) & (wl_cor < re))
                            ind_bad = np.where((wl_bad >= rb) & (wl_bad < re))
                            w, f = wl_cor[ind], fcor1[ind]
                            spec_label = 'Spectrum {}'.format(igood[i]+1)
                            ax.scatter(w/1.e4, f, s=1., marker='.', label=spec_label)
                            wb, fb = wl_bad[ind_bad], fbad[ind_bad]
                            spec_label = 'Spectrum {} bad DQ'.format(igood[i]+1)
                            ax.scatter(wb/1.e4, fb, s=1., marker='x', c='r')
                        ax.legend()
                        plt.show()

                # Coadd the ngood spectra separately for each region
                var = spec_err * spec_err
                imin = np.unravel_index(np.argmin(wcor, axis=None), wcor.shape)
                wave = wcor[imin[0],:]
                re = regend[ireg]
                if (np.max(wave) < re) and (np.max(wcor) > np.max(wave)):
                    argmax = np.argmax(wcor, axis=None)
                    imax = np.unravel_index(argmax, wcor.shape)[0]
                    ind = np.where(wcor[imax,:] > np.max(wave))
                    wave = np.append(wave, wcor[imax,ind])

                if kwargs.get('double', False):
                    wave_delta = wave[1:] - wave[:-1]
                    modal_delta = mode(wave_delta, axis=None)[0]
                    dlam = modal_delta/2
                    wave = np.append(wave, wave[:-1]+dlam)
                    wave = np.sort(wave)

                nsd = len(wave)
                fsum = np.zeros((nsd,), dtype='float64')
                ftsum = np.zeros((nsd,), dtype='float64')
                f2sum = np.zeros((nsd,), dtype='float64')
                gsum = np.zeros((nsd,), dtype='float64')
                bsum = np.zeros((nsd,), dtype='float64')
                tsum = np.zeros((nsd,), dtype='float64')
                npts = np.zeros((nsd,), dtype='float64')
                varsum = np.zeros((nsd,), dtype='float64')
                f_interp = np.zeros((ngood,nsd), dtype='float64')
                b_interp = np.zeros((ngood,nsd), dtype='float64')
                g_interp = np.zeros((ngood,nsd), dtype='float64')
                m_interp = np.zeros((ngood,nsd), dtype='float64')
                y_interp = np.zeros((ngood,nsd), dtype='float64')
                var_interp = np.zeros((ngood,nsd), dtype='float64')
                time_interp = np.zeros((ngood,nsd), dtype='float64')

                for i in range(ngood):
                    wli = wcor[i,:]
                    ig = igood[i]
                    fint = np.interp(wave, wli, spec_net[ig,:], left=0., right=0.)
                    bint = np.interp(wave, wli, spec_back[ig,:], left=0., right=0.)
                    gint = np.interp(wave, wli, spec_gross[i,:], left=0., right=0.)
                    vint = np.interp(wave, wli, var[ig,:], left=0., right=0.)
                    mint = np.interp(wave, wli, mask[ig,:], left=0., right=0.)
                    yint = np.interp(wave, wli, spec_yfit[ig,:], left=0., right=0.)
                    tint = np.interp(wave, wli, spec_time[ig,:], left=0., right=0.)

                    mint = np.where(mint>=1.,1, 0)      # Restrict mask to good (1) or bad (0)
                    fsum = fsum + mint*fint             # sum of net counts/s
                    ftsum = ftsum + mint*tint*fint      # some of net counts/s*exptime
                    gsum = gsum + mint*gint             # gross counts/s. NO WEIGHT.
                    tsum = tsum + mint*tint             # sum of exptimes
                    f2sum = f2sum + mint*(fint)**2    # sum of squares
                    varsum = varsum + mint*tint**2*vint # time-weighted variance
                    npts = npts + mint                  # sum of good points
                    f_interp[i,:] = fint    # retain individual interpolated values
                    b_interp[i,:] = bint
                    g_interp[i,:] = gint
                    m_interp[i,:] = mint
                    y_interp[i,:] = yint
                    var_interp[i,:] = vint
                    time_interp[i,:] = tint

                # Use average when all data is bad
                all_bad = np.where(npts==0)
                n_all_bad = len(all_bad[0])
                if n_all_bad > 0:
                    fbad = f_interp[:,all_bad]
                    tbad = time_interp[:,all_bad]
                    if ngood > 1:
                        fsum[all_bad] = np.sum(fbad,axis=0)
                        tsum[all_bad] = np.sum(tbad,axis=0)
                        ftsum[all_bad] = np.sum(fbad*tbad,axis=0)
                        gsum[all_bad] = np.sum(g_interp[:,all_bad], axis=0)
                        f2sum[all_bad] = np.sum(fbad*fbad,axis=0)
                        vs = var_interp[:,all_bad]*tbad[:]**2
                        varsum[all_bad] = np.sum(vs, axis=0)
                    else:
                        fsum[all_bad] = fbad
                        tsum[all_bad] = tbad
                        ftsum[all_bad] = fbad*tbad
                        gsum[all_bad] = g_interp[:,all_bad]
                        f2sum[all_bad] = fbad*fbad
                        varsum[all_bad] = var_interp[:,all_bad]*tbad**2
                    npts[all_bad] = ngood

                # Compute means on wave grid
                if ngood > 1:
                    bsum = np.sum(b_interp, axis=0)
                else:
                    bsum = b_interp
                totweight = tsum + np.where(tsum==0, 1, 0)  # Change 0 exptimes to 1
                stat_error = np.sqrt(varsum)/totweight      # propagated stat. err.
                net = ftsum/totweight                       # WEIGHTED avg
                back = bsum/ngood
                npts_gt = np.where(npts>1, npts, 1)
                gross = gsum/npts_gt    # UN-WEIGHTED avg?
                sigma = np.sqrt(f2sum/npts_gt)
                error_mean = sigma/np.sqrt(npts_gt)
                if n_all_bad > 0:
                    npts[all_bad] = 0
                # Make merged array from as many as the 3 WL regions
                good = np.where((wave >= regbeg[ireg]) & (wave < regend[ireg]))

                wmrg = np.append(wmrg, wave[good])
                gmrg = np.append(gmrg, gross[good])
                bmrg = np.append(bmrg, back[good])
                nmrg = np.append(nmrg, net[good])
                simrg = np.append(simrg, sigma[good])
                stmrg = np.append(stmrg, stat_error[good])
                emrg = np.append(emrg, error_mean[good])
                npmrg = np.append(npmrg, npts[good])
                tmrg = np.append(tmrg, tsum[good])
            # end for iord in -1,1,2

            sort = np.argsort(wmrg)
            wmrg = wmrg[sort]
            gmrg = gmrg[sort]
            bmrg = bmrg[sort]
            nmrg = nmrg[sort]
            simrg = simrg[sort]
            stmrg = stmrg[sort]
            emrg = emrg[sort]
            npmrg = npmrg[sort]
            tmrg = tmrg[sort]

            # Write Results
            prefix = kwargs.get('prefix', target)
            if prefix is None:
                prefix = target
            Path(spec_dir).mkdir(parents=True, exist_ok=True)
            out_file_name = '{}_{}_{}'.format(prefix, filter, obs)
            out_file = os.path.join(spec_dir, out_file_name)

            if show_plots:
                fig = plt.figure()
                ax = fig.add_subplot(111)
                spec_title = '{} {} ({}) Co-added Spectra'
                ax.set_title(spec_title.format(obs, target, filter))
                plt.xlabel("Wavelength (micron)")
                plt.ylabel("Count Rate (electrons/s)")
                ax.plot(wmrg/1.e4, nmrg, label='net')
                ax.plot(wmrg/1.e4, gmrg, label='gross')
                ax.legend()
                plt.show()

            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            t = Table()
            t['wave'] = wmrg
            t['gross'] = gmrg
            t['back'] = bmrg
            t['net'] = nmrg
            t['stdev'] = simrg
            t['stat_error'] = stmrg
            t['error_mean'] = emrg
            t['npts'] = npmrg
            t['exposure_time'] = tmrg
            t.meta['comments'] = []
            t.meta['comments'].append('Gross and Back columns have Flat Field applied.')
            t.meta['comments'].append('Written by prewfc/wfc_coadd at {}'.format(now))
            co_added_roots = ",".join([r for r in filter_table['root']])
            t.meta['comments'].append('Co-add list={}'.format(co_added_roots))
            t.meta['comments'].append('Target={}'.format(target))
            t.meta['comments'].append('Filter={}'.format(filter))
            t.meta['comments'].append('Observation Set={}'.format(obs))
            t.meta['comments'].append('Date={}'.format(filter_table['date'][0]))
            t.write(out_file+'.tbl', format='ascii.ipac', overwrite=True)
            t.write(out_file+'.fits', format='fits', overwrite=True)

            coadd_file_name = out_file_name+'.fits'
            coadd_file = os.path.join(spec_dir, coadd_file_name)
            coadd_col = os.path.join(spec_name, coadd_file_name)
            roots = [r for r in filter_table['root']]
            for row in output_table:
                if row['root'] in roots:
                    row['coadded'] = coadd_file
                    output_table['coadded'][output_table['root']==row['root']] = coadd_col

            if verbose:
                print("{}: Finished filter.".format(preamble))
        if verbose:
            print("{}: {}: Finished obs".format(task, obs))
    if verbose:
        print("{}: finished co-add".format(task))

    return output_table



def additional_args(**kwargs):
    """
    Additional command-line arguments. 
    
    Provides additional command-line arguments that are unique to the co-add process.
    
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

    double_help = "Subsample output wavelength vector by a factor of 2 (default {})."
    double_help = double_help.format(base_defaults['double'])
    double_args = ["-d", "--double"]
    double_kwargs = {'help': double_help, 'default': base_defaults['double'],
                     'action': 'store_true', 'dest': 'double'}
    additional_args['double'] = (double_args, double_kwargs)

    prefix_help = "Prefix for co-added spectra (default is target name)."
    prefix_args = ['--prefix']
    prefix_kwargs = {'help': prefix_help, 'default': base_defaults['prefix'],
                     'dest': 'prefix'}
    additional_args['prefix'] = (prefix_args, prefix_kwargs)

    plots_help = "Include result plots while running (default {})."
    plots_help = plots_help.format(base_defaults['plots'])
    plots_args = ["-p", "--plots"]
    plots_kwargs = {'dest': 'plots', 'action': 'store_true', 
                    'default': base_defaults['plots'], 'help': plots_help}
    additional_args['plots'] = (plots_args, plots_kwargs)

    return additional_args


def parse_args(**kwargs):
    """
    Parse command-line arguments.
    
    Gets the custom arguments from co-add and extract, and passes them to the joint 
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
    # Add in extraction args because coadd can call extraction and thus may
    #   need to supply arguments to it.
    extracted_args = extract_args()
    for key in extracted_args.keys():
        if key not in args:
            args[key] = extracted_args[key]

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


def main(**kwargs):
    """
    Run the coadd function.
    
    Runs the co-add function if called from the command line, with command-line arguments 
    added in.
    
    Parameters
    ----------
    kwargs : dict
        Dictionary of parameters to override when running.
    """
    kwargs['default_output_file'] = 'dirirstare.log'
    parsed = parse_args(**kwargs)

    for key in kwargs:
        if hasattr(parsed, key):
            setattr(parsed, key, kwargs[key])

    input_table = AbscalDataTable(table=parsed.table,
                                  duplicates='both',
                                  search_str='',
                                  search_dirs=parsed.paths)

    output_table = coadd(input_table, **vars(parsed), **kwargs)

    table_fname = parsed.out_file
    output_table.write_to_file(table_fname, parsed.compat)


if __name__ == "__main__":
    main(module_name='abscal.wfc3.reduce_grism_coadd')
