pro sstar_ascii,file
;+
;
; 92apr-djl
; Routine to read standard star (.tab) table and convert it to ascii
; Output file will be named the same as input file with the .tab changed
; to .txt
;	example:  sstar_ascii,'hz44.std'
; compare special version in [.calib] ###########################!!!!!!!!!!!!!!
; HISTORY:
;       94apr29-generalize.
;	96nov7 -  generalize more to convert mag to flux like special version.
;	99jul19 - fix the ssread to read all output, so that arrays match. The
;		e2 and FWHM were done wrong w/ the tab_val comment below.
;-
; read table file
;
	fdecomp,file,disk,dir,name
	tab_read,file,tcb,tab,h
; eps, totex defined only for obsmode='IUE' in calobs
        ssread,file,w,f,e1,h,fwhm,e2,eps,totex  ; read & convert oke mag to flux
; table_help,tcb,h	; to see all the content of .tab files.
;       w = tab_val(tcb,tab,'wavelength')
;       f = tab_val(tcb,tab,'flux')
;	e1 = tab_val(tcb,tab,'staterror')
;       e2 = tab_val(tcb,tab,'syserror') - NG, as ssread trims w,f,e1 arrays
;	fwhm = tab_val(tcb,tab,'fwhm')
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
	PRINTF,UNIT,'SSTAR_ASCII.PRO DELETED UNDEFINED ROWS '+!STIME
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
