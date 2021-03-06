	SUBROUTINE EZ_UPDATE_VAR( var )
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
*
* Subroutine will update the XDSET and XSTEP common entries for a single
* variable of an EZ_ data set
*
* revision 0.00 - 10/24/89 - extracted from EZ_UPDATE_COMMON
* 4/03 *acm* - Use STR_SAME to compare strings
* V674 2/12 *acm* 6D Ferret: use nferdims rather than 4 for dimension indexing

* Arguments:
*	var		- variable number in COMMON
*
	INTEGER		var
*                                                 
* Include files
	include 'tmap_dims.parm'
#include "tmap_dset.parm"
#include "gt_lib.parm"
	include 'xdset_info.cmn_text'
	external xdset_info_data
	include 'xtm_grid.cmn_text'
	

* calling argument declarations:

* Local definitions
	INTEGER*4	STR_SAME, dset, lcnt, line
*
* Is it an EZ data set ?
	dset = ds_var_setnum( var )
        IF (STR_SAME(ds_type(dset), '  EZ') .NE. 0) GOTO 9000
*
* Update variable records
	DO 100 lcnt = 1,nferdims
	  line = grid_line(lcnt,ds_grid_number(var))		! temporary var
	  IF (line .EQ. mpsnorm) THEN
	    ds_grid_start(lcnt,var) = 1
	    ds_grid_end(lcnt,var)   = 1
	  ELSEIF (line .EQ. mpsunkn ) THEN
	    GOTO 9000
	  ELSE
	    ds_grid_start(lcnt,var) = 1
	    ds_grid_end(lcnt,var)   = line_dim(line)
	  ENDIF
  100	CONTINUE

* All done
	RETURN
*
* ERROR MESSAGES                   
 9000	STOP 'EZ_UPDATE_VAR'
	END                        
