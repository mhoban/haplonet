#!/usr/bin/env littler

options(warn=-1)
suppressMessages(library(docopt))
# Parse command line options using magic docopt package
doc <-
"Usage:
  haplonet.r [--separator=<sep>] [--filter=<filter>] [--order-categories=<cats>] [--field=<field>] [--output=<file>] [(--legend --legend-position=<pos> [--save-legend])] [--haplotype-labels] <alignment> <datafile>

Options:
  -s --separator=<sep>  Data file field separator [default: tab]
  -f --field=<field>  Category field in data file [default: region]
  -t --filter=<filter>  Filter taxa by pattern
  -c --order-categories=<cats>  Specify category order (fmt: x,x,x,x)
  -o --output=<file>  Output file prefix [default: hapnet]
  -l --legend  Print a legend
  -p --legend-position=<pos>  Legend position [default: topleft]
  -v --save-legend  Optional second file to save legend by itself
  -h --haplotype-labels  Display haplotype labels"
opt <- docopt(doc)

# Set separator to actually tab
if (opt[['separator']] == "tab" || opt[['separator']] == "\\t") {
  opt[['separator']] <- "\t"
}

# load dependencies
cat("loading libraries (can take a sec)...\n")
suppressMessages(library(dplyr))
suppressMessages(library(pegas))
require(beyonce,quiet=T)

# color palette
# pal <- c("#d330b1", "#00cb61", "#3941c1", "#b7c200", "#940e8c", "#8dda5e",
#          "#ff8dfb", "#e4b400", "#a196ff", "#dc7800","#007bc4", "#d82528",
#          "#4adcbb", "#e30074", "#a0d57f", "#c497ff", "#817000", "#524892",
#          "#e2c463", "#85346e", "#9cd2a8", "#a50641", "#019f8d", "#b44c00",
#          "#019ccc", "#ff915f", "#365c17", "#ff7cab", "#923316", "#ce94bb")



# make sure alignment and data files exist
if (!file.exists(opt[['alignment']])) {
  stop("Alignment file doesn't exist")
}

if (!file.exists(opt[['datafile']])) {
  stop("Can't open data file")
}

# load alignment file (must be fasta)
alignment <- read.dna(opt[['alignment']],format = "fasta")
if (is.null(alignment)) {
  stop("Failed to load alignment")
}

# make sure our category is treated correctly (integer or string)
field <- ifelse(!is.na(as.integer(opt[['field']])),as.integer(opt[['field']]),opt[['field']])

# read the data table and filter it based on the samples we actually appear to have
samples <- read.table(opt[['datafile']],header=T,sep=opt[['separator']])

# filter alignment if requested to do so
if (!is.null(opt[['filter']])) {
  # try to split filter string by ':'
  filter <- strsplit(opt[['filter']],':')[[1]]
  if (length(filter) == 1) {
    # if there was no ':' in there, filter sequence labels by given criteria
    alignment <- alignment[grep(filter,labels(alignment)),]  
  } else if (length(filter) == 2) {
    # if there was one, the first part is the column to filter and the second part is the criteria
    column <- filter[1]
    criteria <- filter[2]
    ids <- samples[grep(criteria,samples[,column]),'id']
    alignment <- alignment[labels(alignment) %in% ids,]
  }
}

# make sure our sample metadata matches our alignment
samples <- samples %>% filter(id %in% labels(alignment))

# relimit factor levels after filtering (since all those text fields are interpreted as factors)
# if we don't do this, legends will look screwy
samples <- droplevels(samples);
# fctr <- sapply(samples,is.factor)
# samples[fctr] <- lapply(samples[fctr],factor)

# redo the row names of the samples table, so they show up in order
# otherwise, the haplotype table will be screwy
rownames(samples) <- 1:nrow(samples)

# make the data table be in the same order as the aligment (or everything breaks)
samples <- samples[match(labels(alignment),samples$id),]

# generate sample summary, showing 
# count of each selected category
#sample_summary <- samples %>%
  #group_by(samples[,field]) %>%
  #summarise(count=length(sample))

# Calculate haplotype network
hap <- haplotype(alignment)
hap.net <- haploNet(hap)

# do some magic with the row names and categories that I figured out a while ago 
# but no longer entirely understand how it works. Essentially, this gives a table
# with haplotypes and their frequencies by category so you can do the color-coded
# pies for each haplotype in the plot.
hap.pies <- with(
  stack(setNames(attr(hap,'index'),1:length(attr(hap,'index')))),
  table(hap=as.numeric(as.character(ind)),pop=samples[values,field])
)
rownames(hap.pies) <- rownames(hap)

# reorder categories if directed, so your legend looks nice
if (is.character(opt[['order-categories']])) {
  if (grepl('^[0-9]+(,[0-9]+)*$',opt[['order-categories']])) {
    newlevels <- as.numeric(strsplit(opt[['order-categories']],",")[[1]])
    if (length(newlevels) == ncol(hap.pies)) {
      hap.pies <- hap.pies[,c(newlevels)]
    }
  }
}

# get Beyonce palette number 18 with the appropriate number of colors
pal <- beyonce_palette(18,ncol(hap.pies),type = "continuous")

# plot the thing
cat("Trying to plot the thing...\n")

# this will pop up a window, but we want that so we can call replot()
f <- quartz(bg="white")
par(cex=1)
# plot the haplotype network
plot(hap.net, size=attr(hap.net, "freq")*0.2, bg=pal,
     scale.ratio = 0.2, cex = 1, labels=opt[['haplotype-labels']],
     pie=hap.pies, font=2, fast=F, legend=F, show.mutation=T,threshold=0)
# replot puts the plot into interactive mode, allowing you to rearrange the haplotypes so it looks nice
plottr <- replot()

# if we want a legend, draw a legend
categories <- colnames(hap.pies)
if (opt[['legend']]) {
  legend.position <- opt[['legend-position']]
  if (!opt[['save-legend']]) {
    legend(x=legend.position,legend=categories,fill=pal,bty="n",cex=1.2,ncol=2)
  }
}
# save all the necessary R data objects
save(pal,plottr,hap.net,hap.pies,hap,categories,file=paste(c(opt[['output']],'.data'),collapse=""))

# save the plot
quartz.save(file=paste(c(opt[['output']],'_plot','.pdf'),collapse=""),type="pdf")
dev.off()

# plot and save the legend if directed to do so
if (opt[['legend']] && opt[['save-legend']]) {
  outf <- paste(c(opt[['output']],'_legend','.pdf'),collapse="")
  pdf(outf)
  plot(1,type="n",axes=F,xlab='',ylab='')
  legend.position <- opt[['legend-position']]
  legend(x=legend.position,legend=categories,fill=pal,bty="n",cex=1.2,ncol=2)
  dev.off()
}
cat("Done?\n")
