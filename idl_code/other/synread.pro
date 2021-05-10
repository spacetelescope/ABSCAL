; 03jun3 - synread.pro to read synphot output files
;-

pro synread,file,filt,pivot,count

; Input - file name from Francesca's synphot run
; Output - filter name, pivot wavelength, & predicted counts
;
st=''
close,5  &  openr,5,file
filt=strarr(100)
pivot=fltarr(100)
count=pivot
i=-1
while not eof(5) do begin
	i=i+1
	readf,5,st
	if strmid(st,0,4) ne 'Mode' then stop		; idiot check
	filtr=strmid(st,19,10)
	dum=gettok(filtr,',')
	pos=strpos(filtr,')')
	filt(i)=strmid(filtr,0,pos)
	readf,5,st  &  readf,5,st  &  readf,5,st	; skip 2 lines
	pivot(i)=float(strmid(st,0,11))
	readf,5,st  &  readf,5,st  &  readf,5,st	; skip 2 line
	count(i)=float(strmid(st,18,10))
	endwhile
filt=filt(0:i)
pivot=pivot(0:i)
count=count(0:i)
end
 

