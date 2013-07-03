quick-cd
========

qcd -- Quickly Change Directory

By utilizing the find command and a list of commonly used directories,
qcd will attempt to switch into a nested directory with just one keyword.
If more than one directory matches the keyword, qcd will print a list and let the
user select the sought after directory. 

Installation
============

Note that qcd must reside sourced in the current enviroment to be of use.
It is recommended to do the following with a tar.gz until an installer is in place:

tar xzvf quick-cd.tar.gz /usr/local/lib/quick-cd
cd /usr/local/lib/quick-cd
bash install.bash

You may want to remove the tarball after statisifed that the package installed correctly.
Otherwise, enjoy qcd and try not to get too spoiled!
    
Usage
=====

qcd annoying-to-reach-manually-directory
For more info:
    qcd -h

Desired Future Modifications
============================
Feature TODOs:
    Keyword completion.

General TODOs:
    Increased portability. 
    Increased performance.
    Increased readability.
    Increased intelligence of general_dirs.

Make sure that any updates to the program have the version date updated in the functions.bash
file as well (4th comment line).

(C) 2013 - July - 02 Nathaniel Hellabyte nate@hellabit.es
