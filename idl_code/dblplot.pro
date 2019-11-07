pro dblplot,hist,wave,abs,err,gross,back,eps,nmerge,short
;+
;  special IUE publication quality plot routine.
; 92AUG-START MODS FOR V2-XYOUTS FIXED, BUT NOT LOG OR PLOT PROBLEMS
;
; Calling sequence:
;	dblplot,hist,wave,abs,err,gross,back,eps,nmerge,short
;
; Inputs
;
;	hist - two line history (string array)
;	wave - wavelength vector
;	abs - abs. flux vector
;	err - error vector (in percent)
;	gross - gross spectrum (FN)
;	back - background spectrum (FN)
;	eps - epsilon array
;	nmerge - last point in first spectra if merged data,
;		if single spectra then set it to 0.
;	short - boolean flag set to 1 for short wavelength camera points
;
; output:
;	a wonderful plot
;
; history:
;	version 1  D. Lindler  Jul 25, 1989
;	Aug 6, 1989  added pen up for bad epsilon points and different
;		wavelength range for flux/error than used for gross/back
;-
;-------------------------------------------------------------------------------
;
	badeps=-800	;epsilon level for unplotted data points
	!fancy=2
	!ignore=-1
	!type=108
	!PSYM=0
	!linetype=0
	!noeras=1
	erase
;
; determine xscale
;
	wmin=1100
	wmax=3300
;
; find points we do not want to plot in the gross/background
;
	bad =   (eps le badeps) or $
		((short eq 1) and ((wave lt 1150) or (wave gt 1970))) or $
		((short eq 0) and ((wave lt 1925) or (wave gt 3300)))
	badpos = where(bad) & nbad=!err
;
; make additional points not to use for scaling
;
	spectral_lines = (wave lt 1240.0) or $
			 ((wave gt 2180.0) and (wave lt 2210.0))

; plot flux versus wavelength -------------------------------------------------
;
	set_viewport,0.15,0.95,0.34,0.9		;upper 70% of page
;
; determine yscale
;
	flux=alog10(abs>1.0e-25)
	good = where(not(bad or spectral_lines))
	fmax=max(flux(good))

	fmax=fix(fmax*5)/5.
	df=0.2
	fmin=fmax-2.0
	set_xy,wmin,wmax,fmin,fmax
	!xtitle=''
	!ytitle=''
	!c=0
	npts=n_elements(wave)
;
; change bad points to nulls that we do not want plotted
;
	nbad=!err
	if nbad gt 0 then flux(badpos)=1.6e38

	if nmerge gt 0 then begin		;both cameras
		null_plot,wave(0:nmerge-1),flux
		null_plot,wave(nmerge:npts-1),flux(nmerge:npts-1),1
	  end else begin			;single spectra
		null_plot,wave,flux
	end
	plots,[wmin,wmin,wmax,wmax,wmin],[fmin,fmax,fmax,fmin,fmin]
;
; plot x ticks every 100 A
;
	tick_len=(fmax-fmin)/40.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[fmin,fmin+tick_len]
		plots,[w,w],[fmax,fmax-tick_len]
	    end
		w=w+100
	endwhile
;
; plot y ticks
;
	f=df+fmin
	tick_len=(wmax-wmin)/50.0
	while f lt (fmax-0.01) do begin
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
		label=string(f,'(f5.1)')
		xyouts,wmin-(wmax-wmin)/20,f-(fmax-fmin)/75.,label
		f=f+df
	endwhile
;
; label y-axis
;
	TITLE='LOG FLUX (ERG CM!E-2!N S!E-1!N A!E-1!N)'
	xyouts,wmin-(wmax-wmin)/12,fmin+(fmax-fmin)/10.0,title,ORIENT=90
;
; print history lines
;
	xyouts,wmin,              fmax+(fmax-fmin)/10,hist(0)
	xyouts,wmin+(wmax-wmin)/5,fmax+(fmax-fmin)/20,hist(1)
;
; plot errors -----------------------------------------------------------------
;
	set_viewport,0.15,0.95,0.22,0.34	
	!mtitle=''
	fmax=80
	df=20
	set_xy,wmin,wmax,0,fmax
	!c=0
;
; plot the same points plotted for flux
;
	if nbad gt 0 then err(badpos)=1.6e38
	if nmerge gt 0 then begin		;both cameras
		null_plot,wave(0:nmerge-1),abs(err)
		null_plot,wave(nmerge:npts-1),abs(err(nmerge:npts-1)),1
	  end else begin			;single spectra
		null_plot,wave,abs(err)
	end
	plots,[wmin,wmin,wmax,wmax,wmin],[0,fmax,fmax,0,0]
;
; plot x ticks every 100 A
;
	tick_len=fmax/10.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[0,tick_len]
		plots,[w,w],[fmax,fmax-tick_len]
	    end
	    w=w+100
	endwhile
;
; label yticks
;
	f=df
	tick_len=(wmax-wmin)/60.0		
	while f lt fmax do begin
		label=strtrim(f,2)
		xyouts,wmin-tick_len*0.3-tick_len*0.7*strlen(label), $
			f-fmax/20.,label
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
		f=f+df
	endwhile
;
; label y-axis
;
	xyouts,wmin-(wmax-wmin)/13,fmax/5.5,'SIGMA',ORIENT=90
	xyouts,wmin-(wmax-wmin)/18,fmax/3.0,'(%)',ORIENT=90
;
; plot gross and background ---------------------------------------------------
;
	set_viewport,0.15,0.95,0.1,0.22	
	g=gross/1000
	b=back/1000
	ming=min(b)<0
	maxg=max(g(where((wave gt 1240.0) and (wave gt wmin) and $
			(wave lt wmax) and $
			((wave lt 2180) or (wave gt 2210)) )))
	range = maxg-ming
	case 1 of
		range lt 8    : df=1
		range lt 16   : df=2
		range lt 32   : df=4
		range lt 40   : df=5
		range lt 80   : df=10
		range lt 160   : df=20
		range lt 320   : df=40
		range lt 400   : df=50
		range lt 800   : df=100
		range lt 1600   : df=200
		range lt 3200   : df=400
		range lt 4000   : df=500
		range lt 8000   : df=1000
	endcase
;
; determine min and max for plot
;
	fmax=df
	while fmax lt maxg do fmax=fmax+df
	fmin=0
	while fmin gt ming do fmin=fmin-df
	set_xy,wmin,wmax,fmin,fmax
	!c=0
	if nmerge gt 0 then begin		;both cameras
		plot,wave(0:nmerge-1),g
		oplot,wave(nmerge:npts-1),g(nmerge:npts-1)
	  end else begin			;single spectra
		plot,wave,g
	end
	plots,[wmin,wmin,wmax,wmax,wmin],[fmin,fmax,fmax,fmin,fmin]
	!linetype=1
	if nmerge gt 0 then begin		;both cameras
		plot,wave(0:nmerge-1),b
		oplot,wave(nmerge:npts-1),b(nmerge:npts-1)
	  end else begin			;single spectra
		plot,wave,b
	end
	!linetype=0
;
; plot x ticks every 100 A
;
	tick_len=range/10.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[fmin,fmin+tick_len]
		plots,[w,w],[fmax,fmax-tick_len]
	    end
	    w=w+100
	endwhile
;
; label yticks
;
	f=fmin
	tick_len=(wmax-wmin)/100.0		
	while f lt fmax do begin
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
		f=f+df
	endwhile
	f= - (abs(long(fmin))/df + 1) /2*2*df
	tick_len=(wmax-wmin)/60.0		
	while f lt fmax do begin
	   if f gt fmin then begin
		label=strtrim(f,2)
		xyouts,wmin-tick_len*0.3-tick_len*0.7*strlen(label), $
			f-range/20.,label
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
	    endif
	    f=f+df*2
	endwhile
;
; label y-axis
;
	xyouts,wmin-(wmax-wmin)/13,fmin,'GROSS,BKG',ORIENT=90
	xyouts,wmin-(wmax-wmin)/18,fmin,'(1000 FN)',ORIENT=90
;
; label wavelengths
;
	w=200
	while w lt (wmax-1) do begin
	    if w gt (wmin+1) then xyouts,w-(wmax-wmin)/50, $
			(fmin-range/5),strtrim(w,2)
	    w=w+200
	end
	xyouts,(wmax+wmin)/2-250,(fmin-range/2),'WAVELENGTH (A)'

	!type=16
	!PSYM=0
	!linetype=0
	!noeras=0
	!mtitle=''
        set_xy
	set_viewport,0.10,0.95,0.10,0.95

return
end
