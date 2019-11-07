; 96jan11 - fixbd41d80 one stage peakup, where targ was between 2 steps.
; idea: take max of H27 count rate in max 2 steps of pkup and corr obs count 
;	rate using pkup spectrum. Correct Y2M80702T.d0d file and rereduce
;	w/ fos_process. WARNING: SINCE THIS FIX USES THE .C5 FILE, RERUNS MUST
;	BE PRECEEDED BY DELETION of new .D0 (AND OR RE-CREATION OF THE ORIG .C5
;	to see the right plot)
;
x=indgen(512)
st=''
pkobs='DISK$DATA4:[BIANCHI.5349.FOSPROCESSED]Y2M80701T
dtobs='DISK$DATA4:[BIANCHI.5349.FOSPROCESSED]Y2M80702T

	sxopen,1,pkobs+'.C5H',h
	GRP=SXPAR(H,'GCOUNT')
	aper=STRTRIM(sxpar(h,'APER_ID'),2)
	OBDAT=sxpar(h,'DATE-OBS')
	!y.style=1
	C=FLTARR(512,GRP)
	TOT=FLTARR(GRP)
	FOR I=0,GRP-1 DO BEGIN
		C(*,I)=SXREAD(1,i,gp)	;read all pkup spectra
		TOT(I)=TOTAL(C(*,I))
		ENDFOR

MXSORT=REVERSE(SORT(TOT))	;INDEX OF STEPS IN DECREASING ORDER OF SIGNAL

	MX=MAX(C)
	!xtitle='diode'
	!ytitle=''
	!mtitle=fostit(h,gp)
;	good=where(c(*,mxsort(0)) gt 0)-null_plot needed to omit dead Diodes.
	PLOT,C(*,MXSORT(0)),YR=[0,MX]	;MAX SIGNAL STEP
	OPLOT,C(*,MXSORT(1)),lines=2	;2nd highest signal
	xyouts,.11,.55,'thin,dash=pkup steps w/ most counts:'+		       $
			string(mxsort(0:1),form='(2i2)'),/norm,orient=45
	xyouts,.15,.75,'THICK=accum',/norm,orient=45
	xyouts,.05,.2,'CT/S IN FOS PEAKUP & ACCUM FOR APER='+APER+' DATE-OBS=' $
				+OBDAT,/NORM,ORIENT=90
	xyouts,.8,.8,'THICK=fix',/norm

	sxopen,1,dtobs+'.C5H',h
	GRP=SXPAR(H,'GCOUNT')
	aper=STRTRIM(sxpar(h,'APER_ID'),2)
	dtc=SXREAD(1,grp-1,gp)	;h27 accum
	xdt=indgen(n_elements(dtc))
	oplot,xdt/4.,dtc,thick=6		;accum is substepped
	oplot,[360,511],[485,370],thick=6	;fix
	plotdate,'fosfixpkup'
	if !d.name eq 'X' then read,st

;step 1 exceeds accum only past px=~385, so make a fix that =1 up to 
;	px360*4=1440 and then goes smoothly to 370/280=1.32 @px511(*4)=2044

corr=fltarr(2064)+1.
	sxopen,1,dtobs+'.d0H',h
	GRP=SXPAR(H,'GCOUNT')
	dtc=SXREAD(1,grp-1,gp)	;h27 accum d0d
	!mtitle=fostit(h,gp)+'.d0d'
	!ytitle='counts'
	plot,dtc
	y=1.+0.32*(xdt(1440:2063)-1440)/(2044-1440)
	corr(1440:2063)=corr(1440:2063)*y
	dtc=dtc*corr
	oplot,dtc,thick=6
	xyouts,.4,.4,'THICK=fix, THIN=original',/norm
	plotdate,'fosfixpkup'

;write fix:

sxaddhist,'Low counts from bad T/A fixed w/ FOSFIXPKUP'+!STIME,H
        sxopen,1,'Y2M80702T.D0H',h,'','W'
        sxwrite,1,dtc,gp
        close,1
END
