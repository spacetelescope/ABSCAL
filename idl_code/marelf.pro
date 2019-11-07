function marelf,det,filter,comment,name,delnam,delta=delta

;+
; 02aug21 - to read Jen & van der marel L-flats and conv. from mags.
; INPUT:
;	det - HRC, SBC, or WFC in caps.
;	filter - file name in acsdeliv, eg. lphe01235sm02f*.fits
;	delta - keyword to do delta flat correction
; OUTPUT - L-flat correction image to be multiplied by Lab flats 
;	name -name of L-flat correction file
;	comment - bit of info from this function.
;	delnam - name of delta flat
; 03jun20 - jen has the interpolated files that roeland is missing,
;	so switch to using her sets.
; 03aug19 - Pol modes have flats identical to the non-pol!!! SO use Jen's.
; 6 SBC flats added 05nov
; 06sep14 - mod for RGs delta flats for switch of WFC temp on 06jul4
;-
delnam=''
dir='~/data/acsjref/'
pos=strpos(filter,'f')
filt=strlowcase(strmid(filter,pos,5))
name=findfile(dir+strlowcase(det)+'lflat'+filt+'*.fits')  &  name=name(0)
if name eq '' then begin
	corr=1
	print,'  *** WARNING: NO LFLAT CORRECTION AVAILABLE ***',form='(/,a,/)'
	print,'FOR: ',name
	comment='*NO flight corr. available'
	stop					; 04mar17
    end else begin
	print,' Reading L-flat file:',name
	fits_read,name,corr,hd
	corr=10^(-0.4*corr)			; corr to be multiplied by flat
	comment='*flight fix'
	endelse
if not keyword_set(delta) then delta=0
if delta eq 1 and det eq 'WFC' then begin
	delnam='~/data/acsjref/dfl'+strmid(filt,1,3)+'.hhh'
	sxopen,1,delnam,hd
	corr=corr*sxread(1)
	print,'***DELTA WFC SIDE 2 FLAT='+delnam
	endif
return,corr
end
