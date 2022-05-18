# Sucessfully make sensitive geospatial FOI's using pre-anonymisation

Requesting geospatial data throught the UK FOI system can often result in rejection due to risk of breach of the data protection act.

In order to avoid such issues, the code in this repository creates an excel file that takes postcode data from the target departments database and returns the LSOA code.-
This allows the target department to delete the postocde data leaving just the LSOA and preventing the disclosure of sensitive information, or the identification of individuals.

The goal of this repo is to encourage government transparency and access to government data whilst protecting the privacy of individuals. 

This approach as been successfully applied to over 120 FOI's with zero rejections (Although there was a cartain amount of back and fourth in some cases!).

The approach uses the fact that all government departments use relational databases and can extract data in CSV or excel format.

# Instructions

- Download the three datasets shown in the section below to the data folder in the repo
- Extract the files if neccessary and rename them such that
    - The ONSPD folder is called "ONSPD"
    - The LSOA to ward lookup is called "lsoa_to_ward.csv"
    - The LSOA to region lookup is called "lad_to_region.csv"
- If using docker [build the image](dockerfile)
- Run the R script or docker image
    - If you are not using the dockerfile make sure you have installed the [required packages](dockerfile/install_packages.r)
- The resulting files will be in the folder `./data/Regions`. For ease of use the templates are organised by Region of England and Wales

## Help with Java jdk and jni.h

Installing Java dependencies for R can be a horrible experience, and beyond the scope of this readme. You will have to work it out yourself if you end up with the dreaded "jni.h: No such file or directory" message. [This stackoverflow question](https://stackoverflow.com/questions/42562160/r-cmd-javareconf-not-finding-jni-h) may help. It may be easier to use the [Docker image](dockerfile).



# Data

The data needed for creating the templates can be found at the links below. The links were the most recent at the time of creating the repo,
however only the ONSPD really matters. An update for census 2021 areas may be appropriate soon though.

There are 
- [ONSPD](https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=-created&tags=onspd)
- [LSOA to ward lookup](https://data.gov.uk/dataset/9e14de72-df2a-4bbe-b131-1844394e8368/lower-layer-super-output-area-2011-to-ward-2019-lookup-in-england-and-wales)
- [Local authority to region lookup](https://data.gov.uk/dataset/87f1b677-eeec-43b0-a01d-a319992ab8e4/local-authority-district-to-region-december-2018-lookup-in-england) 



# Citing

Bourne, J. Empty homes: mapping the extent and value of low-use domestic property in England and Wales. Palgrave Commun 5, 9 (2019). https://doi.org/10.1057/s41599-019-0216-y

