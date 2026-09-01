/******************************************************************
 06_heterogeneity_analysis.do
 Project: SoMB 

 Purpose:
    Test whether treatment effects on main efficiency outcomes
    vary by selected case and implementation characteristics.

 Primary heterogeneity dimensions:
    1. Case complexity
    2. Translation requirement
    3. Counsellor / language group
    4. Implementation phase

 Main outcomes:
    - Consultation duration
	- Form duration
 
******************************************************************/

clear
set more off
version 18


/******************************************************************
 0. Load data
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
 2. Case complexity
******************************************************************/

foreach outcome in ///
    consultation_duration_min ///
    form_duration_min {

    display as text ///
        "Heterogeneity by case complexity: `outcome'"

    reg `outcome' ///
        i.treatment##i.question_complexity ///
        i.counselor_num ///
        i.project_week ///
        if analysis_sample == 1, ///
        vce(cluster counselor_week)

    margins question_complexity, ///
        dydx(treatment)
}



/******************************************************************
 3. Translation requirement
******************************************************************/
capture drop late_phase

gen late_phase = ///
    project_week >= 11 ///
    if inrange(project_week, 1, 20)

label define phase_lbl ///
    0 "Weeks 1-10" ///
    1 "Weeks 11-20", ///
    replace

label values late_phase phase_lbl


foreach outcome in ///
    consultation_duration_min ///
    form_duration_min {

    reg `outcome' ///
        i.treatment##i.late_phase ///
        i.counselor_num ///
        i.project_week ///
        if analysis_sample == 1, ///
        vce(cluster counselor_week)

    margins late_phase, ///
        dydx(treatment)

    testparm ///
        1.treatment#i.late_phase
}


/******************************************************************
 4. Counsellor / language group
******************************************************************
A = Russian / Ukrainian
 B = Arabic
 C = Persian
 D = Turkish
 E = French

 Counsellor and language are closely linked.
 Interpret as counsellor/language-group heterogeneity,
 not as pure language effects.
******************************************************************/

foreach outcome in ///
    consultation_duration_min ///
    form_duration_min {

    reg `outcome' ///
        i.treatment##i.counselor_num ///
        i.project_week ///
        if analysis_sample == 1, ///
        vce(cluster counselor_week)

    margins counselor_num, ///
        dydx(treatment)

    testparm ///
        1.treatment#i.counselor_num
}

/******************************************************************
 5. Optional secondary heterogeneity: gender
******************************************************************/
* Create numeric gender variable for heterogeneity analysis
gen gender_binary = .

replace gender_binary = 0 if gender == "Male"
replace gender_binary = 1 if gender == "Female"

label define gender_lbl ///
    0 "Male" ///
    1 "Female"

label values gender_binary gender_lbl

label variable gender_binary ///
    "Gender of person seeking consultation"
	
	
reg consultation_duration_min ///
    i.treatment##i.gender_binary ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1 & ///
       !missing(gender_binary), ///
    vce(cluster counselor_week)

margins gender_binary, ///
    dydx(treatment)

testparm ///
    1.treatment#i.gender_binary
	

	
	
/******************************************************************
 6. Implementation phase
******************************************************************/

* Note:
* translation_yes is only observed for cases in which Lateris was used.
* It therefore reflects how Lateris was used, rather than an exogenous
* case characteristic that is observed in both treatment and control.
*
* For this reason, translation_yes is not used as a treatment
* heterogeneity variable and no treatment × translation interaction
* is estimated.
*
* The analysis below is descriptive and restricted to the Lateris
* treatment group. It compares consultation duration between cases
* with and without translation use.

foreach outcome in ///
    consultation_duration_min ///
    form_duration_min {

    reg `outcome' ///
        i.treatment##i.translation_yes ///
        i.counselor_num ///
        i.project_week ///
        if analysis_sample == 1 & ///
           !missing(translation_yes), ///
        vce(cluster counselor_week)

    margins translation_yes, ///
        dydx(treatment)

    testparm ///
        1.treatment#i.translation_yes
}



display as text ///
    "06_heterogeneity_analysis.do completed successfully."