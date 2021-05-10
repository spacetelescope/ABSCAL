;+
; NAME:
;	Ls.pro
;
; PURPOSE:
; 	This routine gives IDL the unix 'ls' command.
;
;INPUTS: 
;	filepath (optional): string of path to directory to be listed
;
;KEYWORDS:
;	OPTIONS: UNIX style options (ie l = long listing). see manual page
;	of ls for complete listing of options. Default is simple file list
;	with directories listed appended with slashes.
;
; HISTORY:
;	Written by:  T. Beck	ACC/GSFC   3 May 1994
;	PP/ACC  Nov. 12, 1997 Added filepath and options
;-
;______________________________________________________________________________

pro ls, filepath, options=options

if keyword_set(options) then command = 'ls -F' + options + ' ' $
   else command = 'ls -F '
if n_elements(filepath) then $ 
   spawn, command + filepath $
      else spawn, command

return
end
