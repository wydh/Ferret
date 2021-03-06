*
* tcat.F
*
* Ansley Manke
* Sep 15 2004
* 4/2006 fix ordering of loops: axis of concatenation must be outermost loop
*
* This function returns the T values of the two variables,
* concatenated into one long list on an abstract t axis. Other 
* axes are unchanged.
*
*
* In this subroutine we provide information about
* the function.  The user configurable information 
* consists of the following:
*
* descr              Text description of the function
*
* num_args           Required number of arguments
*
* axis_inheritance   Type of axis for the result
*                       ( CUSTOM, IMPLIED_BY_ARGS, NORMAL, ABSTRACT )
*                       CUSTOM          - user defined axis
*                       IMPLIED_BY_ARGS - same axis as the incoming argument
*                       NORMAL          - the result is normal to this axis
*                       ABSTRACT        - an axis which only has index values
*
* piecemeal_ok       For memory optimization:
*                       axes where calculation may be performed piecemeal
*                       ( YES, NO )
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


      SUBROUTINE tcat_init(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id, arg
      CHARACTER*100 descrip


* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      WRITE (descrip, 100)
      CALL ef_set_desc(id, descrip)
  100 FORMAT ('Concatenates the T values of two variables into one ',
     .        'list on an abstract T axis')

      CALL ef_set_num_args(id, 2)
      CALL ef_set_axis_inheritance(id, IMPLIED_BY_ARGS, 
     .     IMPLIED_BY_ARGS, IMPLIED_BY_ARGS, ABSTRACT)
      CALL ef_set_piecemeal_ok(id, NO, NO, NO, NO)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'A')
      CALL ef_set_arg_unit(id, arg, ' ')

      CALL ef_set_arg_desc(id, arg, 'First variable to concatenate')
      CALL ef_set_axis_influence(id, arg, YES, YES, YES, NO)

      arg = 2
      CALL ef_set_arg_name(id, arg, 'B')
      CALL ef_set_arg_unit(id, arg, ' ')

      CALL ef_set_arg_desc(id, arg, 'Second variable to concatenate')
      CALL ef_set_axis_influence(id, arg, YES, YES, YES, NO)
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END



      SUBROUTINE tcat_result_limits(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id
      INTEGER arg_lo_ss(4,1:EF_MAX_ARGS), arg_hi_ss(4,1:EF_MAX_ARGS),
     .     arg_incr(4,1:EF_MAX_ARGS)

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER nt

      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)

      nt = (arg_hi_ss(T_AXIS,ARG1) - arg_lo_ss(T_AXIS,ARG1) + 1) +  
     .     (arg_hi_ss(T_AXIS,ARG2) - arg_lo_ss(T_AXIS,ARG2) + 1)

      call ef_set_axis_limits(id, T_AXIS, 1, nt)

*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END

*
* In this subroutine we compute the result
*
      SUBROUTINE tcat_compute(id, arg_1, arg_2, result)

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

	  INTEGER id

      REAL bad_flag(1:EF_MAX_ARGS), bad_flag_result
      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, 
     .           mem1loz:mem1hiz, mem1lot:mem1hit)
      REAL arg_2(mem2lox:mem2hix, mem2loy:mem2hiy, 
     .           mem2loz:mem2hiz, mem2lot:mem2hit)
      REAL result(memreslox:memreshix, memresloy:memreshiy,
     .            memresloz:memreshiz, memreslot:memreshit)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable's axes. 

      INTEGER res_lo_ss(4), res_hi_ss(4), res_incr(4)
      INTEGER arg_lo_ss(4,1:EF_MAX_ARGS), arg_hi_ss(4,1:EF_MAX_ARGS),
     .     arg_incr(4,1:EF_MAX_ARGS)

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER i,j,k,l
      INTEGER i1,j1,k1,l1, i2,j2,k2,l2

      CALL ef_get_res_subscripts(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

      l = res_lo_ss(T_AXIS)
      DO 400 l1 = arg_lo_ss(T_AXIS,ARG1), arg_hi_ss(T_AXIS,ARG1)

         i = res_lo_ss(X_AXIS)
         DO 300 i1 = arg_lo_ss(X_AXIS,ARG1), arg_hi_ss(X_AXIS,ARG1)

            j = res_lo_ss(Y_AXIS)
            DO 200 j1 = arg_lo_ss(Y_AXIS,ARG1), arg_hi_ss(Y_AXIS,ARG1)

               k = res_lo_ss(Z_AXIS)
               DO 100 k1 = arg_lo_ss(Z_AXIS,ARG1),arg_hi_ss(Z_AXIS,ARG1)

                  IF (arg_1(i1,j1,k1,l1) .EQ. bad_flag(ARG1)) THEN
                     result(i,j,k,l) = bad_flag_result
                  ELSE
                     result(i,j,k,l) = arg_1(i1,j1,k1,l1)
                  ENDIF

                  k = k + res_incr(Z_AXIS)
 100           CONTINUE

               j = j + res_incr(Y_AXIS)
 200        CONTINUE

            i = i + res_incr(X_AXIS)
 300     CONTINUE

         l = l + res_incr(T_AXIS)
 400  CONTINUE

* concatenate in T - dont restart count of index L
      
      DO 410 l2 = arg_lo_ss(T_AXIS,ARG2), arg_hi_ss(T_AXIS,ARG2)

         i = res_lo_ss(X_AXIS)
         DO 310 i2 = arg_lo_ss(X_AXIS,ARG2), arg_hi_ss(X_AXIS,ARG2)

            j = res_lo_ss(Y_AXIS)
            DO 210 j2 = arg_lo_ss(Y_AXIS,ARG2), arg_hi_ss(Y_AXIS,ARG2)

               k = res_lo_ss(Z_AXIS)
               DO 110 k2 = arg_lo_ss(Z_AXIS,ARG2),arg_hi_ss(Z_AXIS,ARG2)

                  IF (arg_2(i2,j2,k2,l2) .EQ. bad_flag(ARG2)) THEN
                     result(i,j,k,l) = bad_flag_result
                  ELSE
                     result(i,j,k,l) = arg_2(i2,j2,k2,l2)
                  ENDIF

                  k = k + res_incr(Z_AXIS)
 110           CONTINUE

               j = j + res_incr(Y_AXIS)
 210        CONTINUE

            i = i + res_incr(X_AXIS)
 310     CONTINUE

         l = l + res_incr(T_AXIS)
 410  CONTINUE

      
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END
