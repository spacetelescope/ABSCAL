pro ck04_int, w, f, Te, g, log_z, vturb, W_INDEX = w_index,Message = message, $
            Lejeune=lejeune, lej_orig=lej_orig, alpha=alpha    
;+
; NAME:
;       ck04_int
; PURPOSE:
;       Quickly obtain a ( Kurucz model flux interpolated in temperature.
;       These program is designed for speed, since it is called many times
;       during evaluation of a star cluster evolution model.
;
;       The (default) models are extracted from the CASTELLI database which
;       contains the NEWODF opacities
; CALLING SEQUENCE:
;       ck04_int, W, F, Te, g, log_z, vturb, [ W_INDEX =, /ALPHA
;                  /LEJ_ORIG, /LEJEUNE]
;
; INPUTS:
;       W -  Wavelength(s) (A) at which to evaluate model fluxes, scalar or 
;               vector.   This parameter is ignored if the W_INDEX keyword
;               is supplied.    If values for neither W nor W_INDEX are 
;               supplied, then ck04_int uses the default wavelength grid.
;       Te - effective temperature, scalar.  A blackbody flux value is returned
;               for Te < 3500 or for Te > 50000.
;       g -  Log of the surface gravity (cm/s^2).  ck04_int will both interpolate 
;               and extrapolate in gravity.
;       LogZ - Logarithm metal abundance relative to solar.   For the default
;              Castelli database possible values are -4, -2.5, -2, -1.5, -1.0,
;              -0.5, 0.0, 0.2, or 0.5.   For LEJ_ORIG or LEJEUNE the 16 possible
;               values are  +1.0,+0.5,+0.3,+0.2,+0.1,+0.0,-0.1,-0.2,-0.3,
;               -0.5, -1.0,-1.5,-2.0,-2.5,-3.0,or -3.5 
; 07Dec18 - logZ=-4 is only for alpha-enhanced models. --Wayne
;       Vturb - Macroturbulent velocity (in km/s).    Defaults to 2 km/s, which
;               is really the only model available
;              
; OUTPUTS:
;       F -  Model (physical) flux, same number of elements as W.    To
;            convert to flux at Earth in erg cm-2 s-1 A-1, multiply by a 
;            factor of (R/d)^2 where R is the stellar radius, and d is the 
;            stellar distance.
;
; OPTIONAL KEYWORD INPUTS:
;       /ALPHA - Use  alpha-enhanced models.   This keyword is recognized 
;                only for the default CASTELLI database, because for the other 
;                databases alpha-enhanced models are not available. 
 ;       /LEJEUNE - If set, then use the empircal corrections to the Kurucz
;              models computed by Lejeune et al (1997, A&A, 125, 229)
;       /LEJ_ORIG = Contains Kurucz models for Teff > 3500 K, and the Allard & 
;             Hauschildt models for 2000 < Teff < 3200, without empirical
;             adjustments
;       W_INDEX - Vector specifying the indicies of the Kurucz wavelength grid
;               to return.    This keyword is used when speed is required
;               as it avoids interpolation onto a separate wavelength grid.
;               The procedure get_castkur04_wave can be used to obtain the Kurucz
;               wavelength grid
; OPTIONAL OUTPUT KEYWORD:
;       MESSAGE - String containing any error messages, usually indicating that
;               the supplied metallicity is unavailable
; EXAMPLE:
;       (1) Plot the model spectrum of a 8,720 K solar metallicity star with 
;       log g = 3.2 every 100 A between 1000 and 10000 A.
;
;       IDL> w = 1000 + 100*findgen(90)
;       IDL> ck04_int, w, f, 8720, 3.2, 0
;       IDL> plot, w, f,/xsty
;
;       (2) For improved speed, obtain the same spectrum but use the wavelength
;           points already in the Kurucz grid
;
;       IDL> get_castkur04_wave,w        ;Get Kurucz wavelength vector
;       IDL> index = where((w GT 1000) and (w LT 10000) )
;       IDL> w = w[index]
;       IDL> ck04_int,w,f,8720,3.2,0,w_index = index
;
; NOTES:
;     Besides the new ODF the CASTELLI models include 3 changes from the 1995
;     Kurucz models. (1) no convective overshoot is used.  
;     (2) Alpha-enhanced models are available  and (3) 
;     the solar iron abundance is set at -4.53 (0.16 dex lower than 
;     Kurucz used).        
; PROCEDURE CALLS:
;       get_castkur04_wave, PLANCK(), QUADTERP
; REVISION HISTORY:
;       Written        W. Landsman           January, 1990
;       Planck function call fixed for w_index.  RSH, HSTX, 30-Nov-1993
;       Replace call to NINT() is ROUND()    W. Landsman   HSTX  Jan 1996
;       Use default Kurucz wavelength grid if necessary, W. Landsman Aug 1996
;       Use FIND_WITH_DEF to locate files     W. Landsman   April 1997
;       Major revision, use databases, interpolate in log g   March 2002
;       Make Castelli database the default   W. Landsman   June 2006
;	Convert from kur_int to incorporate new get_castkur04_wave - RCB 08jan24
;
; RCB added doc: see also model_int.pro from DJL for 3-d interpolation
;From:   landsman@milkyway.gsfc.nasa.gov

;Also for population synthesis, the Lejeune models are more convenient with
;their inclusion of (non-Kurucz) models for 2000 < Teff <3500 K. The LEJ_ORIG
;models *are* Kurucz (ATLAS9) models for Teff >3500 K.  In fact, the Kurucz
;models in LEJ_ORIG are more up to date (1997) than what is in the Kurucz
;database (1995), since some small errors were corrected.  Lejeune then adjusted
;the Kurucz models so that the continuum colors matched observed stars -- this
;is what is in the LEJEUNE database.    In principle, one could apply the same
;correction to the CASTELLI database, but this would require comparing observed
;colors with the Castelli models and essentially redoing the work of the Lejeune
;et al (1997) paper, but now with the Castelli models.   

;One reason why one might still use the older Kurucz models (besides reproducing
;earlier results) is that they were computed at 16 metallicities rather than the
;eight computed by Castelli.     For hot (Teff >8500 K) stars the Castelli
;models differ little from the earlier Kurucz models. Also for population
;synthesis, the Lejeune models are more convenient with their inclusion of
;(non-Kurucz) models for 2000 < Teff <3500 K.
;-
; On_error,2
 message = ''

 if ( N_params() LT 5 ) then begin
    print,'Syntax - ck04_int, W ,F, Te, g, log_z, [ W_index = '
    print,'                    /Alpha, /Lejeune,/Lej_orig ]'
    return
 endif

 if (N_elements(w) EQ 0) and (N_elements(W_index) EQ 0) then get_castkur04_wave,w

 init = 0


 get_castkur04_wave,wmod
 if keyword_set(lej_orig) then dbname = 'lej_orig'
 if keyword_set(lejeune) then dbname = 'lejeune' else  $
                                dbname = 'castelli'

 case dbname of 
 'lejeune': tmin = 2000
 'castelli': tmin = 3500
 'lej_orig': tmin = 2000
  endcase

  if keyword_set(alpha) and strmid(dbname,0,8) NE 'castelli' then $ 
    message,/INF,'Warning - /ALPHA keyword ignored for ' + dbname + ' database'
; Use Planck function if out of range

 if (te LT tmin) or (te GT 50000) then begin
     if keyword_set(w_index) then begin
        f = planck(wmod(w_index),te)
     endif else begin
        f = planck(w,te)
     endelse
     return
 endif

; Select models with specified metallicity

 dbopen,dbname
 list = dbfind('log_z='+strtrim(log_z,2),/silent)
 if list[0] LE 0 then begin
     message = 'Unavailable metallicity of ' + strtrim(log_z,2)
     message,'ERROR - ' + message,/INF
     message,'Available metalicities for database ' + $
              strupcase(dbname) + ' are: ',/INF
     dbext,-1,'log_z',log_z
     log_z = log_z(uniq(log_z,sort(log_z)))
     print,log_z,f='(12f6.2)'
     return
 endif  
 if dbname EQ 'castelli' then begin
       if N_elements(vturb) EQ 0 then vturb = 2
       list = dbfind('vturb=' + strtrim(vturb,2),list,/silent)
       dbext,list,'alpha',alp
       if N_elements(alpha) EQ 0 then begin 
              good = where(strtrim(alp,2) EQ 'n')
              list = list[good]
       endif else begin 
              good = where(strtrim(alp,2) EQ 'a')
              list = list[good]
       endelse
 endif
; Find model with Teff closest to (but less than) desired Teff 

  dbext,list,'teff',tmod
 teff = where( histogram(tmod,min=0) GT 0) 
 tabinv,teff,te,index
 i1 = fix(index)
 Te1 = teff(i1)
 list = dbfind('teff='+strtrim(te1,2),list,/silent)

; Extract gravity for that temperature

 dbext,list,'log_g',gg
 ng = N_elements(gg)
 gdiff = g - gg

 if ( ng GT 1 ) then begin        ;More than 1 gravity model for that Teff?

        if g EQ gg[ng-1] then begin               ;Exact gravity match    
                dbext,list[ng-1],'flux',fmod1
        endif else if g GT gg[ng-1] then begin    ;Extrapolation to higher g
                dbext,list[ng-1],'flux',flux1
                dbext,list[ng-2],'flux',flux2
                deltag = gg[ng-1] - gg[ng-2]
                derivf = (flux1-flux2)/deltag
                fmod1 = flux1 + derivf*(g - gg[ng-1] )
        endif else if g LE gg[0] then begin       ;Truncate at lower g
                dbext,list[0],'flux',fmod1

        endif else if min(abs(gdiff)) EQ 0 then begin ;Exact g match 
                jj = where(gg EQ g)
                dbext,list[jj],'flux',fmod1
        endif else begin                             ;Interpolate in log g
                j1 = value_locate(gg,g) > 0
                j2 = j1 + 1 
                g2 = gg(j2)
                g1 = gg(j1)
                fracg = (g-g1)/float(g2-g1)
                dbext,list[j1],'flux',flux1
                dbext,list[j2],'flux',flux2
                fmod1 = (1-fracg)*flux1 + fracg*flux2
        endelse
 endif else dbext,list,'flux',fmod1                 ;Only 1 log g at that Teff
                                  ;Extract flux vector

 if keyword_set( W_index) then f = fmod1( W_index)  $
     else quadterp,wmod,fmod1,w,f     ;quadratic interpolation in wavelength
frac=0.
 if (i1 NE index) then begin          ;Interpolate in temperature?
      Te2 = teff(i1+1)      
      frac = (Te-Te1)/float(Te2-Te1)
      list = dbfind('teff='+strtrim(te2,2) + ',log_z='+strtrim(log_z,2),/silent)
      if dbname EQ 'castelli' then begin
       list = dbfind('vturb=' + strtrim(vturb,2),list,/silent)
       dbext,list,'alpha',alp
       if N_elements(alpha) EQ 0 then begin 
              good = where(strtrim(alp,2) EQ 'n')
              list = list[good]
       endif else begin 
              good = where(strtrim(alp,2) EQ 'a')
              list = list[good]
       endelse
       endif
      endif

        dbext,list,'log_g',gg
       ng = N_elements(gg)
      gdiff = g - gg

 if ( ng GT 1 ) then begin        ;More than 1 gravity model?
         if g EQ gg[ng-1] then begin               
                dbext,list[ng-1],'flux',fmod2
        endif else if g GT gg[ng-1] then begin    ;Extrapolation
                dbext,list[ng-1],'flux',flux1
                dbext,list[ng-2],'flux',flux2
                deltag = gg[ng-1] - gg[ng-2]
                derivf = (flux1-flux2)/deltag
                fmod2 = flux1 + derivf*(g - gg[ng-1] )
        endif else if min(abs(gdiff)) EQ 0 then begin
                ii = where(gg EQ g)
                dbext,list[ii],'flux',fmod2
        endif else begin
                j1 = value_locate(gg,g) > 0
                j2 = j1 + 1
                g2 = gg(j2)
                g1 = gg(j1)
                fracg = (g-g1)/float(g2-g1)
                dbext,list[j1],'flux',flux1
                dbext,list[j2],'flux',flux2
                fmod2 = (1-fracg)*flux1 + fracg*flux2
       endelse
 endif else dbext,list,'flux',fmod2

     if keyword_set( W_index) then f2 = fmod2( W_index) else $
      quadterp,wmod,fmod2,w,f2     ;Grid using quadratic interpolation
      f = f*(1-frac) + f2*(frac)

 return
 end
