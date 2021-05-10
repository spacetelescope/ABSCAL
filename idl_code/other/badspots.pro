pro badspots,hd,mask,xcen,ycen,rad
; +
;
; pro badspot,hd,mask,xcen,ycen,rad  Make mask = 0 in bad regions
;
; INPUT:
;	HD - image header
; INPUT/OUTPUT:
;	mask - predefined (often unity) image mask
; OUTPUT:
;	xcen,ycen - centers of dust motes
;	rad       - radius of motes
; HISTORY - 98JAN2 - RBOHLIN
;	99jun10 - shift STIS med disp left and add xcen,ycen to output
;	99jun21 - add WFC, rename dust.acs--> dust.hrc
;-

s=size(mask)  &  nx=s(1)-1  &  ny=s(2)-1	; max x & y pixel
det=strtrim(sxpar(hd,'detector'),2)

case det of
	'HRC':	begin
			jd=sxpar(hd,'EXPSTART')		; Julian day
			if jd lt 51083 then begin	; guess ~98sep30
				print,'Flight spare HRC. No dust flagged.'
				return  &  endif
			rdf,'dust.hrc',1,d
			s=size(d)
			rad=fltarr(s(1))+20
			end	; ACS HRC
	'WFC':	begin
			return
; needed??		rdf,'dust.wfc',1,d
;			s=size(d)
;			rad=fltarr(s(1))+20
			end	; ACS WFC

;99jun16
	'CCD':  begin  &  rdf,'dust.stis',1,d
			s=size(d)
			rad=fltarr(s(1))+12
; first 2 spots on spectrum & are small. cut size
			rad(0:1)=rad(0:1)-4
			end	; STIS 50CCD
	endcase

xcen=d(*,0)  &  ycen=d(*,1)
; 99jun10 - shift stis medium disp spots left
if strpos(sxpar(hd,'opt_elem'),'M') gt 0 then begin
	print,'STIS Med Disp. Shift badspots left.'
	xcen=xcen-2
	rad=rad*0+16
	rad(0:1)=rad(0:1)-4	; 1st 2 spots on spectrum & are small. cut size
	endif
radsq=rad^2
for i=0,n_elements(xcen)-1 do begin
	for j=0,rad(i) do begin		; 2*rad+1 lines total get some flags
		dist=fix(sqrt(radsq(i)-j^2)+.5)
		xmn=xcen(i)-dist  &  if xmn lt 0 then xmn=0
		xmx=xcen(i)+dist  &  if xmx gt nx then xmx=nx
		yrow=ycen(i)-j    &  if yrow lt 0 then yrow=0
		mask(xmn:xmx,yrow)=0
		yrow=ycen(i)+j    &  if yrow gt ny then yrow=ny
		mask(xmn:xmx,yrow)=0
		endfor
	endfor
end
