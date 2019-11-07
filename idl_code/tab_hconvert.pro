;+
;*NAME:
;   TAB_HCONVERT
;
;*PURPOSE:
;	Perform byte-swapping when converting SDAS tables
;
;*CALLING SEQUENCE:
;	tab_hconvert,name,from=from_platform
;
;*PARAMETERS:
;  INPUT:
;	name - name of table
;
;  KEYWORD:
;	from - (string) - name of computer system the dataset was
;               originally formatted on. The possible names are:
;                                                      
;               from=                   Description
;               ---------------       -----------------------
;               from='VAX'              - DEC VAX VMS
;               from='ALPHA/VMS'        - DEC Alpha VMS
;               from='ALPHA/OSF'        - DEC Alpha OSF/1
;               from='DOS'              - MS DOS
;               from='WINDOWS'          - MS Windows
;               from='SUN3'             - SunOS
;               from='SPARC'            - SunOS
;               from='ULTRIX'           - DEC Ultrix
;               from='CONVEX'           - Convex OS
;
;*NOTE:
;		tcb(*,i) contains description of column i
;		   word 0	column number
;			1	offset for start of row in units of 2-bytes
;			2	width or column in 2-byte units
;			3	data type
;					6 = real*4
;					7 = real*8
;					4 = integer*4
;					1 = boolean*4
;					2 = character string
;			4-8	ascii column name up to 19 characters
;			9-13	column units (up to 19 characters)
;			14-15	format string
;*HISTORY:
;	27-apr-1991	JKF/ACC		- created for GHRS DAF.
;	24-nov-1996	jkf/acc		- updated calling sequence.
;-
;------------------------------------------------------------------------
pro tab_hconvert,name,from_platform=from_platform
if n_params(0) lt 1 then begin
	print,'Calling Sequence: tab_read,name [,from_platform]
	retall
endif

to_os = 'windows'
if (n_elements(from_platform)) gt 0 then begin
	;
	; Check the possible platform
	;               
	idl_os,from_platform(0),arch,from_os
end else $                                      ; set default
	if to_os eq 'vms' then from_os ='sunos' else from_os = 'vms'
;
; open file
;
get_lun,unit
fname = name
if strpos(fname,'.') lt 1 then fname=strtrim(fname)+'.tab'
!err=0
openu,unit,fname,/block                  
if !err lt 0 then begin
	free_lun,unit
	print,'TAB_READ- Error opening file '+fname
	print,strmessage(-!err)                                
	retall
end
;
; read header record
;
if !dump ge 1 then $
	message,/info,' Converting header '+from_os(0) +' to '+to_os

lrec=assoc(unit,lonarr(12),0)
h=lrec(0)
case to_os of
	'DOS'     : begin
		case from_os(0) of 
			'DOS'     : 
			'windows' : 
			'sunos'   : h=swap_endian(h)
			'ConvexOS': h=swap_endian(h)
			'vms'     : 
			'ultrix'  :
			'OSF'     :
		 	end
		end
	'windows' : begin
		case from_os(0) of 
			'DOS'     : 
			'windows' : 
			'sunos'   : h=swap_endian(h)
			'ConvexOS': h=swap_endian(h)
			'vms'     : 
			'ultrix'  :
			'OSF'     :
		 	end
		end
	'sunos'   : begin
		case from_os(0) of 
			'DOS'     : h=swap_endian(h)
			'windows' : h=swap_endian(h)
			'sunos'   : 
			'ConvexOS': 
			'vms'     : h=conv_vax_unix(h)
			'ultrix'  : h=swap_endian(h)
			'OSF'     : h=swap_endian(h)
		 	end
		end
	'ConvexOS': begin
		case from_os(0) of 
			'DOS'     : h=swap_endian(h)
			'windows' : h=swap_endian(h)
			'sunos'   : 
			'ConvexOS': 
			'vms'     : h=conv_vax_unix(h)
			'ultrix'  : h=swap_endian(h)
			'OSF'     : h=swap_endian(h)
		 	end
		end
	'vms'     : begin
		case from_os(0) of 
			'DOS'     : 
			'windows' : 
			'sunos'   : h=conv_unix_vax(h)
			'ConvexOS': h=conv_unix_vax(h)
			'vms'     : 
			'ultrix'  :
			'OSF'     :
		 	end
		end
	'ultrix'  : begin
		case from_os(0) of 
			'DOS'     : 
			'windows' : 
			'sunos'   : h=swap_endian(h)
			'ConvexOS': h=swap_endian(h)
			'vms'     : 
			'ultrix'  :
			'OSF'     :
		 	end
		end
	'OSF'     : begin
		case from_os(0) of 
			'DOS'     : 
			'windows' : 
			'sunos'   : h=swap_endian(h)
			'ConvexOS': h=swap_endian(h)
			'vms'     : 
			'ultrix'  :
			'OSF'     :
		 	end
		end
endcase
lrec(0)=h
maxcol=h(5)

;
; Convert the TCB
;
sbyte=12*4+h(1)*80L			;starting byte of column descriptions
lrec = assoc(unit,lonarr(16,maxcol),sbyte)
tcb=lrec(0)			;read col. descriptions
;		   word 0	column number
;			1	offset for start of row in units of 2-bytes
;			2	width or column in 2-byte units
;			3	data type
;					6 = real*4
;					7 = real*8
;					4 = integer*4
;					1 = boolean*4
;					2 = character string
;			4-8	ascii column name up to 19 characters
;			9-13	column units (up to 19 characters)
;			14-15	format string
for ii=0,3 do begin
	tmp = tcb(ii,*)
	; do not convert TEXT fields(4 thru n)
	case to_os of
		'DOS'     : begin
			case from_os(0) of 
				'DOS'     : 
				'windows' : 
				'sunos'   : tmp=swap_endian(tmp)
				'ConvexOS': tmp=swap_endian(tmp)
				'vms'     : 
				'ultrix'  :
				'OSF'     :
			 	end
			end
		'windows' : begin
			case from_os(0) of 
				'DOS'     : 
				'windows' : 
				'sunos'   : tmp=swap_endian(tmp)
				'ConvexOS': tmp=swap_endian(tmp)
				'vms'     : 
				'ultrix'  :
				'OSF'     :
			 	end
			end
		'sunos'   : begin
			case from_os(0) of 
				'DOS'     : tmp=swap_endian(tmp)
				'windows' : tmp=swap_endian(tmp)
				'sunos'   : 
				'ConvexOS': 
				'vms'     : tmp=conv_vax_unix(tmp)
				'ultrix'  : tmp=swap_endian(tmp)
				'OSF'     : tmp=swap_endian(tmp)
			 	end
			end
		'ConvexOS': begin
			case from_os(0) of 
				'DOS'     : tmp=swap_endian(tmp)
				'windows' : tmp=swap_endian(tmp)
				'sunos'   : 
				'ConvexOS': 
				'vms'     : tmp=conv_vax_unix(tmp)
				'ultrix'  : tmp=swap_endian(tmp)
				'OSF'     : tmp=swap_endian(tmp)
			 	end
			end
		'vms'     : begin
			case from_os(0) of 
				'DOS'     : 
				'windows' : 
				'sunos'   : h=conv_unix_vax(h)
				'ConvexOS': h=conv_unix_vax(h)
				'vms'     : 
				'ultrix'  :
				'OSF'     :
			 	end
			end
		'ultrix'  : begin
			case from_os(0) of 
				'DOS'     : 
				'windows' : 
				'sunos'   : tmp=swap_endian(tmp)
				'ConvexOS': tmp=swap_endian(tmp)
				'vms'     : 
				'ultrix'  :
				'OSF'     :
			 	end
			end
		'OSF'     : begin
			case from_os(0) of 
				'DOS'     : 
				'windows' : 
				'sunos'   : tmp=swap_endian(tmp)
				'ConvexOS': tmp=swap_endian(tmp)
				'vms'     : 
				'ultrix'  :
				'OSF'     :
			 	end
			end
	endcase
	tcb(ii,*)= tmp
end
lrec(0)=tcb

free_lun,unit
return
end
