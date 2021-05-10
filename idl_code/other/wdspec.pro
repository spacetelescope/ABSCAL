pro wdspec,teff=teff,logg=logg,nfreq=nfreq,                      $
    lte=lte,nlte=nlte,full=full,                                 $
    flags=flags,inpmod=inpmod,                                   $
    name1=name1,name2=name2,                                     $
    DIRTLU=DIRTLU,TLUSTY=TLUSTY,DIRDAT=DIRDAT,                   $
    DIRSYN=DIRSYN,SYNSPEC=SYNSPEC,                               $
    wstart=wstart,wend=wend,wdist=wdist,lemke=lemke,             $
    vrot=vrot,steprot=steprot,fwhm=fwhm,stepins=stepins,         $
    relative=relative,scale=scale,rv=rv,                         $
    vacuum=vacuum,observ=observ,save=save,plconv=plconv,         $
    nospec=nospec,nosyn=nosyn,model=model,                       $
    cutlym=cutlym,cutbal=cutbal,                                 $
    oplot=oplot,_extra=e
;
opl=0
isyn=0
if n_elements(vacuum) gt 0 then wend=-wend
if n_elements(wdist) eq 0 then wdist=0.1
if n_elements(nosyn) gt 0 then isyn=-1
if n_elements(oplot) gt 0 then opl=1
;
if n_elements(model) eq 0 then begin                    
  damodel,teff=teff,logg=logg,nfreq=nfreq,                $
          lte=lte,nlte=nlte,full=full,                    $
          flags=flags,inpmod=inpmod,                      $
          name1=name1,name2=name2,plconv=plconv,          $
          cutlym=cutlym,cutbal=cutbal,                    $
          DIRTLU=DIRTLU,TLUSTY=TLUSTY,DIRDAT=DIRDAT
;
  if keyword_set(nospec) then return
;
  ts=strtrim(string(fix(teff*0.01+0.01)),2)
  gs=strtrim(string(fix(logg*10+0.01)),2)
  modname='t'+ts+'g'+gs
  anm='l'
  if keyword_set(nlte) or keyword_set(full) then anm='n'
  if n_elements(lte) eq 0 and n_elements(nlte) eq 0 then anm='n'
  modn=modname+anm
  if n_elements(save) eq 0 then save=modn+'.sp'
;
  synplot,0,opl,0,atmos=modn,wstart=wstart,wend=wend,wdist=wdist,  $
      imode=2,lemke=lemke,                                         $
      vrot=vrot,steprot=steprot,fwhm=fwhm,stepins=stepins,         $
      relative=relative,scale=scale,rv=rv,                         $
      DIRSYN=DIRSYN,SYNSPEC=SYNSPEC,DIRDAT=DIRDAT,                 $
      observ=observ,save=save,_extra=e
endif else begin
;
  if model eq 'prev' or model eq 'previous' then model='tmp'
  if n_elements(save) eq 0 then save=model+'.sp'
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
print,a
    printf,lun1,a
    close,lun1
    free_lun,lun1
    a='cat tmp.flag tmpc >! tmp.flag2 ; mv -f tmp.flag2 tmp.flag'
    spawn,a
  endif
  synplot,isyn,opl,0,atmos=model,idstd=46,                         $
      wstart=wstart,wend=wend,wdist=wdist,imode=2,lemke=lemke,     $
      vrot=vrot,steprot=steprot,fwhm=fwhm,stepins=stepins,         $
      relative=relative,scale=scale,rv=rv,                         $
      DIRSYN=DIRSYN,SYNSPEC=SYNSPEC,DIRDAT=DIRDAT,                 $
      observ=observ,save=save,_extra=e
endelse
;
return
end


