pro montage,matchheader,filename,numimages,subsky=subsky,autosky=autosky,$
   trim=trim,guidestar=guidestar

;+
;NAME:
; MONTAGE
;
;CALLING SEQUENCE:
; montage,matchheader,filename,numimages,[trim=],[/subsky],[/autosky],
;	[/guidetar]
;
;PURPOSE:
; Cut and paste images to match a supplied master header.
; Program will prompt for image filenames and title for new image.
;
;INPUTS:
;'matchheader'  - first input is the name of the header file which the new
;                 image is to have.  This header file must have astrometry
;'filename'     - second input is the filename of the '.hhh' and '.hhd'
;                 image files which will contain the new pasted image
;'numimages'    - this is the number of images which are going to make up
;                 the new montage.  the user will be prompted for filenames of
;                 the individual images
;
;OPTIONAL KEYWORDS:
;'autosky'     - if supplied in the call, then sky values are subtracted out
;                from each image when pasting (as determined by procedure SKY).
;'subsky'      - if set, then the user is prompted for a pixel intensity value
;                to subtract from each image (i.e. customized sky value).
;                This can be used to try and match the average intensity of
;                the images so that the seams of each image will not be visible
;'trim'        - if set, this is the number of pixels trimmed from each edge
;                of each image pasted into the new array.  This is to ignore
;                bad edges, but should only be used if the images overlap
;                and should be set to a value which is less than one half the
;                overlap distance (in pixels).
;'guidestar'   - set this keyword if images being pasted are guide star images
;                or have their astrometry in guide star format
;
;OUTPUT:
; a new header and a new image file which is the montage of the images given
;
;NOTES:
;This is a fairly slow procedure - best run as a batch job.  It is also memory
;intensive.
;
;HISTORY:
; 16-Apr-92  Written by Peter Mangiafico
; 25-May-92  SKY Value subtraction option added, documentation supplied
; 17-Jun-92  Trim keyword option added
; 18-Jun-92  Individual sky subtraction ability added
; 29-Jul-92  Images now altered using HASTROM
; 16-May-94  Added keyword GUIDESTAR
;-

  arg=n_params(0)
  if (arg lt 3) then begin
    print,"CALL> MONTAGE,'matchheader_name','output_file',[# of images],[/autosky],$"
    print,"   [/subsky],[trim=],[/guidestar]"
    print,"e.g.> MONTAGE,'disk$data5:[mangiafico.m33uit]fuv0496g.hhh','m33vis.hhh',6"
    return
    endif

  if (n_elements(subsky) eq 0) then subsky=0
  if (n_elements(autosky) eq 0) then autosky=0
  if (n_elements(trim) eq 0) then trim=0 else trim=fix(trim+.5)
  if (n_elements(guidestar) eq 0) then guidestar=0

  objectname=''
  name=''
  imagename=strarr(numimages)
  ssky=intarr(numimages)
  print,"Enter title of new image which is to appear under 'OBJECT' in the header:" 
  read,objectname
  for a=0,numimages-1 do begin
    print,'Enter filename of image #'+strtrim(string(a),2)+':'
    read,name
    imagename(a)=name
    if subsky ne 0 then begin
      print,'Enter SKY subtraction value for this image:'
      read,val
      ssky(a)=val
      endif
    endfor

  print,'[sxhread] working...'
  sxhread,matchheader,newheader
  x=sxpar(newheader,'naxis1')
  y=sxpar(newheader,'naxis2')

  print,'[getrot] working...'
  getrot,newheader,rotangle
 
  print,'Montage image name:        ',filename
  print,'Size of final image:   X = ',x
  print,'                       Y = ',y
  print,'rotation angle (counterclockwise) :',rotangle

  print,'Creating new image array...'
  newimage=intarr(x,y)

  for a=0,(numimages-1) do begin

    print,''
    print,'Beginning work on image #'+strn(a+1)
    print,'[imgread] working...'
    img=0 & header=0
    imgread,img,header,imagename(a)
    if guidestar eq 1 then gsss_stdast,header
    xaxis=sxpar(header,'naxis1')
    yaxis=sxpar(header,'naxis2')

    if autosky ne 0 then begin
      print,'[sky] working...'
      sky,img,skyvalu,/silent
      print,'Sky value = ',skyvalu
      ssky(a)=skyvalu
      endif
         
    if trim ne 0 then begin
      print,'Trimming image...'
      img=img(trim-1:xaxis-trim-2,trim-1:yaxis-trim-2)
      sxdelpar,header,'naxis1'
      sxdelpar,header,'naxis2'
      crpix1=sxpar(header,'crpix1')
      crpix2=sxpar(header,'crpix2')
      sxdelpar,header,'crpix1'
      sxdelpar,header,'crpix2'
      sxaddpar,header,'naxis1',xaxis-(2*trim)
      sxaddpar,header,'naxis2',yaxis-(2*trim)
      sxaddpar,header,'crpix1',crpix1-trim
      sxaddpar,header,'crpix2',crpix2-trim
      endif

    if (subsky ne 0) or (autosky ne 0) then begin
      print,'Subtracting off sky value...'
      img=temporary(img)-fix(ssky(a)+.5)
      endif

    print,'[hastrom] working...'
    hastrom,img,header,newheader,missing=-32000,interp=1
    use=where(img ne -32000)
    newimage(use)=img(use)
    endfor

  change=['bscale','bunit','bzero','roll','history','object','picscale',$
          'object2','origin','telescop','instrume','image','exptime',$
          'iraf-max','iraf-min','iraf-b/p','iraftype','gain','date','date-obs',$
          'time-obs']
  numdelete=7 & numchange=21
  temp=strarr(numchange)
  sxhread,imagename(0),header
  for a=0,(numchange-1) do sxdelpar,newheader,change(a)
  sxaddpar,newheader,'object',objectname
  for ab=(numdelete),(numchange-1) do begin
    temp(ab)=sxpar(header,change(ab))
    sxaddpar,newheader,change(ab),temp(ab)
    endfor

  print,''
  print,'Adding HISTORY to header and writing final image...'
  print,'[stwrt] working...'
  sxaddpar,newheader,'HISTORY', $
                    'New montage image created by program MONTAGE from files:'
  for a=0,numimages-1 do sxaddpar,newheader,'HISTORY',imagename(a)
  sxaddpar,newheader,'HISTORY','Images altered with HASTROM'
  sxaddpar,newheader,'HISTORY','Reference header name:'
  sxaddpar,newheader,'HISTORY',matchheader
  sxaddpar,newheader,'HISTORY','MONTAGE run on '+!stime
  
  stwrt,newimage,newheader,filename

end
