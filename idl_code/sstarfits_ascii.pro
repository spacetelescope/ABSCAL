pro sstarfits_ascii,file
;+
;
; 99jul19 - rcb adopted from sstar_ascii for old SDAS tables
; Routine to read standard star (.fits) table and convert it to ascii
; Output file will be named the same as input file with the .fits changed
; to .txt
;	example:  sstarfits_ascii,'mu_peg_iue.fits'
;-

; read fits file
;
	fdecomp,file,disk,dir,name
; eps, totex defined only for obsmode='IUE' in calobs
        ssreadfits,file,h,w,f,e1,e2,eps,totex,fwhm
;94FEB11-GET RID OF UNDEFINED ROWS
	IND=WHERE(F NE 1.6E+38 and f ne !values.f_nan)
	W=W(IND)
	F=F(IND)
	E1=E1(IND)
	E2=E2(IND)
	FWHM=FWHM(IND)
	
;
; open output text file
;
;	LEN=STRLEN(NAME) & NAME=STRMID(NAME,0,LEN-4)	;TRIM CDBS GARBAGE
	openw,unit,name+'.txt',/get_lun
	PRINT,'WRITE FILE: ',name+'.txt'
;
; print header
;
	n = 0
	while strmid(h(n),0,8) ne 'END     ' do begin
		printf,unit,h(n)
		n = n+1
	end
	PRINTF,UNIT,'SSTARFITS_ASCII.PRO DELETED UNDEFINED ROWS '+!STIME
	PRINTF,UNIT,'ORIG FILE='+File
;
; print data
;
	printf,unit,' '
	printf,unit,'     Wavelength      flux    staterror    syserror' + $
				'         fwhm'
	printf,unit,' '
	PRINTF,UNIT,' ###    1'
	PRINTF,UNIT,' '+NAME
	for i=0,n_elements(w)-1 do printf,unit,w(i),f(i),e1(i),e2(i),fwhm(i)
	PRINTF,UNIT,' 0 0 0 0 0'
;
; done
;
	free_lun,unit
	return
end
