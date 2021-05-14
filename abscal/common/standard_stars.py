#! /usr/bin/env python
"""
This module includes a list of standard stars used by STScI/ABSCAL for flux
calibration, along with their canonical names and, for each, a set of names
that are known to be used by PIs when filling in the target name in APT (and
thus may be present in the TARGNAME field). In addition, the list contains the
RA and DEC values for the standard stars, along with their proper motion data.

Authors
-------
- Brian York

Use
---
This module is intended to be imported if you need to get information about a particular
standard star, and have its name (or the value in the TARGNAME field)::

    from abscal.common.standard_stars import find_star_by_name

You can also import starlist directly if you have some other need for the ABSCAL standard 
star list::

    from abscal.common.standard_stars import starlist
"""

import yaml

from astropy import units as u
from astropy.coordinates import Angle, SkyCoord

from abscal.common.utils import get_data_file

starlist_data = get_data_file('abscal.common', 'standard_stars.yaml')
with open(starlist_data, 'r') as inf:
    starlist = yaml.safe_load(inf)

def find_star_by_name(name):
    """
    Finds the standard star with a matching name.
    
    Goes through the list of standard stars, looking for one with the same name
    as was provided. If it finds one, returns it. If not, returns None.
    
    Parameters
    ----------
    name : str
        The name to look for
    
    Returns
    -------
    star : dict
        The found star (or None if none was found)
    """
    for star in starlist:
        if star['name'] == name:
            return star
    return None


def find_closest_star(ra, dec, max_distance=None):
    """
    Finds the closest standard star on the sky.
    
    Goes through the list of standard stars, looking for the closest co-ordinate match, 
    and returning that standard (or, optionally, if max_distance is set to a positive 
    value, returning None if no star in the list is within max_distance).
    
    Parameters
    ----------
    ra : float
        RA in decimal degrees
    dec : float
        DEC in decimal degrees
    max_distance : float, default None
        If set, the maximum distance (in arcseconds) for a match to be valid.
    
    Returns
    -------
    star : dict
        The found star (or None if none is found)
    """
    search_coord = SkyCoord(ra, dec, unit=u.deg)

    start_coord = SkyCoord(starlist[0]['ra'], starlist[0]['dec'], unit=u.deg)
    min_separation = search_coord.separation(start_coord).to(u.arcsec).value
    min_index = 0
    
    for i,star in enumerate(starlist):
        star_coord = SkyCoord(star['ra'], star['dec'], unit=u.deg)
        if search_coord.separation(star_coord).to(u.arcsec).value < min_separation:
            min_separation = search_coord.separation(star_coord).to(u.arcsec).value
            min_index = i
    
    if (max_distance is not None) and (min_separation > max_distance):
        return None
    
    return starlist[min_index]
