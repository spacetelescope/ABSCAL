pro calstis_sens,h,msens,wsens,sens,blaze_model,gwidth=gwidth
;+
;                       calstis_sens
;
; Get STIS sensitivity function corrected for extraction height (gwidth)
;
; CALLING SEQUNECE:
;       calstis_sens,h,msens,wsens,sens,gwidth=gwidth
;
; INPUT/OUTPUTS:
;       h - FITS header
;
; OUTPUTS:
;       msens - vector of spectral orders for sensitivity vectors
;       wsens - wavelengths for the sensitivity vector(s)
;       sens - sensitivity vector(s)
;	blaze_model - output structure containing the echelle blaze
;		shift model parameters
;
; OPTIONAL KEYWORD INPUT:
;       gwidth - height of the extraction slit
;               (if not supplied, it is read from the input header)
;
; HISTORY:
;       version 1  D. Lindler  Dec 18, 1997
;       Feb 12, 1998 DJL modified to work for PCTTAB=NONE.
;       Apr. 10, 1998, D. Lindler, Modified to allow order dependent
;               sensitivities
;       June 4, 1998, D. Lindler, Added Equivalent aperture determination
;               for extraction slit height correction
;	June 15, 1998, D. Lindler, added slit throughput correction for
;		both point source and extended source extraction
;	June 24, 1998 D. Lindler, Modified to use the 0.2X0.06 aperture entry
;		of the PCTTAB for the two echelle neutral density slits.
;	June 25, 1998 D. Lindler Modified to work when sensitivity table
;		has a single wavelength tabulated.
;	Sept. 4, 1998, D. Lindler, Modified to use X-disp plate scale
;		instead of disp. direction plate scale when converting
;		to surface brightness.
;	Sept 21, 1998, D. Lindler, Corrected Error (routine was ignoring
;		GWIDTH keyword parameter)
;	Sept 22, 1998 D. Lindler, Corrected to work properly for non-integer
;		gwidths
;	May 11, 1999, D. Lindler, Added ESPS keyword
;	Dec 7, 1999, Lindler, Added temperature/time correction
;	Feb 24, 2000, Lindler, Modified to work correctly when obs aperture
;		= sensitivity aperture and extended=1 and gwidth = sensitivity
;		table gwidth.
;	Dec. 2001, Lindler, added blaze shift model parameters to the output
;	2014aug14 - Use new gwidth/abscor for G750L 52X2. See 'rcb fix' below.
;		AND see stis/doc/abscor.pct for doc.
;	2014sep29 - RCB: NO gwidth corr for 7,11 for new gwidth=11 sens11
;		sensitivity for G750L, which has gwidth=11, so no change here.
;	2015Feb2  - no 2X2 aperture in abscor-140.fits, so patch to 52x2 here.
;-
;------------------------------------------------------------------------
; 
; get header information. APTTAB is modeled thruput, eq aperture3_APT.fits for
;	52X2 18 WL points ranging from .957 to .990 w/ a .006 glitch at ~1800A
;
        senstab = strtrim(sxpar(h,'senstab'))   ;sensitivity table
        pcttab = strtrim(sxpar(h,'pcttab'))     ;extract hgt correction table
        apttab = strtrim(sxpar(h,'apttab'))     ;aperture throughput table
        obs_aper = strupcase(strtrim(sxpar(h,'aperture')))
        opt_elem = strtrim(sxpar(h,'opt_elem'))
        cenwave = fix(sxpar(h,'cenwave'))
	extended = fix(sxpar(h,'extended'))
	surfaceb = fix(sxpar(h,'surfaceb'))
	if extended gt 0 then gwidth_obs = float(sxpar(h,'esgwidth')) $
			 else gwidth_obs = float(sxpar(h,'gwidth'))
        if n_elements(gwidth) ne 0 then gwidth_obs = gwidth
	if (surfaceb ne 0) then gwidth_obs = 600
	esps = fix(sxpar(h,'esps'))
	if esps then extended = 0	;treat as point source
	blaze_model = {MREF:0}
;
; is it a filtered aperture?
;
	if (strpos(obs_aper,'F25') ge 0) or $
	   (strpos(obs_aper,'F28') ge 0) or $
	   (strpos(obs_aper,'ND') ge 0) then filtered=1 else filtered=0 
;
; STEP1: ----------------------------------------------------------------------
;
; get sensitivities for APERTURE = sens_aper and extraction slit GWIDTH_SENS
;
	if strupcase(senstab) eq 'NONE' then return
        filename = list_with_path(senstab,'SCAL')
        filename = filename(0)
        if filename eq '' then begin
                print,'CALSTIS_SENS: ERROR - SENSTAB not found'
                print,'               name = '+senstab
                retall
        endif
;
;
; read sensitivity table and extract columns for correct optical element and
; central wavelength
;
        a = mrdfits(filename,1,hsens,/silent)
        opt_elems = strtrim(a.opt_elem)
        good = where(((opt_elems eq 'ANY') or (opt_elems eq opt_elem)) and $
                      ((a.cenwave eq -1) or (a.cenwave eq cenwave)),ngood)
        if ngood lt 1 then begin
                print,'CALSTIS_SENS: ERROR - no rows in senstab = '+filename
                print,'              for opt_elem '+opt_elem+' cenwave '+ $
                                        strtrim(cenwave,2)
                retall
        end

        wsens = a(good).wavelength
        sens = a(good).sensitivity
        msens = a(good).order
        gwidth_sens = sxpar(hsens,'gwidth')
        sens_aper = strupcase(strtrim(sxpar(hsens,'aperture')))
	print,'Sens file, its gwidth, gwidth_obs=',filename,		$
			gwidth_sens,gwidth_obs,' ',sens_aper
;
; get blaze shift model
;
	tags = tag_names(a)
	found = where(tags eq 'MREF',nfound)
	if nfound gt 0 then begin
		j = good(0)
		blaze_model = {mref:a(j).mref,wref:a(j).wref,yref:a(j).yref, $
				mjd:a(j).mjd,mx:a(j).mx,my:a(j).my,mt:a(j).mt}
	end
;
; convert sens and wsens to 1-D array for interpolation routines
;
        ns_sens = n_elements(sens(*,0))
        n_sens = ngood
        if n_sens gt 1 then begin
                wsens = reform(temporary(wsens),ns_sens*n_sens)
                sens = reform(temporary(sens),ns_sens*n_sens)
        endif
;       
; print history
;
	temp=replace_char(senstab,'.fits','')			;shorten
        hist = 'CALSTIS_SENS: Sensitiv read for '+sens_aper+' from '+	$
			replace_char(temp,'/Users/bohlin/','')	;shorten
	sxaddhist,hist,h
        if !dump gt 0 then print,hist
;	help,'step1',wsens,sens,senstab,pcttab,apttab,gwidth_obs,	$
;		gwidth_sens,obs_aper,sens_aper
;	print,hist		;rcb
;
; STEP2: --------------------------------------------------------------------
; convert sensitivity to 600 pixel extraction height
;
step2:			; normally skipped,except for wide gwidths, eg. 84
        if strupcase(pcttab) eq 'NONE' then goto,step3
	if (gwidth_obs eq gwidth_sens) and (obs_aper eq sens_aper) and $
	   (extended eq 0) then $
					goto,step3

        filename2 = list_with_path(pcttab,'SCAL')
        filename2 = filename2(0)
; RCB fix 2014aug14:
	if opt_elem eq 'G750L' and obs_aper eq '52X2' then begin
; BUT?? abscor..pct says the ff is obsolete. could try again?
		pcttab='abscor-g750l-2014aug.fits'
		sxaddpar,h,'pcttab',pcttab
		filename2='~/stiscal/dat/abscor-g750l-2014aug.fits'
		endif
        if filename2 eq '' then begin
                print,'CALSTIS_SENS: ERROR - PCTTAB not found'
                print,'               name = '+pcttab
                stop					; 2019mar21-was retall
        endif
        a = mrdfits(filename2,1,hpct,/silent)
	apertures = strtrim(a.aperture)

	if gwidth_sens eq 600 then goto,step4
;
; find rows corresponding to the central wavelength and sensitivity
; array aperture
;
;
        good = where(((a.cenwave eq cenwave) or (a.cenwave eq -1)) and  $
                     (strtrim(a.aperture) eq sens_aper) , ngood)
        if ngood lt 2 then begin
                hist = strarr(2)
                print,string(7b)        ;beep
                hist(0) = 'CALSTIS_SENS -- WARNING: rows missing in PCTTAB ' + $
                          'for ' + sens_aper+'  cenwave='+ strtrim(cenwave,2)
                hist(1) = '        Extraction slit photometric correction' + $
                        ' not done'
                sxaddhist,hist,h
                if !dump gt 0 then print,hist
                goto,step3
        endif
        b = a(good)
;
; sort by extraction slit heights
;
        sub = sort(b.extrheight)
        b = b(sub)
        extrheight = b.extrheight & nex = n_elements(extrheight)
;
; find correction for sensitivity aperture at an infinite extrheight
; (gwidth=600)
;
        tabinv,extrheight,600,row
        irow = long(row)
        frac = row-irow
        if frac eq 0 then begin
               tcor_sens_600 = cspline(b(irow).wavelength,b(irow).throughput, $
                                        wsens)
            end else begin
               tcor1 = cspline(b(irow).wavelength,b(irow).throughput,wsens)
               tcor2 = cspline(b(irow+1).wavelength,b(irow+1).throughput,wsens)
               tcor_sens_600 = tcor1 + frac*(tcor2-tcor1)
        end
;
; find correction row for the sensitivity array extraction gwidth
;
        tabinv,extrheight,gwidth_sens,row
        irow = long(row)
        frac = row-irow
        if frac eq 0 then begin
               tcor_sens_gwidth = cspline(b(irow).wavelength, $
                                                b(irow).throughput,wsens)
            end else begin
               tcor1 = cspline(b(irow).wavelength,b(irow).throughput,wsens)
               tcor2 = cspline(b(irow+1).wavelength,b(irow+1).throughput,wsens)
               tcor_sens_gwidth = tcor1 + frac*(tcor2-tcor1)
print,'Interpolation in calstis_sens for gwidth='+gwidth_sens+',pcttab & stop
        end

;
; correct the sensitivity array
;
	sens = sens * (tcor_sens_600/tcor_sens_gwidth)
;
; print history
;
        hist = strarr(2)
        hist(0) = '  Extraction slit GWDITH adjustment with '+pcttab
        hist(1) ='  GWIDTH (senstab) correction from '+strtrim(gwidth_sens,2) +$
                  ' to 600 for '+sens_aper+' aperture'
        if !dump gt 0 then print,hist
        sxaddhist,hist,h
	help,'step2 ',filename2,gwidth_sens,extrheight		; rcb
	print,hist  &  print,'minmax corr to 600=',		$ ; rcb
			minmax(tcor_sens_600/tcor_sens_gwidth)
;
; STEP3: ---------------------------------------------------------------------
; Correct sensitivity to an infinite aperture
;
step3:			; normally skipped as sens_aper eq obs_aper = '52X2'
	if (sens_aper eq obs_aper) and (extended eq 0) then goto,step5
	if strupcase(apttab) eq 'NONE' then goto,step6
        filename = list_with_path(apttab,'SCAL')
        filename = filename(0)
        if filename eq '' then begin
                print,'CALSTIS_ABS: ERROR - APTTAB not found'
                print,'               name = '+file
                retall
        endif
        aa = mrdfits(filename,1,/silent)
	apertures = strtrim(aa.aperture)
;
; find row for sensitivity calibration slit
;
        good = where(apertures eq sens_aper,ngood)
        if ngood eq 0 then begin
                print,'CALSTIS_ABS: ERROR aperture '+sens_aper+' not found in'
                print,'             APTTAB = '+apttab
                retall
        endif
        good = good(0)
        n = aa(good).nelem
        wt = aa(good).wavelength(0:n-1)
        t = aa(good).throughput(0:n-1)
;
; interpolate to sensitivity wavelength scale
;
	tint = interpol(t,wt,wsens)
	sens = sens/(tint>1e-6)
	bad = where(tint lt 1e-6,nbad)
	if nbad gt 0 then sens(bad) = 0
	hist = '  Sensitivity converted to 50CCD aperture'+ $
		' using '+apttab
	sxaddhist,hist,h
	if !dump gt 0 then print,hist
	help,'step3 ',hist,obs_aper,apttab		; rcb
;
; STEP4: ----------------------------------------------------------------------
; Correct sensitivity to target aperture by multiplying by combined
; point source/ filter throughput.  If non-filtered slit and
; we are doing a extended source extraction, skip this step.
;
step4:					; normally skipped -rcb
	if (extended gt 0) and (filtered eq 0) then goto,step6
	if (obs_aper eq '50CCD') then goto,step6
;
; find row for the observation's slit
;
        good = where(apertures eq obs_aper,ngood)
        if ngood eq 0 then begin
                print,'CALSTIS_ABS: ERROR aperture '+obs_aper+' not found in'
                print,'             APTTAB = '+apttab
                retall
        endif
        good = good(0)
        n = aa(good).nelem
        wt = aa(good).wavelength(0:n-1)
        t = aa(good).throughput(0:n-1)
;
; interpolate to sensitivity wavelength scale
;
	tint = interpol(t,wt,wsens)
	sens = sens*(tint>0)
	bad = where(tint lt 1e-8,nbad)
	if nbad gt 0 then sens(bad) = 0
;
; add history
;
	hist = '  Sensitivity converted to target '+obs_aper+' using '+apttab
	sxaddhist,hist,h
	if !dump gt 0 then print,hist
	help,'step4 ',hist,obs_aper,apttab,extended,filtered		; rcb
;
; STEP5: ----------------------------------------------------------------------
; If extended source extraction using a filtered slit, take out point source 
; throughput from the throughput correction in step 4.
;
step5:					; normally skipped -rcb
	if extended eq 0 then goto,step6
	if (strpos(obs_aper,'F25') ge 0) or $
	   (strpos(obs_aper,'F28') ge 0) then goto,step6
;
; determine which point source throughput to use
;
	if (obs_aper eq '0.3X0.05ND') then ps_aper = '0.3X0.06' else $
	if (obs_aper eq '0.2X0.05ND') then ps_aper = '0.2X0.06' else $
					   ps_aper = '52X0.05'
;
; find row for the observation's slit
;
        good = where(apertures eq ps_aper,ngood)
        if ngood eq 0 then begin
                print,'CALSTIS_ABS: ERROR aperture '+ps_aper+' not found in'
                print,'             APTTAB = '+apttab
                retall
        endif
        good = good(0)
        n = aa(good).nelem
        wt = aa(good).wavelength(0:n-1)
        t = aa(good).throughput(0:n-1)
;
; interpolate to sensitivity wavelength scale
;
	tint = interpol(t,wt,wsens)
	sens = sens/(tint>1e-6)
	bad = where(tint lt 1e-6,nbad)
	if nbad gt 0 then sens(bad) = 0
;
; print history
;
	hist = '  Point source throughput removed using '+apttab+' slit = '+ $
		ps_aper
	sxaddhist,hist,h
	if !dump gt 0 then print,hist
	help,'step5 ',hist,obs_aper,extended		; rcb
;
; STEP6: ---------------------------------------------------------------------
; correct sensitivity to extraction slit height of the observation slit
; 
step6:			; normally skipped, except for wide gwidths & gwidth=7
        if strupcase(pcttab) eq 'NONE' then goto,step7
	if gwidth_obs ge 600 then goto,step7
	if (gwidth_obs eq gwidth_sens) and (obs_aper eq sens_aper) and $
	   (extended eq 0) then goto,step7
	apertures = strtrim(a.aperture)
;
; If observation's aperture is not present, find alternate
;
	aperture = obs_aper
;
; find alternate aperture if obs_aper is not in the table
;
	if total(apertures eq aperture) eq 0 then begin
		if (aperture eq '6X6') or (aperture eq '25MAMA') or $
		   (aperture eq '50CCD') or $
		   (strpos(aperture,'F25') ge 0) or $
		   (strpos(aperture,'F28') ge 0) then aperture = '50CCD'
		if (strpos(aperture,'52X2') ge 0) then aperture = '52X2'
		if (strpos(aperture,'52X0.1') ge 0) then aperture = '52X0.1'
		if (strpos(aperture,'52X0.2') ge 0) then aperture = '52X0.2'
		if (strpos(aperture,'52X0.5') ge 0) then aperture = '52X0.5'
		if (strpos(aperture,'52X0.05') ge 0) then aperture = '52X0.05'
		if (strpos(aperture,'31X0.05') ge 0) then aperture = '52X0.05'
		if (strpos(aperture,'0.2X0.2') ge 0) then aperture = '0.2X0.2'
		if (strpos(aperture,'0.2X0.06') ge 0) then aperture = '0.2X0.06'
		if (strpos(aperture,'0.2X0.05') ge 0) then aperture = '0.2X0.06'
		if (strpos(aperture,'0.3X0.05') ge 0) then aperture = '0.2X0.06'
	end
	if total(apertures eq aperture) eq 0 then begin
		if (aperture eq '6X6') or (aperture eq '25MAMA') or $
		   (aperture eq '50CCD') or $
		   (strpos(aperture,'F25') ge 0) or $
		   (strpos(aperture,'F28') ge 0) then aperture = '25MAMA'
	endif
	if total(apertures eq aperture) eq 0 then begin
		if (aperture eq '6X6') or (aperture eq '25MAMA') or $
		   (aperture eq '50CCD') or $
		   (strpos(aperture,'F25') ge 0) or $
		   (strpos(aperture,'F28') ge 0) then aperture = '6X6'
	endif
	if total(apertures eq aperture) eq 0 then begin
		hist = strarr(2)
		hist(0) = 'CALSTIS_SENS: -- WARNING: observation aperture =' + $
			  obs_aper + ' not found in PCTTAB'
		hist(1) = '   Extraction GWIDTH correction not done'
		if aperture eq '2X2' then begin		; RCB patch 2015feb2
			hist(1)='Substitute 52X2 GWIDTH correction for 2X2'
			aperture='52X2'
			endif
		sxaddhist,hist,h
		if !dump gt 0 then print,hist
		if aperture ne '52X2' then goto,step7	; RCB patch 2015feb2
	endif
;
; find rows corresponding to the central wavelength and observations
; array aperture
;
;
        good = where(((a.cenwave eq cenwave) or (a.cenwave eq -1)) and  $
                     (strtrim(a.aperture) eq aperture) , ngood)
        if ngood lt 2 then begin
                hist = strarr(2)
                print,string(7b)        ;beep
                hist(0) = 'CALSTIS_SENS -- WARNING: rows missing in PCTTAB ' + $
                          'for ' + aperture +'  cenwave='+ strtrim(cenwave,2)
                hist(1) = '        Extraction slit photometric correction' + $
                        ' not done'
                sxaddhist,hist,h
                if !dump gt 0 then print,hist
                goto,step7
        endif
        b = a(good)
;
; sort by extraction slit heights
;
        sub = sort(b.extrheight)
        b = b(sub)
        extrheight = b.extrheight & nex = n_elements(extrheight)
;
; find correction for sensitivity aperture at an infinite extrheight
; (gwidth=600)
;
        tabinv,extrheight,600,row
        irow = long(row)
        frac = row-irow
        if frac eq 0 then begin
               tcor_600 = cspline(b(irow).wavelength,b(irow).throughput, $
                                        wsens)
            end else begin
               tcor1 = cspline(b(irow).wavelength,b(irow).throughput,wsens)
               tcor2 = cspline(b(irow+1).wavelength,b(irow+1).throughput,wsens)
               tcor_600 = tcor1 + frac*(tcor2-tcor1)
        end
;
; find correction row for the observations gwidth
;
        tabinv,extrheight,gwidth_obs,row
        irow = long(row)
        frac = row-irow
        if frac eq 0 then begin
               tcor_gwidth = cspline(b(irow).wavelength, $
                                                b(irow).throughput,wsens)
            end else begin
               tcor1 = cspline(b(irow).wavelength,b(irow).throughput,wsens)
               tcor2 = cspline(b(irow+1).wavelength,b(irow+1).throughput,wsens)
               tcor_gwidth = tcor1 + frac*(tcor2-tcor1)
        end
;
; correct the sensitivity array
;
	sens = sens*(tcor_gwidth/tcor_600)
;
; print history
;
        hist = '  Sensitivity GWIDTH correction to '+strtrim(gwidth_obs,2) + $
                  '  using aperture '+aperture+' correction'
        if !dump gt 0 then print,hist
        sxaddhist,hist,h
	help,'step6 ',tcor_gwidth,tcor_600		; rcb
	print,hist  &  print,'minmax corr=',minmax(tcor_gwidth/tcor_600)
	print,'minmax total mult sens corr=',				$
		minmax((tcor_gwidth/tcor_600)*tcor_sens_600/tcor_sens_gwidth)
;
; STEP 7 ----------------------------------------------------------------------
; Optional change to surface brightness
;
step7:					; normally skipped -rcb
	if (surfaceb eq 0) then goto,step8
;	
; Read Plate Scale file (SCALETAB) and get arcsec/pixel in x-disp direction
;
	scaletab = sxpar(h,'scaletab')
        filename = list_with_path(scaletab,'SCAL')
        filename = filename(0)
        if filename eq '' then begin
                print,'CALSTIS_SENS: ERROR - SCALETAB not found'
                print,'               name = '+scaletab
                retall
        endif
	a = mrdfits(filename,1,/silent)
	good = where( ((a.cenwave eq -1) or (a.cenwave eq cenwave)) and $
		      (strtrim(a.opt_elem) eq opt_elem),ngood)
	if ngood eq 0 then begin
		print,'CALSTIS_SENS: ERROR - observations opt_elem/cenwave' + $
			' not found in SCALETAB'
		retall
	endif
	axis2scale = a(good(0)).axis2scale
;
; Read aperture description table (APDTAB) to get aperture width
;
	apdtab = sxpar(h,'apdtab')
        filename = list_with_path(apdtab,'SCAL')
        filename = filename(0)
        if filename eq '' then begin
                print,'CALSTIS_SENS: ERROR - APDTAB not found'
                print,'               name = '+apdtab
                retall
        endif
	a = mrdfits(filename,1,/silent)
	good = where(strtrim(a.aperture) eq obs_aper,ngood)
	if ngood eq 0 then begin
		print,'CALSTIS_SENS: ERROR - observations opt_elem/cenwave' + $
			' not found in SCALETAB'
		retall
	endif
	if strmid(opt_elem,0,1) eq 'X' then width = a(good).width2 $
				       else width = a(good).width1
;
; Convert sensitivity to surface brightness
;	
	sens = sens*(width*axis2scale)
;
; print history
;
	hist = strarr(3)
	hist(0) = '  Sensitivity change to surface brightness units using:'
	hist(1) = '      X-Disp Plate Scale = '+strtrim(axis2scale,2) + $
	          ' arcsec/pixel'
	hist(2) = '      Aperture Width = '+strtrim(width,2)+' arcsec'
	sxaddhist,hist,h
	if !dump gt 0 then print,hist
	help,'step7 ',hist,surfaceb		; rcb
;
; STEP 8 ---------------------------------------------------------------------
; Apply time/temperature correction
;
step8:					; normally skipped -rcb
	timecorr = fix(sxpar(h,'timecorr'))
	if timecorr ne 0 then begin
		ttcorr,h,wsens,0,version=version,tcorr=tcorr,wcorr=wcorr, $
				time=time,/silent
		maxcorr = max(wcorr,min=mincorr)
	        if (maxcorr gt 1) or (mincorr lt 1) then begin
			sens = sens*wcorr
			hist = '  Sensitivity time correction ('+ $
				version +') for'+string(time,'(F8.2)')
			sxaddhist,hist,h
			print,hist
			if !dump gt 0 then print,hist
		end

		if tcorr ne 1.0 then begin
			hist = '  Sensitivity temperature correction = ' + $
				strtrim(string(tcorr,'(F10.3)'),2)+' applied'
			sxaddhist,hist,h
			if !dump gt 0 then print,hist
			sens = sens*tcorr
		end
;	help,'step8 ',mincorr,maxcorr,tcorr		; rcb
;	print,hist
	end
; 
;
; DONE: ----------------------------------------------------------------------
;
done:
;
; convert sensitivity back to a 2-D array
;
        if n_sens gt 1 then begin
                wsens = reform(temporary(wsens),ns_sens,n_sens)
                sens = reform(temporary(sens),ns_sens,n_sens)
		help,'calstis_sens END',wsens,sens
        endif
	return
end  
