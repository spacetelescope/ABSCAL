pro tab_convert,filespec,from=from_platform
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+
;
;*NAME:
;	TAB_CONVERT
;
;*PURPOSE:
;	Convert SDAS tables from VAX to SUN(or DOS) computers.
;
;*CALLING SEQUENCE:
;	tab_convert,filespec [,from=from_platform]
;
;*PARAMETERS:
;  INPUT:
;	filespec - string - file specification for table(s).
;
;*KEYWORDS:
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
;*EXAMPLE:
;	1) Windows, OSF/1, dos, ultrix, sun386i 
;		tab_convert,'*.tab'
;       2) Sun 3/4/SPARC
;		tab_convert,'*.tab',/swaph
;
;*MODIFICATION HISTORY:
;      Apr 18 1991      DJL/ACC    
;      Apr 29 1991	JKF/ACC		- add code for SUN's.
;      Jan 22 1994	JKF/ACC		- add code from OSF/1
;-
;-------------------------------------------------------------------------------

on_error,1
if n_params(0) lt 1 then $
	message,'Calling Sequence: tab_convert, filespec, from=from_platform'
on_error,0

to_os= 'windows'
;
; Substitute OS specified by keyword (/from)
;
if (n_elements(from_platform)) gt 0 then begin
        ;
        ; Check the possible platform
        ;               
        idl_os,from_platform(0),arch,from_os
end else begin						; set defaults
        if to_os eq 'vms' then begin
		from_os ='sunos' 
		from_platform='sparc'
	end else begin
		from_os = 'vms'
		from_platform='vax'
	end
end

if !dump ge 1 then $
        message,/info,' Conversion from '+from_os(0) +' to '+to_os
 
fdecomp,filespec,dks,uics,names,exts
if strlen(strtrim(exts,2)) eq 0 then exts = '.tab' else exts = '.'+exts
filespec = dks+uics+names+exts

list = findfile(filespec)
for j=0,n_elements(list)-1 do begin
    help,list(j)
    ; 
    ; Swap header if necessary
    ;
    swap_header=0
    case to_os of
	'DOS'	:begin
		case from_os(0) of
			'DOS'     :
                        'windows' :
                        'sunos'   : tab_hconvert,list(j),from=from_platform(0)
                        'ConvexOS': tab_hconvert,list(j),from=from_platform(0)
                        'vms'     : 
                        'ultrix'  :
                        'OSF'     :
                        end
             	end
        'windows'   :begin
                case from_os(0) of
                        'DOS'     :     
                        'windows' :
                        'sunos'   : tab_hconvert,list(j),from=from_platform(0)
                        'ConvexOS': tab_hconvert,list(j),from=from_platform(0)
                        'vms'     : 
                        'ultrix'  :
                        'OSF'     :
                        end
                end
	'sunos'   : begin
		case from_os(0) of
			'DOS'     : tab_hconvert,list(j),from=from_platform(0)
                        'windows' : tab_hconvert,list(j),from=from_platform(0)
                        'sunos'   :
                        'ConvexOS':
                        'vms'     : tab_hconvert,list(j),from=from_platform(0)
                        'ultrix'  : tab_hconvert,list(j),from=from_platform(0)
                        'OSF'     : tab_hconvert,list(j),from=from_platform(0)
                        end
              	end
	'ConvexOS': begin
		case from_os(0) of
			'DOS'     : tab_hconvert,list(j),from=from_platform(0)
                        'windows' : tab_hconvert,list(j),from=from_platform(0)
                        'sunos'   :
                        'ConvexOS':
                        'vms'     : tab_hconvert,list(j),from=from_platform(0)
                        'ultrix'  : tab_hconvert,list(j),from=from_platform(0)
                        'OSF'     : tab_hconvert,list(j),from=from_platform(0)
			end
		end
	'vms'     : begin
		case from_os(0) of
			'DOS'     : 
			'windows' : 
			'sunos'   : tab_hconvert,list(j),from=from_platform(0)
                        'ConvexOS': tab_hconvert,list(j),from=from_platform(0)
			'vms'     :
			'ultrix'  : 
			'OSF'     : 
                        end
		end
	'ultrix'     : begin
		case from_os(0) of
                        'DOS'     :     
                        'windows' :
                        'sunos'   : tab_hconvert,list(j),from=from_platform(0)
                        'ConvexOS': tab_hconvert,list(j),from=from_platform(0)
                        'vms'     : 
                        'ultrix'  :
                        'OSF'     :
                        end
		end
	'OSF'     : begin
		case from_os(0) of
                        'DOS'     :     
                        'windows' :
                        'sunos'   : tab_hconvert,list(j),from=from_platform(0)
                        'ConvexOS': tab_hconvert,list(j),from=from_platform(0)
                        'vms'     : 
                        'ultrix'  :
                        'OSF'     :
                        end
		end
    endcase
    ;
    ; Read table and get vitals.
    ;
    tab_read,list(j),tcb,tab,h
    tab_size,tcb,nrows,ncols
    ;
    ; Convert the table (one column at a time)
    ;
    for i=1,ncols do begin
        x = tab_val(tcb,tab,i)
    	case to_os of
		'DOS'	:begin
			case from_os(0) of
				'DOS'     :
	                        'windows' :
	                        'sunos'   : ieee_to_host,x
	                        'ConvexOS': ieee_to_host,x
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  :
	                        'OSF'     :
	                        end
	             	end
	        'windows'   :begin
	                case from_os(0) of
				'DOS'     :
	                        'windows' :
	                        'sunos'   : ieee_to_host,x
	                        'ConvexOS': ieee_to_host,x
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  :
	                        'OSF'     :
	                        end
	                end
		'sunos'   : begin
			case from_os(0) of
				'DOS'     : x=swap_endian(x)
	                        'windows' : x=swap_endian(x)
	                        'sunos'   :
	                        'ConvexOS':
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  : x=swap_endian(x)
	                        'OSF'     : x=swap_endian(x)
                        end
	              	end
		'ConvexOS': begin
			case from_os(0) of
				'DOS'     : x=swap_endian(x)
	                        'windows' : x=swap_endian(x)
	                        'sunos'   :
	                        'ConvexOS':
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  : x=swap_endian(x)
	                        'OSF'     : x=swap_endian(x)
				end
			end
		'vms'     : begin
			case from_os(0) of
				'DOS'     : x=conv_unix_vax(x)
				'windows' : x=conv_unix_vax(x)
				'sunos'   : x=conv_unix_vax(x)
	                        'ConvexOS': x=conv_unix_vax(x)
				'vms'     :
				'ultrix'  : x=conv_unix_vax(x)
				'OSF'     : x=conv_unix_vax(x)
	                        end
			end
		'ultrix'     : begin
			case from_os(0) of
				'DOS'     :
	                        'windows' :
	                        'sunos'   : ieee_to_host,x
	                        'ConvexOS': ieee_to_host,x
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  :
	                        'OSF'     :
	                        end
			end
		'OSF'     : begin
			case from_os(0) of
				'DOS'     :
	                        'windows' :
	                        'sunos'   : ieee_to_host,x
	                        'ConvexOS': ieee_to_host,x
	                        'vms'     : x=conv_vax_unix(x)
	                        'ultrix'  :
	                        'OSF'     :
	                        end
			end
	    endcase
        tab_put,i,x,tcb,tab
    end
    tab_write,list(j),tcb,tab,h
end
return
end
