log close
log using "Assignment_3.log", text replace

use "1997_SCF_data.dta", clear // load the 1997 SCF data
browse 

use "1982_SCF_data.dta", clear // load the 1982 SCF data
browse

use "2016_data.dta", clear // load the 2016 SCF data
browse

use "2018_data.dta", clear // load the 2018 SCF data
browse

// Question 2 
// (a)
import delimited "CPI_1982-2018.csv", clear
browse

describe
keep in 9/11 // keep only the rows that contain the years and actual CPI values
ds
save "cpi_3lines.dta", replace
use "cpi_3lines.dta", clear

preserve
    keep in 1

    * make v2-v38 the same type so reshape works
    foreach x of varlist v2-v38 {
        capture tostring `x', replace force
    }

    gen id = 1
    reshape long v, i(id) j(j)
    destring j, replace force

    rename v cpi_years
    destring cpi_years, replace force

    keep j cpi_years
    sort j
    save "yearmap.dta", replace
restore

use "yearmap.dta", clear
use "cpi_3lines.dta", clear
keep if v1=="All-items"

foreach x of varlist v2-v38 {
    capture tostring `x', replace force
}

gen id = 1
reshape long v, i(id) j(j)
destring j, replace force

rename v cpi
destring cpi, replace force

merge m:1 j using "yearmap.dta", nogen keep(match)

sort cpi_years

gen str12 cpi_lab = ""
replace cpi_lab = string(cpi, "%9.1f") if inlist(cpi_years, 1982, 1997, 2016, 2018)


twoway connected cpi cpi_years, ///
    mlabel(cpi_lab) mlabpos(12) ///
    title("CPI (All-items) for relevant years") ///
    xtitle("Year") ytitle("CPI index") ///

save "cpi_years.dta", replace

// (b)
// need to manually include 2020 and 2019 CPI values, since they are not in the original dataset
use "cpi_years.dta", clear
set obs `=_N+2' // add one more observation for 2020

replace cpi_years = 2019 in `=_N-2'
replace cpi  = 136.0 in `=_N-2'

replace cpi_years = 2020 in `=_N-1'
replace cpi  = 137.0 in `=_N-1'

// CPI_2020 (scalar)
summ cpi if cpi_years==2020, meanonly
scalar CPI2020 = r(mean)
display CPI2020

gen deflator_2020 = cpi / CPI2020 // deflator to convert to 2020$ = 1
label var deflator_2020 "CPI deflator (2020=1)"
tab deflator_2020

gen adj_to_2020 = CPI2020 / cpi // multiply nominal by this to get 2020$
label var adj_to_2020 "Multiply Nominal by this to get 2020$"

save "cpi_annual_2020base.dta", replace


use "cpi_annual_2020base.dta", clear
summarize adj_to_2020 if cpi_years == 1982, meanonly
display r(mean)
scalar s1982_to_2020 = 2.4954462

summarize adj_to_2020 if cpi_years == 1997, meanonly
display r(mean)
scalar s1997_to_2020 = 1.5154867

summarize adj_to_2020 if cpi_years == 2016, meanonly
display r(mean)
scalar s2016_to_2020 = 1.0669782

summarize adj_to_2020 if cpi_years == 2018, meanonly
display r(mean)
scalar s2018_to_2020 = 1.0269866


use "1997_SCF_data.dta", clear

summarize TOTINC INCFTX WAGSAL WEIGHT USHOURS

tab USHOURS


replace USHOURS = 66.5 if USHOURS == 65 // in order the balance out the people who may have worked more than 65 hours

drop Annual_Hours Wage_per_Hour Wage_per_Hour_2020 // drop these variables if they already exist, otherwise it will mess up the calculations when we run this code multiple times
gen Annual_Hours = USHOURS * 52 if USHOURS > 0 // only calculate annual hours for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Annual_Hours "Annual hours worked"

gen Wage_per_Hour = WAGSAL / Annual_Hours if Annual_Hours > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s1997_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "1997_SCF_data_wage.dta", replace

use "1982_SCF_data.dta", clear

tab HRSWRK
replace HRSWRK = 66.5 if HRSWRK == 65 // in order the balance out the people who may have worked more than 65 hours

drop Annual_Hours Wage_per_Hour Wage_per_Hour_2020 // drop these variables if they already exist, otherwise it will mess up the calculations when we run this code multiple times
gen Annual_Hours = HRSWRK * 52 if HRSWRK > 0 // only calculate annual hours for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Annual_Hours "Annual hours worked"

gen Wage_per_Hour = WAGSAL / Annual_Hours if Annual_Hours > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s1982_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "1982_SCF_data_wage.dta", replace

use "2016_data.dta", clear

tab ALHRWK

drop Wage_per_Hour Wage_per_Hour_2020 // drop these variables if they already exist, otherwise it will mess up the calculations when we run this code multiple times
gen Wage_per_Hour = WGSAL / ALHRWK if ALHRWK > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s2016_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "2016_data_wage.dta", replace

use "2018_data.dta", clear

tab ALHRWK
drop Wage_per_Hour Wage_per_Hour_2020 // drop these variables if they already exist, otherwise it will mess up the calculations when we run this code multiple times
gen Wage_per_Hour = WGSAL / ALHRWK if ALHRWK > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s2018_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "2018_data_wage.dta", replace

// Question 3


scalar minwage_1982_2020 = 9.326730419 / 2
display minwage_1982_2020

scalar minwage_1997_2020 = 9.718058628 / 2
display minwage_1997_2020

scalar minwage_2016_2020 =  12.05685358 / 2
display minwage_2016_2020

scalar minwage_2018_2020 =  13.77445652 / 2
display minwage_2018_2020

// dropping values for 1982 data
use "1982_SCF_data_wage.dta", clear
tab AGE

quietly count
local N0 = r(N)
display as text "Initial sample N = " as result %12.0fc `N0'


quietly drop if missing(Wage_per_Hour_2020, Annual_Hours, AGE)   // we need age, annual hours and wage per hour to do the analysis, so drop those with missing values
quietly count
local N1 = r(N)
display as text "After dropping missing info: N = " as result %12.0fc `N1' ///


quietly drop if Wage_per_Hour_2020 < minwage_1982_2020 
quietly count
local N3 = r(N)
display as text "After dropping below minimum wage: N = " as result %12.0fc `N3' ///


quietly drop if AGE < 25 | AGE > 60
quietly count
local N4 = r(N)
display as text "After dropping outside age range: N = " as result %12.0fc `N4' ///


quietly drop if Annual_Hours < 260
quietly count
local N5 = r(N)
display as text "After dropping below 260 annual hours: N = " as result %12.0fc `N5' ///

save "1982_SCF_data_cleaned.dta", replace

///
use "1997_SCF_data_wage.dta", clear
tab AGE

quietly count
local N0 = r(N)
display as text "Initial sample N = " as result %12.0fc `N0'


quietly drop if missing(Wage_per_Hour_2020, Annual_Hours, AGE)   // we need age, annual hours and wage per hour to do the analysis, so drop those with missing values
quietly count
local N1 = r(N)
display as text "After dropping missing info: N = " as result %12.0fc `N1' ///


quietly drop if Wage_per_Hour_2020 < minwage_1997_2020 
quietly count
local N3 = r(N)
display as text "After dropping below minimum wage: N = " as result %12.0fc `N3' ///


quietly drop if AGE < 25 | AGE > 60
quietly count
local N4 = r(N)
display as text "After dropping outside age range: N = " as result %12.0fc `N4' ///


quietly drop if Annual_Hours < 260
quietly count
local N5 = r(N)
display as text "After dropping below 260 annual hours: N = " as result %12.0fc `N5' ///

save "1997_SCF_data_cleaned.dta", replace

///
use "2016_data_wage.dta", clear
tab AGEGP
// age values 07 - 13 correspond to ages 25-60, so we will keep those and drop the rest
tab ALHRWK


quietly count
local N0 = r(N)
display as text "Initial sample N = " as result %12.0fc `N0'


quietly drop if missing(Wage_per_Hour_2020, ALHRWK, AGEGP)   // we need age, annual hours and wage per hour to do the analysis, so drop those with missing values
quietly count
local N1 = r(N)
display as text "After dropping missing info: N = " as result %12.0fc `N1' ///


quietly drop if Wage_per_Hour_2020 < minwage_2016_2020 
quietly count
local N3 = r(N)
display as text "After dropping below minimum wage: N = " as result %12.0fc `N3' ///


quietly drop if AGEGP < "07" | AGEGP > "13"
quietly count
local N4 = r(N)
display as text "After dropping outside age range: N = " as result %12.0fc `N4' ///


quietly drop if ALHRWK < 260
quietly count
local N5 = r(N)
display as text "After dropping below 260 annual hours: N = " as result %12.0fc `N5' ///

save "2016_data_cleaned.dta", replace


use "2018_data_wage.dta", clear
tab AGEGP
tab ALHRWK

quietly count
local N0 = r(N)
display as text "Initial sample N = " as result %12.0fc `N0'


quietly drop if missing(Wage_per_Hour_2020, ALHRWK, AGEGP)   // we need age, annual hours and wage per hour to do the analysis, so drop those with missing values
quietly count
local N1 = r(N)
display as text "After dropping missing info: N = " as result %12.0fc `N1' ///


quietly drop if Wage_per_Hour_2020 < minwage_2016_2020 
quietly count
local N3 = r(N)
display as text "After dropping below minimum wage: N = " as result %12.0fc `N3' ///


quietly drop if AGEGP < "07" | AGEGP > "13"
quietly count
local N4 = r(N)
display as text "After dropping outside age range: N = " as result %12.0fc `N4' ///


quietly drop if ALHRWK < 260
quietly count
local N5 = r(N)
display as text "After dropping below 260 annual hours: N = " as result %12.0fc `N5' ///

save "2018_data_cleaned.dta", replace

// Question 4 and 5

use "1982_SCF_data_cleaned.dta", clear

tab EDUC

gen Years_schooling = . 
replace Years_schooling = 6 if EDUC == 1 // this variable was difficult. It includes people with anywhere from 0 schooling to less than 9 years of schooling. 
replace Years_schooling = 10 if EDUC == 2 // less than high school
replace Years_schooling = 11 if EDUC == 3 
replace Years_schooling = 12 if EDUC == 4 // high school graduate
replace Years_schooling = 13 if EDUC == 5 | EDUC == 6 | EDUC == 7 // some college, associate degree, or diploma
replace Years_schooling = 16 if EDUC == 8

gen potential_experience = AGE - max(10, Years_schooling) - 6 // potential experience is age minus years of schooling, but we assume that people start school at age 10 at the earliest
label var potential_experience "Potential experience"

save "1982_SCF_data_exp.dta", replace

use "1997_SCF_data_cleaned.dta", clear

tab SUMED
gen Years_schooling = .
replace Years_schooling = 6 if SUMED == 1 // no schooling or grade 8 or lower
replace Years_schooling = 10 if SUMED == 2 // less than high school
replace Years_schooling = 11 if SUMED == 3
replace Years_schooling = 12 if SUMED == 4 // high school graduate
replace Years_schooling = 13 if SUMED == 5 | SUMED == 6 // some college, associate degree, or diploma
replace Years_schooling = 16 if SUMED == 7

gen potential_experience = AGE - max(10, Years_schooling) - 6 // potential experience is age minus years of schooling, but we assume that people start school at age 10 at the earliest
label var potential_experience "Potential experience"

save "1997_SCF_data_exp.dta", replace



use "2016_data_cleaned.dta", clear

tab HLEV2G
gen Years_schooling = .
replace Years_schooling = 6  if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace Years_schooling = 12 if HLEV2G == "2" // graduated high school or partial post-secondary
replace Years_schooling = 14 if HLEV2G == "3" // certificate or diploma
replace Years_schooling = 16 if HLEV2G == "4" // university degree

tab AGEGP
gen Age_Actual = .
replace Age_Actual = 26 if AGEGP == "07" // 25-29, was structurally impossible to reach some groups with 27 as actual age
replace Age_Actual = 32 if AGEGP == "08" // 30-34
replace Age_Actual = 37 if AGEGP == "09" // 35-39
replace Age_Actual = 42 if AGEGP == "10" // 40-44
replace Age_Actual = 47 if AGEGP == "11" // 45-49
replace Age_Actual = 52 if AGEGP == "12" // 50-54
replace Age_Actual = 57 if AGEGP == "13" // 55-59

gen potential_experience = Age_Actual - max(10, Years_schooling) - 6 // potential experience is age minus years of schooling, but we assume that people start school at age 10 at the earliest
label var potential_experience "Potential experience"

save "2016_data_exp.dta", replace

use "2018_data_cleaned.dta", clear

tab HLEV2G
gen Years_schooling = .
replace Years_schooling = 6  if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace Years_schooling = 12 if HLEV2G == "2" // graduated high school or partial post-secondary
replace Years_schooling = 14 if HLEV2G == "3" // certificate or diploma
replace Years_schooling = 16 if HLEV2G == "4" // university degree

tab AGEGP
gen Age_Actual = .
replace Age_Actual = 26 if AGEGP == "07" // 25-29, was structurally impossible to reach some groups with 27 as actual age
replace Age_Actual = 32 if AGEGP == "08" // 30-34
replace Age_Actual = 37 if AGEGP == "09" // 35-39
replace Age_Actual = 42 if AGEGP == "10" // 40-44
replace Age_Actual = 47 if AGEGP == "11" // 45-49
replace Age_Actual = 52 if AGEGP == "12" // 50-54
replace Age_Actual = 57 if AGEGP == "13" // 55-59

gen potential_experience = Age_Actual - max(10, Years_schooling) - 6 // potential experience is age minus years of schooling, but we assume that people start school at age 10 at the earliest
label var potential_experience "Potential experience"

save "2018_data_exp.dta", replace

use "1982_SCF_data_exp.dta", clear

// weights dont exist for this year
gen ln_WpH = log(Wage_per_Hour_2020) if Wage_per_Hour_2020 > 0
quietly summarize Wage_per_Hour_2020 
scalar mean_WpH_82 = r(mean)
display mean_WpH_82

quietly summarize ln_WpH
scalar var_log_WpH_82 = r(Var)
display var_log_WpH_82

summarize Years_schooling
scalar mean_school_82 = r(mean)
scalar var_school_82  = r(Var)
display mean_school_82
display var_school_82

quietly summarize potential_experience
scalar mean_exp_82 = r(mean)
scalar var_exp_82  = r(Var)
display mean_exp_82
display var_exp_82


save "1982_SCF_data_log.dta", replace

use "1997_SCF_data_exp.dta", clear

gen ln_WpH = log(Wage_per_Hour_2020) if Wage_per_Hour_2020 > 0
quietly summarize Wage_per_Hour_2020 [aw=WEIGHT] if Wage_per_Hour_2020 > 0
scalar mean_WpH_97 = r(mean)
display mean_WpH_97

quietly summarize ln_WpH [aw=WEIGHT]
scalar var_log_WpH_97 = r(Var)
display var_log_WpH_97

quietly summarize Years_schooling [aw=WEIGHT] 
scalar mean_school_97 = r(mean)
scalar var_school_97  = r(Var)
display mean_school_97
display var_school_97

quietly summarize potential_experience [aw=WEIGHT] 
scalar mean_exp_97 = r(mean)
scalar var_exp_97  = r(Var)
display mean_exp_97
display var_exp_97

save "1997_SCF_data_log.dta", replace

use "2016_data_exp.dta", clear

gen ln_WpH = log(Wage_per_Hour_2020) if Wage_per_Hour_2020 > 0
quietly summarize Wage_per_Hour_2020 [aw=FWEIGHT] if Wage_per_Hour_2020 > 0
scalar mean_WpH_16 = r(mean)
display mean_WpH_16

quietly summarize ln_WpH [aw=FWEIGHT]
scalar var_log_WpH_16 = r(Var)
display var_log_WpH_16

quietly summarize Years_schooling [aw=FWEIGHT]
scalar mean_school_16 = r(mean)
scalar var_school_16  = r(Var)
display mean_school_16
display var_school_16

quietly summarize potential_experience [aw=FWEIGHT]
scalar mean_exp_16 = r(mean)
scalar var_exp_16  = r(Var)
display mean_exp_16
display var_exp_16

save "2016_data_log.dta", replace

use "2018_data_exp.dta", clear

gen ln_WpH = log(Wage_per_Hour_2020) if Wage_per_Hour_2020 > 0
quietly summarize Wage_per_Hour_2020 [aw=FWEIGHT] if Wage_per_Hour_2020 > 0
scalar mean_WpH_18 = r(mean)
display mean_WpH_18

quietly summarize ln_WpH [aw=FWEIGHT]
scalar var_log_WpH_18 = r(Var)
display var_log_WpH_18

quietly summarize Years_schooling [aw=FWEIGHT]
scalar mean_school_18 = r(mean)
scalar var_school_18  = r(Var)
display mean_school_18
display var_school_18

quietly summarize potential_experience [aw=FWEIGHT]
scalar mean_exp_18 = r(mean)
scalar var_exp_18  = r(Var)
display mean_exp_18
display var_exp_18

save "2018_data_log.dta", replace

// Question 7
// Mincer the data

use "1982_SCF_data_log.dta", clear

summarize ln_WpH
gen Exp2 = potential_experience^2
reg ln_WpH Years_schooling potential_experience Exp2

save "1982_SCF_data_mincer.dta", replace


use "1997_SCF_data_log.dta", clear

gen Exp2 = potential_experience^2
reg ln_WpH Years_schooling potential_experience Exp2 [aw=WEIGHT]

save "1997_SCF_data_mincer.dta", replace


use "2016_data_log.dta", clear

gen Exp2 = potential_experience^2
reg ln_WpH Years_schooling potential_experience Exp2 [aw=FWEIGHT]

save "2016_data_mincer.dta", replace

use "2018_data_log.dta", clear

gen Exp2 = potential_experience^2
reg ln_WpH Years_schooling potential_experience Exp2 [aw=FWEIGHT]



// (b) 
summarize potential_experience if Wage_per_Hour_2020 > 0
display r(mean)

display .0213126 + 2 * -.0004132 * 21.579819


save "2018_data_mincer.dta", replace

// Question 8


use "1982_SCF_data_mincer.dta", clear

// Specification 1, 
label list SEX
gen SEX_F = .
replace SEX_F = 1 if SEX == 2
replace SEX_F = 0 if SEX == 1

gen female_school = SEX_F * Years_schooling
gen female_exp    = SEX_F * potential_experience
gen female_exp2   = SEX_F * Exp2

// Specification 2,
tab GEOCODE
describe GEOCODE
label list GEOCODE

gen PROV = .

replace PROV = 10 if GEOCODE == 10
replace PROV = 11 if GEOCODE == 11
replace PROV = 12 if GEOCODE == 12
replace PROV = 13 if GEOCODE == 13
replace PROV = 24 if GEOCODE == 24
replace PROV = 35 if GEOCODE == 35
replace PROV = 46 if GEOCODE == 46
replace PROV = 47 if GEOCODE == 47
replace PROV = 48 if GEOCODE == 48
replace PROV = 59 if GEOCODE == 59



reg ln_WpH Years_schooling potential_experience Exp2 ///
    SEX_F female_school female_exp female_exp2 // [aw=WEIGHT]

reg ln_WpH Years_schooling potential_experience Exp2 i.PROV // [aw=WEIGHT]

save "1982_SCF_data_mincerx2.dta", replace


use "1997_SCF_data_mincer.dta", clear

// Specification 1, 
label list SEX
gen SEX_F = .
replace SEX_F = 1 if SEX == 2
replace SEX_F = 0 if SEX == 1

gen female_school = SEX_F * Years_schooling
gen female_exp    = SEX_F * potential_experience
gen female_exp2   = SEX_F * Exp2

// Specification 2,
tab PROV
label list PROV


reg ln_WpH Years_schooling potential_experience Exp2 ///
    SEX_F female_school female_exp female_exp2 [aw=WEIGHT]

reg ln_WpH Years_schooling potential_experience Exp2 i.PROV [aw=WEIGHT]

save "1997_SCF_data_mincerx2.dta", replace


use "2016_data_mincer.dta", clear

tab SEX
label list SEX
gen SEX_F = .
replace SEX_F = 1 if SEX == "2"
replace SEX_F = 0 if SEX == "1"

gen female_school = SEX_F * Years_schooling
gen female_exp    = SEX_F * potential_experience
gen female_exp2   = SEX_F * Exp2

// Specification 2,
tab PROV
label list PROV

gen PROV_R = .
replace PROV_R = 10 if PROV == "10"
replace PROV_R = 11 if PROV == "11"
replace PROV_R = 12 if PROV == "12"
replace PROV_R = 13 if PROV == "13"
replace PROV_R = 24 if PROV == "24"
replace PROV_R = 35 if PROV == "35"
replace PROV_R = 46 if PROV == "46"
replace PROV_R = 47 if PROV == "47"
replace PROV_R = 48 if PROV == "48"
replace PROV_R = 59 if PROV == "59"


reg ln_WpH Years_schooling potential_experience Exp2 ///
    SEX_F female_school female_exp female_exp2 [aw=FWEIGHT]

reg ln_WpH Years_schooling potential_experience Exp2 i.PROV_R [aw=FWEIGHT]


save "2016_data_mincerx2.dta", replace

use "2018_data_mincer.dta", clear

tab SEX
gen SEX_F = .
replace SEX_F = 1 if SEX == "2"
replace SEX_F = 0 if SEX == "1"

gen female_school = SEX_F * Years_schooling
gen female_exp    = SEX_F * potential_experience
gen female_exp2   = SEX_F * Exp2

// Specification 2,
tab PROV


gen PROV_R = .
replace PROV_R = 10 if PROV == "10"
replace PROV_R = 11 if PROV == "11"
replace PROV_R = 12 if PROV == "12"
replace PROV_R = 13 if PROV == "13"
replace PROV_R = 24 if PROV == "24"
replace PROV_R = 35 if PROV == "35"
replace PROV_R = 46 if PROV == "46"
replace PROV_R = 47 if PROV == "47"
replace PROV_R = 48 if PROV == "48"
replace PROV_R = 59 if PROV == "59"


reg ln_WpH Years_schooling potential_experience Exp2 ///
    SEX_F female_school female_exp female_exp2 [aw=FWEIGHT]

reg ln_WpH Years_schooling potential_experience Exp2 i.PROV_R [aw=FWEIGHT]


save "2018_data_mincerx2.dta", replace


// Question 11,

use "1982_SCF_data_mincerx2.dta", clear

keep ln_WpH Years_schooling potential_experience Exp2
gen Year = 0

save "1982_small.dta", replace


use "2018_data_mincerx2.dta", clear

keep ln_WpH Years_schooling potential_experience Exp2
gen Year = 1

append using "1982_small.dta"

reg ln_WpH ///
    c.Years_schooling##i.Year ///
    c.potential_experience##i.Year ///
    c.Exp2##i.Year

save "Combined_2018_1982.dta", replace


// Question 12, 


use "1982_SCF_data_mincerx2.dta", clear

keep ln_WpH Years_schooling potential_experience Exp2
reg ln_WpH Years_schooling potential_experience Exp2
estimates store reg1982

use "2018_data_mincerx2.dta", clear

keep ln_WpH Years_schooling potential_experience Exp2
reg ln_WpH Years_schooling potential_experience Exp2
estimates store reg2018

estimates restore reg1982
predict xb_1982prices_2018attrs, xb
summarize xb_1982prices_2018attrs
scalar var_xb_1982prices_2018attrs = r(Var)

estimates restore reg2018
predict xb_2018prices_2018attrs, xb
summarize xb_2018prices_2018attrs
scalar var_xb_2018prices_2018attrs = r(Var)

display var_xb_1982prices_2018attrs

display var_xb_2018prices_2018attrs

display var_xb_2018prices_2018attrs - var_xb_1982prices_2018attrs

// Question 13, 

use "1982_SCF_data_mincer.dta", clear

reg ln_WpH Years_schooling potential_experience Exp2
predict resid1982, resid

sum resid1982
scalar residvar1982 = r(Var)

sum ln_WpH
scalar totalvar1982 = r(Var)

display residvar1982
display residvar1982 / totalvar1982

use "1997_SCF_data_mincer.dta", clear

reg ln_WpH Years_schooling potential_experience Exp2 [aw=WEIGHT]
predict resid1997, resid

sum resid1997
scalar residvar1997 = r(Var)

sum ln_WpH [aw=WEIGHT]
scalar totalvar1997 = r(Var)

display residvar1997
display residvar1997 / totalvar1997


use "2016_data_mincer.dta", clear

reg ln_WpH Years_schooling potential_experience Exp2 [aw=FWEIGHT]
predict resid2016, resid

sum resid2016
scalar residvar2016 = r(Var)

sum ln_WpH [aw=FWEIGHT]
scalar totalvar2016 = r(Var)

display residvar2016
display residvar2016 / totalvar2016


use "2018_data_mincer.dta", clear

reg ln_WpH Years_schooling potential_experience Exp2 [aw=FWEIGHT]
predict resid2018, resid

sum resid2018
scalar residvar2018 = r(Var)

sum ln_WpH [aw=FWEIGHT]
scalar totalvar2018 = r(Var)

display residvar2018
display residvar2018 / totalvar2018



