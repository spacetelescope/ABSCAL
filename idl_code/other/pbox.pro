pro pbox,fill=fill,th=th

;
; routine to make (filled is default) box plotting symbol.
; 01dec31 - rewritten. Use symsiz to change size w/ plot.
;-
if keyword_set(fill) then fill = 1 else fill=0
if n_elements(th) eq 0 then th=0
usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1],fill=fill,thic=th
return
end
