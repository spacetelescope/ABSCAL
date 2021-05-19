ABSCAL WFC3 Scripts
===================

This section describes using the ABSCAL WFC3 scripts as python modules. This allows for 
greater customization than running the 
`ABSCAL WFC3 command scripts <./commands.html#wide-field-camera-3-wfc3>`_, 
although it can also be slightly more complicated.

.. contents:: Contents
    :local:
    :depth: 2

:code:`preprocess_table_create.py`
----------------------------------

This module is designed to create an exposure metadata table, or append to an existing 
metadata table. Its intended entry point is the :code:`populate_table()` function. It is 
possible to customize the behaviour of this function by 

* Adding a specific existing table using the :code:`data_table` keyword. This should be 
  used to start out the function with some existing exposures, although it *can* also be 
  used to customize the directory search path and the search pattern when creating the 
  table. Sending an empty table to :code:`populate_table()` is not recommended as a way to 
  set these values (the supported way is to send no table and to include the relevant 
  values as keyword arguments).
* The function verbosity and IDL compatibility mode can be directly set by specifying the 
  relevant keywords.
* The :code:`overrides` dictionary is included for compatibility, and to allow for 
  potential future expansion, but there are currently no defaults that can be overridden 
  by this dictionary.

When running, the function makes use of 

* Whatever file type (e.g. "flt", "drz", "ima", "raw") is specified in the template string.
* The support (spt.fits) file, for determining scan rate. Without that file, all input 
  files will be interpreted as having a scan rate of zero.

For more detail, `see the preprocess_table_create API reference <../autoapi/abscal/wfc3/preprocess_table_create/index.html>`_. 


:code:`reduce_grism_coadd.py`
-----------------------------

This module is designed to group a list of grism exposures by program and visit and, for 
each exposure in a given group, if there is not an extracted spectrum available for the 
exposure, create one using `reduce_grism_extract.py`_ [#a]_. Once each exposure has an 
extracted spectrum available, then for the group,

* Take all of the input exposures belonging to a particular group, and extract the 
  wavelength, net flux, flux error, fitted y position of the trace, data quality value of 
  the trace, background flux, gross flux, and exposure time, then store the 
  values in a set of 2D :code:`numpy` arrays, where the second axis represents the 
  individual exposures in the group.
* Create a 2D mask array of the same size as the above arrays, and set it to 0 wherever 
  a pixel in one of the input arrays has a DQ value that should result in its exclusion, 
  where the corresponding DQ values are 4 (bad detector pixel), 8 (deviant bias value), 
  16 (hot pixel), 64 (warm pixel), 128 (bad reference pixel), and 256 (full-well 
  saturation) (see `Chapter 23 of the WFC3 data handbook`_ for more information on data 
  quality flags).
* Interpolate a net flux value for each single and double bad pixel, that is

    * For a single bad pixel with good pixels on either side of it, set that pixel's flux 
      to the average of the two good pixels
    * For a pair of adjacent bad pixels with good pixels on either side of the pair, set 
      the flux of both pixels to the average of the two good pixels

* For each spectral order,

    * Check all spectra for whether they contain good data for that order [#d]_ and, if 
      none do, skip co-adding the order
    * Cross-correlate the order region of each spectrum against the first spectrum, 
      deriving the best fit with an offset of :math:`<2.7` pixels. If no offset can be 
      derived, if the offset derived is :math:`\ge2.7` pixels, or if the joint coverage 
      of the two spectra is missing more than 1000 angstroms of the wavelength range 
      assigned to the order, the offset is set to 0 pixels.
    * A new wavelength array is created for each of the spectra consisting of its existing 
      wavelength array plus the derived offset multiplied by the dispersion at the central 
      wavelength of the order. For the first spectrum, this array is the same as its 
      existing array. If the :code:`-d` flag is set, then all spectra will have their 
      number of points doubled.
    * Each spectrum is interpolated to provide a new flux at the corrected wavelengths
    * For each of the data arrays above (net flux, flux error, etc.), a new array is 
      created that is the sum (or combination, in the case of error) of all the spectra 
      that had good data for that point. Interpolation is used to fill in points where 
      none of the spectra had good data, although those points remain flagged in the DQ 
      array.

* A final data array is created for each group, consisting of all the data points for 
  each spectral order, sorted so that the wavelengths are monotonically increasing. The 
  result is written out as a FITS file and an astropy table.

For more detail, `see the reduce_grism_coadd API reference <../autoapi/abscal/wfc3/reduce_grism_coadd/index.html>`_. 

Adjustable Parameters
~~~~~~~~~~~~~~~~~~~~~

The adjustable parameters for reduce_grism_coadd consist of a combination of default 
values, command-line arguments, and output overrides corresponding to specific exposures.

Default Values
..............

These are passed to the :code:`coadd()` function via the :code:`overrides` parameter, 
which takes a python dictionary. The default parameter values are found in the 
abscal.wfc3.data.defaults sub-module/directory, stored as a 
`parameter file <./parameter_files.html>`_. The parameters are:

width: float, default 22
    The width of the cross-correlation search region. [#f]_
wbeg: float, default 7500 (G102) or 10,000 (G141)
    The start value (in Angstroms) of the valid wavelength range for the (negative) first 
    order spectrum. For the second order, this value is doubled.
wend: float, default 11,800 (G102) or 17,500 (G141)
    The end value (in Angstroms) of the valid wavelength range for the (negative) first 
    order spectrum. For the second order, this value is doubled.
regbeg_m1: float, default -13,500 (G102) or -19,000 (G141)
    The start of the -1st order region, in Angstroms. [#e]_ 
regend_m1: float, default -3,800 (G102) or -5,100 (G141)
    The end of the -1st order region, in Angstroms.
regbeg_p1: float, default -3,800 (G102) or -5,100 (G141)
    The start of the 1st order region, in Angstroms.
regend_p1: float, default 13,500 (G102) or 19,000 (G141)
    The end of the 1st order region, in Angstroms.
regbeg_p2: float, default 13,500 (G102) or 19,000 (G141)
    The start of the 2nd order region, in Angstroms.
regend_p2: float, default 27,000 (G102) or 38,000 (G141)
    The end of the 2nd order region, in Angstroms.

Command-line Arguments
......................

double: :code:`-d`, :code:`--double`, default False
    Whether to double the number of points in the resampled spectra, and thus interpolate 
    the data to match.

Exposure-specific Overrides
...........................

Exposure-specific overrides for reduce_grism_coadd are found at 
"abscal_base/wfc3/data/reduce_grism_coadd.yaml".


:code:`reduce_grism_extract.py`
-------------------------------

This module is designed to take a table of WFC3 IR grism exposures, and extract 1D spectra 
of each exposure. The suggested entry point is the :code:`reduce` function, which loops 
through the table and, for each grism exposure:

* If the exposure is scan mode, raise a :code:`NotImplemented` exception
* If the exposure is stare mode,

    * If there is an associated filter exposure (i.e. a filter exposure taken as part of 
      the same program and visit, and with the same POSTARG), use the 
      `util_filter_locate_image.py`_ module to find the target's position on the detector, 
      and then use a hardcoded offset to estimate the position of the zeroth-order image.
    * If there is no filter exposure, or if the image could not be found on the filter 
      exposure, use the grism exposure's WCS to estimate the location of the zeroth-order 
      image.
    * Find the zeroth-order image using a centroiding algorithm. If it can't be found, 
      then the estimated position derived above will be used.
    * Assign an approximate mapping from x pixel value to wavelength. 
    
        * If the zeroth-order image was found, use a mapping based on the zeroth-order 
          location (as described further in `WFC3 ISR 2015-10`_). 
        * Otherwise, use an aXe-derived mapping discussed in `WFC3 ISR 2016-15`_.
    
    * Subtract a scaled 2D flatfield
    * If the background/flatfield cube subtraction order is set to do the flatfield 
      subtraction first, scale and subtract a flatfield cube.
    * For each spectral order, use the wavelength/x pixel mapping derived above to create 
      a pixel search range for that order, and use an approximate slope specified as a 
      parameter to estimate the y location of that order. Collapse the resulting box along 
      the x direction, giving a 1D count rate profile. Fit the centre of that profile to 
      give a y location of the spectral order. Use the midpoint of the x range as the x 
      location of the order.
    * Using all of the found orders (including the zeroth order, if found), fit a linear 
      trace profile [#g]_
    * Extract background traces on either side of the target trace, and use them to create 
      a background spectrum
    * If the background/flatfield cube subtraction order is set to do the flatfield 
      subtraction second, scale and subtract a flatfield cube
    * Extract the gross and net count rates, background count rate, data quality flags 
      affecting the spectrum, exposure time, and weighted exposure time for the target 
      trace.
    * Create a FITS file with a bintable extension containing all of the 1D spectra 
      extracted, as well as header cards specifying the keywords used to obtain the 
      extractions.

For more detail, `see the reduce_grism_extract API reference <../autoapi/abscal/wfc3/reduce_grism_extract/index.html>`_. 

Adjustable Parameters
~~~~~~~~~~~~~~~~~~~~~

The adjustable parameters for reduce_grism_extract consist of a combination of default 
values, command-line arguments, and output overrides corresponding to specific exposures.

Default Values
..............

These are passed to the :code:`reduce()` function via the :code:`overrides` parameter, 
which takes a python dictionary. The default parameter values are found in the 
abscal.wfc3.data.defaults sub-module/directory, stored as a 
`parameter file <./parameter_files.html>`_. The parameters are:

xc: float, default -1
    X centre of zeroth order image. If set to a negative value, the submodule will find 
    and fit the centre itself, either from a corresponding filter exposure (preferred) or 
    from the grism exposure directly.
yc: float, default -1
    The same as xc, but the Y centre.
xerr: float, default -1
    Measured error in xc. Set when xc is set. Passed through to FITS header.
yerr: float, default -1
    As xerr, but error in yc.
ywidth: int, default 11
    Width of the extraction box at each x pixel.
y_offset: int, default 0
    Offset of the initial spectral trace in the y direction. Added directly to the 
    approximate initial trace fit, before the actual trace is fit.
gwidth: int, default 6
    Width of smoothing kernel for background smoothing
bwidth: int, default 13
    Width of background extraction box at each x pixel
bmedian: int, default 7
    Width of background median-smoothing region
bmean1: int, default 7
    Width of first background boxcar-smoothing box
bmean2: int, default 7
    Width of second background boxcar-smoothing box
bdist: int, default 25 + bwidth//2
    Distance from spectral trace centre to background trace centres.
slope: float, default 1
    Slope of spectral trace in radians. If this is set to a value other than its default 
    value, then the supplied value will be used in determining the trace, and the slope 
    will not be fit.
yshift: int, default 0
    Offset to the initial spectral trace slope. Added directly to the approximate initial 
    trace fit, before the actual trace is fit.
ix_shift: float, default 252 (G102), 188 (G141)
    Delta in the x direction from the target centroid in the imaging exposure to the 
    zeroth order centroid in the grism exposure.
iy_shift: float, default 4 (G102), 1 (G141)
    As per ix_shift, but in the y direction
wl_offset: flot, default 0
    Offset of the wavelength fit. Added directly to the fit.
wlrang_m1_low: float, default 8000 (G102), 10800 (G141)
    Start of the -1st order wavelength range. [#h]_
wlrang_m1_high: float, default 10000 (G102), 16000 (G141)
    End of the -1st order wavelength range.
wlrang_p1_low: float, default 8800 (G102), 10800 (G141)
    Start of the 1st order wavelength range.
wlrang_p1_high: float, default 11000 (G102), 16000 (G141)
    End of the 1st order wavelength range.
wlrang_p2_low: float, default 8000 (G102), 10000 (G141)
    Start of the -1st order wavelength range.
wlrang_p2_high: float, default 10800 (G102), 13000 (G141)
    End of the -1st order wavelength range.

Command-line Arguments
......................

bkg_flat_order: :code:`-b`, :code:`--bkg_flat_order`, default "flat_first"
    Whether to subtract a scaled flatfield cube before or after fitting and subtracting 
    the detector background. Options are "flat_first" to flatfield before background 
    subtraction, "bkg_first" to do background subtraction before flatfielding, and 
    "bkg_only" to not do flatfielding at all. *NOTE* that this flag does not affect the 
    2D scaled flatfield subtraction, which always occurs and always happens before either 
    background subtraction or cube flatfield subtraction.

Exposure-specific Overrides
...........................

Exposure-specific overrides for reduce_grism_coadd are found at 
"abscal_base/wfc3/data/reduce_grism_extract.yaml".


:code:`reduce_grism_wavelength.py`
----------------------------------

This module has two central functions, :code:`wlmeas()` and :code:`wlmake()`, which will 
be discussed separately.

:code:`wlmeas`
~~~~~~~~~~~~~~

This function takes a table of exposures, selects those that are marked as being grism 
exposures of planetary nebulae (PN), and uses them to produce a final wavelength scale for 
WFC3 IR grism exposures. It does this by:

* Taking a list of emission lines found in PN spectra
* For each PN exposure,

    * For each spectral order present on the detector,
    
        * Identifying the emission lines that are found within that spectral order
        * Using the wavelength scale from `reduce_grism_extract.py`_ to find the 
          approximate pixel location of that line
        * Taking the net spectrum in the line-finding region, and making a flux-weighted 
          centroid of the region
        * If a successful fit is found, letting the user approve, modify, or reject it
        * If no fit is found, letting the user add one if desired
        * Recording the fit location (or the centre of the search region if there was no 
          successful fit) to an output table

Once all of the exposures have had all of their emission line fits recorded, the output 
table is written out in astropy format.

:code:`wlmake`
~~~~~~~~~~~~~~

This function takes the same input table of exposures as `wlmeas`_, as well as the output 
table produced by `wlmeas`_, and derives a wavelength fit based on a pixel's location 
relative to the centre of the zeroth-order image. It derives a separate fit for each order 
of each grism, and records the fit parameters to an output table.

For more detail, `see the reduce_grism_wavelength API reference <../autoapi/abscal/wfc3/reduce_grism_wavelength/index.html>`_. 

Adjustable parameters
~~~~~~~~~~~~~~~~~~~~~

Neither function currently has any adjustable parameters.


:code:`util_filter_locate_image.py`
-----------------------------------

This module locates the target centroid in imaging exposures. The main entry point 
function, :code:`locate_image()`, takes a table of exposures, filters out any non-imaging 
exposures and, for each exposure,

* Take the image data, and set the edges of the image to zero.
* Use the image WCS and the target co-ordinates (corrected for proper motion if the target 
  was recognized as a standard star) to predict the target location on the detector
* If the target was not close to the edge of the detector,

    * Set the image data to zero except for a small region around the predicted location
    * Median-filter the image with a 3-pixel kernel
    * Take an even small region of the image around the brightest pixel in the smoothed
      image
    * Subtract the median value of the small region from the region
    * Subtract 1/5 of the brightest pixel value from the region
    * Set any pixels with negative values to zero
    * Create two image profiles, one collapsed along the X axis and the other collapsed 
      along the Y axis
    * Produce a flux-weighted mean value for each profile, and set the target pixel 
      position to those values
    * Set the error values to :math:`\rm{pos}_{found} - \rm{pos}_{predicted}`.

* If the target was close to the detector edge, or not found, return "-1" as co-ordinates.
* Return the image co-ordinates and image error values.

For more detail, `see the util_filter_locate_image API reference <../autoapi/abscal/wfc3/util_filter_locate_image/index.html>`_. 

Adjustable Parameters
~~~~~~~~~~~~~~~~~~~~~

The adjustable parameters for util_filter_locate_image consist of a pair of default 
values.

Default Values
..............

These are passed to the :code:`locate_image()` function via the :code:`overrides` 
parameter,  which takes a python dictionary. The default parameter values are zero. The 
parameters are:

xstar: float, default 0
    The predicted star x position. 0 means unknown.
ystar: float, default 0
    The predicted star y position. 0 means unknown.

If either of these values is set to something other than zero, the WCS fitting part of the 
function will not be run, and the provided values will be treated as the predicted 
position.


:code:`util_grism_cross_correlate.py`
-------------------------------------

This module cross-correlates two spectra. The entry point function, 
:code:`cross_correlate()` takes two spectra and computes a correlation coefficient for 
every shift within a provided width, then returns the maximum signal value along with an 
array of values.

For more detail, `see the util_grism_cross_correlate API reference <../autoapi/abscal/wfc3/util_grism_cross_correlate/index.html>`_. 

Adjustable Parameters
~~~~~~~~~~~~~~~~~~~~~

The adjustable parameters for util_grism_cross_correlate consist of a set of default 
values.

Default Values
..............

These are passed to the :code:`cross_correlate()` function via the :code:`overrides` 
parameter,  which takes a python dictionary.  The default parameter values are found in 
the abscal.wfc3.data.defaults sub-module/directory, stored as a 
`parameter file <./parameter_files.html>`_. The parameters are:

ishift: int, default 0
    Approximate initial shift. The correlation search will start here. This value will 
    also be added to the final fit.
width: int, default 15
    Size (in pixels) of the correlation search region
i1: int, default 0
    First pixel of the spectrum to use in correlation search
i2: int, default :code:`len(first_spectrum)-1`
    Last pixel of the spectrum to use in correlation search.


Notes
-----

.. [#a] Before extracting a spectrum, the script will look in its output location to see 
   if a spectrum with the appropriate name already exists. By default, if one does exist, 
   it will use that spectrum instead of performing a new extraction. The :code:`-f` flag 
   will force the script to create a new extracted spectrum even if one already exists.
.. [#b] And if the associated FITS file can be found, and if the target is on the detector 
   in the imaging exposure.
.. [#c] The average exposure time is the image exposure time multiplied by the number of 
   pixels extracted in a given column (i.e. the number of pixels without DQ flags that 
   would prevent their being added to the extraction), and divided by the total number of 
   pixels in the extraction box for that column.
.. [#d] In order to check whether an input file has data in an order's spectral range,

   * Define a spectral range for the order based on the :code:`wbeg` and :code:`wend` 
     parameters, where :math:`\rm{start} = \rm{wbeg}*\rm{order}`, 
     :math:`\rm{end} = \rm{wend}*\rm{order}`, and 
     :math:`\rm{range} = \rm{end} - \rm{start}`.
   * Define a central range as :math:`\rm{start}_c = \rm{start} + 0.14 * \rm{range}`, and 
     :math:`\rm{end}_c = \rm{end} - 0.14 * \rm{range}`
   * Define a file as having data in the range if its maximum wavelength is :math:`\ge` 
     :math:`\rm{end}_c`, and its minimum wavelength is :math:`\le` :math:`\rm{start}_c`
   
   Files that do not have data in the range are simply not included when creating the 
   co-added values for that particular order.
.. [#e] These regions are used to divide the overall spectrum into three (-1st order, 
   1st order, and 2nd order). A wavelength being in a particular region does not mean that 
   the wavelength is a valid part of that spectral order (i.e. a wavelength at which the 
   grism has non-zero throughput for that order).
.. [#f] This parameter is passed directly through to `util_grism_cross_correlate.py`_, and 
   is not used directly in co-adding.
.. [#g] It is possible to set the :code:`slope` parameter in order to bypass the trace 
   fitting and use a supplied angle instead.
.. [#h] All of the keywords in this form are multiplied by the current order before use,
   so the actual values are correct only for the 1st order.

.. _WFC3 ISR 2015-10: https://www.stsci.edu/files/live/sites/www/files/home/hst/instrumentation/wfc3/documentation/instrument-science-reports-isrs/_documents/2015/WFC3-2015-10.pdf
.. _WFC3 ISR 2016-15: https://www.stsci.edu/files/live/sites/www/files/home/hst/instrumentation/wfc3/documentation/instrument-science-reports-isrs/_documents/2016/WFC3-2016-15.pdf
.. _Chapter 23 of the WFC3 data handbook: https://www.stsci.edu/itt/review/dhb_2011/WFC3/wfc3_Ch23.html
