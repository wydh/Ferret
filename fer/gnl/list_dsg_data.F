	SUBROUTINE LIST_DSG_DATA ( dset, cx_list, mr_list, nvar,
     .				   heading, nfeatures, nobs )

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
* List data from a single DSG feature collection


* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* V720 4/17 *sh*
* V74+ 6/18 *acm* initial improvements for header for the listing
* V74+ 7/18 *acm* Better handling of string vars - still needs more work.
* V75+ 4/19 *acm* Longer string buffer to contain feature-id strings.
*                 Need comprehensive update to string-lenghts of names and attributes 
* V75+ 4/19 *acm* Note any transformation applied.
* V75+ 4/19 *acm* Changes to SUBSET listing in header
* V751 7/19 *acm* Changes to units and transforms listed in the header for all vars.
* V751 7/18 *acm* Call single routine for DSG feature-type names

        include 'netcdf.inc'
	include 'tmap_dims.parm'
#	include "tmap_dset.parm"
	include 'ferret.parm'
	include 'errmsg.parm'
	include 'xtm_grid.cmn_text'
	include 'xdset_info.cmn_text'
	include 'xdyn_linemem.cmn_text'
	include 'xcontext.cmn'
	include 'xprog_state.cmn'
	include 'xvariables.cmn'
	include 'slash.parm'
	include 'xrisc.cmn'          ! SPLIT_LIST buffer

* calling argument declarations:
	LOGICAL heading
	INTEGER dset, nvar, nfeatures, cx_list(nvar), mr_list(nvar)

* internal parameter declarations:
	INTEGER maxlen
	PARAMETER (maxlen = 20)   ! length of buffer str
             

* internal variable declarations:
	LOGICAL process_feature(nfeatures), process_obs(nobs), its_dsg, 
     .		has_mask, norow
	LOGICAL instance_coord(4), relevant_coord(4),
     .		instance_var(nvar), point_var(nvar), 
     .		instance_vars_only, point_vars_only, 
     .		ftr_label, constraint_labels, all_bad
	INTEGER CGRID_SIZE, TM_LENSTR1, DSG_WHATS_IT,
     .		GET_OFFSET_C_STRING_LEN, CX_DIM_LEN, GET_MAX_STRING_LEN,
     .		i, j, ifeature, ivar, iobs, nobs, idim, cx, grid, slen,
     .		orientation, obsdimlen, coord_lm(4), fvar_varid, base, ptr,
     .		bufflen, line, mr,  gxlate, row_size_lm, clen, nblank,
     .		feature_line, prec_digits(nvar), col_width(nvar), iwd, 
     .		alen, slen1, slen2, vname_len, list_dsg_digits, dtype, 
     .		vdims(2), idlen, ilen, ipad, idwid, data_len, nleft, nright,
     .		nok, direc(nvar), min_width, vstrlen, paren, trans, status
	REAL	value, small, big, biggest
	CHARACTER LEFINT*8, VAR_CODE*128, TM_FMT*16, VAR_UNITS*64, 
     .		FMT*20, AX_TITLE*32, SANITARY_VAR_CODE*128, CD_DSG_FEATURENAME*20,
     .		strbuff*128, line_buff*10000, vcode(nvar)*128,  
     .		col_head_format*32, pstr*15, feature_idname*10, buff*128,  
     .		good_fmt(max_intrp)*10, bad_fmt*10

	CHARACTER*255	VAR_TITLE, VAR_TITLE_MOD, PAREN_SURROUND, vname_buff

	PARAMETER (vstrlen=40)  ! length of vstr
	CHARACTER vstr*40


* coordinate listing field widths
	INTEGER coord_width(4)
     
	DATA coord_width/11, 10, 8, 20/
	CHARACTER*20 coord_head(4)
	DATA coord_head(1)/'  LONGITUDE         '/,
     .	     coord_head(2)/'  LATITUDE          '/,
     .	     coord_head(3)/'   DEPTH            '/,
     .	     coord_head(4)/'            TIME    '/

* initialize

        norow = qual_given(slash_list_norow) .GT. 0

* comma or tab delimited? 

        IF (list_fmt_type.EQ.plist_comma_del .OR. 
     .       list_fmt_type.EQ.plist_tab_del ) THEN
	   CALL LIST_DSG_COMMA_TAB (dset, cx_list, mr_list, nvar,
     .				   heading, nfeatures, nobs )
	   GOTO 5000
	ENDIF

	gxlate = dsg_xlate_grid(dset)
	cx = cx_list(1)
	grid = cx_grid(cx)
	its_dsg = .TRUE.
	CALL TM_DSG_FACTS( grid,
     .			   orientation, obsdimlen, feature_line, its_dsg )
	IF (.NOT. its_dsg) GOTO 5200
	row_size_lm = dsg_loaded_lm(dsg_row_size_var(dset))

	feature_idname = 'feature'

	IF (orientation.GE.pfeatureType_point .AND.  orientation.LE.pfeatureType_timeSeries) THEN
	   strbuff = CD_DSG_FEATURENAME(orientation)
	   feature_idname = strbuff(:tm_lenstr1(strbuff)) // '-id'
	ENDIF

* determine precision for outputting values

	list_dsg_digits = list_digits

	i = qual_given( slash_list_precision ) 
	IF ( i .GT. 0 ) THEN
	   CALL EQUAL_VAL( cmnd_buff(qual_start(i):qual_end(i)),
     .                     value, status )
           IF ( status .NE. ferr_ok ) GOTO 5100
	   list_dsg_digits = MAX(1.,MIN(value, 16.))	! 1 to 16
	ENDIF

!DSGTBD: style consideration: some of the info summarized here may be needed
!        also in plotting, other types of listing, etc.  Perhaps factor this
!        code and create a subroutine or two that can be re-used making
!        greater simplicity setting up plots.

* are there any observation vars?  Or is this all instance vars?
	point_vars_only    = .TRUE.   ! a hack to list E=@AVE result
	instance_vars_only = .TRUE.   ! a hack to list instance vars only
	ftr_label = .TRUE.

	DO ivar = 1, nvar
	   cx = cx_list(ivar)
	   grid = cx_grid(cx)
	   instance_var(ivar) = DSG_WHATS_IT(grid) .EQ. pdsg_instance
	   point_var(ivar) = CGRID_SIZE(cx) .EQ. 1
	   IF (.NOT.point_var(ivar)   ) point_vars_only    = .FALSE.
	   IF (.NOT.instance_var(ivar)) instance_vars_only = .FALSE.
	ENDDO

********** as in list_multi ***

* get direction of each variable in the dsg file

	DO ivar = 1, nvar
	   
	   cx = cx_list(ivar)
	   mr = mr_list(ivar)
	   direc(ivar) = no_dim

	   DO idim = 1, nferdims
	      IF ( cx_hi_ss(cx,idim) .GT. cx_lo_ss(cx,idim) ) 
     .	          direc(ivar) = idim
	   ENDDO
	
	ENDDO

	DO ivar = 1, nvar

* ... determine numeric format to fit nicely in each field
* ... first find largest value to be printed - routine applies 
*     feature-mask to narrow the amount of data

	   IF ( mr_type(mr_list(ivar)) .NE. ptype_string ) THEN
	   
	      mr = mr_list(ivar)
	      cx = cx_list(ivar)

	      IF (point_var(ivar)) THEN
* ... compressed feature result
	         small = memry(mr)%ptr(1)
		 big = small
		 IF ( small .NE. mr_bad_data(mr_list(ivar)) ) nok = 1

	      ELSE

	         CALL MINMAX_DSG ( dset, cx, nfeatures, direc(ivar), 
     .			   memry(mr_list(ivar))%ptr, 
     .			   mr_bad_data(mr_list(ivar)), small, big, nok)
	      ENDIF

	      all_bad = nok .EQ. 0

* . . . how many digits right and left of decimal point ?
	      biggest = MAX( ABS( small ), big )
	      CALL GET_SIG_DIGITS( biggest, list_dsg_digits, nleft, nright )
	      nleft = MAX( 1, nleft )			! at least "0" to left
	   ENDIF

* ... field must be wide enough to accomodate the variable code heading
*     (to a max of 8 characters)
	   min_width = 8

* . . . determine FORTRAN format for listing of this variable
	   IF ( mr_type(mr_list(ivar)) .EQ. ptype_string ) THEN
	      col_width(ivar) =  min_width
	      good_fmt(ivar) = '(A)'  ! not used
	   ELSEIF ( all_bad ) THEN
	      col_width(ivar) =  min_width	
	   ELSE
	      CALL VAR_DATA_FMT( nleft, nright, list_dsg_digits, min_width,
     .			         col_width(ivar), good_fmt(ivar), bad_fmt )

	   ENDIF

	   data_len = data_len + col_width(ivar)
	ENDDO

*************


* The varid of the feature-id variable
 
	line_buff = SANITARY_VAR_CODE(cat_file_var, dsg_feature_var(dset) )
	CALL CD_GET_VAR_ID  (dset, line_buff, fvar_varid, status)

* which dimensions are relevant to show

	IF (.NOT.norow) THEN
	   DO idim = 1, 4
	      line = grid_line(idim, gxlate)
	      relevant_coord(idim) =  line.NE.mnormal .AND. .NOT.point_vars_only
	      IF (relevant_coord(idim)) THEN
	         ivar = dsg_coord_var(idim,dset)
	         coord_lm(idim) = dsg_loaded_lm(ivar)  ! line memory table indices
	         instance_coord(idim) = line_dim(line) .EQ. nfeatures
* ... it causes confusion to show observation coordinates if the variables
*     requested are all instance variables
*     e.g. for time series, what is the time of the rowSize variable?
	         IF (instance_vars_only .AND. .NOT.instance_coord(idim))
     .		      relevant_coord(idim) = .FALSE.
	      ENDIF
	   ENDDO
	ENDIF

* create a mask showing which features to list
	IF (point_vars_only) THEN
	   process_feature(1) = .TRUE.    ! E axis reduced to 1 point
	   ftr_label = (nfeatures .EQ. 1) ! if compressed along ftr dir, don't list feature lab
	ELSE
	   CALL MAKE_DSG_FEATURE_MASK(dset, cx, process_feature, nfeatures)
	ENDIF
	IF (norow) ftr_label = .FALSE.

* Header

	IF (heading) THEN 

* data set name and title
	   CALL GET_DSET_NAME( dset, line_buff, alen )
	   CALL SPLIT_LIST(pttmode_explct, list_lun,
     .		'   DATA SET: '//line_buff(:alen), 0)
 3020	   FORMAT( 13X,A)
* ... title of data set
	   CALL GET_DSET_TITLE( dset, line_buff, alen )
	   IF ( alen .GT. 1 ) CALL SPLIT_LIST(pttmode_explct, list_lun,
     .		'   '//line_buff(:alen), 0)

* ... Is a feature mask set on this dataset?
	   IF (dsg_msk_lm(dset) .NE. unspecified_int4) THEN 
	      risc_buff = 'Mask on features has been set: '
	      slen1 = TM_LENSTR1( risc_buff ) + 1
	      
	      CALL GET_DSG_MASK_TITLE (dset, risc_buff(slen1+1:), has_mask, slen2)

	      slen1 = TM_LENSTR1( risc_buff ) 
	      IF (slen2 .EQ. 0) slen1 = slen1 - 1

	      IF (slen1 .GT. 0)  CALL SPLIT_LIST(pttmode_explct, list_lun, risc_buff(:slen1), 0) 
	   ENDIF ! feature-mask

* ... region information
* ... which axes require labels

	   constraint_labels = .FALSE.
	   DO idim = 1, 4
	      IF ( relevant_coord(idim) .AND. 
     .	   	   cx_lo_ww( idim,cx_cmnd ) .NE. unspecified_val8 ) 
     .		   constraint_labels = .TRUE. 
	   ENDDO
	   IF ( cx_lo_ww( e_dim, cx_cmnd ).NE.unspecified_val8
     .          .OR. cx_lo_ss( cx_cmnd, e_dim ).NE.unspecified_int4 ) 
     .		constraint_labels = .TRUE. 

	   IF (constraint_labels) THEN 
	      line_buff = '   SUBSET   :'
	      slen = 13
	      DO idim = 1, 4
	         IF ( relevant_coord(idim) ) THEN
	            IF ( cx_lo_ww( idim,cx_cmnd ) .NE. unspecified_val8 ) THEN 
	               CALL ASCII_LIMITS( cx, idim, buff, slen1 )
	               col_head_format = AX_TITLE( idim, gxlate, alen )
	               line_buff(slen+1:) = ' '//col_head_format(:alen)//': '//buff(:slen1)
	               slen = TM_LENSTR1( line_buff ) 
		       CALL SPLIT_LIST( pttmode_explct, list_lun, line_buff, slen)
		       line_buff = '     '
		       slen = 13

	            ENDIF
	         ENDIF

	      ENDDO
	      
	   ENDIF
		 
* ... e-direction
	   IF ( cx_lo_ww( e_dim, cx_cmnd ).NE.unspecified_val8
     .       .OR. cx_lo_ss( cx_cmnd, e_dim ).NE.unspecified_int4 ) THEN 
	      CALL ASCII_LIMITS( cx, idim, risc_buff, slen1 )
	      col_head_format = AX_TITLE( idim, grid, alen )
	      CALL SPLIT_LIST( pttmode_explct, list_lun,
     .			line_buff(:slen)//' '//col_head_format( :alen )//': '
     .			//risc_buff(1:slen1), 0)

	   ENDIF

* ... then variable titles and any special limits or data set for a variable

	   strbuff = VAR_CODE( cat_file_var, dsg_feature_var(dset))
	   vname_len = TM_LENSTR1( strbuff )
	   alen = 10
	   vname_len = MAX(vname_len, alen)

	   DO ivar = 1, nvar
	      cx = cx_list(ivar)
	      strbuff = VAR_CODE( cx_category(cx),cx_variable(cx))
	      alen = TM_LENSTR1( strbuff )
	      vname_len = MAX(vname_len, alen)
	   ENDDO

	   WRITE(FMT,2020) vname_len
2020	   FORMAT ("(1x, A", I0, ",' is ', A)")

	   vname_buff = VAR_CODE( cat_file_var, dsg_feature_var(dset))
	   risc_buff = ' '

	   WRITE ( risc_buff, FMT ) 
     .           vname_buff(:vname_len), feature_idname(:TM_LENSTR1(feature_idname))//'-id'
	   IF (.NOT.norow) CALL SPLIT_LIST(pttmode_explct, list_lun, risc_buff, 0)

	   DO ivar = 1, nvar
	      cx = cx_list(ivar)
	      strbuff = VAR_CODE( cx_category(cx),cx_variable(cx))
	      alen = TM_LENSTR1( strbuff )
	      vname_buff   = VAR_TITLE( cx )
	      clen   = TM_LENSTR1( vname_buff )
	      buff = PAREN_SURROUND(VAR_UNITS(cx), slen1)
	      IF (INDEX( buff, '(# of points)') .GT. 0) slen1 = 0
	      vname_buff   = vname_buff(:clen)//' '//buff(:slen1)
   	   	      
	      clen = clen+1+slen1

* Add anything about regridding, or axis description, but not transforms, which are done below.
	      buff   =  PAREN_SURROUND(VAR_TITLE_MOD(cx),slen2)
	      IF (INDEX(buff, "regrid").GT.0 .OR. INDEX(buff, "(axis").GT.0) 
     .	   	           vname_buff = vname_buff(:clen)//' '//buff(:slen2)
	      clen = clen+1+slen2

	      risc_buff = ' '
	      WRITE ( risc_buff, FMT ) strbuff(:vname_len), vname_buff(:clen)
              slen1 = TM_LENSTR1(risc_buff)

* Was there a transformation?
*     buff describes any transformation done on the obs axis for each feature. 
	
	      buff = ' '
	      DO idim = 1, 4
	         IF ( cx_lo_ww( idim,cx ) .NE. unspecified_val8 ) THEN 
	            CALL ASCII_LIMITS( cx, idim, line_buff, slen1 )
	            col_head_format = AX_TITLE( idim, grid, alen )
	            trans = cx_trans( idim, cx )
	            IF ( trans .NE. trans_no_transform ) THEN
	               clen = INDEX( line_buff(1:slen1), '(', .TRUE.)  ! last paren in string
	               IF (clen.GT.0) THEN
	                  buff = line_buff(clen:slen1) 			  
			  clen = TM_LENSTR1( buff )

* Put "each feature" in the label except for "closest distance" trans which are not done per feature

			  slen1 = TM_LENSTR1( risc_buff )

			  IF ( INDEX( buff, 'closest ') .GT. 0 ) THEN
			     risc_buff(slen1+1:slen+clen) = ' '
			     risc_buff(slen1+1:) = ' '//buff(:clen)
			  ELSE
			     risc_buff(slen1+1:) = ' '//buff(:clen-1)// ', each '//
     .	   	            feature_idname(:TM_LENSTR1(feature_idname))//')'
			  ENDIF

		       ENDIF
	            ENDIF

	         ENDIF
	      ENDDO



	      CALL SPLIT_LIST(pttmode_explct, list_lun, risc_buff, 0)

	   ENDDO  ! nvar


	ENDIF  ! heading

* Column header line. List this even if they said /nohead.
	slen = 0
	line_buff = ' '
	     
	IF (.NOT.norow) THEN
	   
	   strbuff =  VAR_CODE( cat_file_var, dsg_feature_var(dset))
	   clen = TM_LENSTR1(strbuff)

	   line_buff = '    FEATURE  '//strbuff(:clen)
	   slen = 23

	   DO idim = 1, 4
	      IF (relevant_coord(idim)) THEN
	         line_buff(slen+1:) = coord_head(idim)
	         slen = slen + coord_width(idim)
	      ENDIF
	   ENDDO

	ENDIF

	DO ivar = 1, nvar
	   cx = cx_list(ivar)
	   strbuff = VAR_CODE( cx_category(cx),cx_variable(cx))
	   clen = TM_LENSTR1(strbuff)
	   nblank = MAX(col_width(ivar)-clen, 1)
	   line_buff(slen+nblank+1:) = strbuff  
	   slen = slen + col_width(ivar)
	ENDDO

	IF (.NOT.heading .AND. norow .AND. nvar.EQ.1) line_buff = ' '
	CALL SPLIT_LIST(pttmode_explct, list_lun, line_buff, 0)

* get string length for ID variable - if its a string. 
* use strbuff and bufflen as dummy variables here

	pstr = '               '
	idlen = 5
	ipad = 0

	IF (.NOT.norow) THEN
	   CALL CD_GET_VAR_TYPE (dset, fvar_varid, strbuff, dtype, status)
	   IF (dtype .EQ. NF_CHAR) THEN
	      CALL CD_GET_VAR_DIMS_INFO (dset, fvar_varid, strbuff, bufflen, 
     .           vdims, status)
              CALL CD_GET_DS_DIMS (dset, vdims(1), strbuff, idlen, status)
	      ipad =(8-idlen)/2 
	      ipad = INT( (5-idlen)/2 )
	      ipad = MAX(1, INT( (5-idlen)/2 ) )
	   ENDIF
	ENDIF

*  ***** LIST THE DATA ******
	base = 0    ! obs index at end of preceding feature

* ... loop over the features
	DO ifeature = 1, nfeatures 
	   nobs = dsg_linemem(row_size_lm)%ptr(ifeature)  ! feature length

* ... have the user's constraints removed this feature?
	   IF (.NOT.process_feature(ifeature)) GOTO 500

	   IF ((heading .OR. base.GT.0) .AND. .NOT.norow) THEN
	   IF (.NOT.point_vars_only .AND. .NOT.instance_vars_only)
     .        CALL SPLIT_LIST(pttmode_explct, list_lun, ' ', 1)
	   ENDIF

* ... each line starts with the feature number and Feature ID
	   buff = pstr
	   IF (.NOT.norow) WRITE(buff, 3100) ifeature
 3100	   FORMAT(I6, 2x)
	   ilen = 8

* Read the feature-id value. If it's numeric turn it into a string

	   IF (ftr_label) THEN
	      idwid = 15
	      CALL CD_READ_ONE ( dset, fvar_varid, ifeature, dtype, value, 
     .                                 strbuff, bufflen, status )
	      IF (dtype .NE. NF_CHAR) THEN
	         strbuff = '  '//TM_FMT(value, 8, 12, bufflen)
	         bufflen = MAX(12,bufflen)
	         ipad = 3
	      ELSE
	         bufflen = MIN(idlen, bufflen)
	         IF (bufflen .LT. idwid) THEN
	            ipad = INT(idwid-bufflen)
	         ENDIF
	      ENDIF

* if compressed along the e dimension don't include the feature-id value.
	   ELSE
	      strbuff = '               '
	      pstr = ' '
	      ipad = 0
	      bufflen = 15
	   ENDIF

	   bufflen = MIN(32-ilen-ipad, bufflen)
	   buff(ilen+1:) = pstr(:ipad)//strbuff(:bufflen)
	   ilen = ilen + bufflen + ipad
	   IF (norow) ilen = 0


* ... get observation-level mask for this feature
	   CALL MAKE_DSG_OBS_MASK(dset, cx, ifeature, base,
     .				  process_obs, nobs)

* ... loop over the observations within each feature
	   DO iobs = 1, nobs
	      ptr = base + iobs  ! pointer (index) into the ragged contig array

* ... have the user's constraints removed this observation?
	      IF (.NOT.process_obs(iobs)) CYCLE
	      line_buff = buff(:ilen)
	      slen = ilen

* ... insert the relevant formatted coordinates
	      IF (.NOT. norow) THEN
	         DO idim = 1, 4
	            IF ( relevant_coord(idim) ) THEN
	               IF (instance_coord(idim)) THEN
* ... feature coordinate
	                  value = dsg_linemem(coord_lm(idim))%ptr(ifeature)
	               ELSE
* ... obs coordinate
	                  value = dsg_linemem(coord_lm(idim))%ptr(ptr)
	               ENDIF
		       IF (ABS(value) .GE. ABS(bad_val4)) THEN
		          strbuff = '*'
		       ELSE
	                  CALL TRANSLATE_TO_WORLD( value, idim, gxlate, 
     .					     ax_dec_pt(idim), strbuff)
	               ENDIF
		       clen = TM_LENSTR1(strbuff)
		       paren = INDEX((strbuff), "(")
		       IF (paren .GT. 0) clen = MIN(clen,paren-1)
	               nblank = MAX(coord_width(idim)-clen, 1)
	               line_buff(slen+nblank+1:) = strbuff(:clen)
	               slen = slen + coord_width(idim)
	            ENDIF
	         ENDDO

	      ENDIF ! .not. norow

* ... insert the formatted data
	      bufflen = slen
	      DO ivar = 1, nvar
	         mr = mr_list(ivar)

		 
	         IF ( mr_type(mr) .EQ. ptype_string ) THEN
                    vstr = '                '
                    vstr(1:1) = '"'

	            IF (point_var(ivar)) THEN
* ... compressed feature result
	               iwd = 0
	           ELSEIF (instance_var(ivar)) THEN
* ... feature value
	               iwd = ifeature - 1
	            ELSE
* ... obs value
	               iwd = ptr - 1
	            ENDIF

	            slen = GET_OFFSET_C_STRING_LEN(mr_c_pointer(mr),
     .					 iwd )
	            slen = MIN(slen, vstrlen-2)  ! fixed length of vstr...
		    CALL GET_OFFSET_C_STRING(mr_c_pointer(mr),
     .				   iwd,
     .				   vstr(2:),
     .				   slen    )
                    vstr(slen+2:slen+2) = '"'    


	         ELSE

	           IF (point_var(ivar)) THEN
* ... compressed feature result
	               value = memry(mr)%ptr(1)
	            ELSEIF (instance_var(ivar)) THEN
* ... feature value
	               value = memry(mr)%ptr(ifeature)
	            ELSE
* ... obs value
	               value = memry(mr)%ptr(ptr)
	            ENDIF
	            IF (value .EQ. mr_bad_data(mr)) THEN
	               vstr = "..."
	            ELSE
	               WRITE(vstr, good_fmt(ivar)) value
	            ENDIF

		 ENDIF

* remove leading blanks   (better way to handle this?)
		 DO i = 1, vstrlen
                    IF ( vstr( i:i ) .NE. ' ' ) ExIT
		 ENDDO
		 CALL TM_PACK_STRING(vstr, vstr, 1, i, clen)
	         clen = TM_LENSTR1(vstr)


	         nblank = MAX(col_width(ivar)-clen, 1)
	         line_buff(bufflen+nblank+1:) = vstr
	         bufflen = bufflen + col_width(ivar)
	      ENDDO

* ... write out the line
	      CALL SPLIT_LIST(pttmode_explct, list_lun, line_buff, 0)

* ... write only a single line from each feature if there are no ragged arrays
	      IF (instance_vars_only) EXIT	! list just one "obs" line
	   ENDDO

 500	   base = base + nobs
	   IF (point_vars_only) EXIT		! list just one "feature" line
	ENDDO   ! loop over features

 5000	RETURN
 5100	CALL ERRMSG( ferr_invalid_command, status,
     .		'Error getting value from LIST/PRECISION= ',
     .		*5000 )
 5200	CALL ERRMSG( ferr_grid_definition, status,
     .		'Data grid is not a DSG grid ',
     .		*5000 )
	END
