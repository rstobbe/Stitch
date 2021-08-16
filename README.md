# Stitch

Stitch is MRI reconstruction software for my 3D-spiraling acquisition (Yarnball, Twisted-Projection) 
* Rob Stobbe (University of Alberta)
* rstobbe@ualberta.ca

Siemens data loading is derived from 'mapVBVD' (Philipp Ehses)  
Feedback logging (Alexander Fyrdahl)   
Trajectory mashing contributors (Quinn Meadus, Justin Grenier, Richard Thompson)  

## Prerequisites

This software has been designed to run on Windows 10, and requires at least one NVIDIA graphics card of 
compute capability 5.0 or greater.  The current compilation uses the CUDA 11.1 Toolkit.      

## Getting Started

Add the Stitch folder (and subfolders) to the Matlab path.  
The Stitch folder contains two files: 'Recon' & 'Script'. These are described below  

### The 'Recon' file

The 'Recon' file defines relevant information necessary for different image reconstructions. It can
be renamed and saved as desired. 

### The 'Script' file

This 'Script' file shows a reconstruction example. This script can be modified for batch processing etc.

## Reference
If using the Yarnball sequence please reference:  
* Stobbe RW, Beaulieu C. Three-dimensional Yarnball k-space acquisition for accelerated MRI. Magn Reson Med. 2021;85:1840-1854.

