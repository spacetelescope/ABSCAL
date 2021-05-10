pro okefix,hdr,wl,stat,qual
;+
;
; 00jun1 - fix oke (1990) stat err and data qual flag
; Input: wl,stat,qual
; Output: fixed stat,qual
;-

; change 99x statistical err to more realistic 10%. Oke (1990) has stat=0 here.
indx=where(stat eq 99,n99)
if n99 gt 0 then stat(indx)=0.1

; set qual=0 in artifact regions. See Oke(1990) in stds folder and stds.paper
indx=where((wl ge 4664.3 and wl le 4749.3) or (wl ge 4901.4 and wl le 4946.4)  $
	or (wl ge 5151.4 and wl le 5211.5) or (wl ge 6847.9 and wl le 6951.9)  $
	or (wl ge 7152   and wl le 7252  ) or (wl ge 7552.1 and wl le 7692.1)  $
	or (wl ge 8152   and wl le 8252  ) or (wl ge 8800))
qual(indx)=0

; ~3200-3400A air problems:
indx=where(strpos(hdr,'OKE DBSP') ge 0)  &  indx=indx(0)
if indx gt 0 then begin
	str=hdr(indx)
        okecut=gettok(str,' ')
        okecut=float(gettok(str,'.0'))
	indx=where(wl ge okecut and wl le 3400)
	stat(indx)=0.2				; per Oke(1990)
	qual(indx)=0
	endif
print,'OKEFIX.pro set flags for up to 9 artifact regions'
end
