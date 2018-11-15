########################################
#  This program computes and plots cumulative plant
#  harvest date from EPIC and State USDA Weekly Crop
#  and weather report files.  It inputs both .csv
#  and .nc formatted file types.
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")

#Define the states that have crop data reports

states=c(1,4,5,6,8,12,13,17,18,19,20,21,26,27,28,29,31,35,37,38,39,40,42,45,46,47,48,51,55)

StateName=as.vector(c("Alabama","Alaska","Dummy","Arizona","Arkansas","California","Dummy","Colorado","Connecticut","Deleaware","Distric of Columbia","Florida","Georgia","Dummy","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachuesetts","Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Dummy","Rhode Island","South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Dummy","Washington","West Virginia","Wisconsin","Wyoming"))

#date1=as.vector(c(0,0,0,0,0,0,98,98,0,0,98,98,0,0,98,98,98,98,0,0,0,0,91,91,0,0,91,91,0,0,119,119,91,91,252,252))

#date2=as.vector(c(0,0,0,0,0,0,161,161,0,0,161,161,0,0,168,168,161,161,0,0,0,0,147,147,0,0,182,182,0,0,175,175,154,154,315,315))



# Read in the NASS crop progress data 

nassFile <- Sys.getenv("NASSIN")
NASS1 <- read.csv(nassFile, skip=1,as.is=TRUE,header=F)


#plot to .pdf file
pdf.out <- T

pdfFile  <- Sys.getenv("OUTFILE")
pdf.name <- pdfFile
pdf.x <- 8  #width in inches
pdf.y <- 8  #height in inches

pdf(pdf.name,height=pdf.y,width=pdf.x,onefile=T)

#Define a function to check odd and even number condition

 is.even <- function(x) x%%2==0


# get file names
yearfile <- Sys.getenv("epicFile")

sitefile <- Sys.getenv("siteFile")

beldfile <- Sys.getenv("beld4File")


spcname <- ("IPLD")

# extract crops
temcrops <- ("CORNG COTTON RICE WWHEAT SWHEAT BARLEY OATS SORGHUMG SOYBEANS")
#temcrops <- ("COTTON")
#temcrops <-("CORNG COTTON RICE WWHEAT SWHEAT BARLEY SORGHUMG SOYBEANS")
temcrops <- toupper(temcrops)
crops    <- (strsplit(temcrops, " +"))[[1]]


allcrops <- c("HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS")

#CropName <- as.vector(c("Dummy","Dummy","Dummy","Dummy","Dummy","Dummy","BARLEY","BARLEY","Dummy","Dummy","CORN","CORN","Dummy","Dummy","COTTON","COTTON","OATS","OATS","PEANUTS","PEANUTS","POTATOES","POTATOES","RICE","RICE","RYE","RYE","SORGHUM","SORGHUM","Dummy","Dummy","SOYBEANS","SOYBEANS","WHEAT, SPRING (EXCL DURUM)","WHEAT, SPRING (EXCL DURUM)","WHEAT, WINTER","WHEAT, WINTER"))

CropName <- as.vector(c("Dummy","Dummy","Dummy","Dummy","Dummy","Dummy","BARLEY","BARLEY","Dummy","Dummy","CORN","CORN","Dummy","Dummy","COTTON, UPLAND","COTTON, UPLAND","OATS","OATS","PEANUTS","PEANUTS","POTATOES","POTATOES","RICE","RICE","RYE","RYE","SORGHUM","SORGHUM","Dummy","Dummy","SOYBEANS","SOYBEANS","WHEAT, SPRING (EXCL DURUM)","WHEAT, SPRING, (EXCL DURUM)","WHEAT, WINTER","WHEAT, WINTER"))


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



# Define my dataframes
#start <- data.frame(wk=NASS1$V3,StFIPS=NASS1$V6,CROP=NASS1$V14,FRAC=NASS1$V17)
start <- data.frame(wk=NASS1$V3,StFIPS=NASS1$V7,CROP=NASS1$V17,FRAC=NASS1$V20)


# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
  sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
  indic <- sitetable$GRIDID > 0
  sitetable <- sitetable[indic,]   


#VAR-LIST = "GMN NMN NFIX  NITR AVOL DN YON QNO3 SSFN PRKN FNO FNO3 FNH3 OCPD
#            TOC TNO3 DN2 YLDG T_YLDG YLDF T_YLDF YLN YLP FTN FTP IRGA WS
#            NS IPLD  IGMD IHVD  "  # variables in epic2cmaq_year.nc



yf <- nc_open(yearfile)
cmaq.var.name <- names(yf$var)
nvar <- length(cmaq.var.name)
if (  ('IPLD' %in% spcname ) ) {
  grid.data1 <- get.M3.var(file = yearfile, var=spcname)
}



beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)

frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)


# Extract crop data from yearfile
for ( i in tlays ) {
   print(i)
   print(spcname)
   print(paste("layer:",i," spcname:",spcname, sep="") )
   if (  ('IPLD' %in% spcname ) ) {

     tem.df <- data.frame(GRIDID=id, PLANT_CROP=as.vector(as.matrix(grid.data1$data[,,i])),PERC=as.vector(as.matrix(frac.data$data[,,i])))
     
     tem.df <- na.omit(tem.df)
     tem.df$AREA <- tem.df$PERC*144*.01
  } 


# Process the NASS data by State one crop at a time for now.  Select on the crop character string

for (j in states) {

x <- start$CROP

#y <- paste(CropName[i]," - PROGRESS, PLANTED, 5 YEAR AVERAGE, MEASURED IN PCT",sep="")
#z <- paste(CropName[i]," - PROGRESS, PLANTED, MEASURED IN PCT",sep="")
y <- paste(CropName[i]," - PROGRESS, 5 YEAR AVG, MEASURED IN PCT PLANTED",sep="")
z <- paste(CropName[i]," - PROGRESS, MEASURED IN PCT PLANTED",sep="")




d<- subset(start,(x%in%y) & (start$StFIPS %in% j))
dz<- subset(start,(x%in%z) & (start$StFIPS %in% j))

#print(d, row.names=F)


#Define the number of weekly report bins from NASS

week=substr(d$wk,7,8)
weekz=substr(dz$wk,7,8)
nweek=(as.numeric(week)*7)
nweekz=(as.numeric(weekz)*7)

if (length(nweek)==0) {
  date1=0
  date2=0
     }
  else {
date1=min(nweek)
date2=max(nweek)
     }

if  (length(nweekz)==0) {
  date1z=0
  date2a=0  
   }
  else {
date1z=min(nweekz)
date2z=max(nweekz)  
    }





epicST <- subset(sitetable,(sitetable$STFIPS %in% j))

#next subset yearfile to the grids that are in the state

epicf <- subset (tem.df, (tem.df$GRIDID %in% epicST$GRIDID))

#If you do not have both NASS and EPIC data, then do not proceed and go to the end of the loops

#First check to see if there are EPIC State data
if (nrow(epicf) > 0) {

#Second, check to see if there are NASS State data
if (nrow(d) >0) {


#next compute a cummulative histogram for these data

plant<- epicf$PLANT_CROP

# This is the max/min with no finite limit


ba=200
bb=50

#Define 7-day bins relative to a week ending on day 91

breaks=seq(1,365,by=7)   #TX Plant breaks=29,156

plant.cut=cut(plant,breaks,right=F)
plant.freq=table(plant.cut)

cumfreq0=c(0,cumsum(plant.freq))

cumfreq2=(cumfreq0/nrow(epicf))*100

#set up to overly with previous plot

#dates=seq(date1[i],date2[i],by=7)
dates=seq(date1,date2,by=7)
datesz=seq(date1z,date2z,by=7)

cumfrac30=d$FRAC
zcumfrac30=dz$FRAC


ab=100
ac=356
ad=0
ae=50


#Construct a cumulative area plot

#first sort the file with areas and dates by ascending date4, then sum

fepic <- data.frame(epicf[with(epicf,order(PLANT_CROP)),])

sumarea=sum(fepic$AREA)
cumarea=cumsum((fepic$AREA/sumarea)*100)




if(is.even(i)) {


plot (fepic$PLANT_CROP,cumarea,main=c("State Irrigated",StateName[j],CropName[i],"Plant Dates"),col=("red"),pch="",xlab="Week Ending Julian Day",
ylab="Fraction of Area Plant", ylim=c(ad,ab),xlim=c(ae,ac)) 
lines(fepic$PLANT_CROP,cumarea,col=("red"),lwd=c(2,2))

points(dates,cumfrac30,pch=19)
lines(dates,cumfrac30,col=("black"))

points(datesz,zcumfrac30,pch=2)
lines(datesz,zcumfrac30,col=("green"),lwd=c(2,2))

legend("bottomright",c("EPIC","Reported 5 yr Avg","Reported yr"),col=c

("red","black","green"),lty=c(1,1),lwd=c(2,2))

} else {

plot (fepic$PLANT_CROP,cumarea,main=c("State Rainfed",StateName[j],CropName[i],"Plant Dates"),col=("red"),pch="",xlab="Week Ending Julian Day",
ylab="Fraction of Area Plant", ylim=c(ad,ab),xlim=c(ae,ac))
lines(fepic$PLANT_CROP,cumarea,col=("red"),lwd=c(2,2))


points(dates,cumfrac30,pch=19)
lines(dates,cumfrac30,col=("black"))

points(datesz,zcumfrac30,pch=2)
lines(datesz,zcumfrac30,col=("green"),lwd=c(2,2))

legend("bottomright",c("EPIC","Reported 5 yr Avg","Reported yr"),col=c
("red","black","green"),lty=c(1,1),lwd=c(2,2))
}
#End of processing if there are NASS data for the state
}

#End of processing if there are EPIC data for a state.

}

#End of processing for 1 state
}

#End of processing for crop (layer)

}

dev.off()
