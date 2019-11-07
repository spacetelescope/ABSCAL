PRO oaolist,FILEspec
;+
;
; Routine to create a list of the names of the text files of spectra
; 93jul19-generalized iuelist to do non-sequential sets of files
;
; Input: filespec - file specification, eg oao*.u2file*
;		  - OR a vector list of the files (w/o file # @ end of name) 
;
; output:
;	 list of the spectra in file oaolist.prt
;
; CALLING SEQ eg: oaolist,'new*.ascii'
;
; HISTORY
;	93dec20-if filespec is a vector list skip sort & add file name to output
;-
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,"oaolist,FILEspec, eg: oaolist,oao*.u2"
	RETALL
	ENDIF

if n_elements(filespec) eq 1 then begin
	list = findfile(filespec)
	nosort=0
      end else begin
	list=filespec
	nosort=1
	siz=size(list)
	icount=siz(1)-1
	idnum=list
	goodlst=list
	isort=indgen(icount+1)
	goto,skipsort
	endelse
fdecomp,filespec,disk,dir,name,ext
FLEN=STRPOS(name,'*')
idnum=list
goodlst=list
icount=-1
for i=0,n_elements(list)-1 do begin
        fdecomp,list(i),disk,dir,name,ext

; FIND INTEGER PART OF NAME & store for sort
;
	LEN=STRLEN(NAME)
	IF LEN EQ FLEN THEN BEGIN
;SKIP THE FILES W/O A NUMBER IN THE NAME
		PRINT,NAME+'.'+EXT,' SKIPPED'
		GOTO,SKIP
		ENDIF
	icount=icount+1
	IDNUM(icount)=STRMID('     ',0,5-(LEN-FLEN))+STRMID(NAME,FLEN,LEN-FLEN)
	goodlst(icount)=list(i) 	;possible bad ones omitted
SKIP:
	endfor

;sort the good files into proper order
;
isort=sort(fix(idnum(0:icount)))	;array of subscripts in proper order

; print summary of good files in proper (isort) order

skipsort:
sumof = strarr(20)
n_sumof = 0
;
; open files
;
close,2  &  openw,2,'list.prt'
fdecomp,goodlst(0),disk,dir,name,ext
printf,2,disk+dir+'   '+'list.prt '+strmid(!stime,0,11)
if strupcase(strmid(filespec,0,3)) eq 'OAO' then 		$
		printf,2,'  File  ','           Star    ',' begwl    endwl'
for i=0,icount do begin
	fname=goodlst(isort(i))
        fdecomp,fname,disk,dir,name,ext
	close,1 & openr,1,fname

;
; read correct position (until you hit '###<id>')
;
		testst='###'
	st='         '
	while strmid(st,1,3) ne testst do begin
		readf,1,st
		pos = strpos(st,'SUM OF')
		if (pos ge 0) and (pos lt 4) then begin
			sumof(n_sumof) =  strtrim(strmid(st,0,71),2)
			n_sumof = n_sumof+1	;MAY BE 2 IUE CAMERAS MERGED
			end
		if nosort eq 1 then idnum(i)=strmid(st,5,8)
		end
; RCB addition
        object='            '
        readf,1,object
        object=strtrim(object,2)
	if n_sumof eq 0 then begin
		READF,1,FORMAT='(F)',BEGWL
		tstwl=1.
		WHILE(tstWL NE 0) DO begin
			endwl=tstwl
			READF,1,FORMAT='(F)',tstwl
			endwhile

		printf,2,form='(a5,a20,2f9.2,a)',  			$
			IDNUM(isort(i))+'   ',object,BEGWL,ENDWL,'  '+name     $
								+'.'+ext
	    end else begin
		for j=0,n_sumof-1 do begin
			if j eq 0 then 					$
		printf,2,form='(a5,a12,a)',  			$
			string(IDNUM(ISORT(i)),'(I4)'),OBJECT, $
				'  '+sumof(j)  			$
			else printf,2,form='(5X,a12,a)',OBJECT,'  '+sumof(j)
			endFOR
		end
;        print,idnum(isort(i)),'   ',object,begwl,endwl,'  '+name+'.'+ext
	n_sumof = 0
	endfor		; end i loop

close,1
close,2
return
end
