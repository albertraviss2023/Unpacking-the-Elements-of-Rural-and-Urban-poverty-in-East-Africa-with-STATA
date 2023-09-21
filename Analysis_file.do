/*******************************************************************************
Purpose: 		    Run main file to compute poverty  variables then tabulate and 
                            export results. 
Datasets:	            all the 3 coded PR_HRcoded.dta files (one by one)
Author:				Albert Lutakome			
Date last modified: September 22, 2023  by Albert Lutakome

Instructions:
 global macros: $path_in and $path_out
********************************************************************************/
  *** SETTING WORKING PATHS 
********************************************************************************
*** Working Folder Path ***
global path_in "C:\Users\..\EA Povery Computation" 
global path_out "C:\Users\..\EA Povery Computation\outdata"

********************************************************************************/
 *** CODING POVERTY VARIABLES AND RELEVANT SOCIAL-DEMOGRAPHIC VARIABLES
 ** This is done by running the relevant file below. 
********************************************************************************

do urban_rural_pov_in_east_africa.do

*****************************************************************************
*** TABULATIONS AND RESULTS EXPORTATION
*****************************************************************************
* List the HRPR merged files from the 3 East african countries . 
global codedfiles "KEPR_HRcoded TZPR_HRcoded UGPR_HRcoded"
	
foreach codedfile in $codedfiles {
use "$path_out//`codedfile'.dta", clear

*getting country two letter initials. 
local cn=substr("`codedfile'",1,2)

** use "$path_out\TZPR_HRcoded.dta"

svyset [pw=weight], psu(hv021) strata(hv022) singleunit(centered)

 
*install tabout if you have not already
ssc install tabout

* Total Adults leaving in poverty 
tab poor_hh [iw=weight]

** Poor households by disaggregations
tab area 	poor_hh        [iw=weight], row nofreq	//by residence 
tab hv024    poor_hh        [iw=weight], row nofreq 	//by region
tab gender  poor_hh        [iw=weight], row nofreq  //by gender
tab household_head poor_hh [iw=weight], row nofreq  //by household headship

* Child Poverty
svy: tab poor_hh if age < 18 ,per

//subgroups
local disaggregations  area hv024 gender household_head  

* output to excel
tabout `disaggregations'  poor_hh using `cn'Tables_Poor_Housholds_Distribution.xls [iw=weight] , c(row) npos(col) nwt(weight) f(1) replace 
	

** Pairwise deprivations 
tab  pair_wise_poor	                [iw=weight] // 2 deprivations 

** 2 deprivations s by subgroups
tab area 	pair_wise_poor          [iw=weight], row nofreq	//by residence 
tab hv024   pair_wise_poor          [iw=weight], row nofreq 	//by region
tab gender  pair_wise_poor          [iw=weight], row nofreq  //by gender
tab household_head pair_wise_poor   [iw=weight], row nofreq  //by household headship

* output to excel
tabout `disaggregations'  pair_wise_poor using `cn'Tables_Poor_Pairwise_Distribution.xls [iw=weight] , c(row) npos(col) nwt(weight) f(1) replace 


** Tripple deprivations 
tab  tripple_wise_poor 		[iw=weight] // 3 deprivations 
** 3 deprivations s by subgroups
tab area 	tripple_wise_poor          [iw=weight], row nofreq	//by residence 
tab hv024   tripple_wise_poor          [iw=weight], row nofreq 	//by region
tab gender  tripple_wise_poor          [iw=weight], row nofreq  //by gender
tab household_head tripple_wise_poor   [iw=weight], row nofreq  //by household headship

* output to excel
tabout `disaggregations'  tripple_wise_poor using `cn'Tables_Poor_Tripplewise_Distribution.xls [iw=weight] , c(row) npos(col) nwt(weight) f(1) replace 


** All 4 deprivations 
tab quadro_wise_poor		[iw=weight] //All 4 deprivations 
** 3 deprivations s by subgroups
tab area 	quadro_wise_poor           [iw=weight], row nofreq	//by residence 
tab hv024   quadro_wise_poor          [iw=weight], row nofreq 	//by region
tab gender  quadro_wise_poor           [iw=weight], row nofreq  //by gender
tab household_head quadro_wise_poor    [iw=weight], row nofreq  //by household headship

* output to excel
tabout `disaggregations'  quadro_wise_poor  using `cn'Tables_Poor_Quadruplewise_Distribution.xls [iw=weight] , c(row) npos(col) nwt(weight) f(1) replace 


 }
