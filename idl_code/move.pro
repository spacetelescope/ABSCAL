; 05feb14 - make a decent move command in current directory, like VMS !!
;	for ONE asterisk
pro move, input, output

; INPUT - ascii string w/ one *
; OUTPUT - ascii string w/ one *
;-

temp=input
inpre=gettok(temp,'*')			; string before *
inpost=temp				; string after *
npre=strlen(inpre)			; no. of char before *

temp=output
outpre=gettok(temp,'*')			; string before *
outpost=temp				; string after *

infil=findfile(input)
for i=0,n_elements(infil)-1 do begin
	npost=strpos(infil(i),inpost)		; char no. input after *
	wild=strmid(infil(i),npre,npost-npre)	; wild card string
	outfil=outpre+wild+outpost
; case of * at end of input:
	if inpost eq '' then begin
		npost=strlen(infil(i))-npre
; 06jun		outfil=outpre+strmid(infil(i),npre,npost)
		outfil=outpre+strmid(infil(i),npre,npost)+outpost
		endif
	print,'Moving '+infil(i)+' to '+outfil
	spawn,'mv '+infil(i)+' '+outfil
	endfor
end
