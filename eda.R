library(dplyr)
library(ggplot2)
library(ggmap)
library(RColorBrewer)
library(lubridate)

df <- read.csv("201402_trip_data.csv", header=T, stringsAsFactors=F)
statdf <- read.csv("201402_station_data.csv", header=T, stringsAsFactors=F)
sf <- statdf[statdf$landmark == "San Francisco" ,"name"]
tripdf <- df[df$End.Station %in% sf & df$Start.Station %in% sf,]

####### station map #######

map.center <- geocode("San Francisco, CA")
sanfran <- get_map(location = c(lon=map.center$lon, lat=map.center$lat), 
                   source="google", 
                   #color="bw",
                   #maptype="toner"
                   zoom=13)
ggmap(sanfran, fullpage=T) + 
  geom_point(data=statdf, aes(x=long, y=lat), color="red", size=5, alpha=.5) + 
  geom_point(data=data.frame(km$centers), aes(x=long, y=lat), color="blue", size=5, alpha=.5)

####### clustering stations using pca #######

tripdf$wday <- wday(strptime(tripdf$Start.Date, format="%m/%d/%Y %H:%M"), label=T)
tripdf$hrstart <- format(strptime(tripdf$Start.Date, format="%m/%d/%Y %H:%M"), format="%H")
hrs <- sort(unique(tripdf$hrstart))

#tripdf$hrend <- format(strptime(tripdf$End.Date, format="%m/%d/%Y %H:%M"), format="%H")
total.trips <- nrow(tripdf)

data <- tripdf %.%
  group_by(Start.Station) %.%
    summarize(
      count=    n(),
      per.tot=  round(n()/total.trips,3),
      per.self= round(sum(Start.Station == End.Station)/count,3),
      per.sub=  round(sum(Subscription.Type == "Subscriber")/count,3),
      per.wknd= round(sum(wday    %in% c("Sat", "Sun"))   /count,3),
      per.cmut= round(sum(hrstart %in% hrs[c(7:10,17:20)])/count,3),
      per.late= round(sum(hrstart %in% hrs[c(1:6,21:24)]) /count,3),
      dur.sub=  round(median(Duration[Subscription.Type == "Subscriber"]),1),
      dur.cust= round(median(Duration[Subscription.Type == "Customer"  ]),1)
      ) %.%          
  arrange(Start.Station, desc(count))

#plot(table(tripdf$hrstart, tripdf$Subscription.Type))

data[,3:ncol(data)] <- apply(data[,3:ncol(data)], 2, scale)
pca <- princomp(~ ., data=data[3:ncol(data)])

plot(pca$scores[,1], pca$scores[,2], xlim = c(-3.5,4.5), ylim = c(-3,3), pch=20, col="red")
text(pca$scores[,1], pca$scores[,2], labels=data$Start.Station, cex=.75, pos=1)
biplot(pca)
screeplot(pca, type="lines")

dimnames(pca$scores)[[1]] <- data$Start.Station

comp1 <- pca$scores[,c("Comp.1")]
comp2 <- pca$scores[,c("Comp.2")]
comp3 <- pca$scores[,c("Comp.3")]

hc1 <- hclust(dist(comp1), method = "complete") # or average
hc2 <- hclust(dist(cbind(comp1, comp2)), method = "complete")
hc3 <- hclust(dist(cbind(comp1, comp2, comp3)), method = "complete")

plot(hc2, hang = -1)
rect.hclust(hc2, 5)

library(ape)
library(dendroextras)

plot(as.phylo(hc2), cex = 0.9, label.offset = .2)
labels(hc2)
clust <- data.frame(name=names(slice(hc2,k=5)), cluster=slice(hc2,k=5))

#data.frame(statsf, cluster=clust$cluster)
lookup <- data.frame(cluster=unique(clust$cluster), color=brewer.pal(5,"RdBu"))

clust <- merge(lookup, clust, by="cluster")
clust <- clust[order(clust$color), c("name", "color")]

write.csv(clust, "rides.csv", row.names=F)
