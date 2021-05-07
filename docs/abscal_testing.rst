ABSCAL Testing
==============

This section describes the ABSCAL testing philosophy along with specific examples of the
current test status (where available).

.. toctree::
  :maxdepth: 2

  abscal_testing/wfc3

General Testing Philosophy
--------------------------

The general philosophy of ABSCAL testing is that the python scripts should, when given the
same inputs, produce the same outputs as the IDL code. In principle,

* If it is possible, the same inputs should generate the same outputs to within machine
  precision
* If that is not possible, the disgreement should be <1% (or <1 pixel), whichever makes
  more sense in a particular case.
* In cases where a discrepancy does not affect the final result, the above point may be
  waved as long as the agreement is sufficiently close to produce the same final output.

As an example, in the ABSCAL WFC3 IR GRISM mode, ABSCAL finds the location of the 
zeroth-order target image in order to build its search box for the spectrum (in order to,
in turn, extract that spectrum). The exact centroid location of the zeroth-order image is
not critical to the extraction process, so a disagreement of >1 pixel would be permitted
as long as both the IDL and the python code find the extraction trace in the same 
location, and produce the same extracted spectrum.

As another example, in the final output grism spectra, the disagreement in wavelength 
ranges with non-zero throughput must be within 1%. However, in regions between spectral
orders, much larger relative disagreement may be tolerated because there is no useful
data in those locations.
