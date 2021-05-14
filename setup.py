from setuptools import setup
from setuptools import find_packages

import glob
import os

main_scripts = glob.glob("abscal/commands/*")
idl_scripts = glob.glob("abscal/idl_commands/*")

file_dir = os.path.abspath(__file__)
version_str = '0.0.dev7'
# jist_dir = os.path.join(os.path.dirname(file_dir), "jist", "__init__.py")
# with open(jist_dir) as inf:
#     version_str = inf.readline().strip()

setup(
    name = 'abscal',
    description = 'HST WFC3 and STIS absolute flux calibration',
    url = 'https://github.com/spacetelescope/ABSCAL',
    author = 'Brian York, Ralph Bohlin, Susana Deustua',
    author_email = 'york@stsci.edu, bohlin@stsci.edu, deustua@stsci.edu',
    keywords = ['astronomy'],
    classifiers = ['Programming Language :: Python'],
    packages = find_packages(),
    install_requires = [
                        "numpy", 
                        "scipy", 
                        "astropy>=3", 
                        "photutils",
                       ],
    version = version_str,
    scripts=main_scripts+idl_scripts,
    include_package_data=True
    )
