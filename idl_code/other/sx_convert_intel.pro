pro sx_convert_intel,filespec,from=from_platform
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+
;
;*NAME:
;	SX_CONVERT
;
;*PURPOSE:
;	Procedure SDAS GEIS datasets (.hhh,.hhd)
;
;*CALLING SEQUENCE:
;	sx_convert_intel, filespec
;
;*PARAMETERS:
; INPUT:
;	filespec - (string ) - file name specification. If the extension
;			is not specified, .hhh/.hhd is assumed.
; KEYWORDS:
;	from_platform - (string) - Name of computer system the dataset was
;		originally formatted on. The possible names are:
;
;		from=			Description
;		---------------       -----------------------
;		from='VAX' 		- DEC VAX VMS 
;		from='ALPHA/VMS'	- DEC Alpha VMS
;		from='ALPHA/OSF'	- DEC Alpha OSF/1
;		from='DOS' 		- MS DOS 
;		from='WINDOWS'		- MS Windows
;		from='SUN3' 		- SunOS
;		from='SPARC' 		- SunOS
;		from='ULTRIX' 	  	- DEC Ultrix
;		from='CONVEX'	  	- Convex OS
;
;*NOTES:
;
;    1) If the keyword parameter (from) is not specified, the program
;	defaults to VMS format unless the program detects that the current
;	computer is VMS. For VMS computers, the program defaults to Sun OS
;	format. User has option to override default input format by specifying
;	the keyword parameter (from).
;
;    2) Here is a list of the default conversions.
;
;	1) !version.os='sunos' then conversion from VMS to Sun (Sun-3, Sparc)
;	2) !version.os='ConvexOS' then conversion from VMS to ConvexOS
;	3) !version.os='OSF' then conversion from VMS to OSF
;	4) !version.os='DOS' or 'WINDOWS' then conversion from VMS to DOS
;	5) !version.os='vms' then conversion from Sun to VMS
;
;*EXAMPLES:
;
;    1) Get a list of the values which can be specified in the "from" keyword
;	parameter:
;		sx_convert,'test',/from
;
;	 Here are the supported GHRS/IDL computer systems
;	     COMPUTER   ARCHITECTURE    OPERATING SYSTEM
;	    VAX            vax                 vms
;	    SUN3           mc68020             sunos
;	    SPARC          sparc               sunos
;	    DOS            3.1                 DOS
;	    ULTRIX         mipsel              ultrix
;	    CONVEX         C2                  ConvexOS
;	    386I           386i                sunos
;	    ALPHA/VMS      alpha               vms
;	    ALPHA/OSF      alpha               OSF
;	    WINDOWS        3.1                 windows
;
;    2) Convert single SDAS GEIS dataset from Sun to OSF.
;	- log on to OSF computer
;	- transfer SDAS GEIS dataset (test.hhh, test.hhd) to the OSF computer.
;	- convert from Sun to OSF:
;		IDL> sx_convert,'test',from='sparc'
;
;    3) Convert single SDAS GEIS dataset from VMS to Sun...VMS is the default 
;	  value for the "from" keyword in this case.
;	- log on to Sun computer
;	- transfer SDAS GEIS dataset (test.hhh, test.hhd) to the Sun computer.
;	- convert from VMS to Sun:
;		IDL> sx_convert,'test.hhh'
;
;    4) Convert multiple SDAS GEIS datasets from VMS to WINDOWS...VMS is the 
;	  default value for the "from" keyword in this case.
;	- log on to WINDOWS computer
;	- transfer SDAS GEIS datasets (*.hhh, *.hhd) to the WINDOWS computer.
;	- convert from VMS to WINDOWS:
;		IDL> sx_convert,'*.hhh'
;
;
;*OPERATION:
;	A temporary dataset is created (junk.hhh/hhd) containing the converted
;	dataset. The temporary is renamed to the name of input file as the
;	final step.
;
;	Warning: On non-VMS computers, this routine performs a "destructive" 
;	write over the original input dataset.
;
;*SUBROUTINES:
;	idl_os
;	conv_vax_unix
;	swap_endian (function...IDL V4.0)
;	
;	
;*MODIFICATION HISTORY:
;          Apr 1991     DJL/ACC    
;	 9-AUG-1991	JKF/ACC 	- forced GCOUNT to be 1.
;	25-Apr-1994	JKF/ACC		- support for VAX
;       26 July 1994   PCVS/ACC         - updated for windows 
;	22-Jan-1995	JKF/ACC		- support for OSF/1
;	 9-Sep-1995	JKF/ACC		- added "from" keywords.
;	09sep1		RCB		- special version for INTEL MAC
;-
;-------------------------------------------------------------------------------
;
on_error,1
if n_params(0) lt 1 then $
	message,'sx_convert,filespec [,from=from_platform]'
on_error,0

to_os = !version.os
; 09sep1 - special patch suggested by DJL for Intel Mac:
to_os = 'windows'
;
; Substitute OS specified by keyword (/from)
;
if (n_elements(from_platform)) gt 0 then begin
	;
	; Check the possible platform
	;		
	idl_os,from_platform(0),arch,from_os
end else $					; set default
	if to_os eq 'vms' then from_os ='sunos' else from_os = 'vms'

if !dump ge 1 then $
	message,/info,' Conversion from '+from_os(0) +' to '+to_os

;
;  Assign default SDAS extension (.hhh/.hhd) if one was not specified.
;
fdecomp,filespec,dks,uics,names,exts
if strlen(strtrim(exts,2)) eq 0 then exts = '.hhh' else exts = '.'+ exts 
filespec = dks+uics+names+exts

list = findfile(filespec)	;list of files to convert
for ifile = 0,n_elements(list)-1 do begin
;
; open file and get header
;
	fdecomp, strtrim(list(ifile)), disk, uic, name, ext, ver
	fname = disk + uic + name + '.' + ext
	print,fname
	sxopen,1,fname,h
	while strlen(h(0)) lt 80 do h=h+' '		;add blanks if needed
	sxaddhist,'Written by sx_convert_intel for INTEL Mac',h

	sxopen,2,'junk',h,'','W'
	gcount = sxpar(h,'gcount')              ;number of groups
	if gcount eq 0 then gcount = 1
	pcount = sxpar(h,'pcount')              ;number of group
	bitpix = sxpar(h,'bitpix')
;
; get group parameter info/types
;
	if pcount gt 0 then begin
	   types = strarr(pcount+1)         ;group parameter type
	   sbytes = intarr(pcount+1)        ;starting byte in par array
	   nbytes = intarr(pcount+1)        ;number of bytes for parameter
;
; loop on group parameters
;
	   for i=1,pcount do begin
;
; get its data type
;
	   	psize = sxpar(h,'psize'+strtrim(i,2))
		if !err lt 0 then psize=bitpix
		pdtype = strtrim(sxpar(h,'pdtype'+strtrim(i,2)))
		if !err lt 0 then begin	 ;not found (use psize)
			case psize of
			    8: pdtype = 'INTEGER*1'
			   16: pdtype = 'INTEGER*2'
			   32: pdtype = 'INTEGER*4'
			end
		end
;
; determine IDL type code and number of bytes
;
		dtype = strupcase(strmid(pdtype,0,2))
		nbyte = psize/8
		case dtype of
		    	'IN' : case nbyte of
				1: idltype = 1
				2: idltype = 2
				4: idltype = 3
				end
		    	'LO' : case nbyte of
				1: idltype = 1
				2: idltype = 2
				4: idltype = 3
			     	end
		    	'RE' : if nbyte eq 4 then idltype=4 else idltype=5
		    	'CH' : idltype = 7
		end
		types(i) = idltype
		nbytes(i) = nbyte
		sbytes(i) = total(nbytes(0:i-1))
	end 
end
;
; loop on groups
;
for i=0,gcount-1 do begin
	if pcount gt 0 then x=sxread(1,i,par) $
	else x=sxread(1,i)            ;read data
 
	case to_os of
		'DOS'     : begin
			case from_os(0) of
				'DOS'     : 
				'windows' : 
				'sunos'   : x = swap_endian(x)
				'ConvexOS': x = swap_endian(x)
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : 
				'OSF'     : 
				end
			end
		'windows' : begin
			case from_os(0) of
				'DOS'     : 
				'windows' : 
				'sunos'   : x = swap_endian(x)
				'ConvexOS': x = swap_endian(x)
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : 
				'OSF'     : 
				end
			end
		'sunos'   : begin
			case from_os(0) of
				'DOS'     : x = swap_endian(x)
				'windows' : x = swap_endian(x)
				'sunos'   : 
				'ConvexOS': 
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : x = swap_endian(x)
				'OSF'     : x = swap_endian(x)
				end
			end
		'ConvexOS': begin
			case from_os(0) of
				'DOS'     : x = swap_endian(x)
				'windows' : x = swap_endian(x)
				'sunos'   : 
				'ConvexOS': 
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : x = swap_endian(x)
				'OSF'     : x = swap_endian(x)
				end
			end
		'vms'     : begin
			case from_os(0) of
				'DOS'     : begin
					    x = swap_endian(x)
					    ieee_to_host,x
					    end
				'windows' : begin
					    x = swap_endian(x)
					    ieee_to_host,x
					    end
				'sunos'   : ieee_to_host,x
				'ConvexOS': ieee_to_host,x
				'vms'     : 
				'ultrix'  : begin
					    x = swap_endian(x)
					    ieee_to_host,x
					    end
				'OSF'     : begin
					    x = swap_endian(x)
					    ieee_to_host,x
					    end
				end
			end
		'ultrix'     : begin
			case from_os(0) of
				'DOS'     : 
				'windows' : 
				'sunos'   : x = swap_endian(x)
				'ConvexOS': x = swap_endian(x)
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : 
				'OSF'     : 
				end
			end
		'OSF'     : begin
			case from_os(0) of
				'DOS'     : 
				'windows' : 
				'sunos'   : x = swap_endian(x)
				'ConvexOS': x = swap_endian(x)
				'vms'     : x = conv_vax_unix(x)
				'ultrix'  : 
				'OSF'     : 
				end
			end
	        else: message,' Architecture is unsupported '
	    endcase
;
; convert group parameters
;
	    if pcount gt 0 then begin
		for j=1,pcount do begin
		    sbyte = sbytes(j)
		    case types(j) of
			1: val = par(sbyte)
			2: val = fix(par,sbyte)
			3: val = long(par,sbyte)
			4: val = float(par,sbyte)
			5: val = double(par,sbyte)
			7: val = par(sbyte:sbyte+nbytes(j)-1)
		    end
		    case to_os of
			'DOS'     : begin
				case from_os(0) of
					'DOS'     : 
					'windows' : 
					'sunos'   : val = swap_endian(val)
					'ConvexOS': val = swap_endian(val)
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : 
					'OSF'     : 
					end
				end
			'windows' : begin
				case from_os(0) of
					'DOS'     : 
					'windows' : 
					'sunos'   : val = swap_endian(val)
					'ConvexOS': val = swap_endian(val)
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : 
					'OSF'     : 
					end
				end
			'sunos'   : begin
				case from_os(0) of
					'DOS'     : val = swap_endian(val)
					'windows' : val = swap_endian(val)
					'sunos'   : 
					'ConvexOS': 
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : val = swap_endian(val)
					'OSF'     : val = swap_endian(val)
					end
				end
			'ConvexOS': begin
				case from_os(0) of
					'DOS'     : val = swap_endian(val)
					'windows' : val = swap_endian(val)
					'sunos'   : 
					'ConvexOS': 
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : val = swap_endian(val)
					'OSF'     : val = swap_endian(val)
					end
				end
			'vms'     : begin
				case from_os(0) of
					'DOS'     : begin
						    val = swap_endian(val)
						    ieee_to_host,val
						    end
					'windows' : begin
						    val = swap_endian(val)
						    ieee_to_host,val
						    end
					'sunos'   : ieee_to_host,val
					'ConvexOS': ieee_to_host,val
					'vms'     : 
					'ultrix'  : begin
						    val = swap_endian(val)
						    ieee_to_host,val
						    end
					'OSF'     : begin
						    val = swap_endian(val)
						    ieee_to_host,val
						    end
					end
				end
			'ultrix'     : begin
				case from_os(0) of
					'DOS'     : 
					'windows' : 
					'sunos'   : val = swap_endian(val)
					'ConvexOS': val = swap_endian(val)
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : 
					'OSF'     : 
					end
				end
			'OSF'     : begin
				case from_os(0) of
					'DOS'     : 
					'windows' : 
					'sunos'   : val = swap_endian(val)
					'ConvexOS': val = swap_endian(val)
					'vms'     : val = conv_vax_unix(val)
					'ultrix'  : 
					'OSF'     : 
					end
				end
		        else: message,' Architecture is unsupported '
		    endcase

		par(sbyte) = byte(val,0,nbytes(j))
		end
	    end
	    sxwrite,2,x,par
	    if !dump gt 1 then print,'processing group ',i+1,' of ',gcount
	end
	close,1,2
	case 1 of
		(to_os eq 'DOS') or (to_os eq 'WINDOWS'): begin
			;
			; Avoid SPAWN when running WINDOWS. Copy the
	                ; JUNK file to the proper name.
	                ;
	                sxopen,3,'junk',h
	                ;
	                ; Don't worry about deleting JUNK since
	                ; it can be overwritten continously.
	                ; 
	                sxopen,4,fname,h,'','W'
	                if pcount eq 0 then begin
	                	im=sxread(3,0)
	                        sxwrite,4,im
	                end else begin
	                        for gc=0,gcount-1 do begin
	                        	im = sxread(3,gc,par)
	                                sxwrite,4,im,par
	                        end
	                end
	                close,3,4
	                end   
		(to_os eq 'vms') : begin
			spawn,'rename/noconf junk.hhh '+fname
			dname = strmid(fname,0,strlen(fname)-1)+'d'
			spawn,'rename/noconf junk.hhd '+dname
			end
		else: begin			; ( default is Unix )
			spawn,'mv -f  junk.hhh '+fname
			dname = strmid(fname,0,strlen(fname)-1)+'d'
			spawn,'mv -f junk.hhd '+dname
			end
	endcase
end
return
end
