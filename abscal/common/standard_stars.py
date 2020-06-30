#! /usr/bin/env python
"""
This module includes a list of standard stars used by STScI for flux 
calibration, along with their canonical names and, for each, a set of names
that are known to be used by PIs when filling in the target name in APT (and
thus may be present in the TARGNAME field). In addition, the list contains the
RA and DEC values for the standard stars, along with their proper motion data.

Authors
-------
    - Brian York

Use
---
    This module is intended to be imported as a reference.
    ::
        from abscal.common.standard_stars import star_list
"""

__all__ = ['starlist', 'find_standard_star_by_name']


#*****
#*****
# GAL COORDINATES ARE NOT ACCURATE IN THE SENSE OF RA AND DEC
#*****
#*****

starlist =  [
                {
                    'name': 'GAIA587_3008',
                    'ra': 223.75403,
                    'dec': -60.215841,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['GAIA587_3008']
                },
                {
                    'name': '6822HV',
                    'ra': 269.6278,
                    'dec': -59.1826,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -4.783,
                    'pm_dec': 3.510,
                    'planetary_nebula': False,
                    'names': ['6822HV', '6822-HV']
                },
                {
                    'name': 'GD153',
                    'ra': 194.2597,
                    'dec': 22.0313,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -38.410,
                    'pm_dec': -202.953,
                    'planetary_nebula': False,
                    'names': ['GD153', 'GD-153']
                },
                {
                    'name': 'GD71',
                    'ra': 88.1151,
                    'dec': 15.8870,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 76.841,
                    'pm_dec': -172.944,
                    'planetary_nebula': False,
                    'names': ['GD71', 'GD-71']
                },
                {
                    'name': 'G191B2B',
                    'ra': 76.3776,
                    'dec': 52.8311,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 12.592,
                    'pm_dec': -93.525,
                    'planetary_nebula': False,
                    'names': ['191B2B', 'BD+52-913', '191-B2B', 'EGGR-247']
                },
                {
                    'name': 'GRW_70D5824',
                    'ra': 204.7103,
                    'dec': 70.2854,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -402.093,
                    'pm_dec': -24.608,
                    'planetary_nebula': False,
                    'names': ['GRW_70D5824', 'HIP66578', 'HIP-66578', 
                              'EGGR-102', '70D5824']
                },
                {
                    'name': 'P330E',
                    'ra': 247.8909,
                    'dec': 30.1462,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -8.991,
                    'pm_dec': -38.768,
                    'planetary_nebula': False,
                    'names': ['P330E', 'GSC-02581-02323', '02581-02323']
                },
                {
                    'name': 'KF06T2',
                    'ra': 269.6583,
                    'dec': 66.7811,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.620,
                    'pm_dec': -4.419,
                    'planetary_nebula': False,
                    'names': ['KF06T2', 'J17583798+6646522', 'J17583798',
                              '2MASS J17583798+6646522',
                              '2MASS-J17583798+6646522']
                },
                {
                    'name': 'VB8',
                    'ra': 253.8969,
                    'dec': -8.3946,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -813.418,
                    'pm_dec': -870.611,
                    'planetary_nebula': False,
                    'names': ['VB8', 'VB 8', 'VB-8', 'GJ644C']
                },
                {
                    'name': '1802271',
                    'ra': 270.6132,
                    'dec': 60.7266,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['1802271', '180227', '2MASS J18022716+6043356']
                },
                {
                    'name': 'WD1657_343',
                    'ra': 254.7130,
                    'dec': 34.3148,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 8.766,
                    'pm_dec': -31.227,
                    'planetary_nebula': False,
                    'names': ['WD1657_343', 'WD1657', 'WD1657+343']
                },
                {
                    'name': 'HD116405',
                    'ra': 200.6880,
                    'dec': 44.7150,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 8.008,
                    'pm_dec': -10.290,
                    'planetary_nebula': False,
                    'names': ['HD116405', '116405']
                },
                {
                    'name': 'HD205905',
                    'ra': 324.7923,
                    'dec': -27.3066,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 384.102,
                    'pm_dec': -83.962,
                    'planetary_nebula': False,
                    'names': ['HD205905', '205905']
                },
                {
                    'name': 'HD37725',
                    'ra': 85.4765,
                    'dec': 29.2975,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 15.052,
                    'pm_dec': -26.928,
                    'planetary_nebula': False,
                    'names': ['HD37725', '37725']
                },
                {
                    'name': 'HD38949',
                    'ra': 87.0836,
                    'dec': -24.4638,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -30.436,
                    'pm_dec': -35.423,
                    'planetary_nebula': False,
                    'names': ['HD38949', '38949']
                },
                {
                    'name': 'HD60753',
                    'ra': 113.3638,
                    'dec': -50.5842,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -3.124,
                    'pm_dec': 5.310,
                    'planetary_nebula': False,
                    'names': ['HD60753', '60753']
                },
                {
                    'name': 'HD93521',
                    'ra': 162.0980,
                    'dec': 37.5703,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.220,
                    'pm_dec': 1.717,
                    'planetary_nebula': False,
                    'names': ['HD93521', '93521']
                },
                {
                    'name': '2M003618',
                    'ra': 9.0671,
                    'dec': 18.3528,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 901.558,
                    'pm_dec': 124.019,
                    'planetary_nebula': False,
                    'names': ['2M003618', 'J00361', 'LSPM J0036+1821']
                },
                {
                    'name': '2M055914',
                    'ra': 89.8300,
                    'dec': -14.0803,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 570.199,
                    'pm_dec': -337.592,
                    'planetary_nebula': False,
                    'names': ['2M055914', 'J05591', '2MASS J05591914-1404488']
                },
                {
                    'name': '1757132',
                    'ra': 269.3051,
                    'dec': 67.0613,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.408,
                    'pm_dec': -14.027,
                    'planetary_nebula': False,
                    'names': ['1757132', '17571', '2MASS J17571324+6703409']
                },
                {
                    'name': 'HD37962',
                    'ra': 85.2165,
                    'dec': -31.3511,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -59.648,
                    'pm_dec': -365.227,
                    'planetary_nebula': False,
                    'names': ['HD37962', '37962', 'LTT-2351', 'LTT2351']
                },
                {
                    'name': 'BD60D1753',
                    'ra': 261.2178,
                    'dec': 60.4308,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 3.981,
                    'pm_dec': 1.809,
                    'planetary_nebula': False,
                    'names': ['BD60D1753', 'BD+60-1753', 'BD +60 1753']
                },
                {
                    'name': '180347',
                    'ra': 288.4116,
                    'dec': 50.9086,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 15.870,
                    'pm_dec': -25.239,
                    'planetary_nebula': False,
                    'names': ['180347', 'HD 180347', 'HD180347']
                },
                {
                    'name': 'HD180609',
                    'ra': 288.1967,
                    'dec': 64.1770,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -3.059,
                    'pm_dec': -7.790,
                    'planetary_nebula': False,
                    'names': ['HD180609', '180609']
                },
                {
                    'name': 'SNAP2',
                    'ra': 244.9421,
                    'dec': 55.5716,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': -2.911,
                    'pm_dec': -10.952,
                    'planetary_nebula': False,
                    'names': ['SNAP2', 'SNAP-2', 'SNAP 2', 
                              '2MASS J16194609+5534178']
                },
                {
                    'name': 'C26202',
                    'ra': 53.1368,
                    'dec': -27.8635,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['C26202', 'C 26202', 'C-26202', 'GOODS-S',
                              '2MASS J03323287-2751483']
                },
                {
                    'name': 'GAIA593_9680',
                    'ra': 243.54954,
                    'dec': -51.781001,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['GAIA593_9680']
                },
                {
                    'name': 'GAIA587_8560',
                    'ra': 230.18496,
                    'dec': -58.453704,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['GAIA587_8560']
                },
                {
                    'name': 'GAIA588_7712',
                    'ra': 234.55682,
                    'dec': -54.522627,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['GAIA588_7712']
                },
                {
                    'name': 'GAIA405_6912',
                    'ra': 267.32024,
                    'dec': -29.210493,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': False,
                    'names': ['GAIA405_6912']
                },
                {
                    'name': 'IC5117',
                    'ra': 323.12904167,
                    'dec': 21.54193611,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': True,
                    'names': ['IC5117', 'IC-5117', 'IC_5117', 'IC 5117']
                },
                {
                    'name': 'VY22',
                    'ra': 291.09266258,
                    'dec': 9.89896083,
                    'coord_type': 'icrs',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'planetary_nebula': True,
                    'names': ['VY22', 'VY2-2', 'VY2-2 copy', 'PN VY 2-2', 
                              'VY 2-2']
                },
            ]


def find_standard_star_by_name(name):
    """
    Goes through the list of standard stars, looking for one with the same name
    as was provided. If it finds one, returns it. If not, returns None
    """
    for star in starlist:
        if star['name'] == name:
            return star
    return None


