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

from abscal.common.args import parse
from abscal.common.utils import get_data_file, set_params
from abscal.common.exposure_data_table import AbscalDataTable
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


def coadd(input_table, overrides={}, arg_list)):
    """
    Co-adds grism data
    """
    task = coadd
    verbose = arg_list.verbose
    
    if verbose:
        print("Starting WFC3 coadd for GRISM data.")
    
    # 32 and 512 OK "per icqv02i3q RCB 2015may26"
    flags = 4 | 8 | 16 | 64 | 128 | 256
    filters = ['G102', 'G141']
    
    known_issues = json.loads(get_data_file("abscal.wfc3", "known_issues.json"))
    input_table.adjust(known_issues['metadata'])
    issues = known_issues["reduction"]["coadd_grism"]
    
    unique_obs = unique_obsets(input_table)
    
    for obs in unique_obs:
        obs_table = input_table.filtered_copy("obset:{}".format(obs))
        mask = [((g == 'G102') or (g == 'G141')) for g in obs_table['filter']]
        masked_table = obs_table[mask]
        target = masked_table[0]['target']
        if len(masked_table) == 0:
            continue
        
        for filter in filters:
            filter_mask = [(g == filter) for g in masked_table['filter']]
            filter_table = masked_table[filter_mask]
            if len(filter_table) == 0:
                continue
            n_obs = len(filter_table)
        
            if verbose:
                print("Co-adding {}".format(obs))
                print(filter_table)
            st = ''
            
            spec_files = []
            spec_wave = np.array((), dtype='float64')
            spec_net = np.array((), dtype='float64')
            spec_err = np.array((), dtype='float64')
            spec_yfit = np.array((), dtype='float64')
            spec_eps = np.array((), dtype='float64')
            spec_back = np.array((), dtype='float64')
            spec_gross = np.array((), dtype='float64')
            spec_time = np.array((), dtype='float64')

#   ***** Planetary Nebula Thing *****
# ; ck if PN wavecal data:
# 		pnposs=findfile('spec/*'+obs(0)+'*')
# 		good=where(strpos(pnposs,'pn.fits') gt 0,npn)
# 		if npn gt 0 then star='pn'		

            for row in filter_table:
                root = row['root']
                preamble = "{}: {}: {}: {}".format(task, obs, root, filter)
            
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
                params = set_params(defaults, row, issues, overrides, verbose)

                spec_file = os.path.join(row['path'], row['extracted'])
                if not os.path.isfile(spec_file):
                    msg = "{}: Unable to find extracted spectrum {}"
                    print(msg.format(preamble, row['extracted']))
                    continue
                spec_files.append(spec_file)
            
                if row['scan_rate'] > 0:
                    # Scanned data

# 	if ckscan eq '' then begin
#       ; SCANNED DATA: Sum up all the good lines for ea spectrum
#       ; for now assume rows 500-950 are good and that bkg=0 & statistical err~0
# 		img=a.scimage
# 		err=a.err
# 		dq=a.dq
# 		ybeg=500  &  yend=950	; good Y range of scan
# 		gross=fltarr(1014)		; re-initialize ea scan
# 		tim=gross
# 		timcon=tim+0.13/sxpar(h,'scan_rat')	; exptime/row
# 		for iy=ybeg,yend do begin
# 			mask=(dq(*,iy) and flags) eq 0	;mask of good px
# 			gross=gross+img(*,iy)*mask	;tot good signal
# 			tim=tim+timcon*mask		;total good time
# 		endfor
# ; Corr spectrum in e/s to good exp time. Assume Bkg=0
# 		f(0,nout) =  gross*(yend-ybeg+1)*timcon/(tim>1)
# 		e(0,nout) =  gross*0.
# 		y(0,nout) =  gross*0		; not used?
# 		eps(0,nout)= gross*0	
# 		b(0,nout) =  gross*0
# 		g(0,nout) = gross		; NO wgt, curiously?
# 		time(0,nout)=tim
# 	end else begin

                else:
                    # Stare data
                    with fits.open(spec_file) as spec_fits:
                        w = spec_fits[1].data['wavelength']
                        f = spec_fits[1].data['net']
                        e = spec_fits[1].data['err']
                        y = spec_fits[1].data['y_fit']
                        eps = spec_fits[1].data['eps']
                        b = spec_fits[1].data['background']
                        g = spec_fits[1].data['gross']
                        time = spec_fits[1].data['time']
                
                    spec_wave = np.append(spec_wave, w, axis=0)
                    spec_net = np.append(spec_net, f, axis=0)
                    spec_err = np.append(spec_err, e, axis=0)
                    spec_yfit = np.append(spec_yfit, y, axis=0)
                    spec_eps = np.append(spec_eps, eps, axis=0)
                    spec_back = np.append(spec_back, b, axis=0)
                    spec_gross = np.append(spec_gross, g, axis=0)
                    spec_time = np.append(spec_time, time, axis=0)
        
            if len(spec_wave) == 0:
                msg = "{}: ERROR: No spectra found for {} {}"
                print(msg.format(preamble, filter, target))
                continue
            f_good = deepcopy(spec_net)
            mask = np.where(spec_eps & flags == 0, 1., 0.)
            for ii in range(mask.shape[0]):
                for jj in range(1, mask[ii].shape[0]):
                    if mask[ii,jj] == 0:
                        if (mask[ii,jj-1] > 0) and (mask[ii,jj+1] > 0):
                            f_good[ii,jj] = (f_good[ii,jj-1]+f_good[ii,jj+1])/2
                        elif (mask[ii,jj-1] > 0) and (mask[ii,jj+2] > 0):
                            f_good[ii,jj] = (f_good[ii,jj-1]+f_good[ii,jj+2])/2
                            f_good[ii,jj+1] = (f_good[ii,jj-1]+f_good[ii,jj+2])/2
            regbeg = [params['regbeg_m1'], params['regbeg_p1'], params['regbeg_p2']]
            regend = [params['regend_m1'], params['regend_p1'], params['regend_p2']]
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
		    npmrg = np.array((), dtype='float64')   # merged #-of-good-points array
		    tmrg = np.array((), dtype='float64')    # merged exptime array

            for iord in [-1, 1, 2]:
                ireg += 1
                wb = wbeg * iord
                we = wend * iord
                if iord == -1:
                    wb = -wend
                    we = -wbeg
                
                # Find indices of spectra covering each order at 90% level
                #   Actually 86% level?
                d10 = (we-wb)*.14 # per IDL "2018may19-.10->.14 for ibwib6m8q"
                jgood = -np.ones((len(mask)), dtype='int16')
                for j in range(len(mask)):
                    # j is # of spectra w/ data in region at 90% level.
                    if (max(spec_wave[j,:]) >= (we-d10)) and (spec_wave[j,0] <= (wb+d10)):
                        jgood[j] = j
                if max(jgood) < 0:
                    msg = "{}: No Good Data in wavelength range for {} {}"
                    print(msg.format(preamble, row['root'], filter))
                    continue
                igood = np.where(jgood>=0)
                if verbose:
                    msg = "{}: {} spectra to cross-correlate."
                    print(msg.format(preamble, len(igood[0])))

                # find approximate offset between spectra using input wavelength scales
                # and actual offsets using cross correlation
                ngood = len(igood[0])
                wcor = np.array((ngood, len(f_good[0])), dtype='float64')
                wcor[0,:] = spec_wave[0,igood[0][0]]
                if ngood != 1:
                    wl1 = spec_wave[igood[0][0],:]
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
                    # 	wl1=w(*,igood(0))			; 1-D 1st good WL arr
                    # 	good=where(wl1 gt -1e10)	; elim -1e20 no-data flags
                    # 	wl1=wl1(good)
                    net1 = fgood[:,igood[0][0]]
                    wcent = (wb+we)/2
                    icen1 = np.searchsorted(wl1, wcent) # px of central WL
                    delam = wl1[icen1+1] - wl1[icen1]   # dispersion
                    wb = max(wb, min(wl1))
                    we = min(we, max(wl1))
                    
                    # Cross-correlate remaining good spectra to net1 of 1st 
                    #   good spectrum.
                    for i in range(1, ngood):
                        wli = w[igood[0][i],:]
                        # See the comment starting on line 253. Same thing here.
                        flxi = fgood[igood[0][i],:]
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
                            msg = "{}: Cross-correlate WL range {}-{}"
                            print(msg.format(preamble, wbcm, wecm))
                        
                        # Cross-correlate
                        path, fname = os.path.split(spec_files[igood[0][i]])
                        fpath, specpath = os.path.split(path)
                        spec_file = os.path.join(specpath, fname)
                        spec_mask = [r['extracted'] == spec_file for r in input_table]
                        row = input_table[spec_mask]
                        overrides = {'width': params['width']}
                        offset, arr = cross_correlate(net1[ib:ie],
                                                      neti[ib:ie],
                                                      row,
                                                      overrides=overrides)
                        
                        # If more than 1000A missing from cross-correlation,
                        #   not enough coverage, so offset -> 0.
                        if (wend-wbeg) - abs((we-wb)/iord) > 1000:
                            offset = 0
                        if verbose:
                            msg = "{}: {} vs. {} shift={}"
                            f0 = spec_files[igood[0][0]]
                            f1 = spec_files[igood[0][i]]
                            print(msg.format(preamble, f0, f1, offset))
                        
                        if (abs(offset) > 2.7 or root == 'xxxxxx') and interactive:
                            fig = plt.figure()
                            ax = fig.add_subplot(111)
                            ax.set_title('Spectra 0 and {}'.format(igood[0][i]))
                            ax.xlim(wb, we)
                            ax.plot(wl1, net1)
                            ax.plot(wl1, neti)
                            ax.plot(wave[igood[0][i],:]+offset*delam, f_good[igood[0][i],:])
                            plt.show()
                            print("Offset {}=cross-correlation offset set to 0".format(offset))
                            offset = 0

                        wcor[i,:] = w[igood[i],:]+offset*delam
                        
                        # Based on "; corners in ibwt01(uqq)"
                        if abs(offset) > 12:
                            raise ValueError("Offset > 12.")
                        if arr is None: #error in cross-correlation fn.
                            raise ValueError("Error in cross-correlation.")
                    
                    # Output Plots
                    if interactive:
                        
                        # First Plot -- uncorrected wavelengths
                        wmin = max(min(wave), regbeg[ireg])
                        wmax = min(max(wave), regend[ireg])
                        xrang = [wmin,wmax]/1.e4
                        ind = np.where((wave[igood[0][0],:] >= regbeg[ireg]) and (wave[igood[0][0],:] < regend[ireg]))                        
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        ax.set_title('Uncorrected Wavelengths for {}{}'.format(obs, filter))
                        ax.xlim(xrang)
                        ax.ylim(0, max(f[igood[0][0],ind]))
                        ax.plot(wave[igood[0][0],ind]/1.e4, spec_net[igood[0][0],ind])
                        for i in range(1, ngood):
                            ind = np.where((wave[igood[0][i],:] >= regbeg[ireg]) and (wave[igood[0][i],:] < regend[ireg]))                        
                            ax.plot(wave[igood[0][i],ind]/1.e4, spec_net[igood[0][i],ind])
                        plt.show()

                        # Second Plot -- corrected wavelengths
                        ind = np.where((wcor[0,:] >= regbeg[ireg]) and (wcor[0,:] < regend[ireg]))                        
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        ax.set_title('Corrected Wavelengths for {}{}'.format(obs, filter))
                        ax.xlim(xrang)
                        ax.ylim(0, max(f[igood[0][0],ind]))
                        ax.plot(wcor[0,ind]/1.e4, spec_net[igood[0][0],ind])
                        for i in range(1, ngood):
                            ind = np.where((wcor[i,:] >= regbeg[ireg]) and (wcor[i,:] < regend[ireg]))                        
                            ax.plot(wcor[i,ind]/1.e4, spec_net[igood[0][i],ind])
                        plt.show()

                        # Third Plot -- remove bad data
                        fcor1 = net + np.where(mask==0, 9e9, 0)
                        ind = np.where((wcor[0,:] >= regbeg[ireg]) and (wcor[0,:] < regend[ireg]))                        
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        ax.set_title('Bad DQ Removed for {}{}'.format(obs, filter))
                        ax.xlim(xrang)
                        ax.ylim(0, 1e9)
                        ax.plot(wcor[0,ind]/1.e4, fcor1[igood[0][0],ind])
                        for i in range(1, ngood):
                            ind = np.where((wcor[i,:] >= regbeg[ireg]) and (wcor[i,:] < regend[ireg]))                        
                            ax.plot(wcor[i,ind]/1.e4, fcor[igood[0][i],ind])
                        plt.show()
                
                # Coadd the ngood spectra separately for each region
                var = spec_err * spec_err
                imin = wcor[np.where(wcor[:,0] == np.min(wcor))][0]
                final_wave = wcor[imin,:]
                if (np.max(final_wave) < regend[ireg]) and (np.max(wcor) > np.max(final_wave)):
                    imax = wcor[np.where(wcor[:,-1] == np.max(wcor))][0]
                    ind = np.where(wcor[imax,:] > np.max(final_wave))
                    final_wave = [final_wave, wcor[imax,ind]]
                
                if arg_list.double:
                    wave_delta = final_wave[1:] - final_wave[:-1]
                    dlam = np.mode(wave_delta)/2
                    final_wave = [final_wave, final_wave[:-1]+dlam]
                    final_wave = np.sort(final_wave)
                
                nsd = len(final_wave)
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
                    fint = np.interp(final_wave, wli, spec_net[igood[0][i],:], left=0., right=0.)
                    bint = np.interp(final_wave, wli, spec_back[igood[0][i],:], left=0., right=0.)
                    gint = np.interp(final_wave, wli, spec_gross[igood[0][i],:], left=0., right=0.)
                    vint = np.interp(final_wave, wli, var[igood[0][i],:], left=0., right=0.)
                    mint = np.interp(final_wave, wli, mask[igood[0][i],:], left=0., right=0.)
                    yint = np.interp(final_wave, wli, spec_yfit[igood[0][i],:], left=0., right=0.)
                    tint = np.interp(final_wave, wli, spec_time[igood[0][i],:], left=0., right=0.)
                    
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
                    fbad = f_interp[all_bad]
                    tbad = time_interp[all_bad]
                    if ngood > 1:
                        fsum[all_bad] = np.sum(fbad,axis=0)
                        tsum[all_bad] = np.sum(tbad,axis=0)
                        ftsum[all_bad] = np.sum(fbad*tbad,axis=0)
                        gsum[all_bad] = g_interp[:,all_bad]
                        f2sum[all_bad] = np.sum(fbad*fbad,axis=0)
                        varsum[all_bad] = var_interp[:,all_bad]*tbad**2
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
                good = np.where((final_wave >= regbeg[ireg]) & (final_wave < regend[ireg]))
                
                wmrg = np.append(wmrg, final_wave[good])
                gmrg = np.append(gmrg, gross[good])
                bmrg = np.append(bmrg, back[good])
                nmrg = np.append(nmrg, net[good])
                simrg = np.append(simrg, sigma[good])
                stmrg = np.append(stmrg, stat_error[good])
                emrg = np.append(emrg, error_mean[good])
                npmrg = np.append(npmrg, npts[good])
                tmrg = np.append(tmrg, tsum[good])
                
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
            os.makedirs(spec_dir)
            out_file_name = '{}_{}_{}'.format(prefix, filter, obs)
            out_file = os.path.join(spec_dir, out_file_name)
                
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
            comments = []
            comments.append('Gross and Back columns have Flat Field applied.')
            comments.append('Written by prewfc/wfc_coadd at {}'.format(now))
            comments.append('Co-add list={}'.format(filter_table['root']))
            comments.append('Target={}'.format(target))
            comments.append('Filter={}'.format(filter))
            comments.append('Observation Set={}'.format(obs))
            comments.append('Date={}'.format(filter_table['date'][0]))
            t.meta['comments'] = comments
            t.write(out_file+'.tbl', format='ascii.ipac')
            t.write(out_file+'.fits', format='fits')
            
            for row in filter_table
                row['coadded'] = os.path.join(arg_list.spec_dir, out_file_name+'.fits')
    
    return input_table
        

def parse_args():
    """
    Parse command-line arguments.
    """
    description_str = 'Process files from metadata table.'
    default_output_file = 'dirirstare.log'
    
    table_help = "The input metadata table to use."
    table_args = ['table']
    table_kwargs = {'help': table_help}
    
    double_help = "Subsample output wavelength vector by a factor of 2."
    double_args = ["-d", "--double"]
    double_kwargs = {'help': double_help, 'default': False, 
                     'action': 'store_true', 'dest': 'double'}
    
    prefix_help = "Prefix for co-added spectra"
    prefix_args = ['-f', '--prefix']
    prefix_kwargs = {'help': prefix_help, 'default': None,
                     'dest': 'prefix'}
    
    additional_args = [(table_args, table_kwargs),
                       (double_args, double_kwargs),
                       (prefix_args, prefix_kwargs)]
    
    res = parse(description_str, default_output_file, additional_args)
    
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
                                  duplicates=parsed.duplicates,
                                  search_str='',
                                  search_dirs=parsed.paths,
                                  idl=parsed.compat)

    output_table = coadd(input_table, overrides, parsed)
    
    table_fname = res.out_file
    output_table.write_to_file(table_fname, res.compat)


if __name__ == "__main__":
    main()
