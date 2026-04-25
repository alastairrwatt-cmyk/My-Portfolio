log using "Assignment_2_Final.log", text replace

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

use "yearmap_final.dta", clear
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
tab WAGSAL

replace USHOURS = 66.5 if USHOURS == 65 // in order the balance out the people who may have worked more than 65 hours

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

gen Annual_Hours = HRSWRK * 52 if HRSWRK > 0 // only calculate annual hours for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Annual_Hours "Annual hours worked"

gen Wage_per_Hour = WAGSAL / Annual_Hours if Annual_Hours > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s1982_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "1982_SCF_data_wage.dta", replace

use "2016_data.dta", clear

tab ALHRWK
gen Wage_per_Hour = WGSAL / ALHRWK if ALHRWK > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s2016_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour_2020 "Wage per hour in 2020$"

save "2016_data_wage.dta", replace

use "2018_data.dta", clear

tab ALHRWK
gen Wage_per_Hour = WGSAL / ALHRWK if ALHRWK > 0 // only calculate wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
label var Wage_per_Hour "Wage per hour"

gen Wage_per_Hour_2020 = Wage_per_Hour * s2016_to_2020 if Wage_per_Hour > 0 // only adjust wage per hour for those who have positive hours, otherwise it will be zero and mess up the wage per hour calculation
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



// Question 4

use "1982_SCF_data_cleaned.dta", clear

// (a)

gen log_TOTINC = log(TOTINC) if TOTINC > 0
label var log_TOTINC "Log of total income"

gen log_INCAFTTX = log(INCAFTTX) if INCAFTTX > 0
label var log_INCAFTTX "Log of income after tax"

gen log_WAGSAL = log(WAGSAL) if WAGSAL > 0
label var log_WAGSAL "Log of wage and salary income"

quietly summarize log_TOTINC
scalar var_TOTINC_1982 = r(Var)
display var_TOTINC_1982

quietly summarize log_INCAFTTX
scalar var_INCAFTTX_1982 = r(Var)
display var_INCAFTTX_1982

quietly summarize log_WAGSAL
scalar var_WAGSAL_1982 = r(Var)
display var_WAGSAL_1982

quietly ineqdeco TOTINC
scalar gini_TOTINC_1982 = r(gini)
display gini_TOTINC_1982

quietly ineqdeco INCAFTTX
scalar gini_INCAFTTX_1982 = r(gini)
display gini_INCAFTTX_1982

quietly ineqdeco WAGSAL
scalar gini_WAGSAL_1982 = r(gini)
display gini_WAGSAL_1982

// (b)

// men
gen log_Annual_Hours = log(Annual_Hours) if Annual_Hours>0
label var log_Annual_Hours "Log of annual hours"

gen log_WpH_2020 = log(Wage_per_Hour_2020) if Wage_per_Hour_2020>0
label var log_WpH_2020 "Log of wage per hour (2020)"

quietly summarize log_Annual_Hours if SEX==1
scalar var_lAH_m_1982 = r(Var)
display var_lAH_m_1982

quietly summarize log_WpH_2020 if SEX==1
scalar var_lWpH_m_1982 = r(Var)
display var_lWpH_m_1982

quietly summarize log_WAGSAL if SEX==1
scalar var_lWAGSAL_m_1982 = r(Var)
display var_lWAGSAL_m_1982

quietly correlate log_Annual_Hours log_WpH_2020 if SEX==1
matrix Cm = r(C)
scalar corr_m_1982 = Cm[1,2]
display corr_m_1982

// women

quietly summarize log_Annual_Hours if SEX==2
scalar var_lAH_w_1982 = r(Var)
display var_lAH_w_1982

quietly summarize log_WpH_2020 if SEX==2
scalar var_lWpH_w_1982 = r(Var)
display var_lWpH_w_1982

quietly summarize log_WAGSAL if SEX==2
scalar var_lWAGSAL_w_1982 = r(Var)
display var_lWAGSAL_w_1982

quietly correlate log_Annual_Hours log_WpH_2020 if SEX==2
matrix Cm = r(C)
scalar corr_w_1982 = Cm[1,2]
display corr_w_1982

// (c) 

quietly centile Wage_per_Hour_2020, centile(5 50 95)
scalar p5_1982  = r(c_1)
scalar p50_1982 = r(c_2)
scalar p95_1982 = r(c_3)

display p5_1982
display p50_1982
display p95_1982

save "1982_SCF_data_logs.dta", replace

///

use "1997_SCF_data_cleaned.dta", clear

gen log_TOTINC = log(TOTINC) if TOTINC > 0
label var log_TOTINC "Log of total income"

gen log_INCFTX = log(INCFTX) if INCFTX > 0
label var log_INCFTX "Log of income after tax"

gen log_WAGSAL = log(WAGSAL) if WAGSAL > 0
label var log_WAGSAL "Log of wage and salary income"

quietly summarize log_TOTINC
scalar var_TOTINC_1997 = r(Var)
display var_TOTINC_1997

quietly summarize log_INCFTX
scalar var_INCFTX_1997 = r(Var)
display var_INCFTX_1997

quietly summarize log_WAGSAL
scalar var_WAGSAL_1997 = r(Var)
display var_WAGSAL_1997

quietly ineqdeco TOTINC
scalar gini_TOTINC_1997 = r(gini)
display gini_TOTINC_1997

quietly ineqdeco INCFTX
scalar gini_INCFTX_1997 = r(gini)
display gini_INCFTX_1997

quietly ineqdeco WAGSAL
scalar gini_WAGSAL_1997 = r(gini)
display gini_WAGSAL_1997

// (b)

// men
gen log_Annual_Hours = log(Annual_Hours) if Annual_Hours>0
label var log_Annual_Hours "Log of annual hours"

gen log_WpH_2020 = log(Wage_per_Hour_2020) if Wage_per_Hour_2020>0
label var log_WpH_2020 "Log of wage per hour (2020)"

quietly summarize log_Annual_Hours if SEX==1
scalar var_lAH_m_1997 = r(Var)
display var_lAH_m_1997

quietly summarize log_WpH_2020 if SEX==1
scalar var_lWpH_m_1997 = r(Var)
display var_lWpH_m_1997

quietly summarize log_WAGSAL if SEX==1
scalar var_lWAGSAL_m_1997 = r(Var)
display var_lWAGSAL_m_1997

quietly correlate log_Annual_Hours log_WpH_2020 if SEX==1
matrix Cm = r(C)
scalar corr_m_1997 = Cm[1,2]
display corr_m_1997

// women

quietly summarize log_Annual_Hours if SEX==2
scalar var_lAH_w_1997 = r(Var)
display var_lAH_w_1997

quietly summarize log_WpH_2020 if SEX==2
scalar var_lWpH_w_1997 = r(Var)
display var_lWpH_w_1997

quietly summarize log_WAGSAL if SEX==2
scalar var_lWAGSAL_w_1997 = r(Var)
display var_lWAGSAL_w_1997

quietly correlate log_Annual_Hours log_WpH_2020 if SEX==2
matrix Cm = r(C)
scalar corr_w_1997 = Cm[1,2]
display corr_w_1997

// (c) 

quietly centile Wage_per_Hour_2020, centile(5 50 95)
scalar p5_1997 = r(c_1)
scalar p50_1997 = r(c_2)
scalar p95_1997 = r(c_3)

display p5_1997
display p50_1997
display p95_1997

save "1997_SCF_data_logs.dta", replace


use "2016_data_cleaned.dta", clear

gen log_TTINC = log(TTINC) if TTINC > 0
label var log_TTINC "Log of total income"

gen log_ATINC = log(ATINC) if ATINC > 0
label var log_ATINC "Log of income after tax"

gen log_WGSAL = log(WGSAL) if WGSAL > 0
label var log_WGSAL "Log of wage and salary income"

quietly summarize log_TTINC
scalar var_TTINC_2016 = r(Var)
display var_TTINC_2016

quietly summarize log_ATINC
scalar var_ATINC_2016 = r(Var)
display var_ATINC_2016

quietly summarize log_WGSAL
scalar var_WGSAL_2016 = r(Var)
display var_WGSAL_2016

quietly ineqdeco TTINC
scalar gini_TTINC_2016 = r(gini)
display gini_TTINC_2016

quietly ineqdeco ATINC
scalar gini_ATINC_2016 = r(gini)
display gini_ATINC_2016

quietly ineqdeco WGSAL
scalar gini_WGSAL_2016 = r(gini)
display gini_WGSAL_2016

// (b)

// men
gen log_ALHRWK = log(ALHRWK) if ALHRWK>0
label var log_ALHRWK "Log of annual hours"

gen log_WpH_2020 = log(Wage_per_Hour_2020) if Wage_per_Hour_2020>0
label var log_WpH_2020 "Log of wage per hour (2020)"

quietly summarize log_ALHRWK if SEX=="1"
scalar var_lAH_m_2016 = r(Var)
display var_lAH_m_2016

quietly summarize log_WpH_2020 if SEX=="1"
scalar var_lWpH_m_2016 = r(Var)
display var_lWpH_m_2016

quietly summarize log_WGSAL if SEX=="1"
scalar var_lWGSAL_m_2016 = r(Var)
display var_lWGSAL_m_2016

quietly correlate log_ALHRWK log_WpH_2020 if SEX=="1"
matrix Cm = r(C)
scalar corr_m_2016 = Cm[1,2]
display corr_m_2016

// women

quietly summarize log_ALHRWK if SEX=="2"
scalar var_lAH_w_2016 = r(Var)
display var_lAH_w_2016

quietly summarize log_WpH_2020 if SEX=="2"
scalar var_lWpH_w_2016 = r(Var)
display var_lWpH_w_2016

quietly summarize log_WGSAL if SEX=="2"
scalar var_lWGSAL_w_2016 = r(Var)
display var_lWGSAL_w_2016

quietly correlate log_ALHRWK log_WpH_2020 if SEX=="2"
matrix Cm = r(C)
scalar corr_w_2016 = Cm[1,2]
display corr_w_2016

// (c) 

quietly centile Wage_per_Hour_2020, centile(5 50 95)
scalar p5_2016 = r(c_1)
scalar p50_2016 = r(c_2)
scalar p95_2016 = r(c_3)

display p5_2016
display p50_2016
display p95_2016

save "2016_data_logs.dta", replace

use "2018_data_cleaned.dta", clear

gen log_TTINC = log(TTINC) if TTINC > 0
label var log_TTINC "Log of total income"

gen log_ATINC = log(ATINC) if ATINC > 0
label var log_ATINC "Log of income after tax"

gen log_WGSAL = log(WGSAL) if WGSAL > 0
label var log_WGSAL "Log of wage and salary income"

quietly summarize log_TTINC
scalar var_TTINC_2018 = r(Var)
display var_TTINC_2018

quietly summarize log_ATINC
scalar var_ATINC_2018 = r(Var)
display var_ATINC_2018

quietly summarize log_WGSAL
scalar var_WGSAL_2018 = r(Var)
display var_WGSAL_2018

quietly ineqdeco TTINC
scalar gini_TTINC_2018 = r(gini)
display gini_TTINC_2018

quietly ineqdeco ATINC
scalar gini_ATINC_2018 = r(gini)
display gini_ATINC_2018

quietly ineqdeco WGSAL
scalar gini_WGSAL_2018 = r(gini)
display gini_WGSAL_2018

// (b)

// men
gen log_ALHRWK = log(ALHRWK) if ALHRWK>0
label var log_ALHRWK "Log of annual hours"

gen log_WpH_2020 = log(Wage_per_Hour_2020) if Wage_per_Hour_2020>0
label var log_WpH_2020 "Log of wage per hour (2020)"

quietly summarize log_ALHRWK if SEX=="1"
scalar var_lAH_m_2018 = r(Var)
display var_lAH_m_2018

quietly summarize log_WpH_2020 if SEX=="1"
scalar var_lWpH_m_2018 = r(Var)
display var_lWpH_m_2018

quietly summarize log_WGSAL if SEX=="1"
scalar var_lWGSAL_m_2018 = r(Var)
display var_lWGSAL_m_2018

quietly correlate log_ALHRWK log_WpH_2020 if SEX=="1"
matrix Cm = r(C)
scalar corr_m_2018 = Cm[1,2]
display corr_m_2018

// women

quietly summarize log_ALHRWK if SEX=="2"
scalar var_lAH_w_2018 = r(Var)
display var_lAH_w_2018

quietly summarize log_WpH_2020 if SEX=="2"
scalar var_lWpH_w_2018 = r(Var)
display var_lWpH_w_2018

quietly summarize log_WGSAL if SEX=="2"
scalar var_lWGSAL_w_2018 = r(Var)
display var_lWGSAL_w_2018

quietly correlate log_ALHRWK log_WpH_2020 if SEX=="2"
matrix Cm = r(C)
scalar corr_w_2018 = Cm[1,2]
display corr_w_2018

// (c) 

quietly centile Wage_per_Hour_2020, centile(5 50 95)
scalar p5_2018 = r(c_1)
scalar p50_2018 = r(c_2)
scalar p95_2018 = r(c_3)

display p5_2018
display p50_2018
display p95_2018


save "2018_data_logs.dta", replace

// graph 1
preserve
clear
set obs 4

gen year = .
replace year = 1982 in 1
replace year = 1997 in 2
replace year = 2016 in 3
replace year = 2018 in 4

gen var_total   = . // these variables are just as placeholders to better visualise 
// clearly the graphs, not strictly necessary
gen var_aftertax= .
gen var_wages   = .

* 1982
replace var_total    = scalar(var_TOTINC_1982)     in 1
replace var_aftertax = scalar(var_INCAFTTX_1982)   in 1
replace var_wages    = scalar(var_WAGSAL_1982)     in 1

* 1997
replace var_total    = scalar(var_TOTINC_1997)     in 2
replace var_aftertax = scalar(var_INCFTX_1997)     in 2
replace var_wages    = scalar(var_WAGSAL_1997)     in 2

* 2016
replace var_total    = scalar(var_TTINC_2016)      in 3
replace var_aftertax = scalar(var_ATINC_2016)      in 3
replace var_wages    = scalar(var_WGSAL_2016)      in 3

* 2018
replace var_total    = scalar(var_TTINC_2018)      in 4
replace var_aftertax = scalar(var_ATINC_2018)      in 4
replace var_wages    = scalar(var_WGSAL_2018)      in 4

sort year

twoway (line var_total year, lwidth(medthick)) ///
       (line var_aftertax year, lpattern(dash)) ///
       (line var_wages year, lcolor(green)), ///
       title("Log variance over time") ///
       xtitle("Year") ytitle("Variance of log") ///
       legend(order(1 "Total income" 2 "After-tax income" 3 "Wages & salaries"))

restore

// graph 2
preserve
clear
set obs 4

gen year = .
replace year = 1982 in 1
replace year = 1997 in 2
replace year = 2016 in 3
replace year = 2018 in 4

gen gini_total   = .
gen gini_aftertax= .
gen gini_wages   = .

* 1982
replace gini_total    = scalar(gini_TOTINC_1982)     in 1
replace gini_aftertax = scalar(gini_INCAFTTX_1982)   in 1
replace gini_wages    = scalar(gini_WAGSAL_1982)     in 1

* 1997
replace gini_total    = scalar(gini_TOTINC_1997)     in 2
replace gini_aftertax = scalar(gini_INCFTX_1997)     in 2
replace gini_wages    = scalar(gini_WAGSAL_1997)     in 2

* 2016
replace gini_total    = scalar(gini_TTINC_2016)      in 3
replace gini_aftertax = scalar(gini_ATINC_2016)      in 3
replace gini_wages    = scalar(gini_WGSAL_2016)      in 3

* 2018
replace gini_total    = scalar(gini_TTINC_2018)      in 4
replace gini_aftertax = scalar(gini_ATINC_2018)      in 4
replace gini_wages    = scalar(gini_WGSAL_2018)      in 4

sort year

twoway (line gini_total year, lwidth(medthick)) ///
       (line gini_aftertax year, lpattern(dash)) ///
       (line gini_wages year, lcolor(green)), ///
       title("Gini coefficient over time") ///
       xtitle("Year") ytitle("Gini") ///
       legend(order(1 "Total income" 2 "After-tax income" 3 "Wages & salaries"))

restore

// graph 4

preserve
clear
set obs 4

gen year = .
replace year = 1982 in 1
replace year = 1997 in 2
replace year = 2016 in 3
replace year = 2018 in 4

gen var_log_annualwage = .
gen var_log_hourlywage = .
gen var_log_hours      = .
gen corr_logh_logw     = .

* 1982 men
replace var_log_annualwage = scalar(var_lWAGSAL_m_1982) in 1
replace var_log_hourlywage = scalar(var_lWpH_m_1982)    in 1
replace var_log_hours      = scalar(var_lAH_m_1982)     in 1
replace corr_logh_logw     = scalar(corr_m_1982)        in 1

* 1997 men
replace var_log_annualwage = scalar(var_lWAGSAL_m_1997) in 2
replace var_log_hourlywage = scalar(var_lWpH_m_1997)    in 2
replace var_log_hours      = scalar(var_lAH_m_1997)     in 2
replace corr_logh_logw     = scalar(corr_m_1997)        in 2

* 2016 men
replace var_log_annualwage = scalar(var_lWGSAL_m_2016)  in 3
replace var_log_hourlywage = scalar(var_lWpH_m_2016)    in 3
replace var_log_hours      = scalar(var_lAH_m_2016)     in 3
replace corr_logh_logw     = scalar(corr_m_2016)        in 3

* 2018 men
replace var_log_annualwage = scalar(var_lWGSAL_m_2018)  in 4
replace var_log_hourlywage = scalar(var_lWpH_m_2018)    in 4
replace var_log_hours      = scalar(var_lAH_m_2018)     in 4
replace corr_logh_logw     = scalar(corr_m_2018)        in 4

sort year

twoway (line var_log_annualwage year, lwidth(medthick)) ///
       (line var_log_hourlywage year, lcolor(blue)) ///
       (line var_log_hours year, lcolor(maroon)) ///
       (line corr_logh_logw year, lpattern(shortdash)), ///
       title("Men: variances and corr over time") ///
       xtitle("Year") ///
       legend(order(1 "Var(log annual wages)" ///
                    2 "Var(log hourly wages)" ///
                    3 "Var(log annual hours)" ///
                    4 "Corr(log hours, log hourly wage)"))

restore


preserve
clear
set obs 4

gen year = .
replace year = 1982 in 1
replace year = 1997 in 2
replace year = 2016 in 3
replace year = 2018 in 4

gen var_log_annualwage = . 
gen var_log_hourlywage = .
gen var_log_hours      = .
gen corr_logh_logw     = .

* 1982 women
replace var_log_annualwage = scalar(var_lWAGSAL_w_1982) in 1
replace var_log_hourlywage = scalar(var_lWpH_w_1982)    in 1
replace var_log_hours      = scalar(var_lAH_w_1982)     in 1
replace corr_logh_logw     = scalar(corr_w_1982)        in 1

* 1997 women
replace var_log_annualwage = scalar(var_lWAGSAL_w_1997) in 2
replace var_log_hourlywage = scalar(var_lWpH_w_1997)    in 2
replace var_log_hours      = scalar(var_lAH_w_1997)     in 2
replace corr_logh_logw     = scalar(corr_w_1997)        in 2

* 2016 women
replace var_log_annualwage = scalar(var_lWGSAL_w_2016)  in 3
replace var_log_hourlywage = scalar(var_lWpH_w_2016)    in 3
replace var_log_hours      = scalar(var_lAH_w_2016)     in 3
replace corr_logh_logw     = scalar(corr_w_2016)        in 3

* 2018 women
replace var_log_annualwage = scalar(var_lWGSAL_w_2018)  in 4
replace var_log_hourlywage = scalar(var_lWpH_w_2018)    in 4
replace var_log_hours      = scalar(var_lAH_w_2018)     in 4
replace corr_logh_logw     = scalar(corr_w_2018)        in 4

sort year

twoway (line var_log_annualwage year, lwidth(medthick)) ///
       (line var_log_hourlywage year, lcolor(blue)) ///
       (line var_log_hours year, lcolor(maroon)) ///
       (line corr_logh_logw year, lpattern(shortdash)), ///
       title("Women: variances and corr over time") ///
       xtitle("Year") ///
       legend(order(1 "Var(log annual wages)" ///
                    2 "Var(log hourly wages)" ///
                    3 "Var(log annual hours)" ///
                    4 "Corr(log hours, log hourly wage)"))

restore



preserve
clear
set obs 4

gen year = .
replace year = 1982 in 1
replace year = 1997 in 2
replace year = 2016 in 3
replace year = 2018 in 4

gen p5  = .
gen p50 = .
gen p95 = .

replace p5  = scalar(p5_1982)  in 1
replace p50 = scalar(p50_1982) in 1
replace p95 = scalar(p95_1982) in 1

replace p5  = scalar(p5_1997)  in 2
replace p50 = scalar(p50_1997) in 2
replace p95 = scalar(p95_1997) in 2

replace p5  = scalar(p5_2016)  in 3
replace p50 = scalar(p50_2016) in 3
replace p95 = scalar(p95_2016) in 3

replace p5  = scalar(p5_2018)  in 4
replace p50 = scalar(p50_2018) in 4
replace p95 = scalar(p95_2018) in 4

sort year

twoway (line p5 year, lcolor(orange)) ///
       (line p50 year, lwidth(medthick)) ///
       (line p95 year, lpattern(dash)), ///
       title("Hourly wage percentiles over time") ///
       xtitle("Year") ytitle("Hourly wage") ///
       legend(order(1 "p5" 2 "p50" 3 "p95"))

restore


// Question 5 
// (a)

use "1982_SCF_data_logs.dta", clear
browse

tab EDUC
summarize EDUC, detail
display EDUC[6]

gen Years_schooling = .

replace Years_schooling = 0  if EDUC == 1
replace Years_schooling = 9.5 if EDUC == 2 // for 9 or 10 years of schooling
replace Years_schooling = 11 if EDUC == 3
replace Years_schooling = 12 if EDUC == 4
replace Years_schooling = 13 if EDUC == 5
replace Years_schooling = 14.5 if EDUC == 6 // some post secondary
replace Years_schooling = 15 if EDUC == 7 // post-secondary or diploma 
replace Years_schooling = 17 if EDUC == 8 // university degree

tab AGE, nolabel
gen potential_experience = AGE - Years_schooling - 6

// serious issues as groups do not have any clear way of ordering them into groups like in AKK.
// I have only done 4 educational groups as the result
gen EDUC_AKK = .
replace EDUC_AKK = 1 if EDUC == 1 | EDUC == 2 | EDUC == 3
replace EDUC_AKK = 2 if EDUC == 4 | EDUC == 5
replace EDUC_AKK = 3 if EDUC == 6 | EDUC == 7
replace EDUC_AKK = 4 if EDUC == 8 

gen Pot_exp_AKK = .
replace Pot_exp_AKK = 1 if potential_experience < 13
replace Pot_exp_AKK = 2 if potential_experience >= 13 & potential_experience < 23
replace Pot_exp_AKK = 3 if potential_experience >= 23 & potential_experience < 33
replace Pot_exp_AKK = 4 if potential_experience >= 33

// (b)
egen Group_1982 = group(SEX EDUC_AKK Pot_exp_AKK)
tab Group_1982

save "1982_SCF_data_groups.dta", replace



use "1982_SCF_data_groups.dta", clear

keep Group_1982 SEX EDUC_AKK Pot_exp_AKK WAGSAL
    drop if missing(Group_1982, SEX, EDUC_AKK, Pot_exp_AKK, WAGSAL)

    gen one = 1
    quietly summarize one, meanonly
    scalar Ntot = r(sum)

    collapse (sum) n_group=one (mean) mean_wage=WAGSAL ///
             (first) SEX EDUC_AKK Pot_exp_AKK, by(Group_1982)

    gen share = n_group / Ntot
    gen year  = 1982
    rename Group_1982 Group
    keep year Group SEX EDUC_AKK Pot_exp_AKK share mean_wage
    save "grpstats_1982.dta", replace

use "grpstats_1982.dta", clear
summ share, meanonly
display r(sum)  // = 1, so all good

use "1997_SCF_data_logs.dta", clear

tab SUMED
summarize SUMED, detail
display SUMED[6]

gen Years_schooling = .

replace Years_schooling = 0  if SUMED == 1
replace Years_schooling = 9.5 if SUMED == 2 // for 9 or 10 years of schooling
replace Years_schooling = 12 if SUMED == 3
replace Years_schooling = 12 if SUMED == 4
replace Years_schooling = 14 if SUMED == 5 // some post secondary no diploma
replace Years_schooling = 15 if SUMED == 6 // post-secondary or diploma
replace Years_schooling = 17 if SUMED == 7 // university degree

tab AGE, nolabel
gen potential_experience = AGE - Years_schooling - 6

gen EDUC_AKK = .
replace EDUC_AKK = 1 if SUMED == 1 | SUMED == 2
replace EDUC_AKK = 2 if SUMED == 3 | SUMED == 4
replace EDUC_AKK = 3 if SUMED == 5 | SUMED == 6
replace EDUC_AKK = 4 if SUMED == 7

gen Pot_exp_AKK = .
replace Pot_exp_AKK = 1 if potential_experience < 13
replace Pot_exp_AKK = 2 if potential_experience >= 13 & potential_experience < 23
replace Pot_exp_AKK = 3 if potential_experience >= 23 & potential_experience < 33
replace Pot_exp_AKK = 4 if potential_experience >= 33

// (b)
egen Group_1997 = group(SEX EDUC_AKK Pot_exp_AKK)
tab Group_1997

save "1997_SCF_data_groups.dta", replace


use "1997_SCF_data_groups.dta", clear

keep Group_1997 SEX EDUC_AKK Pot_exp_AKK WAGSAL
    drop if missing(Group_1997, SEX, EDUC_AKK, Pot_exp_AKK, WAGSAL)

    gen one = 1
    quietly summarize one, meanonly
    scalar Ntot = r(sum)

    collapse (sum) n_group=one (mean) mean_wage=WAGSAL ///
             (first) SEX EDUC_AKK Pot_exp_AKK, by(Group_1997)

    gen share = n_group / Ntot
    gen year  = 1997
    rename Group_1997 Group

    keep year Group SEX EDUC_AKK Pot_exp_AKK share mean_wage
    save "grpstats_1997.dta", replace

use "grpstats_1997.dta", clear
summ share, meanonly
display r(sum)  // = 1, so all good

use "2016_data_logs.dta", clear

tab HLEV2G

gen Years_schooling = .

replace Years_schooling = 7  if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace Years_schooling = 9.5 if HLEV2G == "2" // graduated high school or partial post-secondary
replace Years_schooling = 14 if HLEV2G == "3" // certificate or diploma
replace Years_schooling = 17 if HLEV2G == "4" // university degree

tab AGE, nolabel

gen Age_Actual = .

replace Age_Actual = 25 if AGEGP == "07" // 25-29, was structurally impossible to reach some groups with 27 as actual age
replace Age_Actual = 32 if AGEGP == "08" // 30-34
replace Age_Actual = 37 if AGEGP == "09" // 35-39
replace Age_Actual = 42 if AGEGP == "10" // 40-44
replace Age_Actual = 47 if AGEGP == "11" // 45-49
replace Age_Actual = 52 if AGEGP == "12" // 50-54
replace Age_Actual = 57 if AGEGP == "13" // 55-59

gen potential_experience = Age_Actual - Years_schooling - 6

gen EDUC_AKK = .
replace EDUC_AKK = 1 if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace EDUC_AKK = 2 if HLEV2G == "2" // graduated high school or partial post-secondary
replace EDUC_AKK = 3 if HLEV2G == "3" // certificate or diploma
replace EDUC_AKK = 4 if HLEV2G == "4" // university degree


gen Pot_exp_AKK = .
replace Pot_exp_AKK = 1 if potential_experience < 13
replace Pot_exp_AKK = 2 if potential_experience >= 13 & potential_experience < 23
replace Pot_exp_AKK = 3 if potential_experience >= 23 & potential_experience < 33
replace Pot_exp_AKK = 4 if potential_experience >= 33


// (b)
browse
tab SEX
tab EDUC_AKK Pot_exp_AKK, missing
egen Group_2016 = group(SEX EDUC_AKK Pot_exp_AKK)
tab Group_2016

save "2016_data_groups.dta", replace


use "2016_data_groups.dta", clear

keep Group_2016 SEX EDUC_AKK Pot_exp_AKK WGSAL FWEIGHT
    drop if missing(Group_2016, SEX, EDUC_AKK, Pot_exp_AKK, WGSAL, FWEIGHT)

    quietly summarize FWEIGHT, meanonly
    scalar Wtot = r(sum)

    gen w_wage = WGSAL * FWEIGHT

    collapse (sum) w_group=FWEIGHT (sum) w_wage_sum=w_wage ///
             (first) SEX EDUC_AKK Pot_exp_AKK, by(Group_2016)

    gen mean_wage = w_wage_sum / w_group
    gen share     = w_group / Wtot
    gen year      = 2016
    destring SEX, replace
    rename Group_2016 Group

    keep year Group SEX EDUC_AKK Pot_exp_AKK share mean_wage
    save "grpstats_2016.dta", replace


use "grpstats_2016.dta", clear

use "2018_data_logs.dta", clear

tab HLEV2G

gen Years_schooling = .

replace Years_schooling = 7  if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace Years_schooling = 9.5 if HLEV2G == "2" // graduated high school or partial post-secondary
replace Years_schooling = 14 if HLEV2G == "3" // certificate or diploma
replace Years_schooling = 17 if HLEV2G == "4" // university degree


tab AGE, nolabel

gen Age_Actual = .

replace Age_Actual = 25 if AGEGP == "07" // 25-29, was structurally impossible to reach some groups with 27 as actual age
replace Age_Actual = 32 if AGEGP == "08" // 30-34
replace Age_Actual = 37 if AGEGP == "09" // 35-39
replace Age_Actual = 42 if AGEGP == "10" // 40-44
replace Age_Actual = 47 if AGEGP == "11" // 45-49
replace Age_Actual = 52 if AGEGP == "12" // 50-54
replace Age_Actual = 57 if AGEGP == "13" // 55-59

gen potential_experience = Age_Actual - Years_schooling - 6

gen EDUC_AKK = .
replace EDUC_AKK = 1 if HLEV2G == "1" | HLEV2G == "9" // less than high school
replace EDUC_AKK = 2 if HLEV2G == "2" // graduated high school or partial post-secondary
replace EDUC_AKK = 3 if HLEV2G == "3" // certificate or diploma
replace EDUC_AKK = 4 if HLEV2G == "4" // university degree

gen Pot_exp_AKK = .
replace Pot_exp_AKK = 1 if potential_experience < 13
replace Pot_exp_AKK = 2 if potential_experience >= 13 & potential_experience < 23
replace Pot_exp_AKK = 3 if potential_experience >= 23 & potential_experience < 33
replace Pot_exp_AKK = 4 if potential_experience >= 33


// (b)
browse
tab SEX
tab EDUC_AKK Pot_exp_AKK, missing
egen Group_2018 = group(SEX EDUC_AKK Pot_exp_AKK)
tab Group_2018

save "2018_data_groups.dta", replace

use "2018_data_groups.dta", clear

keep Group_2018 SEX EDUC_AKK Pot_exp_AKK WGSAL FWEIGHT
    drop if missing(Group_2018, SEX, EDUC_AKK, Pot_exp_AKK, WGSAL, FWEIGHT)

    quietly summarize FWEIGHT, meanonly
    scalar Wtot = r(sum)

    gen w_wage = WGSAL * FWEIGHT

    collapse (sum) w_group=FWEIGHT (sum) w_wage_sum=w_wage ///
             (first) SEX EDUC_AKK Pot_exp_AKK, by(Group_2018)

    gen mean_wage = w_wage_sum / w_group
    gen share     = w_group / Wtot
    gen year      = 2018
    destring SEX, replace
    rename Group_2018 Group

    keep year Group SEX EDUC_AKK Pot_exp_AKK share mean_wage
    save "grpstats_2018.dta", replace

// combine data sets

use "grpstats_1982.dta", clear
append using "grpstats_1997.dta"
append using "grpstats_2016.dta"
browse
append using "grpstats_2018.dta"



// average composition share across years (AKK fixed weights)
collapse (mean) share_fixed = share, by(Group)

// quick check: should sum to 1
quietly summarize share_fixed, meanonly
display r(sum) // = 1 so we are good

save "share_fixed.dta", replace

use "share_fixed.dta", clear

use "grpstats_1982.dta", clear
merge 1:1 Group using "share_fixed.dta"
drop _merge

// (a)
gen Comp_all_Term_1982 = share_fixed * mean_wage
quietly summarize Comp_all_Term_1982, meanonly
scalar comp_all_1982 = r(sum)
gen Naive_all_Term_1982 = share * mean_wage
quietly summarize Naive_all_Term_1982, meanonly
scalar naive_all_1982 = r(sum)
// (b)
gen Comp_women_Term_1982 = share_fixed * mean_wage if SEX==2
quietly summarize Comp_women_Term_1982, meanonly
scalar comp_women_1982 = r(sum)
gen Naive_women_Term_1982 = share * mean_wage if SEX==2
quietly summarize Naive_women_Term_1982, meanonly
scalar naive_women_1982 = r(sum)

// (c)
gen Comp_men_Term_1982 = share_fixed * mean_wage if SEX==1
quietly summarize Comp_men_Term_1982, meanonly
scalar comp_men_1982 = r(sum)
gen Naive_men_Term_1982 = share * mean_wage if SEX==1
quietly summarize Naive_men_Term_1982, meanonly
scalar naive_men_1982 = r(sum)

// (d)
gen Comp_uni_Term_1982 = share_fixed * mean_wage if EDUC_AKK==4
quietly summarize Comp_uni_Term_1982, meanonly
scalar comp_uni_1982 = r(sum)
gen Naive_uni_Term_1982 = share * mean_wage if EDUC_AKK==4
quietly summarize Naive_uni_Term_1982, meanonly
scalar naive_uni_1982 = r(sum)

// (e)
gen Comp_hs_Term_1982 = share_fixed * mean_wage if EDUC_AKK==2
quietly summarize Comp_hs_Term_1982, meanonly
scalar comp_hs_1982 = r(sum)
gen Naive_hs_Term_1982 = share * mean_wage if EDUC_AKK==2
quietly summarize Naive_hs_Term_1982, meanonly
scalar naive_hs_1982 = r(sum)

save "decomposition_naive_1982.dta", replace

use "grpstats_1997.dta", clear
merge 1:1 Group using "share_fixed.dta"
drop _merge

// (a)
gen Comp_all_Term_1997 = share_fixed * mean_wage
quietly summarize Comp_all_Term_1997, meanonly
scalar comp_all_1997 = r(sum)
gen Naive_all_Term_1997 = share * mean_wage
quietly summarize Naive_all_Term_1997, meanonly
scalar naive_all_1997 = r(sum)
// (b)
gen Comp_women_Term_1997 = share_fixed * mean_wage if SEX==2
quietly summarize Comp_women_Term_1997, meanonly
scalar comp_women_1997 = r(sum)
gen Naive_women_Term_1997 = share * mean_wage if SEX==2
quietly summarize Naive_women_Term_1997, meanonly
scalar naive_women_1997 = r(sum)

// (c)
gen Comp_men_Term_1997 = share_fixed * mean_wage if SEX==1
quietly summarize Comp_men_Term_1997, meanonly
scalar comp_men_1997 = r(sum)
gen Naive_men_Term_1997 = share * mean_wage if SEX==1
quietly summarize Naive_men_Term_1997, meanonly
scalar naive_men_1997 = r(sum)

// (d)
gen Comp_uni_Term_1997 = share_fixed * mean_wage if EDUC_AKK==4
quietly summarize Comp_uni_Term_1997, meanonly
scalar comp_uni_1997 = r(sum)
gen Naive_uni_Term_1997 = share * mean_wage if EDUC_AKK==4
quietly summarize Naive_uni_Term_1997, meanonly
scalar naive_uni_1997 = r(sum)

// (e)
gen Comp_hs_Term_1997 = share_fixed * mean_wage if EDUC_AKK==2
quietly summarize Comp_hs_Term_1997, meanonly
scalar comp_hs_1997 = r(sum)
gen Naive_hs_Term_1997 = share * mean_wage if EDUC_AKK==2
quietly summarize Naive_hs_Term_1997, meanonly
scalar naive_hs_1997 = r(sum)

save "decomposition_naive_1997.dta", replace

use "grpstats_2016.dta", clear
merge 1:1 Group using "share_fixed.dta"
drop _merge

// (a)
gen Comp_all_Term_2016 = share_fixed * mean_wage
quietly summarize Comp_all_Term_2016, meanonly
scalar comp_all_2016 = r(sum)
gen Naive_all_Term_2016 = share * mean_wage
quietly summarize Naive_all_Term_2016, meanonly
scalar naive_all_2016 = r(sum)
// (b)
gen Comp_women_Term_2016 = share_fixed * mean_wage if SEX==2
quietly summarize Comp_women_Term_2016, meanonly
scalar comp_women_2016 = r(sum)
gen Naive_women_Term_2016 = share * mean_wage if SEX==2
quietly summarize Naive_women_Term_2016, meanonly
scalar naive_women_2016 = r(sum)

// (c)
gen Comp_men_Term_2016 = share_fixed * mean_wage if SEX==1
quietly summarize Comp_men_Term_2016, meanonly
scalar comp_men_2016 = r(sum)
gen Naive_men_Term_2016 = share * mean_wage if SEX==1
quietly summarize Naive_men_Term_2016, meanonly
scalar naive_men_2016 = r(sum)

// (d)
gen Comp_uni_Term_2016 = share_fixed * mean_wage if EDUC_AKK==4
quietly summarize Comp_uni_Term_2016, meanonly
scalar comp_uni_2016 = r(sum)
gen Naive_uni_Term_2016 = share * mean_wage if EDUC_AKK==4
quietly summarize Naive_uni_Term_2016, meanonly
scalar naive_uni_2016 = r(sum)

// (e)
gen Comp_hs_Term_2016 = share_fixed * mean_wage if EDUC_AKK==2
quietly summarize Comp_hs_Term_2016, meanonly
scalar comp_hs_2016 = r(sum)
gen Naive_hs_Term_2016 = share * mean_wage if EDUC_AKK==2
quietly summarize Naive_hs_Term_2016, meanonly
scalar naive_hs_2016 = r(sum)

save "decomposition_naive_2016.dta", replace



use "grpstats_2018.dta", clear
merge 1:1 Group using "share_fixed.dta"
drop _merge

// (a)
gen Comp_all_Term_2018 = share_fixed * mean_wage
quietly summarize Comp_all_Term_2018, meanonly
scalar comp_all_2018 = r(sum)
gen Naive_all_Term_2018 = share * mean_wage
quietly summarize Naive_all_Term_2018, meanonly
scalar naive_all_2018 = r(sum)
// (b)
gen Comp_women_Term_2018 = share_fixed * mean_wage if SEX==2
quietly summarize Comp_women_Term_2018, meanonly
scalar comp_women_2018 = r(sum)
gen Naive_women_Term_2018 = share * mean_wage if SEX==2
quietly summarize Naive_women_Term_2018, meanonly
scalar naive_women_2018 = r(sum)

// (c)
gen Comp_men_Term_2018 = share_fixed * mean_wage if SEX==1
quietly summarize Comp_men_Term_2018, meanonly
scalar comp_men_2018 = r(sum)
gen Naive_men_Term_2018 = share * mean_wage if SEX==1
quietly summarize Naive_men_Term_2018, meanonly
scalar naive_men_2018 = r(sum)

// (d)
gen Comp_uni_Term_2018 = share_fixed * mean_wage if EDUC_AKK==4
quietly summarize Comp_uni_Term_2018, meanonly
scalar comp_uni_2018 = r(sum)
gen Naive_uni_Term_2018 = share * mean_wage if EDUC_AKK==4
quietly summarize Naive_uni_Term_2018, meanonly
scalar naive_uni_2018 = r(sum)

// (e)
gen Comp_hs_Term_2018 = share_fixed * mean_wage if EDUC_AKK==2
quietly summarize Comp_hs_Term_2018, meanonly
scalar comp_hs_2018 = r(sum)
gen Naive_hs_Term_2018 = share * mean_wage if EDUC_AKK==2
quietly summarize Naive_hs_Term_2018, meanonly
scalar naive_hs_2018 = r(sum)

save "decomposition_naive_2018.dta", replace

