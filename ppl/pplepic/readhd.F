      SUBROUTINE READHD(ITAPEI,ITAPEO,NCAST,NDATA,NCAST1,IPRNT,
     1IWRITE,EXKEEP)
*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
C**    @(#)readhd.f	1.1    3/10/88
C**
C**
C***********************************************************************        C**
C**                 EPIC
C**
C***********************************************************************        C**
C**
C  THIS SUBROUTINE WILL CALL FIRSTHDR TO READ IN A HEADER FROM TAPE
C  ITAPEI, AND WILL CONTINUE TO READ IN HEADERS AS LONG AS THE 'HEADER
C  FOLLOWING' FLAG IS SET (LINE 2 COL 79). IF IPRNT IS TRUE, ALL 
C  HEADERS WILL BE WRITTEN TOP OUTPUT TAPE 6. IF IWRITE IS TRUE, THE
C  FIRST HEADER WILL BE WRITTEN TO TAPE ITAPEO
C
C  WRITTEN 10/84 BY M. VERSCHELL
C
      LOGICAL IPRNT,IWRITE,EXKEEP
      CHARACTER*80 HEADER(8),BUFFER(8)
      COMMON /COMHDR/ HEADER
      COMMON /DUMMY/BUFFER
      CHARACTER*1 BLANK
      DATA BLANK/' '/
C
C  READ IN FIRST HEADER, REPEAT UNTIL REQUESTED CAST (NCAST1) IS FOUND
C
  100 CALL FRSTHD(ITAPEI,NCAST,NDATA)
      IF ((NCAST .NE. NCAST1).AND.(NCAST1 .NE. 0)) THEN
  150   IF (HEADER(2)(79:79).EQ.'N') THEN
          READ (ITAPEI,END=175) HEADER(1)
          GOTO 190
  175     READ (ITAPEI) HEADER(1)
  190     DO 195 J=2,8
          READ (ITAPEI) HEADER(J)
  195     CONTINUE 
          GOTO 150
        ELSE
          DO 197 I=1,NDATA
            READ(ITAPEI,END=197) DUM
  197     CONTINUE
        ENDIF
        GOTO 100
      ENDIF
C
C  PRINT OR WRITE IT OUT AS REQUESTED
C
      IF (IPRNT) WRITE(6,200) NCAST,NDATA,(HEADER(I),I=1,8)
CCCC  BUG IN CODE ... 200 FORMAT(1X,'NCAST='I3,'  NDATA=',I5/8(1X,A80/)/)
  200 FORMAT(1X,'NCAST=',I3,'  NDATA=',I5/8(1X,A80/)/)
      IF (IWRITE) THEN
        DO 300 I=1,8
          IF ((.NOT.EXKEEP).AND.(I.EQ.2)) THEN
            WRITE (ITAPEO) HEADER(I)(1:78),BLANK,HEADER(I)(80:80)
          ELSE
            WRITE (ITAPEO) HEADER(I)
          ENDIF
  300   CONTINUE
      ENDIF
C
C  IF N FLAG SET READ IN NEXT HEADER
C
      IF (HEADER(2)(79:79).EQ.'N') THEN
  400   CALL NXTHDR(ITAPEI)
        IF (IPRNT) WRITE (6,200) (BUFFER(I),I=1,8)
        IF ((EXKEEP).AND.(IWRITE)) THEN
          DO 500 I=1,8
            WRITE (ITAPEO) HEADER(I)
  500     CONTINUE
        ENDIF
        IF (BUFFER(2)(79:79).EQ.'N') GOTO 400
      ENDIF
      RETURN
      END
