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

__all__ = ['coadd']

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
from scipy.stats import mode

from abscal.common.args import parse
from abscal.common.utils import get_data_file, set_params
from abscal.common.exposure_data_table import AbscalDataTable
from abscal.wfc3.reduce_grism_extract import reduce
from abscal.wfc3.reduce_grism_extract import additional_args as extract_args
from abscal.wfc3.util_grism_cross_correlate import cross_correlate


def unique_obsets(table):
    """
    Take an ExposureTable, get its 'root' column, get the first six characters
    of that column, and return a set of all obsets (program/visit).

    Parameters
    ----------
    table : abscal.common.exposure_data_table.AbscalDataTable
        The table to be checked.

    Returns
    -------
    obsets : list of str
        unique obsets.
    """
    unique_roots = set(table['obset'])
    return list(unique_roots)


def coadd(input_table, arg_list, overrides={}):
    """
    Co-adds grism data
    """
    task = "coadd"
    verbose = arg_list.verbose
    interactive = arg_list.trace

    if verbose:
        print("{}: Starting WFC3 coadd for GRISM data.".format(task))
        print("{}: Input table is:".format(task))
        print(input_table)

    # 32 and 512 OK "per icqv02i3q RCB 2015may26"
    flags = 4 | 8 | 16 | 64 | 128 | 256
    filters = ['G102', 'G141']

    known_issues_file = get_data_file("abscal.wfc3", "known_issues.json")
    with open(known_issues_file, 'r') as inf:
        known_issues = json.load(inf)
    input_table.adjust(known_issues['metadata'])
    issues = []
    if "coadd_grism" in known_issues:
        issues = known_issues["coadd_grism"]

    unique_obs = unique_obsets(input_table)

    extract = False
    out_dir, out_table = os.path.split(arg_list.out_file)
    if out_dir == '':
        out_dir = os.getcwd()
    for row in input_table:
        ext_fname = row['extracted']
        if isinstance(ext_fname, np.ma.core.MaskedConstant) and ext_fname is np.ma.masked:
            extract = True
        else:
            ext_file = os.path.join(out_dir, ext_fname)
            if not os.path.isfile(ext_file):
                extract = True
    if extract:
        if verbose:
            print("{}: Extracting missing spectra.".format(task))
        input_table = reduce(input_table, overrides, arg_list)
        if verbose:
            print("{}: Finished extraction.".format(task))

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
                defaults = {
                    'wbeg': 0.,         # start of valid wavelengths
                    'wend': 0.,         # end of valid wavelengths
                    'regbeg_m1': 0.,    # -1st order wavelength start
                    'regbeg_p1': 0.,    # 1st order wavelength start
                    'regbeg_p2': 0.,    # 2nd order wavelength start
                    'regend_m1': 0.,    # -1st order wavelength end
                    'regend_p1': 0.,    # 1st order wavelength end
                    'regend_p2': 0.,    # 2nd order wavelength end
                    'width': 22.        # cross-correlation width
                    }
                if filter == 'G102':
                    defaults['wbeg'] = 7500.
                    defaults['wend'] = 11800.
                    defaults['regbeg_m1'] = -13500.
                    defaults['regbeg_p1'] = -3800.
                    defaults['regbeg_p2'] = 13500.
                    defaults['regend_m1'] = -3800.
                    defaults['regend_p1'] = 13500.
                    defaults['regend_p2'] = 27000.
                elif filter == 'G141':
                    defaults['wbeg'] = 10000.
                    defaults['wend'] = 17500.
                    defaults['regbeg_m1'] = -19000.
                    defaults['regbeg_p1'] = -5100.
                    defaults['regbeg_p2'] = 19000.
                    defaults['regend_m1'] = -5100.
                    defaults['regend_p1'] = 19000.
                    defaults['regend_p2'] = 38000.
                params = set_params(defaults, row, issues, preamble, overrides,
                                    verbose)

                spec_file = os.path.join(row['path'], row['extracted'])
                if not os.path.isfile(spec_file):
                    msg = "{}: Unable to find extracted spectrum {}"
                    print(msg.format(preamble, row['extracted']))
                    continue
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
                        path, fname = os.path.split(spec_files[igood[i]])
                        fpath, specpath = os.path.split(path)
                        spec_file = os.path.join(specpath, fname)
                        spec_mask = [r['extracted'] == spec_file for r in input_table]
                        spec_mask = np.ma.masked_array(spec_mask).astype(np.bool_)
                        row = input_table[spec_mask.filled(fill_value=False)]
                        overrides = {'width': params['width']}
                        try:
                            offset, arr = cross_correlate(net1[ib:ie+1],
                                                          neti[ib:ie+1],
                                                          row,
                                                          arg_list,
                                                          overrides=overrides)
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

                        if abs(offset) > 2.7 and interactive:
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
                    if interactive:

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
                        fcor1 = spec_net + np.where(mask==0, 9e9, 0)
                        ind = np.where((wcor[0,:] >= rb) & (wcor[0,:] < re))
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        title = 'Bad DQ for {} ({}) order {}'
                        ax.set_title(title.format(obs, filter, iord))
                        plt.xlim(xrang)
                        plt.ylim(0, 1e9)
                        w, f = wcor[0,ind][0], fcor1[igood[0],ind][0]
                        spec_label = 'Spectrum {}'.format(igood[0]+1)
                        ax.plot(w/1.e4, f, label=spec_label)
                        for i in range(1, ngood):
                            ind = np.where((wcor[i,:] >= rb) & (wcor[i,:] < re))
                            w, f = wcor[i,ind][0], fcor1[igood[i],ind][0]
                            spec_label = 'Spectrum {}'.format(igood[i]+1)
                            ax.plot(w/1.e4, f, label=spec_label)
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

                if arg_list.double:
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
            prefix = arg_list.prefix
            if arg_list.prefix is None:
                prefix = target
            out_dir, out_table = os.path.split(arg_list.out_file)
            if out_dir == '':
                out_dir = os.getcwd()
            spec_dir = os.path.join(out_dir, arg_list.spec_dir)
            Path(spec_dir).mkdir(parents=True, exist_ok=True)
            out_file_name = '{}_{}_{}'.format(prefix, filter, obs)
            out_file = os.path.join(spec_dir, out_file_name)

            if interactive:
                fig = plt.figure()
                ax = fig.add_subplot(111)
                spec_title = '{} {} ({}) Merged Spectra'
                ax.set_title(spec_title.format(obs, target, filter))
                plt.xlabel("Wavelength (micron)")
                plt.ylabel("Flux")
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

            coadd_file = os.path.join(arg_list.spec_dir, out_file_name+'.fits')
            roots = [r for r in filter_table['root']]
            for row in input_table:
                if row['root'] in roots:
                    row['coadded'] = coadd_file

            if verbose:
                print("{}: Finished filter.".format(preamble))
        if verbose:
            print("{}: {}: Finished obs".format(task, obs))
    if verbose:
        print("{}: finished co-add".format(task))

    return input_table



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
    default_output_file = 'dirirstare.log'

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


def main(overrides={}):
    parsed = parse_args()

    for key in overrides:
        if hasattr(parsed, key):
            setattr(parsed, key, overrides[key])

    input_table = AbscalDataTable(table=parsed.table,
                                  duplicates='both',
                                  search_str='',
                                  search_dirs=parsed.paths,
                                  idl=parsed.compat)

    output_table = coadd(input_table, parsed, overrides)

    table_fname = parsed.out_file
    output_table.write_to_file(table_fname, parsed.compat)


if __name__ == "__main__":
    main()
