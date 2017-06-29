
      PROGRAM CSV2IOAPI
!***********************************************************************
!  This program converts comma deliminated line input to gridded
!  netCDF-IOAPI format.
!  The grid parameter is input from GRIDDESC
!  Program always takes first and second input column as grid-x 
!   and grid-y index.
!  Make sure the MXTCOL parameter matches the total number of input column.
!  If you export the file from Excel to .csv file, make sure you convert 
!   the DOS text file to Unix text file with "dos2unix" command.
!
!  Requirement:
!     Requires libnetcdf.a and libioapi.a to compile
!     Also, parsline.o and chkmetem.o from SMOKE
!
!     setenv INPFILE <input text file>
!     setenv OUTFILE <output netCDF-ioapi file>
!     setenv GRIDDESC <grid desc file>
!
!  Call:
!     PARSLINE
!     CHECKMEM
!
!  Created by Jack Chen 11/04
!  Modified by Tan 11/13/06 for MEGAN v2.0
!
!  History:
!  08/14/07 Tan    - Move to MEGANv2.02 with no update
!***********************************************************************
      USE M3UTILIO

      IMPLICIT NONE

C...........   INCLUDES:


C...........   EXTERNAL FUNCTIONS and their descriptions:
      EXTERNAL     PROMPTFFILE, DSCGRID
     &             STR2INT, STR2REAL, INDEX1
     &             PROMPTMFILE

C.........  LOCAL VARIABLES and their descriptions:
      INTEGER       IOS            ! i/o status
      INTEGER       ILINE          ! current line
      INTEGER    :: ADEV           ! unit no. for input data file
      INTEGER    :: LDEV           ! unit no. for log file
      INTEGER       I, J, S, N     ! Counters
      INTEGER     JDATE, JTIME, TSTEP

      CHARACTER*16    CNAME        ! Coord name
      CHARACTER(LEN=1000) LINE     ! input ine buffer
      CHARACTER*256    MESG        ! message buffer
      INTEGER       CID, INX, INY, TST  ! Input grid x and y, timestep

!     CHARACTER*16  :: ONAME = 'OUTFILE'     ! Output file logical name
      CHARACTER*16  :: MNAME                 ! Output file logical name
      CHARACTER*16  :: ONAME                 ! Output file logical name
      CHARACTER*16  :: INAME = 'INPFILE'      ! Input file logical name

      INTEGER, PARAMETER :: MXTCOL = 40      ! Columns in an input line
      CHARACTER*30     SEGMENT( MXTCOL )     ! Input line fields

c      INTEGER, PARAMETER :: NVARS = MXTCOL - 3  ! Number of output variables
      INTEGER, PARAMETER :: NVARS = 16  ! Number of output variables
      CHARACTER*16 UNITS( NVARS ) ! Output variables
      CHARACTER*80 VDESC( NVARS ) ! Output variables
      CHARACTER*16 VNAME( NVARS ) ! Output variables

      REAL, ALLOCATABLE :: IBUFF( :, :, :, : )  ! input, output buffer

      CHARACTER*16  :: PROGNAME = 'CSV2IOAPI'

!***********************************************************************
!... Begin program
!... Initialize log file unit
      LDEV = INIT3() 

!... Get output file grid parameters
      MESG  = 'Enter logical name of input/output data file.'
      MNAME = PROMPTMFILE( MESG, FSREAD3, 'METFILE', PROGNAME )
      write(*,*) "MNAME = ", MNAME

      MESG = 'Coordinate name: '
      IF( .NOT. DESC3( MNAME ) ) THEN
         MESG = 'ERROR: Could not get description of file ' 
         CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
      END IF

!     CALL ENVSTR( 'GDNAM3D', MESG, 'ASACA36km', GDNAM3D, IOS )
!     IF ( .NOT. OPEN3( CNAME, FSUNKN3, PROGNAME ) ) THEN
!          MESG = 'Could not open file "'//TRIM(ONAME)//'" for output'
!          CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
!     ENDIF
!     CALL ENVSTR( 'GDNAM3D', MESG, 'DonaAna_4km', GDNAM3D, IOS )
!     IF( .NOT. DSCGRID( GDNAM3D, CNAME, GDTYP3D,
!    &              P_ALP3D, P_BET3D, P_GAM3D, XCENT3D, YCENT3D,
!    &              XORIG3D, YORIG3D, XCELL3D, YCELL3D,
!    &              NCOLS3D, NROWS3D, NTHIK3D ) ) THEN
!        MESG = 'Could not get grid description.'
!        CALL M3EXIT ( PROGNAME, 0, 0, MESG, 2 )
!     ENDIF
!     DESC3(CNAME)
      print*,'NVARS3D, NCOLS3D, NROWS3D: ',NVARS3D, NCOLS3D, NROWS3D
      print*,'SDATE3D, STIME3D, TSTEP3D: ',SDATE3D, STIME3D, TSTEP3D

!... Allocate memory
      ALLOCATE ( IBUFF( 365, NVARS, NCOLS3D, NROWS3D ),
     &           STAT = IOS )
      CALL CHECKMEM ( IOS, 'IBUFF', PROGNAME )
      IBUFF = 0.

!... Get input file unit
      MESG = 'Enter logical name of input data file.'
      ADEV = PROMPTFFILE( MESG, .TRUE., .TRUE., INAME, PROGNAME )
      IF( ADEV < 0 ) THEN
         MESG = 'Error opening input file..'
         CALL M3EXIT ( PROGNAME, 0, 0, MESG, 2 )
      ENDIF
      ILINE = 0
      DO
         READ( ADEV, 1000, IOSTAT = IOS ) LINE
         ILINE = ILINE + 1
C.............. End of file exit loop
         IF( IOS < 0 ) EXIT
C.............. Skip blank lines
         IF( LINE == ' ' ) CYCLE
         IF( IOS > 0 ) THEN
            WRITE( MESG, 1010 ) 'I/O error', IOS,
     &            'reading input file at line', ILINE
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
         ENDIF
C        PRINT*,'ILINE:',ILINE
         CALL PARSLINE( LINE, MXTCOL, SEGMENT )  ! break lines into segments
         IF ( ILINE .EQ. 1 ) THEN
            DO S = 1, NVARS
               MESG = SEGMENT( S )
               UNITS( S ) = TRIM( MESG )
               PRINT*,'UNITs:',UNITS(S)
            ENDDO
            CYCLE
         ENDIF
         IF ( ILINE .EQ. 2 ) THEN
            DO S = 1, NVARS
               MESG = SEGMENT( S )
               VDESC( S ) = TRIM( MESG )
               PRINT*,'VDESC:',VDESC(S)
            ENDDO
            CYCLE
         ENDIF
         IF ( ILINE .EQ. 3 ) THEN
            DO S = 1, NVARS
               MESG = SEGMENT( S )
               CALL UPCASE( MESG )  ! to all caps
               VNAME( S ) = TRIM( MESG )
               PRINT*,'VNAME:',VNAME(S)
            ENDDO
            CYCLE
         ENDIF

!        INX = STR2INT( SEGMENT(2) )   ! convert character to integer
         TST = STR2INT( SEGMENT(NVARS+1) )   ! convert character to integer
         INX = STR2INT( SEGMENT(NVARS+2) )   ! convert character to integer
         INY = STR2INT( SEGMENT(NVARS+3) )   ! convert character to integer
         DO S = 1, NVARS
!           print*,'S,X,Y,:',S,INX,INY
            IBUFF(TST, S,INX,INY) = STR2INT( SEGMENT( S ) )  ! convert char to integer
             if ( IBUFF(TST,S,INX,INY)  .eq. 0 ) then
                IBUFF(TST,S,INX,INY) = -9
         endif 
         ENDDO
!         if ( IBUFF(S,INX,INY)  .gt. 0 ) then
!             print*,IBUFF(S,INX,INY)
!         endif 
      ENDDO

      WRITE( MESG, 1010 ) 'Total number of input lines read:',ILINE
      CALL M3MESG( MESG )

!... Setup additional outfile parameters and open outfile
!     FTYPE3D = GRDDED3
      NVARS3D = NVARS
      VNAME3D(1:NVARS) = VNAME(1:NVARS)
      VTYPE3D(1:NVARS) = M3REAL
      SDATE3D = 2002001   !SDATE
      STIME3D = 0
      TSTEP3D = 240000 ! time step, 0 for independent
      NLAYS3D = 1
      CALL NAMEVAL ( INAME , MESG )  ! get input file name
      FDESC3D( 1 ) = 'add variables'
!     FDESC3D( 2 ) = TRIM(MESG)
      UNITS3D(1:NVARS) = UNITS(1:NVARS)
      VDESC3D(1:NVARS) = VDESC(1:NVARS)

      IF ( .NOT. OPEN3( ONAME, FSUNKN3, PROGNAME ) ) THEN
           MESG = 'Could not open file "'//TRIM(ONAME)//'" for output'
           CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
      ENDIF
      MESG  = 'Enter logical name of input/output data file.'
      ONAME = PROMPTMFILE( MESG, FSNEW3, 'OUTFILE', PROGNAME )
      write(*,*) "ONAME = ", ONAME

!... Write output
!     DO S = 1, NVARS
      JDATE = SDATE3D
      JTIME = 0        
      TSTEP = TSTEP3D
      DO N = 1,365
!        PRINT*,'min cell value for:',TRIM(VNAME3D(S)),MINVAL(IBUFF(N,S,:,:))
!        PRINT*,'max cell value for:',TRIM(VNAME3D(S)),MAXVAL(IBUFF(N,S,:,:))
         IF ( .NOT. WRITE3(ONAME,'ALL',JDATE,JTIME,IBUFF(N,:,:,:))) THEN
            MESG = 'Error writing to  file "'//TRIM(ONAME)//'"'
            CALL M3EXIT(PROGNAME,0,0,MESG,2)
         ENDIF
         CALL NEXTIME( JDATE, JTIME, TSTEP )
      ENDDO
!     ENDDO

!... Exit and close file
      CALL M3EXIT(PROGNAME,0,0,' ',0)

1000  FORMAT( 40A )
1010  FORMAT( 40( A, :, I8, :, 1X ) )

      ENDPROGRAM
