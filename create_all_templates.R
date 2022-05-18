

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

print(list.files())

basewd = getwd()
ONSpostcodes_csv <- list.files( file.path(basewd,'data', "ONSPD", "Data"), pattern ="\\.csv", full.names = T)
AddGeog <- file.path(basewd, "AdditionalGeographies")
wards_file <- "lsoa_to_ward.csv"

#The output folder with all the region templates in
Regions <- file.path(basewd, "data" ,"Regions")


select <- dplyr::select

print('Loading data')
Wardnames <- read_csv(file.path(basewd, 'data' ,wards_file)) 

names(Wardnames) = gsub("\\d","",names(Wardnames))

LADReg <- read.csv(file.path( basewd, 'data',"lad_to_region.csv"), stringsAsFactors = FALSE   )


#changes the name of the lad code so that it matches the ONSPD
names(LADReg) = gsub("\\d","",names(LADReg))
LADReg = LADReg %>% select(-LADNM)


CorePstCd  <- read_csv(ONSpostcodes_csv) %>%
  select(Postcode = pcd, LSOA11CD = lsoa11, 
         MSOA11CD = msoa11, LAD11CD = oslaua, 
         OA11CD = oa11, Country_code = ctry, 
         Region =  rgn)



{
  PstCdLSOA <- CorePstCd %>% 
    left_join(., LADReg, by = c("LAD11CD"="LADCD")) %>%
    left_join(Wardnames, by = c("LSOA11CD"="LSOACD")) %>%
    #filter(Country_code == "W92000004")
    select(Postcode, Country_code, Admin_district_code = LAD11CD, 
           Admin_ward_code = WDCD, lsoa11cd = LSOA11CD, LAD15NM = LADNM, 
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
           LAD15NM != "NA",
           RGNCD !="Scotland")
  #This is a large dataframe so we want to remove it when possible to save memory
  
  #region cleaning
  #some LSOA are in multiple regions and Adminwards this code fixes this by using a majority vote
  
  MajRegion <- PstCdLSOA  %>% group_by(lsoa11cd, RGNCD) %>%
    summarise(count = n(),
              RGNNM = first(RGNNM)) %>%
    group_by(lsoa11cd) %>%
    arrange(-count) %>%
    summarise_all(first) %>%
    select(-count)
  
  MajLAD <- PstCdLSOA  %>% group_by(lsoa11cd, Admin_district_code) %>%
    summarise(count = n()) %>%
    group_by(lsoa11cd) %>%
    arrange(-count) %>%
    summarise_all(first) %>%
    select(-count)
  
  PstCdLSOA  <- PstCdLSOA %>%
    select(-Admin_district_code,-RGNCD, -RGNNM) %>%
    left_join(MajLAD) %>%
    left_join(MajRegion)
  }

rm(CorePstCd)


unique(PstCdLSOA$RGNNM) %>%
  walk(~{
    
    title <- paste("Region", .x)
    dir.create(file.path(Regions, title ), recursive = TRUE, showWarnings = FALSE)
    #The inner loop creates the excel files for each LAD within each region
    PstCdLSOA.Reg <- PstCdLSOA %>% filter(RGNNM == .x)
    
    print(title)
    
    unique(PstCdLSOA.Reg$LAD15NM) %>%
      walk(~{
        
        PstCdLSOA.filt <- PstCdLSOA.Reg %>% filter(LAD15NM == .x)
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
        writeData(wb, "Input", "Discount_Class") #So that it says Discounts not exemptions, so nobody gets confused.
        saveWorkbook(wb,DiscountsFile ,overwrite = T)
        
      })
    
  })
