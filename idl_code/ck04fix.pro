pro ck04fix,wck04,flux,wnew,fnew
; Interpolate in castelli & kurucz 2004 WL grid to fill in gaps at WL > 10mic
; INPUT - wck04,flux Original 
; OUTPUT - interpolated for new WL and flux values
; 09nov16-fitting a Planck function might fix the 0.4% interpol
;	problem from 10-20mic. The diff w/ Rayleigh-Jeans is ~.3%
; 09may4
;-
;	Subject: 	Re: interpolation of Kurucz models
;	Date: 	November 21, 2009 12:06:57 AM EST
;	From: 	  jamieson@astro.berkeley.edu
;	To: 	  bohlin@stsci.edu

; try: linear interpolation in lambda^4*F(lambda).  cheers, martin


worig=wck04  &  forig=flux	     ; in case wnew or fnew is input on the call
; 2500A spacing is not fine enough for R=100 (ie 1000A @ 10mic)
; 09oct19-wnew=[findgen(40)*2500+102500,findgen(40)*5000+205000]  ;102500-400000
; Try 500,1000A spacing to ~correspond to 400A CK04 spacing at 10-40mic 
wnew=[findgen(200)*500+100500,findgen(200)*1000+201000]		  ; Ang 09oct19
linterp,alog10(worig),alog10(forig),alog10(wnew),flog
fnew=10^flog
good=where(worig le 100200.)
wnew=[worig(good),wnew]  &  fnew=[forig(good),fnew]
print,'CK04 wavelength gaps interpolated'
end
