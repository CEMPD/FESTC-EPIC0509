## set necessary libraries
library(fields)
library(ncdf)
library(rgdal)
library(maps)
library(snow)
# Code by J. Swall with various functions for manipulating CMAQ files using ncdf and rgdal libraries.
source("./func_for_CMAQ_files_with_ncdf_rgdal.r")


C.names <- c("Hay", "Hay_ir", "Alfalfa", "Alfalfa_ir", "Other_Grass", 
             "Other_Grass_ir", "Barley", "Barley_ir", "BeansEdible", 
	     "BeansEdible_ir", "CornGrain", "CornGrain_ir", "CornSilage", 
	     "CornSilage_ir", "Cotton", "Cotton_ir", "Oats", "Oats_ir", 
	     "Peanuts", "Peanuts_ir", "Potatoes", "Potatoes_ir", "Rice", 
	     "Rice_ir", "Rye", "Rye_ir", "SorghumGrain", "SorghumGrain_ir",
             "SorghumSilage", "SorghumSilage_ir", "Soybeans", "Soybeans_ir",
             "Wheat_Spring", "Wheat_Spring_ir", "Wheat_Winter", "Wheat_Winter_ir",
             "Other_Crop", "Other_Crop_ir", "Canola", "Canola_ir", "Beans", 
	     "Beans_ir")


S_func <- function(x) sum(x, na.rm = T)

# get file names
indir    <- Sys.getenv("INDIR")
outfile  <- Sys.getenv("OUTFILE")
B_dat    <- Sys.getenv("BELDFILE")
sitefile <- Sys.getenv("SITEFILE")
pat      <- Sys.getenv("PATTERN")
outname_csv <- Sys.getenv("OUTFILE")
print(paste(">>== site file:   ", sitefile))

# inputfiles 
B_dat   <- open.ncdf(paste(scendir,"/share_data/beld4_CMAQ12km_2001.nc",sep=""))

#Create daily file names
#crop fraction file
y.files   <- dir(paste(indir,"/",sep=""), pattern=pat )

mm     <- 00
mon.l1.tot <- NULL
mon.l2.tot <- NULL

#change 1:1 to 1:12 to run entire year

out.file.1 <- outfile
out.df <- NULL
for( i in 1:12 ){

   print(paste("processing month: ", i))
   if(i<10) {
      yyyymm <- paste("time20020",i,sep="")
   }else {
      yyyymm <- paste("time2002",i,sep="")
   }
   files  <- y.files[grep(yyyymm,y.files)] 
   N_f    <- length(files)

   if(i<10){
       mm <- paste("20020",i,sep="")
   }else {
       mm <- paste("2002" ,i,sep="")
   }
   #out.file.1 <- paste(outfile,"_",mm,"_HUC2.csv",sep="")


   for(l in 1:N_f) {

      #in.file.1 <- paste(paste(indir, "/",files[l],sep=""))
      # monthly fertiliztion files   
   
      E_dat     <- open.ncdf(in.file.1)
      print(paste("processing",in.file.1))   
      
# Read in Beld 4 data

#The daily files are 3 dimensional, x,y,and variable by crop
  
      F1.tmp        <- get.var.ncdf(E_dat, varid = "L1_ANH3")
      F2.tmp        <- get.var.ncdf(E_dat, varid = "L2_ANH3")
      LAT           <- get.var.ncdf(B_dat, varid = "XLAT_M")
      LONG          <- get.var.ncdf(B_dat, varid = "XLONG_M")
      F3.tmp        <- get.var.ncdf(E_dat,varid="L1_ANO3")
      F4.tmp       <- get.var.ncdf(E_dat,varid="L2_ANO3")
      F5.tmp        <- get.var.ncdf(E_dat,varid="L1_AON")
      F6.tmp        <- get.var.ncdf(E_dat,varid="L2_AON")
      F7.tmp        <- get.var.ncdf(E_dat,varid="QNO3")
      F8.tmp        <- get.var.ncdf(E_dat,varid="NFIX")
      F9.tmp        <- get.var.ncdf(E_dat,varid="PRKN")
      F10.tmp        <- get.var.ncdf(E_dat,varid="UN1")
      F11.tmp        <- get.var.ncdf(E_dat,varid="SSFN")
#      F12.tmp       <-  get.var.ncdf(E_dat,varid="HUI")

#  print (ROWN)

      F13.tmp         <- get.var.ncdf(E_dat,varid="UN1")


#These commands identify the missing data flags so all you are left with are valid obs

      V1.app         <- which(F1.tmp > 0, arr.ind = T)
      V2.app         <- which(F2.tmp > 0, arr.ind = T)
      V3.app         <- which(F3.tmp > 0, arr.ind = T)
      V4.app         <- which(F4.tmp > 0, arr.ind = T)
      V5.app         <- which(F5.tmp > 0, arr.ind = T)
      V6.app         <- which(F6.tmp > 0, arr.ind = T)
      V7.app         <- which(F7.tmp > 0, arr.ind = T)
      V8.app         <- which(F8.tmp > 0, arr.ind = T)
      V9.app         <- which(F9.tmp > 0, arr.ind = T)
      V10.app        <- which(F10.tmp > 0, arr.ind = T)
      V11.app        <- which(F11.tmp > 0, arr.ind = T)
#      V12.app        <- which(F12.tmp >0, arr.ind=T) 
      V13.app        <- which(F10.tmp > 0, arr.ind = T)


#If it is the first day of the month, set up an array populated with 0's

      if(l == 1){
         F1.app         <- array(0,dim(F1.tmp))
         F2.app         <- array(0,dim(F2.tmp))
         F3.app         <- array(0,dim(F3.tmp))
         F4.app         <- array(0,dim(F4.tmp))
         F5.app         <- array(0,dim(F5.tmp))
         F6.app         <- array(0,dim(F6.tmp))
         F7.app         <- array(0,dim(F7.tmp))
         F8.app         <- array(0,dim(F8.tmp))
         F9.app         <- array(0,dim(F9.tmp))
         F10.app        <- array(0,dim(F10.tmp))
         F11.app        <- array(0,dim(F11.tmp))
#         F12.app        <- array(0,dim(F12.tmp))
         F13.app        <- array(0,dim(F13.tmp))
         UNO  <-           array(0,dim(F13.tmp))

      }

#Variable UN1 is cummulative so create a new array that is the difference between days in month.  The 
#array I have created is identical to F10.tmp and so I need to define the .app elements in it just like
#we do for F13.tmp.  Since the daily files are closed each day and month, it would be really difficult (for
#me) to carry differences out across months so I am sacrificing uptake on the first day of each month.  There
#are very few months of the year that the area weighted value would be somewhat significant.


        if((length(V13.app)>0) & (l==1)) {
   
          UNO[V13.app]=F13.tmp[V13.app]
          F13.tmp[V13.app]=0
#          F12.tmp[V12.app]=0
        } else {
          F13.tmp[V13.app]= F10.tmp[V10.app]-UNO[V13.app]
          F13.tmp[V13.app][F13.tmp[V13.app] <= -10.0] <- 0.0
          UNO[V13.app]=F10.tmp[V10.app]
       }

#Uptake is reset to zero for a crop when it is harvested.  At that point,the difference could be negative.  To
#avoid adding in a negative number, whenever the differnece is negative, set the daily uptake to 0.  The line
#below subsets the F13.tmp array, the subsets it again by the boolean statement and performs the zero operation
#only on the members of the booleansubsetted array. 


#       F13.tmp[V13.app][F13.tmp[V13.app] < 0] <- 0.0
       
#       if(F10.tmp[V10.app]==0) {
#           F13.tmp[V13.ap]=0
#        }

#        if((length(V10.app)>0) & (F10.tmp[V10.app][F10.tmp[V10.app]==0])) { 
#              F13.tmp[V13.app]=0  
#             } 

#If the data value is valid, then sum for the month

      if(length(V1.app)>0)F1.app[V1.app]  <- F1.app[V1.app] + F1.tmp[V1.app]
      if(length(V2.app)>0)F2.app[V2.app]  <- F2.app[V2.app] + F2.tmp[V2.app]
      if(length(V3.app)>0)F3.app[V3.app]  <- F3.app[V3.app] + F3.tmp[V3.app]
      if(length(V4.app)>0)F4.app[V4.app]  <- F4.app[V4.app] + F4.tmp[V4.app]
      if(length(V5.app)>0)F5.app[V5.app]  <- F5.app[V5.app] + F5.tmp[V5.app]
      if(length(V6.app)>0)F6.app[V6.app]  <- F6.app[V6.app] + F6.tmp[V6.app]
      if(length(V7.app)>0)F7.app[V7.app]  <- F7.app[V7.app] + F7.tmp[V7.app]
      if(length(V8.app)>0)F8.app[V8.app]  <- F8.app[V8.app] + F8.tmp[V8.app]
      if(length(V9.app)>0)F9.app[V9.app]  <- F9.app[V9.app] + F9.tmp[V9.app]
      if(length(V10.app)>0)F10.app[V10.app]  <- F10.app[V10.app] + F10.tmp[V10.app]
      if(length(V11.app)>0)F11.app[V11.app]  <- F11.app[V11.app] + F11.tmp[V11.app]
#      if(length(V12.app)>0)F12.app[V12.app]  <- F12.app[V12.app] + F12.tmp[V12.app]

      if(length(V13.app)>0)F13.app[V13.app]  <- F13.app[V13.app] + F13.tmp[V13.app]

#pull in the crop fraction variable.  This also is a 2D array (x,y,CROPF)
      Cfrac         <- get.var.ncdf(B_dat, varid = "CROPF")/100
      E_dat     <- close.ncdf(E_dat)
      remove(E_dat)     
   }
  
#apply(monthly array;c(1,2,3) means apply the function over row(1),col(2),variable(3);sum is the function.  As currently written this expression computes a domain-wide sum, multiplies it by the grid cell crop fraction and then sums to a domain-wide NLCD class total.
       
# Transfer from kg/ha to kg/km**2, 0.01km**2=1ha
    gridarea = 144  #km^2
    FF1=F1.app*Cfrac*100*gridarea
    FF2=F2.app*Cfrac*100*gridarea
    FF3=F3.app*Cfrac*100*gridarea
    FF4=F4.app*Cfrac*100*gridarea
    FF5=F5.app*Cfrac*100*gridarea
    FF6=F6.app*Cfrac*100*gridarea
    FF7=F7.app*Cfrac*100*gridarea
    FF8=F8.app*Cfrac*100*gridarea
    FF9=F9.app*Cfrac*100*gridarea
    FF10=F10.app*Cfrac*100*gridarea
    FF11=F11.app*Cfrac*100*gridarea
#    FF12=F12.app*Cfrac*100
    FF13=F13.app*Cfrac*100*gridarea


    L1_NH3  <- apply(FF1,c(1,2),sum)
    L2_NH3  <- apply (FF2,c(1,2),sum)
    L1_NO3  <- apply (FF3,c(1,2),sum)
    L2_NO3  <- apply (FF4,c(1,2),sum)
    L1_ON  <- apply (FF5,c(1,2),sum)
    L2_ON  <- apply (FF6,c(1,2),sum)
    TQNO3  <- apply (FF7,c(1,2),sum)
    TNFIX  <- apply (FF8,c(1,2),sum)
    TPRKN  <- apply (FF9,c(1,2),sum)
    TUN1  <- apply (FF10,c(1,2),sum)
    TSSFN <- apply (FF11,c(1,2),sum)

    LTOT_ON=L1_ON+L2_ON
    LTOT_IN=L1_NH3+L2_NH3+L1_NO3+L2_NO3 

    TUN2 <- apply (FF13,c(1,2),sum)
#    HUI  <- apply (FF12,c(1,2),sum)

#}


#Create a matrix to hold the grid id's and then forcibly populate
   nrow=299
   ncol=459
#  grids <- nrow*ncol

   GRIDID <- as.matrix(rep(0,times=nrow*ncol),nrow=nrow, ncol=ncol)
   dim(GRIDID) <- c(ncol,nrow)

 
    for(j in 1:nrow) {
    for(k in 1:ncol) {

    GRIDID[k,j]=(((j-1)*ncol)+k)

      }
      }

#site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PRO
  sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE))
  sitetable$COUNTRY  <- NULL
  sitetable$CNTY_PRO <- NULL

  #The matrix command "unwinds" the multi-dimensional arrays.  It unwinds all rows& col1,all rows & col2, etc.
  #to create and output array that is lat,long,l1,l2

  out.array <- data.frame(GRIDID=matrix(GRIDID),ltot_on=matrix(LTOT_ON),ltot_in=matrix(LTOT_IN),tqno3=matrix(TQNO3),tnfix=matrix(TNFIX),tprkn=matrix(TPRKN),tun2=matrix(TUN2),tssfn=matrix(TSSFN))
  site.tmp <- data.frame(GRIDID=sitetable$GRIDID, HUC2=floor(sitetable$HUC8/1000000))

  out.array <- merge(out.array, site.tmp, by="GRIDID" )
  out.array$GRIDID <- NULL
  com.df <- aggregate(. ~ HUC2, data=out.array, FUN=sum)
   
  #Calculate MRB in kg/km^2
  # number of each HUC2
  # sum: MRB is made up of your HUC-2 numbers 5,6,7,8,10 and 11.
  indic  <- com.df$HUC2 %in% c(5,6,7,8,10,11)
  com.df <- com.df[indic,]
  count.df  <- aggregate(cbind(count = tnfix) ~ HUC2, data = out.array, FUN = function(x){NROW(x)})
  indic  <- count.df$HUC2 %in% c(5,6,7,8,10,11)
  count.df <- count.df[indic,]
  MRB_count <- sum(count.df$tnfix)

  com.df$HUC2 <- NULL
  com.df <- colSums(com.df)
  com.df <- com.df

  #print(paste("write output file: ", out.file.1, sep=""))
  com.df$MONTH <- i
  com.df$CELLS <- MRB_count
  str(com.df)
  tt.df <- out.df
  str(out.df)
  print(i>1)
  if ( i == 1 ) out.df <- as.data.frame(com.df)
  #if ( i > 1 )  out.df <- do.call("rbind", out.df, com.df)
  if ( i > 1 )  out.df <- rbind(out.df, as.data.frame(com.df))
  str(out.df)

  print(length(out.df$ltot_on))

}
#out.df <- colSums(out.df)
write.csv( out.df, file = out.file.1 , row.names = FALSE )
