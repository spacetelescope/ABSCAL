pro sglplot,h,wave,absflux,err,gross,back,eps,TITLE,SCALE,merged,SCLMIN
;+
;  special QSO publication quality plot routine.
;
; Calling sequence:
;	sglplot,h,wave,absflux,err,gross,back,eps,title
;
; Inputs
;
;	h - header array
;	wave - wavelength vector
;	absflux - absflux. flux vector
;	err - error vector (in percent)
;	gross - gross spectrum (FN)
;	back - background spectrum (FN)
;	eps - epsilons
;	TITLE-ADDED 90JAN4-RCB If supplied, the title will be used as the 
;		ytitle of the main plot. Otherwise the routine will construct 
;		the title. If title contains 'LOG', a log flux plot results.
;		
;	SCALE-ADDED 90JAN4-RCB IF SUPPLIED AND GT 0, THEN THAT IS THE MAX FLUX.
;	merged - use 1100 to 3300 wavelength range regardless of range
;		of input wavelengths if MERGED ne 0
; 96MAR6: ADD a sclmin parameter to get more range for cool stars
; output:
;	a wonderful plot
;
; history:
;	version 1  D. Lindler  Jun 29, 1989
;	version 2  D. Lindler  Oct 11, 1989
;       D. Lindler  Dec 21, 1989  Added pen lifting for bad data points
;	RCB-ADDED TITLE TO CALLING SEQUENCE, WHICH WILL ALSO BE USED AS A 
;		FLAG BY SGLPLOT TO DO THE LOG SCALING.
;	DJL Jan 5, 1989  Added Log plot capability
;	90JUL15-BLOW UP ERROR PLOT SCALE IF AVG ERROR IS LT 18%
; 91JAN4-START CONVERSION TO V2 BY ; ALL !DEVICE AND DROP LAST ARG ON XYOUTS-RCB
;       -PROB WE WANT TO START THE CONV OVER, AS I DELETED A LOT OF XYOUTS ARGS.
; 93jul14-a title supplied is the ytitle used... regardless!
; 99jun28- overplot saturated flux as dotted line
;-
;-------------------------------------------------------------------------------
	!p.thick=0
	!x.thick=0
	!y.thick=0
	!p.charthick=0
;
; determine if it is a log plot
;
	if n_params(0) lt 8 then title = ''
	if n_params(0) lt 11 then sclmin=0
	if strpos(strupcase(title),'LOG') ge 0 then log_plot = 1 $
					       else log_plot = 0
;
; set plot defaults
;
	!type=108
	!PSYM=0
	!linetype=0
	!noeras=1
	erase
;
; find bad data points
;
	bad = where((eps le -900)OR (WAVE LT 1150)) & nbad= !err
;
; Extract target name from the header unless a dummy h is supplied with
; less or equal to 2 elements(strings).  Otherwise !mtitle must be supplied
; by calling program.
;
	if n_elements(h) gt 2 then begin
		n=0
		while strmid(h(n),0,7) ne 'HISTORY' do n=n+1
		!mtitle=strtrim(strmid(h(n),64,12),2)
	end
;
; determine xscale
;
	wmax = 2000
	wmin = 1950
	if (merged) or (min(wave) lt 1500) then wmin=1100
	if (merged) or (max(wave) gt 2500) then wmax=3300
  
;
; plot flux versus wavelength -------------------------------------------------
;
	set_viewport,0.15,0.91,0.34,0.9		;upper 70% of page
;
; determine yscale
; 
	if log_plot then flux = alog10(absflux>1.0e-25) else flux = absflux
        fmax=max(flux(where((wave gt 1160) and (wave gt wmin) and $
                        ((wave lt 1200) or (wave gt 1230.0)) and $
                        (wave lt (wmax<3200)) and $
                        ((wave lt 2180) or (wave gt 2210)) and $
                        (eps gt -900) )))
	IF (SCALE GT 0) THEN FMAX=SCALE*.9999	;for linear
	IF (scale lt -1) THEN FMAX=SCALE	;for log
	if log_plot eq 0 then begin 	; normalize linear flux vector
	    Fnorm=0
	    while fmax lt 3 do begin
		Fnorm=Fnorm-1
		fmax=fmax*10
		flux=flux*10
	    endwhile
	end
;
; determine spacing between ticks (df) and labeled ticks (dfl)
;
	if log_plot then  begin
		fmax = fix(fmax*5)/5.0
		fmin = fmax-1.4
		if merged then fmin = fmax-2.2
		if sclmin ne 0 then fmin=sclmin
		df = 0.2
		dfl = 0.2

	   end else begin

		major=[1,  2, 5, 10]
		minor=[0.2, 0.5, 1.0, 2.0]
		for i=0,n_elements(major)-1 do begin
		    if (((fmax/major(i)) le 5.0) and ((fmax/major(i)) gt 2.0)) $
                                                  then begin
			df = minor(i)
			dfl = major(i)
			goto,found_ticks
		    endif
 		end
		stop		;logic error
found_ticks:
		fmax = (fix(fmax/df)+1)*df
	        fmin = -fmax*0.12		;12% neg. allowed
	end
;
; set plot scale for flux plot
;
	set_xy,wmin,wmax,fmin,fmax
	!xtitle=''
 	!ytitle=''
	bflux=flux
	if nbad gt 0 then bflux(bad)=1.6e38
	null_plot,wave,bflux
	oplot,wave,flux,lines=1			; plot everything as dotted line
;	PLOTDATE,'SGLPLOT'
	plots,[wmin,wmin,wmax,wmax,wmin],[fmin,fmax,fmax,fmin,fmin],thick=3
	if log_plot eq 0 then plots,[wmin,wmax],[0,0]
;
; plot x ticks every 100 A
;
	tick_len=(fmax-fmin)/40.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[fmax,fmax-tick_len],thick=2
	    endif
		w=w+100
	endwhile
;
; plot y ticks
;
	if log_plot then f = fmin+df else f=df
	tick_len=(wmax-wmin)/100.0		
	while f lt fmax do begin
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
		f=f+df
	endwhile
;
; label yticks
;
	if log_plot then f = fmin+df else f=0
	tick_len=(wmax-wmin)/60.0		

	while f lt fmax do begin
		if log_plot then begin
			label = string(f,'(f5.1)')
			xyouts,wmin-(wmax-wmin)/20,f-(fmax-fmin)/75.,label
		   end else begin
			label=strtrim(f,2)
			xyouts,wmin-tick_len*0.3-tick_len*0.7*strlen(label), $
			f-fmax/65.,label
		end

		plots,[wmin,wmin+tick_len],[f,f],thick=3
		plots,[wmax,wmax-tick_len],[f,f],thick=3
		f=f+dfl
	endwhile
;
; label y-axis
;
	IF (log_plot eq 0) THEN $
   	  TITLE=title+'(10!E'+STRTRIM(FNORM,2)+'!NERG CM!E-2!N S!E-1!N A!E-1!N)'
	if strpos(strupcase(title),'INTENS') ge 0 then begin
		len=strlen(title)
		title=strmid(title,0,len-1)+' SR!E-1!N)'
		endif
	xyouts,wmin-(wmax-wmin)/12,fmin+(fmax-fmin)/10.0,title,ORIENTATION=90.,$
		CHARSIZE=1.25
;
; plot errors -----------------------------------------------------------------
;
	set_viewport,0.15,0.91,0.22,0.34	
	!mtitle=''
	fmax=80
	IF AVG(ABS(ERR)) LT 18 THEN FMAX=20
	df=FIX(FMAX/4.+.5)
	set_xy,wmin,wmax,0,fmax
	bad = where((eps le -900)OR (WAVE LT 1150)) & nbad= !err
	if nbad gt 0 then err(bad)=1.6e38
	null_plot,wave,abs(err<FMAX)
	plots,[wmin,wmin,wmax,wmax,wmin],[0,fmax,fmax,0,0],thick=3
;
; plot x ticks every 100 A
;
	tick_len=fmax/10.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[0,tick_len],thick=2
		plots,[w,w],[fmax,fmax-tick_len],thick=2
	    endif
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
		plots,[wmin,wmin+tick_len],[f,f],thick=3
		plots,[wmax,wmax-tick_len],[f,f],thick=3
		f=f+df
	endwhile
;
; label y-axis
;
	xyouts,wmin-(wmax-wmin)/13,fmax/5.5,'SIGMA',ORIENTATION=90.,size=0.9
	xyouts,wmin-(wmax-wmin)/18,fmax/3.0,'(%)',ORIENTATION=90.,size=0.9
;
; plot gross and background ---------------------------------------------------
;
	set_viewport,0.15,0.91,0.1,0.22	
	g=gross/1000
	b=back/1000
	ming = min(b(where((wave gt 1240.0) and (wave gt wmin) and $
			(wave lt wmax) and $
			((wave lt 2180) or (wave gt 2210)) )))<0
	maxg=max(g(where((wave gt 1240.0) and (wave gt wmin) and $
			(wave lt wmax) and $
			((wave lt 2180) or (wave gt 2210)) )))
	range = maxg - ming
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
		range gt 8000   : df=2000
	endcase
;
; determine min and max for plot
;
	df=long(df)		;94dec30-rcb fix
	fmax=df
	while fmax lt maxg do fmax=fmax+df
	fmin = 0
	while fmin gt ming do fmin=fmin-df

	set_xy,wmin,wmax,fmin,fmax
	plot,wave,g
	plots,[wmin,wmin,wmax,wmax,wmin],[fmin,fmax,fmax,fmin,fmin],thick=3
	!linetype=1
	oplot,wave,b
	!linetype=0
;
; plot x ticks every 100 A
;
	tick_len=range/10.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[fmin,fmin+tick_len],thick=2
		plots,[w,w],[fmax,fmax-tick_len],thick=2
	    endif
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

	f=-( abs(long(fmin)) / df + 1)/ 2 * df*2
	tick_len=(wmax-wmin)/60.0		
	while f lt fmax do begin
	    if f gt fmin then begin
		label=strtrim(f,2)
		xyouts,wmin-tick_len*0.3-tick_len*0.7*strlen(label), $
			f-range/20.,label
		plots,[wmin,wmin+tick_len],[f,f],thick=3
		plots,[wmax,wmax-tick_len],[f,f],thick=3
	   endif
	   f=f+df*2
	endwhile
;
; label y-axis
;
	xyouts,wmin-(wmax-wmin)/13,fmin,'GROSS,BKG',ORIENTATION=90.,size=0.9
	xyouts,wmin-(wmax-wmin)/18,fmin,'(1000 FN)',ORIENTATION=90.,size=0.9
;
; label wavelengths
;
	w=200
	while w lt (wmax-1) do begin
	    if w gt (wmin+1) then xyouts,w-(wmax-wmin)/50, $
			(fmin-range/5.),strtrim(w,2)
	    w=w+200
	end
	xyouts,(wmax+wmin)/2-100,(fmin-range/2.),'WAVELENGTH (A)'
return
end
