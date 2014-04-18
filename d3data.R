library(rjson)
library(reshape2)

df <- read.csv("201402_trip_data.csv", header=T, stringsAsFactors=F)
sf <- statdf[statdf$landmark == "San Francisco" ,"name"]
tripdf <- df[df$End.Station %in% sf & df$Start.Station %in% sf,]

#tripdf[tripdf$End.Station == "Redwood City Public Lilbrary","End.Station"] <- "Redwood City Public Library"
#tripdf[tripdf$Start.Station == "Redwood City Public Lilbrary","Start.Station"] <- "Redwood City Public Library"

station <- tripdf %.%
  group_by(Start.Station, End.Station) %.%
  summarize(count=n(),
            dursd=sd(Duration),
            quant0=fivenum(Duration, na.rm = TRUE)[1],
            quant25=fivenum(Duration, na.rm = TRUE)[2],
            quant50=fivenum(Duration, na.rm = TRUE)[3],
            quant75=fivenum(Duration, na.rm = TRUE)[4],
            quant1=fivenum(Duration, na.rm = TRUE)[5],
            iqr=quant75-quant25,
            low=range(Duration[!(Duration<(quant25-1.5*iqr)|Duration>(quant75+1.5*iqr))], na.rm=T)[1],
            high=range(Duration[!(Duration<(quant25-1.5*iqr)|Duration>(quant75+1.5*iqr))], na.rm=T)[2]) %.% 
  arrange(Start.Station, desc(count))

n <- sum(station$count)
ord <- as.character(clust$name)
test <- data.frame(table(tripdf$Start.Station, tripdf$End.Station)/n)
temp <- dcast(test, Var1 ~ Var2, value.var = "Freq")
temp$Var1 <- as.character(temp$Var1)
temp <- temp[match(ord, temp$Var1),]
temp <- temp[,match(c("Var1", ord), colnames(temp))]
row.names(temp) <- temp$Var1
temp <- as.matrix(temp[,-1])
templ <- split(temp, rownames(temp))
templ2 <- list()
templ2 <- sapply(1:35, function(x) templ[ord[x]])
names(templ2) <- NULL
sink("rides.json")
cat(toJSON(templ2))
sink()
