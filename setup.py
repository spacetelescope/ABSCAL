#!/usr/bin/env python

# Licensed under a 3-clause BSD style license - see LICENSE.rst

import builtins

from setuptools import setup
from setuptools.config import read_configuration

# Create a dictionary with setup command overrides. Note that this gets
# information about the package (name and version) from the setup.cfg file.
cmdclass = register_commands()

# Freeze build information in version.py. Note that this gets information
# about the package (name and version) from the setup.cfg file.
version = generate_version_py()

# Get configuration information from all of the various subpackages.
# See the docstring for setup_helpers.update_package_files for more
# details.
package_info = get_package_info()

setup(version=version, cmdclass=cmdclass, **package_info)
