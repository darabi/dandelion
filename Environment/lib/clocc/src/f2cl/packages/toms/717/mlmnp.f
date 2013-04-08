      PROGRAM MLMNP
C
C     VERSION:  SEPTEMBER 4, 1991
C
C  ***  MAXIMUM LIKELIHOOD ESTIMATION OF THE LINEAR-IN-PARAMETERS    ***
C  ***  MULTINOMIAL PROBIT MODEL (VIA MENDELL-ELSTON PROBABILITIES). ***
C  ***  SEE REFERENCES BELOW.                                        ***
C
C  ***  THIS VERSION DOES NOT IMPOSE SIMPLE BOUNDS ON THE PARAMETERS.***
C  ***  THIS VERSION DOES CALCULATE T-SCORES AND REGRESSION          ***
C  ***  DIAGNOSTICS.                                                 ***
C
C  ***  THIS PROGRAM UTILIZES A GENERAL FRAMEWORK FOR MLE OF A       ***
C  ***  PROBABILISTIC CHOICE MODEL AND MAY BE MODIFIED FOR USE WITH  ***
C  ***  OTHER CHOICE MODELS. (SEE "PROTOTYE PROGRAM" DISCUSSION.)    ***
C
C     PROGRAM MLEPCM ("PROTOTYPE PROGRAM")
C  ***  MAXIMUM LIKELIHOOD ESTIMATION OF PROBABILISTIC CHOICE MODELS ***
C
C  ***  DESCRIPTION  ***
C
C      THIS PROGRAM PERFORMS MAXIMUM LIKELIHOOD ESTIMATION BY MINIMIZING
C   THE NEGATIVE OF THE LOG-LIKELIHOOD FUNCTION. THE FUNCTION IS WRITTEN
C   AS
C
C       -SUM{FOR I=1, NOBS} WT(I)*LOG P[ICH(I), IX(I), RX(I)]
C
C   WHERE:
C      P[ICH(I), IX(I), RX(I)] IS A GENERAL PROBABILISTIC CHOICE MODEL,
C      ICH(I) IS THE CHOICE MADE FOR OBSERVATION I,
C      IX(I) CONTAINS INTEGER EXPLANATORY DATA SPECIFIC TO OBSERVATION I
C         (E.G., A LIST OF ALTERNATIVES IN THE CHOICE SET),
C      RX(I) CONTAINS REAL EXPLANATORY DATA SPECIFIC TO OBSERVATION I,
C      AND WT(I) IS A WEIGHT FOR OBSERVATION I.
C
C    THIS PROGRAM IS DESIGNED TO CALL THE GENERALIZED REGRESSION
C    OPTIMIZATION SUBROUTINES DGLG AND DGLGB, WHICH IN TURN CALL DRGLG
C    AND DRGLGB, ETC.   A FEW LEVELS DOWN, THE PROBABILITY
C    P[ICH(I), IX(I), RX(I)] IS COMPUTED IN A USER-SUPPLIED SUBROUTINE
C    CALCPR,  USING THE FOLLOWING CALL:
C
C     CALL CALCPR(NPAR, X, IERR, ICH, IALT, II, ICDAT, IR, RCDAT,
C    1                  PROB, IUSER, RUSER, MNPCDF)
C
C    FOR A DESCRIPTION OF PARAMETER USAGE, SEE THE SUBROUTINE.
C
C  ***  MLEPCM PARAMETER DECLARATIONS  ***
C
C  SCALARS:
C
      INTEGER BS, COVTYP, ICSET, IDR, IOUNIT, NB, NFIX, NIUSER
      INTEGER NIVAR, NOBS, NPAR, NRUSER, NRVAR, WEIGHT, XNOTI
C
C  ARRAYS:
C
      INTEGER IV(300), RHOI(28000), UI(24000)
      DOUBLE PRECISION B(2,60), RHOR(164000), UR(160000), V(268105)
      DOUBLE PRECISION X(60)
      DOUBLE PRECISION TSTAT(60), STDERR(60)
      EQUIVALENCE (RHOI(1), UI(1)), (RHOR(1), UR(1))
      CHARACTER*8 VNAME(60)
C
C  LENGTHS OF ARRAYS:
C
      INTEGER LIV, LRHOI, LRHOR, LUI, LUR, LV, LX
C
C     INTEGER IV(LIV), RHOI(LRHOI), UI(LUI)
C     DOUBLE PRECISION B(2,LX), RHOR(LRHOR), UR(LUR), V(LV), X(LX)
C
C  SUBROUTINES:
C
      DOUBLE PRECISION DR7MDC
      EXTERNAL DGLG, DIVSET, DR7MDC, FPRINT, MECDF, PCMRHO, PCMRJ
C
C  ***  MLEPCM PARAMETER USAGE ***
C
C (SEE EXPLANATIONS BELOW)
C
C SCALARS:
C
C BS...... BLOCK-SIZE, IF LEAVE-BLOCK-OUT REGRESSION DIAGNOSTICS ARE
C            REQUESTED AND ALL BLOCKS ARE THE SAME SIZE (SEE BELOW).
C COVTYP.. INDICATES TYPE OF VARIANCE-COVARIANCE MATRIX APPROXIMATION.
C            = 1 FOR H^-1, WHERE H IS THE FINITE-DIFFERENCE HESSIAN
C                AT THE SOLUTION.
C            = 2 FOR (J^T J)^-1, I.E., THE GAUSS-NEWTON HESSIAN
C              APPROXIMATION AT THE SOLUTION.
C ICSET... INDICATOR OF FIXED- OR VARIABLE-SIZE CHOICE SETS.
C IDR..... INDICATOR FOR TYPE OF REGRESSION DIAGNOSTICS (SEE BELOW).
C IOUNIT.. OUTPUT UNIT NUMBER FOR PRINTING ERROR MESSAGES.
C             = FORTRAN UNIT FOR IOUNIT > 0.  DEFAULT = 6.
C IPRNT... INDEX INDICATING PRINT OPTIONS.
C             = 0 FOR NO ADDITIONAL PRINTING.
C             = 1 FOR FINAL CHOICE PROBABILITIES.
C             (DEFAULT = 0.)
C NB...... NUMBER OF BLOCKS, IF LEAVE-BLOCK-OUT REGRESSION DIAGNOSTICS
C            ARE REQUESTED (SEE BELOW).
C NFIX.... PARAMETER USED BY DRGLG.  NFIX = 0.
C NIVAR... NUMBER OF (INTEGER) DATA VARIABLES PER CHOICE SET.
C NIUSER.. NUMBER OF (INTEGER) USER-SPECIFIED CONSTANTS.
C NOBS.... NUMBER OF OBSERVATIONS.
C NPAR.... NUMBER OF MODEL PARAMETERS (X COMPONENTS).
C NRVAR... NUMBER OF (REAL) DATA VARIABLES PER CHOICE SET.
C NRUSER.. NUMBER OF (REAL) USER-SPECIFIED CONSTANTS.
C WEIGHT.. INDICATOR FOR USER-PROVIDED WEIGHTS.
C XNOTI... INDICATOR FOR TYPE OF REGRESSION DIAGNOSTICS (SEE BELOW).
C
C ARRAYS AND ARRAY LENGTHS:
C
C B....... REAL ARRAY OF UPPER AND LOWER BOUNDS ON PARAMETER VALUES.
C IV...... INTEGER VALUE ARRAY USED BY OPTIMIZATION ROUTINES.
C LIV..... LENGTH OF IV; MUST BE AT LEAST 90 + NPAR.
C          CURRENT LIV = 300.
C LV...... LENGTH OF LV; MUST BE AT LEAST
C               105 + P*(3*P + 16) + 2*N + 4P + N*(P + 2), WHERE
C               P = NPAR AND N = NOBS.  FOR P = 60 AND N = 4000, THIS
C               EXPRESSION GIVES 268105.  CURRENT LV = 268105.
C LRHOI... LENGTH OF RHOI.  CURRENT LRHOI = LUI + 4000 = 28000.
C LRHOR... LENGTH OF RHOR.  CURRENT LRHOR = LUR + 4000 = 164000.
C LUI..... LENGTH OF UI.  CURRENT LUI = 24000.
C LUR..... LENGHT OF UR.  CURRENT LUR = 160000.
C LX...... LENGTH OF PARAMETER VECTOR X.  CURRENT LX = 30.
C RHOI.... INTEGER VALUE ARRAY PASSED WITHOUT CHANGE TO PCMRHO.
C            ALSO USED TO PASS BLOCK-SIZES IF LEAVE-BLOCK-OUT
C            REGRESSION DIAGNOSTICS WITH VARIABLE BLOCK-SIZES ARE
C            REQUESTED (SEE BELOW).  (CURRENT PCMRHO MAKES USE OF
C            RHOI THROUGH EQUIVALENCE OF RHOI WITH UI.)
C RHOR.... REAL VALUE ARRAY PASSED WITHOUT CHANGE TO PCMRHO.
C            ALSO USED TO STORE X(I) VECTORS, IF SUCH REGRESSION
C            DIAGNOSTICS ARE REQUESTED (SEE BELOW).  (CURRENT PCMRHO
C            MAKES USE OF RHOR THROUGH 2EQUIVALENCE OF RHOR WITH UR.)
C UI...... INTEGER VALUE ARRAY FOR USER STORAGE (SEE BELOW).
C            UI(1) TO UI(10) STORE MLEPCM PARAMETERS FOR USE IN
C            SUBROUTINES PCMRJ, PCMRHO, CALCPR, ETC.
C UR...... REAL VALUE ARRAY FOR USER STORAGE (SEE BELOW).
C V....... REAL VALUE ARRAY USED BY OPTIMIZATION ROUTINES.
C VNAME... ARRAY OF PARAMETER NAMES FOR X COMPONENTS BEING ESTIMATED.
C X....... PARAMETER VECTOR BEING ESTIMATED.
C
C  SUBROUTINES:
C
C PCMRJ... SUBROUTINE THAT CALCULATES GENERALIZED RESIDUAL VECTOR,
C            AND THE JACOBIAN OF THE GENERALIZED RESIDUAL VECTOR.
C            SEE DISCUSSION OF "CALCRJ" IN DGLG.
C PCMRHO.. SUBROUTINE THAT CALCULATES THE CRITERION FUNCTION, AND
C            ITS DERIVATIVES.  SEE DISCUSSION OF "RHO" IN DRGLG.
C MECDF... SUBROUTINE THAT CALCULATES THE MULTIVARIATE NORMAL CDF
C            USING THE FIXED-ORDER MENDELL-ELSTON APPROXIMATION.
C            PASSED WITHOUT CHANGE TO CALCPR.  (COULD BE REPLACED
C            WITH ANOTHER CDF ROUTINE IF DESIRED.)
C
C
C  ***  DISCUSSION FOR MLEPCM ***
C
C  ***  DATA INPUT STREAM ***
C
C  *** GENERAL PARAMETERS ARE READ IN FIRST FROM "INPUT BLOCK 1": ***
C
C   READ(1,*) NPAR,NOBS,ICSET,WEIGHT,NIVAR,NRVAR,IOUNIT,IPRNT,COVTYP,IDR
C
C     THESE PARAMETERS ARE INTENDED TO GIVE A FLEXIBLE INPUT
C   FORMAT FOR CHOICE MODELS, WITH SOME SHORTCUTS FOR SIMPLE CASES.
C   SPECIFIC SETTINGS OF THE ABOVE PARAMETERS WILL PRODUCE DIFFERENCES
C   IN THE INPUT STREAM FORMAT.
C
C   FOR ICSET = 0 (OR 1) A VARIABLE NUMBER OF ALTERNATIVES PER CHOICE
C      SET IS USED.  THE USER MUST PROVIDE THIS NUMBER FOR EACH
C      OBSERVATION.
C   FOR ICSET > 1 EACH CHOICE SET IS ASSUMED TO INCLUDE ICSET
C      ALTERNATIVES.
C
C   WEIGHT = 1 MEANS THAT EACH OBSERVATION REQUIRES A WEIGHT, WHICH
C      MUST BE PROVIDED BY THE USER.
C   WEIGHT = 0 MEANS THAT ALL OBSERVATIONS AUTOMATICALLY RECEIVE EQUAL
C      WEIGHT AND THEREFORE NO USER-SUPPLIED WEIGHTS ARE REQUIRED.
C
C   FOR NIVAR = -1 NO INTEGER DATA VALUES ARE REQUIRED BY THE MODEL.
C   FOR NIVAR =  0 A VARIABLE NUMBER OF INTEGER DATA VALUES IS STORED
C      PER OBSERVATION.  IN THIS CASE, THE USER MUST INCLUDE FOR EACH
C      OBSERVATION THE NUMBER OF INTEGER VALUES TO BE STORED FOLLOWED
C      BY THE INTEGER VALUES THEMSELVES.  (THIS MIGHT BE USED IN
C      CONJUNCTION WITH ICSET=0 TO LIST NOMINAL VARIABLES FOR THE
C      CHOICE ALTERNATIVES IN THE CHOICE SET.)
C   FOR NIVAR > 0 EACH OBSERVATION IS ASSUMED TO INCLUDE NIVAR INTEGERS.
C
C   FOR NRVAR THE USAGE IS ANALOGOUS TO NIVAR, ONLY FOR REAL DATA.
C
C   NIUSER AND NRUSER ARE USED TO INDICATE THE NUMBER OF CONSTANTS
C      TO BE PASSED TO THE MODEL SUBROUTINES.  THESE ARE MODEL SPECIFIC.
C      FOR SOME CODES NIUSER, NRUSER, AND PERHAPS THE CONSTANTS, MIGHT
C      BE SET IN THE MAIN PROGRAM AND NOT BY THE INPUT STREAM.
C
C   FOR MORE DETAILS ON THIS, SEE THE ACTUAL CODE BELOW.
C
C     IN ADDITION TO DATA STORAGE, MLEPCM PROVIDES A RATHER FLEXIBLE
C   CHOICE OF STATISTICAL ANALYSES.  IN THE VERSION OF THE PROGRAM
C   WHICH ENFORCES BOUNDS, STATISTICS ARE NOT CALCULATED.  HOWEVER,
C   FOR CONVENIENCE IT IS ASSUMED THAT THE SAME INPUT STREAM IS USED
C   FOR BOTH PROGRAMS.
C
C      TO CALCULATE ASYMPTOTIC T-SCORES, A VARIANCE-COVARIANCE MATRIX
C   APPROXIMATION IS REQUIRED.  SEE COVTYP ABOVE.
C
C      TO PERFORM REGRESSION DIAGNOSTICS, THE FOLLOWING PARAMETERS
C   ARE USED:
C
C   IDR = 0 IF NO REGRESSION DIAGNOSTICS ARE DESIRED.
C
C       = 1 FOR ONE-STEP ESTIMATES OF F(X*)-F(X(I)), WHERE X(I)
C             MINIMIZES F (THE NEGATIVE LOG-LIKELIHOOD) WITH
C             OBSERVATION I REMOVED, AND X* IS THE MLE FOR THE FULL
C             DATASET. ("LEAVE-ONE-OUT" DIAGNOSTICS.)
C
C       = 2 FOR ONE-STEP ESTIMATES OF F(X*)-F(X(I)) AS WHEN IDR = 1,
C             AND ALSO THE ONE-STEP ESTIMATES OF X(I), I = 1 TO NOBS.
C
C       = 3 FOR "LEAVE-BLOCK-OUT" DIAGNOSTICS.  (DISCUSSION FOLLOWS.)
C
C *** PARAMETERS RELATED TO "LEAVE-BLOCK-OUT" REGRESSION DIAGNOSTICS ***
C *** READ NEXT FROM "INPUT BLOCK 2" (IF APPLICABLE).                ***
C
C   "LEAVE-BLOCK-OUT" DIAGNOSTICS
C
C       IN THIS CASE, ONE OR MORE ADDITIONAL LINES OF DATA ARE
C    REQUIRED. IF IDR = 3, THE FOLLOWING STATEMENT IS EXECUTED:
C
C              READ(1,*) BS, NB, XNOTI
C
C    NB = NUMBER OF BLOCKS
C
C    XNOTI = 0 IF NO X(I) DIAGNOSTICS ARE REQUESTED,
C          = 1 OTHERWISE.
C
C    BS > 0 MEANS THAT FIXED BLOCK SIZES OF SIZE BS ARE USED.
C           IN THIS CASE NB * BS = NOBS, AND THE PROGRAM
C           PROCEEDS TO "INPUT BLOCK 3" FOR MNP INPUT PARAMETERS.
C
C    BS = 0 MEANS THAT VARIABLE BLOCK SIZES ARE USED.
C           IN THIS CASE THE NEXT FORMAT STATEMENT READS
C           THE BLOCK SIZES INTO RHOI USING FREE FORMAT:
C
C           LR1 = LUI + 1
C           LR2 = LR1 + NB
C           READ(1,*) (RHOI(I),I=LR1,LR2)
C
C  *** THE PROGRAM THEN PROCEEDS TO "INPUT BLOCK 3" TO READ MODEL-***
C  *** RELATED PARAMETERS.  SEE DISCUSSION FOR MNP MODEL BELOW.   ***
C
C  *** INPUT BLOCK 4 CONTAINS THE INITIAL GUESS FOR THE SEARCH.   ***
C  *** IT INCLUDES VARIABLE NAMES, A STARTING GUESS, AND BOUNDS.  ***
C
C      DO 10 I = 1, NPAR
C         READ(1,3) VNAME(I)
C   3     FORMAT(1X,A8)
C         READ(1,*) X(I), B(1,I), B(2,I)
C             WRITE(IOUNIT,4) I, VNAME(I),X(I), B(1,I), B(2,I)
C   4     FORMAT(1X,I2,1X,A8,2X,3(1X,E13.6))
C   10 CONTINUE
C     CLOSE(1)
C
C  *** FOR THE LINEAR-IN-PARAMETERS MNP MODEL, THE ORDERING OF    ***
C  *** PARAMETERS IS AS FOLLOWS:                                  ***
C
C     1.  MEAN TASTE WEIGHTS FOR GENERIC ATTRIBUTES (NATTR OF THESE).
C     2.  ALTERNATIVE-SPECIFIC MEANS (NALT-1 OF THESE).
C     3.  COVARIANCE PARAMETERS FOR ALTERNATIVE-SPECIFIC ERRORS.
C         THERE ARE 2(NALT-1)(NALT)/2  -  1 OF THESE, IN THE FORM OF
C         CHOLESKY DECOMPOSITION, STORED ROW-WISE:
C            B21  B22
C            B31  B32  B33
C            B(J-1,1)  B(J-1,2) ..........B(J-1,J-1)
C         WHERE B11 = SCALE IS ASSUMED.
C         SEE BUNCH(1991, TRANSP. RES. B, VOL. 1, PP. 1-12); NOTE
C         THE MISPRINT IN EQUATION (26).
C         (NOTE THAT PARAMETERS ARE READ IN ONE PARAMETER PER LINE.)
C     4.  COVARIANCE PARAMETERS FOR TASTE VARIATION.
C           NATTR VARIANCES IF ITASTE=1 (UNCORRELATED).
C           NATTR*(NATTR+1)/2 CHOLESKY PARAMETERS IF ITASTE=2
C           (I.E., CORRELATED).
C
C  *** UNIT 1 IS CLOSED, AND THE MODEL DATA IS READ FROM UNIT 2.  ***
C  *** ITS FORMAT IS CONTROLLED BY THE GENERAL PARAMETERS ABOVE.  ***
C  *** FOR THE SPECIFIC FREE-FORMAT READ STATEMENTS, SEE THE MAIN ***
C  *** BODY OF THE CODE.                                          ***
C
C
C  ***  MULTINOMIAL PROBIT MODEL PARAMETERS ***
C      (PARAMETERS SPECIFIC TO THIS MODEL IMPLEMENTATION)
C
      INTEGER ICOV, IDUM, ITASTE, NALT, NATTR
      INTEGER IUSER(18)
      EQUIVALENCE (UI(11),IUSER(1))
C
C  *** PARAMETER USAGE ***
C
C THE FOLLOWING ARE USER-PROVIDED INTEGER CONSTANTS:
C
C IDUM.... INDICATOR FOR ALTERNATIVE-SPECIFIC DUMMIES,
C             = 0 FOR NO, = 1 FOR YES.  IF ICSET .NE. 0, THEN
C             THE SAME SET OF DUMMIES IS USED FOR EACH CHOICE SET.
C             OTHERWISE, INTEGER DATA SHOULD BE USED TO IDENTIFY THE
C             ALTERNATIVES IN EACH CHOICE SET (SEE NALT BELOW).
C ICOV.... INDICATOR FOR TYPE OF ALTERNATIVE-SPECIFIC ERRORS,
C             = 0 FOR IID ERRORS, = 1 FOR CORRELATED ERRORS.
C             IF ICSET .NE. 0, THEN THE SAME CORRELATION MATRIX IS
C             USED FOR EVERY SUBSET.  OTHERWISE, INTEGER DATA SHOULD
C             BE USED TO IDENTIFY THE ALTERNATIVES IN EACH CHOICE SET.
C ITASTE.. INDICATOR FOR TASTE VARIATION,
C             = 0 FOR NO TASTE VARIATION, = 1 FOR UNCORRELATED TASTE
C             VARIATION, = 2 FOR CORRELATED TASTE VARIATION.
C IUSER... INTEGER ARRAY THAT STORES MNP MODEL PARAMETERS USED IN
C             SUBROUTINES PCMRJ, PCMRHO, CALCPR, ETC.
C NALT.... TOTAL NUMBER OF NOMINAL CHOICE ALTERNATIVES (IF APPLICABLE).
C             IF ICSET .NE. 0, THEN NALT IS SET EQUAL TO ICSET.
C             OTHERWISE, NALT SHOULD BE > 0 IF EITHER IDUM OR ICOV
C             (OR BOTH) ARE > 0.
C NATTR... NUMBER OF ATTRIBUTES (I.E., REAL DATA VARS.) PER
C             ALTERNATIVE.
C
C
C ***  READ STATEMENT FOR INPUT BLOCK 3 ***
C
C      READ(1,*) NALT, NATTR, IDUM, ICOV, ITASTE
C+++++++++++++++++++++++++++  DECLARATIONS  +++++++++++++++++++++++++++
C
      INTEGER I, ICH, ICHECK, ICP, IETA0, IH, II, IICDAT, IICH, IIIV,
     1        IIRV, IIU, INALT, IOBS, IPCOEF, IPCOV, IPDUM, IPRNT,
     2        IPTAST, IRCDAT, IRU, IRW, ISCALE, ISIGP, ISIGU, ITST,
     3        IV85, IV86, IV87, IV90, K, LCOVP, LCOVU, LCOVX, LOO,
     4        LRI1, LRR1, LW, NBSCHK, NF, NPCHK, NPS,
     5        NRICHK, NRRCHK, RDR
      DOUBLE PRECISION MKTSHR(20)
      DOUBLE PRECISION RFI, RHOSQR, RSQHAT, RLL0, RLLC, RLLR, RNI,
     1       RNOBS
C
      DOUBLE PRECISION ETA0, ONE, SCALE, TWO, ZERO
C
      DATA ZERO/0.D0/
      DATA ONE/1.D0/
      DATA TWO/2.D0/
C
C *** GENERAL ***
C
C CODED BY DAVID S. BUNCH
C SUPPORTED BY U.S. DEPARTMENT OF TRANSPORTATION THROUGH
C REGION NINE TRANSPORTATION CENTER AT UNIVERSITY OF CALIFORNIA,
C BERKELEY (WINTER-SUMMER 1991)
C---------------------------------  BODY  ------------------------------
C
C  *** INITIALIZE SOME PARAMETERS ***
C      (SEE DISCUSSION ABOVE)
      NFIX = 0
      LIV = 300
      LRI1 = 24001
      LRHOI = 28000
      LRHOR = 164000
      LRR1 = 160001
      LV = 268105
      LUI = 24000
      LUR = 160000
      LX = 60
C
C  *** READ MLEPCM PARAMETERS FROM INPUT BLOCK 1 ***
C
      OPEN(1,FILE='fort.1')
      REWIND 1
      OPEN(2,FILE='fort.2')
      REWIND 2
      READ(1,*) NPAR,NOBS,ICSET,WEIGHT,NIVAR,NRVAR,IOUNIT,IPRNT,
     1          COVTYP,IDR
C
      IF (IOUNIT.LE.0) THEN
         IOUNIT = 6
         WRITE(IOUNIT,10)
 10      FORMAT(/' *** INVALID IOUNIT SET EQUAL TO 6 ***',//)
      ENDIF
C
      WRITE(IOUNIT,20)
 20   FORMAT(' PROGRAM MLMNP',//,' MAXIMUM LIKELIHOOD ESTIMATION OF',
     1      /,' LINEAR-IN-PARAMETERS MULTINOMIAL PROBIT MODELS',/,
     1        ' (BOUNDS NOT ENFORCED; STATISTICS ARE COMPUTED)',//)
      WRITE(IOUNIT,30) NOBS
 30   FORMAT('  NUMBER OF OBSERVATIONS.................',I4)
      IF (ICSET.EQ.1) ICSET = 0
      IF (ICSET.EQ.0) THEN
         WRITE(IOUNIT,40)
 40      FORMAT('  FLEXIBLE CHOICE SETS USED')
      ELSE
                 WRITE(IOUNIT,50) ICSET
 50      FORMAT('  NUMBER OF ALTERNATIVES PER CHOICE SET..',I4)
      ENDIF
      IF (WEIGHT.EQ.1) THEN
         WRITE(IOUNIT,60)
 60      FORMAT('  USER-PROVIDED WEIGHTS USED')
      ELSE
                 WRITE(IOUNIT,70)
 70      FORMAT('  EQUAL WEIGHTS FOR ALL OBSERVATIONS')
      ENDIF
      IF (NIVAR.EQ.-1) THEN
         WRITE(IOUNIT,80)
 80      FORMAT('  NO INTEGER EXPLANATORY VARIABLES')
      ENDIF
      IF (NIVAR.EQ.0) THEN
         WRITE(IOUNIT,90)
 90      FORMAT('  FLEXIBLE INTEGER EXPLANATORY VARIABLES')
      ENDIF
      IF (NIVAR.GT.0) THEN
         WRITE(IOUNIT,100) NIVAR
 100     FORMAT('  NUMBER OF INTEGER DATA VALUES PER OBS..',I4)
      ENDIF
      IF (NRVAR.EQ.-1) THEN
         WRITE(IOUNIT,110)
 110     FORMAT('  NO REAL EXPLANATORY VARIABLES')
      ENDIF
      IF (NRVAR.EQ.0) THEN
         WRITE(IOUNIT,120)
 120     FORMAT('  FLEXIBLE REAL EXPLANATORY VARIABLES')
      ENDIF
      IF (NRVAR.GT.0) THEN
         WRITE(IOUNIT,130) NRVAR
 130     FORMAT('  NUMBER OF REAL DATA VALUES PER OBS.....',I4)
      ENDIF
      WRITE(IOUNIT,140) IOUNIT
 140  FORMAT('  OUTPUT UNIT............................',I4,/)
      IF ((COVTYP.NE.1).AND.(COVTYP.NE.2)) THEN
         COVTYP = 1
         WRITE(IOUNIT,150)
 150     FORMAT('  *** INVALID COVTYP SET TO 1 ***',/)
      ENDIF
      IF (COVTYP.EQ.1)  WRITE(IOUNIT,160)
 160  FORMAT('  COVARIANCE TYPE = INVERSE FINITE-DIFFERENCE HESSIAN')
      IF (COVTYP.EQ.2) WRITE(IOUNIT,170)
 170  FORMAT('  COVARIANCE TYPE = INVERSE GAUSS-NEWTON HESSIAN')
      IF ((IDR.LT.0).OR.(IDR.GT.3)) THEN
         IDR = 0
         WRITE(IOUNIT,180)
 180     FORMAT(/,'  *** INVALID IDR SET TO 0 ***',/)
      ENDIF
      IF (IDR.EQ.0) WRITE(IOUNIT,190)
 190  FORMAT('  NO REGRESSION DIAGNOSTICS REQUESTED')
      IF (IDR.GE.1) WRITE(IOUNIT,200)
 200  FORMAT('  REGRESSION DIAGNOSTICS REQUESTED')
      IF ((IDR.EQ.1).OR.(IDR.EQ.2)) WRITE(IOUNIT,210)
 210  FORMAT('  STANDARD LEAVE-ONE-OUT DIAGNOSTICS REQUESTED')
      IF (IDR.EQ.2) WRITE(IOUNIT,220)
 220  FORMAT('  DIAGNOSTICS ON X-VECTOR REQUESTED')
      IF (IDR.EQ.3) WRITE(IOUNIT,230)
 230  FORMAT(/,'  *** LEAVE-BLOCK-OUT DIAGNOSTICS REQUESTED  ***')
      WRITE(IOUNIT,*)
C
C  *** PROCESS REGRESSION DIAGNOSTICS ***
C
      IF (IDR.EQ.0) RDR = 0
C
      IF (IDR.EQ.1) THEN
         RDR = 1
         LOO = 0
         IV85 = LRI1
         RHOI(LRI1) = 1
         IV86 = 0
         IV87 = 0
         IV90 = 0
         NRICHK = LUI + 1
         NRRCHK = 0
      ENDIF
C
      IF (IDR.EQ.2) THEN
         RDR = 2
         LOO = 1
         IV85 = LRI1
         RHOI(LRI1) = 1
         IV86 = 0
         IV87 = NOBS
         IV90 = LRR1
         NRICHK = LUI + NOBS
         NRRCHK = LUR + NOBS * NPAR
      ENDIF
C
C  *** INPUT FOR SPECIAL REGRESSION DIAGNOSTICS ***
C  *** BEGIN READING "INPUT BLOCK 2"            ***
C
      IF (IDR.EQ.3) THEN
         READ(1,*) BS, NB, XNOTI
C
         IF (BS.LT.0) THEN
            BS = 0
            WRITE(IOUNIT,240)
 240        FORMAT(/,'  *** NEGATIVE BLOCK-SIZE (BS) SET TO 0 ***',/)
         ENDIF
C
         IF (NB.LE.0) THEN
            WRITE(IOUNIT,250)
 250        FORMAT(/,'  *** INVALID NO. OF BLOCKS (NB).  STOP. ***',/)
            STOP
         ENDIF
C
         IF ((XNOTI.NE.0).AND.(XNOTI.NE.1)) THEN
            XNOTI = 0
            WRITE(IOUNIT,260)
 260        FORMAT(/,'  *** INVALID XNOTI SET TO 0. ***',/)
         ENDIF
         IF (XNOTI.EQ.1) WRITE(IOUNIT,220)
         WRITE(IOUNIT,270) NB
 270     FORMAT('  NUMBER OF BLOCKS:  ',I4)
C
         RDR = 2
         LOO = 2
         IV85 = LRI1
         IV86 = 0
         IV87 = NB
         IF (XNOTI.EQ.1) THEN
            IV90 = LRR1
            NRRCHK = LUR + NB * NPAR
         ENDIF
C
         IF (BS.GT.0) THEN
            WRITE(IOUNIT,280) BS
 280        FORMAT('  FIXED BLOCK SIZE:  ',I4,/)
            IF (BS*NB.NE.NOBS) THEN
               WRITE(IOUNIT,290)
 290           FORMAT(/,'  *** (BS * NB) .NE. NOBS.  STOP. ***',/)
               STOP
            ENDIF
            RHOI(LRI1) = BS
            NRICHK = LUI + 1
         ELSE
            IV86 = 1
            WRITE(IOUNIT,300)
 300        FORMAT('  VARIABLE BLOCK-SIZE OPTION CHOSEN',/)
            NRICHK = LUI + NB
         ENDIF
      ENDIF
C
C  *** CHECK SIZE OF RHOI ***
      IF (NRICHK.GT.LRHOI) THEN
         WRITE(IOUNIT,310)
 310     FORMAT('  *** STORAGE CAPACITY OF RHOI EXCEEDED.  STOP. ***')
         STOP
      ENDIF
C
C  *** IF VARIABLE-LENGTH BLOCKSIZES ARE USED, ***
C  *** READ THEM IN AND TEST THEM. ***
C
      IF (IV86.EQ.1) THEN
         READ(1,*) (RHOI(I),I=LRI1,NRICHK)
         WRITE(IOUNIT,320)
 320     FORMAT('  BLOCK-SIZES: ')
         WRITE(IOUNIT,330) (RHOI(I),I=LRI1,NRICHK)
 330     FORMAT(5X,15I5)
         WRITE(IOUNIT,*)
         ICHECK = 0
         DO 350 I = LRI1, NRICHK
            IF (RHOI(I).LE.0) THEN
               ICHECK = 1
               WRITE(IOUNIT,340) I-LUI
 340           FORMAT('    *** BLOCK-SIZE ',I5,' IS INVALID ***')
            ENDIF
            NBSCHK = NBSCHK + RHOI(I)
 350     CONTINUE
         IF (ICHECK.EQ.1) THEN
             WRITE(IOUNIT,360)
 360         FORMAT(/,'  *** CANNOT PROCEED WITH INVALID BLOCK-SIZES. ',
     1               'STOP. ***')
            STOP
         ENDIF
         IF (NBSCHK.NE.NOBS) THEN
             WRITE(IOUNIT,370)
 370         FORMAT(/,'  *** SUM OF BLOCK-SIZES .NE. NOBS.  STOP. ***')
            STOP
         ENDIF
      ENDIF
C
C  *** CHECK SIZE OF RHOR ***
      IF (NRRCHK.GT.LRHOR) THEN
         WRITE(IOUNIT,380)
 380     FORMAT('  *** STORAGE CAPACITY OF RHOI EXCEEDED.  STOP. ***')
         STOP
      ENDIF
C
C
C *** READ MNP PARAMETERS FROM INPUT BLOCK 3 ***
C
      READ(1,*) NALT, NATTR, IDUM, ICOV, ITASTE
C
      IF (ICSET.NE.0) THEN
         IF ((NALT.NE.0).AND.(NALT.NE.ICSET)) THEN
            WRITE(IOUNIT,390)
 390        FORMAT('  *** NOTE:  ERROR IN NALT OR ICSET ***')
            STOP
         ENDIF
         NALT = ICSET
         WRITE(IOUNIT,400)
 400     FORMAT('  *** NOTE:  NALT SET EQUAL TO ICSET ***')
      ENDIF
      IF (NALT.EQ.0) THEN
         WRITE(IOUNIT,410)
 410     FORMAT('  NO NOMINAL VARIABLES')
      ELSE
         WRITE(IOUNIT,420) NALT
 420     FORMAT('  NUMBER OF NOMINAL VARIABLES............',I4)
      ENDIF
C
      WRITE(IOUNIT,430) NATTR
 430  FORMAT('  NUMBER OF ATTRIBUTES PER ALTERNATIVE...',I4)
      IF (IDUM.EQ.0) THEN
         WRITE(IOUNIT,440)
 440     FORMAT('  NO NOMINAL DUMMIES')
      ELSE
         WRITE(IOUNIT,450)
 450     FORMAT('  NOMINAL DUMMIES USED')
      ENDIF
      IF (ICOV.EQ.0) THEN
         WRITE(IOUNIT,460)
 460     FORMAT('  IID ERROR TERMS')
      ELSE
         WRITE(IOUNIT,470)
 470     FORMAT('  CORRELATED ERROR TERMS')
      ENDIF
      IF (ITASTE.EQ.0) THEN
         WRITE(IOUNIT,480)
 480     FORMAT('  NO RANDOM TASTE VARIATION')
      ENDIF
      IF (ITASTE.EQ.1) THEN
         WRITE(IOUNIT,490)
 490     FORMAT('  UNCORRELATED RANDOM TASTE VARIATION')
      ENDIF
      IF (ITASTE.EQ.2) THEN
         WRITE(IOUNIT,500)
 500     FORMAT('  CORRELATED RANDOM TASTE VARIATION')
      ENDIF
C
      WRITE(IOUNIT,510) NPAR
 510  FORMAT(/,'  NUMBER OF MODEL PARAMETERS.............',I4,/)
C
C *** CHECK INITIAL DATA ***
C (ADD MORE ERROR CHECKING HERE?)
C
      IF (((IDUM.NE.0).OR.(ICOV.NE.0)).AND.(NALT.EQ.0)) THEN
         WRITE(IOUNIT,520)
 520     FORMAT(' *** ERROR WITH IDUM OR ICOV OR NALT OR ICSET ***')
         STOP
      ENDIF
C
C *** CHECK NPAR ***
C
      NPCHK = NATTR
      IF (IDUM.EQ.1) NPCHK = NPCHK + NALT - 1
      LCOVX = 0
      LCOVP = 0
      LCOVU = 0
      IF (ICOV.EQ.1) THEN
         LCOVX =  NALT*(NALT-1)/2 - 1
         NPCHK = NPCHK + LCOVX
         LCOVP =  NALT*(NALT+1)/2
         LCOVU =  NALT*NALT
      ENDIF
      IF (ITASTE.EQ.1) NPCHK = NPCHK + NATTR
      IF (ITASTE.EQ.2) NPCHK = NPCHK + NATTR*(NATTR+1)/2
      IF (NPAR.NE.NPCHK) THEN
                  WRITE(IOUNIT,*) ' NPCHK = ',NPCHK
          WRITE(IOUNIT,*) ' INCORRECT NUMBER OF MODEL PARAMETERS'
          STOP
      ENDIF
C
C *** READ INITIAL PARAMETER ESTIMATES FROM UNIT 1 ***
C
      WRITE(IOUNIT,530)
 530  FORMAT(' INITIAL PARAMETER VECTOR AND BOUNDS: ')
      DO 560 I = 1, NPAR
          READ(1,540) VNAME(I)
 540      FORMAT(1X,A8)
          READ(1,*) X(I), B(1,I), B(2,I)
              WRITE(IOUNIT,550) I, VNAME(I),X(I), B(1,I), B(2,I)
 550      FORMAT(1X,I2,1X,A8,2X,3(1X,E13.6))
 560  CONTINUE
      CLOSE(1)
C
C *** SET UP UI STORAGE POINTERS (FOR MLEPCM) ***
C
C NIUSER AND NRUSER ARE USED TO RESERVE STORAGE FOR THE USER.
C NIUSER AND NRUSER FOR MNP APPLICATION:
C
      NIUSER = 18
      LW = MAX(NATTR * NALT, LCOVP)
      NRUSER = LW + LCOVU + 2
C
C (SEE HOW UI AND UR ARE USED BELOW TO PASS MNP INFORMATION)
C
C  MLEPCM ARRAY POINTERS FOR UI:
      IIU = 11
      IICH = NIUSER + IIU
      INALT = IICH + NOBS
      IIIV = INALT + NOBS
      IIRV = IIIV + NOBS
      IICDAT = IIRV + NOBS
C
C  MLEPCM ARRAY POINTERS FOR UR:
      IRU = 1
      ICP = IRU + NRUSER
      IRW = ICP + 2*NOBS
      IRCDAT = IRW + NOBS
C
C  MLEPCM STORES POINTERS IN UI(1) THROUGH UI(10):
      UI(1) = IIU
      UI(2) = IICH
      UI(3) = INALT
      UI(4) = IIIV
      UI(5) = IIRV
      UI(6) = IICDAT
      UI(7) = IRU
      UI(8) = ICP
      UI(9) = IRW
      UI(10) = IRCDAT
C
C *** STORE MNP MODEL CONSTANTS STARTING IN IUSER(1) (=UI(11)) ***
C
C  STORAGE FOR PASSING INVOCATION COUNTS:
C     UI(11) = NF1 = IUSER(1)
C     UI(12) = NF2 = IUSER(2)
C
C  BASIC MNP MODEL INFORMATION:
      IUSER(3) = IOUNIT
      IUSER(4) = WEIGHT
      IUSER(5) = ICSET
      IUSER(6) = NALT
      IUSER(7) = NATTR
      IUSER(8) = IDUM
      IUSER(9) = ICOV
      IUSER(10) = ITASTE
C
C  X ARRAY POINTERS (POINT TO START POSITION - 1):
      II = 0
      IF (NATTR.NE.0) THEN
         IPCOEF = II
         II = II + NATTR
      ENDIF
      IF (IDUM.NE.0) THEN
         IPDUM = II
         II = II + NALT - 1
      ENDIF
      IF (ICOV.NE.0) THEN
         IPCOV = II
         II = II + LCOVX
      ENDIF
      IF (ITASTE.NE.0) IPTAST = II
C
      IUSER(11) = IPCOEF
      IUSER(12) = IPDUM
      IUSER(13) = IPCOV
      IUSER(14) = IPTAST
C
C  ETA0 POINTER:
      IETA0 = 1
      IUSER(17) = IETA0
C
C  SCALE POINTER:
      ISCALE = 2
      IUSER(18) = ISCALE
C
C  SIGMA (AND W) POINTERS:
      ISIGP = 3
C     IW = ISIGP (W AND SIGP SHARE THE SAME STORAGE)
      ISIGU = ISIGP + LW
C
      IUSER(15) = ISIGP
      IUSER(16) = ISIGU
C
C *** SET UP RUSER INFORMATION FOR MNP MODEL USE ***
C
C     SET ETA0 EQUAL TO MACHEP
C     (ETA0 IS USED BY FINITE-DIFFERENCE ROUTINE DS7GRD.)
      ETA0 = DR7MDC(3)
      UR(IETA0) = ETA0
C
C     (SCALE SETS THE SCALING OF THE PROBIT MODEL COVARIANCE MATRIX)
      SCALE = ONE
      UR(ISCALE) = SCALE
C
C *** READ THE REST OF THE DATA FROM UNIT 1 (GENERAL TO MLEPCM ) ***
C *** STORE IT IN THE APPROPRIATE UI AND UR LOCATIONS            ***
C
      IICDAT = IICDAT - 1
      IRCDAT = IRCDAT - 1
      DO 640 IOBS = 1, NOBS
         IF (ICSET.EQ.0) THEN
            READ(2,*) UI(IICH), UI(INALT)
            ICH = UI(IICH)
            IF ((ICH.LE.0).OR.(ICH.GT.NALT)) THEN
               WRITE(IOUNIT,570) IOBS, ICH
 570           FORMAT(1X,' CHOICE ERROR IN OBS. NO. ',
     1                I4,/,1X,'  CHOICE INDEX: ',/,5X,I3)
               WRITE(IOUNIT,580)
 580           FORMAT(' *** PROGRAM TERMINATED... ***')
               STOP
            ENDIF
            ITST = UI(INALT)
            IF ((ITST.LE.1).OR.(ITST.GT.NALT)) THEN
               WRITE(IOUNIT,590) IOBS,ITST
 590           FORMAT(1X,' CHOICE SET SIZE ERROR IN OBS. NO. ',
     1                I4,/,1X,'  CHOICE SET SIZE: ',/,5X,I3)
               WRITE(IOUNIT,580)
               STOP
            ENDIF
         ELSE
            READ(2,*) UI(IICH)
            ICH = UI(IICH)
            IF ((ICH.LE.0).OR.(ICH.GT.NALT)) THEN
               WRITE(IOUNIT,570) IOBS, ICH
               WRITE(IOUNIT,580)
               STOP
            ENDIF
            UI(INALT) = ICSET
         ENDIF
C
         IF (NIVAR.EQ.0) THEN
            READ(2,*) UI(IIIV), (UI(IICDAT+K),K=1,UI(IIIV))
         ENDIF
         IF (NIVAR.GT.0) THEN
            READ(2,*) (UI(IICDAT+K),K=1,NIVAR)
            UI(IIIV) = NIVAR
         ENDIF
C
C *** MNP CODE:  CHECK INTEGER VALUES FOR CORRECTNESS ***
C
         IF (NIVAR.GE.0) THEN
            DO 610 I = 1, UI(IIIV)
               ITST = UI(IICDAT+I)
               IF ((ITST.LE.0).OR.(ITST.GT.NALT)) THEN
                   WRITE(IOUNIT,600) IOBS,(UI(IICDAT+K),K=1,UI(IIIV))
 600                FORMAT(1X,' CHOICE SET INDEX ERROR IN OBS. NO. ',
     1                I4,/,1X,'  INTEGER VALUES: ',/,5X,20I3)
                   WRITE(IOUNIT,580)
                   STOP
               ENDIF
 610        CONTINUE
            IICDAT = IICDAT + UI(IIIV)
         ENDIF
C
         IF (IICDAT.GT.LUI) THEN
            WRITE(IOUNIT,620)
 620        FORMAT(/,' *** STORAGE CAPACITY OF UI EXCEEDED ***')
            STOP
         ENDIF
C
         IF (WEIGHT.EQ.1) THEN
            READ(2,*) UR(IRW)
         ELSE
            UR(IRW) = ONE
         ENDIF
         IF (ICSET.GT.1) MKTSHR(ICH) = MKTSHR(ICH) + UR(IRW)
         RLL0 = RLL0 + UR(IRW)*LOG(DBLE(UI(INALT)))
C
         IF (NRVAR.EQ.0) THEN
            READ(2,*) UI(IIRV), (UR(IRCDAT+K),K=1,UI(IIRV))
            IRCDAT = IRCDAT + UI(IIRV)
         ENDIF
         IF (NRVAR.GT.0) THEN
            READ(2,*) (UR(IRCDAT+K),K=1,NRVAR)
            UI(IIRV) = NRVAR
            IRCDAT = IRCDAT + NRVAR
         ENDIF
         IF (IRCDAT.GT.LUR) THEN
            WRITE(IOUNIT,630)
 630        FORMAT(/,' *** STORAGE CAPACITY OF UR EXCEEDED ***')
            STOP
         ENDIF
         IICH = IICH + 1
         INALT = INALT + 1
         IIIV = IIIV + 1
         IIRV = IIRV + 1
         IRW = IRW + 1
 640  CONTINUE
      CLOSE(2)
C
      CALL DIVSET(1, IV, LIV, LV, V)
C
C  *** SET REGRESSION DIAGNOSTIC CONSTANTS
      IV(83) = NFIX
      IV(84) = LOO
      IV(85) = IV85
      IV(86) = IV86
      IV(87) = IV87
      IV(88) = 0
      IV(89) = 0
      IV(90) = IV90
C
C     IV(RDREQ) = 1 + 2*RDR
      IV(57) = 1 + 2*RDR
C
C     IV(COVPRT) = 3
      IV(14) = 5
C
C     SET IV(COVREQ)
      IF (COVTYP.EQ.1) IV(15) = -2
      IF (COVTYP.EQ.2) IV(15) = 3
C
C--------------------------------------------------------------------
C   THE FOLLOWING COMMENTED-OUT CODE COULD BE USED TO ALTER
C   CONVERGENCE TOLERANCES:
C   (EXAMPLE:  CALCULATE TOLERANCES AS THOUGH MACHEP WERE THE
C      SQUARE ROOT OF THE ACTUAL MACHEP)
C     MACHEP = SQRT(ETA0)
C     MEPCRT = MACHEP *** (ONE/THREE)
C     V(RFCTOL) = MAX(1.D-10, MEPCRT**2)
C     V(SCTOL) = V(RFCTOL)
C     V(XCTOL) = SQRT(MACHEP)
C
C     WRITE(IOUNIT,650) V(RFCTOL), V(XCTOL)
C650  FORMAT(//,'  Relative F-Convergence tolerance: ',d13.6,/,
C    1            '  Relative X-Convergence tolerance: ',d13.6,//)
C--------------------------------------------------------------------
C
      IF (IV(1).NE.12) THEN
         WRITE(IOUNIT,*) ' There was a problem with calling DIVSET'
         STOP
      ENDIF
C
C  *** SET MODE TO FIXED, UNIT SCALING IN OPTIMIZATION ***
C  *** IV(DYTYPE) = IV(16) = 0.  V(DINIT) = V(38) = 1. ***
      IV(16) = 0
      V(38) = ONE

C  *** THERE ARE NO "NUISANCE PARAMETERS" IN THIS IMPLEMENTATION ***
      NPS = NPAR
C
C *** ALLOCATE STORAGE AND OPTIMIZE
C
       CALL DGLG(NOBS, NPAR, NPS, X, PCMRHO, RHOI, RHOR, IV, LIV, LV, V,
     1     PCMRJ, UI, UR, MECDF)
C--------------------------------------------------------------------
C  *** COMPUTE ASYMPTOTIC T-STATISTICS ***
C
      IH = ABS(IV(26)) - 1
      IF (IH.GT.0) THEN
         DO 660 I = 1, NPAR
            IH = IH + I
            STDERR(I) = SQRT(V(IH))
            IF (STDERR(I).GT.0) THEN
               TSTAT(I) = X(I)/STDERR(I)
            ELSE
               STDERR(I) = ZERO
               TSTAT(I) = ZERO
            ENDIF
 660     CONTINUE
C
         WRITE(IOUNIT,670)
 670     FORMAT(/,' ASYMPTOTIC T-STATISTICS: ',/,
     1                  2X,'I',16X,'X(I)'11X,'T-STAT(I)',
     2                  7X,'STD ERROR')
C
         DO 690 I = 1, NPAR
            WRITE(IOUNIT,680) I, VNAME(I), X(I), TSTAT(I), STDERR(I)
 680        FORMAT(1X,I2,2X,A8,2X,E13.6,2(3X,E13.6))
 690     CONTINUE
      ENDIF
C
      RLLR = TWO*(RLL0 - V(10))
      WRITE(IOUNIT,700) NOBS, -V(10), -RLL0, RLLR
 700  FORMAT(/,' NUMBER OF OBSERVATIONS (NOBS) = ',I4,//,
     1         ' LOG-LIKELIHOOD L(EST)  = ',E13.6,/,
     1         ' LOG-LIKELIHOOD L(0)    = ',E13.6,/,
     1         ' -2[L(0) - L(EST)]:     = ',E13.6,/)
C
      IF (WEIGHT.EQ.0) THEN
         RHOSQR = ONE - V(10)/RLL0
         RSQHAT = ONE - (V(10)+NPAR)/RLL0
         WRITE(IOUNIT,710) RHOSQR, RSQHAT
 710     FORMAT(' 1 - L(EST)/L(0):       = ',E13.6,/,
     1           ' 1 - (L(EST)-NPAR)/L(0) = ',E13.6,/)
      ELSE
         WRITE(IOUNIT, 720)
 720     FORMAT(' WEIGHTS USED:  RHO-SQUARES NOT REPORTED.',/)
      ENDIF

      IF (ICSET.GT.1) THEN
         WRITE(IOUNIT,730)
 730     FORMAT(' (FIXED CHOICE SET SIZE)',//,
     1          ' AGGREGATE CHOICES AND MARKET SHARES: ')
         IF (WEIGHT.EQ.1) WRITE(IOUNIT,740)
 740     FORMAT(' (WEIGHTED)')
         RLLC = ZERO
         RNOBS = NOBS
         DO 760 I = 1, ICSET
            RNI = MKTSHR(I)
            RFI = RNI/RNOBS
            IF (RFI.GT.ZERO) RLLC = RLLC + RNI*LOG(RFI)
            WRITE(IOUNIT,750) I, MKTSHR(I), RFI
 750        FORMAT(1X,I3,2X,F10.3,2X,F6.4)
 760     CONTINUE
         RLLR = TWO * (-RLLC - V(10))
         WRITE(IOUNIT, 770) RLLC, RLLR
 770     FORMAT(/,' STATISTICS FOR CONSTANTS-ONLY MODEL:',/,
     1         '    LOG-LIKELIHOOD L(C)    = ',E13.6,/,
     1         '    -2[L(C) - L(EST)]:     = ',E13.6,/)
      ENDIF
C
      IF (IPRNT.EQ.1)
     1   CALL FPRINT(NOBS, NPAR, X, NF, UI, UR, MECDF)
C
      WRITE(IOUNIT,780)
 780  FORMAT(//,' OUTPUT FOR CONVENIENT RESTART:')
      DO 800 I = 1, NPAR
         WRITE(IOUNIT,540) VNAME(I)
         WRITE(IOUNIT,790) X(I), B(1,I), B(2,I)
 790     FORMAT(1X,3(1X,E13.6))
 800  CONTINUE
C *** LAST LINE OF MLMNP FOLLOWS ***
      END