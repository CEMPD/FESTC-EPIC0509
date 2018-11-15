################################################
# Calculate mean temperature and total deposition
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
################################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
source("functions_misc.R")

# get file names
sitefile <- Sys.getenv("SITEFILE")
metfile  <- Sys.getenv("METFILE")
beldfile <- Sys.getenv("BELDFILE")
yearfile <- Sys.getenv("YEARFILE")
np_file <- Sys.getenv("NPCONTENTS")
outdeppre <- Sys.getenv("OUTDEPPRE")
outtotpre <- Sys.getenv("OUTTOTPRE")
outcropre <- Sys.getenv("OUTCROPRE")
region   <- Sys.getenv("REG")
rundep   <- Sys.getenv("RUN_DEP")
runtot   <- Sys.getenv("RUN_TOT")
runcrop  <- Sys.getenv("RUN_CROP")
#runtot   <- Sys.getenv("RUN_TOT")

# Read N_P contents file
print(paste(">>== np file: ", np_file))
nptable <- data.frame(read.csv(np_file,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))

# run annual dep sum
if ( rundep == "YES" ) {
  sum_dep(outdeppre)
}

# get depfile
depfile <- paste(outdeppre, "GRIDID_subtot.csv", sep="_")
if ( file.exists(depfile)) {
  print(paste(">>== dep file: ", depfile))
}
if (! file.exists(depfile)) {
  print(paste("Error: ", depfile, " doesn't exist. "))
  stop
}

# Read deposition file
deptable <- data.frame(read.csv(depfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))

# obtain projection information: ncols, nrows
print(paste(">>== met file:   ",  metfile))
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

# Obtain site info: region, HUC8, fips
sitetable <- read_site(sitefile)
str(sitetable)

# get crop fraction from beld4 file, variable "CROPF"
beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

#percfile = paste(outtotpre, "totlandperc.csv", sep="_")
#if (! file.exists(percfile)) {
#  croparea.df <- read_beld4(beldfile)
#}
#if ( file.exists(percfile)) {
#  croparea.df <- data.frame(read.csv(percfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
#}
#croparea.df[,2:12] <- croparea.df[,2:12]*0.01*garea*0.0001

yf <- nc_open(yearfile)
print(names(yf$var) )

# NUE = T_YLN/(T_FNH3 + T_FNO + T_FNO3 + T_NFIX + T_NWET + T_NDRY)  
# PUE = T_YLP/(T_FPO + TFPL + T_MNP)
# T_IRGA(mm), T_IRGA(Mgal), 
# T_PRCP (mm), T_PET(mm), T_ET(mm)
#IRGA (Mgal): you need to convert mm based on irrigated crop areas (2, 4, 6… even number crops) to Mgal
#pvars <- c("T_dryLand1_6","T_irrLand1_6","T_dryLand7_42","T_irrLand7_42","T_dryLand","T_irrLand","T_cropLand" )

#units: T_YLD* 1000ton, YLD*: ton/ha, IRGA: mm->10m3/ha, others: kg/ha
npvars <- c("YLN","YLP","FNH3","FNO","FNO3","NFIX","GMN","FPO","FPL","MNP","YLDG","YLDF","IRGA","ET","PET","PRCP")
kgvars <- c("YLN","YLP","FNH3","FNO","FNO3","NFIX","GMN","FPO","FPL","MNP")
out_npvars <- c("T_YLN","T_YLP","T_FNH3","T_FNO","T_FNO3","T_NFIX","T_GMN","T_FPO","T_FPL","T_MNP","T_IRGA","T_YLDG","T_YLDF", "T_ET","T_PET","T_PRCP")
mmspc <- c("ET","PET","PRCP","IRGA","WS")
numYLDF <- c(1:6, 13,14, 29,30) # CORNS, SORGHUMS
 
#"T_NWET","T_NDRY"
#out.df <- data.frame(GRIDID=sitetable$GRIDID, FIPS=sitetable$FIPS)
#grid.datag <- get.M3.var(file = yearfile, var="YLDG")
#grid.dataf <- get.M3.var(file = yearfile, var="YLDF")

if ( runtot == "YES" ) {

firstcrop <- TRUE
for ( i in 1:42 ) {
  print(paste("crop", i))
  firstvar <- TRUE
  for ( va in npvars ) {
    print(va)
    grid.data <- get.M3.var(file = yearfile, var=va)  # kg/ha
    tem.df <- data.frame(GRIDID=id, VAR=as.vector(as.matrix(grid.data$data[,,i])), AREA=as.vector(as.matrix(frac.data$data[,,i])))
    tem.df$AREA <- tem.df$AREA*0.01*garea*0.0001
    tem.df$AREA <- ifelse (is.na(tem.df$VAR),0.0, tem.df$AREA)
    tem.df$VAR  <- ifelse (is.na(tem.df$VAR),0.0, tem.df$VAR)
    tem.df$VAR <-  tem.df$VAR*tem.df$AREA

    # m3 = 264.172 gal, mm -> 10m3/ha, to mgal
    if ( va %in% mmspc ) {
       tem.df$VAR <- tem.df$VAR*10     # m3
    }
    if ( va %in% kgvars ) {
       tem.df$VAR <- tem.df$VAR/1000   # kg to ton
    }
    if (! firstvar ) {
      tem.df$AREA <- NULL
      out.df <- merge(out.df, tem.df,  by="GRIDID", all.x=TRUE )
    }
    if ( firstvar ){ 
      out.df <- tem.df
      out.df$AREA <- NULL
      firstvar <- FALSE 
      # get area data frame
      area.df <- tem.df 
      area.df$VAR <- NULL
    }
    #str(out.df)
    names(out.df)[length(out.df)] <- paste("T_",va,sep="")
#   out.df[[length(out.df)]] <- ifelse(is.na(out.df[[length(out.df)]]), 0.0, out.df[[length(out.df)]])
  }

  dep.df <- data.frame(GRIDID=deptable$GRIDID,T_NWET=deptable$Wdep_gha, T_NDRY=deptable$Ddep_gha) 
  dep.df$T_NDEP <- dep.df$T_NWET + dep.df$T_NDRY
  #area.df <- data.frame(GRIDID=id,AREA=as.vector(as.matrix(frac.data$data[,,i])))
  #area.df$AREA <- area.df$AREA*0.01*garea*0.0001

  dep.df  <- merge(dep.df, area.df, by="GRIDID", all.x=TRUE)
  dep.df$T_NWET <- ifelse (is.na(dep.df$T_NWET),0.0, dep.df$T_NWET)
  dep.df$T_NDRY <- ifelse (is.na(dep.df$T_NDRY),0.0, dep.df$T_NDRY)
  dep.df$AREA <- ifelse (is.na(dep.df$AREA), 0.0, dep.df$AREA)
  
  dep.df$T_NWET <- dep.df$T_NWET*dep.df$AREA/1000000    #ton
  dep.df$T_NDRY <- dep.df$T_NDRY*dep.df$AREA/1000000    #ton
  dep.df$T_NDEP <- dep.df$T_NDEP*dep.df$AREA/1000000    #ton
  str(dep.df)

  out.df$T_IRGAmgal <- out.df$T_IRGA*264.172/1000000    # mgal
  if ( i %in% numYLDF ){
    out.df$Nyield <- nptable$CNY[i]*out.df$T_YLDF  
    out.df$Pyield <- nptable$CPY[i]*out.df$T_YLDF  
  }
  else {
    out.df$Nyield <- nptable$CNY[i]*out.df$T_YLDG  # ton 
    out.df$Pyield <- nptable$CPY[i]*out.df$T_YLDG  # ton 
  }

  # print tables for each crop
  newout.df <- merge(out.df, dep.df, by="GRIDID", all.x=TRUE )
  newout.df$T_NWET <- ifelse (is.na(newout.df$T_NWET),0.0, newout.df$T_NWET)
  newout.df$T_NDRY <- ifelse (is.na(newout.df$T_NDRY),0.0, newout.df$T_NDRY)
  newout.df$T_NDEP <- ifelse (is.na(newout.df$T_NDEP),0.0, newout.df$T_NDEP)
  newout.df$AREA   <- ifelse (is.na(newout.df$AREA),0.0, newout.df$AREA)

  newout.df$NUE <- ifelse(newout.df$Nyield>0.0, newout.df$Nyield/(newout.df$T_FNH3+newout.df$T_FNO+newout.df$T_FNO3+newout.df$T_NFIX+newout.df$T_NWET+newout.df$T_NDRY), 0.0 )
  newout.df$PUE <- ifelse(newout.df$Pyield>0.0, newout.df$Pyield/(newout.df$T_FPO+newout.df$T_FPL), 0.0)
  newout.df$NUE1 <- ifelse(newout.df$T_YLN>0.0, newout.df$T_YLN/(newout.df$T_FNH3+newout.df$T_FNO+newout.df$T_FNO3+newout.df$T_NFIX+newout.df$T_NWET+newout.df$T_NDRY), 0.0 )
 newout.df$PUE1 <- ifelse(newout.df$T_YLP>0.0, newout.df$T_YLP/(newout.df$T_FPO+newout.df$T_FPL), 0.0)

  firstline <- "gridid,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,m3,m3,m3,m3,ton,ton,ton,ton,ton,ha"
  cat(firstline, file = paste(outcropre, i, "GRIDID_crop.csv", sep="_"), sep="\n")
  write.table(newout.df, file = paste(outcropre,i,"GRIDID_crop.csv", sep="_"), col.names=T,row.names=F, append=T, quote=F, sep=",")

  if ( region == "FIPS" ) {
    newout.df <- merge(sitetable, newout.df,  by="GRIDID")
    cnames <- c(region,out_npvars,"Nyield","Pyield","T_NWET","T_NDRY","AREA")
    myvars <- names(newout.df) %in% cnames
    newout.df <- newout.df[myvars]
    #str(newout.df)
    newout.df <- aggregate(. ~ FIPS, data=newout.df, FUN=sum)
    newout.df$NUE <- ifelse(newout.df$Nyield>0.0, newout.df$Nyield/(newout.df$T_FNH3+newout.df$T_FNO+newout.df$T_FNO3+newout.df$T_NFIX+newout.df$T_NWET+newout.df$T_NDRY), 0.0 )
    newout.df$PUE <- ifelse(newout.df$Pyield>0.0, newout.df$Pyield/(newout.df$T_FPO+newout.df$T_FPL), 0.0)

    newout.df$NUE1 <- ifelse(newout.df$T_YLN>0.0, newout.df$T_YLN/(newout.df$T_FNH3+newout.df$T_FNO+newout.df$T_FNO3+newout.df$T_NFIX+newout.df$T_NWET+newout.df$T_NDRY), 0.0 )
 newout.df$PUE1 <- ifelse(newout.df$T_YLP>0.0, newout.df$T_YLP/(newout.df$T_FPO+newout.df$T_FPL), 0.0)

    firstline <- "gridid,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,m3,m3,m3,m3,mgal,ton,ton,ton,ton,ton,ha"
    cat(firstline, file = paste(outcropre, i, "FIPS_crop.csv", sep="_"), sep="\n")
    write.table(newout.df, file = paste(outcropre,i,"FIPS_crop.csv", sep="_"), col.names=T,row.names=F, append=T, quote=F, sep=",")
  }
  
  # sum tables by YLDG and YLDF
  # print(firstcrop)
  if ( ! firstcrop ) comcrop.df <- rbind(comcrop.df,out.df)
  if ( firstcrop ) {
    comcrop.df <- out.df
    firstcrop <- FALSE
  }
} 
}
#comcrop.df <- aggregate(. ~ GRIDID, data=comcrop.df, FUN=sum)
#yldgcom.df <- aggregate(. ~ GRIDID, data=yldgcom.df, FUN=sum)
#dep.df <- data.frame(GRIDID=deptable$GRIDID, T_NWET= deptable$T_NWET_kg/1000, T_NDRY= deptable$T_NDRY_kg/1000)
#dep.df$T_NDEP <- dep.df$T_NWET + dep.df$T_NDRY 
#com.df <- merge(comcrop.df, dep.df, by="GRIDID", all.x=TRUE )
#com.df <- merge(sitetable, com.df,  by="GRIDID")
#com.df <- merge(com.df, croparea.df,  by="GRIDID")
#cnames <- c(region,out_npvars,"T_IRGAmgal","Nyield","Pyield","T_NWET","T_NDRY","T_NDEP","T_irrLand","T_cropLand")
#myvars <- names(com.df) %in% cnames
#com.df <- com.df[myvars]
#str(com.df)
#
#print(region)
#if ( region == "FIPS" ) com.df <- aggregate(. ~ FIPS, data=com.df, FUN=sum)
#if ( region == "HUC8" ) com.df <- aggregate(. ~ HUC8, data=com.df, FUN=sum)
#com.df <- rbind(com.df, c("Total", colSums(com.df[,2:length(com.df)])))
#units
#com.df$T_PRCP <- ifelse(com.df$T_cropLand>0.0, com.df$T_PRCP/(com.df$T_cropLand*10), 0.0)
#com.df$T_PET  <- ifelse(com.df$T_cropLand>0.0, com.df$T_PET/(com.df$T_cropLand*10), 0.0)
#com.df$T_ET   <- ifelse(com.df$T_cropLand>0.0, com.df$T_ET/(com.df$T_cropLand*10), 0.0)
#com.df$T_IRGA <- ifelse(com.df$T_irrLand>0.0, com.df$T_IRGA/(com.df$T_irrLand*10), 0.0)
#
#com.df$NUE <- ifelse(com.df$Nyield>0.0, com.df$Nyield/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
#com.df$PUE <- ifelse(com.df$Pyield>0.0, com.df$Pyield/(com.df$T_FPO+com.df$T_FPL), 0.0)
#com.df$NUE1 <- ifelse(com.df$T_YLN>0.0, com.df$T_YLN/(com.df$T_FNH3+com.df$T_FNO+com.df$T_FNO3+com.df$T_NFIX+com.df$T_NWET+com.df$T_NDRY), 0.0 )
#com.df$PUE1 <- ifelse(com.df$T_YLP>0.0, com.df$T_YLP/(com.df$T_FPO+com.df$T_FPL), 0.0)
#
#str(com.df)
#firstline <- "fips,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,ton,mm,mm,mm,mm,mgal,ton,ton,ton,ton,ton,ha,ha"
#cat(firstline, file = paste(outtotpre, region, "year.csv", sep="_"), sep="\n")
#write.table(com.df, file = paste(outtotpre, region, "year.csv", sep="_"), col.names=T,row.names=F, append=T, quote=F, sep=",")
#}
if ( runcrop == "YES" ) {
  sum_crop(outcropre,outtotpre,sitetable, region)
}
