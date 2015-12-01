
# Functions
path_to_db <- "/data2/bi/blast_shared_storage/"
scale01 <- function(x) {(x-min(x))/(max(x)-min(x))}
distance2d <-function(a, b) {sqrt((a[,1]-b[,1])^2 + (a[,2]-b[,2])^2)}
shift <- function (matr, i, dim=2) {y <- apply(matr, dim, function(x) {c(x[(i+1):length(x)],x[1:i])})
                                    if (dim==1) return(t(y))
                                    if (dim==2) return(y)}


blast_grid <- function(contig_data, all_contigs, n) {
  
  step_GC <- (max(contig_data$GC_c)-min(contig_data$GC_c))/n
  step_depth <- (max(contig_data$depth_log)-min(contig_data$depth_log))/n
  df <- data.frame(distance = rep(0, nrow(contig_data)))
  grid_GC <- (contig_data$GC_c %/% step_GC + (contig_data$GC_c %% step_GC)%/%0.5) * step_GC
  grid_depth <- (contig_data$depth_log %/% step_depth + (contig_data$depth_log %% step_depth)%/%0.5) * step_depth
  df$distance <- sqrt((contig_data$depth_log-grid_depth)^2 + (contig_data$GC_c-grid_GC)^2)
  ds <- aggregate(df, by = list(grid_GC, grid_depth), min)
  ds$i <- sapply(ds$distance, function(x) {min(which(x==df$distance))})
  index <- sort(unique(ds$i), decreasing = F)

  data_for_blast <- lapply(all_contigs[index], function(y) {y[1:min(blast_length, length(y))]})
  write.fasta(sequences=data_for_blast, names=names(data_for_blast), file.out="tmp/tmp_blast.fna")
  system(cmdCreate_blastn("tmp/tmp_blast.fna", "tmp/tmp_out_blast.txt"))
  blast_result <- read.table(file = "tmp/tmp_out_blast.txt", sep="\t",  
                             col.names=c("contig", "subject", "alignment_length", 
                                         "mistmatches", "gap_openings", 
                                         "e-value", "bit_score", "qcov"),
                             fill=FALSE,  strip.white=TRUE)
  index <- index[names(data_for_blast) %in% blast_result$contig]
  contig_info <- lapply(levels(blast_result$contig), function(y) {
    blast_result_one <- blast_result[which(blast_result$contig == y),]
    blast_result_one <- blast_result_one[which.max(blast_result_one$qcov),]
  })
  contig_info  <- do.call("rbind", contig_info);
  strings <- sapply(contig_info$subject, function(y) {
    y <- gsub("\\|", "\\\\|", y)
    system(paste("echo ", y," > tmp/tmp.txt", sep = ""))
    n <- system(cmdCreate_blastdbcmd("tmp/tmp.txt"), intern = T)
    return(n[1])})
  tmp <- file.remove(c("tmp/tmp.txt", "tmp/tmp_out_blast.txt", "tmp/tmp_blast.fna"))
  data_names <- data.frame(contig_data[index,], contig_info)     
  data_names$Sci_name <- sapply(strsplit(strings , "~"), function(x) {x[1]})
  data_names$Title <- sapply(strsplit(strings , "~"), function(x) {x[2]})
  return(data_names)
}

blast_clusters <- function(contig_cluster, data_cluster, n) {
  n_contigs_cl = length(contig_cluster)
  index <- sort(sample(1:n_contigs_cl, min(n,(n_contigs_cl)), replace = F), decreasing = F)
  data_for_blast <- lapply(contig_cluster[index], function(y) {y[1:min(blast_length, length(y))]})
  write.fasta(sequences=data_for_blast, names=names(data_for_blast), file.out="tmp/tmp_blast.fna")
  system(cmdCreate_blastn("tmp/tmp_blast.fna", "tmp/tmp_out_blast.txt"))
  blast_result <- read.table(file = "tmp/tmp_out_blast.txt", sep="\t",  
                             col.names=c("contig", "subject", "alignment_length", 
                                         "mistmatches", "gap_openings", 
                                         "e-value", "bit_score", "qcov"),
                             fill=FALSE,  strip.white=TRUE)
  index <- index[names(data_for_blast) %in% blast_result$contig]
  contig_info <- lapply(levels(blast_result$contig), function(y) {
    blast_result_one <- blast_result[which(blast_result$contig == y),]
    blast_result_one <- blast_result_one[which.max(blast_result_one$qcov),]
  })
  contig_info  <- do.call("rbind", contig_info);
  strings <- sapply(contig_info$subject, function(y) {
    y <- gsub("\\|", "\\\\|", y)
    system(paste("echo ", y," > tmp/tmp.txt", sep = ""))
    n <- system(cmdCreate_blastdbcmd("tmp/tmp.txt"), intern = T)
    return(n[1])})
  tmp <- file.remove(c("tmp/tmp.txt", "tmp/tmp_out_blast.txt", "tmp/tmp_blast.fna"))
  data_names <- data.frame(data_cluster[index,], contig_info)     
  data_names$Sci_name <- sapply(strsplit(strings , "~"), function(x) {x[1]})
  data_names$Title <- sapply(strsplit(strings , "~"), function(x) {x[2]})
  return(data_names)
}

parse_graph_info <- function(graph_info, large_names){
  graph_info <- graph_info[(graph_info$contig %in% large_names), -1]
  graph_info$left <- apply(graph_info, 1, function(x) {unlist(strsplit(paste(x["left"]), "[/;]"))})
  graph_info$right <- apply(graph_info, 1, function(x) {unlist(strsplit(paste(x["right"]), "[/;]"))})
  graph_info$con_contig <- apply(graph_info, 1, function(x) {n_left <- 0
                                                             n_rigth <- 0
                                                             if (length(x$left)>=3) n_left = seq(from = 1, to = length(x$left), by = 3)
                                                             if (length(x$right)>=3) n_rigth = seq(from = 1, to = length(x$right), by = 3)
                                                             c(as.integer(x$left[n_left]), as.integer(x$right[n_rigth])) })
  graph_info$depth_contig <- apply(graph_info, 1, function(x) {n_left <- 0
                                                               n_rigth <- 0
                                                               if (length(x$left)>=3) n_left = seq(from = 2, to = length(x$left), by = 3)
                                                               if (length(x$right)>=3) n_rigth = seq(from = 2, to = length(x$right), by = 3)
                                                               c(as.integer(x$left[n_left]), as.integer(x$right[n_rigth])) })
  
  graph_info$between_contig <- apply(graph_info, 1, function(x) {n_left <- 0
                                                                 n_rigth <- 0
                                                                 if (length(x$left)>=3) n_left = seq(from = 3, to = length(x$left), by = 3)
                                                                 if (length(x$right)>=3) n_rigth = seq(from = 3, to = length(x$right), by = 3)
                                                                 c(as.double(x$left[n_left]), as.double(x$right[n_rigth])) })
  graph_info$left <- NULL
  graph_info$right <- NULL
  graph_info$depth_contig <- lapply(1:length(graph_info$con_contig), function(i) {graph_info$depth_contig[[i]][graph_info$con_contig[[i]] %in% large_names]} )
  graph_info$between_contig <- lapply(1:length(graph_info$con_contig), function(i) {graph_info$between_contig[[i]][graph_info$con_contig[[i]] %in% large_names]} )
  graph_info$con_contig <- lapply(1:length(graph_info$con_contig), function(i) {graph_info$con_contig[[i]][graph_info$con_contig[[i]] %in% large_names]} )
  graph_info
}


# Command line functions
cmdCreate_blastn <- function(infile, outfile){
  paste("export BLASTDB=", path_to_db,"; /srv/common/bin/blastn -db ", "nt -query ", 
        infile, " -outfmt \"6 qseqid sseqid slen mismatch gapopen evalue bitscore qcovs\" -num_threads 4 -evalue 1e-10 -out ",
        outfile, sep = "")}
cmdCreate_blastdbcmd <- function(infile){
  paste("export BLASTDB=", path_to_db, "; /srv/common/bin/blastdbcmd -db ", 
        "nt -entry_batch ", infile," -outfmt %L~%t", sep = "")}
