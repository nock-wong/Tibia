# -*- coding: utf-8 -*-
"""
Created on Thu Apr 04 00:15:05 2013

@author: Nick
"""

import zipfile

filename = "C:\Users\Nick\Dropbox\Nick Wong Thesis\Software\data\input\Juan_Cantelejo.zip"

print '%20s  %s' % (filename, zipfile.is_zipfile(filename))

zf = zipfile.ZipFile(filename)

zf.extractall("C:\Users\Nick\Dropbox\Nick Wong Thesis\Software\data\output")