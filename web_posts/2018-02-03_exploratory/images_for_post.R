library(tidyverse)
library(ggplot2)
library(ggmap) # installed from github
library(xml2)
library(lubridate)
library(geosphere)

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

##########
# Get Data

data_files <- list.files(path = "data/", pattern="*.kmz", full.names=TRUE)
flights <- lapply(data_files, get_kmz)
all_flights <- bind_rows(flights)

# Transformations
df <- all_flights %>%
  mutate(
    diff = all_flights$alt - lag(all_flights$alt),
    dir = diff > 0
  ) # both flight fields

df_hp <- all_flights %>% filter(lon > -79.3) # high perspective
df_fg <- all_flights %>% filter(lon < -79.3) # fly gravity

map_hp <- get_map(location=c(mean(df_hp$lon), mean(df_hp$lat)), maptype="satellite", zoom=16)
ggmap(map_hp) + geom_path(aes(x=lon, y=lat), color="red", size=0.5, alpha=0.8, data=df_hp)
ggsave(filename='plots/ggmap_hp.png', width=5, height=5, dpi = 144)

map_fg <- get_map(location=c(mean(df_fg$lon), mean(df_fg$lat)), maptype="satellite", zoom=16)
ggmap(map_fg) + geom_path(aes(x=lon, y=lat), color="red", size=0.5, alpha=0.8, data=df_fg)
ggsave(filename='plots/ggmap_fg.png', width=5, height=5, dpi = 144)

#####################
# Developing features

# Get distance travelled between points
get_distance <- function(lat_1, lon_1, lat_2, lon_2) {
  # http://www.ridgesolutions.ie/index.php/2013/11/14/algorithm-to-calculate-speed-from-two-gps-latitude-and-longitude-points-and-time-difference/
  
  # To Radians
  rlat_1 <- lat_1 * pi / 180
  rlon_1 <- lon_1 * pi / 180
  rlat_2 <- lat_2 * pi / 180
  rlon_2 <- lon_2 * pi / 180
  
  R <- 6378100
  
  # P
  rho_1 <- R * cos(rlat_1)
  z_1 <- R * sin(rlat_1)
  x_1 <- rho_1 * cos(rlon_1)
  y_1 <- rho_1 * sin(rlon_1)
  # Q
  rho_2 <- R * cos(rlat_2)
  z_2 <- R * sin(rlat_2)
  x_2 <- rho_2 * cos(rlon_2)
  y_2 <- rho_2 * sin(rlon_2)
  
  # Dot Product
  dot <- (x_1 * x_2 + y_1 * y_2 + z_1 * z_2)
  cos_theta <- dot/(R^2)
  theta <- acos(cos_theta)
  
  res <- R * theta
  return(R * theta)
}

get_speed <- function(distance, delta_time) {
  distance / delta_time
}
  
get_specific_energy <- function(alt, speed) {
  g <- 9.81
  h <- alt
  V <- speed
  (g * h) + (1/2 * V^2)
}

#########################
# Inspect specific flight

flight <- flights[[54]]
ggplot(flight, aes(lon, lat)) + geom_point()

# Add features
flight_data <- flight %>% mutate(
  lat_prev = c(lat[1], lag(lat)[2:(length(lat))]),
  lon_prev = c(lon[1], lag(lon)[2:(length(lon))]),
  time_prev = c(time[1], lag(time)[2:(length(time))]),
  delta_time = as.numeric(time - time_prev),
  alt_prev = c(alt[1], lag(alt)[2:(length(alt))]),
  delta_alt = (alt - alt_prev) / delta_time,
  distance = get_distance(lat, lon, lat_prev, lon_prev),
  speed = get_speed(distance, delta_time),
  delta_speed = (speed - c(speed[1], lag(speed)[2:(length(speed))])) / delta_time,
  specific_energy = get_specific_energy(alt, speed),
  delta_specific_energy = (specific_energy - c(specific_energy[1], lag(specific_energy)[2:(length(specific_energy))])) / delta_time,
  bearing = geosphere::bearing(cbind(lon, lat)),
  cumulative_distance = cumsum(distance),
  change = abs(delta_alt * delta_specific_energy)
)

#######
# Plots
rgl::plot3d(flight_data$lon, flight_data$lat, flight_data$alt, xlab="Longitude", ylab="Latitude", zlab="Altitude (m)")
# captured screenshot

# immediatly, can plot altitude as function of time
ggplot(flight_data, aes(time, alt)) + geom_line() +
  xlab("Time (UTC)") + ylab("Altitude ASL (m)")
ggsave(filename='plots/explore_alt_v_time.png', width=5, height=2.5)

ggplot(flight_data, aes(cumulative_distance, alt)) + geom_line() +
  xlab("Distance (m)") + ylab("Altitude ASL (m)")
ggsave(filename='plots/explore_alt_v_distance.png', width=5, height=2.5)

ggplot(flight_data[10:785,], aes(time, speed)) + geom_line() +
  xlab("Time (UTC)") + ylab("Speed (m/s)")
ggsave(filename='plots/explore_speed_v_time.png', width=5, height=2.5)

ggplot(flight_data[230:325,], aes(time, speed)) + geom_line() + geom_smooth(method="loess") +
  expand_limits(y=0) + xlab("Time (UTC)") + ylab("Speed (m/s)")
ggsave(filename='plots/explore_speed_while_circling_1.png', width=5, height=5)
{
  flight_data[230:325,] %>%
  {
    map <- get_map(location=c(mean(.$lon), mean(.$lat)), maptype="satellite", zoom=17)
    ggmap(map) + geom_path(aes(x=lon, y=lat), color="red", size=0.5, alpha=0.8, data=.)
  }
}
ggsave(filename='plots/explore_speed_while_circling_2.png', width=5, height=5, dpi = 100)

ggplot(flight_data[10:782,], aes(time, bearing)) + geom_line() +
  xlab("Time (UTC)") + ylab("Bearing (degrees)")
ggsave(filename='plots/explore_bearing_v_time.png', width=5, height=2.5)

ggplot(flight_data[230:325,], aes(speed, bearing)) +
  geom_point(size=1.5) + coord_polar(start=pi, theta="y") +
  expand_limits(x=0) +
  scale_y_continuous(limits=c(-180, 180), breaks=seq(-180+45, 180, by=45)) +
  xlab("Speed (m/s)") + ylab("Bearing (degrees)")
ggsave(filename='plots/explore_bearing_speed.png', width=5, height=3.5)

ggplot(flight_data[10:785,], aes(time, specific_energy)) + geom_line() +
  xlab("Time (UTC)") + ylab("Specific Energy (J/kg)")
ggsave(filename='plots/explore_specific_energy_v_time.png', width=5, height=2.5)

ggplot(flight_data[10:785,], aes(time, delta_specific_energy)) + geom_line() + geom_smooth(span=0.1) +
  xlab("Time (UTC)") + ylab("Specific Energy (J/kg·s)")
ggsave(filename='plots/explore_delta_specific_energy_v_time.png', width=5, height=2.5)
