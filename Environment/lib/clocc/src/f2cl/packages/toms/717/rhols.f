      SUBROUTINE RHOLS(NEED, F, N, NF, XN, R, RP, UI, UR, W)
C
C *** LEAST-SQUARES RHO ***
C
      INTEGER NEED(2), N, NF, UI(1)
      DOUBLE PRECISION F, XN(*), R(N), RP(N), UR(1), W(N)
C
C *** EXTERNAL FUNCTIONS ***
C
      EXTERNAL DR7MDC, DV2NRM
      DOUBLE PRECISION DR7MDC, DV2NRM
C
C *** LOCAL VARIABLES ***
C
      INTEGER I
      DOUBLE PRECISION HALF, ONE, RLIMIT, ZERO
      DATA HALF/0.5D+0/, ONE/1.D+0/, RLIMIT/0.D+0/, ZERO/0.D+0/
C
C *** BODY ***
C
      IF (NEED(1) .EQ. 2) GO TO 20
      IF (RLIMIT .LE. ZERO) RLIMIT = DR7MDC(5)
C     ** SET F TO 2-NORM OF R **
      F = DV2NRM(N, R)
      IF (F .GE. RLIMIT) GO TO 10
      F = HALF * F**2
      GO TO 999
C
C     ** COME HERE IF F WOULD OVERFLOW...
 10   NF = 0
      GO TO 999
C
 20   DO 30 I = 1, N
         RP(I) = ONE
         W(I) = ONE
 30      CONTINUE
 999  RETURN
C *** LAST LINE OF RHOLS FOLLOWS ***
      END
