pro wlover,w,i
;+
; wlover,w,i
;-
;91dec12-set first 20 lines of image to 100000 at even 100A wl values
iwl=indgen(23)*100+1100
tabinv,w,iwl,index
i(fix(index+.5),0:19)=100000
end
