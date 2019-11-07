;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+
;*NAME:
;	remove_tabs
;
;*PURPOSE:
;	Remove tabs from an ASCII dataset.
;
;*CALLING SEQUENCE:
;	remove_tabs, filename
;
;*PARAMETERS:
;  INPUT:
;	filename - (string) full name of input dataset.
;
;*PROCEDURE:
;	Input ASCII dataset is read 1 line at a time. Each line
;	is searched for TAB characters. Each TAB's are replaced with 
;	1 blank.
;
;*NOTES:
;	A new version of the input file is created. For some architectures
;	this will perform a destructive write.
;
;*MODIFICATION HISTORY:
;       Apr 12 1991      JKF/ACC    - GHRS DAF (IDL Version 2)
;-
;-------------------------------------------------------------------------------
pro remove_tabs,filename

on_error,2
if n_params(0) lt 1 then $
	message,' Calling Sequence -- remove_tabs, filename

if !dump gt 2 then message,/cont,' Removing non printable characters...'

openu,unit,filename,/get_lun
sarry = strarr(400)
line  =''
indx  = 0
;
; read through the input file
;
while (not(eof(unit))) do begin
	readf,unit,line
	sarry(indx) = line
	indx=indx+1
end
indx = indx-1
;
; Convert each input line into the byte equivalent. Then search for
;	tab's (9b) and replace them with blanks (32b).
;
barry= byte(sarry(0:indx))
btmp = where(barry eq 9b,count)
if count gt 0 then barry(btmp) = 32b

sarry= string(barry)
free_lun,unit
;
; Rewrite the file...this is a destructive write on Unix computers.
;
openw, unit,filename,/get_lun
for i=0,indx-1 do printf,unit,sarry(i)
free_lun,unit
return
end
