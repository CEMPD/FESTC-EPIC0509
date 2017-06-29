########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
source("./functions.r")

# get file names
sitefile <- Sys.getenv("SITEFILE")
yearfile <- Sys.getenv("YEARFILE")
metdir   <- Sys.getenv("METDIR")
outname_csv <- Sys.getenv("OUTFILE")
print(paste(">>== year file:   ", yearfile))
print(paste(">>== output file: ", outname_csv))
print(paste(">>== met dir: ", metdir))

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


#get gridid and corrpspondign huc8
out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC8=sitetable$HUC8)
str(out.df)

# GRIDID,YEAR,MONTH,DAY,JDATE,WOX,WRD,WOG
  outfiles <- dir(paste(metdir,"/",sep=""), pattern=".csv" )
  NO_f      <- length(outfiles)
  if ( NO_f == 0 ) {
     get_metdeps(metdir)
  }  

  outfiles <- dir(paste(metdir,"/",sep=""), pattern=".csv" )
  NO_f      <- length(outfiles)
  if ( NO_f > 0 ){
  for ( no in 1:NO_f )  {
    outfile <- paste(paste(metdir, "/",outfiles[no],sep=""))
    print(outfile)
    tmp.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    #tmp.df <- as.character(tmp.df$GRIDID) 

    met_year.df <- merge(x=tmp.df, y=out.df, by="GRIDID")
    str(met_year.df)
    met_year.df <- na.omit(met_year.df)
    if ( no == 1 ) dep.df <- met_year.df
    if ( no > 1 )  dep.df <- rbind(dep.df, met_year.df)
  }
  }
 

dep.df$GRIDID <- NULL
mean_dep.df   <- aggregate(.~YEAR+JDATE+HUC8, data=dep.df,mean, na.rm=TRUE)
mean_dep.df$drydep_nh4_mO <- mean_dep.df$WRD + mean_dep.df$WOG
mean_dep.df$WRD <- NULL 
mean_dep.df$WOG <- NULL 
str(mean_dep.df)

spt_huc8  <- split(mean_dep.df, mean_dep.df$HUC8)
#lapply(names(spt_huc8), function(x){spt_huc8[[x]]["HUC8"]<-NULL; x})  
print(names(spt_huc8))
for ( huc in names(spt_huc8) ) {
    str(huc)
    tt.df <-  spt_huc8[[huc]] 
    tt.df$HUC8 <- NULL
    com.df <- data.frame(MATMO=tt.df$YEAR,JDATE=tt.df$JDATE,rammo_mo=0.0,rcn_mO=0.0,drydep_nh4_mO=tt.df$drydep_nh4_mO, drydep_no3_mo=tt.df$WOX)
    filename <- paste(outname_csv, huc,".csv", sep ="")
    line="TITLE\nTITLE"
    write(line,file=filename,append=FALSE)
    write(metdir,file=filename,append=FALSE)
    line="mg/l   mg/l    kg/ha/day   kg/ha/day"
    write(line,file=filename,append=TRUE)

    title1 <- "MATMO,,RAMMO_D,RCN_D,DRYDEP_NH4_D,DRYDEP_NO3_D"
    title2 <- "1"
    write(title1,file=filename,append=TRUE)
    write(title2,file=filename,append=TRUE)
    write.table(com.df, file=filename, col.names=F,row.names=F, append=TRUE, quote=F, sep=",")
} 

