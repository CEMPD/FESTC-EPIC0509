## set necessary libraries
library(fields)
library(ncdf4)
library(ncdf)
require(M3)

#for ( scen in c("3SAQS_Base11a_sensGCBC", "3SAQS_Base11a", "3SAQS_Base20a_11") ) {
for ( scen in c("3SAQS_Base20a_11") ) {
for ( domain in c("grd03")) {  #"grd02","grd03"

source("func_for_CMAQ_files_with_ncdf_rgdal.r")
INDIR <- paste("/nas01/depts/ie/cempd/3SAQS/CAMx/",scen,"/combine/output/post/",sep="")
#OUTDIR <- paste("/nas01/depts/ie/cempd/3SAQS/CAMx/",scen,"/combine/output/post/",sep="")
outname_csv <- paste("./outputs/model_",scen,"_8hrO3_",domain,".csv",sep="")

# get lat lon from met data
METFILE <- paste("GRIDCRO2D_",domain,sep="")
metf <- open.ncdf(METFILE)
met.var.name <- names(metf$var)
lonmat  = get.var.ncdf( nc=metf,varid="LON")
vlonmat <- as.vector(as.matrix(lonmat))
latmat  = get.var.ncdf( nc=metf,varid="LAT")
vlatmat <- as.vector(as.matrix(latmat))
rows <- metf$dim$ROW$len
cols <- metf$dim$COL$len
grids <- rows*cols

for ( j in 1:grids ) {
   round(vlonmat[j],6)
   round(vlatmat[j],6)
}

id  <- NULL
lat <- NULL
lon <- NULL
date <- NULL
value <- NULL
out.df <- NULL
#out.df <- data.frame(ID="ID", TYPE= "", lat = "LAT", lon= "LON", Date="DATE", O3="O3")

dummy<- rep("", times = grids )
length(dummy)
for ( i in 1:rows ) {
  for ( j in 1:cols ){
    colrow <- j * 1000 + i
    id <- c(id, colrow)    
  }
}

cat("DAY\n", file=outname_csv, append=F)
cat("_ID,_TYPE, LAT, LONG, DATE, O3\n", file=outname_csv,append=T)

ndays <- c(31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
for ( mon in c("01","02","03","04","05","06","07","08","09","10","11","12") ) {
#for ( mon in c("01") ) {
  out.df <- NULL
  INFILE <- paste("camx.v6.10.CB6r2.",scen,".25L.combine_conc.",domain,".2011",mon,".ncf.O3.8hr.dmax",sep="")
  INFILE.cmaq <- paste(INDIR, INFILE, sep="/")  # model file name
  mc <- nc_open(INFILE.cmaq)
  cmaq.var.name <- names(mc$var)      # show all the variable names
  #n.time <-  length(get.datetime.seq(INFILE.cmaq))-1  # get the time steps
       
  nmon <- as.numeric(as.character(mon))
  n.time <- ndays[nmon]
  print(cmaq.var.name)
  print(INFILE)
  print(paste("month: ", 2008, mon, n.time))

  grid.data <- get.Models3.variable(file = INFILE.cmaq,
                   ldatetime=get.datetime.seq(INFILE.cmaq)[1],
                   udatetime= get.datetime.seq(INFILE.cmaq)[n.time],
                   var=cmaq.var.name[2])

    for (i in 1:n.time ) {
    print(i)
    idate <- substr(get.datetime.seq(INFILE.cmaq)[i],0,10)
     
    if ( scen == "3SAQS_Base20a_11" ) {
      idate <- paste("2020",substr(idate,6,7),substr(idate,9,10),sep="")
    }
    else {
      idate <- paste(substr(idate,1,4),substr(idate,6,7),substr(idate,9,10),sep="")
    }

    idate <- as.numeric(idate)
    dates <- rep(idate, times=grids)
    #dates <- rep(substr(get.datetime.seq(INFILE.cmaq)[i],0,10), times=grids)
    tem.df <- data.frame(ID=id,TYPE=dummy,lat=vlatmat, lon=vlonmat, Date=dates, O3=as.vector(as.matrix(grid.data$data[,,1,i])))
    out.df <- rbind(out.df,tem.df)
    }
    write.table(out.df, file = outname_csv,col.names=F,row.names=F, append=T, sep=",")
}

# grid.data hold the data for variable var, use str(grid.data) to see the structure
 
}    # end domain
}    # end scen
