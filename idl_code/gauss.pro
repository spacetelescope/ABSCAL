;***********************************************************************
;+
;*NAME:  GAUSS   
;*CLASS:
;    numerical function
;*CATEGORY:
;
;*PURPOSE:  TO CALCULATE A GAUSSIAN FUNCTION
; 
;*CALLING SEQUENCE: 
;    GAUSS,X,X0,DX,YMAX,Y
; 
;*PARAMETERS:
;    X     (REQ) (I) (0 1) (I L F D)
;          required scalar or vector containing the independent variable(s)
;
;    X0    (REQ) (I) (0)   (F D)
;          required scalar giving the center of the Gaussian function
;          This parameter must have the same units as X.
;
;    DX    (REQ) (I) (0)   (F D)
;          required scalar giving the one sigma width of the distribution
;          This parameter must have the same units as X.
;
;    YMAX  (REQ) (I) (0)   (F D)
;          the Gaussian value at the peak of the distribution
; 
;    Y     (REQ) (O) (0 1) (F D)
;          required output scalar or vector giving the calculated value
;          of the gaussian from the expression:
;          Y = YMAX * EXP (-0.5 * ((X-X0)/DX)^2)
; 
;*EXAMPLES:
;    To calculate a gaussian with center at 1545 A, sigma of 2 A, using the
;    wavelength scale derived from an IUE spectrum, with amplitude 1.0,
; 
;     GAUSS,WAVE,1545.,2.,1.0,Y
;
;*SYSTEM VARIABLES USED:
;     None
;
;*INTERACTIVE INPUT:
;     None
;
;*SUBROUTINES CALLED:
;     PARCHECK
;
;*FILES USED:
;     None
;
;*SIDE EFFECTS:
;     None
;
;*RESTRICTIONS:
;     None
;
;*NOTES:
;    Values for which (X-X0)/DX > 9 are set to zero.
;    If DX = 0, the delta function is returned.
; 
;*PROCEDURE: 
;    GAUSS is similiar to Bevingtons program PGAUSS (p.45)
;
;*MODIFICATION HISTORY:
;    Aug 19 1979  I. Ahmad  initial program
;    Jul  7 1984  RWT GSFC  updated documentation
;    Sep 25 1984  RWT GSFC  changed limit from 12 sigma to 9 sigma due to
;                           problems in WFIT. Also compiles PCHECK.
;    Apr 13 1987  RWT GSFC  add PARCHECK
;    Aug 19 1987  RWT GSFC  add procedure call listing
;    Mar  9 1988  CAG GSFC  add VAX RDAF-style prolog
;    Nov 26 1990  JKF ACC   copied to GHRS DAF
;-
;***********************************************************************
PRO GAUSS,X,X0,DX,YMAX,Y
;
;
IF N_PARAMS(0) EQ 0 THEN BEGIN
   PRINT,' GAUSS,X,X0,DX,YMAX,Y'
   RETALL & END
  IF DX NE 0 THEN BEGIN
  ARG=(ABS((X-X0)/DX)<9.)    ; set values 9 sigma to 0 to avoid trap errors
  Y=EXP(-ARG*ARG/2)*(ARG LT 9.0)
  END ELSE Y=(0.*X)*(X NE X0)+(X EQ X0)
                        ; IF DX EQ 0 RETURN DELTA FUNCTION
Y=Y*YMAX
RETURN
END
                                                  
