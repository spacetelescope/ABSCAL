pro plstack,wratio,ratio,TITLES,S_TO_N,dely
;
;+
;		PLSTACK
;
; procedure to plot signal to noise
;
; CALLING SEQUENCE:
;	plstack,wratio,ratio,s_to_n,TITLES,dely
;	SEE WD SUBDIRECTORY FOR VERSION THAT DIVIDES BY A FLAT FIELD SPECTRUM
; INPUTS:
;	wratio - wavelength vectors
;	ratio - ratio vectors (raw data/signal)
;
; OPTIONAL INPUTS:
;	titles - string arrar of plot titles.  If not supplied no
;		titles will be printed
;	s_to_n - vector with estimated signal to noise for the region.
;		if not supplied or set to all zeros the s/n will not
;		be printed
;	dely - tick mark spacing (default=.1)
;
; You may optionally supply your own !ytitle.  If not supplied,
; the default is 'RATIO TO SMOOTH FIT'
;
; IF !PSYM IS 0 IT WILL BE SET TO -8.  IF you really want 0 then
;	set !psym to 99
;
; HISTORY
;	Aug 26, 1988  added filled box symbol (pbox)
;		To use the filled box set !psym to -8
;	Sept 1, 1988 allows S_TO_N to be zeros (and not printed)
;		This makes ratstack obsolete. added !psym=99
;-
;---------------------------------------------------------
pbox,2			;create a box of size 2
if n_params(0) lt 3 then titles=strarr(1,20)
if n_params(0) lt 4 then s_to_n=fltarr(20)
if n_params(0) lt 5  then dely=0.1
YTITLE=!YTITLE
IF STRTRIM(YTITLE) EQ '' THEN !YTITLE='RATIO TO SMOOTH FIT'
s=size(ratio)
if s(0) ne 2 then begin
	print,'RATIO must be a 2-D array'
	return
end
n=s(2)			;number of ratio vectors
;
; extract wavelengths (use only ones greater than zero
;
w=wratio(*,0)
w=w(where(w gt 0))
;
; set up some plotting parameters
;
set_viewport,0.1,0.9,0.1,0.9
!ymin=1-2.0*dely
!ymax=!ymin+n*4*dely
zero=w*0
!fancy=4
!xtitle='WAVELENGTH (A)'
;!MTITLE=''

savepsym=!psym
CASE !PSYM OF
	0: !PSYM=-8
	99: !PSYM=0
	ELSE: !PSYM=!PSYM
ENDCASE

psym=!Psym
!Psym=0 & plot,w,zero+!ymin,ytickname=replicate(' ',n*4+1),ystyle=1
!psym=psym
plotdate,'PLSTACK'
;
wmin=!cxmin
wmax=!cxmax
xpos=wmin-(wmax-wmin)/20
xpos2=wmin+0.8*(wmax-wmin)
!c=0
for i=0,n-1 do begin
  w=wratio(*,i)
  w=w(where(w gt 0))
  rr=ratio(*,i)+(n-1-i)*4*dely
  oplot,w,rr
;
; write signal/noise
;
  !Psym=0 & oplot,[!cxmin,!cxmax],(n-1-i)*4*dely+1.0+zero 
			 !psym=psym
  if s_to_n(i) gt 0 then xyouts,xpos2,4*dely*(n-1-i)+1+dely*1.4,'S/N = '+ $
		string(s_to_n(i),'(f5.1)'),size=1.4
;
; write TITLES
;
  xyouts,wmin+0.1*(wmax-wmin),4*dely*(n-1-i)+1+dely*1.4,TITLES(I),size=1.4
;
; label yticks
;
  xyouts,xpos,1.0+i*4*dely-dely/10.0,'1.0',size=1.4
  xyouts,xpos,1+dely+i*4*dely-dely/10.0,string(1+dely,'(f3.1)'),size=1.4
  xyouts,xpos,1-dely+i*4*dely-dely/10.0,string(1-dely,'(f3.1)'),size=1.4
endfor
!YTITLE=YTITLE
!psym=savepsym
return
end
