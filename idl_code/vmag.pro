function vmag,starin,ebv,spty,bvri,teff,logg,logz,normfac,cohen=cohen,	$
	model=model
;+
; PURPOSE:
;	return the stellar V mag, if any. Otherwise return zero.
; CALLING SEQUNCE:
;	V=vmag('G191b2b')
; Inputs:
;	starin - name
;	cohen - Keyword for cohen stellar parameters
;	model - Keyword ='marcs' for marcs models of Gtype stars. Otherwise CK04
;			mz for meszaros, lanz for Lanz & Hubeny OB grid.
;			hubeny or rauch for hot pure hyd WD grid
; -->KEEP values here off grid edges by 0.2 in log g, etc.
; OUTPUT:
;	The Vmag
;	ebv - E(B-V) reddening in mag
;	spty - Spectral Type
;	bvri - vector of cohen mags B,V,R,I from MHO
;	teff - effective temperature
;	logg-  log of gravity
;	logz - log of metallicity... default -1 for now
; HISTORY
;	06mar28 - rcb
;	07jan16 - rcb add E(B-V) and Sp Type
;	07nov12 - New E(B-V) from cohen.photom file B & V + Landolt-Bernstein
;	07nob18 - add BVRI cohen photom from calib/aktype/cohen.photom
;	07nov23 - add 2 MASS JHK
;	07dec18 - switch V & JHK to pure Maiz zero points.
;	08mar11 - add cohen keyword for cohen params
;	09feb23 - add P stars and model keyword
;	09dec15 - update-tweak 7 gstar params
;	10jan07 - put G191 vmag back to Landolt value of 11.781 & vega to .031
;	11nov29 - add new JWST stars
;	12may17 - swap E(B-V) & log z to match findmin.pro output table
;	13sep   - New Rauch cal.
;	14mar7  - add results for mz=meszaros grid.
;	18Oct11 - read stisonly input to get normalization factors for models.
;-

vmag=0.  &  spty=''
bvri=[0.,0.,0.,0.,0,0,0]
teff=0.  &  logg=0  &  logz=0  &  ebv=0  &  normfac=0
star=starin						; preserve starin
star=gettok(star,'.')  &  star=gettok(star,'_')		; 08dec4-elim _ in name
star=strupcase(star)
if strpos(star,'SUN') ge 0 then star='SUN'
if strpos(star,'TARGET') eq 0 then star=strmid(star,0,8)
if star eq 'GRW' or star eq 'AGK' then star=strupcase(starin)
if not keyword_set(model) then model='cast'

	case star of 
		'SUN':	begin
			teff=5777.  &  logg=4.44  &  ebv=0.00  &  logz=0.
			vmag=-26.7  &  spty='G2V'  &  end
		'C26202':	begin
			teff=6320  &  logg=4.6  &  logz=-0.45  &  ebv=0.073
			if model eq 'marcs' then begin
			  teff=6320 & logg=4.85  & logz=-.49  &  ebv=0.076 & end
			if model eq 'mz' then begin
			  teff=6270 & logg=4.4  & logz=-.42  &  ebv=0.064 & end
			vmag=16.64  &  spty='G'  &  end
; 2011nov29 - five new JWST G stars (HD27836 is double and BAD)
;bad		'HD27836':	begin
;bad			teff=5980  &  logg=3.90  &  ebv=0.000  &  logz=-0.06
;bad			if model eq 'marcs' then begin
;bad			  teff=6080 & logg=4.55  &  ebv=0.021  & logz=0.01 & end
;bad			vmag=7.6  &  spty='G1V'  &  end
		'HD37962':	begin
			teff=5690  &  logg=3.35  &  logz=-.41  &  ebv=0.002
			if model eq 'marcs' then begin
			  teff=5790 & logg=4.35  & logz=-0.31  & ebv=0.024 & end
			if model eq 'mz' then begin
			  teff=5740 & logg=3.8  & logz=-.19  &  ebv=0.007 & end
			vmag=7.85  &  spty='G2V'  &  end
		'HD38949':	begin
			teff=5980  &  logg=4.0  &  logz=-0.25  &  ebv=0.001
			if model eq 'marcs' then begin
			  teff=5990 & logg=4.6  & logz=-0.26  &  ebv=0.005 & end
			if model eq 'mz' then begin
			  teff=6010 & logg=4.4  & logz=-.11  &  ebv=0.002 & end
			vmag=8.0  &  spty='G1V'  &  end
		'HD106252':	begin
			teff=5820  &  logg=3.50  &  logz=-0.28  &  ebv=0.0
			if model eq 'marcs' then begin
			  teff=5810 & logg=4.2  & logz=-.27  &  ebv=0.00 & end
			if model eq 'mz' then begin
			  teff=5850 & logg=4.05  & logz=-.08  &  ebv=0.001 & end
			vmag=7.36  &  spty='G0'  &  end
		'P041C':	begin
;deliv	004		teff=5900  &  logg=4.15  &  logz=0.03  &  ebv=0.013 
;   "   005		teff=6020  &  logg=4.15  &  logz=0.07  &  ebv=0.034 
			teff=6040  &  logg=4.00  &  logz=0.05  &  ebv=0.04
			if model eq 'marcs' then begin
			  teff=6030 & logg=4.7  & logz=0.02  &  ebv=0.04 & end
			if model eq 'mz' then begin
			  teff=5950 & logg=4.2  & logz=+0.12  & ebv=0.018 & end
			vmag=12.01  &  spty='G0V'  &  end
		'P177D':	begin
;deliv	004		teff=5800  &  logg=3.80  &  logz=-.12  &  ebv=.037
;.....  005		teff=5880  &  logg=3.80  &  logz=-.11  &  ebv=.052
			teff=5880  &  logg=3.45  &  logz=-.14  &  ebv=.053
			if model eq 'marcs' then begin
			  teff=5910 & logg=4.2  &  logz=-.10 &  ebv=0.061 & end
			if model eq 'mz' then begin
			  teff=5830 & logg=3.65  & logz=-0.04  & ebv=0.038 & end
			vmag=13.48  &  spty='G0V'  &  end
		'SF1615':	begin
			teff=5880  &  logg=4.20  &  logz=-0.69  &  ebv=0.118
			if model eq 'marcs' then begin
			  teff=5860 & logg=4.85 &  logz=-.77 &  ebv=0.116 & end
			if model eq 'mz' then begin
			  teff=5790 & logg=4.60  & logz=-.63  &  ebv=0.095 & end
			vmag=16.75  &  spty='G'  &  end
		'SNAP2':	begin
			teff=5810  &  logg=4.1  &  logz=-0.28  &  ebv=0.047
			if model eq 'marcs' then begin
			  teff=5800 & logg=4.75  &  logz=-0.32 & ebv=0.048 & end
			if model eq 'mz' then begin
			  teff=5710 & logg=4.4  & logz=-.22  &  ebv=0.023 & end
			vmag=16.75  &  spty='G'  &  end
		'P330E':	begin
			teff=5900  &  logg=4.10  &  logz=-.25  &  ebv=0.049
			if model eq 'marcs' then begin
			  teff=5900 & logg=4.75  & logz=-.29  &  ebv=0.052 & end
			if model eq 'mz' then begin
			  teff=5830 & logg=4.95  & logz=-.21  &  ebv=0.027 & end
			vmag=13.01  &  spty='G0V'  &  end
		'HD159222':	begin
			teff=5790  &  logg=3.3  &  logz=-0.09  &  ebv=0.001
			if model eq 'marcs' then begin
			 teff=5780 & logg=4.1  & logz=-0.07  &  ebv=0.001 & end
			if model eq 'mz' then begin
			  teff=5820 & logg=3.75  & logz=+.13  &  ebv=0.00 & end
			vmag=6.56  &  spty='G1V'  &  end
		'HD205905':	begin
			teff=5830  &  logg=3.45  &  logz=-0.14  &  ebv=0.001
			if model eq 'marcs' then begin
			  teff=5870 & logg=4.3  & logz=-.08  &  ebv=0.011 & end
			if model eq 'mz' then begin
			  teff=5860 & logg=3.8  & logz=+.05  &  ebv=0.002 & end
			vmag=6.74  &  spty='G2V'  &  end
		'HD209458':	begin
			teff=6160  &  logg=4.05  &  logz=-0.04  &  ebv=0.017
			if model eq 'marcs' then begin
			  teff=6150 & logg=4.55 &  logz=-.07 &  ebv=0.017  & end
			if model eq 'mz' then begin
			  teff=6110 & logg=4.15  & logz=+.0  &  ebv=0.004 & end
			vmag=7.65  &  spty='G0V'  &  end
		'KF01T5': 	begin
			bvri=[14.691,13.592,13.016,12.505]
			vmag=bvri(1)  &  ebv=0.04  &  spty='K1III' & end
		'KF06T1': 	begin
			bvri=[14.442,13.419,12.862,12.334]
			vmag=bvri(1)  &  ebv=0.0  & spty='K1.5III' & end
		'KF06T2': 	begin
			teff=4600  &  logg=1.20  &  logz=-0.55  &  ebv=0.092
			if model eq 'marcs' then begin
			   teff=4560  &  logg=1.2 & logz=-.54 & ebv=0.067 & end
			if model eq 'mz' then begin
			  teff=4490  &  logg=1.5 & logz=-.26 & ebv=0.044 & end
			bvri=[15.111,13.951,13.332,12.766]
			vmag=bvri(1)  & spty='K1.5III' & end
		'KF08T3': 	begin
;BZ only chisq=0.218 2017aug
			teff=4910  &  logg=1.60 & logz=-.26 & ebv=0.037
			bvri=[14.271,13.314,12.806,12.299]
			vmag=bvri(1)  & spty='K0.5III' & end
		'G191':		begin
			teff=60920  &  logg=7.55	; Gian pure Hyd
;			vmag=11.773  &  ebv=0  &  spty='DA0'  &  end ; 10jan7
			vmag=11.781  &  ebv=0.0005  &  spty='DA0'  &  end
		'G191B2B':	begin
			teff=60920  &  logg=7.55	; Gian pure Hyd
			bvri=[11.455,11.781,11.930,12.108,12.543,12.669,12.764]
;			vmag=11.773  &  ebv=0  &  spty='DA0'  &  end ; 10jan7
			vmag=11.781  &  ebv=0.0005  &  spty='DA0'  &  end
		'GD153':	begin
			teff=40204  &  logg=7.82
			bvri=[13.060,13.349,13.484,13.526,14.012,14.209,14.308]
			vmag=13.346  &  ebv=0.0002  &  spty='DA1'  &  end
		'GD71':		begin
			teff=33301  &  logg=7.88
			bvri=[12.783,13.032,13.169,13.334,13.728,13.901,14.115]
			vmag=13.032  &  ebv=0.0001  &  spty='DA1'  &  end
; GRW is too cool & has a few % 1400A dip + other weak FUV absorp
		'GRW_70D5824':		begin		; Hubeny grid is default
			teff=20540  &  logg=7.9  &  ebv=0.0
			vmag=12.60  &  ebv=.00  &  spty='DA1'  &  end
		'WD0320':	begin
; ref?			teff=33423  &  logg=7.845
			teff=33110  &  logg=7.6
			vmag=14.948  &  ebv=0  &  spty='DA'  &  end
		'WD0947': 	begin
; ref?			teff=50787  &  logg=8.134
			teff=40020  &  logg=7.55
			vmag=15.9  &  ebv=0  &  spty='DA'  &  end
		'WD1026': 	begin
; ref?			teff=35025  &  logg=7.726
			teff=35240  &  logg=7.55
			vmag=16.13  &  ebv=0  &  spty='DA'  &  end
		'WD1057': 	begin
; ref? orig values	teff=41464  &  logg=7.898  &  ebv=.003
; vmag per makstd.pro
			teff=41010  &  logg=7.85  &  ebv=.00	; findminwd
			vmag=14.74  &  spty='DA1.2'  &  end
		'WD1657': 	begin
; ref?			teff=53011  &  logg=7.757 {ebv was 0.01) 2020feb
			teff=46110  &  logg=7.25  &  ebv=.00	; findminwd
; vmag per makstd.pro
			vmag=16.46  &  ebv=0.0  &  spty='DA1'  &  end
		'VEGA940': 	begin
			teff=9400  &  logg=3.90  &  ebv=0.0  &  logz=-0.5
			bvri=[.034,.031,.030,0.017,-.021,+.009,0]	;10jan7
			vmag=bvri(1)  &  spty='A0V'  &  end
		'VEGA955': 	begin
			teff=9550  &  logg=3.95  &  ebv=0.0  &  logz=-0.5
			if model eq 'mz' then begin
			  teff=9570.  &  logg=3.55 & logz=-.73 & ebv=0.0 & end
			bvri=[.034,.031,.030,0.017,-.021,+.009,0]	;10jan7
			vmag=bvri(1)  &  spty='A0V'  &  end
		'SIRIUS': 	begin
			teff=9850.  &  logg=4.3  &  logz=+0.4  &  ebv=0.0
			if model eq 'mz' then begin
			  teff=9820.  &  logg=3.95 & logz=+0.47 & ebv=0.0 & end
			vmag=-1.46 & spty='A1V' & end
		'10LAC': 	begin
			teff=30910.  &  logg=3.95  &  logz=0.1  &  ebv=0.077
			if model eq 'mz' then begin
			  teff=30840 & logg=3.85  & logz=-.05  & ebv=0.072 & end
			if model eq 'lanz' then begin
			  teff=32090 & logg=3.55  & logz=0.05  & ebv=0.066 & end
			vmag=4.88 & spty='O9V' & end
		'LAMLEP': 	begin
			teff=27100.  &  logg=3.9  &  logz=-0.22  &  ebv=0.006
			if model eq 'mz' then begin
			  teff=27000 & logg=3.7  & logz=-.37  &  ebv=.003 & end
			if model eq 'lanz' then begin
			  teff=27160 & logg=3.20  & logz=-.10  &  ebv=.00 & end
			vmag=4.27 & spty='B0.5IV' & end
		'HD60753': 	begin
			teff=15840.  &  logg=3.2  &  logz=-2.00  &  ebv=0.062
			if model eq 'mz' then begin
			  teff=15960 & logg=3.1  & logz=-1.4  & ebv=0.065 & end
			if model eq 'lanz' then begin
			  teff=16580 & logg=3.3  & logz=-0.60  &  ebv=.083 & end
			vmag=6.68 & spty='B3IV' & end
		'MUCOL': 	begin
			teff=30950.  &  logg=4.35  &  logz=+.32  &  ebv=0.011
			if model eq 'mz' then begin
			  teff=30960 & logg=4.05  & logz=0.07  & ebv=0.007 & end
			if model eq 'lanz' then begin
			  teff=31780 & logg=3.65  & logz=0.10  & ebv=0.00 & end
			vmag=5.15 & spty='O9.5V' & end
		'KSI2CETI': 	begin
			teff=10370.  &  logg=3.95  &  logz=-0.52  &  ebv=0.00
			if model eq 'mz' then begin
			  teff=10400 & logg=4.0  & logz=-.52  &  ebv=0.0 & end
			vmag=4.28 & spty='B9III' & end
		'HD14943': 	begin
			teff=7930  &  logg=3.9  &  logz=0.07  &  ebv=0.012
			if model eq 'marcs' then begin
			  teff=7840 & logg=3.85  & logz=+.07  &  ebv=0.002 & end
			if model eq 'mz' then begin
			  teff=7910 & logg=3.85  & logz=+0.02  & ebv=0.005 & end
			vmag=5.91  &  spty='A5V'  &  end
		'HD37725': 	begin
			teff=8380  &  logg=4.3  &  logz=-.08  &  ebv=0.045
			if model eq 'mz' then begin
			  teff=8420 & logg=4.3  & logz=-.10  &  ebv=0.047 & end
			vmag=8.35  &  spty='A3V'  &  end
		'HD116405': 	begin
			teff=10790  &  logg=4.05 &  logz=-.37  &  ebv=0.00
			if model eq 'mz' then begin
			  teff=10820 & logg=4.05  & logz=-.31  & ebv=0.00 & end
			vmag=8.34  &  spty='A0V'  &  end
		'BD60D1753': 	begin
			teff=9410  &  logg=3.90  &  logz=-.06  &  ebv=0.017
			if model eq 'mz' then begin
			  teff=9420 & logg=3.80  & logz=-.02  &  ebv=0.013 & end
			vmag=9.67  &  spty='A1V'  &  end
		'HD158485': 	begin
			teff=8640  &  logg=4.20  &  logz=-.35  &  ebv=0.052
			if model eq 'mz' then begin
			  teff=8630 & logg=4.2  & logz=-.33  &  ebv=0.047 & end
			vmag=6.50  &  spty='A4V'  &  end
		'1739431': 	begin			; Not Used
			teff=8500  &  logg=4	 &  ebv=0.079 & logz=-1.5 ;nic
			if keyword_set(cohen) then begin
			  teff=8710  &  logg=4.21  &  logz=0  &  ebv=0.10 & end
			bvri=[12.505,12.311,12.225,12.129,11.937,11.942,11.876]
			vmag=bvri(1)  &  spty='A3V'  &  end
		'1740346': 	begin			; Not Used - Dust Ring
			teff=8050  &  logg=4.0 &  logz=-1.5  &  ebv=0.032 ;nic
			if keyword_set(cohen) then begin
			  teff=8185  &  logg=4.25  &  logz=0  &  ebv=0.06 & end
			bvri=[12.678,12.478,12.381,12.271,12.079,12.022,11.996]
			vmag=bvri(1)  &  spty='A5V'  &  end
		'1812524': 	begin			;Nic only Not Used now
;			teff=8450  &  logg=4.0  & logz=-1  &  ebv=0.067 ;nic
			if keyword_set(cohen) then begin
			  teff=9397  &  logg=4.18  &  logz=0  &  ebv=0.14 & end
			bvri=[12.455,12.273,12.191,12.103,11.919,11.881,11.865]
			vmag=bvri(1)  &  spty='A1V'  &  end
		'1732526': 	begin
			teff=8670  &  logg=4.15 & logz=-.25  &  ebv=0.039
			if model eq 'mz' then begin
			  teff=8610 & logg=4.10  & logz=-.36  &  ebv=0.031 & end
			if keyword_set(cohen) then begin
			  teff=8710  &  logg=4.21  &  ebv=0.04  &  logz=0 & end
			bvri=[12.647,12.530,12.474,12.407,12.289,12.255,12.254]
			vmag=bvri(1)  &  spty='A3V'  &  end
		'1743045': 	begin
			teff=7460  &  logg=3.65 & logz=-.31 &  ebv=0.026 ;JWST
			if model eq 'marcs' then begin
			  teff=7410 & logg=3.60  & logz=-.36  &  ebv=0.020 & end
			if model eq 'mz' then begin
			  teff=7550 & logg=3.75  & logz=-.25  &  ebv=0.032 & end
			if keyword_set(cohen) then begin
			  teff=8185  &  logg=4.25  &  logz=0  &  ebv=0.14 & end
			bvri=[13.803,13.525,13.378,13.223,12.979,12.880,12.772]
			vmag=bvri(1)  &  spty='A5V'  &  end
		'HD163466': 	begin
			teff=7950  &  logg=3.75  &  logz=-0.24  &  ebv=0.031
			if model eq 'marcs' then begin
			  teff=7890 & logg=3.70  & logz=-.28  &  ebv=0.026 & end
			if model eq 'mz' then begin
			  teff=7880 & logg=3.65  & logz=-.32  &  ebv=0.018 & end
			vmag=6.86  &  spty='A2'  &  end
		'1757132': 	begin
			teff=7660  &  logg=3.8  &  logz=+.18  &  ebv=0.041
			if model eq 'marcs' then begin
			  teff=7560 & logg=3.70  & logz=+.15  &  ebv=0.029 & end
			if model eq 'mz' then begin
			  teff=7400 & logg=3.45  & logz=+.0  &  ebv=0.001 & end
			vmag=12.0  &  spty='A3V'  &  end
		'1802271': 	begin
			teff=9070  &  logg=4.0 & logz=-.47 &  ebv=0.02 ;JW
			if model eq 'mz' then begin
			  teff=9080 & logg=4.0  & logz=-.45  &  ebv=0.018 & end
			if keyword_set(cohen) then begin
			  teff=8710  &  logg=4.21  &  logz=0  &  ebv=0.0 & end
			bvri=[12.065,11.985,11.978,11.955,11.872,11.850,11.832]
			vmag=bvri(1)  &  spty='A3V'  &  end
		'1805292': 	begin
			teff=8540  &  logg=4.0 & logz=-.11  &  ebv=0.032 ;004s
			if model eq 'mz' then begin
			  teff=8570 & logg=4.0  & logz=-.07  &  ebv=0.031 & end
			if keyword_set(cohen) then begin
			  teff=9397  &  logg=4.18  &  logz=0  &  ebv=0.10 & end
			bvri=[12.413,12.278,12.230,12.164,12.039,12.031,12.005]
			vmag=bvri(1)  &  spty='A1V'  &  end
		'1808347': 	begin
			teff=7890  &  logg=3.85  &  logz=-.62  &  ebv=0.022
			if model eq 'marcs' then begin
			  teff=7840 & logg=3.80  & logz=-.66  &  ebv=0.017 & end
			if model eq 'mz' then begin
			 teff=7850 & logg=3.75  & logz=-.85  &  ebv=0.016 & end
			vmag=11.9  &  spty='A3V'  &  end
		'1812095': 	begin
			teff=7830  &  logg=3.70  & logz=+.22  &  ebv=0.013 ;003
			if model eq 'marcs' then begin
			  teff=7760 & logg=3.65  & logz=+.20  &  ebv=0.005 & end
			if model eq 'mz' then begin
			  teff=7800 & logg=3.6  & logz=+.15  &  ebv=0.002 & end
			if keyword_set(cohen) then begin
			  teff=9016  &  logg=4.20  &  ebv=0.13  &  logz=0 & end
			bvri=[11.941,11.736,11.632,11.526,11.368,11.312,11.286]
			vmag=bvri(1)  &  spty='A2V'  &  end
		'HD180609': 	begin
			teff=8600  &  logg=4.00  &  logz=-.45  &  ebv=0.042
			if model eq 'mz' then begin
			  teff=8560 & logg=3.95  & logz=-.44  &  ebv=0.035 & end
			vmag=9.41  &  spty='A3V'  &  end
		'HD165459': 	begin
			teff=8540  &  logg=4.2 & logz=0.07  &  ebv=0.021 ;JW
			if model eq 'mz' then begin
			  teff=8570 & logg=4.20  & logz=+.05  &  ebv=0.021 & end
			if keyword_set(cohen) then begin
			  teff=9397  &  logg=4.18  &  logz=0  &  ebv=0.09 & end
			bvri=[6.994,6.864,99,99,6.637,6.626,6.584]
			vmag=bvri(1)  &  spty='A1V'  &  end
		'BD17D4708': 	begin
			teff=6200.  &  logg=3.9  &  logz=-1.69  &  ebv=0.022
			vmag=9.45 & spty='sdF8' & end
; Schmidt 12813 stars. 2019may31-Add BOSZ results
		'BD02D3375': 	begin
; deliv 002 of 2014 Feb	teff=6200  &  logg=4.0  &  logz=-2.49  &  ebv=0.055
			teff=6080  &  logg=3.8  &  logz=-2.5  &  ebv=0.033
			if model eq 'mz' then begin
			  teff=5910 & logg=3.55  & logz=-2.48  &  ebv=0.00 & end
			if model eq 'marcs' then begin
			  teff=6440  & logg=4.4  &  logz=-2.0 & ebv=0.09 & end
			vmag=9.93 & spty='A5' & end
		'BD21D0607': 	begin
			teff=6260  &  logg=3.9  &  logz=-1.96  &  ebv=0.018
			if model eq 'mz' then begin
			  teff=6150 & logg=3.75  & logz=-2.04  & ebv=0.00 & end
			if model eq 'marcs' then begin
			  teff=6380 & logg=4.2  &  logz=-1.67 &  ebv=0.040 & end
			vmag=9.22 & spty='F2' & end
		'BD26D2606': 	begin
			teff=6300  &  logg=4.0  &  logz=-2.5 &  ebv=0.033
			if model eq 'mz' then begin
			  teff=6130 & logg=3.75  & logz=-2.50  & ebv=0.003 & end
			if model eq 'marcs' then begin
			  teff=6460  & logg=4.3  & logz=-2.10  & ebv=0.057 & end
			vmag=9.73 & spty='A5' & end
		'BD29D2091': 	begin
			teff=5840  &  logg=4.1  &  logz=-1.91  &  ebv=0.002
			if model eq 'mz' then begin
			  teff=5840 & logg=4.2  & logz=-1.85  &  ebv=0.00 & end
			if model eq 'marcs' then begin
			  teff=6000 & logg=4.5  &  logz=-1.53 &  ebv=0.034 & end
			vmag=10.22 & spty='F5' & end
		'BD54D1216': 	begin
			teff=6080  &  logg=3.9  &  logz=-1.68  &  ebv=0.002
			if model eq 'mz' then begin
			  teff=6080 & logg=3.9  & logz=-1.65  &  ebv=.001 & end
			if model eq 'marcs' then begin
			  teff=6200 & logg=4.10  & logz=-1.51 &  ebv=0.028 & end
			vmag=9.71 & spty='sdF6' & end
		'HD009051': 	begin
			teff=5080  &  logg=1.9  &  logz=-1.54  &  ebv=0.061
			if model eq 'mz' then begin
			  teff=5020 & logg=2.00  & logz=-1.45  & ebv=0.041 & end
			if model eq 'marcs' then begin
			  teff=5100 & logg=2.5  & logz=-1.01  &  ebv=0.085 & end
			vmag=8.92 & spty='G7III' & end
		'HD031128': 	begin
			teff=5985  &  logg=3.90  &  logz=-1.62  &  ebv=0.00
			if model eq 'mz' then begin
			  teff=5995 & logg=3.85 & logz=-1.63  &  ebv=0.001 & end
			if model eq 'marcs' then begin
			  teff=6045 & logg=4.0  &  logz=-1.50 &  ebv=0.021 & end
			vmag=9.14 & spty='F4V' & end
		'HD074000': 	begin
			teff=6260  &  logg=3.8  &  logz=-2.42  &  ebv=0.005
			if model eq 'mz' then begin
			  teff=6250 & logg=3.75 & logz=-2.50  &  ebv=0.002 & end
			if model eq 'marcs' then begin
			  teff=6480 & logg=4.2  &  logz=-2.0 &  ebv=0.041 & end
			vmag=9.66 & spty='sdF6' & end
		'HD111980': 	begin
			teff=5860  &  logg=3.4  &  logz=-1.32  &  ebv=0.011
			if model eq 'mz' then begin
			  teff=5820 & logg=3.4  & logz=-1.27  & ebv=0.001 & end
			if model eq 'marcs' then begin
			  teff=5820 & logg=3.7  &  logz=-1.09 &  ebv=0.007 & end
			vmag=8.38 & spty='F7V' & end
		'HD160617': 	begin
			teff=5980  &  logg=3.3  &  logz=-2.03  &  ebv=0.001
			if model eq 'mz' then begin
			  teff=6000 & logg=3.4  & logz=-1.90  & ebv=0.00 & end
			if model eq 'marcs' then begin
			  teff=6280 & logg=3.9  &  logz=-1.65 &  ebv=0.054 & end
			vmag=8.73 & spty='F' & end
		'HD185975': 	begin
			teff=5600  &  logg=2.9  &  logz=-0.22  &  ebv=0.001
			if model eq 'mz' then begin
			  teff=5620 & logg=3.4  & logz=+0.02  &  ebv=.00 & end
			if model eq 'marcs' then begin
			  teff=5760 & logg=4.4  &  logz=0.01 &  ebv=0.036 & end
			vmag=8.1 & spty='G3V' & end
		'HD200654': 	begin
			teff=5480  &  logg=2.9  &  logz=-2.50  &  ebv=0.058
			if model eq 'mz' then begin
			  teff=5450 & logg=2.85  & logz=-2.5  &  ebv=0.051 & end
			if model eq 'marcs' then begin
			  teff=5520 & logg=3.2  &  logz=-2.03 &  ebv=0.071 & end
			vmag=9.11 & spty='G' & end
; 2019aug27 - new DD 15485 stars:
		'109VIR': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=9760 & logg=3.55  & logz=-0.07  &  ebv=.022 & end
			vmag=3.73 & spty='A0III' & end
		'16CYGB': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=5710 & logg=3.75  & logz=0.05  &  ebv=0.002 & end
			vmag=6.20 & spty='G3V' & end
		'18SCO': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=5730 & logg=3.4  & logz=-0.12  &  ebv=.00 & end
			vmag=5.50 & spty='G2V' & end
		'DELUMI': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=9200 & logg=3.65  & logz=-0.18  & ebv=0.008 & end
			vmag=4.34 & spty='A1V' & end
		'ETA1DOR': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=10170 & logg=3.9  & logz=-0.55  &  ebv=.00 & end
			vmag=5.69 & spty='A0V' & end
		'ETAUMA': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=17260 & logg=4.6  & logz=-0.28  &  ebv=0. & end
			vmag=1.86 & spty='B3V' & end
		'HD101452': 	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=7400 & logg=3.8  & logz=+0.15  & ebv=0.021 & end
			vmag=8.20 & spty='A2/3' & end
		'HD115169':	begin
		   	teff=8000  &  logg=4  &  logz=0  &  ebv=0
		   	if model eq 'mz' then begin
		   	  teff=5760 & logg=3.7  & logz=-0.15  & ebv=0.014 & end
		   	vmag=9.20 & spty='G3V' & end
		'HD128998':	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=9550 & logg=3.7  & logz=-0.52  & ebv=.00 & end
			vmag=5.83 & spty='A1V' & end
		'HD142331':	begin
		   	teff=8000  &  logg=4  &  logz=0  &  ebv=0
		   	if model eq 'mz' then begin
		   	  teff=5650 & logg=3.6  & logz=-0.0  & ebv=0.008 & end
		   	vmag=8.75 & spty='A5V' & end
		'HD167060':	begin
		   	teff=8000  &  logg=4  &  logz=0  &  ebv=0
		   	if model eq 'mz' then begin
		   	  teff=5850 & logg=3.55  & logz=-0.10  &  ebv=.020 & end
		   	vmag=8.92 & spty='G3V' & end
		'HD2811':	begin
		   	teff=8000  &  logg=4  &  logz=0  &  ebv=0
		   	if model eq 'mz' then begin
		   	  teff=7920 & logg=3.5  & logz=-0.42  & ebv=0.017 & end
		   	vmag=7.50 & spty='A3V' & end
		'HD55677':	begin
			teff=8000  &  logg=4  &  logz=0  &  ebv=0
			if model eq 'mz' then begin
			  teff=8870 & logg=3.8  & logz=-0.92  & ebv=0.047 & end
			vmag=9.41 & spty='A4V' & end
		'HD93521': 	begin
			teff=25450  &  logg=3.05  &  logz=-0.06  &  ebv=0
			if model eq 'mz' then begin
			  teff=25660 & logg=3.1  &  logz=0.04  &  ebv=0. & end
			if model eq 'lanz' then begin		; NG
			  teff=27000 & logg=3.  & logz=+0.3  &  ebv=0.008 & end
			vmag=7.03 & spty='09.5III' & end
		'HZ4': 	begin		; Hubeny grid is default. Too cool
; extrapolating:
			teff=17160  &  logg=8.5  &  logz=0  &  ebv=0.17  &  end
		'SDSS132811': 	begin	; Hubeny grid is default. Too cool
; extrapolating:
			teff=16720  &  logg=8.4  &  logz=0  &  ebv=0.041  &  end
;Saha/Narayan WDs:
		'SDSSJ151421': 	begin		; Hubeny grid is default
			teff=28750  &  logg=9  &  logz=0  &  ebv=0.40
			if model eq 'rauch' then begin
			  teff=29120 & logg=8.9 &  logz=0 &  ebv=0.043 & end
			vmag=9.11 & spty='G' & end
		'NGC6681-1':  begin
			teff=8320  &  logg=3.25  &  logz=-1.37  & ebv=.094 & end
		'NGC6681-2':  begin
			teff=9670  &  logg=3.6  &  logz=-0.59  &  ebv=.082 & end
		'NGC6681-3':  begin
			teff=12430  &  logg=3.4  &  logz=0.75  &  ebv=.084 & end
		'NGC6681-4':  begin
			teff=10200  &  logg=2.5  &  logz=-2.5 &  ebv=.075 & end
		'NGC6681-5':  begin		; ~12.3
			teff=10240  &  logg=2.5  &  logz=-2.46 & ebv=.083 &  end
		'NGC6681-6':  begin
			teff=10640  &  logg=3.9  &  logz=.22  &  ebv=.117 &  end
		'NGC6681-7':  begin
			teff=5100  &  logg=2.00  &  logz=-.91  &  ebv=.176 & end
		'NGC6681-8':  begin
			teff=11990  &  logg=2.85  &  logz=-.31 & ebv=.078 & end
		'NGC6681-9':  begin
			teff=8400  &  logg=3.30  &  logz=-1.39  & ebv=.116 & end
		'NGC6681-10':  begin
			teff=20830  &  logg=5  &  logz=-.70  & ebv=.100 & end
		'NGC6681-11':  begin
			teff=7990  &  logg=3.25  &  logz=-1.18  & ebv=.120 & end
		'NGC6681-12':  begin
			teff=14820  &  logg=4.8  &  logz=0.68  & ebv=.074 & end
;; lcb stars
		'TARGET14': 	begin
			teff=3660  &  logg=2.1  &  logz=0.40  &  ebv=0.0
			if model eq 'marcs' then begin
			  teff=3140 & logg=3.8  &  logz=-1.68 &  ebv=0.0 & end
			vmag=0 & spty='M' & end
		'TARGET34': 	begin
			teff=4560  &  logg=3  &  logz=-2.4  &  ebv=0.0
			if model eq 'marcs' then begin
			  teff=4240 & logg=2.3  &  logz=.31 &  ebv=.0 & end
			vmag=0 & spty='M' & end

			else: begin   &  endelse  &  endcase
; 2018oct11 - for mz-stisonly, read param file w/ norm values
if model eq 'mz-stisonly' then begin
	readcol,'~/chifit/dat/param.'+model,strnam,teff,logg,logz,ebv,	$
		chi,normfac,form='(a,f,f,f,f,f,f)'
	ind=where(strnam eq strupcase(starin),nind)
	if nind ne 1 then stop else begin
		teff=teff(ind(0))  &  logg=logg(ind(0))  &  logz=logz(ind(0))
		ebv=ebv(ind(0))  &  normfac=normfac(ind(0))
		endelse
	endif
teff=float(teff)
print,'star in vmag=',star,teff,logg,logz,ebv
return,vmag
end
