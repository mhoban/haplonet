#!/usr/bin/env littler


# NOTE: this script relies on a customized version of the pegas library
# to install it, uncomment the following:
# devtools::install_github("mhoban/pegas")

options(warn=-1)
suppressMessages(library(docopt))
# Parse command line options using magic docopt package
doc <-
"Usage:
  haplonet.r [--separator=<sep>] [--filter=<filter>] [--order-categories=<cats>] [--field=<field>] [--output=<file>] [(--legend --legend-position=<pos> [--save-legend])] [--haplotype-labels] [--big-palette] [--dump] <alignment> <datafile>

Options:
  -s --separator=<sep>  Data file field separator [default: tab]
  -f --field=<field>  Category field in data file [default: region]
  -t --filter=<filter>  Filter taxa by pattern
  -c --order-categories=<cats>  Specify category order (fmt: x,x,x,x)
  -o --output=<file>  Output file prefix [default: hapnet]
  -l --legend  Print a legend
  -p --legend-position=<pos>  Legend position [default: topleft]
  -v --save-legend  Optional second file to save legend by itself
  -h --haplotype-labels  Display haplotype labels
  -b --big-palette  Use large color palette for many categories  
  -d --dump  Dump the options for debugging"

opt <- docopt(doc)


# Set separator to actually tab
if (opt[['separator']] == "tab" || opt[['separator']] == "\\t") {
  opt[['separator']] <- "\t"
}

# load dependencies
cat("loading libraries (can take a sec)...\n")
suppressMessages(library(dplyr))
suppressMessages(library(stringr))
suppressMessages(library(pegas))
require(beyonce,quiet=T)

# big color palette
pal_269 <- c( "#000000", "#FFFF00", "#1CE6FF", "#FF34FF", "#FF4A46", "#008941", "#006FA6", "#A30059",
              "#FFDBE5", "#7A4900", "#0000A6", "#63FFAC", "#B79762", "#004D43", "#8FB0FF", "#997D87",
              "#5A0007", "#809693", "#FEFFE6", "#1B4400", "#4FC601", "#3B5DFF", "#4A3B53", "#FF2F80",
              "#61615A", "#BA0900", "#6B7900", "#00C2A0", "#FFAA92", "#FF90C9", "#B903AA", "#D16100",
              "#DDEFFF", "#000035", "#7B4F4B", "#A1C299", "#300018", "#0AA6D8", "#013349", "#00846F",
              "#372101", "#FFB500", "#C2FFED", "#A079BF", "#CC0744", "#C0B9B2", "#C2FF99", "#001E09",
              "#00489C", "#6F0062", "#0CBD66", "#EEC3FF", "#456D75", "#B77B68", "#7A87A1", "#788D66",
              "#885578", "#FAD09F", "#FF8A9A", "#D157A0", "#BEC459", "#456648", "#0086ED", "#886F4C",
              
              "#34362D", "#B4A8BD", "#00A6AA", "#452C2C", "#636375", "#A3C8C9", "#FF913F", "#938A81",
              "#575329", "#00FECF", "#B05B6F", "#8CD0FF", "#3B9700", "#04F757", "#C8A1A1", "#1E6E00",
              "#7900D7", "#A77500", "#6367A9", "#A05837", "#6B002C", "#772600", "#D790FF", "#9B9700",
              "#549E79", "#FFF69F", "#201625", "#72418F", "#BC23FF", "#99ADC0", "#3A2465", "#922329",
              "#5B4534", "#FDE8DC", "#404E55", "#0089A3", "#CB7E98", "#A4E804", "#324E72", "#6A3A4C",
              "#83AB58", "#001C1E", "#D1F7CE", "#004B28", "#C8D0F6", "#A3A489", "#806C66", "#222800",
              "#BF5650", "#E83000", "#66796D", "#DA007C", "#FF1A59", "#8ADBB4", "#1E0200", "#5B4E51",
              "#C895C5", "#320033", "#FF6832", "#66E1D3", "#CFCDAC", "#D0AC94", "#7ED379", "#012C58",
              
              "#7A7BFF", "#D68E01", "#353339", "#78AFA1", "#FEB2C6", "#75797C", "#837393", "#943A4D",
              "#B5F4FF", "#D2DCD5", "#9556BD", "#6A714A", "#001325", "#02525F", "#0AA3F7", "#E98176",
              "#DBD5DD", "#5EBCD1", "#3D4F44", "#7E6405", "#02684E", "#962B75", "#8D8546", "#9695C5",
              "#E773CE", "#D86A78", "#3E89BE", "#CA834E", "#518A87", "#5B113C", "#55813B", "#E704C4",
              "#00005F", "#A97399", "#4B8160", "#59738A", "#FF5DA7", "#F7C9BF", "#643127", "#513A01",
              "#6B94AA", "#51A058", "#A45B02", "#1D1702", "#E20027", "#E7AB63", "#4C6001", "#9C6966",
              "#64547B", "#97979E", "#006A66", "#391406", "#F4D749", "#0045D2", "#006C31", "#DDB6D0",
              "#7C6571", "#9FB2A4", "#00D891", "#15A08A", "#BC65E9", "#FFFFFE", "#C6DC99", "#203B3C",
              
              "#671190", "#6B3A64", "#F5E1FF", "#FFA0F2", "#CCAA35", "#374527", "#8BB400", "#797868",
              "#C6005A", "#3B000A", "#C86240", "#29607C", "#402334", "#7D5A44", "#CCB87C", "#B88183",
              "#AA5199", "#B5D6C3", "#A38469", "#9F94F0", "#A74571", "#B894A6", "#71BB8C", "#00B433",
              "#789EC9", "#6D80BA", "#953F00", "#5EFF03", "#E4FFFC", "#1BE177", "#BCB1E5", "#76912F",
              "#003109", "#0060CD", "#D20096", "#895563", "#29201D", "#5B3213", "#A76F42", "#89412E",
              "#1A3A2A", "#494B5A", "#A88C85", "#F4ABAA", "#A3F3AB", "#00C6C8", "#EA8B66", "#958A9F",
              "#BDC9D2", "#9FA064", "#BE4700", "#658188", "#83A485", "#453C23", "#47675D", "#3A3F00",
              "#061203", "#DFFB71", "#868E7E", "#98D058", "#6C8F7D", "#D7BFC2", "#3C3E6E", "#D83D66",
              
              "#2F5D9B", "#6C5E46", "#D25B88", "#5B656C", "#00B57F", "#545C46", "#866097", "#365D25",
              "#252F99", "#00CCFF", "#674E60", "#FC009C", "#92896B")



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
fields <- str_split(opt[['field']],",")[[1]]
field <- ifelse(!is.na(as.integer(fields[1])),as.integer(fields[1]),fields[1])
field2 <- ifelse(length(fields)>1,fields[2],"")
field2 <- ifelse(!is.na(as.integer(field2)),as.integer(field2),field2)

# read the data table and filter it based on the samples we actually appear to have
samples <- read.table(opt[['datafile']],header=T,sep=opt[['separator']])

# filter alignment if requested to do so
if (!is.null(opt[['filter']])) {
  # try to split filter string by ':'
  filter <- strsplit(opt[['filter']],':')[[1]]
  if (length(filter) == 1) {
    # if there was no ':' in there, filter sequence labels by given criteria
    alignment <- alignment[grep(filter,labels(alignment),perl=T),]  
  } else if (length(filter) == 2) {
    # if there was one, the first part is the column to filter and the second part is the criteria
    column <- filter[1]
    criteria <- filter[2]
    ids <- samples[grep(criteria,samples[,column],perl=T),'id']
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
if (opt[["big-palette"]]) {
  pal <- pal_269
} else {
  pal <- beyonce_palette(18,ncol(hap.pies),type = "continuous")  
}
if (length(pal) > ncol(hap.pies)) {
  pal <- pal[1:ncol(hap.pies)]
}

# plot the thing
cat("Trying to plot the thing...\n")

# this will pop up a window, but we want that so we can call replot()
f <- quartz(bg="white")
par(cex=1)
# plot the haplotype network
plot(hap.net, size=attr(hap.net, "freq")*0.2, bg=pal,
     scale.ratio = 0.2, cex = 1, labels=opt[['haplotype-labels']],
     pie=hap.pies, font=2, fast=F, legend=F, show.mutation=1,threshold=0,show.single=F)
# replot puts the plot into interactive mode, allowing you to rearrange the haplotypes so it looks nice
plottr <- replot()

# if we want a legend, draw a legend
categories <- colnames(hap.pies)
if (field2 != "") {
  categories <- samples %>%
    dplyr::filter(.[,field] %in% categories) %>%
    dplyr::arrange(.[,field]) %>%
    dplyr::mutate(thing=paste(.[,field],paste0("(",.[,field2],")"))) %>%
    dplyr::pull(thing) %>%
    unique()
}
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
  #pdf(outf)
  quartz(type="pdf",file=outf)
  plot(1,type="n",axes=F,xlab='',ylab='')
  legend.position <- opt[['legend-position']]
  legend(x=legend.position,legend=categories,fill=pal,bty="n",cex=1.2,ncol=2)
  dev.off()
}
