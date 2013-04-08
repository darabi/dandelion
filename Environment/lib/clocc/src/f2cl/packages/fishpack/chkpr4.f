      SUBROUTINE CHKPR4(IORDER,A,B,M,MBDCND,C,D,N,NBDCND,COFX,IDMN,IERR
     1OR)
      EXTERNAL COFX
C
C     THIS PROGRAM CHECKS THE INPUT PARAMETERS FOR ERRORS
C
C
C
C     CHECK DEFINITION OF SOLUTION REGION
C
      IERROR = 1
      IF (A.GE.B .OR. C.GE.D) RETURN
C
C     CHECK BOUNDARY SWITCHES
C
      IERROR = 2
      IF (MBDCND.LT.0 .OR. MBDCND.GT.4) RETURN
      IERROR = 3
      IF (NBDCND.LT.0 .OR. NBDCND.GT.4) RETURN
C
C     CHECK FIRST DIMENSION IN CALLING ROUTINE
C
      IERROR = 5
      IF (IDMN .LT. 7) RETURN
C
C     CHECK M
C
      IERROR = 6
      IF (M.GT.(IDMN-1) .OR. M.LT.6) RETURN
C
C     CHECK N
C
      IERROR = 7
      IF (N .LT. 5) RETURN
C
C     CHECK IORDER
C
      IERROR = 8
      IF (IORDER.NE.2 .AND. IORDER.NE.4) RETURN
C
C     CHECK INTL
C
C
C     CHECK THAT EQUATION IS ELLIPTIC
C
      DLX = (B-A)/FLOAT(M)
      DO  30 I=2,M
         XI = A+FLOAT(I-1)*DLX
         CALL COFX (XI,AI,BI,CI)
      IF (AI.GT.0.0) GO TO 10
      IERROR=10
      RETURN
   10 CONTINUE
   30 CONTINUE
C
C     NO ERROR FOUND
C
      IERROR = 0
      RETURN
      END