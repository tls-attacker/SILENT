####################
# Base
####################
FROM alpine:3.21.3 AS base

# Install dependencies
RUN apk add R R-dev R-doc g++ libxml2-dev fontconfig-dev harfbuzz-dev fribidi-dev freetype-dev libpng-dev tiff-dev libjpeg
RUN R -e "options(repos = c(CRAN = 'http://cran.rstudio.com/')); install.packages(c('tidyverse', 'optparse', 'jsonlite', 'crayon', 'np', 'robcp', 'Qtools'), dependencies=TRUE, Ncpus = 10);"

# Copy scripts 
COPY scripts/functions.R /app/functions.R
COPY scripts/SILENT.R /app/SILENT.R
COPY scripts/Statistical_Power_SILENT.R /app/Statistical_Power_SILENT.R
RUN chmod +x /app/SILENT.R
RUN chmod +x /app/Statistical_Power_SILENT.R

# Create data directory
RUN mkdir -p /data
VOLUME /data

####################
# SILENT-Image
####################
FROM base AS silent
ENTRYPOINT ["/app/SILENT.R"]

####################
# Power-Image
####################
FROM base AS power
ENTRYPOINT ["Rscript", "/app/Statistical_Power_SILENT.R"]