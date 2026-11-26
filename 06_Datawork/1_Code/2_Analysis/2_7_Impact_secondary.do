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

4) Objective: 	Estimate the secondary service and behavioural outcomes, and
				summarise the quality of Lateris-supported counselling

5) Output:		- log only

*************************************************************************
*************************************************************************/

clear all
set more off

****************************************************************************
**# 				1. Load analysis data
****************************************************************************

use "${processing}/SoMB_WB_analysis.dta", clear


****************************************************************************
**# 				2. Verify analysis variables
****************************************************************************

capture confirm variable analysis_sample

if _rc {
    display as error ///
        "ERROR: analysis_sample not found. Run 01_create_analysis_variables.do."
    exit 111
}

capture confirm variable counselor_week

if _rc {
    display as error ///
        "ERROR: counselor_week not found. Run 01_create_analysis_variables.do."
    exit 111
}


****************************************************************************
**# 				3. Secondary service outcomes
****************************************************************************

* Referral provided
reg referral_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store secondary_referral


* Feedback received
reg feedback_received_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store secondary_feedback


****************************************************************************
**# 				4. Behavioral / mechanism outcome
****************************************************************************

* Use of other AI tools
reg other_ai_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store mechanism_other_ai


****************************************************************************
**# 				5. Descriptive quality of Lateris-supported counselling
****************************************************************************

display as text ///
    "=========================================================="
display as text ///
    "QUALITY OF LATERIS-SUPPORTED COUNSELLING"
display as text ///
    "DESCRIPTIVE ONLY"
display as text ///
    "=========================================================="


* Overall quality index
summarize quality_index ///
    if analysis_sample == 1 & lateris_yes == 1, ///
    detail


* Individual quality dimensions
foreach outcome in ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness {

    display as text ///
        "Quality outcome: `outcome'"

    summarize `outcome' ///
        if analysis_sample == 1 & ///
           lateris_yes == 1
}


****************************************************************************
**# 				6. Results
****************************************************************************

display as text ///
    "=========================================================="
display as text ///
    "SECONDARY SERVICE OUTCOMES"
display as text ///
    "=========================================================="


estimates table ///
    secondary_referral ///
    secondary_feedback, ///
    keep(treatment) ///
    b(%9.3f) ///
    se(%9.3f) ///
    stats(N r2)


display as text ///
    "=========================================================="
display as text ///
    "BEHAVIORAL / MECHANISM OUTCOME"
display as text ///
    "=========================================================="


estimates table ///
    mechanism_other_ai, ///
    keep(treatment) ///
    b(%9.3f) ///
    se(%9.3f) ///
    stats(N r2)


display as text ///
    "05_secondary_outcomes.do completed successfully."

