/* EF_Util.h
 *
 * Jonathan Callahan
 * July 10th 1997
 *
 * This is the header file to be included by routines which
 * are part of the Ferret External Function library.
 *
 */
 
 
#ifndef	_EF_UTIL_H
#define	_EF_UTIL_H
 
/* .................... Includes .................... */
 


/* .................... Defines ..................... */

#define TRUE  1
#define FALSE 0
#define YES   1
#define NO    0

#define LO    0
#define HI    1

#define ATOM_NOT_FOUND 0  /* This should match the atom_not_found parameter in ferret.parm. */

#define EF_VERSION 1.1

#define EF_MAX_NAME_LENGTH 40
#define EF_MAX_DESCRIPTION_LENGTH 128
#define EF_MAX_ARGS 9

enum { EF_C=1, EF_F } EF_LANGUAGE_type;

enum { X_AXIS=0, Y_AXIS, Z_AXIS, T_AXIS } EF_AXIS_type;

enum { CUSTOM=101, IMPLIED_BY_ARGS, NORMAL, ABSTRACT } EF_AXIS_SOURCE_type;

enum { CANNOT_ALLOCATE, INSUFFICIENT_DATA } EF_ERROR_type;

/* .................... Typedefs .................... */

typedef struct {
  int  will_be, modulo;
  int  ss_lo, ss_hi, ss_incr;
  float ww_lo, ww_hi, ww_del;
  char unit[EF_MAX_NAME_LENGTH];
} Axis;


/*
 * This structure defines the information we can know about
 * an internal function.  Ferret gets information from this
 * structure by calling one of the C routines beginning with
 * "efcn_".
 */
typedef struct {
  /* Information about the overall function */
  float version;
  char description[EF_MAX_DESCRIPTION_LENGTH];
  int  language;
  int  num_reqd_args, has_vari_args;
  int  axis_will_be[4];
  int  piecemeal_ok[4];
  Axis axis[4];

  /* Information specific to each argument of the function */
  int  axis_implied_from[EF_MAX_ARGS][4];
  int  axis_extend_lo[EF_MAX_ARGS][4];
  int  axis_extend_hi[EF_MAX_ARGS][4];
  char arg_name[EF_MAX_ARGS][EF_MAX_NAME_LENGTH];
  char arg_unit[EF_MAX_ARGS][EF_MAX_NAME_LENGTH];
  char arg_desc[EF_MAX_ARGS][EF_MAX_DESCRIPTION_LENGTH];
} ExternalFunctionInternals;
 
/*
 * This structure defines the basic element of the 
 * GLOBAL_ExternalFunctionList.
 */
typedef struct {
  void *handle;
  char name[EF_MAX_NAME_LENGTH];
  char path[EF_MAX_DESCRIPTION_LENGTH];
  int id, already_have_internals;
  ExternalFunctionInternals *internals_ptr;
} ExternalFunction;


#endif	/* _EF_UTIL_H */

