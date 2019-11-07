PRO rdrip,FILE,ndegr,numord,optelem,cenwave,targ,ap,root,det,ord,xripl,smrip
;+
;
; 98Apr7 - read STIS echelle ascii calibration files - rcb
;
; Input: file - file name
; OUTPUT:
;	ndegr - number of spline nodes in fits for each order
;	numord - Number of orders in echelle spectrum
;	optelem - STIS mode
; 	cenwave - central wl
;	targ    - star observed
;	ap      - observation aperture
;	root    - observation rootname
;	det	- detector
;	ord	- echelle order numbers
;	xripl   - wl's of nodes. Dimension (ndegr,numord)
;	smrip   - sensitivity at each wl node
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	
PRINT,'FILE,ndegr,numord,optelem,cenwave,targ,ap,root,det,ord,xripl,smrip'
	RETALL
	ENDIF
		st=''
                close,5  &  openr,5,file
                ndegr=0 & numord=0 & readf,5,ndegr,numord,form='(23x,i3,23x,i3)'
                print,'ECHSENS spline fits for',ndegr,' nodes and # of '+    $
                                'orders=',numord,form='(a,i3,a,i3)'
                optelem=''  &  readf,5,optelem,form='(a5)'
                cenwave=''  &  readf,5,cenwave
                targ=''     &  readf,5,targ
                aperture='' &  readf,5,aperture
                root=''     &  readf,5,root,form='(a)'
                detector='' &  readf,5,detector,form='(a)'
                readf,5,st                      ;' order m     wave,sens'
                xripl=fltarr(ndegr,numord)  &  smrip=xripl
                ord=intarr(numord)
                xrip=fltarr(ndegr)  &  smrp=xrip
                readf,5,date,form='(d)'
                for j=0,numord-1 do begin
                        readf,5,icount,ordr,xrip,smrp,  $
                                form='(2i4,'+strtrim(ndegr,2)+'F11.3/'+ $
                                       '8x,'+strtrim(ndegr,2)+'E11.3)'
                        ord(j)=ordr
                        xripl(*,j)=xrip  &  smrip(*,j)=smrp
                        endfor                  ; end order loop (j)
                close,5
	return
	end
