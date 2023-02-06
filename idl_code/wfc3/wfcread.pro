pro wfcread,file,target,image,head,extname=extname
; 2020feb4 - read a file and update header for proper name & coord, as needed. 
;	Replaces this function of wfcdir.pro for new stars & multiple stars on
;	an image.
; NO UPDATE should be needed for stars w/ proper name & correct PM & coord.
; Also updates header for proper, invented Gaia TARGNAME convention.
; INPUT: file,target,extname(optional)
; OUTPUT: image,head
; USED BY: calwfc_imagepos, calwfc_spec
;-

if keyword_set(extname) then fits_read,file,image,head,extname=extname	$
	else fits_read,file,image,head

; Needed coord updates not already in wfcdir, EG. Gaia Secondary stars:
;	list of stars w/ P.M. > ~4px = ~0.5" in 25 yrs-->i.e. 20milli-arcsec/yr:
star=['GAIA405_6912','GAIA587_3008','GAIA588_7712','GAIA587_8560',	$
	'GAIA593_9680']

indx=where(star eq target(0))  &  indx=indx(0)
	    if indx lt 0 then return		; skip PM computation & addition
; use ten(hr,mn,sc)*15, ck w/ sixty.pro
; Use Simbad coord (header astrom is based on PH2 specified star coord)
ra= [267.32024d,223.75403,234.55682,230.18496, 243.54954]	; Gaia
dec=[-29.210493d,-60.215841,-54.522627,-58.453704,-51.781001]
; mas/yr: (Max Gaia PM=4mas/yr)
rapm=[0,0,0,0,0]
decpm=[0,0,0,0,0]

sptfil=file
pos=strpos(sptfil,'.fits')
strput,sptfil,'spt',pos-3
dum=findfile(sptfil)
fracyr=0.
pstrtime=0.
if dum ne '' then begin
    fits_read,sptfil,dum,hdspt
    pstrtime=sxpar(hdspt,'pstrtime')
    fracyr=absdate(pstrtime)-2000
    endif
; make a PM correction:
;if J2000 coord are wrong in Ph2, pointing is still to that spot & astrom is OK.
tra=ra(indx)			; new J2000 coord
tdec=dec(indx)

;corr for pm
delra=fracyr*rapm(indx)/1000d  ; arcsec
deldec=fracyr*decpm(indx)/1000.d
print,'PM corr for '+target+' at',tra,tdec,fracyr,delra,deldec, 	$
	'     for '+file,form='(a,2f11.6,3f8.2/a)'
tra=tra+delra/3600d		;degree coord of ref. px
tdec=tdec+deldec/3600d

sxaddpar,head,'RA_TARG',tra(0),'PM included by wfcread.pro-rcb'
sxaddpar,head,'DEC_TARG',tdec(0),'PM included by wfcread.pro-rcb'
sxaddpar,head,'targname',target(0),'updated by wfcread.pro-rcb'

return
end
