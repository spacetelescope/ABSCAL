PRO iuelist,FILE,ist,last
;+
;
; Routine to create a list the names of the text files of iue spectra
;
; Input: file - file name
;	 ist  - first file #
;	 last - last file #
; output:
;	 list of the spectra in file iuelist.prt
;
; calling seq eg: iuelist,'new.ascii',22,222
; NB: see also oaolist.pro
;-
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'iuelist,FILE,first,last'
	RETALL
	ENDIF
sumof = strarr(20)
n_sumof = 0
;
; open files
;
close,2 & openw,2,'iuelist.prt'
printf,2,'		'+FILE+'   '+'iuelist.prt '+!stime

for i=ist,last do begin
	on_ioerror,try_again
	close,1 & openr,1,file
	fname=file
	goto,got_it
try_again:
	on_ioerror,null
	fdecomp,file,disk,dir,name,ext
	fname=disk+dir+name+strtrim(i,2)+'.'+ext
	close,1 & openr,1,fname
got_it: on_ioerror,null
;
; read correct position (until you hit '###<id>')
;
		nchar=8
		testst='###'+string(i,'(i5)')
	st='         '
	while strmid(st,1,nchar) ne testst do begin
		readf,1,st
		pos = strpos(st,'SUM OF')
		if (pos ge 0) and (pos lt 4) then begin
			sumof(n_sumof) =  strtrim(strmid(st,0,71),2)
			n_sumof = n_sumof+1
		end
	end
; RCB addition
        object='            '
        readf,1,object
        object=strtrim(object,2)
        print,fname,'   ',object
	if n_sumof eq 0 then begin
		printf,2,fname,'   ',object
	    end else begin
		for j=0,n_sumof-1 do begin
		    if j eq 0 then printf,2,string(i,'(I4)')+'  '+sumof(j) $
			      else printf,2,'      '+sumof(j)
		end
	end
	n_sumof = 0
	endfor

close,1
close,2
return
end
