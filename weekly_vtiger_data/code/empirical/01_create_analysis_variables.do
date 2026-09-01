/******************************************************************
 01_create_analysis_variables.do
 Purpose: Create variables required for empirical analysis
******************************************************************/

clear
set more off

global indicator_file "$processed_path/SoMB_WB_monitoring_indicators.dta"
global analysis_file  "$processed_path/SoMB_WB_analysis.dta"

use "$indicator_file", clear

/******************************************************************
 0. Define empirical analysis sample
******************************************************************

gen analysis_sample = inrange(project_week, 1, 20) ///
    & !missing(treatment)

label variable analysis_sample ///
    "Main empirical sample: randomized project weeks 1-20"

tab project_week analysis_sample, missing **/


/******************************************************************
 1. Create counsellor ID
******************************************************************/

gen counselor_id = ""

replace counselor_id = "A" if inlist(language, "Russian", "Ukrainian")
replace counselor_id = "B" if language == "Arabic"
replace counselor_id = "C" if language == "Persian"
replace counselor_id = "D" if language == "Turkish"
replace counselor_id = "E" if language == "French"

label variable counselor_id ///
    "Counsellor ID derived from consultation language"

tab language counselor_id, missing


/******************************************************************
 2. Merge randomized treatment assignment
******************************************************************/

merge m:1 counselor_id project_week ///
    using "$processed_path/randomization_schedule.dta"
	
tab _merge
* Drop randomized counselor-week cells without observed cases
drop if _merge == 2

* Keep observed cases, whether treatment matched or not
assert inlist(_merge, 1, 3)

drop _merge

/* to see which cases we have to drop ; for example german or englishc language. 
tab language if _merge == 1, missing
tab counselor_id if _merge == 1, missing
tab project_week if _merge == 1, missing

drop _merge
*/

*** to reaname ai and treatment and lateirs ; look which cases are here first 

rename ai treatment

label define treatment_lbl ///
    0 "Control" ///
    1 "Lateris assigned", replace

label values treatment treatment_lbl
label variable treatment ///
    "Randomized Lateris treatment assignment"
	
	
* check in 
tab treatment, missing

tab counselor_id treatment, missing

tab project_week treatment, missing

tab counselor_id project_week if missing(treatment)


*and also check how much 
tab treatment lateris_yes, row

/******************************************************************
 0. Define empirical analysis sample
******************************************************************/

gen analysis_sample = inrange(project_week, 1, 20) ///
    & !missing(treatment)

label variable analysis_sample ///
    "Main empirical sample: randomized project weeks 1-20"

tab project_week analysis_sample, missing


/******************************************************************
 3. Create case count indicator
******************************************************************/

capture drop case_counter
gen case_counter = 1

label variable case_counter "Case count"

/******************************************************************
 4a Create response quality index
******************************************************************/

egen quality_index = ///
    rowmean(accuracy clarity appropriateness completeness)

label variable quality_index ///
    "Mean response quality index based on available components"

summarize quality_index, detail

/******************************************************************
 4b Create response quality index
******************************************************************/

egen quality_components_n = ///
    rownonmiss(accuracy clarity appropriateness completeness)

egen quality_index_b = ///
    rowmean(accuracy clarity appropriateness completeness)

replace quality_index_b = . if quality_components_n < 4

label variable quality_components_n ///
    "Number of available quality components"

label variable quality_index_b ///
    "Mean response quality index (4 components)"

summarize quality_index_b, detail
tab quality_components_n, missing
/******************************************************************
 5. Create other AI use indicator
******************************************************************/

gen other_ai_yes = .

capture confirm variable other_ai_tool_used

if !_rc {

    replace other_ai_tool_used = strtrim(other_ai_tool_used)

    replace other_ai_yes = 1 if inlist(other_ai_tool_used, ///
        "Ja", "Yes", "yes", "YES", "1", "1: Ja")

    replace other_ai_yes = 0 if inlist(other_ai_tool_used, ///
        "Nein", "No", "no", "NO", "0", "0: Nein")
}

label values other_ai_yes yesno_lbl
label variable other_ai_yes "Other AI tool used"

tab other_ai_yes, missing

/******************************************************************
 6. Create lagged treatment assignment
******************************************************************/

preserve

* Restrict treatment history to randomized analysis period
keep if inrange(project_week, 1, 20)

keep counselor_id project_week treatment

drop if missing(counselor_id) | ///
        missing(project_week) | ///
        missing(treatment)

* One observation per counsellor-week
duplicates drop counselor_id project_week treatment, force

sort counselor_id project_week

* Treatment assignment in immediately preceding project week
by counselor_id: gen lag_treatment = treatment[_n-1] ///
    if project_week == project_week[_n-1] + 1

label variable lag_treatment ///
    "Treatment assignment in previous project week"

tempfile treatment_history
save `treatment_history'

restore

merge m:1 counselor_id project_week ///
    using `treatment_history', ///
    keepusing(lag_treatment)

drop _merge

/******************************************************************
 7. Create immediate control-after-treatment indicator for spillover
******************************************************************/

gen control_after_treatment = ///
    treatment == 0 & lag_treatment == 1 ///
    if !missing(treatment, lag_treatment)

label variable control_after_treatment ///
    "Control week immediately following treatment week"

tab control_after_treatment, missing

/******************************************************************
 8. Create previous treatment exposure indicator
******************************************************************/

preserve

keep counselor_id project_week treatment
drop if missing(counselor_id) | missing(project_week) | missing(treatment)

duplicates drop counselor_id project_week treatment, force

sort counselor_id project_week

by counselor_id: gen cumulative_previous_treatment = ///
    sum(treatment) - treatment

gen ever_treated_before = cumulative_previous_treatment > 0

label variable cumulative_previous_treatment ///
    "Number of previous treatment weeks"

label variable ever_treated_before ///
    "Counsellor previously exposed to treatment"

tempfile previous_exposure
save `previous_exposure'

restore

merge m:1 counselor_id project_week ///
    using `previous_exposure', ///
    keepusing(cumulative_previous_treatment ever_treated_before)

drop _merge

/******************************************************************
 9. Feedback received
******************************************************************/

* Binary indicator for whether feedback was received
capture drop feedback_received_yes

gen feedback_received_yes = .

replace feedback_received_yes = 0 ///
    if feedback_received == "0: Nein"

replace feedback_received_yes = 1 ///
    if inlist(feedback_received, ///
        "4: ja - positiv", ///
        "5: ja - sehr positiv")

label variable feedback_received_yes ///
    "Feedback received"

label values feedback_received_yes yesno_lbl


* Validation checks
tab feedback_received feedback_received_yes, missing
tab feedback_received_yes, missing

/******************************************************************
 10. Final analysis dataset checks
******************************************************************/

describe

summarize ///
    consultation_duration_min ///
    form_duration_min ///
    quality_index

tab treatment, missing
tab counselor_id, missing
tab project_week, missing

tab treatment lateris_yes, row
tab treatment other_ai_yes, row

tab lag_treatment, missing
tab control_after_treatment, missing

/******************************************************************
 11.Create numeric counsellor ID
******************************************************************/

* Create numeric counsellor ID for fixed effects
capture drop counselor_num

encode counselor_id, gen(counselor_num)

label variable counselor_num ///
    "Numeric counsellor ID for fixed effects"

* Check coding
tab counselor_id counselor_num, missing

/******************************************************************
 12. Case volume
******************************************************************/

* Number of cases handled per counsellor-week
bysort counselor_num project_week: egen case_volume = ///
    total(case_counter)

label variable case_volume ///
    "Number of cases handled per counsellor-week"
	
/******************************************************************
 12. Create counsellor-week cluster identifier
******************************************************************/
* Create numeric counsellor ID for fixed effects

capture confirm variable counselor_num

if _rc {
    encode counselor_id, gen(counselor_num)
}

label variable counselor_num ///
    "Numeric counsellor ID for fixed effects"
capture drop counselor_week


egen counselor_week = group(counselor_num project_week) ///
    if analysis_sample == 1

label variable counselor_week ///
    "Counsellor-project week randomization unit"
/******************************************************************
 101.Save analysis dataset
******************************************************************/

compress
save "$analysis_file", replace