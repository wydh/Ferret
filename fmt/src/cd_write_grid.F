	SUBROUTINE CD_WRITE_GRID ( cdfid, dset, grid, lo, hi, recdim, 
     .                           itsa_slab, gname, edges_flag, 
     .                           do_bounds, mode_upcase_output, 
     .                           keepax_flag, date_fmt_out, status )

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
* Write a grid definition out to the current output netCDF file

* Programmer Steve Hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* revision 0.0 - 3/92
*               10/92 - put into netCDF into define mode before writing attribs
*		1/95  - change in "parent" argument to cd_write_axis (now int)
*   11/95 - *sh* use CD_AXIS_NAME rather than line_name for dynamic lines
*    2/96 - *sh* same deal for dynamic grids ... a quick fix right here
* v500 *kob*  3/99 - change lengths of CD_CHILDAX_NAME, CD_AXIS_NAME,
*                    lname to 64 from 24 to match longer line_name
* v570 *acm*  6/04 - changes to use bounds attribute
* V602 *acm* 11/06 - Fix bug 1471; new routine CD_AXIS_OUTNAME gets correct 
*                    output axis name.
* V62  *acm*  2/09 - Fix bug 1634: allow SAVE/KEEP_AXISNAMES so that child axis names
*                    arent written. They can get too long for OPeNDAP library calls
* V65  *acm* 1/10  Change all netcdf2-style calls and parameter names to 
*                  netcdf3-style calls, which are also consistent with netcdf4.
* V65  *acm* 1/10  Add #ifdef usingDODSf2cUnderscore, for 32-bit linux build
*                  linked with OPeNDAP library.
* V67  *acm* 3/11  Fix bug 1750. Revert to older behavior: if grid uses same axis
*                  name but different contents, write both to file with the name
*                  Ferret uses internally.
* V674 2/12 *acm* 6D Ferret: use nferdims rather than 4 for dimension indexing
* V685 6/13 *acm* new qualifier SAVE/NOBOUNDS
* V685 6/13 *acm* Dont add SAVE/NOCOORDS
* V687 3/14 *acm* Fix ticket 1750. Write Ferret-internal axis names to cdf files, unless
*                 the user has said /KEEP_AXISNAMES
* V69+ 4/14 *acm* After the above fix, need a tweak to be able to append to files having 
*                 dimensions that are not coordinate variables
* V710 9/16 *acm* Use ww_dim_name from xtext_info.cmn
* v745 *acm* 12/18 Issue 1909, option to write dates in ISO8601 format

* argument definitions:
*     cdfid   - netCDF id number for already opened CDF file
*     grid    - TMAP grid id
*     lo      - low indices of variable hyperslab
*     hi      - high indices of variable hyperslab
*     recdim  - which axis (1-4) is to be the CDF record axis
*     itsa_slab- does the underlying variable need a formal grid defn
*     gname   - the name of the parent grid created
*     status  - return status

* include files
        include 'netcdf.inc'
	include 'tmap_errors.parm'
	include 'tmap_dims.parm'
        include 'cdf_tmap.parm'
#include "gt_lib.parm"
        include 'cd_lib.parm'
	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'xtext_info.cmn'  ! with ww_dim_name

! Declare netcdf function names. 
! The ones without trailing underscore are declared in netcdf.inc
#include "netcdf_declareUnderscore.inc"

* argument declarations
      LOGICAL itsa_slab, mode_upcase_output
      INTEGER cdfid, dset, grid, lo(nferdims), hi(nferdims), recdim, 
     .        edges_flag, keepax_flag, date_fmt_out, do_bounds, status
      CHARACTER*(*) gname

* local variable declarations:
      LOGICAL gmod, name_from_grid, dim_only
      INTEGER TM_LENSTR1, 
     .        defid, defdim, nlen, slen, cdfstat, iaxis, idim, glen, i
      CHARACTER CD_CHILDAX_NAME*132, CD_AXIS_OUTNAME*132, CD_AXIS_NAME*132,
     .		names*132, lname*132

* are the axes, alone, enough of a grid definition
      IF ( .NOT.itsa_slab ) GOTO 100

* put CDF into define mode so attributes can be written
      CALL CD_SET_MODE(cdfid, pcd_mode_define, status)
      IF ( status .NE. merr_ok ) RETURN

* create "grid_definition" dimension name if not already in the file
       	cdfstat = NF_INQ_DIMID( cdfid, 'grid_definition', defdim)
      IF ( cdfstat .NE. NF_NOERR ) cdfstat = NF_DEF_DIM 
     .     ( cdfid, 'grid_definition', 1, defdim )


* create an output grid name that reflects axes which have been averaged, etc.
* and a string with a list of the axis names (starting w/ 2 blanks)
      gname = grid_name(grid)
      glen = TM_LENSTR1( gname )
! 2/96 - strip parentheses from dynamic grid name
      IF ( gname(1:1).EQ.'(' .AND. glen.GT.2 ) THEN
	gname = gname(2:glen-1)
	glen = glen - 2
      ENDIF
! 2/96 - end of insertion
      gmod = .FALSE.
      names = ' '
      nlen = 1
      DO 50 idim = 1, nferdims
         iaxis = grid_line(idim, grid)

         lname = CD_AXIS_NAME( dset, grid, idim, slen )
         IF (keepax_flag .EQ. 1)  lname = 
     .        CD_AXIS_OUTNAME( dset, grid, idim, slen )

         IF ( iaxis .EQ. mpsnorm ) THEN
            names = names(:nlen)//' '//'NORMAL'
         ELSEIF ( lo(idim) .EQ. unspecified_int4 ) THEN
            names = names(:nlen)//' '//'NORMAL'
            IF ( gmod ) THEN
               gname = gname(:glen)//ww_dim_name(idim)
               glen = glen + 1
            ELSE
               gname = gname(:glen)//'_N'//ww_dim_name(idim)
               gmod = .TRUE.
               glen = glen + 3
            ENDIF

         ELSEIF ( lname .EQ. 'ABSTRACT' .AND. (keepax_flag.EQ.0)) THEN
            names = names(:nlen)//' '//
     .           CD_CHILDAX_NAME( ww_dim_name(idim)//'AX',
     .                            lo(idim), hi(idim), i )
         ELSE
            names = names(:nlen)//' '//lname
         ENDIF
         nlen = TM_LENSTR1(names)
 50   CONTINUE

* does this grid already exist ? (no consistency check if so)
      cdfstat = NF_INQ_VARID ( cdfid, gname(:glen), defid )
      IF ( cdfstat .EQ. NF_NOERR ) GOTO 1000

* create a dummy variable for this grid definition
      cdfstat = NF_DEF_VAR ( cdfid, gname(:glen), NF_CHAR, 1,
     .                defdim, defid )

* write the axis list as an attribute of the grid
      cdfstat = NF_PUT_ATT_TEXT ( cdfid, defid, 'axes', nlen-2,
     .             names(3:))

* create the parent axes
 100  DO 200 idim = 1, nferdims
         IF ( grid_line(idim, grid) .NE. mpsnorm
     .  .AND. lo(idim) .NE. unspecified_int4     ) THEN
            CALL CD_WRITE_AXIS( cdfid, dset, grid, idim, 
     .           idim.EQ.recdim,
     .           lo(idim), hi(idim), pcdf_full_span, 
     .           edges_flag, do_bounds, mode_upcase_output,
     .           keepax_flag, name_from_grid, dim_only,
     .           date_fmt_out, status ) 

            IF ( status .NE. merr_ok ) GOTO 5900
         ENDIF
 200  CONTINUE

* successful completion
 1000 status = merr_ok
      RETURN

* error exit
 5900   RETURN
	END
