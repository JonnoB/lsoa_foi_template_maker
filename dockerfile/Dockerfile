# Base image https://hub.docker.com/u/rocker/
FROM rocker/r-base:latest


ADD install_packages.r install_packages.r

#Installing rJava is always a nightmare for some reason. this came from stackoverflow
#https://stackoverflow.com/questions/64739254/installing-rjava-package-with-docker


RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get install -y liblzma-dev && \
    apt-get install -y libbz2-dev && \
    apt install -y r-cran-rjava


## install R-packages
RUN Rscript install_packages.r

WORKDIR /app

CMD Rscript /app/create_all_templates.R

#docker run --rm -it -v $(pwd):/app foi_template/latest:latest 
