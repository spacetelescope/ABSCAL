Function mode,arr

;Input:
;	arr to find the mode of, ie most common value
;History:
;	2017dec5 - Mode function that works for string arrays, as IDL has none.
;-

newarr=arr(sort(arr))
wh = where(newarr ne Shift(newarr,-1), cnt)
if cnt eq 0 then mode = newarr[0] else begin
      void = Max(wh-[-1,wh], mxpos)
      mode = newarr[wh[mxpos]]
   endelse 

return,mode
end
