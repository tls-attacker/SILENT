####################
# Base
####################
FROM alpine:3.21.3 AS base

# Install dependencies
RUN apk add R R-dev build-base
RUN R -e "options(repos = c(CRAN = 'http://cran.rstudio.com/')); install.packages(c('cli', 'glue','jsonlite','np', 'robcp', 'Qtools'), dependencies=TRUE, Ncpus = 12);"

# Copy scripts 
COPY scripts/functions.R /app/functions.R
COPY scripts/SILENT.R /app/SILENT.R
COPY scripts/Statistical_Power_SILENT.R /app/Statistical_Power_SILENT.R
RUN chmod +x /app/SILENT.R
RUN chmod +x /app/Statistical_Power_SILENT.R

# Create data directory
RUN mkdir -p /data
VOLUME /data
WORKDIR /data

####################
# SILENT-Image
####################
FROM base AS silent
ENTRYPOINT ["Rscript", "/app/SILENT.R"]

####################
# Power-Image
####################
FROM base AS power
ENTRYPOINT ["Rscript", "/app/Statistical_Power_SILENT.R"]