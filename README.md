haplonet.r: a terminal-based R script for plotting haplotype networks
=======================================================================


Quick start
--------------
##### Dependencies:
haplonet.r relies upon the following dependencies:  
- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)
- [pegas](https://cran.r-project.org/web/packages/pegas/index.html)
- [beyonce](https://github.com/dill/beyonce) (This last is required as-written for color palette generation, but the script can easily be re-tooled for other color palettes. For more R color packages, see [here](https://github.com/EmilHvitfeldt/r-color-palettes))

Currently, haplonet.r is written using the [quartz](https://cran.r-project.org/bin/macosx/RMacOSX-FAQ.html#Quartz-device) graphics device, which limits it to Mac systems, but subsequent versions may support other devices.

At minimum, haplonet.r requires you to have a sequence alignment in FASTA format and a text-based, delimited data file (the default delimiter is tab, but can be set via command-line options. The data file must have a field called 'id' that matches the FASTA sequence identifiers and a field that defines some category which by default is named 'region' but can be changed in the options.

Example alignment:
```
>seq1
GATTACA
>seq2
ATTACA-
>seq3
TACCAGA
```

Example data file:
id | marker | region | country
--- | ---- | ---- | ----
seq1 | coi | northwest | Kiribati
seq2 | coi | southeast | Kiribati
seq3 | coi | east | Kiribati


The order of sequences in either the data or alignment files is not important as the script associates samples by sequence identifier.

So, with a sequence alignment of a one species and a data file describing (say) where they were sampled, you'd do:

```bash
$ ./haplonet.r alignment.fasta data.tab
```
If everything worked properly, you should get a graphics window popping up with a likely shoddy-looking haplotype network, like so:

![initial haplotype network](../assets/network1.png?raw=true)


Usage:
  haplonet.r [--separator=<sep>] [--filter=<filter>] [--order-categories=<cats>] [--field=<field>] [--output=<file>] [(--legend --legend-position=<pos> [--save-legend])] [--haplotype-labels] <alignment> <datafile>

### Options:  
  -s --separator=<sep>  Data file field separator [default: tab]  
  -f --field=<field>  Category field in data file [default: region]  
  -t --filter=<filter>  Filter taxa by pattern  
  -c --order-categories=<cats>  Specify category order (fmt: x,x,x,x)  
  -o --output=<file>  Output file prefix [default: hapnet]  
  -l --legend  Print a legend  
  -p --legend-position=<pos>  Legend position [default: topleft]  
  -v --save-legend  Optional second file to save legend by itself  
  -h --haplotype-labels  Display haplotype labels"  
