************
Installation
************

STIPS is a simulation tool that depends on other modules such as PSF and exposure time calculators.
These underlying submodules need to be installed for STIPS to function properly along with their supporting datasets.
There are multiple options for installation and they are listed in this section along with instructions.

STIPS Requirements
##################

* `Pandeia`: Exposure time calculator.
* `WebbPSF`: James Webb and Nancy Grace Roman PSF calculator.
* `astropy`: STIPS uses astropy in order to:

	- Read and write FITS files.
	- Read and write ASCII tables (specifically in the IPAC format).
	- Generate Sersic profile models (if any are in the generated scene).

* `esutil`: Used for retrieving data from sqlite databases in the form of numpy arrays.
* `montage_wrapper`: STIPS uses montage to generate mosaics. It is only imported if
  STIPS is asked to generate a multi-detector image.
* `numpy`: STIPS uses numpy extensively for almost everything that it does.
* `photutils`: STIPS uses photutils to determine the flux inside the half-light radius
  in generated Sersic profiles.
* `synphot` and `stsynphot`: STIPS uses synphot and stsynphot to generate 
  bandpasses, count rates, and zero points. Note that the reference data must
  also be downloaded, as described below in "Doanloading Required Data".
* `scipy`: STIPS uses scipy to manipulate its internal images (zoom and rotate).

Finally, STIPS requires a set of data files whose location is marked by setting the environment
variable `stips_data`. The current version of the STIPS data is located on box and can be downloaded via the link below.

Downloading STIPS Data
#######################

STIPS needs data for reference and calibration. The latest version of the STIPS data can be downloaded as follows::

    # Use wget ot curl to download the data
    $ wget https://stsci.box.com/shared/static/iufbhsiu0lts16wmdsi12cun25888nrb.gz -O stips_data.tar.gz

    # Unpack the data
    $ tar -xzvf stips_data.tar.gz

    # Point the stips environment variable in your bash profile or in terminal
    $ export stips_data=<absolute_path_to_this_folder>/stips_data


Installing Using Conda and Source
##################################

STIPS can be installed using the source code and a Conda environment file.
If you do not have anaconda or miniconda installed, please visit the `astroconda docs <https://astroconda.readthedocs.io/en/latest/getting_started.html>`_ for installation instructions.
We have included a Conda environment file for easily installing or updating Conda packages to meet STIPS requirements.
Please follow the steps below to install STIPS:

Installing
**********

1. You will need to clone the ABSCAL source code from the 
   `github repository <https://github.com/spacetelescope/ABSCAL>`_. `cd` into the 
   directory where you would like to store the source code and run::

    git clone https://github.com/spacetelescope/ABSCAL.git

    cd ABSCAL

2. The environment file can be used in two ways:

    a. To create a new Conda environment named `abscal` run::

        conda env create -f environment.yml

        conda activate abscal


    b. To install to or update an existing (currently active) Conda environment::

        conda env update --file environment.yml


3. You can now install ABSCAL using the cloned source code as follows::

    python setup.py install
