FUNCTION INTEGRAL,X,Y,XMIN,XMAX
;
;+
;			integral
;
; Routine to perform trapezoidal integration in X,Y between limits
; xmin to xmax.
;
; CALLING SEQUENCE:
;	result = integral(x,y,xmin,xmax)
;
; INPUTS:
;	x,y - vectors to be integrated
;	xmin,xmax - vectors with lower and upper integral limits
; OUTPUTS:
;	the integrations between xmin and xmax are returned
;	as the function result
; RESTRICTIONS:
;	The values in XMIN must be greater than or equal to the minimum
;	of X. The values in XMAX must be less than or equal to the 
;	maximum of X. X must be in ascending order.
;
; HISTORY:
;	Version 1,  D. Lindler  (a long time ago)
;	Version 2,  JKF/ACC	28-jan-1992	- moved to IDL V2.
; 	Version 3,  DJL 	17-jun-1992	- FIXED BUG AT ENDPOINTS
;	version 4,  DJL		27-Jul-1992	- fixed previous change to
;						  work with vector inputs
;	DJL Aug, 1996 corrected to work with arrays longer than 32767 points
;	DJL Aug, 1997 corrected to work with input x vector that has
;		duplicate wavelengths (i.e. 0.0 wavelength increments)
;-
;------------------------------------------------------------------
;
; COMPUTE INDEX POSITIONS OF XMIN,XMAX
;
TABINV,X,XMIN,RMIN
TABINV,X,XMAX,RMAX
n = n_elements(x)
;
; CHECK FOR VALID LIMITS
;
DX=SHIFT(X,-1)-X
; 97aug15 - rcb addition to trap bad wl scales.
;bad=where(dx eq 0,nbad)
;if nbad gt 0 then begin
;	print,'BAD WL scale. Some delta lam are zero. Stopping'
;	stop
;	endif
A=MAX(XMIN)>MAX(XMAX)
B=MIN(XMIN)<MIN(XMAX)
D=MIN(XMAX-XMIN)
IF (A GT MAX(X)) OR (B LT MIN(X)) OR (D LT 0.0) THEN $
  message,'INVALID INTEGRAL LIMITS SUPPLIED TO INTEGRAL FUNCTION'
;
; COMPUTE DIFFERENCES IN X AND Y
;
DX=SHIFT(X,-1)-X
DY=SHIFT(Y,-1)-Y
;
; COMPUTE INTEGRALS FOR EACH FULL INTERVAL IN X
;
DINT=(SHIFT(Y,-1)+Y)/2.0*DX
;
; COMPUTE FULL INTERVALS TO INTEGRATE BETWEEN
;
IMIN=long(RMIN)
IMAX=long(RMAX)
;
; COMPUTE FUNCTION VALUES AT XMIN AND XMAX
;                                                 
DXMIN=XMIN-X(IMIN)
YMIN=Y(IMIN)+DXMIN*(Y(IMIN+1)-Y(IMIN))/(DX(IMIN)+(dx(imin) eq 0))
DXMAX=XMAX-X(IMAX)
YMAX=Y(IMAX)+DXMAX*(Y((IMAX+1)<(n-1)) - Y(IMAX))/(DX(IMAX)+(dx(imax) eq 0))
;
; COMPUTE INTEGRAL FROM IMIN TO IMAX
;
NOUT=N_ELEMENTS(XMIN)
INT=FLTARR(NOUT)
FOR I=0L,NOUT-1 DO BEGIN
	IF IMAX(I) NE IMIN(I) THEN INT(I)=TOTAL(DINT(IMIN(I):IMAX(I)-1))
;print,i,Imax(i),imin(i),int(i)
END
;
; SUBTRACT INTEGRAL FROM IMIN TO RMIN
;
INT=INT - (Y(IMIN)+YMIN)/2.*DXMIN
;
; ADD INTEGRAL FROM IMAX TO RMAX
;
INT=INT + (Y(IMAX)+YMAX)/2.0*DXMAX
RETURN,INT
END
