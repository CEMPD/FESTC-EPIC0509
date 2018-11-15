########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")


# get file names
yearfile <- Sys.getenv("YEARFILE")
sitefile <- Sys.getenv("SITEFILE")
beldfile <- Sys.getenv("BELDFILE")
outname_csv <- Sys.getenv("OUTFILE")
print(paste(">>== year file:   ", yearfile))
print(paste(">>== output file: ", outname_csv))


spcname  <- Sys.getenv("SPC")
region   <- Sys.getenv("REG")
print(paste(">>== Sum by ", region))

# extract crops
temcrops <- Sys.getenv("CROPS")
temcrops <- toupper(temcrops)
crops    <- (strsplit(temcrops, " +"))[[1]]


allcrops <- c("HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS")

# calculate all crops 
if ( "ALL" %in% crops ) crops  <- allcrops
print( crops )

# calculate selected crops
indexs <- which(allcrops %in% crops)
tlays  <- c(indexs*2-1, indexs*2)
tlays  <- sort(tlays)
print( tlays )

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
  indic <- sitetable$GRIDID > 0
  sitetable <- sitetable[indic,]   
  sitetable$FIPS <- sitetable$STFIPS*1000+sitetable$CNTYFIPS
  sitetable$HUC2 <- floor(sitetable$HUC8/1000000)
  sitetable$HUC1 <- floor(sitetable$HUC8/10000000)
  str(sitetable)

yf <- nc_open(yearfile)
cmaq.var.name <- names(yf$var)
nvar <- length(cmaq.var.name)
if ( ! ('3N' %in% spcname ) ) {
  grid.data1 <- get.M3.var(file = yearfile, var=spcname)
#  grid.data <- as.matrix(grid.data1%data) 
}
if ( '3N' %in% spcname )  {
  grid.data1 <- get.M3.var(file = yearfile, var="FNO") 
  grid.data2 <- get.M3.var(file = yearfile, var="FNO3")
  grid.data3 <- get.M3.var(file = yearfile, var="FNH3") 
#  grid.data <- as.matrix(grid.data1$data) + as.matrix(grid.data2$data) + as.matrix(grid.data3$data)
}
beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

out.df <- sitetable
cnames <- c(region)
out.df <- sitetable

# Extract crop data from yearfile
for ( i in tlays ) {
   print(i)
   print(spcname)
   print(paste("layer:",i," spcname:",spcname, sep="") )
   cname <- paste("CROP", i, "kg",sep="")
   aname <- paste("CROP", i, "ha",sep="")
#  cname <- paste("CROP", i, "%",sep="")
   if ( ! ('3N' %in% spcname ) ) {
     tem.df <- data.frame(GRIDID=id, CROP=as.vector(as.matrix(grid.data1$data[,,i])), PERC=as.vector(as.matrix(frac.data$data[,,i])))
   }
   if ( '3N' %in% spcname )  {
     tem.df <- data.frame(GRIDID=id, CROP=as.vector(as.matrix(grid.data1$data[,,i])+as.matrix(grid.data2$data[,,i])+as.matrix(grid.data3$data[,,i])), PERC=as.vector(as.matrix(frac.data$data[,,i])))
   }
   tem.df <- na.omit(tem.df)
   tem.df$AREA <- tem.df$PERC*0.01*garea*0.0001  #m**2 =ha/0.0001

   # transfter data to kg if not T_YLDF, unit for T_YLDF is 1000ton
   #if ( ! grep('T_', spcname)>0 ) tem.df$CROP <- tem.df$AREA*tem.df$CROP
   tem.df$CROP <- tem.df$AREA*tem.df$CROP
   print("value of spcname")
   print(grepl('T_', spcname)) 
   if ( grepl('T_', spcname)>0 ) 
   {
     tem.df$CROP <- tem.df$CROP
     cname <- paste("CROP", i, "tton",sep="")
     print(cname)
   } 

   tem.df$PERC <- NULL
#  tem.df$AREA <- NULL
#  tem.df$CROP <- NULL

   out.df <- merge(x=out.df, y=tem.df, by="GRIDID", all.x=TRUE )
   out.df$CROP <- ifelse (is.na(out.df$CROP),0.0, out.df$CROP)
   out.df$AREA <- ifelse (is.na(out.df$AREA),0.0, out.df$AREA)
   cnames<- c(cnames, cname, aname)
   print(names(out.df))
   names(out.df)[length(out.df)-1] <- cname
   names(out.df)[length(out.df)]   <- aname
}

print(cnames)
print(region)

# exclude variables v1, v2, v3
myvars <- names(out.df) %in% cnames 
newout.df <- out.df[myvars]
str(newout.df)

print(region)
if ( region == "FIPS" ) com.df <- aggregate(. ~ FIPS, data=newout.df, FUN=sum)
if ( region == "STFIPS" ) com.df <- aggregate(. ~ STFIPS, data=newout.df, FUN=sum)
if ( region == "HUC8" ) com.df <- aggregate(. ~ HUC8, data=newout.df, FUN=sum)
if ( region == "HUC2" ) com.df <- aggregate(. ~ HUC2, data=newout.df, FUN=sum)
if ( region == "HUC1" ) com.df <- aggregate(. ~ HUC1, data=newout.df, FUN=sum)
if ( region == "REG10" ) com.df <- aggregate(. ~ REG10, data=newout.df, FUN=sum)
if ( region == "GRIDID" ) com.df <- newout.df
str(com.df)
#for ( i in tlays ) {
#  com.df[,i+1] <- com.df[,i+1]/com.df[,i+2]
#}

print(outname_csv)
write.table(com.df, file = outname_csv,col.names=T,row.names=F, append=F, sep=",")

