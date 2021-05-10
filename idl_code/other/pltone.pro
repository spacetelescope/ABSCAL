pro PLTONE,FILE,IPLOT,FMAX,sclmin
;+
;
; Driver for sglplot.  Its only input is the IUE file name AND #.
; use as:  FOR I=1,30 DO PLTONE,'QSOSPC',33
; EXAMPLE:  PLTONE,'QSOSPC',33,FMAX,sclmin
;	USE A TITLE W/ LOG IN IT TO GET A LOG PLOT, OTHERWISE A 
;	LINEAR PLOT RESULTS.
; 89DEC8 MOD TO DO IUE ASCII FILE FORMAT FOR ONE CAMERA
; 91JUL31-ADD FMAX OPTIONAL SCALE PARAM
; 93jul14-generalize title capability for linear plots to get right scale expon
; 96mar6 - add sclmin parameter for log plots in log units
;-
	IF N_PARAMS(0) LT 3 THEN 	$
		SCALE=0. 	$	;TO MAKE SGLPLOT DO AUTO SCALING
		ELSE SCALE=FMAX
	IF N_PARAMS(0) LT 4 THEN SClmin=0.
;	TITLE='LOG INTENS (ERG CM!E-2!N S!E-1!N A!E-1!N SR!E-1!N)'
;	TITLE='INTENS '
	TITLE='LOG FLUX (ERG CM!E-2!N S!E-1!N A!E-1!N)'
;	TITLE='FLUX )'	;automatic units of 10-14 w/ full label
		RDf,FILE,IPLOT,D1	;94mar25-change from rd & AGAIN 94DEC30
;		RD,FILE,IPLOT,D1	;95jan3-try rd
		s=size(d1) & n1=s(1)
		nmerge=0
		d=d1
		short=intarr(n1)
		if d(0,0) lt 1500 then short=short+1
		hist=strarr(2)	;DUMMY SINCE NOT READING DISK FITS
	fdecomp,file,disk,dir,name,ext

;
; plot the data
;
	if strupcase(ext) eq 'MRG' then merged=1 else merged=0
	sglplot,hist,d(*,0),d(*,5),d(*,7)*100,d(*,2),d(*,2)-D(*,4)*D(*,6), $
					d(*,1),TITLE,SCALE,merged,sclmin
  
plotdate,'pltone'
	!type=4
	!PSYM=0
	!linetype=0
	!noeras=0
	!mtitle=''
        set_xy
	set_viewport
	set_screen,0,0,0,0
end
