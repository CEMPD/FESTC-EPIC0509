################################################
# Calculate mean temperature and total deposition
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
################################################

sum_crop <- function(outcropre, outtotpre, sitetable, region)
{

npvars <- c("YLN","YLP","FNH3","FNO","FNO3","NFIX","GMN","FPO","FPL","MNP","YLDG","YLDF","IRGA","ET","PET","PRCP")
kgvars <- c("YLN","YLP","FNH3","FNO","FNO3","NFIX","GMN","FPO","FPL","MNP")
out_npvars <- c("T_YLN","T_YLP","T_FNH3","T_FNO","T_FNO3","T_NFIX","T_GMN","T_FPO","T_FPL","T_MNP","T_IRGA","T_YLDG","T_YLDF", "T_ET","T_PET","T_PRCP")
mmspc <- c("ET","PET","PRCP","IRGA","WS")
numYLDF <- c(1:6, 13,14, 29,30) # CORNS, SORGHUMS

firstc <- TRUE
for ( i in 1:21 ) {
  print(paste("crop", i))
  j1 <- (i-1)*2 +1
  j2 <- (i-1)*2 +2
  cropfile1 <- paste(outcropre,j1,"GRIDID_crop.csv", sep="_")
  cropfile2 <- paste(outcropre,j2,"GRIDID_crop.csv", sep="_")
  if (! file.exists(cropfile1)) {
   print(paste("Error: ", depfile, " doesn't exist. "))
   stop
  }
  if (! file.exists(cropfile2)) {
   print(paste("Warning: ", depfile, " doesn't exist. "))
   next
  }
  croptable1 <- data.frame(read.csv(cropfile1,header=TRUE, sep=",", skip=1, na.strings="NA", strip.white=TRUE, nrows=-1))
  croptable2 <- data.frame(read.csv(cropfile2,header=TRUE, sep=",", skip=1, na.strings="NA", strip.white=TRUE, nrows=-1))
  irrarea <- data.frame(GRIDID=croptable2$GRIDID, T_irrLand=croptable2$AREA )
  croptable1$NUE <- NULL
  croptable1$PUE <- NULL
  croptable1$NUE1 <- NULL
  croptable1$PUE1 <- NULL
  croptable2$NUE <- NULL
  croptable2$PUE <- NULL
  croptable2$NUE1 <- NULL
  croptable2$PUE1 <- NULL
  names(croptable1)[length(croptable1)] <- "T_cropLand"
  names(croptable2)[length(croptable2)] <- "T_cropLand"
 
  # sum by crops
  print(firstc)
  if (! firstc )  {
    croptablet <- croptable1
    croptablet$CROP_NUM <- j1
    croptablet$T_irrLand <- 0 
    croptable <- rbind(croptable, croptablet)
    croptablet <- croptable2
    croptablet$CROP_NUM <- j2
    croptablet$T_irrLand <- croptablet$T_cropLand
    croptable <- rbind(croptable, croptablet)
  }
  if ( firstc ) {
    croptable <- croptable1
    croptable$CROP_NUM <- j1
    croptable$T_irrLand <- 0 
    croptablet <- croptable2
    croptablet$CROP_NUM <- j2
    croptablet$T_irrLand <- croptablet$T_cropLand
    croptable <- rbind(croptable, croptablet)
    firstc <- FALSE 
  }
  
  #sum two crop tables
  newout.df <- croptable
  newout.df$CROP_NUM <- NULL
  newout.df <- aggregate(. ~ GRIDID, data=newout.df, FUN=sum) 
  newout.df <- merge(sitetable, newout.df,  by="GRIDID")
  
  print(region)
  com.df <- newout.df
  if ( region == "FIPS" ) com.df <- aggregate(. ~ FIPS, data=newout.df, FUN=sum)
  if ( region == "HUC8" ) com.df <- aggregate(. ~ HUC8, data=newout.df, FUN=sum)
  cnames <- c(region,out_npvars,"T_IRGAmgal","Nyield","Pyield","T_NWET","T_NDRY","T_irrLand","T_cropLand")
  myvars <- names(com.df) %in% cnames
  com.df <- com.df[myvars]
  str(com.df)

  com.df$T_IRGAmgal <- com.df$T_IRGA*264.172/1000000
  com.df$NUE <- ifelse(com.df$Nyield>0.0, com.df$Nyield/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
  com.df$PUE <- ifelse(com.df$Pyield>0.0, com.df$Pyield/(com.df$T_FPO+com.df$T_FPL), 0.0)

  com.df$NUE1 <- ifelse(com.df$T_YLN>0.0, com.df$T_YLN/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
  com.df$PUE1 <- ifelse(com.df$T_YLP>0.0, com.df$T_YLP/(com.df$T_FPO+com.df$T_FPL), 0.0)

  #com.df$T_PRCP <- ifelse(com.df$T_cropLand>0.0, com.df$T_PRCP/(com.df$T_cropLand*10), 0.0)
  #com.df$T_PET  <- ifelse(com.df$T_cropLand>0.0, com.df$T_PET/(com.df$T_cropLand*10), 0.0)
  #com.df$T_ET   <- ifelse(com.df$T_cropLand>0.0, com.df$T_ET/(com.df$T_cropLand*10), 0.0)
  #com.df$T_IRGA <- ifelse(com.df$T_irrLand>0.0, com.df$T_IRGA/(com.df$T_irrLand*10), 0.0)
  print(paste("write file ==>", outcropre))
  firstline <- paste(region,",ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,m3,m3,m3,m3,mgal,ton,ton,ton,ton,ha,ha" )
  cat(firstline, file = paste(outcropre,j1,j2,region,"crop.csv", sep="_"), sep="\n")
  write.table(com.df, file = paste(outcropre,j1,j2,region,"crop.csv", sep="_"), col.names=T,row.names=F, append=T, quote=F, sep=",")
  }
  
  # all region sort by crops
  cropcom.df <- croptable
  cropcom.df$GRIDID <- NULL
  cropcom.df <-  aggregate(. ~ CROP_NUM, data=cropcom.df, FUN=sum)
  str(cropcom.df)
  cropcom.df$T_IRGAmgal <- cropcom.df$T_IRGA*264.172/1000000
  cropcom.df$NUE <- ifelse(cropcom.df$Nyield>0.0, cropcom.df$Nyield/(cropcom.df$T_FNH3+cropcom.df$T_FNO+cropcom.df$T_FNO3+cropcom.df$T_NFIX+cropcom.df$T_NWET+cropcom.df$T_NDRY), 0.0 )
cropcom.df$PUE <- ifelse(cropcom.df$Pyield>0.0, cropcom.df$Pyield/(cropcom.df$T_FPO+cropcom.df$T_FPL), 0.0)
 cropcom.df$NUE1 <- ifelse(cropcom.df$T_YLN>0.0, cropcom.df$T_YLN/(cropcom.df$T_FNH3+cropcom.df$T_FNO+cropcom.df$T_FNO3+cropcom.df$T_NFIX+cropcom.df$T_NWET+cropcom.df$T_NDRY), 0.0 )
 cropcom.df$PUE1 <- ifelse(cropcom.df$T_YLP>0.0, cropcom.df$T_YLP/(cropcom.df$T_FPO+cropcom.df$T_FPL), 0.0)

  firstline <- paste("cropnum,","ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,m3,m3,m3,m3,nmgal,ton,ton,ton,ton,ha,ha" )
  cat(firstline, file = paste(outtotpre,"allcrop.csv", sep="_"), sep="\n")
  write.table(cropcom.df, file = paste(outtotpre,"allcrop.csv", sep="_"), col.names=T,row.names=F, append=T, quote=F, sep=",")

  # all crops sort by region
  print(region)
  com.df <- croptable
  com.df$CROP_NUM <- NULL
  com.df <-  aggregate(. ~ GRIDID, data=com.df, FUN=sum)
  com.df <- merge(sitetable, com.df,  by="GRIDID")
  if ( region == "FIPS" ) com.df <- aggregate(. ~ FIPS, data=com.df, FUN=sum)
  if ( region == "HUC8" ) com.df <- aggregate(. ~ HUC8, data=com.df, FUN=sum)
  cnames <- c(region,out_npvars,"T_IRGAmgal","Nyield","Pyield","T_NWET","T_NDRY","T_irrLand","T_cropLand")
  myvars <- names(com.df) %in% cnames
  com.df <- com.df[myvars]
  str(com.df)

  com.df$T_IRGAmgal <- com.df$T_IRGA*264.172/1000000
  com.df$NUE <- ifelse(com.df$Nyield>0.0, com.df$Nyield/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
  com.df$PUE <- ifelse(com.df$Pyield>0.0, com.df$Pyield/(com.df$T_FPO+com.df$T_FPL), 0.0)

  com.df$NUE1 <- ifelse(com.df$T_YLN>0.0, com.df$T_YLN/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
  com.df$PUE1 <- ifelse(com.df$T_YLP>0.0, com.df$T_YLP/(com.df$T_FPO+com.df$T_FPL), 0.0)
  firstline <- paste(region,",ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,m3,m3,m3,m3,nmgal,ton,ton,ton,ton,ha,ha" )
  outfile <- paste(outtotpre,region,"allcrop.csv", sep="_")
  cat(firstline, file = outfile, sep="\n")
  write.table(com.df, file = outfile, col.names=T,row.names=F, append=T, quote=F, sep=",")
}

sum_dep <- function(outpre)
{

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
#source("functions_dailyWETH.r")

# get file names
sitefile <- Sys.getenv("SITEFILE")
metfile  <- Sys.getenv("METFILE")
beldfile <- Sys.getenv("BELDFILE")
#outpre <- Sys.getenv("OUTFILEPRE")
#region   <- Sys.getenv("REG")

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
grid.Wet_OND <-get.M3.var(file = metfile, var="Wet_Oxidized_ND")
grid.Wet_RND  <-get.M3.var(file = metfile, var="Wet_Reduced_ND")
grid.Wet_OrND  <-get.M3.var(file = metfile, var="Wet_Organic_ND")

sitetable <- read_site(sitefile)
perc.df   <- read_beld4(beldfile, id)
perc.df[,2:12] <- perc.df[,2:12]*0.01*garea*0.0001  # m2 to ha
print("percentage file====")
str(perc.df)

out.df <- sitetable
#sdays <- c(1, 32, 60, 91,121,152,182,213,244,274,305,335)
#edays <- c(31, 59, 90,120,151,181,212,243,273,304,334,365)
#mnames<- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

  # calculate/sum total deposition
  isFirst <- TRUE
  for ( i in c(1:365) ) {
    print(i)
    temt.df <- data.frame(GRIDID=id, Dry_OND=as.vector(as.matrix(grid.Dry_OND$data[,,,i])),Dry_RND=as.vector(as.matrix(grid.Dry_RND$data[,,,i])),Wet_OND=as.vector(as.matrix(grid.Wet_OND$data[,,,i])),Wet_RND=as.vector(as.matrix(grid.Wet_RND$data[,,,i])),Wet_OrND=as.vector(as.matrix(grid.Wet_OrND$data[,,,i])))    

    #temt.df <- merge(x=temt.df, y=perc.df, by="GRIDID" )
    #temt.df$Ddep_gha <- temt.df$Dry_OND + temt.df$Dry_RND 
    #temt.df$Wdep_gha <- temt.df$Wet_OND+temt.df$Wet_RND+temt.df$Wet_OrND
    #temt.df$T_NDRY_1_6_kg <- temt.df$Ddep_gha*(temt.df$T_dryLand1_6 + temt.df$T_irrLand1_6)/1000.0   #transfer units from g to kg
    #temt.df$T_NWET_1_6_kg <- temt.df$Wdep_gha*(temt.df$T_dryLand1_6 + temt.df$T_irrLand1_6)/1000.0   #transfer units from g to kg
    #temt.df$T_NDRY_7_42_kg <- temt.df$Ddep_gha*(temt.df$T_dryLand7_42+temt.df$T_irrLand7_42)/1000.0   #transfer units from g to kg
    #temt.df$T_NWET_7_42_kg <- temt.df$Wdep_gha*(temt.df$T_dryLand7_42+temt.df$T_irrLand7_42)/1000.0   #transfer units from g to kg
    #temt.df$T_NDRY_kg <- temt.df$Ddep_gha*(temt.df$T_cropLand)/1000.0   #transfer units from g to kg
    
    if ( ! isFirst )  year.df <- rbind(year.df,temt.df)  
    if ( isFirst ) {       
       year.df <- temt.df
       isFirst <- FALSE    
    }
    year.df <- aggregate(. ~ GRIDID, data=year.df, FUN=sum)
  }

  # Calculate year accumulated deposition 
  year.df <- aggregate(. ~ GRIDID, data=year.df, FUN=sum)
  year.df <- merge(x=year.df, y=perc.df, by="GRIDID" )
  year.df$Ddep_gha <- year.df$Dry_OND + year.df$Dry_RND 
  year.df$Wdep_gha <- year.df$Wet_OND + year.df$Wet_RND + year.df$Wet_OrND
  
  year.df$T_NDRY_1_6_kg <- year.df$Ddep_gha*(year.df$T_dryLand1_6 + year.df$T_irrLand1_6)/1000.0   #transfer units from g to kg
  year.df$T_NWET_1_6_kg <- year.df$Wdep_gha*(year.df$T_dryLand1_6 + year.df$T_irrLand1_6)/1000.0   #transfer units from g to kg
  year.df$T_NDRY_7_42_kg <- year.df$Ddep_gha*(year.df$T_dryLand7_42+year.df$T_irrLand7_42)/1000.0   #transfer units from g to kg
  year.df$T_NWET_7_42_kg <- year.df$Wdep_gha*(year.df$T_dryLand7_42+year.df$T_irrLand7_42)/1000.0   #transfer units from g to kg
  year.df$T_NDRY_kg <- year.df$Ddep_gha*(year.df$T_cropLand)/1000.0   #transfer units from g to kg
  year.df$T_NWET_kg <- year.df$Wdep_gha*(year.df$T_cropLand)/1000.0   #transfer units from g to kg
  #year.df$Wet_OrND <- year.df$Wet_OrND*year.df$AREA/1000.0   #transfer units from g to kg

  #grida.df <- grid_crop_area(beldfile)
  out.df <- merge(x=out.df, y=year.df, by="GRIDID", all.x=TRUE )
  str(out.df)
  
  # Grid summary
  cnames <- c("GRIDID","Ddep_gha","Wdep_gha","T_NDRY_1_6_kg","T_NWET_1_6_kg","T_NDRY_7_42_kg","T_NWET_7_42_kg","T_NDRY_kg","T_NWET_kg")
  myvars <- names(out.df) %in% cnames
  grid.df <- out.df[myvars]

  str(grid.df)
  grid.df <- rbind(grid.df, c("Total", colSums(grid.df[,2:length(grid.df)])))
  write.table(grid.df, file = paste(outdeppre, "GRIDID_subtot.csv", sep="_"), col.names=T,row.names=F, append=F, quote=F, sep=",")

  # FIPS summary
  cnames <- c("FIPS","T_NDRY_kg","T_NWET_kg")
  myvars <- names(out.df) %in% cnames
  fips.df <- out.df[myvars]

  fips.df <- aggregate(. ~ FIPS, data=fips.df, FUN=sum)
  #if ( region == "HUC1" ) com.df <- aggregate(. ~ HUC1, data=newout.df, FUN=sum)
  #if ( region == "REG10" ) com.df <- aggregate(. ~ REG10, data=newout.df, FUN=sum)
  #if ( region == "USA" )   com.df <- aggregate(. ~ USA, data=newout.df, FUN=sum)
  #if ( region == "GRIDID" ) com.df <- newout.df
  fips.df <- rbind(fips.df, c("Total", colSums(fips.df[,2:length(fips.df)])))
   
  write.table(fips.df, file = paste(outdeppre, "FIPS_subtot.csv", sep="_"), col.names=T,row.names=F, append=F, quote=F, sep=",")

}


# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
read_site <- function(sitefile)
{
  sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
  indic <- sitetable$GRIDID > 0
  sitetable <- sitetable[indic,]
  sitetable$FIPS <- sitetable$STFIPS*1000+sitetable$CNTYFIPS
  sitetable$HUC2 <- floor(sitetable$HUC8/1000000)
  sitetable$HUC1 <- floor(sitetable$HUC8/10000000)
  return(sitetable)
} 

read_beld4 <- function(beldfile, id)
{ 
# get crop fraction
  beldf <- nc_open(beldfile)
  beld.var.names <- names(beldf$var)
  print(beld.var.names)
  frac.data <- get.M3.var(file = beldfile,var="CROPF")  # Time,crop_cat,row,col

# Sum to get crop land percentage
# T_irrLand1_6,  T_irrLand7_42 , T_dryLand1_6,  T_dryLand7_42, T_irrLand, T_dryLand T_cropLand
  print("Summarize T_dryLand1_6")
  perc.df <- data.frame(GRIDID=id, T_dryLand1_6=as.vector(as.matrix(frac.data$data[,,1])))
  for ( i in c(3,5) ) {
    perct.df <- data.frame(GRIDID=id, T_dryLand1_6=as.vector(as.matrix(frac.data$data[,,i])))
    perc.df <- rbind(perc.df, perct.df)
  }
  perc.df <- aggregate(. ~ GRIDID, data=perc.df, FUN=sum)

  print("Summarize T_irrLand1_6")
  tperc.df <- data.frame(GRIDID=id, T_irrLand1_6=as.vector(as.matrix(frac.data$data[,,2])))
  for ( i in c(4,6) ) {
    perct.df <- data.frame(GRIDID=id, T_irrLand1_6=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

  print("Summarize T_dryLand_yldf")
  tperc.df <- data.frame(GRIDID=id, T_dryLand_yldf=as.vector(as.matrix(frac.data$data[,,1])))
  for ( i in c(3,5,13,29) ) {
    perct.df <- data.frame(GRIDID=id, T_dryLand_yldf=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")


# Summarize T_irrLand_yldf
  tperc.df <- data.frame(GRIDID=id, T_irrLand_yldf=as.vector(as.matrix(frac.data$data[,,2])))
  for ( i in c(4,6,14,30) ) {
    perct.df <- data.frame(GRIDID=id, T_irrLand_yldf=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")


# Summarize T_dryLand7_42
  tperc.df <- data.frame(GRIDID=id, T_dryLand7_42=as.vector(as.matrix(frac.data$data[,,7])))
  for ( i in c(9, 11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41) ) {
    perct.df <- data.frame(GRIDID=id, T_dryLand7_42=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

# Summarize T_irrLand7_42
  tperc.df <- data.frame(GRIDID=id, T_irrLand7_42=as.vector(as.matrix(frac.data$data[,,8])))
  for ( i in c(10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42) ) {
    perct.df <- data.frame(GRIDID=id, T_irrLand7_42=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

# Summarize T_dryLand_yldg
  tperc.df <- data.frame(GRIDID=id, T_dryLand_yldg=as.vector(as.matrix(frac.data$data[,,7])))
  for ( i in c(9,11,15,17,19,21,23,25,27,31,33,35,37,39,41) ) {
    perct.df <- data.frame(GRIDID=id, T_dryLand_yldg=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

# Summarize T_irrLand_yldg
  tperc.df <- data.frame(GRIDID=id, T_irrLand_yldg=as.vector(as.matrix(frac.data$data[,,8])))
  for ( i in c(10,12,16,18,20,22,24,26,28,32,34,36,38,40,42) ) {
    perct.df <- data.frame(GRIDID=id, T_irrLand_yldg=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")


# Summarize T_dryLand
  tperc.df <- data.frame(GRIDID=id, T_dryLand=as.vector(as.matrix(frac.data$data[,,1])))
  for ( i in c(3,5,7,9, 11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41) ) {
    perct.df <- data.frame(GRIDID=id, T_dryLand=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

# Summarize T_irrLand
  tperc.df <- data.frame(GRIDID=id, T_irrLand=as.vector(as.matrix(frac.data$data[,,2])))
  for ( i in c(4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42) ) {
    perct.df <- data.frame(GRIDID=id, T_irrLand=as.vector(as.matrix(frac.data$data[,,i])))
    tperc.df <- rbind(tperc.df, perct.df)
  }
  tperc.df <- aggregate(. ~ GRIDID, data=tperc.df, FUN=sum)
  perc.df  <- merge(perc.df, tperc.df, by="GRIDID")

# Summarize T_cropLand
  perc.df$T_cropLand <- perc.df$T_dryLand + perc.df$T_irrLand

# transfer perc to area, ha
  str(perc.df)
  write.table(perc.df, file = paste(outtotpre, "totlandperc.csv", sep="_"), col.names=T,row.names=F, append=F, quote=F, sep=",")

  return(perc.df)
}

read_cropvar <- function(cropname,i, spcname,garea )
{ 
   (paste("layer:",i," spcname:",spcname, sep="") )
   aname <- paste(crops[cropnum], i, "_ha",sep="")
   tem.df <- data.frame(GRIDID=id, CROP=as.vector(as.matrix(grid.data1$data[,,i])), PERC=as.vector(as.matrix(frac.data$data[,,i])))

#  tem.df <- na.omit(tem.df)
   tem.df$AREA <- tem.df$PERC*0.01*garea*0.0001  #m**2 =ha/0.0001

   # units: T_YLD* 1000ton, YLD*: ton/ha, others: kg/ha
   if ( ! grepl('T_', spcname)>0 ) tem.df$CROP <- tem.df$AREA*tem.df$CROP

   if ( grepl('T_', spcname)>0 )
   {
     cname <- paste(crops[cropnum], i, "tton",sep="")
     print(cname)
   }
   tem.df$PERC <- NULL

   if ( (spcname == "IGRA"))
   {
     cname <- paste(crops[cropnum], i, "_mgal",sep="")
     # 1m3 = 264.172 gal, mm -> 10m3/ha
     tem.df$CROP <- tem.df$CROP*10*264.172/1000000   
   }   
   if ( (spcname == "WS"))   {
     cname <- paste(crops[cropnum], i, "_days",sep="")   
   }
   if ( (spcname == "YLDG") || (spcname == "YLDF") )   {
     cname <- paste(crops[cropnum], i, "_ton",sep="")
     yname <- paste("YIELD", i, "_tonPHA",sep="")
     cwpname <- paste("CWP", i, "_kgPM3",sep="")
     tem.df$YIELD <- 0.0
#    tem.df$CWP   <- as.vector(as.matrix(grid.data2$data[,,i])) #ET: m**3/ha     
#    tem.df$CWP   <- tem.df$AREA*tem.df$CWP*10                 # ha*(m**3/ha)     tem.df$CWP   <- ifelse (is.na(tem.df$CWP),0.0, tem.df$CWP)
     print(cname)
     # Reorder CWP to the last column
     tem.df <- tem.df [c(1,2,4,5,3)]   
   }

   out.df <- merge(x=out.df, y=tem.df, by="GRIDID", all.x=TRUE )
   out.df$CROP <- ifelse (is.na(out.df$CROP),0.0, out.df$CROP)
   out.df$AREA <- ifelse (is.na(out.df$AREA),0.0, out.df$AREA)
   cnames<- c(cnames, cname, aname)
   anames<- c(anames, aname)
   pnames<- c(pnames, cname)

}

