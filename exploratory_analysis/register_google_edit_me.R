## Google Cloud Platform key
#
# To be able to use features of ggmap such as satellite map tiles, you will
# need a Google Cloud Platform key with the relevant Maps APIs enabled.
#
# At the time of writing, I'm using the development version of ggmap as well
# You can install this using:
# 
# devtools::install_github("dkahle/ggmap")
#
# For more details, refer to: https://github.com/dkahle/ggmap
#
# Place your Google Cloud Platform API key here, and don't share it.
# Rename the file to register_google.R, as this file is included in .gitignore.

ggmap::register_google(key='<my key>')
