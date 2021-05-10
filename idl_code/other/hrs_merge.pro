pro hrs_merge,wave,flux,eps,err,wout,fout,epsout,errout,GROSS,NET,GROUT,NTOUT, $
		badeps=badeps,sort=sort,interp=interp
;
;+
;*NAME:
;			hrs_merge
;
;*PURPOSE:
; Merge data from an GHRS fp-split or WSCAN observations.
;
;*CALLING SEQUENCE:
;      hrs_merge,wave,flux,eps,err,wout,fout,epsout,errout,GROSS,NET,GROUT,NTOUT
;
;*INPUTS:
;	WAVE - 2 dimensional wavelength array
;	FLUX - 2 dimensional flux array
;	EPS  - 2 dimensional epsilon (data quality array).  May
;		be set to a scalar in indicate no epsilon processing
;	ERR  - 2 dimensional statistical error array.  May
;		be set to a scalar in indicate no error processing
;	GROSS - OPTIONAL 2-d GROSS COUNTRATE array FROM SPECIAL DJL/GSFC 
;		PROCESSING FOR USE W/ DJLREDUCE.PRO ONLY
;	NET   - OPTIONAL 2 dimensional NET COUNTRATE array.....
;
; OPTIONAL KEYWORD INPUTS:
;	/SORT - sort input data instead of averaging overlap regions
;	/INTERP - use linear interpolation in overlap region before
;		averaging
;	BADEPS=value - epsilon (data quality) threshold for unusable
;		data.  Data with an epsilon value greater or equal
;		to this value is not averaged.
; OUTPUTS:
;	wout - merged wavelengths
;	fout - merged flux
;	epsout - merged epsilon vector
;	errout - propagated statistical errors
;	GROUT  - MERGED GROSS COUNTRATE
;	NTOUT  - ...... NET  .........
;
; METHOD:
;
;	This routine will merge data using one of three methods.
;
;	Method 1: default
;
;	    In regions where the data overlap, points are averaged
;	    by choosing the wavelength closest to an existing wavelength
;	    in the output array.  Spectra are processed in ascending order
;	    of the first wavelength in each spectra.  Any non-overlapping
;	    portion is concatenated to the end of the output arrays.
;	    Overlapping portions are averaged with the existing data
;	    points with the closest wavelength.  If a data point has
;	    an epsilon greater then or equal to BADEPS.  It is not
;	    used in the average.
;
;	Method 2: specfied by /SORT
;	    This method retains all input data points.  The output
;	    vectors contain the input data sorted by wavelength.
;
;	Method 3: specified by /INTERP
;	    This method is simular to method 1 except that the
;	    data in the overlapping region is linearly interpolated
;	    to the wavelength scale of the previous spectra.
;	    Any interpolated value that requires the use of a bad
;	    epsilon is not included in the average.  Statistical errors
;	    are propagated through the inerpolation.  This results in
;	    the correlated errors in the output data vectors.
;
; EXAMPLES:
;	Merge wave and flux with no error or epsilon processing using
;	method 1.
;
;		HRS_MERGE,wave,flux,0,0,WOUT,FOUT
;
;	Merge data using method 3 and the bad epsilon flag set to 150.
;
;		HRS_MERGE,wave,flux,eps,err,wout,fout,epsout,errout, $
;				/interp,badeps=150
;
; HISTORY:
;	version 1  D. Lindler  Sept, 1991
;	3-FEB-1992	JKF/ACC	- on_error, return to caller (per SRH).
;	5-oct-1992	JKF/ACC	- increase range from short to longword.
;	10-Sep-1993	DJL/ACC, JKF/ACC - corrected problem when last
;				data point(s) in spectrum have a bad
;				epsilon
;	15-Nov-1995	JKF/ACC - removed bug installed on 5-oct-1992
;	97JUL3		RCB - ADDED GROSS,NET PROCESSING FOR GSFC IDL PIPELINE 
;				OUTPUT FOR USE W/ HRD AND DJLREDUCE.PRO ONLY.
;
;----------------------------------------------------------------------
;
; print some documenation if n_params eq 0
;
on_error,0
    if n_params(0) eq 0 then begin
	print, $
	'CALLING SEQUENCE: hrs_merge,wave,flux,eps,err,WOUT,FOUT,EPSOUT,ERROUT'$
			+',GROSS,NET,GROUT,NTOUT'
	print,'   optional keyword parameters:  /interp,/sort,badeps=value' 
	retall
    endif
    if n_params(0) lt 6 then begin
	print,'HRS_MERGE - requires at least 6 parameters on calling sequence'
	retall
    endif
on_error,2
;
; set defaults
;
    mtype = 'N'				   	; nearest data point
    if keyword_set(sort) then mtype = 'S'  	; sort all data
    if keyword_set(interp) then mtype = 'I'	; iterpolate
    if n_elements(badeps) eq 0 then badeps = 200
;
; determine if we are doing epsilon processing and error propagation
;
    if n_elements(eps) le 1 then eps_proc = 0 else eps_proc=1 ; epsilons
    if n_elements(err) le 1 then err_proc = 0 else err_proc=1 ; errors
;
; check input data set sizes
;
    s = size(wave) & ndim = s(0)
    if (ndim ne 1) and (ndim ne 2) then $
	message,'- invalid wavelength array supplied'
    ns = s(1) & n=n_elements(wave)
    not_ok = 0
    s = size(flux)
    if (s(1) ne ns) or (s(0) ne ndim) or (n_elements(flux) ne n) then not_ok=1

    if eps_proc then begin
       s = size(eps)
       if (s(1) ne ns) or (s(0) ne ndim) or (n_elements(eps) ne n) then not_ok=1
    end

    if err_proc then begin
       s = size(err)
       if (s(1) ne ns) or (s(0) ne ndim) or (n_elements(err) ne n) then not_ok=1
    end

    if not_ok then $
	message,'HRS_MERGE - input data array sizes are inconsistent'
;
; determine number of spectra
;
    s = size(wave) & ndim = s(0) & ns = s(1) & nspec = s(2)
    if (ndim eq 1) or (nspec eq 1) then begin	;only one spectrum
	wout = wave
	fout = flux
	GROUT=GROSS
	NTOUT=NET
	if eps_proc then epsout = eps
	if err_proc then errout = err
	return
    end
;
; merge data
;
; ----------------------- SORT ----------------------------------------
    if mtype eq 'S' then begin
	sub = sort(wave)
	wout = wave(sub)
	fout = flux(sub)
	GROUT=GROSS(SUB)
	NTOUT=NET(SUB)
	if eps_proc then epsout = eps(sub)
	if err_proc then errout = err(sub)
	return
    end

;------------------------ NEAREST/INTERP ------------------------
;
; determine wavelength range for each spectrum and order of wavelength
; vectors
;
;
; determine order of wavelengths
;
	wmins = wave(0,*)
	order = sort(wmins)
	if eps_proc then begin
		wmaxs = dblarr(nspec)
		nkeep = lonarr(nspec)
		for i=0,nspec-1 do begin	;find last good point
			good = where(eps(*,i) lt badeps,ngood)
			if ngood gt 0 then begin
				wmaxs(i) = max(wave(good,i))	;last good wave
				nkeep(i) = max(good)+1		;last good point
			end
		end
	    end else begin
		wmaxs = wave(ns-1,*)
		nkeep = replicate(ns,nspec)
	end

	wmaxs = wmaxs(order)
	nkeep = nkeep(order)
;
; find overlap points
;
	ipos = lonarr(nspec)	;starting data point not in wavelength
				;range of previous specturm
	for i = 1,nspec-1 do begin
		good = where(wave(*,order(i)) gt wmaxs(i-1),ngood)
		if ngood gt 0 then ipos(i)=good(0) else ipos(i) = ns
	endfor
;
; create output arrays
;
        nout = long(total(nkeep-ipos))
	wout = dblarr(nout)
	fout = fltarr(nout)
	GROUT=fltarr(nout)
	NTOUT=fltarr(NOUT)
	nadds = intarr(nout)
	if err_proc then sumsq = fltarr(nout)
	if eps_proc then epsout = fltarr(nout)
	iout = 0L		;current position in output array
;
; loop on spectra
;
	for ispec = 0,nspec-1 do begin
	    kspec = order(ispec)	;position of spectrum
	    kpos = ipos(ispec)		;first new wavelength position
	    nk = nkeep(ispec)		;number of points to keep
;
; insert new wavelengths into output array
;
	    if kpos lt nk then begin
		wout(iout) = wave(kpos:nk-1,kspec)
		fout(iout) = flux(kpos:nk-1,kspec)
		GROUT(iout) = GROSS(kpos:nk-1,kspec)
		NTOUT(iout) = NET(kpos:nk-1,kspec)
		nadds(iout) = replicate(1,nk-kpos)
		if eps_proc then epsout(iout) = eps(kpos:nk-1,kspec)
		if err_proc then sumsq(iout) = err(kpos:nk-1,kspec)^2
		iout = iout+nk-kpos
	    endif
;
; add in overlap region
;
	    if kpos gt 0 then begin
;
; extract overlap region
;
		NTOVER=NET(0:kpos-1,kspec)
		GROVER=GROSS(0:kpos-1,kspec)
		fover = flux(0:kpos-1,kspec)
		wover = wave(0:kpos-1,kspec)
		if eps_proc then epsover = eps(0:kpos-1,kspec)
		if err_proc then errover = err(0:kpos-1,kspec)
		kpos1 = kpos-1
;
; --------------------------- NEAREST -------------------------------------
;
		if mtype eq 'N' then begin
;
; find position of each overlap data point in the output arrays
;
		    index = lonarr(kpos)	;position in output arrays
						; for each overlap point
		    ii = 0L
		    for k=0L,kpos1 do begin				
			ww = wover(k)
			while ww gt wout(ii+1) do ii = ii+1
			if abs(ww-wout(ii)) lt abs(ww-wout(ii+1)) then $
					index(k) = ii else index(k) = ii+1
		    end
;
; find bad data in output arrays and new overlap region
; replace bad data with good data and average good data with new good data
;
		    if eps_proc then begin
		        good = epsout(index) lt badeps
		        bad = not good
		        newgood = epsover lt badeps
			replace = where(bad and newgood,nreplace)
			average = where(good and newgood,naverage)
			
;
; replace bad data points with good ones
;
		        if nreplace gt 0 then begin
			    ind = index(replace)
			    fout(ind) = fover(replace)
			    GROUT(IND)=GROVER(REPLACE)
			    NTOUT(IND)=NTOVER(REPLACE)
			    epsout(ind) = epsover(replace)
			    if err_proc then sumsq(ind) = errover(replace)^2
			end
;
; average data
;
			if naverage gt 0 then begin
			    ind = index(average)
			    fout(ind) = fout(ind) + fover(average)
			    GROUT(IND)=GROUT(IND)+GROVER(AVERAGE)
			    NTOUT(IND)=NTOUT(IND)+NTOVER(AVERAGE)
			    epsout(ind) = epsout(ind)>epsover(average)
			    nadds(ind) = nadds(ind)+1
			    if err_proc then sumsq(ind) = sumsq(ind) + $
							errover(average)^2
			endif
		      end else begin
;
; No epsilon processing
;
			fout(index) = fout(index) + fover
			GROUT(INDEX)=GROUT(INDEX)+GROVER
			NTOUT(INDEX)=NTOUT(INDEX)+NTOVER
			nadds(index) = nadds(index) + 1
			if err_proc then sumsq(index) = sumsq(index) + $
							errover^2
		    end
		end else begin
;
; -------------------------------INTERP--------------------------------------
;
; find region to correct
;
		    index = where((wout ge wover(0)) and $
				  (wout lt wover(kpos-1)),n)
		    if n gt 0 then begin
			ifirst = index(0)		;region in wout to proc.
			ilast = index(n-1)
			pointer = 0L			;pointer in wover, fover
;
;  			Fixed bug (changed iL to i)	jkf/acc 11/95
;			for iL = ifirst,ilast do begin	
;
			for i = long(ifirst),long(ilast) do begin

;
; find two data points in wover that wout(i) is between
;
			    while (pointer lt kpos1)  and $
			     (wout(i) gt wover(pointer+1)) do pointer=pointer+1 
;
; interpolate
;
			    pointer1 = pointer+1

			    if eps_proc then begin
				eps_interp = epsover(pointer)>epsover(pointer1)
				if eps_interp ge badeps then goto,skipit
				if epsout(i) ge badeps then begin ;replace it
					nadds(i) = 0
					fout(i) = 0.0
					GROUT(I)=0
					NTOUT(I)=0
					if err_proc then sumsq(i) = 0.0
					epsout(i) = eps_interp
				    end else begin		  ;average it
					epsout(i) = epsout(i) > eps_interp
				end
			    endif

			    frac1 = (wout(i) - wover(pointer))/ $
					(wover(pointer1)-wover(pointer))
			    frac2 = 1.0 - frac1
			    fout(i) = fout(i) + frac2 * fover(pointer) + $
				                frac1 * fover(pointer1)
			    GROUT(i) =GROUT(i) + frac2 *GROVER(pointer) + $
				                frac1 *GROVER(pointer1)
			    NTOUT(i) =NTOUT(i) + frac2 *NTOVER(pointer) + $
				                frac1 *NTOVER(pointer1)
			    nadds(i) = nadds(i) + 1

			    if err_proc then $
				sumsq(i) = sumsq(i) + $
					        (frac2*errover(pointer))^2 + $
						(frac1*errover(pointer1))^2
skipit:
		    end; for i
		end; if n gt 0
	    end; if mtype eq 'N'
	    end; if kpos gt 0

	end; for ispec = 0,nspec-1
	fout = fout/nadds
	GROUT=GROUT/NADDS
	NTOUT=NTOUT/NADDS
	if err_proc then errout = sqrt(sumsq)/nadds
return
end
