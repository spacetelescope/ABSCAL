Using ABSCAL WFC3 Scripts
=========================

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

For more detail, `see the API reference <../autoapi/abscal/wfc3/preprocess_table_create/index.html>`_. 

:code:`reduce_grism_coadd.py`
-----------------------------

