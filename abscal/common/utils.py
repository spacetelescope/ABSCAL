#! /usr/bin/env python
"""
This module includes utility functions that might be used by any instrument.

Authors
-------
    - Brian York

Use
---
    Individual functions from this module are intended to be imported where
    needed.
    ::
        from abscal.common.utils import absdate
"""

__all__ = ['absdate']

from astropy.time import Time
from datetime import datetime

from .standard_stars import starlist


def absdate(pstrtime):
    # '2013.057:04:24:48'
    # pstrtime is in the format yyyy.ddd:hh:mm:ss where 'ddd' is the decimal 
    #   date (i.e. January 1 is 001, January 31 is 031, February 1 is 032,
    #   December 31 is 365 or 366 depending on leap year status)
    if isinstance(pstrtime, datetime):
        dt = pstrtime
    elif isinstance(pstrtime, Time):
        dt = pstrtime.datetime
    else:
        dt = datetime.strptime(pstrtime, "%Y.%j:%H:%M:%S")
    next_year = datetime(year=dt.year+1, month=1, day=1)
    this_year = datetime(year=dt.year, month=1, day=1)
    year_part = dt - this_year
    year_length = next_year - this_year
    return dt.year + year_part/year_length

