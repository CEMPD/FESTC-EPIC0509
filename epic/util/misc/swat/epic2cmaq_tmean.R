################################################
# Calculate mean temperature and total deposition
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
################################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
source("functions_dailyWETH.r")

# get file names
sitefile <- Sys.getenv("SITEFILE")
metfile  <- Sys.getenv("METFILE")
beldfile <- Sys.getenv("BELDFILE")
outfile <- Sys.getenv("OUTFILE")
print(paste(">>== met file:   ",  metfile))

# obtain M3 file and file information
projinfo <- get.proj.info.M3(metfile)
gridinfo <- get.grid.info.M3(metfile)
print(projinfo)
print(gridinfo)
ncols <- gridinfo$ncols
nrows <- gridinfo$nrows
ncrops <- gridinfo$nlays
grids <- nrows*ncols
id <- c(1:grids)
garea <- (gridinfo$x.cell.width)*(gridinfo$y.cell.width)

# extract data from met file
mf <- nc_open(metfile)
cmaq.var.name <- names(mf$var)
#[1] "TFLAG"           "Radiation"       "Tmax"            "Tmin"           
#[5] "Precipitation"   "R_humidity"      "Windspeed"       "Dry_Oxidized_ND"
#[9] "Dry_Reduced_ND"  "Wet_Oxidized_ND" "Wet_Reduced_ND"  "Wet_Organic_ND" 
# MJ m^02, Celsius, mm, fraction, m/s, g/ha  

grid.Radi <- get.M3.var(file = metfile, var="Radiation")
grid.Tmax <- get.M3.var(file = metfile, var="Tmax")
grid.Tmin <- get.M3.var(file = metfile, var="Tmin")
grid.Prec <- get.M3.var(file = metfile, var="Precipitation")
grid.Humi <- get.M3.var(file = metfile, var="R_humidity")
grid.WS   <- get.M3.var(file = metfile, var="Windspeed")
grid.Dry_OND <-get.M3.var(file = metfile, var="Dry_Oxidized_ND")
grid.Dry_RND  <-get.M3.var(file = metfile, var="Dry_Reduced_ND")
grid.Wet_OND <-get.M3.var(file = metfile, var="Dry_Oxidized_ND")
grid.Wet_RND  <-get.M3.var(file = metfile, var="Wet_Reduced_ND")
grid.Wet_OrND  <-get.M3.var(file = metfile, var="Wet_Organic_ND")


# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
indic <- sitetable$GRIDID > 0
sitetable <- sitetable[indic,]
sitetable$FIPS <- sitetable$STFIPS*1000+sitetable$CNTYFIPS
sitetable$HUC2 <- floor(sitetable$HUC8/1000000)
sitetable$HUC1 <- floor(sitetable$HUC8/10000000)
str(sitetable)

# get crop fraction
beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

#allcrops <- c("HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS")

# calculate all crops
#if ( "ALL" %in% crops ) crops  <- allcrops
#print( crops )

# calculate selected crops
#indexs <- which(allcrops %in% crops)
#tlays  <- c(indexs*2-1, indexs*2)
#tlays  <- sort(tlays)
#print( tlays )


perc.df <- data.frame(GRIDID=id, PERC=as.vector(as.matrix(frac.data$data[,,1])))
for ( i in 2:42 ) {
  perct.df <- data.frame(GRIDID=id, PERC=as.vector(as.matrix(frac.data$data[,,i])))
  perc.df <- rbind(perc.df, perct.df)
}
perc.df <- aggregate(. ~ GRIDID, data=perc.df, FUN=sum)
perc.df$AREA <- perc.df$PERC*0.01*garea*0.0001
perc.df$PERC <- NULL
str(perc.df)


out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC2=sitetable$HUC2)
sdays <- c(1, 32, 60, 91,121,152,182,213,244,274,305,335)
edays <- c(31, 59, 90,120,151,181,212,243,273,304,334,365)
mnames<- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

for ( mon in c(1:12) ) {

  sday <- sdays[mon]
  eday <- edays[mon]
  isFirst <- TRUE
  for ( i in c(sday:eday) ) {
    tema.df <- data.frame(GRIDID=id, Tmax=as.vector(as.matrix(grid.Tmax$data[,,,i])), Tmin=as.vector(as.matrix(grid.Tmin$data[,,,i])), Prec=as.vector(as.matrix(grid.Prec$data[,,,i])),Humi=as.vector(as.matrix(grid.Humi$data[,,,i])),WS=as.vector(as.matrix(grid.WS$data[,,,i])),Radi=as.vector(as.matrix(grid.Radi$data[,,,i])))
    if ( isFirst ) {
       mona.df <- tema.df
       isFirst <- FALSE
    }
    
    if ( ! isFirst )  mona.df <- rbind(mona.df,tema.df)
  }

  # calculate monthly averaged temperature
  mona.df$Tmean <- (mona.df$Tmax + mona.df$Tmin)/2
  mona.df$Tmax  <- NULL
  mona.df$Tmin  <- NULL
  t.df <- aggregate(. ~ GRIDID, data=mona.df, FUN=mean)
  tout.df <- merge(x=out.df, y=t.df, by="GRIDID", all.x=TRUE )
  tout.df$GRIDID <- NULL
  tt.df <- aggregate(. ~ HUC2, data=tout.df, FUN=mean)
  str(tt.df)
  
  # calculate total deposition
  isFirst <- TRUE
  for ( i in c(sday:eday) ) {  
    temt.df <- data.frame(GRIDID=id, Dry_OND=as.vector(as.matrix(grid.Dry_OND$data[,,,i])),Dry_RND=as.vector(as.matrix(grid.Dry_RND$data[,,,i])),Wet_OND=as.vector(as.matrix(grid.Wet_OND$data[,,,i])),Wet_RND=as.vector(as.matrix(grid.Wet_RND$data[,,,i])),Wet_OrND=as.vector(as.matrix(grid.Wet_OrND$data[,,,i])))    

    if ( isFirst ) {       
       mont.df <- temt.df
       isFirst <- FALSE    
    }
    if ( ! isFirst )  mont.df <- rbind(mont.df,temt.df)  
  }

  # Calculate monthly accumulated deposition 
  mont.df$Tdep <-  mont.df$Dry_OND + mont.df$Dry_RND + mont.df$Wet_OND+mont.df$Wet_RND+mont.df$Wet_OrND
  mont.df$Dry_OND  <- NULL
  mont.df$Dry_RND  <- NULL
  mont.df$Wet_OND  <- NULL
  mont.df$Wet_RND  <- NULL
  mont.df$Wet_OrND <- NULL
  d.df <- aggregate(. ~ GRIDID, data=mont.df, FUN=sum)
  dout.df <- merge(x=d.df, y=perc.df, by="GRIDID" )
  dout.df$Tdep <- dout.df$Tdep*dout.df$AREA/1000.0   #transfer units from g to kg

  #grida.df <- grid_crop_area(beldfile)
  dout.df <- merge(x=out.df, y=dout.df, by="GRIDID", all.x=TRUE )
  dout.df$GRIDID <- NULL
  dout.df$AREA   <- NULL
  dd.df <- aggregate(. ~ HUC2, data=dout.df, FUN=sum)
   
  # merge t average and dep accumulate
  dt.df <- merge(tt.df, dd.df, by="HUC2" )
  dt.df$MONTH <- mnames[mon]

  # Celsius  kg
  #dtout  <- merge(x=out.df, y=dt.df, by="GRIDID", all.x=TRUE )
  if ( mon == 1) write.table(dt.df, file = outfile, col.names=T,row.names=F, append=F, quote=F, sep=",")
  if ( mon >1  ) write.table(dt.df, file = outfile, col.names=F,row.names=F, append=T, quote=F, sep=",")
}


