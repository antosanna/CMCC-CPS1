/* File loaded by posptc_clm.sh in a ncap2 -S procedure.                          */
/* for details ask to A.Cantelli, D.Peano                                         */
/* This script caluclate the snow density for a clm output file, and need:        */
/*   TBOT,QFLX_SNOW_GRND,H2OSNO,SNOWDP (the last 2 are averaged over grid area)   */
/* Basically the algo calculate fresh snow from QFLX_SNOW_GRND and applying a     */
/* threshold (10 mm) substitute RHOSNO_bulk (H2OSNO/SNOWDP)  with RHOSNO_fresh    */

/* H2OSNO_fresh [mm] = QFLX_SNOW_GRND [mm H2O/s] * time (h1 files)  */
H2OSNO_fresh=QFLX_SNOW_GRND*3600*24;

/* cap both H2OSNO and H2OSNO_fresh for values < 10-4 */
where (H2OSNO<0.0001) 
	H2OSNO=0;
where (H2OSNO_fresh<0.0001) 
	H2OSNO_fresh=0;	

/* calculate difference */
H2OSNO_diff=H2OSNO-H2OSNO_fresh;

/* Initialize variable RHOSNO and RHOSNO_BULK */
RHOSNO_BULK=H2OSNO/SNOWDP ; 
where (SNOWDP==0) 
	RHOSNO_BULK=0;

/* cap all RHOSNO_BULK to min 50 */
where (RHOSNO_BULK<=50) 
	RHOSNO_BULK=50;
where (RHOSNO_BULK>450) 
	RHOSNO_BULK=450;

RHOSNO=RHOSNO_BULK ;
/* Initialize RHOSNO_fresh at 50 for the where condition - see clm doc - if loop*/
RHOSNO_fresh=RHOSNO_BULK*0+50 ;

/* RHOSNO_fresh= bulk fresh snow density [kg/m3]. See clm 4.0 (var bifall) - Anderson 1976 */
where (TBOT>275.15)
   RHOSNO_fresh=169.15;

where (TBOT>258.15)   
   RHOSNO_fresh=50+1.7*(TBOT-273.15+15.0)^1.5; 

/* cap all RHOSNO_fresh to min 50 */
where (H2OSNO==0) 
	RHOSNO_fresh=50;

/* Where ther is snow and if H2OSNO_diff is lower (10 mm) or negative is all fresh snow for density */
where (H2OSNO>0 && H2OSNO_diff<10)  
   RHOSNO=RHOSNO_fresh;

/* Where snodp < 0.01 also apply fresh snow */
where (SNOWDP<0.01)  
   RHOSNO=RHOSNO_fresh;

/* cap to 450 */
where (SNOWDP>450)  
   RHOSNO=450;

