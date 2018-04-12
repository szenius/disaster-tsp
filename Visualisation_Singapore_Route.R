
df<-data.frame("from" = c("Lyon", "Toulouse", "Paris", "Marseille"), 
               "to"= c("Paris", "Paris", "Marseille", "Toulouse"))
meta <- data.frame("name"=c("Lyon", "Toulouse", "Paris", "Marseille"), 
                   "lon"=c(103.8454342, 103.9273405, 103.835212, 103.763679599999),  
                   "lat"=c(1.3691149, 1.3236038, 1.352585, 1.3590288))

g <- graph.data.frame(df, directed=TRUE, vertices=meta)
lo <- layout.norm(as.matrix(meta[,2:3]))


library(sp)
gg <- get.data.frame(g, "both")
vert <- gg$vertices
coordinates(vert) <- ~lon+lat

edges <- gg$edges

edges <- lapply(1:nrow(edges), function(i) {
  as(rbind(vert[vert$name == edges[i, "from"], ], 
           vert[vert$name == edges[i, "to"], ]), 
     "SpatialLines")
})


for (i in seq_along(edges)) {
  edges[[i]] <- spChFIDs(edges[[i]], as.character(i))
}

edges <- do.call(rbind, edges)


library(leaflet)
leaflet(vert) %>% addTiles() %>% addMarkers(data = vert) %>% addPolylines(data = edges)