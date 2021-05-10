pro iuebreak,file,ISTART
;+
;			iuebreak
;
; Breaks up IUE/IBM text files
;
; CALLING SEQUENCE:
;	iuebreak,name,istart
;
; INPUTS:
;	name - file name
; OPTIONAL INPUT: ISTART-FIRST OUTPUT FILE IS ISTART+1
;
; OUTPUTS:
;	a alot of files with names <name>###
; 93sep2-mod to make the output file ### numbers sequential, starting w/ 1
; 94JUL18-ADD OPTIONAL STARTING PARM, WHERE FIRST OUTPUT FILE IS ISTART+1
;-
;-----------------------------------------------------------------------------
;
; open input file
;
	close,1 & openr,1,file
	fdecomp,file,disk,dir,name,ext
	comments = strarr(5000)
	st = ''
	IF N_PARAMS(0) GT 1 THEN ISPEC=ISTART ELSE ispec=0
;
; loop until done
;
	while not eof(1) do begin
;
; read comments
;
		ncom = 0
		readf,1,st
		while strmid(st,0,4) ne ' ###' do begin
			if eof(1) then goto,done
			if ncom lt 4999 then begin
				ncom = ncom+1
				comments(ncom) = st
			endif
			readf,1,st
		endwhile
;
; construct output file name
;
;		fname = name+strtrim(strmid(st,4,strlen(st)-4),2)+'.'+ext
; 93sep2-go to sequential numbering for ellip atlas from >1 MERGE runs
		ispec=ispec+1
		fname = name+strtrim(ispec,2)+'.'+ext
		print,fname
;
; open output file and write header
;
		close,2 & openw,2,fname
		if ncom gt 0 then $
			for i=0,ncom-1 do printf,2,strtrim(comments(i))
		printf,2,st
;
; write data
;
		readf,1,st & printf,2,st
		repeat begin
			readf,1,st
			printf,2,st
			trim_st = strtrim(st,2)
		       end until strmid(trim_st,0,1) eq '0'
		close,2
	endwhile
done:	close,1,2
	return
end	
