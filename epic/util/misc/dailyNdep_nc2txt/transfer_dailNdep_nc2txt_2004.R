#####################################################
# Extract deposition data from daily weather for SWAT   
# Developed by: UNC Institute for the Environment
# Date: 04/01/2017
#####################################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
epicbase        <- Sys.getenv("EPIC_DIR")                     # base directory of EPIC

# get file names
ndeptype  <- Sys.getenv("NDEP_TYPE")
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
gridids <- c(1:grids)  


#  output .dly file: I6, 3I4, 3F7.2 
#  2001   1   1   1    3.97  1.46   0.63
#  year month day jdate WOX  WRD     WOG
# GRIDID,YEAR,MONTH,DAY,JDATE,WOX,WRD,WOG


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

# Read all dep files, summarized to csv
isFirst <- TRUE
cdate <- sdate
for ( i in c(1:days) ) {
# "rad", "pcp", "tmp", "rhd", "wsp"
  print(i)
  print(cdate)
  #deptmp.df <- data.frame(GRIDID=gridids, DATE=cdate, Dry_OND=as.vector(as.matrix(grid.Dry_OND$data[,,,i])),Dry_RND=as.vector(as.matrix(grid.Dry_RND$data[,,,i])),Wet_OND=as.vector(as.matrix(grid.Wet_OND$data[,,,i])),Wet_RND=as.vector(as.matrix(grid.Wet_RND$data[,,,i])),Wet_OrND=as.vector(as.matrix(grid.Wet_OrND$data[,,,i])))
  deptmp.df <- data.frame(GRIDID=gridids, DATE=cdate, DOX=as.vector(as.matrix(grid.Dry_OND$data[,,,i])),DRD=as.vector(as.matrix(grid.Dry_RND$data[,,,i])),WOX=as.vector(as.matrix(grid.Wet_OND$data[,,,i])),WRD=as.vector(as.matrix(grid.Wet_RND$data[,,,i])),WOG=as.vector(as.matrix(grid.Wet_OrND$data[,,,i])))

  if ( ! isFirst )  {
   dep.df <- rbind(dep.df,deptmp.df)
  }
  if ( isFirst ) {
     dep.df <- deptmp.df
     isFirst <- FALSE
  }
  cdate <- cdate + 1
}

# if ( (i %% 40==0) || i==days ) {
    #print(i)
    #isFirst <- TRUE
    print ("Deposition data frame structure: ")
    str(dep.df)

    syear <- substr(sdate, 1, 4)
    print("  ")
    print(paste("Start year: ", syear))

  # get the first day
    dep.df$YEAR  <- substr(dep.df$DATE, 1, 4)
    dep.df$JDATE <- substr(dep.df$DATE, 5, 7)
    dep.df$DATE  <- as.Date(as.numeric(dep.df$JDATE)-1, origin=as.Date(paste(syear,"-01-01", sep="")))

    dep.df$MON <- substr(dep.df$DATE, 6, 7)
    dep.df$DAY <- substr(dep.df$DATE, 9, 10)
    print(paste("DATE: ", dep.df$JDATE[[1]])) 
#> as.Date(32, origin=as.Date("2001-01-01"))
#[1] "2001-02-02"

#Reorder columns
#Reformat columns
#split by GRIDID
    spt_id  <- split(dep.df, dep.df$GRIDID)
    for ( gridid in gridids ) {
      tt.df <-  spt_id[[gridid]]
      #tt.df <- dep.df[dep.df$GRIDID == gridid, ]
      #str(ttt.df)
      ttt.df <- data.frame(YEAR=tt.df$YEAR,month=tt.df$MON,DAY=tt.df$DAY,JDATE=tt.df$JDATE,DOX=tt.df$DOX,DRD=tt.df$DRD,WOX=tt.df$WOX,WRD=tt.df$WRD,WOG=tt.df$WOG)
      #rint(ttt.df[[1]])
      ttt.df[, 1] = sprintf("%6s", ttt.df[,1])
      ttt.df[, 2] = sprintf("%4s", ttt.df[,2])
      ttt.df[, 3] = sprintf("%4s", ttt.df[,3])
      ttt.df[, 4] = sprintf("%4s", ttt.df[,4])
      ttt.df[, 5] = sprintf("%7.2f", ttt.df[,5] )
      ttt.df[, 6] = sprintf("%7.2f", ttt.df[,6] )
      ttt.df[, 7] = sprintf("%7.2f", ttt.df[,7] )
      ttt.df[, 8] = sprintf("%7.2f", ttt.df[,8] )
      ttt.df[, 9] = sprintf("%7.2f", ttt.df[,9] )
      filename <- paste(outdir,"/",gridid,".dly", sep ="")
    
      write.table(ttt.df, file=filename, col.names=F,row.names=F,quote=F,append=F,sep="")
    }
  #}  # end sub group loop
#}

#  year month day jdate WOX  WRD     WOG
