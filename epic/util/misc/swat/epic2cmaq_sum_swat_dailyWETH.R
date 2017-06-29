########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
source("functions_dailyWETH.r")

# get file names
sitefile <- Sys.getenv("SITEFILE")
yearfile <- Sys.getenv("YEARFILE")
metdir   <- Sys.getenv("METDIR")
outdir  <- Sys.getenv("OUTDIR")
print(paste(">>== year file:   ", yearfile))
print(paste(">>== output file: ", outname_csv))

region   <- Sys.getenv("REG")
print(paste(">>== Sum by ", region))

# obtain M3 file and file information
projinfo <- get.proj.info.M3(yearfile)
gridinfo <- get.grid.info.M3(yearfile)
print(projinfo)
print(gridinfo)
ncols <- gridinfo$ncols
nrows <- gridinfo$nrows
ncrops <- gridinfo$nlays
grids <- nrows*ncols
garea <- (gridinfo$x.cell.width)*(gridinfo$y.cell.width)

# set up id from bottomleft to upright
id <- c(1:grids)  

# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
str(sitetable)

#  9  WOX  = WET OXIDIZED N(g/ha)
# 10  WRD  = WET REDUCED N(g/ha)
# 11  WOG  = WET ORGANIC N(g/ha)

#TITLE
#MATMO "space"   rammo_mo  rcn_mO  drydep_nh4_mO drydep_no3_mo	
#1988   1        0.0        0.0   ave(WRD+WOG)        ave(WOX)(WNO3)

#  1
# 1988   1        0.0        0.0   ave(WRD+WOG)        ave(WOX)(WNO3)
# mg/l   mg/l    kg/ha/day   kg/ha/day

# .dly file: Y ,M ,D ,PRCP,   QNO3,   SSFN,   PRKN,     DN,    DN2,   AVOL,    HMN,   NFIX,   FER
# 2008   1   1   1    3.97  1.46   0.63
# year month day jdate WOX  WRD     WOG


# GRIDID,YEAR,MONTH,DAY,JDATE,WOX,WRD,WOG

# get gridid and corrpspondign huc8
# LAT	LONG	ELEVATION
site.df <- data.frame(GRIDID=sitetable$GRIDID,LAT=sitetable$YLAT,LONG=sitetable$XLONG,ELEVATION=sitetable$ELEVATION,HUC8=sitetable$HUC8)
str(site.df)

# Create csv files to facilitate processing
  outfiles <- dir(paste(metdir,"/",sep=""), pattern=".csv" )
  NO_f      <- length(outfiles)
  if ( NO_f == 0 ) {
     get_dailywdeps(metdir)
  }

# Read all met files summarized to csv
  outfiles <- dir(paste(metdir,"/",sep=""), pattern=".csv" )
  NO_f      <- length(outfiles)
  if ( NO_f > 0 ){
  for ( no in 1:NO_f )  {
    outfile <- paste(paste(metdir, "/",outfiles[no],sep=""))
    print(outfile)
    tmp.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    #tmp.df <- as.character(tmp.df$GRIDID)

    met_year.df <- merge(x=tmp.df, y=site.df, by="GRIDID")
    str(met_year.df)
    met_year.df <- na.omit(met_year.df)
    if ( no == 1 ) met_dep.df <- met_year.df
    if ( no > 1 )  met_dep.df <- rbind(met_dep.df, met_year.df)
  }
  }

str(met_dep.df)

met_dep.df$GRIDID <- NULL
met_dep.df   <- aggregate(.~YEAR+MONTH+DAY+HUC8, data=met_dep.df,mean, na.rm=TRUE)
met_dep.df$drydep_nh4_mO <- met_dep.df$WRDN + met_dep.df$DRDN + met_dep.df$WORN
met_dep.df$drydep_no3_mo <- met_dep.df$WOXN + met_dep.df$DOXN
met_dep.df$WRDN <- NULL 
met_dep.df$DRDN <- NULL 
met_dep.df$WORN <- NULL 
met_dep.df$WOXN <- NULL 
met_dep.df$DOXN <- NULL 
met_dep.df$JDATE <- paste(met_dep.df$MONTH,met_dep.df$DAY,met_dep.df$YEAR, sep="/")
met_dep.df$JDATE   <- as.Date( met_dep.df$JDATE, "%m/%d/%Y")
#met_dep.df$JDATE   <- format( met_dep.df$JDATE, "%m/%d/%Y")
met_dep.df$JDATE  <- format( met_dep.df$JDATE, "%j")
met_dep.df <- met_dep.df[with(met_dep.df,order(HUC8,YEAR,MONTH,DAY)),]
is.num<- sapply(met_dep.df, is.numeric)
met_dep.df[is.num] <- lapply(met_dep.df[is.num], round, 8)

spt_huc8  <- split(met_dep.df, met_dep.df$HUC8)
#lapply(names(spt_huc8), function(x){spt_huc8[[x]]["HUC8"]<-NULL; x})  
print(names(spt_huc8))

# create and write N dep files
for ( huc in names(spt_huc8) ) {
    tt.df <-  spt_huc8[[huc]] 
    tt.df$HUC8 <- NULL
    str(tt.df)
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mO=0.0,drydep_nh4_mO=tt.df$drydep_nh4_mO, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/dailyWETH/dep/ndep_2001_", huc,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(metdir,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)

    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
} 

# export HUC8 LAT, LONG, and Elevation
# rad:  Radiation (MJ m^02) - daily total
# pcp:  Daily Total Precipitation
# maxt: Daily Maximum 2m Temperature (C)
# mint: Daily Minimum 2m Temperature (C)
# rhd : Daily Average Relative Humidity
# wsp : Daily Average 10m Windspeed (m/s)
info.df    <- data.frame(NAME=met_dep.df$HUC8,LAT=met_dep.df$LAT,LONG=met_dep.df$LONG, ELEVATION=met_dep.df$ELEVATION)
metinfo.df <- unique(info.df)
metinfo.df$ID  <- seq.int(nrow(metinfo.df))
for ( item in c("rad", "pcp", "tmp", "rhd", "wsp") ) {
    outmet.df <- data.frame(ID=metinfo.df$ID, NAME=metinfo.df$NAME,LAT=metinfo.df$LAT,LONG=metinfo.df$LONG,ELEVATION=metinfo.df$ELEVATION)
    outmet.df$NAME <- paste(item, outmet.df$NAME, sep="") 
    filename <- paste(outdir,"/dailyWETH/met/",item,".txt",sep="")
    print(filename)
    write.table(outmet.df, file=filename, col.names=T,row.names=F, append=F, quote=F, sep=",")
}

for ( huc in names(spt_huc8) ) {
    tt.df <-  spt_huc8[[huc]]
    str(tt.df)
    out_rad  <- c("20010101", as.vector(tt.df$RAD))
    filename <- paste(outdir,"/dailyWETH/met/rad",huc,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")

    out_pcp  <- c("20010101", as.vector(tt.df$PRECP))
    filename <- paste(outdir,"/dailyWETH/met/pcp",huc,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")

    out_t.df <- data.frame(MINT=tt.df$MINT, MAXT= tt.df$MAXT)
    filename <- paste(outdir,"/dailyWETH/met/tmp",huc,".txt",sep="")
    write("20010101",file=filename,append=F)
    write.table(out_t.df,file=filename,col.names=F,row.names=F, append=T, quote=F, sep=",")

    out_rhd  <- c("20010101", as.vector(tt.df$HUM))
    filename <- paste(outdir,"/dailyWETH/met/rhd",huc,".txt",sep="")
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")

    out_wsp  <- c("20010101", as.vector(tt.df$WINDS))
    filename <- paste(outdir,"/dailyWETH/met/wsp",huc,".txt",sep="")
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
}
