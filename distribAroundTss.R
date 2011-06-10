# Plots the distribution of sequences around a defined interval around the TSS

library(ggplot2)
setwd("~/work/freq_array")
int_size = 1000
win_size = 20

# Please change to the approprate filename
if (win_size == 0) {
  e17.filename = paste('E17_10000', '.txt', sep="")
  p15.filename = paste('PN15_10000', '.txt', sep="")
} else {
  e17.filename = paste('E17_10000', '_win', win_size, '.txt', sep="")
  p15.filename = paste('PN15_10000', '_win', win_size, '.txt', sep="")
}

e17.freq = read.delim(e17.filename)
p15.freq = read.delim(p15.filename)

e17.freq2 = data.frame(Offset=e17.freq$X.Offset, Value=e17.freq$Value, Type=rep("E17", nrow(e17.freq)))
p15.freq2 = data.frame(Offset=p15.freq$X.Offset, Value=p15.freq$Value, Type=rep("PN15", nrow(p15.freq)))

#f = (2703615-24) / (5042007-24);
#e17.freq2$Value = e17.freq2$Value * f

if (int_size < 10000) {
  e17.freq3 = subset(e17.freq2, e17.freq2$Offset >= -int_size & e17.freq2$Offset <= int_size)
  p15.freq3 = subset(p15.freq2, p15.freq2$Offset >= -int_size & p15.freq2$Offset <= int_size)
} else {
  e17.freq3 = e17.freq2
  p15.freq3 = p15.freq2
}
mouse = rbind(p15.freq3, e17.freq3)

m <- ggplot(mouse, aes(x=Offset, y=Value, color=Type))
m <- m + geom_line(size = 3)
m <- m + scale_x_continuous("Offset from Transcription Start Site") + scale_y_continuous("Number of Sequences")

#Opts settings could be reviewed with theme_get()
m <- m + opts(axis.title.x = theme_text(size = 20), axis.title.y = theme_text(size = 20, angle = 90))
m <- m + opts(axis.text.x = theme_text(size = 15), axis.text.y = theme_text(size = 15))
m <- m + opts(legend.title = theme_text(face = "bold", size = 15, hjust = 0), legend.text = theme_text(size = 15))
m <- m + opts(title = "Peaks Distribution Relative to Mouse Genes (mm9)", plot.title = theme_text(size = 30))

print(m)

#png.filename = paste('E17andPN15_smoothed_', int_size, '.png', sep="")
#png(png.filename, width=1600, height=1200);
#print(m);
#dev.off();
