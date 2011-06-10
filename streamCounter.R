#Plots the average number of sequences that falls in a defined interval upstream and downstream of the TSS,
#Represented as separate chromosomes

setwd("~/work/freq_count/")
library(ggplot2)

e17.data = read.delim("E17_count_norand.txt");
p15.data = read.delim("PN15_count_norand.txt");

getmean = function(data, c, ud) {
  s = subset(data, data$chrom==c, select=ud);
  return (mean(s));
}

chr.list = c('chr1', 'chr2', 'chr3', 'chr4', 'chr5', 'chr6', 'chr7', 'chr8', 'chr9', 'chr10', 'chr11', 'chr12', 'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18', 'chr19', 'chrX', 'chrY');
chr.str.list = c('chr01', 'chr02', 'chr03', 'chr04', 'chr05', 'chr06', 'chr07', 'chr08', 'chr09', 'chr10', 'chr11', 'chr12', 'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18', 'chr19', 'chrX', 'chrY');

chrvmean = function(data, clist, ud) {
  a = vector();
  for (i in 1:length(clist)) {
    a[length(a)+1] = getmean(data, clist[i], ud);
  }
  return (a);
}

#Normalization factor
f = (2703615-24) / (5042007-24);

e17u_mean = chrvmean(e17.data, chr.list, 'Upstream');
e17d_mean = chrvmean(e17.data, chr.list, 'Downstream');
p15u_mean = chrvmean(p15.data, chr.list, 'Upstream');
p15d_mean = chrvmean(p15.data, chr.list, 'Downstream');

e17u_mean_n = e17u_mean * f;
e17d_mean_n = e17d_mean * f;

e17u.type = rep("E17 Upstream", 21);
e17d.type = rep("E17 Downstream", 21);
p15u.type = rep("PN15 Upstream", 21);
p15d.type = rep("PN15 Downstream", 21);

e17u.df = data.frame(chrom=chr.str.list, avecount=e17u_mean_n, type=e17u.type);
e17d.df = data.frame(chrom=chr.str.list, avecount=e17d_mean_n, type=e17d.type);
p15u.df = data.frame(chrom=chr.str.list, avecount=p15u_mean, type=p15u.type);
p15d.df = data.frame(chrom=chr.str.list, avecount=p15d_mean, type=p15d.type);
mouse = rbind(e17u.df, p15u.df, e17d.df, p15d.df);


library(ggplot2);
m<-ggplot(mouse, aes(x=chrom, y=avecount, fill=type));
m<-m+layer(geom="bar", position="dodge");
m<-m+scale_fill_manual(value = c("grey", "lightgreen", "grey", "lightgreen"));
#png('AverageHitNorm_E17andPN15.png', width=1600, height=1200);
#print(m);
#dev.off();

