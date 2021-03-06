	SUBROUTINE INIT_CONTEXT_MODS ( cx )

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
* prepare a clean,empty cx to receive a list of modifications

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - ????
* revision 0.1 -  4/1/89  - added regridding transformations
* V200:  6/28/89 - 4D symmetrical - init trans_arg, too, eliminate %%_relative
*		 - init cx_dset_gvn, cx_grid_needs_dset
* V420: 9/8/95 - added initializations for implicit grid creation
* 
*       8/97 *kob* - initalize cx_calendar - used to indicate whether a date
*                    contains a string 
* V510 *sh* - added cx_formatted
*       *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)
* V685 3/2013 *sh* initialize auxiliary regrid variable info
* V695  *acm* 2/15 cx_calendar stores info about calendar formatting of T and F axes

        IMPLICIT NONE
	include 'tmap_dims.parm'
	include	'ferret.parm'
	include	'xcontext.cmn'

* calling argument declarations:
	INTEGER	cx

* internal variable declarations:
	INTEGER	idim, ivar

* initialize everything but region
	cx_variable( cx ) = unspecified_int4
	cx_category( cx ) = unspecified_int4
	cx_data_set( cx ) = unspecified_int4
	cx_dset_gvn( cx ) = .FALSE.
	cx_grid( cx )     = unspecified_int4
	cx_unstand_grid( cx )  = .FALSE.
	cx_has_impl_grid( cx ) = .FALSE.
	cx_grid_needs_dset     = .FALSE.
	
* initialize region
* note: ss specifications are not used in storing modifications
	DO 100 idim = 1, nferdims
	   cx_lo_ss ( cx, idim )  = unspecified_int4
	   cx_hi_ss ( cx, idim )  = unspecified_int4
	   cx_calendar(idim,cx)   = .FALSE.
	   cx_lo_ww ( idim, cx )  = unspecified_val8
	   cx_hi_ww ( idim, cx )  = unspecified_val8
	   cx_delta ( idim, cx )  = unspecified_val8
	   cx_trans ( idim, cx )  = trans_no_transform
	   cx_trans_arg  ( idim, cx ) = bad_val4
	   cx_by_ss      ( idim, cx ) = .FALSE.	!for bookkeeping
	   cx_given      ( idim, cx ) = .FALSE.
	   cx_aux_given  ( idim, cx ) = .FALSE.
	   cx_aux_stat   ( idim, cx ) = paux_stat_na
	   cx_regrid_trans(idim, cx ) = unspecified_int4 
	   cx_formatted( idim )	  = .FALSE.
100	CONTINUE

* initialize info about auxiliary regridding variables
	cx_naux( cx ) = 0
	DO 200 ivar = 1, nferdims
	   cx_aux_var  (ivar, cx) = unspecified_int4
	   cx_aux_cat  (ivar, cx) = unspecified_int4
 200	CONTINUE


	RETURN
	END
