Function WSTDEV, Array,wgt,Mean,errmean
;
;+
; NAME:  WSTDEV
;
; PURPOSE:
; Compute the weighted standard deviation and, optionally, the
; mean of any array like stdev where the wgt=1 for all the array values.
;
; CALLING SEQUENCE:
; Result = WSTDEV(Array,wgt, [, Mean],errmean)
;
; INPUTS:
; Array:  The data array.  Array may be any type except string.
; wgt:	  The relative weights, eg exposure time or 1/sigma^2, in general.
;
; OUTPUTS:						    
; WSTDEV returns the standard deviation s (rms sample variance).
; 	The result is an unbiased estimate, because the divisor is analogous to
;	using N-1 in stdev.pro).
; MEAN optional weighted mean of array
; ERRMEAN optional error-in-the-mean = std dev of the mean
;
; FORMULA: s^2= V1 * sum{wgti(xi-mean)^2}/(V1^2-V2)
;	 where V1=sum{wgti} and V2=sum{wgti^2} Ref: Wikipedia.
;	ERRMEAN^2 = 1/sum(wgti)
;
; MODIFICATION HISTORY: 				    
; RCB STScI, Dec. 2013.
; rcb - 2014Jan add errmean to output options
;2014nov11-norm wgt to max wgt * then mult by wstdev to get errmean, eg n exp=2s
;	for alvsacs.pro in photom
;-
on_error,2		  ;return to caller if error
n = n_elements(array)	  ;# of points.
if n le 1 then message, 'Number of data points must be > 1'
;
mean = total(wgt*array)/total(wgt)
; orig: v1=total(wgt)
; orig: v2=total(wgt^2)
; orig: errmean=sqrt(1./v1)
; orig: return,sqrt(v1*total(wgt*(array-mean)^2)/(v1^2-v2))
norwgt=wgt/max(wgt)
v1=total(norwgt)
v2=total(norwgt^2)
wstdev=sqrt(v1*total(norwgt*(array-mean)^2)/(v1^2-v2))
errmean=sqrt(1./v1)*wstdev			;works for 10 equal exp times...
return,wstdev
end
