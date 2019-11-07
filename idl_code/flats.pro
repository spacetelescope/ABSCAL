pro flats,det,entry,SUMFLT,HDR,FLAT,ERR,EPS,FIT,chip=chip
;+
; ACS - Make P-flats. Used for SBC preflight data.
; 
; INPUT:
;       det-SBC, WFC, or HRC
;       entry - vector list of exp to add and make a flat.
; OUTPUT:
;	SUMFLT - coadded data used to make the flat. For CCD add w/ acs_cr.
;       HDR,FLAT,ERR,EPS - co-added frames and made into flat
;	FIT - the final fit to the SUMFLT
; EXAMPLE:  flats,'sbc',list,SUMFLT,HEAD,FLAT,ERR,EPS,FIT
;
; HISTORY:
; 99mar11- iterate w/ fits to the fits in the orthogonal direction, esp for SBC
;		Revamped to be a subroutine, instead of main program.
; 99mar22- iterate HRC fits in col direction, as well.
; 02may15 - conv to unix. Use this .pro only for SBC.
; 05apr11 - fix DQ (eps) array to conform w/ STScI convention (512=bad in flat)
; 06nov28 - sbc hot px found at 55-56,281 & 842-3,81. 
;		Ck bad px table w/ 295 bad pixels and add flags.
;-

hdr=strarr(1)				; for CCD & to be safe on SBC
sm=n_elements(entry)		; # of coadded images
; SBC MAMA SECTION
if det eq 'sbc' then begin
	eps=intarr(1024,1024)		; 05apr11 - was byte
	acsadd,det,entry,hdr,sumflt,err,fullhdr
        onemsk=bytarr(1024,1024)+1	; mask of where flat is set to 1
        ignmsk=bytarr(1024,1024)+1	; mask of pts to keep,but ignore in fit
	onemsk(*,0:3)=0			; bottom 3 rows bad.
	onemsk(*,1020:1023)=0		; top 4 rows bad.
	onemsk(0:1,*)=0			; first 2 cols bad.
	onemsk(*,599:604)=0		; Bad MAMA rows
	onemsk=imcircle(onemsk,697,494,505,0)	; set corners to zero
; 06nov28 - read bad px table and add those flags:
	z=mrdfits('~/acsjref/lch1502jj_bpx.fits',1,hd)
	xpx=z.pix1-1  &  ypx=z.pix2-1	; conv sdas convention to IDL
	onemsk(xpx,ypx)=0
; 06oct2 - postlaunch do not have filter3
	if !prelaunch eq 0 then sxaddpar,hdr,'filter3',sxpar(hdr,'filter1')
; Prisms drop rapidly to zero beyond ~850.
	if strpos(sxpar(hdr,'filter3'),'PR') ge 0 then onemsk(851:1023,*)=0
; pinhole "SPLATS":
	if strpos(sxpar(fullhdr,'STFTARG'),'PINHOLE') ge 0 then 	$
					onemsk=imcircle(onemsk,125,625,560,0)
        ignmsk(0:4,*)=0                 ; 01jul16 - flaky col 2-4
	ignmsk(1000:1023,*)=0		; RH cols drop sharply. Prob real vignet
	bad=where(onemsk eq 0)  &  eps(bad)=512
; repeller wire. prism 2 px wider than filters.
	if strpos(sxpar(hdr,'filter3'),'PR') ge 0 then begin 
		ignmsk(558:570,*)=0
;<10 deep no flag	eps(558:570,*)=174			; Repeller. fix mar23
	      end else begin
		ignmsk(573:583,*)=0
;<10 deep no flag	eps(573:583,*)=174			; Repeller flag
		endelse
	fitflat,hdr,sumflt,onemsk*ignmsk,9,rowfit,flat,/nomed
	if strpos(sxpar(fullhdr,'STFTARG'),'PINHOLE') lt 0 then begin
; FIT the FIT in orthogonal direction
		fitflat,hdr,rowfit,onemsk,9,fit,/col,/nomed	; ignmsk filled
		flat=sumflt/fit
		endif

	flat(where(onemsk le 0))=1              ;01jul11 - -1 mask can be set
	err=1./sqrt(sumflt>1)			; % uncertainty
	err=err*flat				; fixed 99mar29
	err(bad)=1				; 06nov8 - new CCD convention

;	tvscl,flat<1.05>.95
;	bigtv,flat<1.05>.95
     end else begin		$

; CCD SECTION == WFC, HRC... NOT used as of 01jul.
; /noskyadjust required, otherwise the sky lots of data gets rejected near min.
	if not keyword_set(chip) then chip=0	; default
	acs_cr,entry,hcr,sumflt,err,eps,nused,/noskyadj,chip=chip
;						outfil=filnam+'_crj.fits'
	s=size(sumflt)  &  nx=s(1)  &  ny=s(2)
	onemsk=bytarr(nx,ny)+1			; mask of where flat is set to 1
	ignmsk=bytarr(nx,ny)+1 		;mask of pts to keep,but ignore in fit
	badspots,hcr,ignmsk
	if det eq 'wfc' then ignmsk(0:100,*)=0	; 00jun22 9:56 wfc bright on lft
; WFC chip1-only one px bad @ left,rt,bott. top ok chip2-1 bad all around
	onemsk(0,*)=0				; First hrc,wfc col bad
	onemsk(nx-4:nx-1,*)=0			; Last 4 hrc col
	onemsk(*,0:2)=0				; bottom 3 hrc. Top ok for hrc
	onemsk(*,ny-1)=0			; top row WFC chip2 bad
	if chip eq 2 then onemsk(603,0:825)=0	; bad col entry=16521

	if det eq 'hrc' then finger_mask,hcr,onemsk	; occulting finger mask
; set lower left WFC corner to zero
	if det eq 'wfc' and chip eq 1 then 				$
		onemsk=imcircle(onemsk,5160,5000,1400,0)
	bad=where(onemsk eq 0)  &  eps(bad)=512 ; 99mar29

	fitflat,hcr,sumflt,onemsk*ignmsk,9,rowfit

	fitflat,hcr,rowfit,onemsk,9,fit,/col,/nomed	;ignmsk regions filled
	flat=sumflt/fit
	
	flat(where(onemsk le 0))=1
	err=err/(sumflt>1)			; proper value from acs_cr
; no significant change (<.01%) from int F625W check:
;	err=1./sqrt(sumflt>1)			; rough. fixed 99mar30 16:52
	err=err*flat				; fixed 99mar29

	if det eq 'hrc' then begin		; 00jul3 no dust flagged on wfc
		rdf,'dust.'+det,1,spots
		tvcircle,16,spots(*,0),spots(*,1)
		tvscl,flat<1.02>.98
		endif

; CCD only, as SBC acsadd.pro makes the headers:
	sxhmake,flat,1,hdr
; nx & ny need to be defined,if this ff line ever gets used:
        sxaddpar,hdr,'naxis1',nx  &  sxaddpar,hdr,'naxis2',ny
        sxaddpar,hdr,'origin','Bohlin IDL'
        sxaddpar,hdr,'filetype','PIXEL-TO-PIXEL FLAT'   ; 01aug-official value
        sxaddpar,hdr,'ccdgain',-999             ; 01aug-official value required
        sxaddpar,hdr,'ccdamp','N/A'             ; 01aug-official value    "
        sxaddpar,hdr,'telescope','HST'
        sxaddpar,hdr,'instrument','ACS'
        sxaddpar,hdr,'obstype','IMAGING'
        sxaddpar,hdr,'obsmode','ACCUM'
        sxaddpar,hdr,'pedigree','GROUND'
        sxaddpar,hdr,'USEAFTER','Jan 1 1997'
        sxaddpar,hdr,'DESCRIP','GROUND MAMA P-FLAT from 1999 data'
	sxaddpar,hdr,'filter1',sxpar(hcr,'filter1',comment=comment),comment
	sxaddpar,hdr,'filter2',sxpar(hcr,'filter2',comment=comment),comment
	sxaddpar,hdr,'filter3',sxpar(hcr,'filter3',comment=comment),comment
	sxaddpar,hdr,'detector',sxpar(hcr,'detector',comment=comment),comment
	sxaddpar,hdr,'stimulus',sxpar(hcr,'stimulus',comment=comment),comment
	sxaddpar,hdr,'sclamp',sxpar(hcr,'sclamp',comment=comment),comment
        sxaddpar,hdr,'totimg',long(sm),'Total number of images co-added'
	if det eq 'wfc' then sxaddpar,hdr,'chip',long(chip)
	endelse        					; end CCD unused section
sxaddhist,'Flat made by FLATS.PRO-rcb '+!stime,hdr

; double checking flats for zero 01jul10
bad=where(flat le 0,nbad)
if nbad gt 0 then flat(bad)=1
if nbad gt 0 then err(bad)=1
if nbad gt 0 then eps(bad)=512          ; dead detector element
return
end
