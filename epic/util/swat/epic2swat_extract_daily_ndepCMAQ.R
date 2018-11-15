#####################################################
# Extract deposition data from daily weather for SWAT   
# Developed by: UNC Institute for the Environment
# Date: 04/01/2017
#####################################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
epicbase        <- Sys.getenv("EPIC_DIR")                     # base directory of EPIC
swatR           <- paste(epicbase,"/util/swat",sep="")        # R directory
source(paste(swatR,"/functions_epic2swat.r",sep=""))

# get file names
sitefile <- Sys.getenv("SITE_FILE")
beld4file <- Sys.getenv("DOMAIN_BELD4_NETCDF")
depmetfile   <- Sys.getenv("NDEP_FILE")
outdir  <- Sys.getenv("OUTDIR")

print(paste(">>== Dep weather file:   ", depmetfile))

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
print("NDEP file variables: " )
print(depmet.var.name)

#nvar <- length(nvar.var.name)
#[1] "TFLAG"           "Radiation"       "Tmax"            "Tmin"           
#[5] "Precipitation"   "R_humidity"      "Windspeed"       "Dry_Oxidized_ND"
#[9] "Dry_Reduced_ND"  "Wet_Oxidized_ND" "Wet_Reduced_ND"  "Wet_Organic_ND" 
grid.Dry_OND <-get.M3.var(file = depmetfile, var="Dry_Oxidized_ND")
grid.Dry_RND  <-get.M3.var(file = depmetfile, var="Dry_Reduced_ND")
grid.Wet_OND <-get.M3.var(file = depmetfile, var="Wet_Oxidized_ND")
grid.Wet_RND  <-get.M3.var(file = depmetfile, var="Wet_Reduced_ND")
grid.Wet_OrND  <-get.M3.var(file = depmetfile, var="Wet_Organic_ND")

sdate <- ncatt_get(yf, varid=0, attname="SDATE")$value
days  <-  yf$dim$TSTEP$len
print (paste("Start date and days: ", sdate, days))

# Read all dep files summarized to csv
isFirst <- TRUE
cdate <- sdate
for ( i in c(1:days) ) {
#for ( i in c(1:2) ) {
# "rad", "pcp", "tmp", "rhd", "wsp"
  print(i)
  deptmp.df <- data.frame(GRIDID=id, DATE=cdate, Dry_OND=as.vector(as.matrix(grid.Dry_OND$data[,,,i])),Dry_RND=as.vector(as.matrix(grid.Dry_RND$data[,,,i])),Wet_OND=as.vector(as.matrix(grid.Wet_OND$data[,,,i])),Wet_RND=as.vector(as.matrix(grid.Wet_RND$data[,,,i])),Wet_OrND=as.vector(as.matrix(grid.Wet_OrND$data[,,,i])))

  deptmp.df <- merge(x=deptmp.df, y=site.df, by="GRIDID")
  deptmp.df <- merge(x=deptmp.df, y=tperc.df, by="GRIDID")

  if ( ! isFirst )  {
   dep.df <- rbind(dep.df,deptmp.df)
  }
  if ( isFirst ) {
     dep.df <- deptmp.df
     isFirst <- FALSE
  }
  cdate <- cdate + 1

}
print ("Deposition data frame structure: ")
str(dep.df)

dep.df$GRIDID <- NULL
syear <- substr(sdate, 1, 4)

dep.df$drydep_nh4_mo <- dep.df$Dry_RND + dep.df$Wet_RND + dep.df$Wet_OND
dep.df$drydep_no3_mo <- dep.df$Wet_OrND + dep.df$Dry_OND
dep.df$Wet_RND <- NULL 
dep.df$Dry_RND <- NULL 
dep.df$Wet_OND <- NULL 
dep.df$Wet_OrND <- NULL 
dep.df$Dry_OND <- NULL 
dep.df<- dep.df[with(dep.df,order(HUC8,DATE)),]

print("  ")
print(paste("Start year: ", syear))
filename <- paste(outdir,"/ndep_",syear,"_grid.txt", sep ="")
write.table(dep.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")

dep.df$drydep_nh4_mo <- dep.df$drydep_nh4_mo*dep.df$T_cropLand
dep.df$drydep_no3_mo <- dep.df$drydep_no3_mo*dep.df$T_cropLand
dep.df   <- aggregate(.~DATE+HUC8+STCNTY, data=dep.df,sum)

# get the first day
sdate <- paste(syear,"0101", sep="")
dep.df$YEAR  <- substr(dep.df$DATE, 1, 4)
dep.df$JDATE <- substr(dep.df$DATE, 5, 7)
dep.df$DATE <- NULL

#split by state and county
dep_region.df <- dep.df
dep_region.df$HUC8 <- NULL
dep_region.df <- aggregate(.~YEAR+JDATE+STCNTY, data=dep_region.df,sum)
dep_region.df$drydep_nh4_mo <- dep_region.df$drydep_nh4_mo/dep_region.df$T_cropLand
dep_region.df$drydep_no3_mo <- dep_region.df$drydep_no3_mo/dep_region.df$T_cropLand
spt_region  <- split(dep_region.df, dep_region.df$STCNTY)
for ( reg in names(spt_region) ) {
    tt.df <-  spt_region[[reg]]
    tt.df$STCNTY <- NULL
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/county/ndep_county_",reg,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(depmetfile,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)
    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
}

dep_region.df$ST <- substr(dep_region.df$STCNTY, 1, 2)
dep_region.df$STCNTY <- NULL
dep_region.df <- aggregate(.~YEAR+JDATE+ST, data=dep_region.df,sum)
dep_region.df$drydep_nh4_mo <- dep_region.df$drydep_nh4_mo/dep_region.df$T_cropLand
dep_region.df$drydep_no3_mo <- dep_region.df$drydep_no3_mo/dep_region.df$T_cropLand
spt_region  <- split(dep_region.df, dep_region.df$ST)
for ( reg in names(spt_region) ) {
    tt.df <-  spt_region[[reg]]
    tt.df$STCNTY <- NULL
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/state/ndep_state_",reg,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(depmetfile,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)
    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
}
dep_region.df$ST <- NULL 
dep_region.df <- aggregate(.~YEAR+JDATE, data=dep_region.df,sum)
dep_region.df$drydep_nh4_mo <- dep_region.df$drydep_nh4_mo/dep_region.df$T_cropLand
dep_region.df$drydep_no3_mo <- dep_region.df$drydep_no3_mo/dep_region.df$T_cropLand
tt.df <- dep_region.df
com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
filename <- paste(outdir,"/domain/ndep_domain.txt", sep ="")
line="TITLE\nTITLE"
write(line,file=filename,append=FALSE)
write(depmetfile,file=filename,append=T)
line="mg/l   mg/l    kg/ha/day   kg/ha/day"
write(line,file=filename,append=T)
title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
title2 <- "1"
write(title1,file=filename,append=TRUE)
write(title2,file=filename,append=TRUE)
write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")

#split by HUC
print("Begin split into HUC8! ")
dep.df[is.na(dep.df)] <- 0
dep_huc.df <- dep.df
dep_huc.df$STCNTY <- NULL
dep_huc.df <- aggregate(.~YEAR+JDATE+HUC8, data=dep_huc.df,sum)
dep_huc.df$drydep_nh4_mo <- dep_huc.df$drydep_nh4_mo/dep_huc.df$T_cropLand
dep_huc.df$drydep_no3_mo <- dep_huc.df$drydep_no3_mo/dep_huc.df$T_cropLand
spt_huc  <- split(dep_huc.df, dep_huc.df$HUC8)
print(names(spt_huc))
# create and write N dep files
for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]] 
    tt.df$HUC8 <- NULL
    #str(tt.df)
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/HUC8/ndep_HUC",huc,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(depmetfile,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)

    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
} 

print("Begin split into HUC6! ")
dep_huc.df$HUC6 <- floor(dep_huc.df$HUC8/100)
dep_huc.df$HUC8 < NULL
dep_huc.df   <- aggregate(.~YEAR+JDATE+HUC6, data=dep_huc.df,sum)
dep_huc.df$drydep_nh4_mo <- dep_huc.df$drydep_nh4_mo/dep_huc.df$T_cropLand
dep_huc.df$drydep_no3_mo <- dep_huc.df$drydep_no3_mo/dep_huc.df$T_cropLand
spt_huc  <- split(dep_huc.df, dep_huc.df$HUC6)
print(names(spt_huc))
# create and write N dep files
for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]]
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/HUC6/ndep_HUC",huc,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(depmetfile,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)
    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
}

print("Begin split into HUC2! ")
dep_huc.df$HUC2 <- floor(dep_huc.df$HUC6/10000)
dep_huc.df$HUC6 < NULL
dep_huc.df   <- aggregate(.~YEAR+JDATE+HUC2, data=dep_huc.df,sum)
dep_huc.df$drydep_nh4_mo <- dep_huc.df$drydep_nh4_mo/dep_huc.df$T_cropLand
dep_huc.df$drydep_no3_mo <- dep_huc.df$drydep_no3_mo/dep_huc.df$T_cropLand
spt_huc  <- split(dep_huc.df, dep_huc.df$HUC2)
print(names(spt_huc))
# create and write N dep files
  for ( huc in names(spt_huc) ) {
    tt.df <-  spt_huc[[huc]]
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mo=0.0,drydep_nh4_mo=tt.df$drydep_nh4_mo, drydep_no3_mo=tt.df$drydep_no3_mo)
    filename <- paste(outdir,"/HUC2/ndep_HUC",huc,".txt", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(depmetfile,file=filename,append=T)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=T)

    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
}

