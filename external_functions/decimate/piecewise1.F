*  piecewise1.F
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

* Ansley Manke June 2013
* implements stl2, Piecewise linear approximations of fewest line segments
* described in http://www.computer.org/csdl/proceedings/afips/1972/5079/00/50790187.pdf
* and a somewhat later version of the code, found at
* http://www.netlib.org/toms/510
*
*
*  In this subroutine we provide information about
*  the function.  The user configurable information 
*  consists of the following:
* 
*  descr              Text description of the function
* 
*  num_args           Required number of arguments
* 
*  axis_inheritance   Type of axis for the result
*                        ( CUSTOM, IMPLIED_BY_ARGS, NORMAL, ABSTRACT )
*                        CUSTOM          - user defined axis
*                        IMPLIED_BY_ARGS - same axis as the incoming argument
*                        NORMAL          - the result is normal to this axis
*                        ABSTRACT        - an axis which only has index values
* 
*  piecemeal_ok       For memory optimization:
*                        axes where calculation may be performed piecemeal
*                        ( YES, NO )
* 
*
* For each argument we provide the following information:
*
* name               Text name for an argument
*
* unit               Text units for an argument
*
* desc               Text description of an argument
*
* axis_influence     Are this argument's axes the same as the result grid?
*                       ( YES, NO )
*
* axis_extend       How much does Ferret need to extend arg limits relative to result 
*


      SUBROUTINE piecewise1_init(id)

      IMPLICIT NONE
      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id, arg

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      CALL ef_set_desc(id,
     . 'Return indices to sample from piecewise linear interpolation of 1 var' )

      CALL ef_set_num_args(id, 3) 
      CALL ef_set_has_vari_args(id, NO)
      CALL ef_set_axis_inheritance(id, ABSTRACT, NORMAL, 
     .                                              NORMAL,   NORMAL)
      CALL ef_set_piecemeal_ok(id, NO, NO, NO, NO)
      CALL ef_set_num_work_arrays(id, 4)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'V1')
      CALL ef_set_arg_desc(id, arg, 'variable to sample')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, NO)

      arg = 2
      CALL ef_set_arg_name(id, arg, 'Control parameter')
      CALL ef_set_arg_desc(id, arg,
     .          'Control parameter (e.g. 6 for ntol=rest=cont=1)')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, NO)

      arg = 3
      CALL ef_set_arg_name(id, arg, 'Tol1')
      CALL ef_set_arg_desc(id, arg, 'Tolerance for V1')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, NO)


*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END


*
* In this subroutine we provide information about the lo and hi
* limits associated with each abstract or custom axis.   The user 
* configurable information consists of the following:
*
* lo_ss               lo subscript for an axis
*
* hi_ss               hi subscript for an axis
*

      SUBROUTINE piecewise1_result_limits(id)

      IMPLICIT NONE
      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id

* **********************************************************************
*                                           USER CONFIGURABLE PORTION |
*                                                                     |
*                                                                     V

      INTEGER my_hi_i
      INTEGER arg_lo_ss(4,EF_MAX_ARGS),
     .        arg_hi_ss(4,EF_MAX_ARGS),
     .        arg_incr (4,EF_MAX_ARGS)

*
*     Use utility functions to get context information about the arguments.
*

      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)

      my_hi_i = arg_hi_ss(X_AXIS,1) - arg_lo_ss(X_AXIS,1) + 1

      CALL ef_set_axis_limits(id, X_AXIS, 1, my_hi_i)
*                                                                     ^
*                                                                     |
*                                           USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END

      
*
* In this subroutine we request an amount of storage to be supplied
* by Ferret and passed as an additional argument.
*
      SUBROUTINE piecewise1_work_size(id)

      IMPLICIT NONE
      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
* 
* Set the work arrays, X/Y/Z/T/E/F dimensions
*
* ef_set_work_array_dims(id, array #,
*                           xlo, ylo, zlo, tlo, 
*                           xhi, yhi, zhi, thi)
*

      INTEGER arg_lo_ss(4,EF_MAX_ARGS),
     .        arg_hi_ss(4,EF_MAX_ARGS),
     .        arg_incr (4,EF_MAX_ARGS)
      INTEGER npts, iwork

      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)

      npts = 1 + arg_hi_ss(X_AXIS,ARG1) - arg_lo_ss(X_AXIS,ARG1)
  
* input x-axis coordinates
      iwork = 1
      CALL ef_set_work_array_dims(id, iwork,
     .                                1, 1, 1, 1,
     .                             npts, 1, 1, 1)

* internal computation, u1 for y1
      iwork = 2
      CALL ef_set_work_array_dims(id, iwork,
     .                                1, 1, 1, 1,
     .                             npts, 1, 1, 1)

* internal computation, v
      iwork = 3
      CALL ef_set_work_array_dims(id, iwork,
     .                                1, 1, 1, 1,
     .                           2*npts, 1, 1, 1)

* internal computation, w
      iwork = 4
      CALL ef_set_work_array_dims(id, iwork,
     .                                1, 1, 1, 1,
     .                           2*npts, 1, 1, 1)
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN
      END


*  In this subroutine we compute the result
* 
      SUBROUTINE piecewise1_compute(id, arg_1, arg_2, arg_3, 
     .         result, xpts, u1, v, w)

      IMPLICIT NONE
      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

      INTEGER id

      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, mem1loz:mem1hiz, 
     .           mem1lot:mem1hit)
      REAL arg_2(mem2lox:mem2hix, mem2loy:mem2hiy, mem2loz:mem2hiz, 
     .           mem2lot:mem2hit)
      REAL arg_3(mem3lox:mem3hix, mem3loy:mem3hiy, mem3loz:mem3hiz, 
     .           mem3lot:mem3hit)

      REAL result(memreslox:memreshix, memresloy:memreshiy, 
     .            memresloz:memreshiz, memreslot:memreshit)

* Ignore the Y/Z/T/E/F dimensions in the work array since
* they are not used and Fortran is column major

      REAL xpts(wrk1lox:wrk1hix)

      REAL u1(wrk2lox:wrk2hix)
      REAL  v(wrk3lox:wrk3hix)
      REAL  w(wrk4lox:wrk4hix)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable's axes. 

      INTEGER res_lo_ss(4),
     .        res_hi_ss(4),
     .        res_incr (4)
      INTEGER arg_lo_ss(4,EF_MAX_ARGS),
     .        arg_hi_ss(4,EF_MAX_ARGS),
     .        arg_incr (4,EF_MAX_ARGS)

      REAL bad_flag(EF_MAX_ARGS), bad_flag_result


* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER i,  k
      INTEGER nx, nout1, ip
      REAL val, tol, bad_y
      CHARACTER*100 errtxt

      CALL ef_get_res_subscripts(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

* Control parameter IP

      CALL ef_get_one_val(id, ARG2, val)
      IP = INT(val)

* Tolerances

      CALL ef_get_one_val(id, ARG3, tol)

*  Set x coordinate - abstract axis.

      nx = arg_hi_ss(X_AXIS, ARG1) - arg_lo_ss(X_AXIS, ARG1) + 1
      DO 50 i = 1, nx
         xpts(i) = i
  50  CONTINUE

      k = res_lo_ss(Z_AXIS)  ! index for unused dimensions

* STL2 modified to truncate result to next lowest integer

      bad_y = bad_flag(ARG1)
      CALL STL2(xpts, arg_1, tol, nx, bad_y, bad_flag_result, 
     .   result, v, w, nout1, IP)
      IF (nout1 .GT. res_hi_ss(X_AXIS)) THEN
        write (errtxt,*) 'call to STL2 returns too many data', nout1
	 GOTO 999
      ENDIF

      DO 100 i = nout1+1, res_hi_ss(X_AXIS)
        result(i,k,k,k) = bad_flag_result
 100  CONTINUE

      RETURN
 999  CALL EF_BAIL_OUT(id, errtxt)
      RETURN

      END
