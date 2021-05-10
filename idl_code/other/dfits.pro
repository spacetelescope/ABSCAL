pro dfits,filespec
;+
;
; routine to do a lot of dfitswrt's
; 92may1-rcb mod to take a list of files
;EXAMPLE:  dfits,'DISK$DATA8:[OCHS.M51]*.hhh'
;          or dfits,['TPSHAMOSAIC.HHH','FORDVMOSAIC.HHH']
;******** ST_TAPEWRITE WORKED FOR MOSAIC OF CCD FILES, BUT FOR NON-ST DATA,
;		THIS PROG MIGHT NEED TO BE EDITED. SEE COMMENTS BELOW.
;-
if n_params(0) lt 1 then begin
	filespec = ''
	read,'Enter file spec for header files (eg. *.c1h,[no ticks])',filespec
endif
if n_elements(filespec) eq 1 then list = findfile(filespec) $
	else list=filespec
for i=0,n_elements(list)-1 do begin
	fdecomp,list(i),disk,dir,name,ext
;	dfitswrt,disk+dir+name+'.'+ext,name+'.fits'	;NON-hst data
;mode of tapewriting for disk output
;print,disk+dir+name+'.'+ext,' ',name+'.fits'
	st_tapewrite,disk+dir+name+'.'+ext,name+'.fits'	;HST data only
end
return
end
