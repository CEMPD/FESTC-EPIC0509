########################################
# Calculate domain total by crops
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries (amet & yaml) and initialize data
if(! require(M3)) stop("Required package M3 could not be loaded")

# get file names
yearfile <- Sys.getenv("YEARFILE")
sitefile <- Sys.getenv("SITEFILE")
beldfile <- Sys.getenv("BELDFILE")
outname_csv <- Sys.getenv("OUTFILE")
print(paste(">>== year file:   ", yearfile))
print(paste(">>== output file: ", outname_csv))


spcname  <- Sys.getenv("SPC")

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

# read site file 
# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
indic <- sitetable$GRIDID > 0
sitetable <- sitetable[indic,]   
sitetable$FIPS <- sitetable$STFIPS*1000+sitetable$CNTYFIPS

yf <- nc_open(yearfile)
cmaq.var.names <- names(yf$var)
print(cmaq.var.names)
grid.data <- get.M3.var(file = yearfile, var=spcname)

beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

# Extract crop data from yearfile
firstlay <- TRUE
for ( i in tlays ) {
   print(i)
#  outname_grd <- paste(outname_csv, ".crop",i, sep="")
   cname <- paste("CROP", i, sep="")
   tem.df <- data.frame(GRIDID=id, CROP=as.vector(as.matrix(grid.data$data[,,i])), PERC=as.vector(as.matrix(frac.data$data[,,i])))
   tem.df <- na.omit(tem.df)
#  if ( i == 11 )  write.table(tem.df, file = outname_grd,col.names=T,row.names=F, append=F, quote=F, sep=",")
   tem.df$AREA <- tem.df$PERC*0.01*garea*0.0001

# grepl('T_', spcname)>0
   if ( ! (grepl('T_', spcname)>0) ) tem.df$CROP <- tem.df$AREA*tem.df$CROP 
   tem.df$PERC <- NULL

   # do sum for whole domain
   c <- colSums(tem.df[-1]) 
   str(c)
   crow <- c(CropNum=i, c)
   if (firstlay)  out.df <- crow 
   else           out.df <- rbind(out.df, crow)

   # transfter data to kg if not T_YLDF, unit for T_YLDF is 1000ton
   if ( ! (grepl('T_', spcname)>0) ) unit <- "(kg)"
   if ( grepl('T_', spcname)>0 )     unit <- "(1000ton)"
   cnames <- c("CropNum", paste(spcname,unit,spe=""), "AREA(ha)")
   
   names(out.df) <- cnames
   firstlay <- FALSE
}

write.table(out.df, file = outname_csv,col.names=T,row.names=F, append=F, quote=F, sep=",")

