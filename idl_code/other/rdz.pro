pro rdz,name,ze,ZA
; 91JUL27-GET THE FIRST token from NAME to MAKe SPECIAL MTITLES WORK
NAME=GETTOK(NAMe,' ')
close,1
IF N_PARAMS(0) EQ 3 THEN $
	openr,1,'DISK$data2:[BOHLIN.QSO]z.list' $
      ELSE $
	openr,1,'DISK$data2:[BOHLIN.GAL]z.list'
st=''
for i=1,1000 do begin
	readf,1,st
	fname=gettok(st,' ')
	if name eq fname then begin
		st=strtrim(st)
		ze=float(gettok(st,' '))
PRINT,'ZE=',ZE
;		za=fltarr(8)
;		n=0
;		st=strtrim(st)
;		while st ne '' do begin
;			za(n)=gettok(st,' ')
;			n=n+1
;		endwhile
;		if n gt 0 then za=za(0:n-1) else za=fltarr(1)-1
		goto,done
	endif
endfor
done: close,1
return
end
