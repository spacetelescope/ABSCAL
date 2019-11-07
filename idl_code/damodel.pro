pro damodel,teff=teff,logg=logg,nfreq=nfreq,                $
            lte=lte,nlte=nlte,full=full,                    $
            flags=flags,inpmod=inpmod,plconv=plconv,        $
            name1=name1,name2=name2,                        $
            cutlym=cutlym,cutbal=cutbal,                    $
            DIRTLU=DIRTLU,TLUSTY=TLUSTY,DIRDAT=DIRDAT
;
;  Input keyword parameters:
;
;  teff     - T_eff [K]
;  logg     - log g [cgs]
;  nfreq    - number of frequencies in continua (default 200)
;  lte      - if set, computes an LTE model 
;  nlte     - if set, computes NLTE model
;  full     - if set, computes the whole sequence LTE-grey -> LTE ->NLTE
;  flags    - non-standard flags for Tlusty (see Tlusty Guide);
;             default='ND=100,TAULAS=4091,NFTAIL=81,DFTAIL=0.07' -- 
;             i.e. 100 depths; last depth at tau_ross=4091;
;             number of frequencies at high-frequency tail 
;             Lyman continuum in this case) = 81, and half of those
;             points concentrated close to the Lyman limit, within
;             0.07 of the difference (\nu_max - \nu_Ly),
;             where \nu_max$ is the maximum frequency (set up
;             automatically by TLUSTY).
;  inpmod   - a core name of the input model (needed only if keywords 
;             lte or nlte are set)
;  name1    - string with a prefix model name (if missing, DAMODEL
;             will assign the name, e.g. for teff=60000, logg=8, as
;             't600g80*', where *='l' for LTE model; *='n' for NLTE
;             model, and *='l0' for initial LTE model without lines)
;             if name1 is set, e.q.name1='a', then the core name will
;             be 'at600g80*'
;  name1    - analogous, but for a postfix
;  DIRTLU   - directory, where Tlusty is stored;
;             default: DIRTLU='~/synsplib/tlusty200/' 
;  TLUSTY   - the actual name of the TLUSTY executable
;             default: TLUSTY='tlusty203' 
;  DIRDAT   - directory where the hydrogen atomic data file 'h1s.dat'
;             (and also necessary atomic data files - Lemke line
;             broadenieng tables) are stored;
;             default: DIRDAT='~/synsplib/data/'

; ---------------------------------------------------------------------
;
; Note: the user may easily change a definition of DIRTLU, TLUSTY, and
;       DIRDAT in order to avoid an explicit coding of the parameters
;       in every run. The definitions are the first executive commands.
;
; Example: to compute a NLTE model for Teff=60,000 K, log g = 8, and
; if one has directory ~/synsplib/ and subdirectories as indicated
; above, one issues a command:
;
; IDL> damodel,teff=60000,logg=8,/full
;
; if one uses tlusty, version 198, stored in the current directory,
; and one copied file h1s.dat to directory '~/data', then one codes
;
; IDL> damodel,teff=60000,logg=8,/full,DIRTLU='./',TLUSTY='tlusty198',$
;              DIRDAT='~/data/'
;----------------------------------------------------------------------------
;
;
if n_elements(DIRTLU) eq 0 then DIRTLU='~/synsplib/tlusty/'
if n_elements(TLUSTY) eq 0 then TLUSTY='tlusty203'
if n_elements(DIRDAT) eq 0 then DIRDAT='~/synsplib/data/'
;
ts=strtrim(string(fix(teff*0.01+0.01)),2)
gs=strtrim(string(fix(logg*10+0.01)),2)
modname='t'+ts+'g'+gs
;
if n_elements(name1) gt 0 then modname=name1+modname
if n_elements(name2) gt 0 then modname=modname+name2
if n_elements(nfreq) eq 0 then nfreq=200
;
if n_elements(inpmod) ne 0 then begin
  a='/bin/cp -f '+inpmod+' fort.8'
  spawn,a
  grey=0
endif else grey=1
;
if n_elements(flags) eq 0 then $
  flags='ND=100,TAULAS=4091.6,NFTAIL=81,DFTAIL=0.07,IHYDPR=1'
;
close,1
openw,1,'tmp.flag'
printf,1,flags
close,1
;
  if n_elements(cutlym) gt 0 then begin
    get_lun,lun1
    openw,lun1,'tmpc'
    a='CUTLYM='+strtrim(string(cutlym),2)
    printf,lun1,a
    close,lun1
    free_lun,lun1
    a='cat tmp.flag tmpc >! tmp.flag2 ; mv -f tmp.flag2 tmp.flag'
    spawn,a
  endif
  if n_elements(cutbal) gt 0 then begin
    get_lun,lun1
    openw,lun1,'tmpc'
    a='CUTBAL='+strtrim(string(cutbal),2)
    printf,lun1,a
    close,lun1
    free_lun,lun1
    a='cat tmp.flag tmpc >! tmp.flag2 ; mv -f tmp.flag2 tmp.flag'
    spawn,a
  endif
;
if n_elements(full) gt 0 then nmod=3 else nmod=1
for imod=1,nmod do begin
;
if n_elements(lte) gt 0 then lablt='  T  ' else lablt='  F  '
if grey gt 0 then labgr='  T  ' else labgr='  F  '

if nmod eq 3 and imod eq 1 then lablt='  T  '
if nmod eq 3 and imod eq 1 then labgr='  T  '
if nmod eq 3 and imod eq 2 then lablt='  T  '
if nmod eq 3 and imod eq 2 then labgr='  F  '
if nmod eq 3 and imod eq 3 then lablt='  F  '
if nmod eq 3 and imod eq 3 then labgr='  F  '
;print,nmod,imod,lablt,labgr
;
openw,1,'tmp.5'
;
printf,1,teff,logg
printf,1,lablt,labgr
printf,1,' ''tmp.flag'' '
printf,1,nfreq
;
printf,1,'*'
printf,1,'* data for atoms' 
printf,1,'*'
natom=1
printf,1,natom
printf,1,'* mode abn modpf'
printf,1,'    2   0   0'
printf,1,'*'
printf,1,'*iat iz nlv ilst ilvln nonst typion filei'
printf,1,'*'
;ad=DIRDAT
ad=''
a=' 1  0  9  0  0  0  '+''' H 1'' '''+ad+'h1s.dat'''
if nmod eq 3 and imod eq 1 then $
a=' 1  0  9  0 20  0  '+''' H 1'' '''+ad+'h1s.dat'''
printf,1,a
printf,1,' 1  1  1  1  0  0  '' H 2'' '' ''
printf,1,' 0  0  0 -1  0  0  ''    '' '' '''
close,1
;
anm='l'
if nmod eq 3 and imod eq 1 then anm='l0'
if keyword_set(nlte) or imod eq 3 then anm='n'
if n_elements(lte) eq 0 and n_elements(nlte) eq 0 and nmod eq 1 then $
  anm='n'
modn=modname+anm
a='/bin/cp -f tmp.5 '+modn+'.5'
spawn,a 
if n_elements(inpmod) gt 0 then begin
 print,'compute model  ',modn,'   starting from  ',inpmod
endif else begin
  if labgr eq  '  T  ' then $
  print,'compute model  ',modn,'   from scratch' else $
  print,'compute model  ',modn,'   from previous' 
endelse
;
   al='ln -s '+DIRDAT+'h1s.dat .'
   spawn,'/bin/rm -f h1s.dat; '+al
   al='ln -s '+DIRDAT+'lemke.dat .'
   spawn,'/bin/rm -f lemke.dat; '+al
;
atl=DIRTLU+TLUSTY
;a='/home/hubeny/tlusty200/tlusty200  <'+modn+'.5 >! '+modn+'.6'
a=atl+' <'+modn+'.5 >! '+modn+'.6'
spawn,a
a='/bin/cp -f fort.7 '+modn+'.7; /bin/cp -f fort.9 '+modn+'.9'
spawn,a
a='/bin/cp -f fort.69 '+modn+'.69; /bin/cp -f fort.13 '+modn+'.13'
spawn,a
spawn,'/bin/cp -f fort.7 fort.8; /bin/cp -f fort.7 tmp.7'
;
reltot1,niter,chmax
if chmax gt 1.e-3 and chmax lt 1. then $
print,'WARNING!!! MODEL ATMOSPHERE ',modn,' IS NOT FULLY CONVERGED'
if chmax gt 1  then $
print,'WARNING!!! MODEL ATMOSPHERE ',modn,' DID NOT CONVERGE!'
;
if keyword_set(plconv) then relc7a,modn
;
endfor
return
end


