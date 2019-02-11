library(tidyverse)
library(ggplot2)
library(ggmap) # installed from github
library(xml2)
library(lubridate)
library(geosphere)

# Source secret GCP API Key
# Also added a line to save the elevation credential to 'secret_key'
source('register_google.R')

# Source parsers
source('parsers.R')

data_files <- list.files(path = "data/", pattern="*.kmz", full.names=TRUE)
flights <- lapply(data_files, get_kmz)
flight <- flights[[54]]

get_ground_elevation <- function(lat, lon) {
  # url <- paste0(
  #   'https://maps.googleapis.com/maps/api/elevation/json?',
  #   'key=', secret_key,
  #   '&locations=', lat, ',', lon
  # )
  # httr::content(httr::POST(url))$results[[1]]$elevation
  return(222)
}

grnd <- c()
for (i in 1:nrow(flight)) {
  grnd[i] <- get_ground_elevation(flight[[i, "lat"]], flight[[i, "lon"]])
}

flight <- flight %>%
  mutate(
    time_prev = c(time[1], lag(time)[2:(length(time))]),
    delta_time = as.numeric(time - time_prev),
    alt_prev = c(alt[1], lag(alt)[2:(length(alt))]),
    delta_alt = (alt - alt_prev) / delta_time,
    elev = grnd,
    agl = alt - elev
  )

m_to_ft <- 3.28084

flight %>%
  ggplot(aes(x=time)) +
  geom_rect(aes(
    xmin = mean(flight$time[9:11]), xmax = flight$time[20],
    ymin = -Inf, ymax = Inf
  ), fill="#4286f4") +
  geom_line(aes(y=alt*m_to_ft)) +
  xlab("Time (UTC)") + ylab("Altitude ASL (ft)")
ggsave(filename='results/preparing_for_launch_altitude.png', width=5, height=3)
flight %>%
  ggplot(aes(x=time)) +
  geom_rect(aes(
    xmin = mean(flight$time[9:11]), xmax = flight$time[20],
    ymin = -Inf, ymax = Inf
  ), fill="#3879e2") +
  geom_line(aes(y=delta_alt*m_to_ft)) +
  xlab("Time (UTC)") + ylab("Change in Altitude (ft/s)")
ggsave(filename='results/preparing_for_launch_delta_altitude.png', width=5, height=3)
flight %>%
  ggplot(aes(x=time)) +
  geom_line(aes(y=agl*m_to_ft)) +
  geom_line(aes(y=0), linetype=2) +
  geom_ribbon(aes(
    ymin = ifelse(agl*m_to_ft>100, 100, 0),
    ymax = ifelse(agl*m_to_ft>100, agl*m_to_ft, 0)
  ), fill="#3879e2") +
  xlab("Time (UTC)") + ylab("Altitude AGL (ft)")
ggsave(filename='results/preparing_for_launch_agl.png', width=7, height=3)