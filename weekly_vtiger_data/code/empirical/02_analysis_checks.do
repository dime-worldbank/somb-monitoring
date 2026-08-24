/******************************************************************
 02_analysis_checks.do
 Project: SoMB / WB empirical analysis
 Purpose: Validate analysis sample, treatment assignment,
          randomization merge, and key outcome variables
******************************************************************/

clear
set more off


/******************************************************************
 0. Load analysis dataset
******************************************************************/

use "$analysis_file", clear


/******************************************************************
 1. Basic dataset checks
******************************************************************/

describe

count
display "Total observations: " r(N)

duplicates report case_id

count if missing(case_id)
count if missing(project_week)


/******************************************************************
 2. Check analysis period
******************************************************************/

tab project_week, missing

summarize project_week, detail

* Randomized intervention period
count if inrange(project_week, 1, 20)


/******************************************************************
 3. Check counsellor assignment
******************************************************************/

tab counselor_id, missing

tab language counselor_id, missing

* Cases without assigned counsellor
count if missing(counselor_id)

tab language if missing(counselor_id), missing


/******************************************************************
 4. Check randomized treatment assignment
******************************************************************/

tab treatment, missing

tab counselor_id treatment, missing
tab project_week treatment, missing

tab counselor_id project_week if missing(treatment), missing


/******************************************************************
 5. Verify treatment schedule within counsellor-week
******************************************************************/

* Treatment must be constant within counsellor-week

bysort counselor_id project_week: ///
    egen treatment_min = min(treatment)

bysort counselor_id project_week: ///
    egen treatment_max = max(treatment)

assert treatment_min == treatment_max ///
    if !missing(counselor_id, project_week, treatment)

drop treatment_min treatment_max


/******************************************************************
 6. Treatment vs. actual Lateris use
******************************************************************/

tab treatment lateris_yes, row missing

* Assigned Lateris but not used
count if treatment == 1 & lateris_yes == 0

* Lateris used during control assignment
count if treatment == 0 & lateris_yes == 1


/******************************************************************
 7. Other AI use
******************************************************************/

tab treatment other_ai_yes, row missing

tab other_ai_yes, missing


/******************************************************************
 8. Check main outcome variables
******************************************************************/

summarize ///
    consultation_duration_min ///
    form_duration_min ///
    quality_index ///
    quality_index_b, detail

misstable summarize ///
    consultation_duration_min ///
    form_duration_min ///
    quality_index ///
    quality_index_b


/******************************************************************
 9. Quality index checks
******************************************************************/

tab quality_components_n, missing

summarize ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness ///
    quality_index ///
    quality_index_b


/******************************************************************
 10. Spillover variables
******************************************************************/

tab lag_treatment, missing
tab control_after_treatment, missing
tab ever_treated_before, missing

summarize cumulative_previous_treatment


/******************************************************************
 11. Final analysis sample
******************************************************************/

count if ///
    !missing(treatment) & ///
    !missing(counselor_id) & ///
    inrange(project_week, 1, 20)

display "Potential RCT analysis sample: " r(N)


/******************************************************************
 End of analysis checks
******************************************************************/

display "=================================================="
display "Analysis checks completed"
display "=================================================="