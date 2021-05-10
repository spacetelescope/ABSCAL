pro sn,warray,farray,wratio,ratio,s_to_n,nodes,wmin,wmax
;
;+
;				SN
;
; procedure to compute signal to noise
; NORMAL USE IS PRECEEDED BY RDIN,file,NSPEC,WARRAY,FARRAY,TIT and
;     followed by:           PLSTACK,WRATIO,RATIO,TIT,SN
;
; CALLING SEQUENCE:
;	sn,warray,farray,wratio,ratio,s_to_n,nodes,wmin,wmax
; INPUTS:
;	warray - wavelength array
;	farray - flux array
;	nodes - number of nodes to use in cubic spline fit or
;		if negative it gives minus the order of a polynomial.
;		The fitted curve is used as an estimate of the signal.
;		if not supplied the user will be prompted for it.
;		If nodes = 0 then no scaling.
;		If nodes = 1 then scaled by average between wmin and wmax.
; 	wmin, wmax - wavelength range to compute signal/noise
;		if not supplied user is prompted for it
;
; OUTPUTS:
;	wratio - wavelength vectors for ratio vectors
;	ratio - ratio array (raw data/signal)
;		ratio(*,i) contains the ratio for the ith
;		call where i runs from 0 to nspec-1.  the
;		value of nspec is obtained during the first
;		call.
;	s_to_n - estimated signal to noise for the region.
;		if supplied in the calling sequence, all inputs must be
;		supplied.  The routine also prints the result so that
;		you do not have to supply it if you don't wnat to.
;		s_to_n is a vector of length nspec.
;
; SIDE EFFECTS:
;	if !dump > 0 then results are plotted
;-
; HISTORY
;	MAR 14, 1991 DJL changed polynomial fit to double precision
;-----------------------------------------------------------
s=size(warray) & nspec=s(2)
;
; get wavelength range and number of nodes
;
if n_params(0) lt 8 then begin
	nodes=0
	read,'Enter number of spline nodes or minus number of '+ $
		'polynomial order',nodes
	wmin=0.0 & wmax=0.0
	read,'Enter wavelength region (Wmin,Wmax)',wmin,wmax
end
;
;
; loop on spectra
;
for ispec=0,nspec-1 do begin
	wave=warray(*,ispec)
	flux=farray(*,ispec)
;
; extract selected region
;
	good=where((wave ge wmin) and (wave le wmax))
	if !err lt 1 then begin
		print,'no points found in selected wavelength region'
		return
	end
	w=wave(good)
	f=flux(good)
;
; fit signal
;
	case 1 of
		nodes lt 0: coef=poly_fit(DOUBLE(w),DOUBLE(f),-nodes,signal)
		nodes gt 2: signal=sfit(w,f,nodes)
		nodes eq 0: signal=fltarr(n_elements(f))+1.0
		nodes eq 1: signal=total(f)/n_elements(f) + $
						fltarr(n_elements(f))
	endcase
;
; compute signal to noise
;
	rat=f/signal
	if (nodes eq 0) or (nodes eq 1) then ston=0.0 else ston=1.0/stdev(rat)
	if !dump gt 0 then begin
		set_xy,0,0,0,0
		!psym=0 & !Linetype=3
		plot,w,f
		!linetype=0
		oplot,w,signal
		st=''
		read,st
	    end else begin
		print,'Signal to Noise =',ston
	end
;
; return output arrays if nspec>0 (first call) create them
;
	if ispec eq 0 then begin
		nel=n_elements(w)*2
		wratio=fltarr(nel,nspec) ;return wavelengths on first call only
		ratio=fltarr(nel,nspec)  
		s_to_n=fltarr(nspec)	 ;signal to noise vector
	end
;
; put results in arrays
;
	s_to_n(ispec)=ston
	WRATIO(0,ISPEC)=W
	RATIO(0,ISPEC)=RAT
end
return
end
