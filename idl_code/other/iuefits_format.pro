pro iuefits_format,h,tab,name,array,ndecimal,type
;+
;			iuefits_format
; subroutine of iuefits to determine best format for floating point
; numbers or integers and add a column to the table.
;
; inputs:
;	h,tab - fits table arrays
;	name - name of column
;	array - array of numbers that will be converted
;	ndecimal - number of digits past decimal point
;	type - 'I' for integer  'F' for floating point
;
;
;-
;---------------------------------------------------------------------------
;
; find min and max
;
	amax = max(array,min=amin)
	amax = long(amax>(abs(amin)))+1
	print,amax,amin
;
; find number of digits
;
	n = 1
	test = 10.0d0
	while amax ge test do begin
		test = test*10
		n = n+1
	end
;
; do we need room for minus sign
;
	if amin lt 0 then n=n+1
;
; construct format
;
	if type eq 'I' then begin
		format = 'I'+strtrim(n,2)
	   end else begin
		n = n+1+ndecimal
		format = 'F'+strtrim(n,2)+'.'+strtrim(ndecimal,2)
	end
;
; determine data type
;
	s = size(array)
	idltype = s(s(0)+1)
	print,name,idltype,format
;
; add column
;
	ftaddcol,h,tab,name,idltype,format
	ftput,h,tab,name,0,array
return
end


