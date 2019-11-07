FUNCTION GSMOOTH,IN,SIGMA
;+
;		GSMOOTH
;
; Perfrom Gaussian smoothing out to 3 sigma
;
; RESULT = gsmooth(in,sigma)
;
; 	in - input vector
;	sigma - sigma of gaussian
;
; D. Lindler  Aug 1, 1991 
;-
	nsig = 3		;number of sigma to go out

	n = fix(sigma*nsig*2+1)
	n = (n/2*2)+1		;make it odd
	n2 = n/2		;center of gaussian
	gauss,findgen(n),float(n2),sigma,1.0,psf
	psf = psf/total(psf)
	return,convol(in,psf)
end
