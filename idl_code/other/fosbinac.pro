pro FOSbinac,file,ypos,data,h
;+
;			binacq
;
; ANALYZE FOS binary acquisition data file, I.E. THE .C4H, AS GEO SAYS THAT THE
;	NSCC1 CORRECTS FOR OVERSCAN AND DEAD DIODE BEFORE LOCATING STAR.
;	******* LOOK AT KEYWORD 'OPMODE' IN .SHH FILE TO VERIFY THAT THE 
;	FGWA_ID=CAM DATA IS REALLY ACQ/BINARY. see M31/M33, etc LCB GO file and
;	DISK$DATA2:[BOHLIN.FOSDATA.6038]AM6.TACQ
; 256 ybase units per diode hgt=1.29" (1.4" cycle1-3)--> 198 (182)ybases/arcsec
;
; CALLING SEQUENCE:
;	FOSbinac,file,ypos,data,h
;
; INPUTS:
;	file - header file name
;
; OUTPUTS:
;	data - data (sorted by ypos)
;	ypos - sorted ypositions
;	h - header array
;
; PLOT OUTPUT:
;	if !dump is greater than 0 a plot is produced.
;
; HISTORY:
; 93JUL22-WRITTEN AS BINACQ BY DJL AND TURNED INTO FOSBINAC BY RCB
; 96aug19-add some header ID info to 2nd plot along w/ integ counts at ea y-step
; 96aug20-add peak and 9px sum info to 2nd plot
;-----------------------------------------------------------
;
; open file and read data
	sxopen,1,file,h
	gcount=sxpar(h,'gcount')
	ns = sxpar(h,'naxis1')
	psize = sxpar(h,'psize')
	data = fltarr(ns,gcount)
	par = bytarr(psize/8,gcount)

	for i=0,gcount-1 do begin
		data(0,i) = sxread(1,i,p)
		par(0,i) = p
		end
;
; extract ypos AND EXPOSURE TIME PER X STEP
;
	EXPTM=sxgpar(h,p,'exposure')
	y =sxgpar(h,par,'ypos')
	if exptm eq 0 then exptm=1	;96apr24-to allow doh file to be used
	CNTS=DATA*EXPTM

	tot = fltarr(gcount)
	for i=0,gcount-1 do tot(i) = total(cnts(*,i))
	print,tot

	!p.multi=[0,2,(GCOUNT+1)/2]
	XTIT='PX IN GROUP='+STRTRIM(INDGEN(GCOUNT),2)
	YTIT='CTS FOR EXPTM='+STRMID(STRTRIM(EXPTM,2),1,4)+' AT Y='	$
		+STRTRIM(FIX(Y),2)
	TIT=YTIT
	FOR I=0,GCOUNT-1 DO TIT(I)=FILE+' PEAK COUNTS='+		$
		STRTRIM(MAX(CNTS(*,I)),2)
	ST=''
	FOR I=0,GCOUNT-1 DO PLOT,CNTS(*,I),TIT=TIT(I),XTIT=XTIT(I),	$
		YTIT=YTIT(I),YR=[0,MAX(CNTS)]
	PLOTDATE,'FOSBINAC'
READ,'HIT <CR> TO CONTINUE',ST

;
; sort
;
	sub = sort(y)
	ypos = y(sub)
	data = data(*,sub)
;
; contour data
;
; 96aug19-add idiot ck:
	aper=strtrim(sxpar(h,'APER_ID'),2)
	if aper ne 'A-1' then begin
		print, aper+' aperture NE A-1...STOP in FOSBINAC'
		stop
		endif
	if !dump gt 0 then begin
		!mtitle=strtrim(sxpar(h,'targname'),2)+' '+		$
			strtrim(sxpar(h,'FGWA_ID'),2) +' '+		$
			strtrim(sxpar(h,'detector'),2)+' '+ file
		!ytitle=' Y-Position'
		!p.multi=0
		contour,data,findgen(ns),ypos
		x0 = ns/30
		x1 = ns/15
		x2 = ns/10
		dely = (!y.crange(1)-!y.crange(0))/100.0
		for i=0,gcount-1 do begin
			oplot,[x1,x2],[y(i),y(i)]
			xyouts,x0,y(i)-dely,strtrim(i,2),/data
			xyouts,x2+1,y(i)-dely,strtrim(fix(tot(i)+.5),2),/data
			xyouts,x2+5,y(i)-dely,				$
					STRTRIM(fix(MAX(CNTS(*,I))+.5),2),/data
			indx=where(cnts(*,i) eq max(cnts(*,i)))
			ind1=indx(0)-4  &  if ind1 lt 0 then ind1=0
			ind2=ind1+8
			if ind2 gt n_elements(cnts(*,i))-1 then begin
				ind2=n_elements(cnts(*,i))-1
				ind1=ind2-8
				endif
			xyouts,x2+9,y(i)-dely,                          $
                              STRTRIM(fix(total(CNTS(ind1:ind2,I))+.5),2),/data
			PLOTDATE,'FOSBINAC'
			endfor
		ylab=!y.crange(1)-3.5*dely
		xyouts,x0,ylab,'Counts:TOTAL PEAK 9PX SUM',/DATA
		endif
return
end
