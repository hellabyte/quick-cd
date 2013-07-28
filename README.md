quick-cd
========

qcd -- Quickly Change Directory 

By utilizing the find command and a list of commonly used directories,
qcd will attempt to switch into a nested directory with just one keyword.
If more than one directory matches the keyword, qcd will print a list and let the
user select the sought after directory. 

CURRENTLY ONLY WORKS FOR BASH.

Installation
============

Note that qcd must reside sourced in the current enviroment to be of use.
For Mac OS X, it is recommended to do the following with a
 tar.gz until a formal installer is in place:

tar xzvf quick-cd.tar.gz /usr/local/lib/quick-cd  
cd /usr/local/lib/quick-cd  
bash install.bash  

For Linux, follow the same steps. You will be prompted for a password during install.
This password gives the program needed sudo access.

You may want to remove the tarball after statisifed that the package installed correctly.

It is also possible to use git:

git clone https://github.com/hellabyte/quick-cd.git  
cd ./quick-cd  
bash install.bash

You can remove the directory that git clone creates after a successful install.  
Otherwise, enjoy qcd and try not to get too spoiled!
    
Usage
=====

qcd annoying-to-reach-manually-directory-keyword

For more info:  
    qcd -h

Desired Future Modifications
============================
### Important Feature TODOs: ###
    Keyword completion.  
    ZSH compatibility.  


#### General TODOs: ####
    Increase portability.                    
    Increase performance.                    
    Increase readability.                    
    Increase intelligence of general_dirs.   

Make sure that any updates to the program have the version date updated in the functions.bash
file as well (4th comment line).

(C) 2013 - July - 06 Nathaniel Hellabyte nate@hellabit.es
