function replace_char,st,char,newchar,nocase=nocase
;+
;			replace_char
;
; Routine to replace a character or substring in a string with a different
; character or substring
;
; CALLING SEQUENCE
;
;	result = replace_char(st,char,newchar)
;
; INPUTS:
;
;	st - string to replace characters in
;	char - character or substring to replace
;	newchar - replacement character or string (it may be a null string)
;
; OPTIONAL KEYWORD INPUTS:
;	nocase - specifies that the search for the input search is not
;		case sensitive. (i.e. Red would be found if RED is specified)
; OUTPUTS:
;	updated string returned as function result
;
; EXPAMPLE:
;	replace underlines with blanks.
;		title = replace_char(title,'_',' ')
; HISTORY:
;	version 1 D. Lindler  April 27, 1995
;-
;--------------------------------------------------------------------------
	if n_elements(nocase) eq 0 then nocase=0
	lastpos = -1			;test for infinite loop
	st_out = st			;output string
	len_char = strlen(char)		;length of string to be replaced
	if len_char eq 0 then return,st
	len_newchar = strlen(newchar)	;length of replacement string

	if nocase then schar = strupcase(char) 
	if nocase then pos = strpos(strupcase(st_out),schar) $
		  else pos = strpos(st_out,char)
;
; loop until all occurences are found
;
	while pos ge 0 do begin

		len = strlen(st_out)
		st_out = strmid(st_out,0,pos) + newchar + $
			strmid(st_out,pos+len_char,len-len_char-pos)
		start = pos + len_newchar	;where to start looking for 
						; next substring
;
; look for next one
;
		if nocase then pos = strpos(strupcase(st_out),schar,start) $
			  else pos = strpos(st_out,char,start)

	endwhile

	return,st_out
end
