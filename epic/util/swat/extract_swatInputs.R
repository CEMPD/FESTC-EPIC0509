########################################
# Extract SWAT inputs    
# Developed by: UNC Institute for the Environment
# created: 04/2018
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
epicbase        <- Sys.getenv("EPIC_DIR")              # base directory of EPIC
swatR           <- paste(epicbase,"/util/swat",sep="")        # R directory
source(paste(swatR,"/functions_epic2swat.r",sep=""))

# get input variables
ratiofile <- Sys.getenv("RATIO_FILE")
outdir  <- Sys.getenv("OUTDIR")
swat_outdir  <- Sys.getenv("SWAT_OUTDIR")

run_dailyEPIC <- Sys.getenv("RUN_dailyEPIC")
run_NDEP <- Sys.getenv("RUN_NDEP")
run_MET  <- Sys.getenv("RUN_MET")
NDEP_type <- Sys.getenv("NDEP_TYPE")  #CMAQ, dailyNDep_2004, dailyNDep_2008
year <- Sys.getenv("SIM_YEAR")

# repeat years for SWAT
#years <- c(2007, 2008, 2009, 2010)
#years <- c(1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012)
years <- c(year)

print(paste(">>== output directory ", outdir))

# Read swat inputs: "swatID","HUC8","RVALUES"
ratio.df <- get_ratios(ratiofile)
#str(ratio.df)

# dailyEPIC input format: $SCEN/base_2002_0509/output4SWAT/dailyEPIC/HUC8
#DATE,Floday,Sedday,Orgnday,Orgpday,No3day,Nh3day,No2day,Minpday,Cbodday,Disoxday,Chladay,Solpstday,Srbpstday,Bactpday,Bactlpday,Cmtl1day,Cmtl2day,Cmtl3day
if ( run_dailyEPIC == "YES" )
{
  print( "Running daily EPIC .... " )
  inputdir <- paste(outdir, "/dailyEPIC/HUC8/", sep="") 
  s_outdir <- paste(swat_outdir, "/EPICinputPoint/", sep="")
  has_dummy <- FALSE 
  misshuc8 <- c()
  missSwat <- c()
  for ( swatid in ratio.df$swatID ) {
    huc8 <- ratio.df[ratio.df$swatID==swatid,]$HUC8
    inputfile <- paste(inputdir, "huc8_", huc8, ".csv", sep="")
    if ( ! file.exists(inputfile)) 
    {
      print(paste("Missing huc8 in dailyEPIC: ",huc8, swatid))
      #print(paste("Create zero dummy file for: ",huc8 ))
      misshuc8 <- c(misshuc8, huc8)
      missSwat <- c(missSwat, swatid)
      next
    }
    print(paste("Processing: ",inputfile ))
    input.df <- data.frame(read.csv(inputfile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    #Apply ratio to sediment, organic nitrogen and phosphorous
    #print(inputfile)
    names(input.df) <- toupper(names(input.df)) 
    rvalue <- ratio.df[ratio.df$HUC8==huc8,]$MeanSDR
    input.df$SEDDAY  <- input.df$SEDDAY*rvalue
    input.df$ORGNDAY <- input.df$ORGNDAY*rvalue
    input.df$ORGPDAY <- input.df$ORGPDAY*rvalue

    # get DAY and YEAR 
    dy.df <- data.frame(DAY=c(1:length(input.df$DATE)), YEAR=substr(input.df$DATE, 7,10), DATE=input.df$DATE)
    input.df <- merge(dy.df, input.df, by="DATE")
    input.df$DATE <- NULL 
    col_count <- length(colnames(input.df))

    for ( i in c(3:col_count) )
    {
      input.df[[i]] <- format(as.numeric(input.df[[i]]), scientific = TRUE, digits = 3)
    }
    if ( ! has_dummy ) {
      dummy.df <- input.df
      dummy.df$FLODAY  <- 0.0
      dummy.df$SEDDAY  <- 0.0
      dummy.df$ORGNDAY <- 0.0
      dummy.df$ORGPDAY <- 0.0
      dummy.df$NO3DAY <- 0.0
      dummy.df$MINPDAY<- 0.0
      for ( i in c(3:col_count) )
      {
        dummy.df[[i]] <- format(as.numeric(dummy.df[[i]]), scientific = TRUE, digits = 3)
      }
      has_dummy <- TRUE
    }
    # Set up output format
    outfile <- paste(s_outdir,swatid,"p.dat",sep="") 
    fline <- paste("PS file for SWAT-EPIC coupling. Subbasin: ", swatid, "  (HUC8_", huc8, ")", sep="")
    # 1-6 lines, comments
    write(fline,file=outfile,append=FALSE)    
    write("   ",file=outfile,append=TRUE)    
    write("   ",file=outfile,append=TRUE)    
    write("   ",file=outfile,append=TRUE)    
    write("   ",file=outfile,append=TRUE)    
    fyear <- TRUE
    for ( year in years ) {
      isLeap <- get_isleapyear(year)
      input.df$YEAR <- year
      finput.df <- input.df
      if ( isLeap && (nrow(finput.df)<366) ) {
        lastRow <- input.df[nrow(input.df),]
        lastRow$DAY <- 366
        finput.df <- rbind(input.df,lastRow)
      }
    # 1-6 lines, comments
      if ( fyear) {
        write.table(finput.df, file=outfile, col.names=T,row.names=F, append=TRUE, quote=F, sep="\t")
        fyear <- FALSE 
      } else {
        if ( !fyear) write.table(finput.df, file=outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="\t")
      }
    }
  }
  #export huc8 without agland
  print(paste(length(misshuc8), " Missed huc8 in dailyEPIC processing." ))
  print(misshuc8)
  print(paste(length(missSwat), " Missed swatid in dailyEPIC processing: " ))
  print(missSwat)
  hindex <- 1
  for ( huc8 in misshuc8 ) {
    #print(huc8)
    swatid <- missSwat[hindex]
    outfile <- paste(s_outdir,swatid,"p.dat",sep="")
    fline <- paste("PS file for SWAT-EPIC coupling. Subbasin: ", swatid, "  (HUC8_", huc8, ")", sep="") 
    write(fline,file=outfile,append=FALSE)
    write("   ",file=outfile,append=TRUE)
    write("   ",file=outfile,append=TRUE)
    write("   ",file=outfile,append=TRUE)
    write("   ",file=outfile,append=TRUE)
    input.df <- dummy.df
    fyear <- TRUE
    for ( year in years ) {
      isLeap <- get_isleapyear(year)
      input.df$YEAR <- year
      finput.df <- input.df
      print(nrow(finput.df))
      if ( isLeap && (nrow(finput.df)<366) ) {
        lastRow <- input.df[nrow(input.df),]
        lastRow$DAY <- 366
        finput.df <- rbind(input.df,lastRow)
      }
    # 1-6 lines, comments
      if ( fyear) {
        write.table(finput.df, file=outfile, col.names=T,row.names=F, append=TRUE, quote=F, sep="\t")
        fyear <- FALSE 
      } else {
        if ( !fyear) write.table(finput.df, file=outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="\t")
      }
    }
    hindex <- hindex + 1
  } 
}

# met format
# 20110101
# 0.271583865111073
if ( run_MET == "YES" )
{
  print( "  " )
  print( "Running MET .... " )
  inputdir <- paste(outdir, "/dailyWETH/",NDEP_type,"/HUC8/", sep="")
  s_outdir <- paste(swat_outdir, "/dailyweath/", sep="")
  # hmd.hmd  pcp1.pcp  slr.slr  tmp1.tmp  wnd.wnd
  # Station hmd7140201,hmd7140202.... 
  firstline <- c("Station  ")
  latline <- c("Lati     ")
  lonline <- c("Long     ")
  elevline <- c("Elev     ")
  hmd_outfile <- paste(s_outdir, "hmd.hmd", sep="")
  pcp1_outfile <- paste(s_outdir, "pcp1.pcp", sep="")
  slr_outfile <- paste(s_outdir, "slr.slr", sep="")
  tmp1_outfile <- paste(s_outdir, "tmp1.tmp", sep="")
  wnd_outfile <- paste(s_outdir, "wnd.wnd", sep="")
  
  misshuc8 <- c()
  missSwat <- c()
  met_count <- 0
  for ( swatid in ratio.df$swatID ) {
    tline  <- ratio.df[ratio.df$swatID==swatid,]
    str(tline)
    huc8 <- tline$HUC8
    #print(huc8)
    hmd_input <- paste(inputdir, "rhd", huc8, ".txt", sep="")
    pcp1_input <- paste(inputdir, "pcp", huc8, ".txt", sep="")
    slr_input <- paste(inputdir, "rad", huc8, ".txt", sep="")
    tmp1_inputmin <- paste(inputdir, "tmin", huc8, ".txt", sep="")
    tmp1_inputmax <- paste(inputdir, "tmax", huc8, ".txt", sep="")
    wnd_input <- paste(inputdir, "wsp", huc8, ".txt", sep="")
    if ( ! file.exists(hmd_input)) 
    {
      print(paste("Missing in MET process: ",huc8, swatid ))
      misshuc8 <- c(misshuc8, huc8)
      missSwat <- c(missSwat, swatid)
      stop(paste("Input file doesn't exist:", hmd_input))
    }
    else{
      print(paste("Processing: ",hmd_input ))
      met_count = met_count + 1
    }
    if ( ! file.exists(pcp1_input)) stop(paste("Input file doesn't exist:", pcp1_input))
    if ( ! file.exists(slr_input)) stop(paste("Input file doesn't exist:", slr_input))
    if ( ! file.exists(tmp1_inputmin)) stop(paste("Input file doesn't exist:", tmp1_inputmin))
    if ( ! file.exists(tmp1_inputmax)) stop(paste("Input file doesn't exist:", tmp1_inputmax))
    if ( ! file.exists(wnd_input)) stop(paste("Input file doesn't exist:", wnd_input))
    tline  <- ratio.df[ratio.df$swatID==swatid,]
    huc8  <- tline$HUC8
    lat   <- tline$Lati
    lon   <- tline$Long
    #print(lat)
    #print(lon)
    elev  <- tline$Elev
    # hmd:f8.3; pcp:f5.1; tmp:f7.1; slr:f8.3; wnd:f8.3
    hmd_tem.df <- data.frame(read.csv(hmd_input,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    #hmd_tem.df[[1]] <-  as.numeric(hmd_tem.df[[1]])
    hmd_tem.df[,1] <- sprintf("%8.3f", hmd_tem.df[,1])
    #print(names(hmd_tem.df)[1])
    sdate <- substr(names(hmd_tem.df)[1], 2,8)
    #print(sdate)
    hmd_tem.df$JDATE <- as.numeric(sdate):(as.numeric(sdate) + length(hmd_tem.df[,1])-1) 
    #print(hmd_tem.df$JDATE)
    pcp1_tem.df <- data.frame(read.csv(pcp1_input,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    pcp1_tem.df[,1] <- sprintf("%5.1f", pcp1_tem.df[,1])
    pcp1_tem.df$JDATE <- hmd_tem.df$JDATE
    slr_tem.df <- data.frame(read.csv(slr_input,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    slr_tem.df[[1]] <- sprintf("%8.3f", slr_tem.df[[1]])
    slr_tem.df$JDATE <- hmd_tem.df$JDATE
    tmp1_tem_min.df <- data.frame(read.csv(tmp1_inputmin,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    tmp1_tem_min.df[[1]] <- sprintf("%5.1f", tmp1_tem_min.df[[1]])
    tmp1_tem_min.df$JDATE <- hmd_tem.df$JDATE
    tmp1_tem_max.df <- data.frame(read.csv(tmp1_inputmax,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    tmp1_tem_max.df[[1]] <- sprintf("%5.1f", tmp1_tem_max.df[[1]])
    tmp1_tem_max.df$JDATE <- hmd_tem.df$JDATE
    tmp1_tem.df <- merge(tmp1_tem_max.df,tmp1_tem_min.df, by="JDATE")

    wnd_tem.df <- data.frame(read.csv(wnd_input,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
    wnd_tem.df[[1]] <- sprintf("%8.3f", wnd_tem.df[[1]])
    wnd_tem.df$JDATE <- hmd_tem.df$JDATE
    if ( met_count == 1 ) 
    {
       hmd.df <- hmd_tem.df
       pcp1.df <- pcp1_tem.df
       slr.df <- slr_tem.df
       tmp1.df <- tmp1_tem.df
       wnd.df <- wnd_tem.df
    }
    else
    {
      hmd.df <- merge(hmd.df, hmd_tem.df, by="JDATE" )
      pcp1.df <- merge(pcp1.df, pcp1_tem.df, by="JDATE" )
      slr.df <- merge(slr.df, slr_tem.df,  by="JDATE" )
      tmp1.df <- merge(tmp1.df, tmp1_tem.df,  by="JDATE" )
      wnd.df <- merge(wnd.df, wnd_tem.df,  by="JDATE" )
    }
    firstline <- paste(firstline, paste("tttt", huc8, ",", sep=""), sep="")
    latline <- paste(latline, sprintf("%10.4f", as.numeric(lat)))
    lonline <- paste(lonline, sprintf("%10.4f", as.numeric(lon)))
    #print(latline)
    #print(lonline)
    elevline <- paste(elevline,sprintf("%10.0f", elev))
  }
  # write output files 
  hmd_head <- firstline
  hmd_head <- gsub("tttt", "hmd", hmd_head)
  pcp_head <- firstline
  pcp_head <- gsub("tttt", "pcp", pcp_head)
  slr_head <- firstline
  slr_head <- gsub("tttt", "slr", slr_head)
  tmp_head <- firstline
  tmp_head <- gsub("tttt", "tmp", tmp_head)
  wnd_head <- firstline
  wnd_head <- gsub("tttt", "wnd", wnd_head)

  hmd.df <- hmd.df[1:365,]
  pcp1.df <- pcp1.df[1:365,]
  slr.df <- slr.df[1:365,]
  tmp1.df <- tmp1.df[1:365,]
  wnd.df <- wnd.df[1:365,]

  #hmd.df$JDATE <- NULL
  #str(hmd.df)
  write(hmd_head,file=hmd_outfile,append=FALSE)    
  #write.table(hmd.df, file=hmd_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")

  write(pcp_head,file=pcp1_outfile,append=FALSE)    
  write(latline,file=pcp1_outfile,append=TRUE)    
  write(lonline,file=pcp1_outfile,append=TRUE)    
  write(elevline,file=pcp1_outfile,append=TRUE)    
  #write.table(pcp1.df, file=pcp1_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")

  write(slr_head,file=slr_outfile,append=FALSE)    
  #write.table(slr.df, file=slr_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")

  write(tmp_head,file=tmp1_outfile,append=FALSE)    
  write(latline,file=tmp1_outfile,append=TRUE)    
  write(lonline,file=tmp1_outfile,append=TRUE)    
  write(elevline,file=tmp1_outfile,append=TRUE)    
  #write.table(tmp1.df, file=tmp1_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")

  write(wnd_head,file=wnd_outfile,append=FALSE)    
  #write.table(wnd.df, file=wnd_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
 
  print(paste(length(misshuc8), " Missed huc8 in MET processing: " ))
  print(misshuc8)
  print(paste(length(missSwat), " Missed swatid in MET processing: " ))
  print(missSwat)

    for ( year in years ) {
      isLeap <- get_isleapyear(year)
      #if ( nrow(hmd.df)== 366 ) {
      #  sdate  <- paste(year,"001", sep="")
      #  edate  <- paste(year,"366", sep="")
      #}
      #else { 
        sdate  <- paste(year,"001", sep="")
        edate  <- paste(year,"365", sep="")
      #}
      hmd.df$JDATE <- as.numeric(sdate):as.numeric(edate)  
      pcp1.df$JDATE <- as.numeric(sdate):as.numeric(edate)  
      slr.df$JDATE <- as.numeric(sdate):as.numeric(edate)  
      tmp1.df$JDATE <- as.numeric(sdate):as.numeric(edate)  
      wnd.df$JDATE <- as.numeric(sdate):as.numeric(edate)  

      fhmd.df <- hmd.df
      fpcp1.df <- pcp1.df
      fslr.df <- slr.df
      ftmp1.df <- tmp1.df
      fwnd.df <- wnd.df
      if ( isLeap && (nrow(fhmd.df)<366) ) {
        lastRow <- hmd.df[nrow(hmd.df),]
        lastRow$JDATE <- as.numeric(paste(year,"366", sep=""))
        fhmd.df <- rbind(hmd.df,lastRow)
        lastRow <- pcp1.df[nrow(pcp1.df),]
        lastRow$JDATE <- as.numeric(paste(year,"366", sep=""))
        fpcp1.df <- rbind(pcp1.df,lastRow)
        lastRow <- slr.df[nrow(slr.df),]
        lastRow$JDATE <- as.numeric(paste(year,"366", sep=""))
        fslr.df <- rbind(slr.df,lastRow)
        lastRow <- tmp1.df[nrow(tmp1.df),]
        lastRow$JDATE <- as.numeric(paste(year,"366", sep=""))
        ftmp1.df <- rbind(tmp1.df,lastRow)
        lastRow <- wnd.df[nrow(wnd.df),]
        lastRow$JDATE <- as.numeric(paste(year,"366", sep=""))
        fwnd.df <- rbind(wnd.df,lastRow)
      }
    # 1-6 lines, comments
      write.table(fhmd.df, file=hmd_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
      write.table(fpcp1.df, file=pcp1_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
      write.table(fslr.df, file=slr_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
      write.table(ftmp1.df, file=tmp1_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
      write.table(fwnd.df, file=wnd_outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
    }
  
}

# NDEP format 
if ( run_NDEP == "YES" )
{
  print( "  " )
  print( "Running NDEP .... " )
  ndep_count = 0
  inputdir <- paste(outdir, "/NDEP/", NDEP_type, "/HUC8/", sep="")
  s_outdir <- paste(swat_outdir, "/dailydep/", sep="")
  outfile <- paste(swat_outdir, "/dailydep/atmo.day", sep="")
  #outputfile <- paste(outdir, "/swat_outputs/dailydep_",NDEP_type,"/atmo.day") 
  headline1 <- "Atmospheric deposition file (DAILY)"
  headline2 <- paste("Read from : ", NDEP_type )
  headline3 <- "TITLE"
  headline4 <- "MATMO            " 
  misshuc8 <- c()
  missSwat <- c()
  for ( swatid in ratio.df$swatID ) {
    tline  <- ratio.df[ratio.df$swatID==swatid,]
    huc8 <- tline$HUC8
    inputfile <- paste(inputdir, "ndep_HUC", huc8, ".txt", sep="")
    if ( ! file.exists(inputfile) ) 
    {
      print(paste("Missing in NDET process: ",huc8, swatid ))
      misshuc8 <- c(misshuc8, huc8)
      missSwat <- c(missSwat, swatid)
      stop(paste("Input file doesn't exist:", inputfile))
      #next
    }
    else{
      print(paste("Processing: ",inputfile ))
      ndep_count = ndep_count + 1
    }
    input.df <- data.frame(read.csv(inputfile,header=FALSE, sep=",", skip=6, na.strings="NA", strip.white=TRUE))
    input.df[is.na(input.df)] <- 0.0
   
    if ( ndep_count == 1 ) { str(input.df) }
       
    # format output file  f10.3
    input.df[, ncol(input.df)] = input.df[,ncol(input.df)]/1000
    input.df[, ncol(input.df)-1] = input.df[,ncol(input.df)-1]/1000
    input.df[, ncol(input.df)-2] = input.df[,ncol(input.df)-2]/1000
    input.df[, ncol(input.df)-3] = input.df[,ncol(input.df)-3]/1000

    input.df[, ncol(input.df)] = sprintf("%10.3f", input.df[,ncol(input.df)] )
    input.df[, ncol(input.df)-1] = sprintf("%10.3f", input.df[,ncol(input.df)-1] )
    input.df[, ncol(input.df)-2] = sprintf("%10.3f", input.df[,ncol(input.df)-2] )
    input.df[, ncol(input.df)-3] = sprintf("%10.3f", input.df[,ncol(input.df)-3] )
    headline4 <- paste(headline4, "RAMMO_D     RCN_D DRY_NH4_D DRY_NO3_D   ")
    if ( ndep_count == 1 )  
    {
      output.df <- input.df
    } 
    else
    {
      output.df <- merge(output.df, input.df, by=c("V1", "V2") )
    }
    names(output.df)[length(output.df)] <- paste("V6_", ndep_count, sep="")
    names(output.df)[length(output.df)-1] <- paste("V5_", ndep_count, sep="")
    names(output.df)[length(output.df)-2] <- paste("V4_", ndep_count, sep="")
    names(output.df)[length(output.df)-3] <- paste("V3_", ndep_count, sep="")
  }
  #output.df[, 1] = sprintf("%07d", output.df[, 1])
  output.df[, 2] <- as.numeric(output.df[, 2])
  output.df <- output.df[with(output.df,order(V2)),]
  #output.df[, 2] = sprintf("%7d", output.df[, 2])
  write(headline1,file=outfile,append=FALSE)    
  write(headline2,file=outfile,append=TRUE)    
  write(headline3,file=outfile,append=TRUE)    
  write(headline3,file=outfile,append=TRUE)    
  write(headline4,file=outfile,append=TRUE)    
  write(ndep_count, file=outfile,append=TRUE)
  output.df <- output.df[1:365,]
  #str(output.df)

  for ( year in years ) {
    isLeap <- get_isleapyear(year)
    sdate  <- paste(year,"001", sep="")
    edate  <- paste(year,"365", sep="")
    print(paste("process ", year))
    output.df$V1 <- year  
    output.df$V2 <- 1:365 
    foutput.df <- output.df
    print(nrow(output.df))
    if ( isLeap & (nrow(output.df)<366)) {
      lastRow <- output.df[nrow(output.df),]
      lastRow$V1 <- year
      lastRow$V2 <- 366
      foutput.df <- rbind(output.df,lastRow)
    }
    foutput.df[, 1] = sprintf("%7s", foutput.df[, 1])
    foutput.df[, 2] = sprintf("%7s", foutput.df[, 2])
    write.table(foutput.df, file=outfile, col.names=F,row.names=F, append=TRUE, quote=F, sep="")
  }

  print(paste(length(misshuc8), " Missed huc8 in NDEP processing: " ))
  print(misshuc8)
  print(paste(length(missSwat), " Missed swatid in NDEP processing: " ))
  print(missSwat)
}

