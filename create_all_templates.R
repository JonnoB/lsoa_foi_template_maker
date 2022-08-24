

##
## Tidyverse packages
##
library(dplyr)
library(purrr)
library(readr)

##
## Other packages
##
library(XLConnect)
library(openxlsx)

basewd = getwd()

ONSPD_path = list.files(file.path(basewd, "data"), full.names = TRUE, pattern = "ONSPD")
documents_path <- file.path(ONSPD_path ,"Documents")

#There should only be one file/folder with ONSPD in the name however if not a warning will be sent
if(length(ONSPD_path)>1) print("Warning more than one ONSPD object defaulting to first in list")

ONSpostcodes_csv <- list.files( file.path(ONSPD_path , "Data"), pattern ="\\.csv", full.names = T)


wards_file <- "lsoa_to_ward.csv"

#The output folder with all the region templates in
Regions <- file.path(basewd, "data" ,"Regions")


select <- dplyr::select

print('Loading data')

#This is a convenience function for loading the lookup tables used by
#the ONSPD
return_lookup_data <- function(folder_path, file_regex_pattern ){
  
  #get the path to the ward names lookup
  lookup_path <-list.files(folder_path, 
                           pattern = file_regex_pattern, 
                           ignore.case = TRUE, 
                           full.names = TRUE)
  
  lookup_df <- read_csv(lookup_path) 
  
  
  
  #Removes the years digits from the column names.
  #The lookup tables have the year that the table codes were generated the name
  #i.e. on the wardnames lookup from after the 2020 update 
  #the column names will be "WD20CD" and "WD20NM",
  #This Regex removes the numbers meaning that changes in years will not affect the process
  #This makes the process more robust.
  #However, if the ONS change the naming convention could cause an error
  names(lookup_df) = gsub("\\d","",names(lookup_df))
  
  return(lookup_df)
}


wardnames_lookup <- return_lookup_data(documents_path, "^ward names.*(csv)" )

region_lookup <- return_lookup_data(documents_path, "^region.*(csv)" ) %>%
  select(1,3)

LADNM_lookup <- return_lookup_data(documents_path, "^la_ua.*(csv)" ) %>%
  select(1:2)


CorePstCd  <- read_csv(ONSpostcodes_csv) %>%
  select(Postcode = pcd, lsoa11cd = lsoa11, 
         MSOA11CD = msoa11, oslaua, 
         OA11CD = oa11, Country_code = ctry, 
         RGNCD =  rgn,
         WDCD = osward)



{
  PstCdLSOA <- CorePstCd %>% 
    left_join(., region_lookup, by = "RGNCD") %>%
    left_join(wardnames_lookup, by = "WDCD") %>%
    left_join(LADNM_lookup, by = c("oslaua"= "LADCD")) %>%
    #filter(Country_code == "W92000004")
    select(Postcode, Country_code, Admin_district_code = oslaua, 
           Admin_ward_code = WDCD, lsoa11cd, LADNM, 
           RGNCD, RGNNM, WD16NM = WDNM) %>%
    mutate(
      #Make sure Scotland and Wales have region names
      RGNCD = case_when(
        grepl("W", Country_code) ~"Wales",
        grepl("S", Country_code) ~"Scotland",
        TRUE ~ RGNCD),
      RGNNM = case_when(
        grepl("W", Country_code) ~"Wales",
        grepl("S", Country_code) ~"Scotland",
        TRUE ~ RGNNM
      ),
      Postcode = gsub(" ", "", Postcode)) %>% #remove spaces from postcodes
    filter(!is.na(RGNNM),
           LADNM != "NA",
           RGNCD !="Scotland")
  
  #This is a large dataframe so we want to remove it when possible to save memory
  rm(CorePstCd)
  
  ###
  ##REGION CLEANING
  ##A small number of postcodes can slip into different, regionss, this 
  ###is likely an error from postcodes being updated bny the ONS or post office. 
  ##The code below fixes this issue by using a majority vote
  ###
  
  #this was used previously but started causing errors when only
  #ONSPD data started being used
  # MajRegion <- PstCdLSOA  %>% group_by(lsoa11cd, RGNCD) %>%
  #   summarise(count = n(),
  #             RGNNM = first(RGNNM)) %>%
  #   group_by(lsoa11cd) %>%
  #   arrange(-count) %>%
  #   summarise_all(first) %>%
  #   select(-count)
  
  MajLAD <- PstCdLSOA  %>% group_by(lsoa11cd, Admin_district_code) %>%
    summarise(count = n()) %>%
    group_by(lsoa11cd) %>%
    arrange(-count) %>%
    summarise_all(first) %>%
    select(-count)
  
  PstCdLSOA  <- PstCdLSOA %>%
    select(-Admin_district_code) %>%
    left_join(MajLAD)
  }


unique(PstCdLSOA$RGNNM) %>%
  walk(~{
    
    title <- paste("Region", .x)
    dir.create(file.path(Regions, title ), recursive = TRUE, showWarnings = FALSE)
    #The inner loop creates the excel files for each LAD within each region
    PstCdLSOA.Reg <- PstCdLSOA %>% filter(RGNNM == .x)
    
    print(title)
    
    unique(PstCdLSOA.Reg$LADNM) %>%
      walk(~{
        
        PstCdLSOA.filt <- PstCdLSOA.Reg %>% filter(LADNM == .x)
        print(paste(title, ":", .x))
        ExemptionsFile <- paste0(.x,"ExemptionsLSOA.xlsx")
        DiscountsFile <- paste0(.x,"DiscountsLSOA.xlsx")
        setwd(basewd)
        wb <- loadWorkbook("Convert Postcode to LSOA.xlsx")
        #input the LSOA lookup table
        writeData(wb, sheet = "LSOAdata", PstCdLSOA.filt, colNames = T)
        #add in randomly sampled postcodes as an example
        writeData(wb, sheet = "Input", sample(PstCdLSOA.filt$Postcode, 6),
                  startCol = 2, startRow = 2,
                  colNames = F)
        setwd(file.path(Regions, title))
        saveWorkbook(wb,ExemptionsFile ,overwrite = T)
        writeData(wb, "Input", "Discount_Type") #So that it says Discounts not exemptions, so nobody gets confused.
        saveWorkbook(wb,DiscountsFile ,overwrite = T)
        
      })
    
  })
