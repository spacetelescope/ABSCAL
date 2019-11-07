pro galplot,H,wave,abs,eps,err,gross,back,ze,za,em,emm_titles,emm_off, $
		absorp,abs_titles,abs_off, $
		det_abs,det_num,ARTIF,FMX,merged
;+
;  special GAL publication quality plot routine.
;
; Calling sequence:
; 	galplot,'HEADER NEEDS WORK',wave,abs,eps,err,gross,back,ze,za,em,emm_titles,
;			absorp,abs_titles,det_abs,det_num,ARTIF,FMX,merged
;	
;
; Inputs
;
;	h - header array
;	wave - wavelength vector
;	abs - abs. flux vector
;	eps - epsilon vector
;	err - error vector (in percent)
;	gross - gross spectrum (FN)
;	back - background spectrum (FN)
;	ze - z value for emision lines
;	za - vector of z values for absorption lines
;	emm - vector of emmission line wavelengths
;	emm_titles - names of the lines
;	absorp - vector of absoption line wavelengths
;	abs_titles - names of the abs. lines
;	det_abs - wavelengths of detected lines
;	det_num - vector of numbers of detected lines
;	ARTIF   - ARTIFACT LIST
;	FMX    - IF NE -1. THEN USE FOR SCALE FACTOR 90APR14-RCB
;	merged - if not zero, use full wavelength range (1100-3200)
; 91DEC30-CHANGE FROM 3300 TO 3200 FOR WL RANGE
;		regardless of input data range
; output:
;	a wonderful plot
;
; history:
;	version 1  D. Lindler  Jun 29, 1989
;	version 2  D. Lindler  Oct 11, 1989
;	Jan 22, 1990 DJL  added pen lifting for eps le -1600 and
;		wavelengths AROUND LYMAN-ALPHA.  modified major/minor
;		tick positions. added EPS to calling sequence
; 91JAN28-START CONVERSION TO V2 BY ;!DEVICE AND FIXING XYOUTS-RCB
; 91JUL27-BLOW UP ERROR PLOT SCALE IF AVG ERROR IS LT 18%
;
; 91 jan28 modify for ascii - IDL - postscript; rcb
; 91apr26-put "tiny=-1" for upward ticks and -z for no z label in linebar calls
; 94mar10-fix problem of not lifting pen for undefined errors
;-
;-------------------------------------------------------------------------------
	!p.charthick = 0
	!p.thick = 0
	!x.thick = 0
	!y.thick = 0
;	!fancy=2*Fsclfac
	!type=108
	!PSYM=0
	!linetype=0
	!noeras=1
	erase
	if !d.name eq 'PS' then begin
		device,output='2 setlinejoin 2 setlinecap'
	endif
;
; Extract target name from the header
;
;	n=0
;	while strmid(h(n),0,7) ne 'HISTORY' do n=n+1
;
; determine xscale
;
	if merged then begin
	    	wmin = 1100 & wmax = 3200
	    end else begin
		if min(wave) lt 1500 then begin
			wmin=1100 & wmax=2000
		   end else begin
			wmin=1950 & wmax=3300
		end
	end
;
; plot flux versus wavelength -------------------------------------------------
;
	set_viewport,0.15,0.91,0.34,0.9		;upper 70% of page
;
; determine yscale
;
	flux=abs
; 92jan27-add 1.2 factor to give more room for linebars and A's
	fmax=1.2*max(flux(where((wave gt 1230.0) and (wave gt wmin) and $
;91may23-change from 1205 to 1198 to make ngc2403 work 
;91DEC30-CHANGE FROM 1160 TO 1232 FOR MIN WL FOR SCALING
;92JAN18-CHANGE FROM 1232 TO 1227.5 FOR MIN WL FOR SCALING for n3393
;92FEB8-CHANGE FROM 1227.5 TO 1230.0 FOR MIN WL FOR SCALING for N5728
			(wave lt (wmax<3200)) and $
			((wave lt 2180) or (wave gt 2210)) and $
			(eps gt -1600) )))
;90FEB9-SET MIN FULL SCALE OF 1.5E-14
;92JAN18-SET MIN FULL SCALE OF 1.0E-14 TO BOOST UP NGC4350 SCALE
	IF FMAX LT 1.0E-14 THEN FMAX=1.0E-14
	IF FMX  GT 0.      THEN FMAX=FMX
	Fnorm=0
	while fmax lt 3 do begin
		Fnorm=Fnorm-1
		fmax=fmax*10
		flux=flux*10
	endwhile
;
; determine spacing between ticks (df) and labeled ticks (dfl)
;

	major=[1,  2, 5, 10]
	minor=[0.2, 0.5, 1.0, 2.0]
	for i=0,n_elements(major)-1 do begin
		if (((fmax/major(i)) le 5.0) and ((fmax/major(i)) gt 2.0)) then begin
			df = minor(i)
			dfl = major(i)
			goto,found_ticks
		endif
	end
	stop		;logic error
found_ticks:
	fmax = (fix(fmax/df)+1)*df
;
; set plot scale for flux plot
;
	fmin = -fmax*0.12			;12% neg. allowed
	set_xy,wmin,wmax,fmin,fmax
	!xtitle=''
	!ytitle=''
	!c=0
;
; 91jan29-lift pen at bad data in wavelengths 1200-1225 to get
;	@ Z=.017 
; 92JAN18-CHANGE PEN LIFT TO 1200-1223 TO GET TOL1924-41
; 92FEB8-CHANGE PEN LIFT TO 1200-1225 TO GET TOL1924-41 TO STILL OK
; 92jan17-LIFT PEN BELOW 1152A because of the 1.08 corr in pltgal
;
	bad = where((eps le -1600) or ((wave gt 1200) and (wave lt 1225.)) $
		OR (WAVE LT 1152))
	nbad = !err
	if nbad gt 0 then flux(bad) = 1.6e38
	null_plot,wave,flux
	plots,[wmin,wmin,wmax,wmax],[fmin,fmax,fmax,fmin],thick=3
	plots,[wmin,wmax],[0,0]
;
; plot x ticks every 100 A
;
	tick_len=(fmax-fmin)/30.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then plots,[w,w],[fmax,fmax-tick_len]
	    w=w+100
	endwhile
;
; plot y ticks
;
	f=df
	tick_len=(wmax-wmin)/100.0		
	while f lt fmax do begin
		plots,[wmin,wmin+tick_len],[f,f]
		plots,[wmax,wmax-tick_len],[f,f]
		f=f+df
	endwhile
;
; label yticks
;
	f=0
	tick_len=(wmax-wmin)/60.0		
	while f lt fmax do begin
		label=strtrim(f,2)
		xyouts,wmin-tick_len*0.3-tick_len*0.7*strlen(label), $
			f-fmax/65.,label
		plots,[wmin,wmin+tick_len],[f,f],thick=2
		plots,[wmax,wmax-tick_len],[f,f],thick=2
		f=f+dfl
	endwhile
;
; label y-axis
;
	TITLE='FLUX (10!E'+STRTRIM(FNORM,2)+'!NERG CM!E-2!N S!E-1!N A!E-1!N)'
	xyouts,wmin-(wmax-wmin)/15,fmax/10.0,title,ORIENTATION=90.
; 90MAR28-ADD ARTIFACT LABELS --RCB
	FOR I=0,3 DO IF ARTIF(I) GT 0 THEN BEGIN
            AMAX=MAX(FLUX(WHERE((WAVE GT ARTIF(I)-10) AND $ 
	    (WAVE LT ARTIF(I)+10))))+FMAX*.05
	    if amax gt 0.9*fmax then amax=1.01*fmax
	    XYOUTS,ARTIF(I)-10.,AMAX,'A'
	    ENDIF

;
; plot emission and absorp. line positions -----------------------------------
;
	frange = fmax - fmin
	ftop =  fmax-frange*0.04		;top of ticks
; 91aug1-test set last arg (tiny)=1 for all em line plots.
	linebar,frange,ftop,wmin,wmax,em,-ZE,emm_titles,emm_off,1
	for i=0,n_elements(za)-1 do begin
	    ftop = fmin + frange*(0.47 + (6-i)*0.07)
	    linebar,frange,ftop,wmin,wmax,absorp,-za(i),abs_titles,abs_off,1
	end
	ftop=-frange*.025
	linebar,frange,ftop,wmin,wmax,absorp,-0.,abs_titles,abs_off,-1  ;Z=0.0

;
; plot errors -----------------------------------------------------------------
;
	set_viewport,0.15,0.91,0.22,0.34	
	!mtitle=''
	fmax=80
        IF AVG(ABS(ERR)) LT 18 THEN FMAX=20
        df=FIX(FMAX/4.+.5)
        set_xy,wmin,wmax,0,fmax
        bad = where((eps le -900) OR (WAVE LT 1150)) & nbad= !err
	err=abs(err<FMAX)		;fix 94mar10
        if nbad gt 0 then err(bad)=1.6e38
        null_plot,wave,err
        plots,[wmin,wmin,wmax,wmax,wmin],[0,fmax,fmax,0,0],thick=3
;
; plot x ticks every 100 A
;
	tick_len=fmax/10.0
	w=100
	while w lt wmax do begin
	    if w gt wmin then begin
		plots,[w,w],[fmax,fmax-tick_len]
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
	xyouts,wmin-(wmax-wmin)/13,fmax/5.5,'SIGMA',ORIENTATION=90.,SIZE=0.9
	xyouts,wmin-(wmax-wmin)/18,fmax/3.0,'(%)',ORIENTATION=90.,SIZE=0.9
;
; plot gross and background ---------------------------------------------------
;
	set_viewport,0.15,0.91,0.1,0.22	
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
		plots,[w,w],[fmin,fmin+tick_len]
		plots,[w,w],[fmax,fmax-tick_len]
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
	f=- (abs(long(fmin))/df +1)/2*df*2
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
	xyouts,wmin-(wmax-wmin)/13,fmin,'GROSS,BKG',ORIENTATION=90.,SIZE=0.9
	xyouts,wmin-(wmax-wmin)/18,fmin,'(1000 FN)',ORIENTATION=90.,SIZE=0.9
;
; label wavelengths
;
	w=200
	while w lt (wmax-1) do begin
	    if w gt (wmin+1) then xyouts,w-(wmax-wmin)/50, $
			(fmin-range/5),strtrim(w,2)
	    w=w+200
	end
	xyouts,(wmax+wmin)/2-100,(fmin-range/2),'WAVELENGTH (A)'
return
end
