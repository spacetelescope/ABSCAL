; 93aug18-plot each step of a target acq
;
x=indgen(512)
st=''
;FOSOBS,'DirGOPN.LMC20',LIST
list=['DISK$DATA4:[BIANCHI.5349.FOSPROCESSED]Y2M80701T']	;96jan10
siz=size(list)
;DY=1.4					;A1 SCANS

for IOBS=0,siz(1)-1,3 do begin		; every 3rd log entry is A1
	sxopen,1,LIST(IOBS)+'.C5H',h
	GRP=float(SXPAR(H,'GCOUNT'))
	aper=STRTRIM(sxpar(h,'APER_ID'),2)
	OBDAT=sxpar(h,'DATE-OBS')
	!y.style=1
	erase
	sum=fltarr(512)
	C=FLTARR(512,GRP)
	FOR I=0,GRP-1 DO BEGIN
		C(*,I)=SXREAD(1,i,gp)
		sum=sum+c(*,I)
		ENDFOR
	MX=MAX(C)
	TIC=STRARR(30)			;FIRST PLOT NORMAL LABELS
	FOR I=0,GRP-1 DO BEGIN
		!xtitle=''
		IF I EQ 0 THEN !xtitle='diode'
		!ytitle=''
		IF I EQ GRP/2 THEN !ytitle='count/s'
		!mtitle=''
		if i eq grp-1 then !mtitle=fostit(h,gp)
		PLOT,C(*,I),/noerase,posit=[0.1,.08+.88*i/grp,.98,	     $
			.08+(i+1)*.88/grp],YR=[0,MX],XTICKN=TIC,YTICKN=TIC,  $
			YTICKS=1
		TIC=TIC+' '		;SUPRESS TICK LABELS
		xyouts,300,.4*mx,'STEP='+STRING((I-1),'(I2)')+'  TOT CTS/S='   $
			+STRING(TOTAL(C(*,I)),'(F8.1)'),/DATA
		ENDFOR
	xyouts,.05,.1,'FOS PEAKUP FOR APER='+APER+' DATE-OBS='+OBDAT,/NORM,    $
						ORIENT=90
	plotdate,'pltpkup'
	if !d.name eq 'X' then read,st
	;!mtitle=fostit(h,gp)
	;plot,sum
	endfor
END
