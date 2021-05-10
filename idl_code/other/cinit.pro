PRO CINIT,DUM
;+
; NAME
;	CINIT
; PURPOSE:
;	To initialize the common block TV, TEK, IMAGES, and TAPEINFO (on
;	the SUNs)
; CALLING SEQUENCE:
;	CINIT
; INPUTS:
;	None.
; OUTPUTS:
;	None.
; COMMON BLOCKS:
;	The common blocks are initialized.
; SIDE EFFECTS:
;	The TV is reset to zero roam and zoom factors.
; REVISION HISTORY:
;	Written, Wayne Landsman, July 1986.
;	Converted to workstation use.  Michael R. Greason, May 1990.
;	OPND variable removed from common block TV.  K.Rhode, July 1990.
;	TAPEINFO added.  MRG, STX, October 1990.
;	TEK added, N. Collins, STX, Nov. 28, 1990.  
;-
COMMON TV,CHAN,ZOOM,XROAM,YROAM
COMMON IMAGES, x00, y00, xsize, ysize
COMMON TAPEINFO, ndrives, drivenames
COMMON TEK, plotunit, old_device
;
;			Image display initialization.
;
n_planes = 128
chan = 0
zoom = replicate(1b,n_planes)	;Image planes
xroam = intarr(n_planes)	;Roam X Direction
yroam = intarr(n_planes)	;Roam Y Direction
x00 = intarr(n_planes) 		;Lower left corner x pos. of image in window.
y00 = intarr(n_planes) 		;Lower left corner y pos. of image in window.
xsize = intarr(n_planes) 	;Number of columns in the displayed image.
ysize = intarr(n_planes) 	;Number of rows in the displayed image.
plotunit = 0
old_device = !D.NAME
;
if !VERSION.OS ne "vms" then begin
;
;			Tape drive initialization.
;
ndrives = 2			;Number of available tape drives.
drivenames = strarr(ndrives)	;Tape drive device names.
drivenames(0) = '/dev/rdev/nrst1'
drivenames(1) = '/dev/bdev/nrst1'
endif
;
RETURN
END
