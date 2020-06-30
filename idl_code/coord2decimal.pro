; 2020Apr22 - convert sexigesimal coord to decimal
;-

; from acsisr/sbc/ngc6681coord.avila
ra=[18,43,13.3192,			$	; ngc6681 A = 1
    18,43,13.1651,			$	; ngc6681 B = 2
    18,43,13.0412,			$	; ngc6681 C = 3
    18,43,12.8932,			$	; ngc6681 E = 4
    18,43,12.8715,			$	; ngc6681 F = 5
    18,43,12.7547,			$	; ngc6681 G = 6
    18,43,12.6390,			$	; ngc6681 H = 7
    18,43,12.2782,			$	; ngc6681 I = 8
    18,43,12.1987,			$	; ngc6681 J = 9
    18,43,12.1461,			$	; ngc6681 K = 10
    18,43,12.0486,			$	; ngc6681 L = 11
    18,43,11.9016]				; ngc6681 M = 12

dec=[-32,17,25.358,			$	; ngc6681 A = 1
     -32,17,25.821,			$	; ngc6681 B = 2
     -32,17,25.407,			$	; ngc6681 C = 3
     -32,17,26.428,			$	; ngc6681 E = 4
     -32,17,26.556,			$	; ngc6681 F = 5
     -32,17,25.692,			$	; ngc6681 G = 6
     -32,17,27.089,			$	; ngc6681 H = 7
     -32,17,27.509,			$	; ngc6681 I = 8
     -32,17,27.106,			$	; ngc6681 J = 9
     -32,17,26.584,			$	; ngc6681 K = 10
     -32,17,27.520,			$	; ngc6681 L = 11
     -32,17,27.909]			 	; ngc6681 M = 12
     
ra=reform(ra,3,12)
dec=reform(dec,3,12)

nstar=n_elements(ra(0,*))
for istr=0,nstar-1 do begin
	radec=ten(ra(*,istr))*15				; decimal
	decdec=ten(dec(*,istr))
	print,istr,radec,decdec
	endfor

end
