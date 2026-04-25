*******************************************************
// Income Distribution Assignment 1 - Do-file        
// Given Group: Ontario
*******************************************************
// my notes are mostly for myself in order to better grasp stata commands and logic.
// will also be helpful for future reference and for you to understand my thought process.

capture log close // closes open log file and prevents error if no log is open
log using "Assignment1_Final.log", text replace // starts a new log file to record output, replace if it already exists

// Q1: Load data and identify key variables (total income, market income, wages, self-employment, age, province)
use "CIS-72M0003-E-2018_F1.dta", clear // use this data set, clear any existing data from memory
describe TTINC MTINC WGSAL SEMP AGEGP PROV // check variable descriptions to understand what they represent

// need to create an indicator for Ontario (Province code "35")
gen byte Ontario = (PROV == "35")   // Ontario dummy (1 if Ontario, 0 otherwise)
tab PROV if Ontario==1             // Verify that only province 35 is included (Ontario)

// Q2: Construct KR's definition of earnings (wages plus a fraction of business income)

gen Ci = MTINC - WGSAL - SEMP   // Ci: "unambiguous" capital income


gen byte q2_ok = !missing(FWEIGHT, MTINC, WGSAL, SEMP)   // 1 if all values present, 0 otherwise
tab q2_ok

// Calculate the sample-wide ratio phi = Σ_i WGSAL_i / Σ_i (WGSAL_i + Ci_i), using person weights
quietly total WGSAL [pw=FWEIGHT] if q2_ok==1 // quietly tells stata to run the command without displaying output
scalar wLi_total = e(b)[1,1] // retrieve the total WGSAL from the previous command and store it in a scalar
gen WGSAL_Ci = WGSAL + Ci
quietly total WGSAL_Ci [pw=FWEIGHT] if q2_ok==1
scalar wLiCi_total = e(b)[1,1]
scalar Phi_ratio = wLi_total / wLiCi_total // calculate the phi ratio using the totals
display "Phi (Canada) = " %9.6f Phi_ratio

// Calculate phi for the Ontario subsample (for comparison)
quietly total WGSAL [pw=FWEIGHT] if Ontario==1 & q2_ok==1
scalar wLi_ON = e(b)[1,1]
quietly total WGSAL_Ci [pw=FWEIGHT] if Ontario==1 & q2_ok==1
scalar wLiCi_ON = e(b)[1,1]
scalar Phi_ratio_ON = wLi_ON / wLiCi_ON
display "Phi (Ontario) = " %9.6f Phi_ratio_ON

// Generate KR-adjusted earnings variables using the phi values
gen Earnings_KR = WGSAL + (Phi_ratio * SEMP)   // KR adjusted earnings using national phi
label var Earnings_KR "KR adjusted earnings (Canada-wide phi)"
gen Earnings_KR_ON = WGSAL + (Phi_ratio_ON * SEMP)   // KR adjusted earnings using Ontario phi
label var Earnings_KR_ON "KR adjusted earnings (Ontario phi)"




// Q3: Replicate KR’s Table 1 for market income and earnings (Canada vs Ontario)
// need to compute quantiles (0, 1, 5, ..., 99, 100) and mean for Canada and for Ontario
local plist = "1 5 10 20 40 50 60 80 90 95 99"   // defines local for percentiles of interest (excluding 0 and 100 which are min and max)

// need to create results matrix for Canada (row1: Market Income, row2: Earnings)
matrix Table_Can = J(2, 14, .) // generate the matrix
matrix colnames Table_Can = min p1 p5 p10 p20 p40 p50 p60 p80 p90 p95 p99 max mean
matrix rownames Table_Can = Canada_MarketInc Canada_Earnings // define the rows and columns
local r = 1
foreach var in MTINC Earnings_KR { 
    summarize `var' [aw=FWEIGHT] if q2_ok==1
    matrix Table_Can[`r', 1]  = r(min)
    matrix Table_Can[`r', 13] = r(max)
    matrix Table_Can[`r', 14] = r(mean)
    _pctile `var' [pw=FWEIGHT] if q2_ok==1, p(`plist') // compute the specified percentiles for the variable, using person weights
    forvalues i = 1/11 {
        matrix Table_Can[`r', `i'+1] = r(r`i')
    }
    local r = `r' + 1
}
matrix list Table_Can 

local plist = "1 5 10 20 40 50 60 80 90 95 99"
// Create results matrix for Ontario (row1: Market Income, row2: Earnings) same as above
matrix Table_ON = J(2, 14, .)
matrix colnames Table_ON = min p1 p5 p10 p20 p40 p50 p60 p80 p90 p95 p99 max mean
matrix rownames Table_ON = Ontario_MarketInc Ontario_Earnings
local r = 1
foreach var in MTINC Earnings_KR_ON {
    summarize `var' [aw=FWEIGHT] if Ontario==1 & q2_ok==1
    matrix Table_ON[`r', 1]  = r(min)
    matrix Table_ON[`r', 13] = r(max)
    matrix Table_ON[`r', 14] = r(mean)
    _pctile `var' [pw=FWEIGHT] if Ontario==1 & q2_ok==1, p(`plist')
    forvalues i = 1/11 {
        matrix Table_ON[`r', `i'+1] = r(r`i')
    }
    local r = `r' + 1
}
matrix list Table_ON

// Q4: Replicate KR’s Figure 3b – Distribution of Total Income (using TTINC)

histogram TTINC if TTINC <= 500000, ///
    percent bin(60) ///
    xscale(range(0 500000)) xlabel(0(100000)500000) ///
    xline(0) ///
    xtitle("Total income (CAD)") ytitle("Percent") ///
    title("Income distribution (Canada, 2018)")

histogram TTINC if TTINC <= 500000 & Ontario==1, ///
    percent bin(60) ///
    xscale(range(0 500000)) xlabel(0(100000)500000) ///
    xline(0) ///
    xtitle("Total income (CAD)") ytitle("Percent") ///
    title("Income distribution (Ontario, 2018)")

// Q5: Compute various inequality measures for income and earnings in Ontario


ineqdeco MTINC [pw=FWEIGHT] if q2_ok==1
ineqdeco Earnings_KR [pw=FWEIGHT] if q2_ok==1

// Coefficient of variation (std dev / mean)
summarize MTINC if q2_ok==1
scalar mean_inc = r(mean)
scalar sd_inc = r(sd)
scalar CV_inc = sd_inc / mean_inc
display "Coefficient of Variation (Income) = " %9.4f CV_inc

summarize Earnings_KR if q2_ok==1
scalar mean_earn = r(mean)
scalar sd_earn = r(sd)
scalar CV_earn = sd_earn / mean_earn
display "Coefficient of Variation (Earnings) = " %9.4f CV_earn

// Variance of log incomes (for observations with positive income)
gen double MTINC_Log = log(MTINC) if MTINC > 0
gen double EKR_Log = log(Earnings_KR) if Earnings_KR > 0
summarize MTINC_Log
display "Variance of log Income = " %9.7f r(Var)
summarize EKR_Log
display "Variance of log Earnings = " %9.7f r(Var)

// Location of the mean (percentage of population with income below the mean)
gen byte below_mean_inc = (MTINC <= mean_inc)
summarize below_mean_inc
display "Percent with income below mean = " %9.6f (100 * r(mean))

gen byte below_mean_earn = (Earnings_KR <= mean_earn)
summarize below_mean_earn
display "Percent with earnings below mean = " %9.6f (100 * r(mean))

// Mean-to-median ratio
centile MTINC if q2_ok==1, centile(50)
scalar median_inc = r(c_1)
display "Mean/Median (Income) = " %6.4f (mean_inc / median_inc)

centile Earnings_KR if q2_ok==1, centile(50)
scalar median_earn = r(c_1)
display "Mean/Median (Earnings) = " %6.4f (mean_earn / median_earn)

* Percentile ratios (P99/P50, P90/P50, P50/P30)
centile MTINC if Ontario==1 & q2_ok==1, centile(30 50 90 99)
display "P99/P50 (Income) = " %6.4f (r(c_4) / r(c_2))
display "P90/P50 (Income) = " %6.4f (r(c_3) / r(c_2))
display "P50/P30 (Income) = " %6.4f (r(c_2) / r(c_1))

centile Earnings_KR_ON if Ontario==1 & q2_ok==1, centile(30 50 90 99)
display "P99/P50 (Earnings) = " %6.4f (r(c_4) / r(c_2))
display "P90/P50 (Earnings) = " %6.4f (r(c_3) / r(c_2))
display "P50/P30 (Earnings) = " %6.4f (r(c_2) / r(c_1))   // note: will be missing if p30 = 0

// Q6: Define income distribution groups (quintiles, top 2–5%, top 1%)
sort MTINC   // Sort data by total market income (ascending order)
xtile quintile = MTINC, nq(5)  
summarize MTINC, detail  
// Get detailed distribution stats, including 95th and 99th percentiles for `market_income`.
scalar cut95 = r(p95)
scalar cut99 = r(p99)

gen top1 = (MTINC >= cut99)  
gen top5 = (MTINC >= cut95)  
gen top2_5 = (top5 == 1 & top1 == 0)  

gen inc_group = quintile  
replace inc_group = 6 if top2_5 == 1  
replace inc_group = 7 if top1 == 1  


label define incgrp 1 "Q1 (bottom 20%)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (80–95%)" ///
                 6 "Top 2–5%" 7 "Top 1%", replace  
label values inc_group incgrp  


// Compute wage and business income shares for each group (All Canada)
preserve  
collapse (sum) tot_wage = WGSAL (sum) tot_bus = SEMP (sum) tot_inc = MTINC, by(inc_group)  

gen wage_share = tot_wage / tot_inc  
gen bus_share  = tot_bus  / tot_inc  
// Calculate share of total income from wages and from business for each group.

format %6.2f wage_share bus_share  
list inc_group wage_share bus_share, noobs  

restore  // bring back full dataset

// Compute wage and business income shares for each group (Ontario only)
preserve
keep if Ontario == 1
collapse (sum) tot_wage = WGSAL (sum) tot_bus = SEMP (sum) tot_inc = MTINC, by(inc_group)
gen wage_share = tot_wage / tot_inc
gen bus_share  = tot_bus  / tot_inc
format %6.2f wage_share bus_share
list inc_group wage_share bus_share, noobs
// Repeat the collapse and share calculations, but now restricted to observations where `Ontario == 1`.
// this produces the same income groups and their wage/business shares for the Ontario sub-sample.

restore
// Compare the results for All Canada vs. Ontario

// Q7: Analyze how earnings and inequality vary across age groups in Ontario
// Create age groups

gen age_group = .
replace age_group = 1 if AGEGP == "01"  // Likely <5 or <10
replace age_group = 2 if AGEGP == "02"
replace age_group = 3 if AGEGP == "03"
replace age_group = 4 if AGEGP == "04"
replace age_group = 5 if AGEGP == "05"
replace age_group = 6 if AGEGP == "06"
replace age_group = 7 if AGEGP == "07"
replace age_group = 8 if AGEGP == "08"
replace age_group = 9 if AGEGP == "09"
replace age_group = 10 if AGEGP == "10"
replace age_group = 11 if AGEGP == "11"
replace age_group = 12 if AGEGP == "12"
replace age_group = 13 if AGEGP == "13"
replace age_group = 14 if AGEGP == "14"
replace age_group = 15 if AGEGP == "15"



label define age_lbl 1 "0–4" 2 "5–9" 3 "10–14" 4 "15–19" 5 "20–24" 6 "25–29" ///
                    7 "30–34" 8 "35–39" 9 "40–44" 10 "45–49" ///
                    11 "50–54" 12 "55–59" 13 "60–64" 14 "65–69" 15 "70+"
label values age_group age_lbl

// Collapse mean earnings by age group
preserve
collapse (mean) Earnings_KR, by(age_group)

// Plot earnings only
twoway line Earnings_KR age_group, sort ///
    xlabel(4 "15–19" 5 "20–24" 6 "25–29" 7 "30–34" 8 "35–39" ///
           9 "40–44" 10 "45–49" 11 "50–54" 12 "55–59" 13 "60–64" ///
           14 "65–69" 15 "70+") ///
    xtitle("Age Group", size(medsmall)) ///
    ytitle("Mean Earnings ($)", size(medsmall)) ///
    title("Mean Earnings by Age Group", size(medium)) ///
    lcolor(red) lpattern(solid) ///
    msymbol(square) msize(big) ///
    ylabel(0.3(0.1)0.9, labsize(small)) ///
    graphregion(color(white)) ///
    plotregion(style(none)) ///
    legend(off)



restore
// Create a summary dataset with one row per age group
preserve
keep age_group Earnings_KR
keep if Earnings_KR < .   // drop missing earnings
duplicates drop           // ensure uniqueness (optional)

gen gini = .
tempvar gini_holder
gen `gini_holder' = .

levelsof age_group, local(grps)

gen obs = 1

foreach g of local grps {
    su age_group if age_group == `g'  // ensure group exists
    capture ineqdeco Earnings_KR if age_group == `g'
    if _rc == 0 {
        replace gini = r(gini) if age_group == `g'
    }
}
collapse (first) gini , by(age_group) 

twoway line gini age_group, sort ///
    xlabel(4 "15–19" 5 "20–24" 6 "25–29" 7 "30–34" 8 "35–39" ///
           9 "40–44" 10 "45–49" 11 "50–54" 12 "55–59" 13 "60–64" ///
           14 "65–69" 15 "70+", labsize(small)) ///
    xtitle("Age Group", size(medsmall)) ///
    ytitle("Gini Index (Earnings)", size(medsmall)) ///
    title("Earnings Inequality by Age Group", size(medium)) ///
    lcolor(red) lpattern(solid) ///
    msymbol(circle) msize(small) ///
    ylabel(0.3(0.1)0.9, labsize(small)) ///
    graphregion(color(white)) ///
    plotregion(style(none)) ///
    legend(off)

restore
