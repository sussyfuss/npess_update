
# This script downloads the NPESS file from the CMS NPESS website
# The file is output to the /extdata folder 
# Alternatively, the data is saved as a data frame here and into the /data folder


# function to install packages if missing by user
usePackage<-function(p){
  # load a package if installed, else load after installation.
  # Args:
  #   p: package name in quotes
  
  if (!is.element(p, installed.packages()[,1])){
    print(paste('Package:',p,'Not found, Installing Now...'))
    install.packages(p, dep = TRUE)}
  print(paste('Loading Package :',p))
  require(p, character.only = TRUE)  
}


# load the libraries using the above function
usePackage("xml2") # xml
usePackage("rvest") # web scrape
usePackage("stringr") # manipulate the string
usePackage("dplyr") # munge data
usePackage("data.table") # for use with the fread download


URL <- "http://download.cms.gov/nppes/NPI_Files.html" # Starts here to search for the weekly dissemination files
baseURL <- "http://download.cms.gov/nppes/" # use this for pasting together the correct URLs

# web scrap the URLs
pg <- read_html(URL)
df.temp <- as.data.frame(html_attr(html_nodes(pg, "a"), "href"), stringsAsFactors = FALSE)

# label the column x
colnames(df.temp)[1] <- "x"

# filter down for the weekly URL Patterns
df.temp2 <- df.temp %>% filter(grepl(x, pattern = "./NPPES_Data_Dissemination_") & grepl(x, pattern = "Weekly.zip") 
)

# replace the ./ with the baseURL
df.temp3 <- list(x = str_replace_all(df.temp2$x, pattern = "./", replacement = baseURL))
urlList <- as.data.frame(df.temp3$x, stringsAsFactors = F)

# rename the column to x
colnames(urlList)[1] <- "x"

# sequence out the URLs, this assumes that the max value is the most recent weekly dissemination file
urlList$sequence <- seq(nrow(urlList))
urlList <- filter(urlList, sequence == max(urlList$sequence))

# Get the file name to extract
urlList$file_short_name <- regmatches(urlList$x, gregexpr("(?<=Dissemination_).*?(?=_Weekly)",urlList$x, perl = TRUE))
#urlList$file_short_name <- paste("npidata_",str_replace_all(urlList$file, pattern = "_", replacement = "-"), sep="")

# drop the temps
rm(list = c("df.temp","df.temp2", "df.temp3"))

# download the file
temp <- tempfile()
download.file(urlList[1,1], temp)

# get  the csv file that isn't the File Header 
zipped_csv_names <- as.data.frame(grep('\\.csv$', unzip(temp, list=TRUE)$Name, 
                                       ignore.case=TRUE, value=TRUE), stringsAsFactors = F)
colnames(zipped_csv_names)[1] <- "fullfile"
urlList$fullfile <- zipped_csv_names %>% filter(!grepl(zipped_csv_names$fullfile, pattern = "FileHeader"))

# drop the zipped_csv_names 
rm(zipped_csv_names)

# build a name for the data.frame
dfName <- paste("npess_weekly_file_", urlList[,3], sep = "")

# assign the csv file to npess temporarily
npess <- fread(unzip(temp, files = paste(urlList[1,4]), exdir="extdata"))


# rename the data frame from npess to dfName's value and drop the temp npess data frame
assign(dfName, npess)
rm(npess)

# unlink to the temp
unlink(temp) 


# remove the temp file
rm(temp)

# save the rda file
save(dfName, file = paste("data/",dfName,".rda", sep = ""))


# remove the other unnecessary items now
rm(list = c("pg", "urlList","baseURL", "dfName", "URL", "usePackage"))

# tell the user where to get their
print(paste("Files are ready here: ", getwd(), sep=""))

