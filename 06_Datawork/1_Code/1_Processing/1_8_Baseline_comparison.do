****************************************************************************
**#             1. Load yearly data
****************************************************************************

use "${processing}/SoMB_yearly_analysis.dta", clear


****************************************************************************
**#             2. Inspect historical coverage
****************************************************************************

* Years
tab created_year

* Languages
tab language, missing

* Date range
summarize created_date, detail

display "First case: " %td r(min)
display "Last case:  " %td r(max)


****************************************************************************
**#             3. Prepare baseline language groups
****************************************************************************

* Keep languages corresponding to RCT counsellor language groups
keep if inlist(language, ///
    "Arabic", "French", "Persian", ///
    "Russian", "Turkish", "Ukrainian")

* Combine Russian and Ukrainian into one language group
gen language_group = language

replace language_group = "Russian/Ukrainian" ///
    if inlist(language, "Russian", "Ukrainian")

label variable language_group ///
    "Counselling language group"


****************************************************************************
**#             4. Create weekly case volume
****************************************************************************

* Create calendar week from case creation date
gen baseline_week = wofd(created_date)
format baseline_week %tw

* Collapse to language-group × week
collapse ///
    (sum) case_volume = one_case, ///
    by(language_group baseline_week)

label variable case_volume ///
    "Number of cases per language-group week"

sort language_group baseline_week


****************************************************************************
**#             5. Inspect weekly case volume
****************************************************************************

bysort language_group: summarize case_volume


****************************************************************************
**#             6. Baseline summary table
****************************************************************************

preserve

collapse ///
    (count) n_weeks = case_volume ///
    (mean) mean_weekly_cases = case_volume ///
    (sd)   sd_weekly_cases = case_volume ///
    (min)  min_weekly_cases = case_volume ///
    (max)  max_weekly_cases = case_volume, ///
    by(language_group)

* Format for presentation
format mean_weekly_cases %9.2f
format sd_weekly_cases   %9.2f

label variable n_weeks           "Number of weeks"
label variable mean_weekly_cases "Mean cases per week"
label variable sd_weekly_cases   "SD"
label variable min_weekly_cases  "Minimum"
label variable max_weekly_cases  "Maximum"

list, noobs

restore 


****************************************************************************
**#             8. Baseline case volume graph
****************************************************************************

preserve

collapse ///
    (mean) mean_weekly_cases = case_volume, ///
    by(language_group)

graph hbar mean_weekly_cases, ///
    over(language_group, sort(1) descending) ///
    blabel(bar, format(%4.1f)) ///
    ytitle("Average number of cases per week") ///
    title("Historical Case Volume by Language Group") ///
    subtitle("Pre-intervention period") ///
    note("Mean weekly case volume by language group")

graph export ///
    "${impact}/Graphs/baseline_case_volume.png", ///
    replace width(2000)
	
restore