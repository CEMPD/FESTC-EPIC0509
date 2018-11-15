########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################


# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")

# Get environment variables
#syear     <- Sys.getenv("START_YEAR")
epicbase        <- Sys.getenv("EPIC_DIR")                     # base directory of EPIC
swatR           <- paste(epicbase,"/util/swat",sep="")        # R directory
source(paste(swatR,"/functions_epic2swat.r",sep=""))

beld4file <- Sys.getenv("DOMAIN_BELD4_NETCDF")
sitefile <- Sys.getenv("SITE_FILE")
year     <- Sys.getenv("SIM_YEAR")
day_dir  <- Sys.getenv("DAY_DIR")
region   <- Sys.getenv("REGION")
outdir   <- Sys.getenv("OUTDIR")
out_prefix <- Sys.getenv("OUTFILE_PREFIX")

print(paste(">>== EPIC daily file dir: ", day_dir))
print(paste(">>== BELD site  file: ", sitefile))
print(paste(">>== Output directory: ", outdir))
  
# Determine leap year
isleapy <- get_isleapyear(year) 

# extract crops
temcrops <- Sys.getenv("CROPS")
temcrops <- toupper(temcrops)
crops    <- (strsplit(temcrops, " +"))[[1]]

print(">>== Layers and crops: ")
allcrops <- c("HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS")

# calculate all crops 
crops <- allcrops
#if ( "ALL" %in% crops ) crops  <- allcrops
#print( crops )

indexs <- which(allcrops %in% crops)
tlays  <- c(indexs*2-1, indexs*2)
tlays  <- sort(tlays)
print( tlays )

# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
print(">>== Site table stuctures: ")
str(sitetable)

# get crop fraction
beldf <- nc_open(beld4file)
beld.var.names <- names(beldf$var)
print("Beld4 variables: ")
print(beld.var.names)
print("  ")
frac.data <- get.M3.var(file = beld4file,
           var="CROPF")  # Time, crop_cat, row, col)
ncols <- beldf$dim$west_east$len
nrows <- beldf$dim$south_north$len
grids <- nrows*ncols
dx <- ncatt_get(beldf,0,"DX")$value
dy <- ncatt_get(beldf,0,"DY")$value
garea <- dx*dy

# set up id from bottomleft to upright
print(">>== domain information")
print(paste("cols:", ncols, "rows:", nrows, "dx:", dx, "dy:", dy))
print("  ")
id <- c(1:grids)  

#out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC8=sitetable$HUC8)

# Extract crop data from daily file
#FLODAY   	Q, SSF
#SEDDAY  	MUSL
#ORGNDAY 	YON
#ORGPDAY  	YP
#NO3DAY  	QNO3, SSFN
#MINPDAY 	QAP, SSFP
#NH3DAY  	
#NO2DAY	

# NCD file: Y ,M ,D ,PRCP,   QNO3,   SSFN,   PRKN,     DN,    DN2,   AVOL,    HMN,   NFIX,   FER
# SWAT file: DAY YEAR FLODAY SEDDDAY ORGNDAY ORGPDAY NO3DAY NH3DAY NO2DAY MINPDAY CBODDAY DISOXDAY CHLADAY SOLPSTDAY SRBPSTDAY BACTPDAY BACTLPDAY CMTL1DAY CMTL2DAY CMTL3DAY
#cnames<-c("QNO3")

firstfile <- TRUE 
for ( i in tlays ) {
#for ( i in c( 19 ) ) {
   # process daily NCD
   dayfile <- paste(day_dir, "/",i,".NCD", sep="")
   # check if file exist
   if ( file.exists(dayfile)) 
   {  
      print(paste("Processing file ", dayfile))
   } 
   else 
   {
     print(paste("Waring: ", dayfile, " doesn't exist. ")) 
     next
   }

   # check if file is empty
   if ( file.info(dayfile)$size == 0 ) {
     print(paste("Waring: ", dayfile, " has zero line. ")) 
     next
   }

   # check if there are any data in file, if empty, go to next file.  
   daytable <- data.frame(read.csv(dayfile,header=TRUE, sep=",", skip=0, na.strings="NA"))
   print(paste("Number of Records: ", length(daytable$Y)) )
   if ( length(daytable$Y) == 0 )  next

   # get grid ids, 11677030/1000; transfer date to Jdate
   daytable$GRIDID <- floor(daytable$RUN.NAME/1000)
   if ( grepl('FML', day_dir)>0 )  daytable$GRIDID <- floor(daytable$RUN.NAME/10000)

   indic <- daytable$Y == year 
   daytable <- daytable[indic,]
   if ( length(daytable$Y) == 0 ) 
   {
     stop(paste("Error: Please check the simulation year: ", year))
   } 
   daytable$DATE   <- paste(daytable$M,daytable$D,daytable$Y, sep="/")
   daytable$DATE   <- as.Date(daytable$DATE, "%m/%d/%Y")
   daytable$DATE   <- format(daytable$DATE, "%m/%d/%Y")

   daytable$Floday <- daytable$Q+daytable$SSF
   daytable$No3day <- daytable$QNO3+daytable$SSFN
   daytable$Minpday <- daytable$QAP+daytable$DRNP

   day.df <- data.frame(GRIDID=daytable$GRIDID,DATE=daytable$DATE,Floday=daytable$Floday,Sedday=daytable$MUSL,Orgnday=daytable$YON,Orgpday=daytable$YP,No3day=daytable$No3day,Nh3day=0.0,No2day=0.0,Minpday=daytable$Minpday,Cbodday=0.0,Disoxday=0.0,Chladay=0.0,Solpstday=0.0,Srbpstday=0.0,Bactpday=0.0,Bactlpday=0.0,Cmtl1day=0.0,Cmtl2day=0.0,Cmtl3day=0.0)

   # print("Process EPIC daily NCD files: ")
   perc.df <- data.frame(GRIDID=id, PERC=as.vector(as.matrix(frac.data$data[,,i])))
     
   perc.df <- na.omit(perc.df)
   crop.df <- merge(x=day.df, y=perc.df, by="GRIDID" )

   #merge with site file to get HUC8 values
   out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC8=sitetable$HUC8, STCNTY=paste(sprintf("%02d",sitetable$STFIPS), sprintf("%03d",sitetable$CNTYFIPS), sep=""), REG10=sitetable$REG10)
   out.df <- merge(x=crop.df, y=out.df, by="GRIDID" )

   out.df$AREA <- out.df$PERC*0.01*garea*0.0001
   #FLODAY - Contribution to streamflow for the day (m3)  -Q VAR(14) IN mm PER DAY, MUST BE CONVERTED TO M3. HECTARES IN GRID CELL IN HUC*10,000M2*Q/1000, one hectare=10000 square meter.

   out.df$Floday  <- out.df$Floday*out.df$AREA*10  
   out.df$Sedday  <- out.df$Sedday*out.df$AREA
   out.df$Orgnday <- out.df$Orgnday*out.df$AREA
   out.df$Orgpday <- out.df$Orgpday*out.df$AREA
   out.df$No3day  <- out.df$No3day*out.df$AREA
   out.df$Minpday <- out.df$Minpday*out.df$AREA

   out.df$GRIDID <- NULL
   out.df$PERC   <- NULL
   out.df$AREA   <- NULL

   #print("Daily NCD with HUC8: ")
   #str(out.df)
   temp.com.df <-aggregate(.~DATE+HUC8+STCNTY+REG10, data=out.df, sum)

   # crop data aggregate by date and HUC8
   if (firstfile)  
   {
     com.df <- temp.com.df
     firstfile <- FALSE
   }

   if ( !firstfile)  
   {
     com.df<- rbind(com.df, temp.com.df)
     com.df <- aggregate(. ~ DATE+HUC8+STCNTY+REG10, data=com.df, FUN=sum)
   }
}

print("Finished reading daily files! ")

# add 02/29/year for leap year
# com.df$DATE <- as.Date(com.df$DATE)
#if ( isleapy ) {
#   replines <- com.df[com.df$DATE ==  paste("02/28/", year, sep=""), ]
#   #replines$DATE <- paste("02/29/", year, sep="")
#   #ldate <- as.Date(paste("02/29/", year, sep=""), format="%m/%d/%Y")
#   replines$DATE <- paste("02/29/", year, sep="")
#   str(replines)
#   com.df <- rbind(com.df, replines)
#   com.df <- com.df[order(as.Str(com.df$DATE)),]
#}
print("Combined Data Frame: ")
str(com.df)
write.table(com.df, file = paste(outdir,"/",out_prefix,"all_region.csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")

print("Split into county. ")
com_region.df <- com.df
com_region.df$HUC8 <- NULL
com_region.df$REG10   <- NULL
com_region.df <- aggregate(. ~ DATE+STCNTY, data=com_region.df, FUN=sum)
spt_stcty  <- split(com_region.df, com_region.df$STCNTY)
for ( stcty in names(spt_stcty) ) {
    tt.df <-  spt_stcty[[stcty]] 
    tt.df$STCNTY <- NULL
    #if ( isleapy ) {
    #  repline <- tt.df[tt.df$DATE ==  paste("02/28/", year, sep=""), ]
    #  repline $DATE <- paste("02/29/", year, sep="")
    #  tt.df <- rbind(tt.df[1:59,], repline, tt.df[60:365,])
    #}
    write.table(tt.df, file = paste(outdir,"/county/", out_prefix, "stcty_",stcty, ".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
} 

print("Split into state. ")
com_region.df$ST <- substr(com_region.df$STCNTY, 1, 2)
com_region.df$STCNTY <- NULL
com_region.df <- aggregate(. ~ DATE+ST, data=com_region.df, FUN=sum)
spt_st  <- split(com_region.df, com_region.df$ST)
for ( st in names(spt_st) ) {
    tt.df <-  spt_st[[st]] 
    tt.df$STCNTY <- NULL
    #if ( isleapy ) {
    #  repline <- tt.df[tt.df$DATE ==  paste("02/28/", year, sep=""), ]
    #  repline $DATE <- paste("02/29/", year, sep="")
    #  tt.df <- rbind(tt.df[1:59,], repline, tt.df[60:365,])
    #}
    write.table(tt.df, file = paste(outdir,"/state/",out_prefix, "st_",st, ".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
} 

print("Whole domain total.  ")
com_region.df$ST <- NULL
com_region.df <- aggregate(. ~ DATE, data=com_region.df, FUN=sum)
write.table(com_region.df, file = paste(outdir,"/domain/",out_prefix, "whole_domain.csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
rm(com_region.df)

#split file by HUC8, create outputs by HUC8  
com_huc.df  <- com.df
com_huc.df$STCNTY  <- NULL
com_huc.df$REG10   <- NULL
print("Begin split into HUC8! ")
com_huc8.df <- aggregate(. ~ DATE+HUC8, data=com_huc.df, FUN=sum)
spt_huc8 <- split(com_huc8.df, com_huc8.df$HUC8)
print(names(spt_huc8))
for ( huc in names(spt_huc8) ) {
    tt.df <-  spt_huc8[[huc]] 
    tt.df$HUC8 <- NULL
    if ( isleapy ) {
      repline <- tt.df[tt.df$DATE ==  paste("02/28/", year, sep=""), ]
      repline $DATE <- paste("02/29/", year, sep="")
      tt.df <- rbind(tt.df[1:59,], repline, tt.df[60:365,])
    }
    write.table(tt.df, file = paste(outdir,"/HUC8/",out_prefix, "huc8_",huc,".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
} 
rm(com_huc8.df, spt_huc8)

print("Begin split into HUC6! ")
com_huc.df$HUC6  <- floor(com_huc.df$HUC8/100)
com_huc.df$HUC8  <- NULL
com_huc6.df <- aggregate(. ~ DATE+HUC6, data=com_huc.df, FUN=sum)
spt_huc6  <- split(com_huc6.df, com_huc6.df$HUC6)
print(names(spt_huc6))
for ( huc in names(spt_huc6) ) {
    tt.df <-  spt_huc6[[huc]]
    tt.df$HUC6 <- NULL
    if ( isleapy ) {
      repline <- tt.df[tt.df$DATE ==  paste("02/28/", year, sep=""), ]
      repline $DATE <- paste("02/29/", year, sep="")
      tt.df <- rbind(tt.df[1:59,], repline, tt.df[60:365,])
    }
    write.table(tt.df, file = paste(outdir,"/HUC6/",out_prefix,"huc6_",huc,".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
}
rm(com_huc6.df)

print("Begin split into HUC2! ")
com_huc.df$HUC2  <- floor(com_huc.df$HUC6/10000)  
com_huc.df$HUC6  <- NULL  
com_huc2.df <- aggregate(. ~ DATE+HUC2, data=com_huc.df, FUN=sum)
spt_huc2  <- split(com_huc2.df, com_huc2.df$HUC2)
print(names(spt_huc2))
for ( huc in names(spt_huc2) ) {
    tt.df <-  spt_huc2[[huc]]
    tt.df$HUC2 <- NULL
    if ( isleapy ) {
      repline <- tt.df[tt.df$DATE ==  paste("02/28/", year, sep=""), ]
      repline $DATE <- paste("02/29/", year, sep="")
      tt.df <- rbind(tt.df[1:59,], repline, tt.df[60:365,])
    }
    write.table(tt.df, file = paste(outdir,"/HUC2/",out_prefix,"huc6_",huc,".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
}


