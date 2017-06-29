# Mapping Grid and HUC


#
get_dailywdeps <- function(filedir)
{
  ## Require the OUT

  ## Open netCDF file which has the projection we want to use..
   
  outfiles <- dir(paste(filedir,"/",sep=""), pattern=".csv" )
  files    <- dir(paste(filedir,"/",sep=""), pattern=".dly" )
  NO_f      <- length(outfiles)
  NI_f      <- length(files)
  print(NO_f)
  print(NI_f)
  print(filedir)
  
  #write(outfile)
  if ( length(outfiles) >0 ) {
     for ( no in 1:NO_f )  {
       outfile <- paste(paste(filedir, "/",outfiles[no],sep=""))
       print(outfile)
       if ( no == 1 )  tout.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
       if (no > 1 ) {
         tmp.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
         tout.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
         tout.df <- rbind(tout.df, tmp.df)
       }
     }
     return(tout.df)
  }

  # set up input file format
  # The -1 in the widths argument says there is a one-character column that should be ignored
  #add WOxN and DOxN for NO3 and wRdN and drdN for NH4
  dw_names  <- c("YEAR","MONTH","DAY","RAD","MAXT","MINT","PRECP","HUM","WINDS","WOXN","WRDN","DOXN","DRDN","WORN")
  dw_widths <- c(-2,4,4,4,6,6,6,6,6,6,7,7,7,7,7)
  #croptable <- read.fwf(cropfile,col.names=crop_names,width=crop_widths)

  # set up limit since there are too many met files
  limit = 2000
  tl = floor(NI_f/limit) + 1
  print(paste("total csv files: ", tl))
  for ( i in 1:tl ) {
    sl <- (i-1)*limit +1 
    el <- i*limit 
    if ( i == tl ) el <- NI_f 
    firstl  <- TRUE
    tout.df <- NULL
    outfile <- paste(filedir,"/out_",limit,"_",i,".csv",sep="")
  for(l in sl:el) {
     print(paste(l, ":", files[l]))
     gridid <- strsplit(files[l], "[.]")[[1]][1]
     #gridid <- floor(as.numeric(gridid))
     #print(gridid)

     metfile  <- paste(paste(filedir, "/",files[l],sep=""))

     mettable <- read.fwf(metfile,col.names=dw_names,width=dw_widths)
     mettable$GRIDID <- gridid 
     # catch the right line and hi value
     
     if ( firstl ) {
       #tout.df <- data.frame(GRIDID=gridid,YEAR=mettable$V1,MONTH=mettable$V2,DAY=mettable$V3,JDATE=mettable$V4,WOX=mettable$V5,WRD=mettable$V6,WOG=mettable$V7)
       tout.df <- mettable
       firstl <- FALSE
     }
     if ( !firstl ) {
       #tmp.df <- data.frame(GRIDID=gridid,YEAR=mettable$V1,JDATE=mettable$V4,WOX=mettable$V5,WRD=mettable$V6,WOG=mettable$V7)
       tout.df <- rbind(tout.df, mettable)
     }
   }
     str(tout.df)
     print(outfile)
     write.table(tout.df, file = outfile,col.names=T,row.names=F, append=F, sep=",")
   }
   print("End of process...")
   return(tout.df)
}
#
get_metdeps <- function(filedir)
{
  ## Require the OUT

  ## Open netCDF file which has the projection we want to use..
   
  outfiles <- dir(paste(filedir,"/",sep=""), pattern=".csv" )
  files    <- dir(paste(filedir,"/",sep=""), pattern=".dly" )
  NO_f      <- length(outfiles)
  NI_f      <- length(files)
  print(filedir)
  print(NI_f)
  
  #write(outfile)
  if ( length(outfiles) >0 ) {
     for ( no in 1:NO_f )  {
       outfile <- paste(paste(filedir, "/",outfiles[no],sep=""))
       print(outfile)
       if ( no == 1 )  tout.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
       if (no > 1 ) {
         tmp.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
         tout.df <- data.frame(read.csv(outfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
         tout.df <- rbind(tout.df, tmp.df)
       }
     }
     return(tout.df)
  }


  #if ( N_f == 0 )  quit()
  # set up limit since there are too many met files
  limit = 2000
  tl = floor(NI_f/limit) + 1
  print(tl)
  for ( i in 1:tl ) {
    sl <- (i-1)*limit +1 
    el <- i*limit 
    if ( i == tl ) el <- NI_f 
    firstl <- TRUE
    tout.df <- NULL
  for(l in sl:el) {
     print(l)
     outfile <- paste(filedir,"/out_",limit,"_",i,".csv",sep="")
     gridid <- strsplit(files[l], "[.]")[[1]][1]
     #gridid <- floor(as.numeric(gridid))
     #print(gridid)

     metfile  <- paste(paste(filedir, "/",files[l],sep=""))
     mettable <- data.frame(read.table(metfile,header=FALSE, sep="", skip=0, na.strings="NA"))
     #print(paste("processing",in.file.1))   
     # catch the right line and hi value
     
     if ( firstl ) {
       #tout.df <- data.frame(GRIDID=gridid,YEAR=mettable$V1,MONTH=mettable$V2,DAY=mettable$V3,JDATE=mettable$V4,WOX=mettable$V5,WRD=mettable$V6,WOG=mettable$V7)
       tout.df <- data.frame(GRIDID=gridid,YEAR=mettable$V1,JDATE=mettable$V4,WOX=mettable$V5,WRD=mettable$V6,WOG=mettable$V7)
       firstl <- FALSE
     }
     if ( !firstl ) {
       tmp.df <- data.frame(GRIDID=gridid,YEAR=mettable$V1,JDATE=mettable$V4,WOX=mettable$V5,WRD=mettable$V6,WOG=mettable$V7)
       tout.df <- rbind(tout.df, tmp.df)
     }
   }
     str(tout.df)
     print(outfile)
     write.table(tout.df, file = outfile,col.names=T,row.names=F, append=F, sep=",")
   }
   print("End of process...")
   return(tout.df)
}
