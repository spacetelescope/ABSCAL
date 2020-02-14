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


starlist =  [
                {
                    'name': 'GAIA593_9680',
                    'ra': 243.54954,
                    'dec': -51.781001,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['GAIA593_9680']
                },
                {
                    'name': 'GAIA587_8560',
                    'ra': 230.18496,
                    'dec': -58.453704,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['GAIA587_8560']
                },
                {
                    'name': 'GAIA588_7712',
                    'ra': 234.55682,
                    'dec': -54.522627,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['GAIA588_7712']
                },
                {
                    'name': 'GAIA405_6912',
                    'ra': 267.32024,
                    'dec': -29.210493,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['GAIA405_6912']
                },
                {
                    'name': 'GAIA587_3008',
                    'ra': 223.75403,
                    'dec': -60.215841,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['GAIA587_3008']
                },
                {
                    'name': '6822HV',
                    'ra': 334.3073,
                    'dec': -16.6928,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -4.783,
                    'pm_dec': 3.510,
                    'names': ['6822HV', '6822-HV']
                },
                {
                    'name': 'GD153',
                    'ra': 317.2550,
                    'dec': 84.7466,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -38.410,
                    'pm_dec': -202.953,
                    'names': ['GD153', 'GD-153']
                },
                {
                    'name': 'GD71',
                    'ra': 192.0286,
                    'dec': -5.3382,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 76.841,
                    'pm_dec': -172.944,
                    'names': ['GD71', 'GD-71']
                },
                {
                    'name': 'G191B2B',
                    'ra': 155.9533,
                    'dec': 7.0990,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 12.592,
                    'pm_dec': -93.525,
                    'names': ['191B2B', 'BD+52-913', '191-B2B', 'EGGR-247']
                },
                {
                    'name': 'GRW_70D5824',
                    'ra': 117.1761,
                    'dec': 46.3094,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -402.093,
                    'pm_dec': -24.608,
                    'names': ['GRW_70D5824', 'HIP66578', 'HIP-66578', 
                              'EGGR-102', '70D5824']
                },
                {
                    'name': 'P330E',
                    'ra': 50.2508,
                    'dec': 42.0737,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -8.991,
                    'pm_dec': -38.768,
                    'names': ['P330E', 'GSC-02581-02323', '02581-02323']
                },
                {
                    'name': 'KF06T2',
                    'ra': 96.6388,
                    'dec': 29.9458,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.620,
                    'pm_dec': -4.419,
                    'names': ['KF06T2', 'J17583798+6646522', 'J17583798']
                },
                {
                    'name': 'VB8',
                    'ra': 11.0082,
                    'dec': 21.0866,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -813.418,
                    'pm_dec': -870.611,
                    'names': ['VB8', 'VB 8', 'VB-8', 'GJ644C']
                },
                {
                    'name': '1802271',
                    'ra': 89.6890,
                    'dec': 29.3446,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['1802271', '180227', 'HD J18022716+6043356']
                },
                {
                    'name': 'WD1657_343',
                    'ra': 56.9193,
                    'dec': 37.1438,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 8.766,
                    'pm_dec': -31.227,
                    'names': ['WD1657_343', 'WD1657', 'WD1657+343']
                },
                {
                    'name': 'HD116405',
                    'ra': 105.3341,
                    'dec': 71.3279,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 8.008,
                    'pm_dec': -10.290,
                    'names': ['HD116405', '116405']
                },
                {
                    'name': 'HD205905',
                    'ra': 21.1794,
                    'dec': -47.5316,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 384.102,
                    'pm_dec': -83.962,
                    'names': ['HD205905', '205905']
                },
                {
                    'name': 'HD37725',
                    'ra': 179.2670,
                    'dec': -0.5012,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 15.052,
                    'pm_dec': -26.928,
                    'names': ['HD37725', '37725']
                },
                {
                    'name': 'HD38949',
                    'ra': 229.2065,
                    'dec': -24.1467,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -30.436,
                    'pm_dec': -35.423,
                    'names': ['HD38949', '38949']
                },
                {
                    'name': 'HD60753',
                    'ra': 262.7926,
                    'dec': -14.4333,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -3.124,
                    'pm_dec': 5.310,
                    'names': ['HD60753', '60753']
                },
                {
                    'name': 'HD93521',
                    'ra': 183.1403,
                    'dec': 62.1520,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.220,
                    'pm_dec': 1.717,
                    'names': ['HD93521', '93521']
                },
                {
                    'name': '2M003618',
                    'ra': 117.8937,
                    'dec': -44.3704,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 901.558,
                    'pm_dec': 124.019,
                    'names': ['2M003618', 'J00361', 'LSPM J0036+1821']
                },
                {
                    'name': '2M055914',
                    'ra': 219.9782,
                    'dec': -17.7916,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 570.199,
                    'pm_dec': -337.592,
                    'names': ['2M055914', 'J05591', '2MASS J05591914-1404488']
                },
                {
                    'name': '1757132',
                    'ra': 96.9644,
                    'dec': 30.0808,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.408,
                    'pm_dec': -14.027,
                    'names': ['1757132', '17571', '2MASS J17571324+6703409']
                },
                {
                    'name': 'HD37962',
                    'ra': 235.9064,
                    'dec': -27.8785,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -59.648,
                    'pm_dec': -365.227,
                    'names': ['HD37962', '37962', 'LTT-2351', 'LTT2351']
                },
                {
                    'name': 'BD60D1753',
                    'ra': 89.3590,
                    'dec': 33.9569,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 3.981,
                    'pm_dec': 1.809,
                    'names': ['BD60D1753', 'BD+60-1753']
                },
                {
                    'name': '180347',
                    'ra': 81.7980,
                    'dec': 17.4343,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 15.870,
                    'pm_dec': -25.239,
                    'names': ['180347', 'HD 180347']
                },
                {
                    'name': 'HD180609',
                    'ra': 95.0454,
                    'dec': 21.9867,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -3.059,
                    'pm_dec': -7.790,
                    'names': ['HD180609', '180609']
                },
                {
                    'name': 'SNAP2',
                    'ra': 85.1636,
                    'dec': 43.2612,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': -2.911,
                    'pm_dec': -10.952,
                    'names': ['SNAP2', 'SNAP-2', 'SNAP 2', 
                              '2MASS J16194609+5534178']
                },
                {
                    'name': 'C26202',
                    'ra': 223.6715,
                    'dec': -54.4280,
                    'coord_type': 'gal',
                    'coord_epoch': 'J2000',
                    'pm_ra': 0.,
                    'pm_dec': 0.,
                    'names': ['C26202', 'C 26202', 'C-26202', 'GOODS-S',
                              '2MASS J03323287-2751483']
                }
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


