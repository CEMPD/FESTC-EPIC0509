      Program Beld_NC2IOAPI
      
      USE M3UTILIO
      
      Implicit None
      
      include 'netcdf.inc'
      
! netCDF id's
      INTEGER        :: FID, VARID, DIMID, ATTID
      INTEGER        :: NBL, STATUS     
! netCDF diminsions      
      Integer  :: n_crops, n_trees, n_lu, n_x, n_y
! loop integers 
      Integer :: i ,j
      Real, Save, Allocatable :: Beld_ag   ( :,:,: )
      Real, Save, Allocatable :: Beld_Tree ( :,:,: )
      Real, Save, Allocatable :: Beld_Lu ( :,:,: )
      Real,Allocatable  ::  xmin(:),ymin(:),dx(:),dy(:)
      Real,Allocatable  ::  xcent(:),ycent(:)
!     Character( 50 ) :: max_b, xmin,ymin,dx,dy
!     Integer :: xmin,ymin,dx,dy
      Character( 50 ), Allocatable :: CropNames( : )
      Character( 50 ), Allocatable :: TreeNames( : )             
      Character( 50 ), Allocatable :: LuNames( : ) 
      Character( 50 ), Allocatable :: LuDesc( : )     
      
! Input/Output file names
      CHARACTER( 200 )            :: infileName
      CHARACTER( 20 )            ::  gridname
! Models-3 IO/API varialbes
      CHARACTER( 96 )            :: XMSG    = ' '   
      CHARACTER( 16 ), PARAMETER :: pname = 'BELD_NC2IOAPI'
      INTEGER, SAVE  :: LOGDEV    
      Integer :: n_start, n_end

      Write(*,*) 'Starting converion of BELD from NC to IO/API'
! Open NetCDF file and get variables used by all LUs
      CALL GETENV( "INFILE", infileName )  
      CALL GETENV( "GRID_NAME", gridname )  

      Write(*,*) 'Input file: ', infileName
      Write(*,*) 'Grid Name: ', gridname
      Status = NF_OPEN(infileName, NF_NOWRITE, FID)
      Write(*,*) 'After NF_OPEN'
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error opening NetCDF file'
	 call exit()
      End If
      
      Status = NF_INQ_DIMID(FID, 'west_east', DIMID) 
      Write(*,*) 'After NF_INQ_DIMID west_east', DIMID
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting west_east DIMID'
	 call exit()
      End If
      Status = NF_INQ_DIMLEN(FID, DIMID, n_x) 
      Write(*,*) 'After NF_INQ_DIMLEN n_x',n_x
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting west_east DIM'
	 call exit()
      End If      
      
      Status = NF_INQ_DIMID(FID, 'south_north', DIMID) 
      Write(*,*) 'After NF_INQ_DIMID south_north', DIMID
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting south_north DIMID'
	 call exit()
      End If
      Status = NF_INQ_DIMLEN(FID, DIMID, n_y) 
      Write(*,*) 'After NF_INQ_DIMLEN n_y', n_y
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting south_north DIM'
	 call exit()
      End If     
!      Write(*,*) 'Number of rows: ', n_y     

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'XMIN', j)
      IF ( .NOT. ALLOCATED ( xmin ) ) THEN
            ALLOCATE ( xmin ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'XMIN', xmin)
      Write(*,*) 'Domain xmin: ',xmin

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'YMIN', j)
      IF ( .NOT. ALLOCATED ( ymin ) ) THEN
            ALLOCATE ( ymin ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'YMIN', ymin)
      Write(*,*) 'Domain ymin: ',ymin

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'DX', j)
      IF ( .NOT. ALLOCATED ( dx ) ) THEN
            ALLOCATE ( dx ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'DX', dx)
      Write(*,*) 'Domain dx: ',dx

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'DY', j)
      IF ( .NOT. ALLOCATED ( dy ) ) THEN
            ALLOCATE ( dy ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'DY', dy)
      Write(*,*) 'Domain dy: ',dy

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'STAND_LON', j)
      IF ( .NOT. ALLOCATED ( xcent) ) THEN
            ALLOCATE ( xcent ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'STAND_LON', xcent)
      Write(*,*) 'Domain xcent: ',xcent(1)

      Status = NF_INQ_ATTLEN(FID,NF_GLOBAL,'STAND_LAT', j)
      IF ( .NOT. ALLOCATED ( ycent) ) THEN
            ALLOCATE ( ycent ( j ) )
      END IF
      Status = NF_GET_ATT_REAL(FID, NF_GLOBAL,'STAND_LAT', ycent)
      Write(*,*) 'Domain ycent: ',ycent(1)
      
! Get crop names and arrays
      Status = NF_INQ_DIMID(FID, 'crop_cat', DIMID)  
      Write(*,*) 'After NF_INQ_DIMID crop_cat', DIMID    
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting crop_cat DIMID'
	 call exit()
      End If
      Status = NF_INQ_DIMLEN(FID, DIMID, n_crops) 
      Write(*,*) 'After NF_INQ_DIMLEN n_crops', n_crops
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting crop_cat DIM'
	 call exit()
      End If     
       Write(*,*) 'Number of crops: ', n_crops
      
      IF ( .NOT. ALLOCATED ( CropNames ) ) THEN
            ALLOCATE ( CropNames ( n_crops  ) )
      END IF
       write(*,*) 'Size of CropNames vector: ', Size(CropNames)                        
      
      IF ( .NOT. ALLOCATED ( Beld_ag ) ) THEN
            ALLOCATE ( Beld_ag ( n_x,n_y,n_crops  ) )
      END IF  
       write(*,*) 'Size of Beld_ag vector: ', Shape(Beld_ag)                

      Status = NF_INQ_VARID(FID, 'CROP_NAME', VARID)
      Write(*,*) 'After NF_INQ_VARID CROPNAMES'
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring CROPNAMES variable'
	 call exit()
      End If
      
      Status = NF_GET_VAR_TEXT(FID, VARID,CropNames)
      Write(*,*) 'After NF_GET_VAR_TEXT CropNames'      
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting CROPNAMES variable'
	 call exit()
      End If

      
      Do i=1, n_crops
         Select Case (i)
            Case(1:9)
	       CropNames(i) = CropNames(i)(4:50)
	    Case(10:99)
	       CropNames(i) = CropNames(i)(5:50)
	    Case(100:)
	       CropNames(i) = CropNames(i)(6:50)
	 End Select
	 
	 Write(*,*) CropNames(i),','
      End Do      
            
      Status = NF_INQ_VARID(FID, 'CROPF', VARID)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring CROPF variable ID'
	 call exit()
      End If
      
      Status = NF_GET_VAR_REAL(FID, VARID, Beld_Ag)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting CROPF variable'
	 call exit()
      End If
!      Write(*,*) 'Max Frac Beld Agriculture: ', Maxval(Beld_Ag)
!      Write(*,*) 'NF_NOERR', NF_NOERR

! Get tree names and arrays     
      Status = NF_INQ_DIMID(FID, 'tree_cat', DIMID)      
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting tree_cat DIMID'
	 call exit()
      End If
      Status = NF_INQ_DIMLEN(FID, DIMID, n_trees) 
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting tree_cat DIM'
	 call exit()
      End If     
!      Write(*,*) 'Number of trees: ', n_trees
      
      IF ( .NOT. ALLOCATED ( TreeNames ) ) THEN
            ALLOCATE ( TreeNames ( n_trees  ) )
      END IF
!      write(*,*) 'Size of TreeNames vector: ', Size(TreeNames)     
      
      IF ( .NOT. ALLOCATED ( Beld_tree ) ) THEN
            ALLOCATE ( Beld_tree ( n_x,n_y,n_trees  ) )
      END IF  
!      write(*,*) 'Size of Beld_tree vector: ', Shape(Beld_ag)  
      
      Status = NF_INQ_VARID(FID, 'TREE_NAME', VARID)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring TREENAMES variable'
	 call exit()
      End If
      
      Status = NF_GET_VAR_TEXT(FID, VARID,TreeNames)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting TreeNames variable'
	 call exit()
      End If
      
      Do i=1, n_trees
         Select Case (i)
            Case(1:9)
	       TreeNames(i) = TreeNames(i)(4:50)
	    Case(10:99)
	       TreeNames(i) = TreeNames(i)(5:50)
	    Case(100:)
	       TreeNames(i) = TreeNames(i)(6:50)
	 End Select
	 Write(*,*) 'Tree names: ', TreeNames(i)
      End Do
      
      Status = NF_INQ_VARID(FID, 'TREEF', VARID)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring TREEF variable ID'
	 call exit()
      End If
      
      Status = NF_GET_VAR_REAL(FID, VARID, Beld_Tree)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting Beld_Tree variable'
	 call exit()
      End If
!      Write(*,*) 'Max Frac Beld Tree: ', Maxval(Beld_Tree)
          
! Get Land Use names and arrays     
      Status = NF_INQ_DIMID(FID, 'land_cat', DIMID)      
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting land_cat DIMID'
	 call exit()
      End If
      Status = NF_INQ_DIMLEN(FID, DIMID, n_lu) 
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting n_lu DIM'
	 call exit()
      End If     
      Write(*,*) 'Number of Land Uses: ', n_lu
      
      IF ( .NOT. ALLOCATED ( LuNames ) ) THEN
            ALLOCATE ( LuNames ( n_lu  ) )
      END IF
      IF ( .NOT. ALLOCATED ( LuDesc ) ) THEN
            ALLOCATE ( LuDesc ( n_lu  ) )
      END IF
      write(*,*) 'Size of LuNames vector: ', Size(LuNames)     
      
      IF ( .NOT. ALLOCATED ( Beld_Lu ) ) THEN
            ALLOCATE ( Beld_Lu ( n_x,n_y,n_lu  ) )
      END IF  
      write(*,*) 'Size of Beld_Lu vector: ', Shape(Beld_Lu)  
      
      Status = NF_INQ_VARID(FID, 'LU_NAME', VARID)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring LUNAMES variable'
	 call exit()
      End If
      
      Status = NF_GET_VAR_TEXT(FID, VARID,LuDesc)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting LuNames variable'
	 call exit()
      End If
      
      Do i=1, n_lu
         Select Case (i)
            Case(1:9)
	       LuNames(i) = LuDesc(i)(4:8)//'_'//LuDesc(i)(1:1)
	    Case(10:20)
	       LuNames(i) = LuDesc(i)(5:9)//'_'//LuDesc(i)(1:2)
	    Case(21:30)
	       LuNames(i) = LuDesc(i)(5:8)//'_'//LuDesc(i)(1:2)
	    Case(31:40)
	       LuNames(i) = LuDesc(i)(5:8)//'_'//LuDesc(i)(1:2)
!	    Case(41:48)
!	       LuNames(i) = LuDesc(i)(5:70)
!	    Case(49:50)
!	       LuNames(i) = LuDesc(i)(5:9)//'_'//LuDesc(i)(12:15)
	 End Select
	 Write(*,*) 'Land use names: ', LuNames(i)
	 Write(*,*) 'Index(LuNames): ', index(LuNames(i),' ')
      End Do      
      
      Status = NF_INQ_VARID(FID, 'LANDUSEF', VARID)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error inquiring LANDUSEF variable ID'
	 call exit()
      End If
      
      Status = NF_GET_VAR_REAL(FID, VARID, Beld_Lu)
      If (Status .NE. NF_NOERR) Then
         Write(*,*) 'Error getting Beld_Lu variable'
	 call exit()
      End If
!      Write(*,*) 'Max Frac Beld Land Use: ', Maxval(Beld_Lu)
      
      Status = NF_CLOSE(FID)
      
! set up and write Models-3 IO/API file
      LOGDEV = INIT3()
      
      FTYPE3D = GRDDED3
      NVARS3D = n_lu + n_crops + n_trees
      NCOLS3D = n_x
      NROWS3D = n_y
      NLAYS3D = 1
      NTHIK3D = 1
      GDTYP3D = 2
      P_ALP3D = 33.0
      P_BET3D = 45.0
      P_GAM3D = -97.0
      XORIG3D = xmin(1)
      YORIG3D = ymin(1)
      XCENT3D = xcent(1)
      YCENT3D = ycent(1)
      XCELL3D = dx(1)
      YCELL3D = dy(1)
      VGTYP3D = -9999
      VGTOP3D = -9999
      VGLVS3D = -9999
      GDNAM3D = TRIM(gridname)
      SDATE3D = 0
      STIME3D = 0
      TSTEP3D = 0
      
      Do i = 1, n_lu + n_crops + n_trees
         VTYPE3D(i) = M3REAL
	 IF (( i >= 1 ) .AND. (i <= n_lu)) THEN
	    VNAME3D(i) = Trim(LuNames(i))
	    VDESC3D(i) = Trim(LuDesc(i))
!	    Write(*,*) Trim(LuNames(i)),','		
         ENDIF
	 IF (( i >= n_lu+1 ) .AND. (i <= n_lu+n_crops)) THEN
	    VNAME3D(i) = Trim(CropNames(i-n_lu))
	    VDESC3D(i) = 'BELD4 land use'
!	    Write(*,*) Trim(CropNames(i-n_lu)),','	
         ENDIF
	 IF (( i >= n_lu+n_crops+1) .AND. (i<=n_lu+n_crops+n_trees)) THEN
	    VNAME3D(i) = Trim(TreeNames(i-n_lu-n_crops))
	    VDESC3D(i) = 'BELD4 land use'
!	    Write(*,*) Trim(TreeNames(i-n_lu-n_crops)),','	
         ENDIF 
	 UNITS3D(i) = 'percent'	 
	 Write(*,*) 'VNAME3D: ', VNAME3D(i)
      End Do      
            
      write(*,*)  "before Output file is opened. "
      IF ( .NOT. OPEN3( 'OUTFILE', FSNEW3, PNAME ) ) THEN
         XMSG = 'Could not create beld4.ncf file'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT1 )
      END IF
      write(*,*)  "after Output file is opened. "
   
      Do i = 1, n_lu   
          IF ( .NOT. WRITE3( 'OUTFILE', Trim(LuNames( i )), SDATE3D,
     &                       STIME3D, Beld_Lu(:,:,i) ) ) THEN
             XMSG = 'Could not write initial values to beld4_12US1.ncf file'
             CALL M3EXIT( PNAME, SDATE3D, STIME3D, XMSG, XSTAT1 )
          END IF
      End Do
      
      Do i = 1, n_crops   
          IF ( .NOT. WRITE3( 'OUTFILE', Trim(CropNames( i )), SDATE3D,
     &                       STIME3D, Beld_ag(:,:,i) ) ) THEN
             XMSG = 'Could not write initial values to beld4_12US1.ncf file'
             CALL M3EXIT( PNAME, SDATE3D, STIME3D, XMSG, XSTAT1 )
          END IF
      End Do
      
      Do i = 1, n_trees   
          IF ( .NOT. WRITE3( 'OUTFILE', Trim(TreeNames( i )), SDATE3D,
     &                       STIME3D, Beld_Tree(:,:,i) ) ) THEN
             XMSG = 'Could not write initial values to beld4_12US1.ncf file'
             CALL M3EXIT( PNAME, SDATE3D, STIME3D, XMSG, XSTAT1 )
          END IF
      End Do
      
      End Program Beld_NC2IOAPI
