/******************************************************************
 04_main_ols.do
 Project: SoMB / Lateris RCT
 Purpose: Estimate main intention-to-treat (ITT) effects of
          randomized Lateris assignment on primary and secondary
          outcomes
******************************************************************/

clear
set more off


/******************************************************************
 0. Define files
******************************************************************/

global analysis_file "$processed_path/SoMB_WB_analysis.dta"

use "$analysis_file", clear


/******************************************************************
 1. Prepare analysis sample
******************************************************************/
capture confirm variable counselor_num

if _rc {
    display as error ///
        "ERROR: counselor_num not found. Run 01_create_analysis_variables.do."
    exit 111
}

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

* Verify sample definition
assert analysis_sample == ///
    (!missing(treatment) & ///
     !missing(counselor_id) & ///
     inrange(project_week, 1, 20))

count if analysis_sample == 1
tab counselor_id if analysis_sample == 1
tab treatment if analysis_sample == 1




/******************************************************************
 2. Primary outcome 1:
    Consultation / response duration
******************************************************************/

reg consultation_duration_min ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store m_consultation


/******************************************************************
 3. Primary outcome 2:
    Form completion duration
******************************************************************/

reg form_duration_min ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_form


/******************************************************************
 4. Primary outcome 3:
    Case volume
    Unit of analysis: counsellor-week
******************************************************************/

**
preserve

keep if analysis_sample == 1

collapse ///
    (sum) case_volume = case_counter, ///
    by(counselor_id counselor_num project_week treatment)

* to see if the in which week and which case the counsellor had 0 cases, to comapare to sick
* days and vacation days.

egen counselor_week = group(counselor_num project_week)

label variable case_volume ///
    "Number of cases per counsellor-week"

label variable counselor_week ///
    "Counsellor-project week randomization unit"

summarize case_volume, detail

reg case_volume ///
    treatment ///
    i.counselor_num ///
    i.project_week, ///
    vce(cluster counselor_week)

estimates store m_volume

restore



/* Counselor-week availability for case volume analysis
 Remove / replace once absence information is verified
******************************************************************

preserve

keep if analysis_sample == 1

collapse ///
    (sum) case_volume = case_counter, ///
    by(counselor_id counselor_num project_week treatment)

* Identify counsellor-weeks with no observed cases
fillin counselor_num project_week

* Restore counsellor ID for filled-in observations
bysort counselor_num (counselor_id): ///
    replace counselor_id = counselor_id[_N] ///
    if missing(counselor_id)

* Temporary availability variable
gen counselor_active = 1

/*
 important:
 After checking vacation / absence information,
 set counselor_active = 0 for confirmed absence weeks.

 Example:

 replace counselor_active = 0 ///
     if counselor_id == "D" & inrange(project_week, 13, 15)

 replace counselor_active = 0 ///
     if counselor_id == "B" & project_week == 15
*/

* For active weeks with no observed cases:
* interpret missing case volume as zero cases
replace case_volume = 0 ///
    if missing(case_volume) & counselor_active == 1

* For confirmed absence weeks:
* case volume should remain missing
replace case_volume = . ///
    if counselor_active == 0

* Show weeks requiring verification
list counselor_id counselor_num project_week ///
    case_volume counselor_active ///
    if _fillin == 1, separator(0)

restore
*/

/******************************************************************
 5. Secondary outcome:
    Overall response quality index
	 Treatment-only descriptive analysis: Lateris quality
******************************************************************/

* Quality is only measured when Lateris was used.
* Therefore, quality cannot be analyzed as an ITT outcome.
* Results below are descriptive and conditional on Lateris use.

summarize quality_index if lateris_yes == 1, detail

tabstat quality_index if lateris_yes == 1, ///
    statistics(n mean sd p25 p50 p75 min max)

* Quality over project weeks
tabstat quality_index if lateris_yes == 1, ///
    by(project_week) ///
    statistics(n mean sd)

* Quality by counselor
tabstat quality_index if lateris_yes == 1, ///
    by(counselor_num) ///
    statistics(n mean sd)

/******************************************************************
 6. Lateris-only quality measures
    Individual quality dimensions

    Note:
    Quality measures are collected only when Lateris was used.
    They therefore cannot be used to estimate ITT effects by
    comparing randomized treatment and control observations.
    The following analyses are descriptive and conditional on
    actual Lateris use.
******************************************************************/

foreach outcome in ///
    accuracy ///
    clarity ///
    appropriateness ///
    completeness {

    display "---------------------------------------------"
    display "Lateris-only quality measure: `outcome'"

    * Number of observed ratings
    count if lateris_yes == 1 & !missing(`outcome')
    display "Observed ratings: " r(N)

    * Descriptive statistics
    summarize `outcome' ///
        if lateris_yes == 1 & !missing(`outcome')

    * Distribution of ratings
    tab `outcome' ///
        if lateris_yes == 1, missing
}


/******************************************************************
 7. Secondary outcome:
    Referral provided
******************************************************************/

reg referral_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_referral


/******************************************************************
 8. Secondary outcome:
    Feedback received
******************************************************************/

reg feedback_received_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_feedback


/******************************************************************
 9. Secondary outcome:
    Detailed feedback available
******************************************************************/

reg has_detailed_feedback ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_detailed_feedback


/******************************************************************
 10. Treatment fidelity / first stage
******************************************************************/

reg lateris_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_lateris_use


/******************************************************************
 11. Other AI use
******************************************************************/

reg other_ai_yes ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce( cluster counselor_week)

estimates store m_other_ai


/******************************************************************
 12. Display main primary estimates
******************************************************************/

estimates table ///
    m_consultation ///
    m_form ///
    m_volume, ///
    keep(treatment) ///
    b(%9.3f) ///
    se(%9.3f) ///
    stats(N r2)



/******************************************************************
 End
******************************************************************/

display as text ///
    "05_main_analysis.do completed successfully."