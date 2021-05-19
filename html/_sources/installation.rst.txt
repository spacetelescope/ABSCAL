Installing ABSCAL
=================

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


3. You can now install ABSCAL from the repository, either by using its setup script 
   directly::

        python setup.py install
   
   or by installing via pip::
   
        pip install [-e] .
    
   where the :code:`-e` flag makes the installation editable, and is useful if you intend 
   to modify your local version.
