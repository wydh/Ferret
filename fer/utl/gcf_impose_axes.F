	SUBROUTINE GCF_IMPOSE_AXES( cx_base, mrg_cx, uvar, status )

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
* at this point a grid has been determined which lacks only those
* axes which are to be imposed by a grid changing variable. This routine
* completes that grid and the uvar_given associated with it.

* V4500: 10/98 - *jc* logic for context passing
* V450: 1/97
* V510: *sh* 12/99 - bug fixes to uvar_given associated with GC variables
*	- 1) imposing an axis always makes limits on that axis uvlim_irrelevant
*	- 2) context limits on axes that do inherit must match exactly (cuz
*			we have no idea what goes on inside the EF)
*	*sh*  4/00 - all axes now maintain use counts, not just dynamic
* V533: *sh* 7/01 - improve caching of some functions -- like SPAWN that
*	            should have uvlim_hidden behavior equivalent to FFTA
*       *acm* 3/12 Add E and F dimensions (use nferdims in tmap_dims.parm)
* V697  12/15 *acm* Changes to add details on SHOW GRID uvar to indicate 
*                   compressed or subset of axes
* V740   4/18 *acm* Issue 1867: Restore pre-3/17 behavior for RESHAPE - 
*                   previous code change may have been an unintended checkin

        IMPLICIT NONE
	include 'tmap_dims.parm'
	include	'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'ferret.parm'
	include 'grid_chg_fcns.parm'
	include 'errmsg.parm'
	include	'xcontext.cmn'
	include	'xvariables.cmn'
	include 'xgrid_chg_fcns.cmn'

* calling argument declarations
	INTEGER		cx_base, mrg_cx, uvar, status

* local variable declarations
	INTEGER WHICH_GCFCN
	INTEGER	gcfcn, idim, imp_ax, mrg_ax, mrg_grd, uvg,
     .		axis_source(nferdims), imposed_axes(nferdims), 
     .		axis_reduction(nferdims)


* initialize
* which grid changing variable?
	gcfcn = WHICH_GCFCN(uvar)

* which axes are involved?
	CALL GCF_GET_AXIS_SRCS( gcfcn, 1, axis_source )

* get the axis_reduction information
	IF ( gcfcn .GT. gfcn_num_internal ) THEN
       CALL EFCN_GET_AXIS_REDUCTION(gcfcn, axis_reduction)
	ENDIF

* get the replacement axes
	CALL GCF_GET_IMPOSED_AXES( gcfcn, cx_base, imposed_axes,
     .       status )
	IF ( status .NE. ferr_ok ) GOTO 5000

* get the current grid
	mrg_grd = cx_grid( mrg_cx )


* loop through the axes
	DO 500 idim = 1, nferdims

	   mrg_ax  = grid_line ( idim, mrg_grd )

	   IF (    axis_source(idim).EQ.pgc_ignore_axis) THEN
	      GOTO 500
	   ELSEIF (axis_source(idim).EQ.pgc_impose_axis) THEN
	      imp_ax = imposed_axes(idim)
* ... since new axis is imposed old axis need not be allocated to result
	      CALL TM_USE_LINE(imp_ax)
	      CALL TM_DEALLO_DYN_LINE(mrg_ax)
	      grid_line( idim, mrg_grd ) = imp_ax
* ... imposing an axis implies that the gcvar doesn't depend on the axis cx
	      IF ( imp_ax .EQ. mnormal ) THEN
	         uvar_given(idim,uvar) = uvlim_irrelevant
	      ELSEIF ( gcfcn .GT. gfcn_num_internal ) THEN
	         uvar_given(idim,uvar) = uvlim_hidden	! 12/99
	      ELSEIF ( gcfcn .EQ. p_spawn ) THEN
	         uvar_given(idim,uvar) = uvlim_hidden   ! 7/01
	      ELSE
* ... allows XSEQUENCE, etc. context to be determined w/out full evaluation
*     This can make some scripts more efficient ... others maybe less because
*     uvlim_hidden would make caching more effective.  Example like
*       "let a = XSEQUENCE(J[j=1:5]); say `a[i=100:200],return=isize`"
*     can actually yield a wrong answer
	         uvar_given(idim,uvar) = uvlim_needed ! for fcns like RESHAPE
	      ENDIF
	   ELSE
* ... it is evidently, a mergible axis ... continue on
	      CONTINUE
	   ENDIF	      

* For grid-changing functions (that may perform operations analagous to
* averaging) a cache hit requires an exact match on all relevant limits
* (Note: this is over-kill for some functions, but has
* impacts only on cache efficiency)

c For SHOW GRID with details e.g. compressed axes or subsets these settings
c wind up returning result of COMPRESSED for axes unaffected by the function.
c add logic to change uvar_given only when the gcf changes the axis. 

           IF ( gcfcn .GT. gfcn_num_internal ) THEN
	      IF (axis_source(idim) .EQ. pgc_impose_axis) THEN
                 uvg = uvar_given(idim,uvar)
                 IF (    uvg.GE.uvlim_gvn_gnl    .AND.
     .                uvg.LE.uvlim_gvn_xact) THEN
                    uvar_given(idim,uvar) = uvlim_gvn_xact
                 ELSEIF (uvg.GE.uvlim_needed .AND.
     .                   uvg.LE.uvlim_need_xact) THEN
                    uvar_given(idim,uvar) = uvlim_need_xact
                 ENDIF
	      ENDIF
           ENDIF

 500	CONTINUE

* successfully merged
	status = ferr_ok
	RETURN

* error exit
 5000	RETURN
	END
