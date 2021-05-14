ABSCAL WFC3 IDL Code
====================

This section describes running the IDL WFC3 flux calibration code.

.. contents:: Contents
    :local:
    :depth: 2

Setup Requirements
------------------

In order to run the IDL code, the following setup steps must be taken:


Environment Variables
~~~~~~~~~~~~~~~~~~~~~

* **IDL_PATH** In addition to the common directories, :code:`IDL_PATH` must include
  :code:`ABSCAL/idl_code/wfc3`, where :code:`ABSCAL` is the location of the ABSCAL 
  repository.
* **WFC3_REF** This should point to :code:`ABSCAL/idl_code/data/wfc3/ref`


Directories
~~~~~~~~~~~

Create a directory containing the WFC3 FITS files that you want to extract and calibrate.
Inside this directory, create a directory where the extracted spectra will be placed. The
default name for this directory is "spec".


Run Steps
---------


Create Initial Data File (:code:`wfcdir`)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Main Script** :code:`wfcdir.pro`
* **Other WFC3 Scripts Used** None
* **Common Code Used** :code:`absdate.pro`
* **Input Files** None [#a]_
* **Output Files** :code:`dirtemp.log`. Canonically renamed to :code:`dirirstare.log` or
  :code:`dirirscan.log` as appropriate

The :code:`wfcdir.pro` script is run as follows::

    wfcdir,'data_path','output_file_name'

where :code:`data_path` is the path to the directory containing the FITS files to be used 
(defaults to the current directory), and :code:`output_file_name` is the name of the 
exposure table to be created (default :code:`dirtemp.log`).

After running the script, open :code:`dirtemp.log` and, for every grism exposure, keep at 
most one single filter exposure from the same visit and with the same :code:`POSTARG` 
value. Later steps will use the filter exposure to estimate the location of the 
zeroth-order grism image, so the corresponding filter image should be from the same visit, 
and with nointervening move commands. Standard practice is to then re-name the file to 
some name that starts with "dir" and has the extension ".log", but that no longer contains 
"temp". The canonical name is :code:`dirirstare.log` for non-scanned exposures, and
:code:`dirirscan.log` for scan-mode exposures. If you already have a file created as the 
output of :code:`wfcdir.pro`, append the lines that you're keeping to the existing file.


Extract and Co-add Spectra (:code:`prewfc`)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Main Script** :code:`prewfc.pro`
* **Other WFC3 Scripts Used** :code:`calwfc_imagepos.pro`, :code:`calwfc_spec.pro`,
  :code:`wfc_coadd.pro`, :code:`wfc_flatscal.pro`, :code:`wfc_process.pro`, 
  :code:`wfc_wavecal.pro`, :code:`wfcobs.pro`, :code:`wfcread.pro`, :code:`wfcwlfix.pro`
* **Common Code Used** :code:`cross_correlate.pro`, :code:`mode.pro`, :code:`psclose.pro`,
  :code:`pset.pro`, :code:`ws.pro` 
* **Input Files*** :code:`dirirstare.log` or :code:`dirirscan.log` as appropriate [#a]_
* **Output Files** :code:`spec` dir containing 1d extracted spectra and co-added spectra.

The :code:`prewfc.pro` script is run as follows::

    prewfc,'data_path','data_file','spectra_subpath',/display,/trace

where :code:`data_path` is the path to the directory containing the FITS files to be used
and the log file to be read (defaults to current directory), :code:`data_file` is the log 
file name (defaults to :code:`dirirstare.log`), :code:`spectra_subpath` is the name of the
subdirectory where the 1d- and co-added spectra will be written (defaults to 
:code:`spec`), :code:`display` is a flag to display intermediate plots showing the 
zeroth-order finding process, and :code:`trace` is a flag to display plots of the 
extraction trace (and extracted spectra).

After the program has been run, one spectrum will be created in the spectra sub-directory 
for each input file (named :code:`spec_ipppssoot.fits` for standard data files, and
:code:`spec_ipppssootpn.fits` for planetary nebula wavelength calibration files, where in 
both cases :code:`ipppssoot` is the root name of the input data file), one spectrum table 
will be created for each co-added spectrum (where each visit is co-added into a single 
spectrum), named :code:`target.grism-ipppss` (or :code:`targetpn.grism-ipppss`) where
target is the canonical target name, grism the grism used for the observation, and ipppss
is the portion of the rootname that specifies instrument (i), program (ppp), and visit 
(ss). Finally, postscript plots are created for each order of each of the co-added 
spectra, named :code:`target-ipppss_coaddngrism.ps` (or 
:code:`targetpn-ipppss_coaddngrism.ps`), with the :code:`n` after "coadd" being the grism 
order, and the remaining name aspects as above.


Fit Planetary Nebula Emission Lines (:code:`wlmeas`)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Main Script** :code:`wlmeas.pro`
* **Other WFC3 Scripts Used** :code:`wlimaz.pro`
* **Common Code Used** :code:`integral.pro`, :code:`linecen.pro`, :code:`null_plot.pro`, 
  :code:`pbox.pro`, :code:`snomod.pro`, :code:`tin.pro`, :code:`ws.pro`
* **Input Files*** :code:`dirirstare.log` [#b]_
* **Output Files** :code:`wlmeas.tmp`

:code:`wlmeas.pro` requires a separate data set of planetary nebula observations that have 
been prepared by :code:`wfcdir.pro` and :code:`prewfc.pro`. Once those observations are 
ready, the :code:`wlmeas.pro` script is run as follows::

    wlmeas,'data_path',specdir='spectra_subpath',/display

where :code:`data_path` is the path to the directory containing the WFC3 data (defaults to 
current directory), :code:`spectra_subpath` is the subdirectory of :code:`data_path` that 
contains the extracted spectra (default :code:`spec`), and :code:`display` is a flag to 
display plots of the lines being found/fit.

After the program has been run, the :code:`wlmeas.tmp` file will contain the measured 
X positions of the planetary nebula emission lines for all of the input files. After 
checking the file for any potential issues, it should be renamed to (or its data should be
added to) a file named :code:`wlmeas.output`


Create 2D detector Wavelength Map (:code:`wlmake`)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **Main Script** :code:`wlmake.pro`
* **Other WFC3 Scripts Used** None
* **Common Code Used** :code:`ws.pro`
* **Input Files** :code:`wlmeas.output` [#b]_
* **Output Files** None [#c]_

The :code:`wlmake.pro` script is rn as follows::

    wlmake,'data_path',specfile='data_file'

where :code:`data_path` is the path to the directory containing the WFC3 planetary nebula 
data (defaults to current directory), and :code:`specfile` is the output file from the 
:code:`wlmeas.pro` script (defaults to :code:`wlmeas.output`). The script solves for a 
2D wavelength solution over the full detector, and prints out fit and fit error 
information to standard output. It produces no output files.


References
----------

`Bohlin, R. C.; Deustua, S. E. 2019, AJ, 157, 229. "CALSPEC: WFC3 IR GRISM SPECTROSCOPY" <https://iopscience.iop.org/article/10.3847/1538-3881/ab1b50/meta>`_

`Bohlin, R. C., Deustua, S. E., MacKenty, J. 2014, WFC3 ISR 2014-15 "Enabling Observations of Bright Stars with WFC3 IR Grisms" <https://www.stsci.edu/files/live/sites/www/files/home/hst/instrumentation/wfc3/documentation/instrument-science-reports-isrs/_documents/2014/WFC3-2014-15.pdf>`_

`Bohlin, R. C., Deustua, S. E., Pirzkal, N. 2015, WFC3 ISR 2015-10 "IR Grism Wavelength Solutions using the Zero Order Image as the Reference Point" <https://www.stsci.edu/files/live/sites/www/files/home/hst/instrumentation/wfc3/documentation/instrument-science-reports-isrs/_documents/2015/WFC3-2015-10.pdf>`_


Reference Files
---------------

Below are Ralph Bohlin's master tables:

* :download:`dirirstare.log <../files/dirirstare_2021-01-01.log>`
* :download:`wlmeas.log <../files/wlmeas_2013-05-31.log>`

Notes
-----

.. [#a] All of the scripts use a set of WFC3 grism exposures as their analysis target, so
   those files are assumed as inputs are will not be called out in any specific step.
.. [#b] This script uses WFC3 IR grism observations of planetary nebula that have been 
   processed according to :code:`wfcdir.pro` and :code:`prewfc.pro`
.. [#c] All output produced by :code:`wlmake.pro` is written to :code:`stdout`
