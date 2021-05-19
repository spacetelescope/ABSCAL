ABSCAL Data Files
=================

ABSCAL stores many of its operating parameters, and exposure-specific settings, in a 
number of parameter files. ABSCAL keeps copies of these files internally (and updates them 
in the process of updating the repository), but it's also possible to create a local copy 
of these files, and tell ABSCAL where to find them by setting the :code:`ABSCAL_DATA` 
environment variable.

.. contents:: Contents
    :local:
    :depth: 2


Directory Structure
-------------------

ABSCAL data files are stored in a directory structure that mimics the structure used 
within the module itself::

    abscal/
        commands/
        common/
            data/
                standard_stars.yaml
        data/
        stis/
            data/
        wfc3/
            data/
                defaults/
                    reduce_grism_coadd.yaml
                    reduce_grism_extract.yaml
                    util_grism_cross_correlate.yaml
                calibration_files.yaml
                image_edits.yaml
                metadata.yaml
                reduce_grism_coadd.yaml
                reduce_grism_extract.yaml
                reduce_grism_wavelength.yaml
                util_filter_locate_image.yaml

Note that, if a data file is fetched by :code:`abscal.common.utils.get_data_file()` then 
the :code:`data` directory will be automatically appended to whatever module path is 
supplied to the function. If, instead, it is fetched by the 
:code:`abscal.common.utils.get_defaults()` function, then both :code:`data` and 
:code:`defaults` directories are automatically appended.

File Structure
--------------

ABSCAL data files are stored as `YAML <https://yaml.org>`_ files, which is intended as a 
relatively straightforward text file structure that also allows for comment lines. Each of 
the internal data files includes comments that specify the file structure, and what is 
expected to be at each level.

Exposure-specific Values
------------------------

It is possible to use data files to store exposure-specific values that deal with specific 
issues or characteristics encountered in single exposures. By creating these files, it is 
possible to edit the exposure image, adjust the exposure metadata values in the table of 
exposures, or adjust parameter values for a single exposure. In order to do this, ABSCAL 
defines a number of data files.

abscal/<instrument>/data/metadata.yaml: Edit table metadata
    These files allow table metadata to be changed. For example, if a file has the wrong 
    program or visit information, or the filter keyword is inaccurate, those values can 
    be changed in these files.
abscal/<instrument>/data/image_edits.yaml: Edit exposure data
    These files allow for data values in exposures to be changed. This allows DQ flags to 
    be set or removed, or unflagged bad pixels to be edited out.
abscal/<instrument>/data/<submodule>.yaml: Edit parameters
    These files (one for each submodule for an instrument) allow the default parameters to 
    be changed for a single exposure.

All of these files are commented with formatting information.
