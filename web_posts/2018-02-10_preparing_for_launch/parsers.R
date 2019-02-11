# Vario Log Parsers

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

