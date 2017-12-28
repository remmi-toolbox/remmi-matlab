
# About REMMI-matlab

REMMI-Matlab is a toolbox for processing MRI data from supported small 
animal imaging vendors (mainly, Bruker and Varian/Agilent). We aim for this 
toolbox to provide easy access to advanced MRI measures of magnetization 
transfer, multi-exponential T2 (including the myelin water fraction), 
diffusion, etc.

REMMI-Matlab is written by Kevin Harkins (<kevin.harkins@vanderbilt.edu>) 
and Mark Does (<mark.does@vanderbilt.edu>), Vanderbilt University. This 
work is supported by NIH Grant **TK**


# REMMI-Matlab Examples

'Easy' examples for processing diffusion tensor (`easy_dti`), magnetization 
transfer (`easy_mtir`), and multi-exponential T2 (`easy_t2`), data are 
given in the base directory. An example for advanced processing of multi-
exponential T2 data is also provided (`full_t2`). 


# An Introduction to Matlab Namespaces

In Matlab, directory names preceded with a `+` are used as _namespaces_.
For example, if the REMMI-Matlab base directory is in the Matlab path, the 
REMMI `workspace` class in the `./+remmi` directory can be accessed as:

```Matlab
remmi.workspace()
```

Also, the `recon` function in that folder can be accessed as:

```Matlab
remmi.recon()
```

Inductively, the function `dti()` in the `./+remmi/+dwi` sub-directory can 
be accessed with:

```Matlab
remmi.dwi.dti()
```


# Saving and Loading Data

The `remmi.workspace` class is intended to provide easy to manage, clean 
workspaces of saved data. To create a new instance of a REMMI workspace:

```Matlab
fname = 'mydatafile.mat';
ws = remmi.workspace(fname);
```

where `mydatafile.mat` is the name of the file where data will be 
stored. Presently, all data is stored in Matlab's native data format, 
`*.mat`. If `mydatafile.mat` already exists in the current path, any 
contents of that file will be automatically loaded into workspace. 

Any existing Matlab structure can be converted into a REMMI workspace. For
example:  

```Matlab
info = struct();
info.data = {'cell','array','to','be','saved','to','file'};
ws = remmi.workspace(fname, info);
```

In practice, `ws` can be used like any Matlab structure, and any data put 
into `ws` is automatically saved to file. For instance, to save a 100x100 
matrix of noise:

```Matlab
ws.noise = randn(100);
```

**Note**: For all practical purposes `remmi.workspace` is independent from 
the rest of the REMMI toolbox. There is no requirement to use this class 
for storing/saving data. The rest of the toolbox can be used with or
without `remmi.workspace`. Likewise, `remmi.workspace` can be used with or 
without the rest of the toolbox. 

**Warning**: By default, Matlab `.mat` files are limited to 2 GB in size. 
**TK**

# Image Reconstruction

`remmi.recon()` is an entry-level function to simplify loading and 
reconstruction of MRI image data from any supported vendor.

For example:

```Matlab
info.spath = '/path/to/study'; % path to the study folder
info.exps = 20; % Bruker experiment number contained in info.spath
ws.images = remmi.recon(info); 
```

Given a valid study path and list of experiments, the `remmi.recon()` 
function returns a Matlab structure containing the fields:

* `img` contains the reconstructed complex images
* `labels` contains a cell array of dimension labels for `img`
* `pars` is a structure of general and vendor-specific parameters used in 
the imaging sequence

In this example, the structure returned by `remmi.recon()` is saved in the 
REMMI workspace, `ws`, with the variable name `images`.

Helper functions

* `remmi.recon.options` loads default options and processes custom 
options for reconstruction
* `remmi.recon.ft` is a function for basic 2D or 3D reconstruction of 
Fourier-encoded MRI data.


# Core REMMI functions

Most 'Core' REMMI functions take as a first argument and return a Matlab 
structure that contains both:

1. the data to be processed 
2. meta-data detailing what the data encodes. 

For the example in above section: if `info.spath` and `info.exps` point to 
diffusion-tensor encoded image data, these images could be processed with:

```Matlab
ws.dti = remmi.dwi.dti(ws.images);
```

As before, the Matlab structure returned by `remmi.dwi.dti()` is saved in 
the to file with the variable name `dti`.

By default, most REMMI functions assume that the data to be processed 
exists in the field `img`. In the example above, image data is contained in 
`remmi.images.img`. However, the default field name can be modified. Check 
the function-specific help for reference. 


# Diffusion MRI

`remmi.dwi.*` contains functions for processing diffusion-weighted (DWI) 
data. See function-specific help for more details.

## Core functions
* `remmi.dwi.dti` is a function for processing of diffusion-tensor encoded 
data
* `remmi.dwi.addbmatrix` is a function to add a vendor-specific b-matrix to 
structures of diffusion-encoded data

## Helper functions

* `remmi.dwi.dtilin` performs (simple) linear DTI analysis on raw signals
* `remmi.dwi.dtinonlin` performs (simple) non-linear DTI analysis (warning: 
this is sllllooowwww)

By default, DTI signals are processed by simple linear analysis 
(`remmi.dwi.dtilin`).


# Inversion-recovery

`remmi.ir.*` contains functions for processing inversion recovery (IR) 
data. See function-specific help for more details.

## Core functions

* `remmi.ir.T1` is a function for quantitative T1 analysis of inversion 
recovery data
* `remmi.ir.qmt` is a function for quantitative magnetization transfer 
(qmt) analysis of selective inversion recovery data

## Helper functions

* `remmi.ir.sir` solves the Bloch equations for signals from 2-
compartment selective inversion recovery experiments
* `remmi.ir.ir` contains signal equations for inversion-recovery 
experiments


# Multiple-spin echo

`remmi.mse.*` contains functions for processing multiple spin echo (MSE) 
data. See function-specific help for more details.

## Core functions

* `remmi.mse.analysis` is a function for generalized processing of 
relaxometry data, based upon the MERA toolbox
* `remmi.mse.mT2` is a function for processing of EPG-based multi-
exponential T2 (mT2) analysis of MSE data.

## Helper functions

* `remmi.mse.mT2options` loads default options and processes custom 
options for `remmi.mse.mT2`

# Region of Interest

`remmi.roi.*` contains functions for *only basic* region of interest (ROI) 
analysis. See function-specific help for 
more details.

## Core functions

* `remmi.roi.draw` is a function for drawing and processing ROIs
* `remmi.roi.copy` copies ROIs and analysis from one structure to 
another


# Other Utilities

`remmi.util.*` contains utility functions that are independent of any other 
namespace

## Core functions

* `remmi.util.slice` is a function to slice through multi-dimensional data
* `remmi.util.thresholdmask` is a function to create a threshold mask from 
image data

## Helper functions

* `remmi.util.apodize` provides Tukey window anodization of a 1D, 2D or 3D 
array
* `remmi.util.githash` returns the hash number of current git commit for 
REMMI-Matlab. This will make it easier to reprocess of data from older 
versions of REMMI-Matlab
* `remmi.util.snrCalc` calculates the SNR of an image
* `remmi.util.strsplit` provides backwards compatibility for Matlab 
distributions that don't include strsplit


# MRI Vendor Support

`remmi.vendors.*` contains classes and functions for vendor-specific 
loading of data and parameter files

## Classes

* `remmi.vendors.BrukerPV` is a class for loading Bruker PV5 & PV6 data and 
parameter files
* `remmi.vendors.Agilent` is a class for loading Varian/Agilent data and 
parameter files

## Helper functions

* `remmi.vendors.autoVendor` detects if the file structure within a study 
path matches that of a supported vendor
* `remmi.vendors.bmatBruker` is a function to calculate a b-matrix from the 
remmiRARE sequence
* `remmi.vendors.loadBruker` is a function to load Bruker data
* `remmi.vendors.loadAgilent` is a function to load Agilent data
* `remmi.vendors.parsBruker` is a function to load Bruker parameter files
* `remmi.vendors.parsAgilent` is a function to load Agilent parameter files


# Known Bugs



# Bug Reporting

Please report bugs through this git repository. Alternatively, you can 
email <kevin.harkins@vanderbilt.edu>

