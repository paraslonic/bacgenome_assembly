list.of.packages <- c("fpc", "grDevices", "seqinr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.rstudio.com/")


# Include Libraries
library(seqinr, quietly=T)
suppressMessages(suppressWarnings(library(mclust)))
library(grDevices)
source("/data4/bio/knomics/test/helpers/functions_cluster_contigs.R")

# Parsing console args
args <- commandArgs()
#args <- c("-p", "/data7/bio/knomics/Lactobacillus/NN38_S8/", "-n", "3", "-grid")

if(length(args) < 1) {args <- c("--help")}
if (("--help" %in% args) || ("-h" %in% args )) {
  cat("The R Script
      Arguments:
      -p  - string, directory with Newbler assembly result
      -n=10   - integer, number of random indexes from each cluster or number of grid rows/cols (if use '--grid') to blast
      -c=10000   - integer, max number of nucleotides to blast for each contig
      --grid or g - srting, the way to choose points for blast (if dfined the points are chosen from grid, not from clusters)\n\n")
  q(save="no")
}
argsL <- list(p="", n=10, c=10000, grid=F)
if("-p" %in% args) {argsL$p <- args[which(args=="-p")+1]}
if("-n" %in% args) {argsL$n <- args[which(args=="-n")+1]}
if("-c" %in% args) {argsL$c <- args[which(args=="-c")+1]}
if(("--grid" %in% args)||("g" %in% args)) {argsL$grid <- T}

num_points <- as.integer(argsL$n)
path_to_file <- argsL$p
blast_length <- as.integer(argsL$c)
is_grid <- as.logical(argsL$grid)
path_to_db <- "/data2/bio/blast_shared_storage"

# Start analysis
all_contigs <- read.fasta(file = paste(path_to_file, "/assembly/newbler_large/assembly/", "454LargeContigs.fna", sep=""))
n_contigs <- length(all_contigs)
all_contig_graph <- read.table(file=paste(path_to_file, "/assembly/newbler_large/assembly/", "454ContigGraph.txt", sep=""), 
                               sep="\t", 
                               col.names=c("n", "name", "length", "depth"), 
                               nrows=n_contigs,
                               fill=FALSE, 
                               strip.white=TRUE)
depth_log <- log(all_contig_graph$depth)
GC_c <- sapply(all_contigs, GC)
contigs_data_scaled <- data.frame(scale01(depth_log), scale01(GC_c))
contigs_data <- data.frame(depth_log, GC_c)

system('mkdir -p tmp')
system(paste("grep  \"^F\" ", path_to_file, "/assembly/newbler_large/assembly/454ContigGraph.txt > tmp/tmp.txt", sep=""))
binding_graph <- read.table(file="tmp/tmp.txt",
                            sep="\t", 
                            col.names=c("F", "contig", "left", "right"),
                            strip.white=TRUE)
tmp <- file.remove("tmp/tmp.txt")
binding_graph <- parse_graph_info(binding_graph, all_contig_graph$n)

#Find plasmids
plasmids <- apply(binding_graph, 1, function(i) {identical(i$con_contig, c(i$contig, i$contig))&identical(i$between_contig, c(0.0, 0.0))})
plasmids <- binding_graph[plasmids,]
print(paste("Number of doubt plasmids:", length(plasmids[,1]), sep=" "))
table_blast_res_p <- data.frame()
table_plasmids <- data.frame()
if (nrow(plasmids)>0) {
  print("Start blast for doubt plasmids")
  table_blast_res_p <- blast_clusters(all_contigs[plasmids$contig], contigs_data[plasmids$contig,], 
                                           length(plasmids$contig))
  table_plasmids <- table_blast_res_p[sapply(table_blast_res_p$Title, function(x) {length(grep("plasmid", x))})>0,]
  if (nrow(table_plasmids)>0) {
    write.fasta(sequences=all_contigs[names(all_contigs)==table_plasmids$contig], 
                names=names(all_contigs[names(all_contigs)==table_plasmids$contig]), 
                file.out=paste(path_to_file, "/plasmids.fasta", sep="")) 
    print(paste("Plasmid (",table_plasmids$Title, ") was found in contig: ", table_plasmids$contig, sep=""))
  }
}

# Clustering
cl = Mclust(contigs_data_scaled, G=1:2, modelNames="EVI")    
num_clusters <- cl$G
cl <- cl$classification
print(paste("Number of clusters: ", num_clusters))

# Classify data to clusters
classified_contigs <- lapply(1:num_clusters, function(x) {all_contigs[cl==x]})
classified_data <- lapply(1:num_clusters, function(x) {contigs_data[cl==x,]})
tmp <- lapply(1:num_clusters, function(i){
    write.fasta(sequences=classified_contigs[[i]], names=names(classified_contigs[[i]]), 
                file.out=paste(path_to_file, "/", i,"_cluster.fasta", sep=""))
})

# Blast
if (is_grid==T) {
  print(paste("Start blast for grid ", num_points, "x", num_points, sep=""))
  table_blast_res <- blast_grid(contigs_data, all_contigs,
                 num_points-1)
} else {
    table_blast_res <- lapply(1:num_clusters, function(i){
    print(paste("Start blast for cluster", i))
    blast_clusters(classified_contigs[[i]], classified_data[[i]], 
                   num_points)
    })
  table_blast_res <- do.call("rbind", table_blast_res);
}

print(paste("End blast"))
table_blast_res <- rbind(table_blast_res, table_blast_res_p)
table_blast_res$Sci_name <- sapply(table_blast_res$Sci_name, function(y) {name_split <- strsplit(as.character(y), " ")
                                                    name_split <- name_split[[1]][c(1, 2)]
                                                    name_split <- paste(name_split[!is.na(name_split)], collapse = " ")})

names_labels <- table_blast_res$Sci_name[-which(duplicated(table_blast_res$Sci_name))]
row.names(table_blast_res) <- NULL
write.table(table_blast_res, paste(path_to_file, "/Contamination_blast_res.txt", sep=""))


classified_points <- lapply(names_labels, function(x) {table_blast_res[x==table_blast_res$Sci_name, c("depth_log", "GC_c", "Sci_name")]})
classified_points <- classified_points[order(sapply(classified_points, function(x) {length(x[,1])}), decreasing = TRUE)]
names_labels <- sapply(classified_points, function(x) {x$Sci_name[1]})
names_clusters <- sapply(1:num_clusters, function(x) {paste(x, "cluster")})

# Create plot
pal <- rainbow(num_clusters, alpha = 0.1)
pal_points <- rainbow(length(classified_points))
pal_pch <- rep_len(c(21, 22, 23, 24), length(classified_points))
pdf(paste(path_to_file, "/Contamination.pdf", sep=""), width=7, height=5)
par(xpd=T, mar=par()$mar+c(0,0,0,10))
plot(contigs_data, pch=19, col=rgb(0.3, 0.3, 0.3, alpha=0.3),
     cex.lab=0.7, xlab="log(depth)", ylab="GC", bty = 'n', lwd=0.5, axes=FALSE, cex=0.7)
title(main=list(paste(path_to_file, " n=", num_points), col="black", cex=0.7, font=1))
box(which = "plot", lty = "solid", col = rgb(0.6, 0.6, 0.6), lwd = 0.5)
axis(1, col = rgb(0.6, 0.6, 0.6), lwd = 0.5, cex.axis=0.5)
axis(2, col = rgb(0.6, 0.6, 0.6), lwd = 0.5, las=2, cex.axis=0.5)

points(contigs_data[row.names(contigs_data) == table_plasmids$contig,]$depth_log, 
contigs_data[row.names(contigs_data) == table_plasmids$contig,]$GC_c, pch=1, cex=1.5, col=rgb(0.3, 0.3, 0.3, alpha=0.3))

tmp <- apply(binding_graph, 1, function(i) {
  sapply(1:length(unlist(i$con_contig)), function (j) {
    x <- contigs_data[as.integer(c(unlist(i$contig), unlist(i$con_contig)[j])), 1]
    y <- contigs_data[as.integer(c(unlist(i$contig), unlist(i$con_contig)[j])), 2]
    wd = log(as.integer(unlist(i$depth_contig)[j]))
    lines(x, y,  col=rgb(0.3, 0.3, 0.3, alpha=0.05), lwd=wd)})})

tmp <- lapply(1:num_clusters, function(i) {x <- classified_data[[i]]
                                            ch <- chull(x)
                                            ch <- c(ch, ch[1])
                                            polygon(x[ch,], col=pal[i], border=NA)})

tmp <- sapply(1:length(classified_points), function(x) {points(classified_points[[x]][,c(1, 2)], pch=pal_pch[x], 
                                                              bg=pal_points[x], col = rgb(0.5, 0.5, 0.5, alpha = 0.3), cex=0.7)
                                                       return(0)})

legend_x <- max(contigs_data$depth_log) + (max(contigs_data$depth_log) - min(contigs_data$depth_log))/10
legend_y <- max(contigs_data$GC_c) + (max(contigs_data$GC_c) - min(contigs_data$GC_c))/10
legend_y_2 <- min(contigs_data$GC_c) + (max(contigs_data$GC_c) - min(contigs_data$GC_c))/10
legend(legend_x, legend_y, legend=names_labels, pch=pal_pch, pt.bg = pal_points, pt.lwd = 0.1, bty="n", col = rgb(0.5, 0.5, 0.5, alpha = 0.3), y.intersp=1, cex=0.7)
legend(legend_x, legend_y_2, legend=names_clusters, fill=pal, bty="n", y.intersp=1, cex=0.7, pt.lwd=0.1, border=pal)

tmp <- dev.off()

