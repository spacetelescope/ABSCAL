pro acsadd,camera,list,HDR,SUMFLT,SIGMA,fullhdr
;+
;
; for SBC only. no overscan or trimming in acs_read. use acs_cr for ccds
; INPUT:
;	camera-SBC, WFC, or HRC
;	list - list of exp to add instead of doing DB search
; OUTPUT:
;       HDR,SUMFLT,SIGMA - of co-added frames NOT written to disk
;	fullhdr - full header of last image in coadd
; EXAMPLE:  fltadd,'F115LP','SBC',list,HDR,SUMFLT,SIGMA
;
; HISTORY:
;	99Mar5 - rcb adopted from the STIS fltadd.pro
;	99mar19- add totimg keyword to header.
;-
;!prelaunch=1	not needed. SBC lab and GO coord are the same.
flat=fltarr(1024,1024)			;SBC or HRC master flat to be created
bmask=flat+1				;init. mask to unity
st=''
!x.style=1
sxhmake,flat,1,hdr
sxaddpar,hdr,'origin','Bohlin IDL'
sxaddpar,hdr,'filetype','PIXEL-TO-PIXEL FLAT'   ; 01aug-official value'
sxaddpar,hdr,'telescope','HST'
sxaddpar,hdr,'instrument','ACS'
sxaddpar,hdr,'obstype','IMAGING'
sxaddpar,hdr,'obsmode','ACCUM'
sxaddpar,hdr,'pedigree','GROUND'
sxaddpar,hdr,'USEAFTER','March 01 2002'
sxaddpar,hdr,'DESCRIP','GROUND MAMA P-FLAT from 1999 data-R. Bohlin'
                                                                         
nfiles=n_elements(list)

for i=0,nfiles-1 do begin
	acs_read,list(i),fullhdr,bin		
;print,list(i)
;print,bin(840:845,78:83)                        ; eg: spike
;print,bin(958:962,849:853)                      ; eg: zero sens
	av=avg(bin(460:563,460:563))		;avg counts at center
	print,'avg counts=',av,' For entry=',list(i)

	if i eq 0 then begin
	    sxaddpar,hdr,'filter1',sxpar(fullhdr,'filter1',comment=comment),   $
								comment
	    sxaddpar,hdr,'filter2',sxpar(fullhdr,'filter2',comment=comment),   $
								comment
	    sxaddpar,hdr,'filter3',sxpar(fullhdr,'filter3',comment=comment),   $
								comment
	    sxaddpar,hdr,'detector',sxpar(fullhdr,'detector',comment=comment), $
								comment
; lab flats	    sxaddpar,hdr,'stimulus',sxpar(fullhdr,'stimulus',comment=comment), $
;	only							comment
	    sxaddpar,hdr,'sclamp',sxpar(fullhdr,'sclamp',comment=comment),     $
								comment
	    sxaddpar,hdr,'totimg',long(nfiles),'Total number of images co-added'
	    sxaddpar,hdr,'fw1offst',0,'Offset of filter wheel 1'
	    sxaddpar,hdr,'fw2offst',0,'Offset of filter wheel 2'
	    sxaddpar,hdr,'fwsoffst',0,'Offset of filter wheel 3'
	    sxaddpar,hdr,'fwoffset',0,'Obsolete Offset of filter wheel'
 	    sxaddhist,'Flat field image composed of the following images:',hdr
	    endif
	sxaddhist,'Entry '+strtrim(list(i),2)+' avg counts @ '+		$
			'(460:563,460:563)='+string(av,form='(f6.0)'),hdr
	flat=flat+bin
	endfor
; resultant co-add will be the sum of counts in the list of images:

bad=where(flat eq 0)
;tvscl,sumflt<avg(sumflt(500:600,500:600))*1.1>avg(sumflt(500:600,500:600))*.7
sumflt=flat
sigma=flat*0
good=where(flat gt 0)
sigma(good)=1./sqrt(flat(good))

RETURN
end
