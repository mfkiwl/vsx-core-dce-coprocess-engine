![alt text](http://nearist.sightbox.io/wp-content/uploads/2017/04/nearist.svg)

Nearist greatly accelerates big data searches through a revolutionary new hardware platform specifically engineered to handle the computationally demanding task of performing Nearest Neighbor Search on vector representations of content—enabling your search routines to deliver results several orders of magnitude faster than anything else on the market.

## Structure
This repository conatains the RTL for the (21) lfe5u-85f-8bg381i on Nearist's VSX board. More information about the VSX board can be found !!!here!!! and can be purchased !!!here!!!

- `/bin/` contains the Lattice Diamond constraint file for the design. Anything you would like to know about pin mapping or any constraints we put on place/route can be found here.
- `/lib/syn/ip_cores_syn`contains the Clarity Designer project file ip_cores_sny.sbx that automatically adds preconfigured all the Lattice IP blocks used in the design. see !!!Getting Started>Clarity Designer!!! for more information.
- `/rtl/` contains the source code of the distance calculation engine (DCE).
- '/run/' The last folder in the repository is a folder dedicated for the project folders of all the configurations you build
## Module Hiearchy
see below diagram for a high level view of the design, for more information go to the !!!VSX Design Introduction!!!.

!!!TODO: Add diagram!!!

## Synthesis & Place/Route 
To build the design one must have Lattice Diamond(!!!link!!!) development environment

when creating a new project the following items are required:
  - constraint file 
  - top module and parallel communication interface
  - select common files required for the desired DCE and slot configuration
  - the clarity design file .sbx

for further information about building the design go the !!!Getting Started!!! wiki page
  
## Configurations tested and available
<table> 
  <tr> <th>Distance Metric</th> <th>Component Size</th> <th>Query Mode</th> <th># Slots</th></tr>
  <tr> <th>L1</th> <th>8-bit</th> <th>KNN</th> <th>1</th></tr>
  <tr> <th>L1</th> <th>8-bit</th> <th>KNN</th> <th>10</th></tr>
  <tr> <th>L1</th> <th>8-bit</th> <th>Thresholded</th> <th>1</th></tr>
  <tr> <th>L1</th> <th>8-bit</th> <th>Thresholded</th> <th>10</th></tr>
  <tr> <th>Hamming</th> <th>32-bit</th> <th>Thresholded</th> <th>1</th></tr>
  <tr> <th>Hamming</th> <th>32-bit</th> <th>Thresholded</th> <th>16</th></tr>
