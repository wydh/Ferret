	SUBROUTINE CREATE_PERMUTATION( cx, msrc, perm, mdst, do_shrink,
     .				       status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
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
* create a memory-resident variable from input data, msrc, using region limits
* from context cx permuted into the order specified by array perm
* To optimize speed pre-test to see if the input data is already suitably
* organized
* -- flag the result as temporary

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  9/1/89
* V312: 5/94 - array "memory" as a calling argument
* V530:  8/00 *sh* - partial implementation of permuting string arrays
*		("table only")
*v580  *acm* 11/04 transfer cx_cal_id, the calendar ID used when  
*                  computing world coordinates
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* V702 1/17 *sh* for trac enhancement #2369 -- dynamic memory management 

* ... Ticket 1480: When writing to netCDF, check whether the region 
*     on modulo axes is just one grid-cell longer than the axis length,
*     e.g. if they give a region of /X=0:360.  If so, write one grid-cell 
*     less data.so the axis can still be a valid modulo axis.

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'errmsg.parm'
	include 'xvariables.cmn'
	include 'xcontext.cmn'

* calling argument declarations:
	LOGICAL do_shrink
	INTEGER	cx, msrc, perm(nferdims), mdst, status

* internal variable declarations:
	LOGICAL	table_entry_only
	INTEGER nsrc, ndst, idim, dim, prm, 
     .		src_len(nferdims), dst_len(nferdims),
     .          src_ax(nferdims),  dst_ax(nferdims)

* initialize
	table_entry_only = .FALSE.

* test if any action is necessary
* ... it is unnecessary if all dimensions with length greater than 1 are
* the same length and in the same order in the source data as in the requested
* permutation, or if there is more than one dimension in the grid and a dimension
* is shrunk.
* (Note: msrc regions always span cx regions)
* Compute src_len and dst_len - the non-unity axis lengths in the source and
* destination data
	nsrc = 0
	DO 200 idim = 1, nferdims
	   dim = mr_hi_ss(msrc,idim) - mr_lo_ss(msrc,idim)
	   IF ( dim .GT. 0 ) THEN
	      nsrc = nsrc + 1
	      src_ax (nsrc) = idim
	      src_len(nsrc) = dim
	   ENDIF
 200	CONTINUE
	ndst = 0
	DO 210 idim = 1, nferdims
	   prm = perm(idim)
	   dim = cx_hi_ss(cx,prm) - cx_lo_ss(cx,prm)
	   IF ( dim .GT. 0 ) THEN
	      ndst = ndst + 1
	      dst_ax (ndst) = prm
	      dst_len(ndst) = dim
	   ENDIF
 210	CONTINUE

* must "extract" data if the source data is a larger object than the request
* must permute if the axis ordering is different
	IF ( nsrc .NE. ndst ) GOTO 500
	DO 250 idim = 1, nsrc
	   IF ( dst_len(idim) .NE. src_len(idim)
     .	  .OR.  dst_ax (idim) .NE. src_ax (idim) ) GOTO 500
 250	CONTINUE

* no actual permutation of values is necessary
* see if a dummy mr table entry is needed to represent the permutation
	DO 300 idim = 1, nferdims
	   IF ( perm(idim) .NE. idim ) THEN
	      table_entry_only = .TRUE.
	      GOTO 500
	   ENDIF
 300	CONTINUE

	IF (do_shrink) GOTO 500

* dimensions have not been permuted nor are context region sizes < stored data
	status = ferr_ok
	mdst = msrc
	RETURN

* need a dummy entry

* create a permuted context
 500	CONTINUE
	
	DO 510 idim = 1,nferdims
	   prm = perm(idim)
	   cx_lo_ss ( cx_buff, idim )   = cx_lo_ss ( cx, prm )
	   cx_hi_ss ( cx_buff, idim )   = cx_hi_ss ( cx, prm )
	   cx_lo_ww ( idim, cx_buff )   = cx_lo_ww ( prm, cx )
	   cx_hi_ww ( idim, cx_buff )   = cx_hi_ww ( prm, cx )
	   cx_trans ( idim, cx_buff )   = cx_trans ( prm, cx )
	   cx_by_ss ( idim, cx_buff )   = cx_by_ss ( prm, cx )
	   cx_given ( idim, cx_buff )   = cx_given ( prm, cx )
	   cx_delta ( idim, cx_buff )   = cx_delta ( prm, cx )
	   cx_trans_arg(idim, cx_buff)  = cx_trans_arg(prm, cx)
	   cx_regrid_trans(idim,cx_buff)=cx_regrid_trans(prm,cx)
 510	CONTINUE

	cx_data_set( cx_buff ) = cx_data_set( cx )
	cx_dset_gvn( cx_buff ) = cx_dset_gvn( cx )
	cx_category( cx_buff ) = cx_category( cx )
	cx_variable( cx_buff ) = cx_variable( cx )
	cx_grid    ( cx_buff ) = cx_grid    ( cx )
	cx_type    ( cx_buff ) = cx_type    ( cx )
	cx_ovsiz   ( cx_buff ) = cx_ovsiz   ( cx )
	cx_bad_data( cx_buff ) = cx_bad_data( cx )
        cx_cal_id  ( cx_buff ) = cx_cal_id  ( cx )

	cx_unstand_grid( cx_buff ) = cx_unstand_grid( cx )

* create a memory space for the result
	CALL CREATE_TEMP_MEM_VAR( cx_buff, mdst, status )
	IF ( status .NE. ferr_ok ) RETURN

* permute or kludge around permuting the data
	IF ( table_entry_only .AND. .NOT.do_shrink) THEN
! DSGTBD - cleaner to use the new routine CREATE_TABLE_ONLY_MEM_VAR
!   instead of allocating memory and then freeing it up afterwards
!   still need to copy mr_c_pointer here, presumably
* ... point to the original data using permuted limits
* ... a duplicated pointer, only 
*     mr_size of the table-entry-only mr will be zero
*     total_mem need not be adjusted cuz no actual new memory is involved
	   essential_mem = essential_mem - mr_size(mdst)
	   CALL FREE_MR_DYNMEM( mdst )
	   memry(mdst)%ptr => memry(msrc)%ptr

	   mr_c_pointer(mdst) = mr_c_pointer(msrc)
	   mr_protected(mdst) = mr_table_entry_only
	ELSE
* ... permute the data
	   CALL PERMUTE( cx, memry(msrc)%ptr, msrc,
     .			     memry(mdst)%ptr, mdst, perm )
	ENDIF

	RETURN
	END
