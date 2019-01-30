library(tidyverse)
library(ggplot2)
library(ggmap) # installed from github
library(xml2)
library(lubridate)

# Source secret GCP API Key
source('register_google.R')

# Unwrap KMZ and parse enclosed KML
get_kmz <- function(f) {
  kml_file <- unzip(f, list=TRUE)$Name %>% {.[grepl("kml$", .)]}
  extracted <- unzip(f, files = kml_file, exdir=tempdir())
  df <- get_kml(extracted)
  unlink(extracted)
  (df)
}

# Parse KML to a data frame
get_kml <- function(f) {
  
  # Parse to XML
  f_xml <- xml2::read_xml(f)

  # Collect the track information
  d <- as_list(f_xml)$kml$Document$Placemark$Track
  
  # init
  currtime <- NULL
  res <- list()

  # Walk the track and write to data frame
  # Not the fastest, but it'll do for now
  for (i in seq_along(d)) {
    entry <- d[i]
    type <- names(entry)
    if (type=="when") {
      currtime = lubridate::ymd_hms(entry$when[[1]])
    } else if (type=="coord") {
      # add a row at time=currtime
      vals <- as.double(strsplit(entry$coord[[1]], " ")[[1]])
      df <- data_frame(
        time=currtime,
        lat=vals[2],
        lon=vals[1],
        alt=vals[3]
      )
      res[[i]] <- df
    } else {
      # Entry types to handle:
      # altitudeMode (e.g. absolute/relative)
      cat("unknown type: ", type, "\n")
    }
  }
  return(bind_rows(res))
}

# Start inspecting...
data_files <- list.files(path = "data/", pattern="*.kmz", full.names=TRUE)
flights <- lapply(data_files, get_kmz)
all_flights <- bind_rows(flights)

# Transformations
df <- all_flights %>%
  mutate(
    diff = all_flights$alt - lag(all_flights$alt),
    dir = diff > 0
  ) # both flight fields
df_hp <- df %>% filter(lon > -79.3) # high perspective
df_dave <- df %>% filter(lon < -79.3) # dave's field

# overhead view of path
ggplot(df_hp, aes(x=lon, y=lat, color=diff)) + geom_path()
ggplot(df_dave, aes(x=lon, y=lat, color=diff)) + geom_path()

# altitude v. time
ggplot(df, aes(x=time, y=alt, color=diff)) + geom_line()

map_hp <- get_map(location=c(mean(df_hp$lon), mean(df_hp$lat)), maptype="satellite", zoom=16)
map_dave <- get_map(location=c(mean(df_dave$lon), mean(df_dave$lat)), maptype="satellite", zoom=16)

ggmap(map_hp) + geom_path(aes(x=lon, y=lat), color="red", size=0.5, alpha=0.8, data=df_hp)
ggsave(filename='results/ggmap_hp.png', width=5, height=5)
ggmap(map_dave) + geom_path(aes(x=lon, y=lat), color="red", size=0.5, alpha=0.8, data=df_dave)
ggsave(filename='results/ggmap_dave.png', width=5, height=5)

