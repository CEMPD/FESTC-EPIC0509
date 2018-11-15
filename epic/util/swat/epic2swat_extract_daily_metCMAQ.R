########################################
# Extract from daily weather for SWAT   
# Developed by: UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
epicbase        <- Sys.getenv("EPIC_DIR")                     # base directory of EPIC
swatR           <- paste(epicbase,"/util/swat",sep="")        # R directory
source(paste(swatR,"/functions_epic2swat.r",sep=""))

# get file names
sitefile <- Sys.getenv("SITE_FILE")
beld4file <- Sys.getenv("DOMAIN_BELD4_NETCDF")
depmetfile   <- Sys.getenv("DEPMET_FILE")
outdir  <- Sys.getenv("OUTDIR")
#region   <- Sys.getenv("REGION")

print(paste(">>== Dep weather file:   ", depmetfile))
print(paste(">>== Beld4 file: ", beld4file))

# obtain M3 file and file information
projinfo <- get.proj.info.M3(depmetfile)
gridinfo <- get.grid.info.M3(depmetfile)
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
print("Site table: ")
str(sitetable)

#  1
# 1988   1        0.0        0.0   ave(WRD+WOG)        ave(WOX)(WNO3)
# mg/l   mg/l    kg/ha/day   kg/ha/day

# .dly file: Y ,M ,D ,PRCP,   QNO3,   SSFN,   PRKN,     DN,    DN2,   AVOL,    HMN,   NFIX,   FER
# 2001   1   1   1    3.97  1.46   0.63
# year month day jdate WOX  WRD     WOG

# GRIDID,YEAR,MONTH,DAY,JDATE,WOX,WRD,WOG

# get gridid and corrpspondign huc8
# LAT	LONG	ELEVATION
site.df <- data.frame(GRIDID=sitetable$GRIDID,LAT=sitetable$YLAT,LONG=sitetable$XLONG,ELEVATION=sitetable$ELEVATION,HUC8=sitetable$HUC8, STCNTY=paste(sprintf("%02d",sitetable$STFIPS), sprintf("%03d",sitetable$CNTYFIPS), sep="") )
rm(sitetable)

tperc.df <- get_tcrop(beld4file, id)
print("Perc table: ")
str(tperc.df)

yf <- nc_open(depmetfile)
depmet.var.name <- names(yf$var)
print(depmet.var.name)

#nvar <- length(nvar.var.name)
#[1] "TFLAG"           "Radiation"       "Tmax"            "Tmin"           
#[5] "Precipitation"   "R_humidity"      "Windspeed"       "Dry_Oxidized_ND"
#[9] "Dry_Reduced_ND"  "Wet_Oxidized_ND" "Wet_Reduced_ND"  "Wet_Organic_ND" 
grid.Radi <- get.M3.var(file = depmetfile, var="Radiation")
grid.Tmax <- get.M3.var(file = depmetfile, var="Tmax")
grid.Tmin <- get.M3.var(file = depmetfile, var="Tmin")
grid.Prec <- get.M3.var(file = depmetfile, var="Precipitation")
grid.Humi <- get.M3.var(file = depmetfile, var="R_humidity")
grid.WS   <- get.M3.var(file = depmetfile, var="Windspeed")

sdate <- ncatt_get(yf, varid=0, attname="SDATE")$value
days  <-  yf$dim$TSTEP$len
print (paste("Start date and days: ", sdate, days))

# Read all met files summarized to csv
isFirst <- TRUE
cdate <- sdate
for ( i in c(1:days) ) {
#for ( i in c(1:2) ) {
# "rad", "pcp", "tmp", "rhd", "wsp"
  print(i)
  mettmp.df <- data.frame(GRIDID=id, DATE=cdate,RAD=as.vector(as.matrix(grid.Radi$data[,,,i])), PCP=as.vector(as.matrix(grid.Prec$data[,,,i])), TMAX=as.vector(as.matrix(grid.Tmax$data[,,,i])), TMIN=as.vector(as.matrix(grid.Tmin$data[,,,i])), RHD=as.vector(as.matrix(grid.Humi$data[,,,i])), WSP=as.vector(as.matrix(grid.WS$data[,,,i])))
  mettmp.df$TMP <- (mettmp.df$TMAX+mettmp.df$TMIN)/2

  mettmp.df <- merge(x=mettmp.df, y=site.df, by="GRIDID")

  if ( ! isFirst )  {
   met.df <- rbind(met.df,mettmp.df)
  }
  if ( isFirst ) {
     met.df <- mettmp.df
     isFirst <- FALSE
  }
  cdate <- cdate + 1

}
print ("Meteorology data frame structure: ")
str(met.df)

met.df$GRIDID <- NULL
syear <- substr(sdate, 1, 4)
met.df   <- aggregate(.~DATE+HUC8+STCNTY, data=met.df,mean)

print("  ")
print (paste("Start year: ", syear))
met.df$YEAR  <- substr(met.df$DATE, 1, 4)
met.df$JDATE <- substr(met.df$DATE, 5, 7)
met.df$DATE <- NULL

# export HUC8 LAT, LONG, and Elevation
# rad:  Radiation (MJ m^02) - daily total
# pcp:  Daily Total Precipitation
# maxt: Daily Maximum 2m Temperature (C)
# mint: Daily Minimum 2m Temperature (C)
# rhd : Daily Average Relative Humidity
# wsp : Daily Average 10m Windspeed (m/s)
info.df    <- data.frame(NAME=met.df$HUC8,LAT=met.df$LAT,LONG=met.df$LONG, ELEVATION=met.df$ELEVATION)
metinfo.df <- unique(info.df)
metinfo.df$ID  <- seq.int(nrow(metinfo.df))

#split by state and county
met_region.df <- met.df
met_region.df$HUC8 <- NULL
met_region.df <- aggregate(.~YEAR+JDATE+STCNTY, data=met_region.df,mean)
spt_region  <- split(met_region.df, met_region.df$STCNTY)
for ( reg in names(spt_region) ) {
    tt.df <-  spt_region[[reg]]
    tt.df$STCNTY <- NULL
    out_rad  <- c(sdate, as.vector(tt.df$RAD))
    filename <- paste(outdir,"/county/rad",reg,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_pcp  <- c(sdate, as.vector(tt.df$PCP))
    filename <- paste(outdir,"/county/pcp",reg,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmp <-  c(sdate, as.vector(tt.df$TMP))
    filename <- paste(outdir,"/county/tmp",reg,".txt",sep="")
    write.table(out_tmp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmin <-  c(sdate, as.vector(tt.df$TMIN))
    filename <- paste(outdir,"/county/tmin",reg,".txt",sep="")
    write.table(out_tmin,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmax <-  c(sdate, as.vector(tt.df$TMAX))
    filename <- paste(outdir,"/county/tmax",reg,".txt",sep="")
    write.table(out_tmax,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_rhd  <- c(sdate, as.vector(tt.df$RHD))
    filename <- paste(outdir,"/county/rhd",reg,".txt",sep="")   
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_wsp  <- c(sdate, as.vector(tt.df$WSP))
    filename <- paste(outdir,"/county/wsp",reg,".txt",sep="")    
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
} 

met_region.df$ST <- substr(met_region.df$STCNTY, 1, 2)
met_region.df$STCNTY <- NULL
met_region.df <- aggregate(.~YEAR+JDATE+ST, data=met_region.df,mean)
spt_region  <- split(met_region.df, met_region.df$ST)
for ( reg in names(spt_region) ) {
    tt.df <-  spt_region[[reg]]
    tt.df$ST <- NULL
    out_rad  <- c(sdate, as.vector(tt.df$RAD))
    filename <- paste(outdir,"/state/rad",reg,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_pcp  <- c(sdate, as.vector(tt.df$PCP))
    filename <- paste(outdir,"/state/pcp",reg,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmp <-  c(sdate, as.vector(tt.df$TMP))
    filename <- paste(outdir,"/state/tmp",reg,".txt",sep="")
    write.table(out_tmp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmin <-  c(sdate, as.vector(tt.df$TMIN))
    filename <- paste(outdir,"/state/tmin",reg,".txt",sep="")
    write.table(out_tmin,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmax <-  c(sdate, as.vector(tt.df$TMAX))
    filename <- paste(outdir,"/state/tmax",reg,".txt",sep="")
    write.table(out_tmax,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_rhd  <- c(sdate, as.vector(tt.df$RHD))
    filename <- paste(outdir,"/state/rhd",reg,".txt",sep="")  
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",") 
    out_wsp  <- c(sdate, as.vector(tt.df$WSP))
    filename <- paste(outdir,"/state/wsp",reg,".txt",sep="") 
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
} 


print("Begin split into HUC8! ")
met_huc.df <- met.df
met_huc.df$STCNTY <- NULL
met_huc.df <- aggregate(.~YEAR+JDATE+HUC8, data=met_huc.df,mean)
for ( item in c("rad", "pcp", "tmp", "rhd", "wsp") ) {
    outmet.df <- data.frame(ID=metinfo.df$ID, NAME=metinfo.df$NAME,LAT=metinfo.df$LAT,LONG=metinfo.df$LONG,ELEVATION=metinfo.df$ELEVATION)
    outmet.df$NAME <- paste(item, outmet.df$NAME, sep="") 
    filename <- paste(outdir,"/",item,".txt",sep="")
    print(filename)
    write.table(outmet.df, file=filename, col.names=T,row.names=F, append=F, quote=F, sep=",")
}

print("===>output rad, pcp, tmp, rhd, wsp ")
#str(met_huc.df)
print("Split into HUC8...")
spt_huc  <- split(met_huc.df, met_huc.df$HUC8)
for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]]
    #str(tt.df)
    out_rad  <- c(sdate, as.vector(tt.df$RAD))
    filename <- paste(outdir,"/HUC8/rad",huc,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_pcp  <- c(sdate, as.vector(tt.df$PCP))
    filename <- paste(outdir,"/HUC8/pcp",huc,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmp <-  c(sdate, as.vector(tt.df$TMP))
    filename <- paste(outdir,"/HUC8/tmp",huc,".txt",sep="")
    write.table(out_tmp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmin <-  c(sdate, as.vector(tt.df$TMIN))
    filename <- paste(outdir,"/HUC8/tmin",huc,".txt",sep="")
    write.table(out_tmin,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmax <-  c(sdate, as.vector(tt.df$TMAX))
    filename <- paste(outdir,"/HUC8/tmax",huc,".txt",sep="")
    write.table(out_tmax,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_rhd  <- c(sdate, as.vector(tt.df$RHD))
    filename <- paste(outdir,"/HUC8/rhd",huc,".txt",sep="")
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_wsp  <- c(sdate, as.vector(tt.df$WSP))
    filename <- paste(outdir,"/HUC8/wsp",huc,".txt",sep="")
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
}

print("Split into HUC6...")
met_huc.df$HUC6 <- floor(met_huc.df$HUC8/100)
met_huc.df$HUC8 <- NULL
met_huc.df   <- aggregate(.~YEAR+JDATE+HUC6, data=met_huc.df,mean)
spt_huc <- split(met_huc.df, met_huc.df$HUC6)
for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]]
    #print(huc)
    out_rad  <- c(sdate, as.vector(tt.df$RAD))
    filename <- paste(outdir,"/HUC6/rad",huc,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_pcp  <- c(sdate, as.vector(tt.df$PCP))
    filename <- paste(outdir,"/HUC6/pcp",huc,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmp <-  c(sdate, as.vector(tt.df$TMP))
    filename <- paste(outdir,"/HUC6/tmp",huc,".txt",sep="")
    write.table(out_tmp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmin <-  c(sdate, as.vector(tt.df$TMIN))
    filename <- paste(outdir,"/HUC6/tmin",huc,".txt",sep="")
    write.table(out_tmin,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmax <-  c(sdate, as.vector(tt.df$TMAX))
    filename <- paste(outdir,"/HUC6/tmax",huc,".txt",sep="")
    write.table(out_tmax,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_rhd  <- c(sdate, as.vector(tt.df$RHD))
    filename <- paste(outdir,"/HUC6/rhd",huc,".txt",sep="")
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_wsp  <- c(sdate, as.vector(tt.df$WSP))
    filename <- paste(outdir,"/HUC6/wsp",huc,".txt",sep="")
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
}

print("Split into HUC2...")
met_huc.df$HUC2 <- floor(met_huc.df$HUC6/10000)
met_huc.df$HUC6 <- NULL
met_huc.df   <- aggregate(.~YEAR+JDATE+HUC2, data=met_huc.df,mean)
spt_huc <- split(met_huc.df, met_huc.df$HUC2)
for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]]
    #str(tt.df)
    out_rad  <- c(sdate, as.vector(tt.df$RAD))
    filename <- paste(outdir,"/HUC2/rad",huc,".txt",sep="")
    write.table(out_rad,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_pcp  <- c(sdate, as.vector(tt.df$PCP))
    filename <- paste(outdir,"/HUC2/pcp",huc,".txt",sep="")
    write.table(out_pcp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmp <-  c(sdate, as.vector(tt.df$TMP))
    filename <- paste(outdir,"/HUC2/tmp",huc,".txt",sep="")
    write.table(out_tmp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmin <-  c(sdate, as.vector(tt.df$TMIN))
    filename <- paste(outdir,"/HUC2/tmin",huc,".txt",sep="")
    write.table(out_tmin,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_tmax <-  c(sdate, as.vector(tt.df$TMAX))
    filename <- paste(outdir,"/HUC2/tmax",huc,".txt",sep="")
    write.table(out_tmax,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_rhd  <- c(sdate, as.vector(tt.df$RHD))
    filename <- paste(outdir,"/HUC2/rhd",huc,".txt",sep="")
    write.table(out_rhd,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
    out_wsp  <- c(sdate, as.vector(tt.df$WSP))
    filename <- paste(outdir,"/HUC2/wsp",huc,".txt",sep="")
    write.table(out_wsp,file=filename,col.names=F,row.names=F, append=F, quote=F, sep=",")
}

