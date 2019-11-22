#! /usr/bin/env python
"""
This module contains the ExposureTable class. The class contains a table of
exposure metadata, as well as the ability to export that table in formats
suitable for IDL compatibility, or for further use by later scripts.

Authors
-------
    - Brian York

Use
---
    This module provides the ExposureTable class, which holds an astropy table
    of exposure metadata, along with the ability to present that data either in
    a form expected by IDL, or in a form more suitable for passing on to
    later scripts in abscal.
    ::
        from abscal.common.exposure_data_table import ExposureTable
"""

__all__ = ['ExposureTable']

import argparse
import datetime
import glob
import io
import os

import numpy as np

from astropy.io import ascii, fits
from astropy.table import Table, Column
from astropy.time import Time
from copy import deepcopy

from abscal.common.standard_stars import starlist, find_standard_star_by_name
from abscal.common.utils import absdate


def scan_rate_formatter(scan_rate):
    scan_rate_str = "{:6.4f}".format(scan_rate)
    return "{:<9}".format(scan_rate_str)


class ExposureTable:
    def __init__(self, **kwargs):
        """
        Initialize the class. For the moment, simply set creation metadata.
        
        Parameters
        ----------
        kwargs : dict
            Dictionary of optional keyword arguments. Known kwargs include
                search_str : str
                    String used to search for files.
                search_dirs : list of str
                    Directories in which to search for search_str
                idl_mode : bool
                    Whether to operate in strict IDL mode
                table : string or None
                    Initial table to read in on initialization
                duplicates : string
                    How to handle duplicate entries
        """
        self.creation = datetime.datetime.now()
        self.search_str = kwargs.get('search_str', 'i*flt.fits')
        self.search_dirs = kwargs.get('search_dirs', os.getcwd())
        self.duplicates = kwargs.get('duplicates', 'both')
        if "table" in kwargs and kwargs['table'] is not None:
            idl_mode = kwargs.get("idl_mode", False)
            table_file = kwargs.get("table")
            self._table = self.read_table(table_file, idl_mode, **kwargs)
    
    
    def add_exposure(self, metadata_dict):
        """
        Add a new row to the table from a dictionary built up from an exposure.
        
        Parameters
        ----------
        metadata_dict : dictionary
            A dictionary containing information on a single exposure.
        """
        if not hasattr(self, '_table'):
            column_dict = {}
            for column in metadata_dict:
                column_dict[column] = [metadata_dict[column]]
            self._table = Table(column_dict, names=self.columns)
            for col in self._table.itercols():
                if col.dtype.kind in 'SU':
                    self._table.replace_column(col.name, col.astype('S512'))
            return

        if metadata_dict['root'] in self._table['root']: # duplicate entry
            if self.duplicates == 'both': # deep both
                self._table.add_row(metadata_dict)
            elif self.duplicates == 'preserve': # keep existing, ignore new
                pass
            elif self.duplicates == 'replace': # delete existing, add new
                remove_mask = [self._table['root'] == metadata_dict['root']]
                self._table.remove_rows(remove_mask)
                self._table.add_row(metadata_dict)
            elif self.duplicates == 'neither': # delete both
                remove_mask = [self._table['root'] == metadata_dict['root']]
                self._table.remove_rows(remove_mask)
            else:
                msg = "ERROR: Unknown duplicate policy '{}'"
                raise ValueError(msg.format(self.duplicates))
        return
    
    
    def sort_data(self, sort_list):
        """
        Sort the table by passing on sort_list directly to the internal table.
        
        Parameters
        ----------
        sort_list : str or list
            Either a string matching a column or a list of strings matching
            columns.
        """
        self._table.sort(sort_list)
    
    def read_table(self, file_name, idl_mode, **kwargs):
        """
        Read a metadata table from a file, optionally using IDL for strict
        compatibility. Note that, even if idl_mode is set to False, if reading
        the table fails with the standard method, then the program will attempt 
        to read the table with the IDL reader.
        
        Parameters
        ----------
        file_name : str
            The table file to read.
        idl_mode : bool
            Whether to operate in IDL compatibility mode.
        kwargs : dict
            Optional keyword arguments. Known arguments are:
                format : str
                    Table format to attempt to read.
        
        Returns
        -------
        t : astropy.table.Table
            The table that was read in.
        """
        if idl_mode:
            return self._read_from_idl(file_name)
        format = kwargs.get('format', self.default_format)
        
        t = Table()
        try:
            t = t.read(file_name, format=format)
        except Exception as e:
            print("ERROR: {}".format(e))
            t = self._read_from_idl(file_name)
        
        return t
        
        
        
    def write_table(self, file_name, idl_mode, **kwargs):
        """
        Write the table to a file, optionally using IDL strict compatibility.
        
        Parameters
        ----------
        file_name : str
            The file to write the table to.
        idl_mode : bool
            Whether to write the table in IDL compatibility mode.
        kwargs : dict
            Optional keyword arguments. Known arguments are:
                filters : list
                    List of filters to apply to the table before writing it.
        """
        date_str = self.creation.strftime("%d-%b-%Y %H:%M:%S")
        format = kwargs.get('format', self.default_format)
        filters = kwargs.get('filters', [])
        if not isinstance(filters, list):
            filters = [filters]
        
        table = self._table
        for filter in filters:
            table = self._filter_table(table, filter)
        if len(table) == 0:
            return

        table.comments = []
        table.comments.append("Start time: {}".format(date_str))
        for dir in self.search_dirs:
            search_str = os.path.join(dir, self.search_str)
            table.comments.append("Searched {}".format(search_str))
        for filter in filters:
            table.comments.append("Filtered by: {}".format(filter))
        
        if idl_mode:
            self._write_to_idl(file_name, table)
            return
        
        table.metadata = table.comments
        
        table.write(file_name, format=format, overwrite=True)
    

    @property
    def n_exposures(self):
        """
        Return the number of rows in the table.
        """
        return len(self._table)


    def _filter_table(self, table, filter):
        """
        Filter a table by means of a particular filter. The filter should be
        either a known string value, or a callable which takes an astropy table
        and returns a filtered version of the table.
        
        Parameters
        ----------
        table : astropy.table.Table
            The table to filter
        filter : str or callable
            Either a keyword string or a callable. Known strings are:
                stare : filter out scan_rate > 0.
                scan : filter out scan_rate == 0
                filter : filter out grism data.
                grism : keep all grism data and the closest-in-time filter
                        exposure from the same visit as the grism exposure.
        
        Returns
        -------
        filtered_table : astropy.table.Table
            Filtered table.
        """
        filtered_table = deepcopy(table)
        if isinstance(filter, str):
            if filter == 'stare':
                filtered_table.remove_rows(filtered_table['scan_rate'] > 0.)
            elif filter == 'scan':
                filtered_table.remove_rows(filtered_table['scan_rate'] == 0.)
            elif filter == 'filter':
                filter_list = [f[0] != 'F' for f in filtered_table['filter']]
                filtered_table.remove_rows(filter_list)
            elif filter == 'grism':
                filtered_table = self._grism_filter(filtered_table)
        else:
            filtered_table = filter(filtered_table)

        return filtered_table


    def _grism_filter(self, table):
        """
        Filter the table as follows:
            - keep all grism exposures
            - for each grism exposure:
                - if there is at least one filter exposure from the same
                  program and visit,
                    - keep the filter exposure closest in time to the grism
                - else annotate the grism that no corresponding filter was found
        
        Parameters
        ----------
        table : astropy.table.Table
            The table to filter.
        
        Returns
        -------
        filtered_table : astropy.table.Table
            The filtered table.
        """
        grism_table = deepcopy(table)
        grism_list = [f[0] != 'G' for f in grism_table['filter']]
        grism_table.remove_rows(grism_list)
        grism_check_table = deepcopy(grism_table)
        
        filter_table = deepcopy(table)
        filter_list = [f[0] != 'F' for f in filter_table['filter']]
        filter_table.remove_rows(filter_list)
        
        for row in grism_check_table:
            program_visit = row['root'][:6]
            check_mask = [r[:6] == program_visit for r in filter_table['root']]
            check_table = filter_table[check_mask]
            if len(check_table) > 0:
                check_dates = [abs(row['date']-t) for t in check_table['date']]
                minimum_time_index = check_dates.index(min(check_dates))
                minimum_time_row = check_table[minimum_time_index]
                if minimum_time_row['root'] not in grism_table['root']:
                    grism_table.add_row(minimum_time_row)
            else:
                row_mask = [r == row['root'] for r in grism_table['root']]
                msg = "No corresponding filter exposure found."
                grism_table[row_mask]["note"] += " {}".format(msg)
        
        grism_table.sort(['root'])
        return grism_table
    
    
    def _write_to_idl(self, file_name, table):
        """
        Write the table in strict IDL mode.
        
        Parameters
        ----------
        file_name : str
            The file to write to.
        table : astropy.table.Table
            The (filtered) table to write
        """
        if len(table) == 0:
            return
        
        column_formats = {
                            "ROOT": "<10",
                            "MODE": "<7",
                            "APER": "<15",
                            "TYPE": "<5",
                            "TARGET": "<12",
                            "IMG SIZE": "<9",
                            "DATE": "<8",
                            "TIME": "<8",
                            "PROPID": "<6",
                            "EXPTIME": "7.1f",
                            "POSTARG X,Y": ">14",
                            "SCAN_RAT": scan_rate_formatter
                         }
        column_mappings = {
                            "ROOT": "root",
                            "MODE": "filter",
                            "APER": "aperture",
                            "TYPE": "exposure_type",
                            "TARGET": "target",
                            "PROPID": "proposal",
                            "EXPTIME": "exptime",
                            "SCAN_RAT": "scan_rate"
                          }
        
        idl_table = Table()
        for column in self.idl_columns:
            if column in column_mappings:
                data = table[column_mappings[column]]
            elif column == "IMG SIZE:
                xsize = table["xsize"]
                ysize = table["ysize"]
                data = ["{:4d}x{:4d}".format(x,y) for x,y in zip(xsize,ysize)]
            elif column == "DATE":
                data = [d.strftime("%y-%m-%d") for d in table["date"]]
            elif column == "TIME":
                data = [d.strftime("%H:%M:%S") for d in table["date"]]
            elif column == "POSTARG X,Y":
                p1 = table["postarg1"]
                p2 = table["postarg2"]
                data = ["{:6.1f}, {:6.1f}".format(x,y) for x,y in zip(p1,p2)]
            else:
                msg = "Trying to create nonexistent column {}".format(column)
                raise ValueError(msg)
            format = column_formats[column]
            idl_table[column] = Column(data, name=column, format=format)
        
        idl_table.write(file_name,
                        format='ascii.fixed_width',
                        delimiter=' ',
                        delimiter_pad=None,
                        bookend=False,
                        overwrite=True)
        
        date_str = self.creation.strftime("%d-%b-%Y %H:%M:%S")
        with open(file_name, 'r+') as table_file:
            content = table_file.read()
            table_file.seek(0, 0)
            table_file.write("# WFCDIR {}\n".format(date_str))
            for dir in self.search_dirs:
                search_str = os.path.join(dir, self.search_str)
                table_file.write("# SEARCH FOR {}\n".format(search_str))
            table_file.write(content)

        return

    
    def _read_from_idl(self, table_file):
        """
        Reads in an IDL-formatted text table, and turns it into a standard
        format.
        
        Parameters
        ----------
        table_file : str
            The file to read.
        
        Returns
        -------
        t : astropy.table.Table
            Table, in the standard internal format, read from the IDL table. The
            notes column will be set to zero automatically.
        """
        parse_fn = datetime.datetime.strptime
        parse_str = "%y-%m-%d %H:%M:%S"
        
        idl_table = ascii.read(table_file, 
                               format="fixed_width",
                               col_starts=idl_column_start)
        
        t = Table()
        t['root'] = idl_table['ROOT']
        t['filter'] = idl_table['MODE']
        t['aperture'] = idl_table['APER']
        t['exposure_type'] = idl_table['TYPE']
        t['target'] = idl_table['TARGET']
        img_x = [int(i[:4].strip()) for i in idl_table['IMG SIZE']]
        t['xsize'] = Column(img_x)
        img_y = [int(i[5:].strip()) for i in idl_table['IMG SIZE']]
        t['ysize'] = Column(img_y)
        dt = zip(idl_table["DATE"], idl_table["TIME"])
        dates = [parse_fn("{} {}".format(d,t), parse_str) for d,t in dt]
        t['date'] = Column(dates)
        t['proposal'] = idl_table["PROPID"]
        t['exptime'] = idl_table["EXPTIME"]
        postarg_1 = [float(p[:6].strip()) for p in idl_table["POSTARG X,Y"]]
        t['postarg1'] = Column(postarg_1)
        postarg_2 = [float(p[8:].strip()) for p in idl_table["POSTARG X,Y"]]
        t['postarg2'] = Column(postarg_2)
        t['scan_rate'] = idl_table["SCAN_RAT"]
        t['notes'] = Column(["" for r in idl_table["ROOT"]])
        t.comments = idl_table.comments
        
        return t


    columns = [
                'root', 
                'filter', 
                'aperture', 
                'exposure_type', 
                'target', 
                'xsize',
                'ysize',
                'date',
                'proposal',
                'exptime', 
                'postarg1',
                'postarg2',
                'scan_rate',
                'notes'
              ]

    
    idl_columns = [
                    'ROOT',
                    'MODE',
                    'APER',
                    'TYPE',
                    'TARGET',
                    'IMG SIZE',
                    'DATE',
                    'TIME',
                    'PROPID',
                    'EXPTIME',
                    'POSTARG X,Y',
                    'SCAN_RAT'
                  ]
    idl_column_start = (
                        0,
                        11,
                        19,
                        35, 
                        41, 
                        54, 
                        64, 
                        73, 
                        82, 
                        89, 
                        98, 
                        112
                       )
    
    
    default_format = 'ascii.ipac'

# This is the only way that I've figured out to actually read in correctly.
#t = ascii.read("dirtemp_all.log", format="fixed_width", col_starts=(0, 11, 19, 35, 41, 54, 64, 73, 82, 89, 98, 112))
