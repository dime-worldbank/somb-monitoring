/******************************************************************
 05_secondary_outcomes.do
 Project: SoMB / Lateris RCT
 Purpose:
    Estimate secondary service outcomes and behavioral outcomes,
    and summarize Lateris-supported counselling quality.

 Main specification:
    Outcome = beta * treatment
              + counsellor FE
              + project-week FE

 Standard errors:
    Clustered at counsellor-project-week level
******************************************************************/

clear
set more off
version 18


/******************************************************************
 0. Load analysis data
******************************************************************/

use "$processed_path/SoMB_WB_analysis.dta", clear


/******************************************************************
 1. Verify analysis variables
******************************************************************/

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


/******************************************************************
 2. Secondary service outcomes
******************************************************************/

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


/******************************************************************
 3. Behavioral / mechanism outcome
******************************************************************/

* Use of other AI tools
reg other_ai_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store mechanism_other_ai


/******************************************************************
 4. Descriptive quality of Lateris-supported counselling
******************************************************************/

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


/******************************************************************
 5. Results
******************************************************************/

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