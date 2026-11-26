/*************************************************************************
 *************************************************************************
				Social Media Bridge (SoMB) - Germany

1) Created by: 	Samrawit Degu Shibeshi
				DIME - World Bank
				sshibeshi@worldbank.org

2) Reviewed by:	Daniel Márquez
				DIME - World Bank
				dmarquezmuskus@worldbank.org

3) Date: 		Created  January 2026
				Revised  August 2026

4) Objective: 	Descriptive statistics, treatment fidelity and outcome summaries
				by treatment, counsellor and project week

5) Output:		- log only

*************************************************************************
*************************************************************************/

clear all
set more off

****************************************************************************
**# 				1. Load analysis dataset
****************************************************************************

use "${processing}/SoMB_WB_analysis.dta", clear


****************************************************************************
**# 				2. Basic sample overview
****************************************************************************

describe

count

tab project_week, missing
tab counselor_id, missing
tab treatment, missing

tab counselor_id project_week, missing


****************************************************************************
**# 				3. Check treatment assignment
****************************************************************************

* Overall treatment distribution
tab treatment, missing

* Treatment distribution by counsellor
tab counselor_id treatment, row

* Treatment distribution by project week
tab project_week treatment, row

* Check whether treatment varies within counsellor-week
bysort counselor_id project_week: ///
    egen treatment_min = min(treatment)

bysort counselor_id project_week: ///
    egen treatment_max = max(treatment)

count if treatment_min != treatment_max ///
    & !missing(treatment_min, treatment_max)

drop treatment_min treatment_max


****************************************************************************
**# 				4. Cases per counsellor and week
****************************************************************************

preserve

collapse ///
    (sum) case_volume = case_counter, ///
    by(counselor_id project_week treatment)

sort counselor_id project_week

list counselor_id project_week treatment case_volume, ///
    sepby(counselor_id)

summarize case_volume, detail

restore


****************************************************************************
**# 				5. Treatment fidelity
****************************************************************************

* Actual Lateris use by randomized assignment
tab treatment lateris_yes, row missing

* Other AI use by randomized assignment
tab treatment other_ai_yes, row missing

* Lateris use by counsellor and treatment assignment
tab counselor_id lateris_yes if treatment == 1, row

* Lateris use in control weeks
tab counselor_id lateris_yes if treatment == 0, row


****************************************************************************
**# 				6. Missingness in main outcomes
****************************************************************************

misstable summarize ///
    consultation_duration_min ///
    form_duration_min ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness ///
    quality_index ///
    referral_yes

tab quality_components_n, missing


****************************************************************************
**# 				7. Overall descriptive statistics
****************************************************************************

summarize ///
    consultation_duration_min ///
    form_duration_min ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness ///
    quality_index ///
    referral_yes, detail


****************************************************************************
**# 				8. Descriptive statistics by treatment assignment
****************************************************************************

bysort treatment: summarize ///
    consultation_duration_min ///
    form_duration_min ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness ///
    quality_index ///
    referral_yes


****************************************************************************
**# 				9. Mean outcomes by treatment assignment
****************************************************************************

preserve

collapse ///
    (count) n_cases = case_counter ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (mean) avg_form_duration = form_duration_min ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_completeness = completeness ///
    (mean) avg_quality_index = quality_index ///
    (mean) share_referral = referral_yes ///
    (mean) share_lateris = lateris_yes ///
    (mean) share_other_ai = other_ai_yes, ///
    by(treatment)

replace share_referral = share_referral * 100
replace share_lateris  = share_lateris  * 100
replace share_other_ai = share_other_ai * 100

list, noobs

restore


****************************************************************************
**# 				10. Outcomes by counsellor and treatment
****************************************************************************

preserve

collapse ///
    (count) n_cases = case_counter ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (mean) avg_form_duration = form_duration_min ///
    (mean) avg_quality_index = quality_index ///
    (mean) share_referral = referral_yes, ///
    by(counselor_id treatment)

replace share_referral = share_referral * 100

sort counselor_id treatment

list, sepby(counselor_id)

restore


****************************************************************************
**# 				11. Outcomes by project week and treatment
****************************************************************************

preserve

collapse ///
    (count) n_cases = case_counter ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (mean) avg_form_duration = form_duration_min ///
    (mean) avg_quality_index = quality_index ///
    (mean) share_referral = referral_yes, ///
    by(project_week treatment)

replace share_referral = share_referral * 100

sort project_week treatment

list, sepby(project_week)

restore


****************************************************************************
**# 				12. Learning and spillover descriptives
****************************************************************************

tab lag_treatment, missing
tab control_after_treatment, missing

capture confirm variable ever_treated_before

if !_rc {
    tab ever_treated_before, missing
}

capture confirm variable cumulative_previous_treatment

if !_rc {
    summarize cumulative_previous_treatment, detail
}


****************************************************************************
**# 				13. Descriptives for control weeks after treatment
****************************************************************************

summarize ///
    consultation_duration_min ///
    form_duration_min ///
    quality_index ///
    if treatment == 0 & control_after_treatment == 1

summarize ///
    consultation_duration_min ///
    form_duration_min ///
    quality_index ///
    if treatment == 0 & control_after_treatment == 0


****************************************************************************
**# 				14. Basic sample consistency checks
****************************************************************************

* Treatment should only be 0/1 when observed
assert inlist(treatment, 0, 1) if !missing(treatment)

* Case counter should always equal 1
assert case_counter == 1

* Quality index should remain within original rating scale
assert inrange(quality_index, 1, 6) if !missing(quality_index)

* Duration cannot be negative
assert consultation_duration_min >= 0 ///
    if !missing(consultation_duration_min)

assert form_duration_min >= 0 ///
    if !missing(form_duration_min)


****************************************************************************
**# 				15. End
****************************************************************************

display as text "04_descriptive_analysis.do completed successfully."

