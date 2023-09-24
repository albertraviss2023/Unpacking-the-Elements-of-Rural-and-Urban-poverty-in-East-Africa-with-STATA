/*******************************************************************************
Purpose:            Code poverty by residence, gender, and deprivation types,
                    Household headship.
                    in 3 East african countries (Uganda, Kenya and Tanzania).  
Datasets:	       	PR  merged with HR files
Author:				Albert Lutakome			
Date last modified: September 22, 2023  by Albert Lutakome

For purposes of this analysis, we define a poor household as one that lacks
at least 2 of the following:
- Improved water source (1)
- Improved sanitation/toilet (2)
- Durable household (3)
- Sufficient living space (4)

Instructions:
- The original HR and PR datasets have to be placed in the global input folder
- The root folder has to contain a global export folder named for example: 'outdata' 
(but you can neme it as you wish).
- These have to be set correctly in the globar macros: $path_in and $path_out
********************************************************************************/
clear all 
set more off
set maxvar 100000
** set varabbrev off, perm
********************************************************************************

********************************************************************************
*** Step 1.1 LOOP MERGING HR WITH THEIR RESPECTIVE PR files.
********************************************************************************
clear

* list of PR datasets for the 3 countries
global prdata "KEPR72FL TZPR7BFL UGPR7BFL"

*list your HR files for the 3 countries 
tokenize "KEHR72FL TZHR7BFL UGHR7BFL"

* Looping through the files

foreach pr in $prdata {

*getting 6 letter country name. 	
local cname=substr("`pr'",1,8)  

use "$path_in//`cname'.dta", clear 

*We use a m:1 merge since PR/household file has many members in one household- HR file. 

* local `1' here refers to the first file in the tokenized list above. 

merge m:1 hv001 hv002 using "$path_in//`1'.dta"

tab _merge 

*Keeping only matched observations. 
keep if _merge==3

*drop  _merge column to maintain a cleaner dataset. 
drop _merge 

*save merged file	
save "$path_out//`cname'_`1'_MERGE.dta", replace

* this shifts to the next survey in the tokensize list and the loop continues until the list is completed. 
mac shift

  }

********************************************************************************
*** Step 1.3 COMPUTING POVERTY ELEMENTS FROM THE MERGED FILES
********************************************************************************

* List the HRPR merged files from the 3 East african countries . 
global prhrfiles "KEPR72FL_KEHR72FL_MERGE TZPR7BFL_TZHR7BFL_MERGE UGPR7BFL_UGHR7BFL_MERGE"
	
foreach prhr in $prhrfiles {
use "$path_out//`prhr'.dta", clear

*saving the filename for each survey
gen filename= lower(substr("`prhr'",1,6)) 

*getting country two letter initials. 
local cn=substr("`prhr'",1,2)


*--------------------------- SANITATION ---------------------------------------
clonevar toilet = hv205   
* codebook toilet, tab(30)

gen	improved_toilet = .    
replace improved_toilet=  1 if (toilet<23 | toilet==41) & toilet!=. & toilet!=99   	
replace improved_toilet = 0 if toilet==14 | toilet==15 | toilet==31 | toilet==96 
lab var improved_toilet "Household has improved sanitation"

label define improved_toilet 0 "No" 1"Yes"
label values improved_toilet improved_toilet

tab toilet improved_toilet, miss // check

*----------------------------WATER SOURCE -------------------------------------
clonevar water = hv201  
*codebook water, tab(100)	

gen	improved_water    = 1  if water==11 | water==12 | water==14 | water==21 | ///
					     water==31 | water==41 | water==51 | water==71 
	
replace improved_water = 0 if water==32 | water==42 | water==43 | ///
						 water==61 | water==62 | water==96 
	
replace improved_water = . if water==. | water==99
lab var improved_water "Household has drinking water"
label var improved_water "Improved water source"
label define improved_water 0 "No" 1"Yes"
label values improved_water improved_water

tab water improved_water, miss // check

*------------------------- DURABLE MATERIAL -------------------------------------

* floor material
recode hv213 (11/22 96/99=0 "No") (23/37=1 "Yes"), gen(floor)
label var floor "Household floor made of durable material"

* wall material
recode hv214 (11/28 96/99=0 "No") (31/36=1 "Yes"), gen(wall)
label var wall "Household wall made of durable material"

* roof material
recode hv215 (11/26 96/99=0 "No") (31/39=1 "Yes"), gen(roof)
label var wall "Household roof made of durable material"


gen durable_house=0
replace durable_house=1 if floor==1 & wall==1 & roof==1
label define durable_house 0 "No" 1"Yes"
label values durable_house durable_house
label var durable_house "Household made of durable material"

*------------------------- LIVING SPACE/ Over-crowding conditions ------------------------------------
gen mem_usual =hv012
replace mem_usual=hv013 if mem_usual==0
gen room_space =.
replace room_space=trunc(mem_usual/hv216) if hv216>0
replace room_space=mem_usual if hv216==0

* handling missing values
replace room_space=. if hv216>=99

*The threshold for sufficient living space is less or equal to 3 (3<=)
recode room_space (0/2=1 "Yes") (3/max=0 "No"), gen(living_spce)

label var living_spce "Sufficient Living Space for household members"
label define living 1 "Sufficient Living Space" 0 "Over-crowded"
label values living_spce living

***** Generating urban poverty variable
/* A poor household as one that has at least 2 of the deprivations. 
 Note: for all the 4 deprivations, the expression evaluates to 1 accordingly.
 Eg. if there is lack in sanitation, (1-improved_toilet) = 1, or else =0.
 - Notice, over_crowd is differnt since 1 already represents over crowding.  */

gen poverty= (1-improved_toilet) + (1-improved_water) + (1-durable_house) + (1-living_spce)

*******************************************************************************
***The Poverty threshold: Having 2 or more deprivations means poverty >=2.
*******************************************************************************
gen poor_hh=0
replace poor_hh=1 if poverty>=2
label define poor_hh 0 "non-poor" 1 "poor" 
label values poor_hh poor_hh
label var poor_hh "Household poverty based on key deprivations"

********************************************************************************
*** Grouping all deprivation thresholds ***
********************************************************************************
gen pov_threshold = . 
replace pov_threshold = 1 if poverty == 1 
replace pov_threshold = 2 if poverty == 1
replace pov_threshold = 3 if poverty == 1 
replace pov_threshold = 4 if poverty == 1 

label var pov_threshold "Poverty thresholds"
label define pov_thresh 1 "" 2 "" 3 "" 4 ""
label val pov_threshold pov_thresh

*********************************************************
* Single Deprivations for poverty == 1
* Single  combinations: there are 4C1 = 4!/1!3! = 4
********************************************************
**  
 gen one_wise_poor = 0
 replace one_wise_poor  = 1 if poverty == 1
 lab var one_wise_poor  "Household lacks one deprivation"
 tab one_wise_poor poverty, missing 
                               
*lack improved_toilet improved_water - A
gen lack_toilet_only = 0
replace lack_toilet_only = 1 if improved_toilet == 1 & poverty == 1

*lack improved_water only  - B
gen lack_water_only = 0
replace lack_water_only = 1 if improved_water == 1 & poverty == 1

*lack durable_house  only  - C
gen lack_house_only = 0
replace lack_house_only = 1 if durable_house == 1 & poverty == 1

*lack Living space  only  - D
gen lack_living_only = 0
replace lack_living_only = 1 if living_spce == 1 & poverty == 1
*******************************************************************************
** Pairwise deprivations: => poverty == 2
*******************************************************************************
 gen pair_poor = 0
 replace pair_poor = 1 if poverty == 2 
 lab var pair_poor "Pairwise deprivations"

 /* Pairwise combinations: there are 4C2 = 4!/2!2! = 6 pairs that can be generated
*** our list improved_toilet improved_water durable_house living_spce if pair_poor==1
-                  A            B                  C         D
-The combos are: AB, AC, AD, BC , BD, CD.                                     */
                           
*lack improved_toilet improved_water - AB
gen lack_toilet_water = 0
replace lack_toilet_water  = 1 if improved_toilet==1 & improved_water ==1 &  poverty == 2 

*lack improved_toilet & durable_house - AC
gen lack_toilet_house =0
replace lack_toilet_house = 1 if improved_toilet==1 & durable_house ==1 &  poverty == 2 

*lack improved_toilet and living_spce - AD
gen lack_toilet_living_spce =0
replace lack_toilet_living_spce = 1 if improved_toilet==1 & living_spce ==1 &  poverty == 2 

*lack improved water and durable house - BC
gen lack_water_house =0
replace lack_water_house = 1 if improved_water ==1 & durable_house==1 &  poverty == 2 

*lack improved water and living_spce - BD
gen lack_water_living_spce =0
replace lack_water_living_spce = 1 if improved_water ==1 & living_spce==1 &  poverty == 2 

*lack durable house and living_spce - CD
gen lack_house_living_spce =0
replace lack_house_living_spce = 1 if durable_house==1 & living_spce==1 &  poverty == 2 

gen pair_wise_poor = .
replace pair_wise_poor =1 if lack_toilet_water ==1
replace pair_wise_poor =2 if lack_toilet_house ==1
replace pair_wise_poor =3 if lack_toilet_living_spce ==1
replace pair_wise_poor =4 if lack_water_house ==1
replace pair_wise_poor =5 if lack_water_living_spce ==1
replace pair_wise_poor =6 if lack_house_living_spce ==1

lab var pair_wise_poor "Two Deprivations Combinations"
lab define pair_wise 1 "improved toilet and water" 2 "improved toilet and durable house" /// 
3 "lacks improved toilet and living space" 4 "improved water and durable house" ///
5 "improved water and living space" 6 "durable house and living space" 
label values  pair_wise_poor pair_wise

tab pair_wise_poor poverty, missing

************************************************************************************
 ** Tripple deprivations poverty: Having 3 deprivations  =>poverty == 3
 **********************************************************************************
 gen tri_poor = 0
 replace tri_poor = 1 if poverty == 3
 lab var tri_poor "Tripple deprivations"
 
 /* Poverty by 3 deprivations: since the order doesnt matter, This is combination,
n is the total number of items and r is the number of items to be chosen, hence 4C3
=> there are = n!/(r!(n-r)!) = 4!/(3!(4-3)!) = = 24/(6*1) = 4 combinations. 
*** our list improved_toilet improved_water durable_house living_spce if tri_poor==1
-                  A            B                  C         D
-The combos are: ABC,ABD,BCD,CDA.                                             */ 
                                     

*lack improved_toilet improved_water and durable_house - ABC
gen lack_toilet_water_house = 0
replace lack_toilet_water_house  = 1 if improved_toilet==1 & improved_water ==1& durable_house ==1 & poverty == 3

**lack improved_toilet improved_water and living_spce - ABD
gen lack_toilet_water_living_spce = 0
replace lack_toilet_water_living_spce  = 1 if improved_toilet==1 & improved_water ==1 & living_spce ==1 & poverty == 3

**lack improved_water,durable_house and  living_spce - BCD
gen lack_water_house_living_spce = 0
replace lack_water_house_living_spce = 1 if improved_water ==1 & durable_house ==1 & living_spce ==1 & poverty == 3

**lack durable_house,  living_spce and improved_toilet   - CDA
gen lack_house_living_spce_toilet = 0
replace lack_house_living_spce_toilet = 1 if durable_house ==1 & living_spce ==1 & improved_toilet==1  & poverty == 3

gen tripple_wise_poor = .
replace tripple_wise_poor =1 if lack_toilet_water_house ==1
replace tripple_wise_poor =2 if  lack_toilet_water_living_spce ==1
replace tripple_wise_poor =3 if lack_water_house_living_spce  ==1
replace tripple_wise_poor =4 if lack_house_living_spce_toilet ==1

lab var tripple_wise_poor "3 Deprivations Combinations"
lab define tripple_wise 1 "improved toilet, water and durable house" /// 
2 "improved toilet, water and living space" ///
3 "water, durable house  and living space" 4 "durable house, living space and toilet" 
label values tripple_wise_poor tripple_wise

tab tripple_wise_poor poverty, missing

**********************************************************************
** All 4 deprivatisons poverty:  Here 4C4 = 4!/(4!1!) =1 
*********************************************************************
 gen quadro_wise_poor = 0
 replace quadro_wise_poor  = 1 if poverty == 4 
 lab var quadro_wise_poor  "Household lacks all four deprivations"

tab quadro_wise_poor poverty, missing

********************************************************************************
*** Step 1.2 CODING DEMOGRAPHIC VARIABLES ***
********************************************************************************

//Sample weight
desc hv005
clonevar weight = hv005
replace weight = weight/1000000 
label var weight "Sample weight"

//Area: urban or rural	
desc hv025
*codebook hv025, tab (5)		
clonevar area = hv025  
replace area=0 if area==2  
label define lab_area 1 "urban" 0 "rural"
label values area lab_area
label var area "Area: urban-rural"


//Relationship to the head of household 
clonevar relationship = hv101 
recode relationship (1=1)(2=2)(3=3)(11=3)(4/10=4)(12=5)(98=.)
label define lab_rel 1"head" 2"spouse" 3"child" 4"extended family" 5"not related" 
label values relationship lab_rel
label var relationship "Relationship to the head of household"
tab hv101 relationship, miss


//Sex of household member	
clonevar gender = hv104 
label var gender "Sex of household member"

//Household headship 
gen hhhead_male  =0
gen hhhead_female=0
gen spouse=0
gen child=0

replace hhhead_male  =1 if hv101==1 & gender==1
replace hhhead_female=1 if hv101==1 & gender==2
replace spouse=1        if hv101==2
replace child=1         if hv101==3 & hv105<=17 & (hv115==0 | hv115==.)

egen nhhhead_male  =total(hhhead_male),   by(hv024 hv001 hv002) 
egen nhhhead_female=total(hhhead_female), by(hv024 hv001 hv002) 
egen nspouse       =total(spouse),        by(hv024 hv001 hv002) 
egen nchild        =total(child),         by(hv024 hv001 hv002) 

gen hhtype=.
replace hhtype=1 if nhhhead_male==1   & nspouse>=1 & nchild>0
replace hhtype=2 if nhhhead_male==1   & nspouse>=1 & nchild==0
replace hhtype=3 if nhhhead_male==1   & nspouse==0 & nchild>0
replace hhtype=4 if nhhhead_male==1   & nspouse==0 & nchild==0
replace hhtype=5 if nhhhead_female==1 & nspouse>=1 & nchild>0
replace hhtype=6 if nhhhead_female==1 & nspouse>=1 & nchild==0
replace hhtype=7 if nhhhead_female==1 & nspouse==0 & nchild>0
replace hhtype=8 if nhhhead_female==1 & nspouse==0 & nchild==0
replace hhtype=9 if hhtype==.

label define hhtype 1 "Male head with spouse and children" 2 "Male head with spouse, no children" ///
3 "Male head, no spouse, and children" 4 "Male head, no spouse, no children" ///
5 "Female head with spouse and children" 6 "Female head with spouse, no children" ///
7 "Female head, no spouse, and children" 8 "Female head, no spouse, no children" 9 "Other"
label values hhtype hhtype
label var hhtype "Household structure"

recode hhtype (1 2 3 4=1 "Male headed")(5 6 7 8=2 "Female headed")(9=3 "Other"), gen(household_head)
label var household_head "Relationship to the head of household"

//Age of household member
clonevar age = hv105  
replace age = . if age>=98
label var age "Age of household member"

*keep only variables you need
keep hv000-hv027 hv012 hv013 weight area gender age toilet improved_toilet ///
water improved_water  floor wall roof durable_house room_space living_spce poverty ///
poor_hh relationship hhtype household_head pair_poor tri_poor lack_* filename ///
one_wise_poor pair_wise_poor tripple_wise_poor quadro_wise_poor
 
save "$path_out//`cn'PR_HRcoded.dta", replace
  }
  


  
