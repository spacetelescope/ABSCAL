pro cirflx,im,xc,yc,rmean,PROF,rflux,tflux,keep=keep,disable=disable,  $
           binnum=binnum,notrunc=notrunc,px=px
;+
;
; CALLING SEQUENCE:
;      	cirflx,file,xcenter,ycenter,rmean,profile,rflux,tflux
; DESCRIPTION:
;	Measures the fluxes contained within circular apertures about a common
;       center (xc,yc) by calling NEKDAP.PRO.
; INPUT
;	im               - IDL 2-D array containing image
;       xcenter,ycenter  - center of object in pixels
;	rflux - If keyword /px, outer radii of annuli; must have constant 
;								increment.
; OUTPUT:
;	rmean - mean radius of each of BINnum annuli
;             - if /px used, then rmean = rflux-increment/2
;	profile  - vector of surface brightness w/i each annulus, wrt RMEAN
;	rflux - If no /px, outer radii of annuli. (default 1-26?)
;       tflux - total energy w/i each RFLUX annulus
;
;       ****** NOTE ESPECIALLY: DIFF RADII FOR PROF AND TFLUX *****
;
; KEYWORDS:
;	keep    - keeps image window after routine finishes.
;       disable - does not display image/annuli at all.
;       binnum  - changes no. of annuli (default=26)
;       px      - use the pixel array RFLUX  as the specified annuli radii
;       notrunc - original binnum used (default -> deletes superfluous zero
;		  values from NEKDAP tflux output.Truncation warning is printed)
;
; HISTORY:
;  93jan30 - to find enclosed energy in circular annuli in an image - RCB
;  93feb16 - added /KEEP & /DISABLE keywords			    - EV
;  93feb25 - added /BINNUM keyword				    - EV
;  93mar4  - added rflux, tflux, and /px keyword                    - rcb
;  93MAR15 - CHANGE FROM DIST_CIRCLE TECHNIQUE TO NEKDAP (UIT_APER)
;		 FOR MORE EXACT CALC FOR SMALL RADII                - RCB
;  93Mar18 - LINE 61:  Included offset of 1.6, because of the way NEKDAP
;                      calculates EDGE array - 1.5 is not good
;                      enough because of round-off errors between
;                      between RFLUX in this routine and EDGE in NEKDAP. - EV
;  93Jul16 - Truncate NEKDAP output of tflux containing zero values      - EV
;          - added /NOTRUNC keyword to keep binnum constant
;  96JUL25 - CONVERT TVSCL TO TV, AS TVSCL FOULS UP ON POSTSCRIPT OUTPUT - RCB
;-
;-----------------------------------------------------------------------------
;						; check # of parameters
if (n_params(0) eq 0) then begin
  print,'CALLING SEQUENCE: cirflx,im,xcenter,ycenter,radius,profile'
  print,'        KEYWORDS: keep,disable,binnum,px'
  retall
endif
;
if (not keyword_set(binnum)) then binnum=26	; set # of annuli (i.e. bins)
;
siz=size(im)
scl=513./siz(1)	; 96jul29-increase from 512 to have odd # px for centering-rcb
siz2=fix(siz(2)*scl+.5)
;
if (not keyword_set(disable)) then begin	; window for image
;  device,window_state=opn
;  for i=0,15 do if opn(i) eq 0 then win_prof=i	
;  chan,win_prof
 if !d.name eq 'X' then window,15,xs=513,ys=513	;96jul24-rcb
;  ctv,.................			; no good for postscript!
						; Must define data coord for PS
  plot,[0,513],[0,513],xsty=5,ysty=5,/nodata,posit=[0.,0.,1,1]
  fbyt=alog10(im>1)
; scale image for display, based on 255=1.2*local max to keep max from satura.:
  fbyt=!d.n_colors-bytscl(fbyt,min=0,max=fbyt(xc,yc)*1.2,top=!d.n_colors-1)-1
  imout=congrid(fbyt,513,siz2)			; display size 513 x siz2
  tv,imout,/data 				; display size 513 x siz2
endif
; 						; set up the circle parameters
if (not keyword_set(px)) then begin		; CALCULATE RADII
  rad=min([xc,yc,siz(1)-xc,siz(2)-yc])		; back off by 1.6px (deleted)
;rad=min([xc,yc,siz(1)-xc,siz(2)-yc])-1.6
;					
  inc=rad/float(binnum)
  rmean=fltarr(binnum)
  RMEAN=inc*indgen(binnum)+inc/2.		; for Surf. Bri. profile
  rflux=inc*indgen(binnum)+inc			; for energy profile
end else begin					; USER-SPECIFIED rflux & BINS
  bsiz=size(rflux)
  binnum=bsiz(1)
  rad=rflux(binnum-1)
  inc=rflux(1)-rflux(0)
  rmean=rflux-inc/2.				
endelse
if (min(rflux) le 0) or (min(rmean) le 0) then begin
	print,'STOP IN CIRFLX. all radii must be gt 0. rflux=',rflux,   $ 
						      'rmean=',rmean
	stop
	endif
;
print,'max circle radius=',rad,'px to divide into',binnum,' bins'
;
for i=0,binnum-1 do begin			; overplot annuli over image
  if (not keyword_set(disable)) then $
    tvcircle,rflux(i)*scl,xc*scl,yc*scl,thick=1,/data,color=0
  endfor
;
prof=fltarr(binnum)				; define output arrays
tflux=prof
;						; AREA per circle,radius=rflux
NUMPX= lonARR(binnum)+3.14159*RFLUX^2		; since we have >32767 px
;						; Use UIT software
NEKDAP,im,XC,YC,TFLUX,D1,D2,D3,1,RFLUX,[10,15],[-1E30,1e30],  $
			SETSKYVAL=[0,1,100],/SIL
;						; 93Jul16-EV Remove zeros from
;						;   NEKDAP output.

ngood=where(tflux ne 0.0) & good=max(ngood)
if ( good lt binnum-1 ) then begin
  print,' Cumulative flux from NEKDAP.PRO zero towards end of array. '
  if ( not keyword_set(notrunc) ) then begin
    print,' Truncating zero values from NEKDAP output array .....'
    binnum=good+1
    print,' BINNUM = ',binnum
    rflux=rflux(0:binnum-1) & rmean=rmean(0:binnum-1)
    prof=prof(0:binnum-1) & tflux=tflux(0:binnum-1)
  endif else begin
    print,' NOTRUNC keyword set - BINNUM remains unchanged'
  endelse
endif
;
prof(0)=TFLUX(0)/numpx(0)			; calculate flux/annulus
for i = 0,binnum-1 do begin
  if i gt 0 then prof(I)=(TFLUX(I)-TFLUX(I-1))/(NUMPX(I)-NUMPX(I-1))
endfor
;						; display options
if ((keyword_set(keep)) or (keyword_set(disable))) then goto,SKIP
cdel,win_prof
SKIP:
return
end
