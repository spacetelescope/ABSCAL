ABSCAL IDL Code
===============

This section describes the ABSCAL IDL code.

General Notes
-------------

In general, the running IDL code has been modified from its original form in the following
ways:

* Programs ask for a directory on startup, and will look for input files (and write 
  output files) in that directory
* Hard-coded paths have been renamed to be relative to either the working directory 
  (discussed above) or an environment variable
* Input and output file names still have default values, but are *also* accepted as 
  keyword arguments when running the script

These changes were needed in order to make it actually possible to run the IDL code.

Environment Variables
---------------------

The following general environment variables need to be set to run the ABSCAL IDL code:

* **IDL_PATH**: This must include `ABSCAL/idl_code/common`, and `ABSCAL/idl_code/<ins>`,
  where `<ins>` is replaced by the name of each instrument you wish to be able to run,
  and where `ABSCAL` is the path to the ABSCAL repository.

Contents
--------

.. toctree::
  :maxdepth: 2

  abscal_idl_code/wfc3


Support Statement and Disclaimer
--------------------------------

The IDL code is found in the "idl_code" directory of the ABSCAL repository. The IDL code 
is in no way officially supported by STScI, and no guarantee is made that the code will
either run or produce correct output when run. STScI is under no obligation to provide any
sort of environment in which to execute the IDL code. IDL is owned by 
`L3Harris Technologies Inc <https://www.l3harrisgeospatial.com>`_, and IDL legal and
copyright notices can be found at 
`the L3Harris website <https://www.l3harrisgeospatial.com/docs/legalandcopyrightnotices.html>`_.
