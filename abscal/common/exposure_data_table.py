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


def scan_rate_formatter(scan_rate):
    scan_rate_str = "{:6.4f}".format(scan_rate)
    return "{:<9}".format(scan_rate_str)


class AbscalDataTable(Table):
    def __init__(self, data=None, masked=None, names=None, dtype=None,
                 meta=None, copy=True, rows=None, copy_indices=True, **kwargs):
        """
        Initialize the table. For the moment, look for abscal-specific metadata
        and otherwise pass everything along to the superclass.
        
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
        # Persistent Metadata
        self.create_time = datetime.datetime.now()
        self.search_str, kwargs = self._get_kwarg('search_str', 'i*flt.fits', kwargs)
        self.search_dirs, kwargs = self._get_kwarg('search_dirs', os.getcwd(), kwargs)
        self.duplicates, kwargs = self._get_kwarg('duplicates', 'both', kwargs)
        
        # Creation Flags
        idl_mode, kwargs = self._get_kwarg('idl', False, kwargs)
        initial_table, kwargs = self._get_kwarg('table', None, kwargs)
        
        if initial_table is not None:
            if data is not None:
                msg = "ERROR: Supplied initial data {} and input file {}"
                raise ValueError(msg.format(data, initial_table))
            data = self._read_file_to_table(initial_table, idl_mode, **kwargs)
        else:
            if data is None:
                kwargs = {}
                names = self.standard_columns.keys()
                dtype = [self.standard_columns[x]['dtype'] for x in names]

        # Initialize superclass
        super().__init__(data=data, masked=masked, names=names, dtype=dtype,
                         meta=meta, copy=copy, rows=rows,
                         copy_indices=copy_indices, **kwargs)
        self._fix_columns()
    
    
    def read(*args, **kwargs):
        """
        Override the read method to make sure that strings have the Object type.
        
        Parameters
        ----------
        args : list
            List of positional arguments
        kwargs : dictionary
            Dictionary of keyword arguments
        
        Returns
        -------
        out : astropy.table.Table
            The table that was read in.
        """
        out = super().read(*args, **kwargs)
        for col in out.itercols():
            if col.dtype.kind in 'SU':
                out.replace_column(col.name, col.astype('object'))
        return out


    def add_exposure(self, metadata_dict):
        """
        Add a new row to the table from a dictionary built up from an exposure.
        The dictionary should contain all of the standard abscal columns. If the
        value of the root column is already in the table, then deal with it as
        provided for in the internal duplicates metadata.
        
        Handling duplicates can currently be any of:
            - both: keep the existing entry, add the new entry.
            - preserve: keep the existing entry, discard the new entry.
            - replace: remove the existing entry, add the new entry.
            - neither: remove the existing entry, discard the new entry.
        
        Parameters
        ----------
        metadata_dict : dictionary
            A dictionary containing information on a single exposure.
        
        Returns
        -------
        success : bool
            True if the column was added, False if not. Will generally only be
            False in the case of duplicate columns.
        """
        for column in self.standard_columns:
            if column not in metadata_dict:
                idl = self.standard_columns[column]['idl']
                default = 'N/A'
                if 'default' in self.standard_columns[column]:
                    default = self.standard_columns[column]['default']
                if (not idl) and (default != 'N/A'):
                    metadata_dict[column] = default
        
        if metadata_dict['root'] in self['root']:
            if self.duplicates == 'both':
                self.add_row(metadata_dict)
            elif self.duplicates == 'preserve':
                return False
            elif self.duplicates == 'replace':
                remove_mask = [self['root'] == metadata_dict['root']]
                self.remove_rows(remove_mask)
                self.add_row(metadata_dict)
            elif self.duplicates == 'neither':
                remove_mask = [self['root'] == metadata_dict['root']]
                self.remove_rows(remove_mask)
                return False
            else:
                msg = "ERROR: Unknown duplicate policy '{}'"
                raise ValueError(msg.format(self.duplicates))
        else:
            self.add_row(metadata_dict)
        self._fix_columns()
        return True
    
    
    def adjust(self, adjustments):
        """
        Adjust the table based on an adjustment dictionary. The dictionary
        may contain entries that edit columns or delete rows.
        
        Parameters
        ----------
        adjustments : dict
            Dictionary of adjustments
        """
        removal_str = "Removed for {} ({})."
        
        for item in adjustments['delete']:
            if item["value"] in self[item["column"]]:
                masked = self[self[item["column"]] == item["value"]]
                masked["use"] = False
                new_notes = masked["notes"]
                reason = removal_str.format(item["reason"], item["source"])
                new_notes += [" "+reason for x in new_notes]
                masked["notes"] = new_notes
        
        for item in adjustments['edit']:
            value = item["key"]
            prefix = [c[:len(value)] for c in self[item["column"]]]
            if value in prefix:
                mask = [x == value for x in prefix]
                masked = self[mask]
                if operation == "replace":
                    column = masked[item["column"]]
                    original, revised = item["value"].split("->")
                    new_col = [x.replace(original, revised) for x in column]
                masked[item["column"]] = new_col
                reason = "Edited {} by {} {} because {} ({})."
                reason = reason.format(item["column"], item["operation"],
                                       item["value"], item["reason"],
                                       item["source"])
                new_notes = masked["notes"]
                new_notes += [" "+reason for x in new_notes]
                masked["notes"] = new_notes
        
        return
    
    
    def set_filter_images(self):
        """
        For any grism exposures, look for the nearest associated filter
        exposure and, if one is found, associate it using the filter_root
        column.
        """
        filter_table = deepcopy(self)
        filter_list = [f[0] != 'F' for f in filter_table['filter']]
        filter_table.remove_rows(filter_list)
        
        grism_table = deepcopy(self)
        grism_list = [f[0] != 'G' for f in grism_table['filter']]
        grism_table.remove_rows(grism_list)
        
        for row in grism_table:
            base_mask = [r == row['root'] for r in self['root']]
            obset = row['obset']
            check_mask = [r == obset for r in filter_table['obset']]
            check_table = filter_table[check_mask]
            if len(check_table) > 0:
                check_dates = [abs(row['date']-t) for t in check_table['date']]
                minimum_time_index = check_dates.index(min(check_dates))
                minimum_time_row = check_table[minimum_time_index]
                self["filter_root"][base_mask] = minimum_time_row["root"]
            else:
                msg = "No corresponding filter exposure found."
                self["note"][base_mask] += " {}".format(msg)
                self["filter_root"][base_mask] = "NONE"
        return
       
    
    def filtered_copy(self, filter_or_filters):
        """
        Get a copy of the table, filtered by the specified filters.
        
        Parameters
        ----------
        filter_or_filters : list of filters or filter
            The filters to apply
        
        Returns
        -------
        table : AbscalDataTable
            The filtered table
        """
        if not isinstance(filter_or_filters, list):
            filter_or_filters = [filter_or_filters]
        
        table = deepcopy(self)
        for filter in filter_or_filters:
            table = self._filter_table(table, filter)
        
        return table
    
    
    def write_to_file(self, file_name, idl_mode, **kwargs):
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
        date_str = self.create_time.strftime("%d-%b-%Y %H:%M:%S")
        format = kwargs.get('format', self.default_format)
        filters = kwargs.get('filters', [])
        
        table = self.filtered_copy(filters)
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
            self._write_to_idl(file_name, table, create_time=self.create_time,
                               search_dirs=self.search_dirs,
                               search_str = self.search_str)
            return
        
        table.metadata = table.comments
        
        table.write(file_name, format=format, overwrite=True)
    

    @property
    def n_exposures(self):
        """
        Return the number of rows in the table.
        """
        return len(self)


    @staticmethod
    def _filter_table(table, filter):
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
                obset:<value> : keep all data where the root column begins with
                                <value>.
        
        Returns
        -------
        filtered_table : astropy.table.Table
            Filtered table.
        """
        if isinstance(filter, str):
            if filter == 'stare':
                table.remove_rows(table['scan_rate'] > 0.)
            elif filter == 'scan':
                table.remove_rows(table['scan_rate'] == 0.)
            elif filter == 'filter':
                filter_list = [f[0] != 'F' for f in table['filter']]
                table.remove_rows(filter_list)
            elif filter == 'grism':
                table = AbscalDataTable._grism_filter(table)
            elif "obset" in filter:
                val = filter[filter.find(":")+1:]
                len_val = len(val)
                mask = [r[:len_val] == val for r in table['root']]
                table = table[mask]
        else:
            table = filter(table)

        return table


    @staticmethod
    def _grism_filter(table):
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
            
            base_mask = [r == row['root'] for r in grism_table['root']]
            obset = row['obset']
            check_mask = [r == obset for r in filter_table['obset']]
            check_table = filter_table[check_mask]
            if len(check_table) > 0:
                check_dates = [abs(row['date']-t) for t in check_table['date']]
                minimum_time_index = check_dates.index(min(check_dates))
                minimum_time_row = check_table[minimum_time_index]
                if minimum_time_row['root'] not in grism_table['root']:
                    grism_table.add_row(minimum_time_row)
                new_mask = [r == row['root'] for r in grism_table['root']]
                grism_table["filter_root"][new_mask] = minimum_time_row["root"]
            else:
                row_mask = [r == row['root'] for r in grism_table['root']]
                msg = "No corresponding filter exposure found."
                grism_table["note"][row_mask] += " {}".format(msg)
                grism_table["note"][base_mask] += " {}".format(msg)
                grism_table["filter_root"][base_mask] = "NONE"
        
        grism_table.sort(['root'])
        return grism_table
    
    
    def _read_file_to_table(self, file_name, idl_mode, **kwargs):
        """
        Read an abscal table from a file, optionally using IDL compatibility 
        mode. Note that, even if idl_mode is set to False, if reading
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

        
    @staticmethod
    def _write_to_idl(file_name, table, **kwargs):
        """
        Write the table in strict IDL mode.
        
        Parameters
        ----------
        file_name : str
            The file to write to.
        table : astropy.table.Table
            The (filtered) table to write
        kwargs : dict
            Dictionary of optional keywords. Known keywords include:
                create_time : datetime.DateTime
                    Table creation date
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
        
        columns = column_formats.keys()
        
        idl_table = Table()
        for column in columns:
            if column in column_mappings:
                data = table[column_mappings[column]]
            elif column == "IMG SIZE":
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
        
        create_time = kwargs.get('create_time', datetime.datetime.now())
        date_str = create_time.strftime("%d-%b-%Y %H:%M:%S")
        search_dirs = kwargs.get('search_dirs', os.getcwd())
        search_str = kwargs.get('search_str', 'i*flt.fits')
        with open(file_name, 'r+') as table_file:
            content = table_file.read()
            table_file.seek(0, 0)
            table_file.write("# WFCDIR {}\n".format(date_str))
            for dir in search_dirs:
                search_str = os.path.join(dir, search_str)
                table_file.write("# SEARCH FOR {}\n".format(search_str))
            table_file.write(content)
        
        meta_file_name = file_name + ".meta"
        with open(meta_file_name, 'w') as meta_file:
            meta_file.write("duplicates={}\n".format(table.duplicates))
            meta_file.write("create_time={}\n".format(date_str))
            meta_file.write("search_str={}\n".format(search_str))
            for dir in search_dirs:
                meta_file.write("search_dirs={}\n".format(dir))
            for column in AbscalDataTable.standard_columns:
                if not AbscalDataTable.standard_columns[column]['idl']:
                    for item in table[column]:
                        meta_file.write("{}={}\n".format(column, item))

        return

    
    @staticmethod
    def _read_from_idl(table_file):
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
        parse_date = "%d-%b-%Y %H:%M:%S"

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
        
        idl_table = ascii.read(table_file, 
                               format="fixed_width",
                               col_starts=idl_column_start)
        
        duplicates = "both"
        create_time = datetime.datetime.now()
        search_str = "i*flt.fits"
        search_dirs = []
        extra_columns = {}
        for column in AbscalDataTable.standard_columns:
            if not AbscalDataTable.standard_columns[column]["idl"]:
                extra_columns[column] = []
        meta_file = table_file+".meta"
        if os.path.isfile(meta_file):
            with open(meta_file, 'r') as meta:
                state='start'
                for line in meta:
                    items = line.strip().split("=")
                    column = items[0]
                    data = "=".join(items[1:])
                    if column == "create_time":
                        create_time = datetime.datetime.strptime(data, parse_date)
                    elif column == "duplicates":
                        duplicates = data
                    elif column == "search_str":
                        search_str = data
                    elif column == "search_dirs":
                        search_dirs.append(data)
                    else:
                        if column in extra_columns:
                            if column == 'use':
                                if 'false' in data or 'False' in data:
                                    extra_columns[column].append(False)
                                else:
                                    extra_columns[column].append(True)
                            else:
                                extra_columns[column].append(data)
                        else:
                            msg = "ERROR: Unknown Metadata Line: {}"
                            raise ValueError(msg.format(line.strip()))
        
        if len(search_dirs) == 0:
            search_dirs.append(os.getcwd())
        
        c = {}
        c['root'] = Column(name='root', data=idl_table['ROOT'])
        c['obset'] = Column(name='obset', data=[r[:6] for r in idl_table['ROOT']])
        c['filter'] = Column(name='filter', data=idl_table['MODE'])
        c['aperture'] = Column(name='aperture', data=idl_table['APER'])
        c['exposure_type'] = Column(name='exposure_type', data=idl_table['TYPE'])
        c['target'] = Column(name='target', data=idl_table['TARGET'])
        img_x = [int(i[:4].strip()) for i in idl_table['IMG SIZE']]
        c['xsize'] = Column(name='xsize', data=img_x)
        img_y = [int(i[5:].strip()) for i in idl_table['IMG SIZE']]
        c['ysize'] = Column(name='ysize', data=img_y)
        dt = zip(idl_table["DATE"], idl_table["TIME"])
        dates = [parse_fn("{} {}".format(d,t), parse_str) for d,t in dt]
        c['date'] = Column(name='date', data=dates)
        c['proposal'] = Column(name='proposal', data=idl_table["PROPID"])
        c['exptime'] = Column(name='exptime', data=idl_table["EXPTIME"])
        postarg_1 = [float(p[:5].strip()) for p in idl_table["POSTARG X,Y"]]
        c['postarg1'] = Column(name='postarg1', data=postarg_1)
        postarg_2 = [float(p[8:].strip()) for p in idl_table["POSTARG X,Y"]]
        c['postarg2'] = Column(name='postarg2', data=postarg_2)
        c['scan_rate'] = Column(name='scan_rate', data=idl_table["SCAN_RAT"])
        for column in AbscalDataTable.standard_columns:
            if column not in c:
                c[column] = Column(name=column, data=extra_columns[column])
        col_names = list(AbscalDataTable.standard_columns.keys())

        t = Table(data=c, names=col_names)
        t.create_time = create_time
        t.meta = idl_table.meta
        
        return t
    
    
    @staticmethod
    def _get_kwarg(key, default, kwargs):
        """
        Get an abscal-specific kwarg from the kwarg dictionary (if present),
        otherwise returning a default value.
        
        Parameters
        ----------
        key : str
            The kwarg key to look for
        default : obj
            The default value of key
        kwargs : dict
            The keyword dictionary to search.
        """
        if key in kwargs:
            return kwargs.pop(key), kwargs
        return default, kwargs
    
    def _fix_columns(self):
        """
        Adjust all columns to replace fixed-length strings with objects.
        """
        for col in self.itercols():
            if col.dtype.kind in 'SU':
                self.replace_column(col.name, col.astype('object'))
    
    
    default_format = 'ascii.ipac'
    
    standard_columns = {
                            'root': {'dtype': 'O', 'idl': True},
                            'obset': {'dtype': 'S6', 'idl': True},
                            'filter': {'dtype': 'O', 'idl': True},
                            'aperture': {'dtype': 'O', 'idl': True},
                            'exposure_type': {'dtype': 'O', 'idl': True},
                            'target': {'dtype': 'O', 'idl': True},
                            'xsize': {'dtype': 'i4', 'idl': True},
                            'ysize': {'dtype': 'i4', 'idl': True},
                            'date': {'dtype': 'O', 'idl': True},
                            'proposal': {'dtype': 'i4', 'idl': True},
                            'exptime': {'dtype': 'f8', 'idl': True},
                            'postarg1': {'dtype': 'f8', 'idl': True},
                            'postarg2': {'dtype': 'f8', 'idl': True},
                            'scan_rate': {'dtype': 'f8', 'idl': True},
                            'path': {'dtype': 'O', 'idl': False, 
                                     'default': 'N/A'},
                            'use': {'dtype': '?', 'idl': False, 
                                    'default': True},
                            'filter_root': {'dtype': 'S10', 'idl': False,
                                            'default': 'unknown'},
                            'filename': {'dtype': 'O', 'idl': False,
                                         'default': 'N/A'},
                            'xc': {'dtype': 'f8', 'idl': False, 'default': -1.},
                            'yc': {'dtype': 'f8', 'idl': False, 'default': -1.},
                            'xerr': {'dtype': 'f8', 'idl': False, 
                                     'default': -1.},
                            'yerr': {'dtype': 'f8', 'idl': False, 
                                     'default': -1.},
                            'crval1': {'dtype': 'f8', 'idl': False, 
                                       'default': 0.},
                            'crval2': {'dtype': 'f8', 'idl': False, 
                                       'default': 0.},
                            'ra_targ': {'dtype': 'f8', 'idl': False, 
                                        'default': 0.},
                            'dec_targ': {'dtype': 'f8', 'idl': False, 
                                         'default': 0.},
                            'extracted': {'dtype': 'O', 'idl': False, 
                                          'default': ''},
                            'coadded': {'dtype': 'O', 'idl': False, 
                                        'default': ''},
                            'planetary_nebula': {'dtype': '?', 'idl': False,
                                                 'default': False},
                            'notes': {'dtype': 'O', 'idl': False, 
                                      'default': 'N/A'},
                       }
    


# This is the only way that I've figured out to actually read in correctly.
#t = ascii.read("dirtemp_all.log", format="fixed_width", col_starts=(0, 11, 19, 35, 41, 54, 64, 73, 82, 89, 98, 112))
