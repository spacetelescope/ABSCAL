ABSCAL WFC3 Examples
====================

Extracting WFC3 IR GRISM spectra for a single program
-----------------------------------------------------

This example uses WFC3 program 15587, consisting of observations of GD153, and available 
from the following 
`MAST query <https://mast.stsci.edu/portal/Mashup/Clients/Mast/Portal.html?searchQuery=%7B%22service%22%3A%22CAOMFILTERED%22%2C%22inputText%22%3A%5B%7B%22paramName%22%3A%22project%22%2C%22niceName%22%3A%22project%22%2C%22values%22%3A%5B%22HST%22%5D%2C%22valString%22%3A%22HST%22%2C%22isDate%22%3Afalse%2C%22separator%22%3A%22%3B%22%2C%22facetType%22%3A%22discrete%22%2C%22displayString%22%3A%22HST%22%7D%2C%7B%22paramName%22%3A%22proposal_id%22%2C%22niceName%22%3A%22proposal_id%22%2C%22values%22%3A%5B%5D%2C%22valString%22%3A%2215587%22%2C%22isDate%22%3Afalse%2C%22freeText%22%3A%2215587%22%2C%22displayString%22%3A%2215587%22%7D%5D%2C%22position%22%3A%22undefined%2C%20undefined%2C%20undefined%22%2C%22paramsService%22%3A%22Mast.Caom.Filtered%22%2C%22title%22%3A%22MAST%3A%20%20Advanced%20Search%203%22%2C%22tooltip%22%3A%22HST%3B%2015587%3B%20%22%2C%22columns%22%3A%22*%22%2C%22columnsConfig%22%3A%22Mast.Caom.Cone%22%7D>`__.

The first step is to construct a list of the exposures along with associated metadata. In
order to do this, enter the command::

    wfc3_setup -v "i*flt.fits"

The "-v" flag asks for verbose output, and the '"i*flt.fits"' template tells the script to
build its table from all of the WFC3 flt files in the directory. The template is put in
quotes to prevent it from being expanded before being passed to the script.

When run, the script should produce three output files: "dirtemp_all.log" (all files),
"dirtemp_grism.log" (grism files with a single filter file included for each grism
exposure to provide more accurate zeroth order centring), and "dirtemp_filter.log" (all
filter exposures). The key file here is "dirtemp_grism.log", and the output should look
like :download:`this <example_files/ex1/dirtemp_grism.log>` (except with the "path" 
column replaced by the actual path to the files).

The next and final step is extracting the grism data and co-adding the grism exposures 
taken with the same grism. To do this, enter the command::

    wfc3_coadd -fvdp dirtemp_grism.log

When run, the script produces a number of extracted spectra (found in the "spec" 
directory), and an updated table named "dirirstare.log". The "-f" option tells the script
to create new output files even if identically-named files already exist, the "-v" option
tells it to run in verbose mode, the "-d" option tells it to double the spectral 
resolution when co-adding, and the "-t" mode tells it to display informational plots while
running, and allow the user to choose between options (when applicable). The spec 
directory should contain files like :download:`these <example_files/ex1/spec.zip>`, and 
the new output table should look like :download:`this <example_files/ex1/dirirstare.log>`.

This completes the example.

Using Planetary Nebulae to generate a WFC3 IR GRISM wavelength fit
------------------------------------------------------------------

This example uses WFC3 program 13582, consisting of observations of IC5117, and available
from the following
`MAST query <https://mast.stsci.edu/portal/Mashup/Clients/Mast/Portal.html?searchQuery=%7B%22service%22%3A%22CAOMFILTERED%22%2C%22inputText%22%3A%5B%7B%22paramName%22%3A%22project%22%2C%22niceName%22%3A%22project%22%2C%22values%22%3A%5B%22HST%22%5D%2C%22valString%22%3A%22HST%22%2C%22isDate%22%3Afalse%2C%22separator%22%3A%22%3B%22%2C%22facetType%22%3A%22discrete%22%2C%22displayString%22%3A%22HST%22%7D%2C%7B%22paramName%22%3A%22proposal_id%22%2C%22niceName%22%3A%22proposal_id%22%2C%22values%22%3A%5B%5D%2C%22valString%22%3A%2213582%22%2C%22isDate%22%3Afalse%2C%22freeText%22%3A%2213582%22%2C%22displayString%22%3A%2213582%22%7D%5D%2C%22position%22%3A%22undefined%2C%20undefined%2C%20undefined%22%2C%22paramsService%22%3A%22Mast.Caom.Filtered%22%2C%22title%22%3A%22MAST%3A%20%20Advanced%20Search%201%22%2C%22tooltip%22%3A%22HST%3B%2013582%3B%20%22%2C%22columns%22%3A%22*%22%2C%22columnsConfig%22%3A%22Mast.Caom.Cone%22%7D>`__.

The first two steps are identical to the above example. 
:download:`Here is the example dirtemp_grism.log file <example_files/ex2/dirtemp_grism.log>`, 
:download:`here is the example dirirstare.log file <example_files/ex2/dirirstare.log>`, and 
:download:`here is the example spec directory <example_files/ex2/spec.zip>`.

After you have run those steps, the next step is to locate the centres of the emission 
lines used for wavelength fitting. To do this, enter the command::

    wfc3_wave_find_lines -fvp dirirstare.log

When run, the script produces a table named "wlmeastmp.log". The "-f" option tells the
script to generate output files even if they already exist, the "-v" option tells the
script to generate verbose output, and the "-t" option tells the script to display plots
while running. Assuming that you take the default fit in all cases (except for rejecting 
the few cases where a spurious fit is found), the output table should look like 
:download:`this <example_files/ex2/wlmeastmp.log>`.

The next and final step is generating a wavelength solution fit over the whole detector.
To do this, enter the command::

    wfc3_wave_solve -fvp dirirstare.log

When run, the script produces a table named "wlmeastmp_final.log". The options are the 
same as for the previous step. The resulting output table should look like
:download:`this <example_files/ex2/wlmeastmp_final.log>`.

This completes the example.

.. _ABSCAL: https://github.com/spacetelescope/ABSCAL
.. _MAST: https://mast.stsci.edu
