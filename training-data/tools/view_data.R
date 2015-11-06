#!/usr/local/bin/Rscript

args <- commandArgs(trailingOnly = TRUE)
filename <- args[1]

# load csv file
print(paste("loading: ", filename))
data <- read.csv(filename, header=FALSE)

# set column names
names(data) <- c("x", "y", "z", "ex", "int", "kg", "rep")

# plot x,y,z and ex
plot.ts(data[c("x", "y", "z", "ex")], main="Sensors data")
