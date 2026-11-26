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

4) Objective: 	Validate the analysis sample, the randomized treatment assignment
				and the main outcome variables

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
**# 				2. Basic dataset checks
****************************************************************************

describe

count
display "Total observations: " r(N)

duplicates report case_id

count if missing(case_id)
count if missing(project_week)


****************************************************************************
**# 				3. Check analysis period
****************************************************************************

tab project_week, missing

summarize project_week, detail

* Randomized intervention period
count if inrange(project_week, 1, 20)


****************************************************************************
**# 				4. Check counsellor assignment
****************************************************************************

tab counselor_id, missing

tab language counselor_id, missing

* Cases without assigned counsellor
count if missing(counselor_id)

tab language if missing(counselor_id), missing


****************************************************************************
**# 				5. Check randomized treatment assignment
****************************************************************************

tab treatment, missing

tab counselor_id treatment, missing
tab project_week treatment, missing

tab counselor_id project_week if missing(treatment), missing


****************************************************************************
**# 				6. Verify treatment schedule within counsellor-week
****************************************************************************

* Treatment must be constant within counsellor-week

bysort counselor_id project_week: ///
    egen treatment_min = min(treatment)

bysort counselor_id project_week: ///
    egen treatment_max = max(treatment)

assert treatment_min == treatment_max ///
    if !missing(counselor_id, project_week, treatment)

drop treatment_min treatment_max


****************************************************************************
**# 				7. Treatment vs. actual Lateris use
****************************************************************************

tab treatment lateris_yes, row missing

* Assigned Lateris but not used
count if treatment == 1 & lateris_yes == 0

* Lateris used during control assignment
count if treatment == 0 & lateris_yes == 1


****************************************************************************
**# 				8. Other AI use
****************************************************************************

tab treatment other_ai_yes, row missing

tab other_ai_yes, missing


****************************************************************************
**# 				9. Check main outcome variables
****************************************************************************

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


****************************************************************************
**# 				10. Quality index checks
****************************************************************************

tab quality_components_n, missing

summarize ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness ///
    quality_index ///
    quality_index_b


****************************************************************************
**# 				11. Spillover variables
****************************************************************************

tab lag_treatment, missing
tab control_after_treatment, missing
tab ever_treated_before, missing

summarize cumulative_previous_treatment


****************************************************************************
**# 				12. Final analysis sample
****************************************************************************

count if ///
    !missing(treatment) & ///
    !missing(counselor_id) & ///
    inrange(project_week, 1, 20)

display "Potential RCT analysis sample: " r(N)


****************************************************************************
**# 				13. End of analysis checks
****************************************************************************

display "=================================================="
display "Analysis checks completed"
display "=================================================="

