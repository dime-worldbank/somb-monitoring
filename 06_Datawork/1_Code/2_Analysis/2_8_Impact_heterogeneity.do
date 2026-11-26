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

4) Objective: 	Test whether the treatment effects vary by case complexity,
				translation, counsellor language group, gender and phase

5) Output:		- log only

*************************************************************************
*************************************************************************/

clear all
set more off

****************************************************************************
**# 				1. Load data
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
**# 				3. Case complexity
****************************************************************************

foreach outcome in ///
     consultation_duration_min{

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

*------------------------------------------------------------
* Create binary complexity variable
* 1–3 = Low complexity
* 4–6 = High complexity
*------------------------------------------------------------

gen complexity_high = .
replace complexity_high = 0 if inrange(question_complexity, 1, 3)
replace complexity_high = 1 if inrange(question_complexity, 4, 6)

label define complexity_lbl ///
    0 "Low complexity" ///
    1 "High complexity"

label values complexity_high complexity_lbl

* Check distribution
tab complexity_high
tab question_complexity complexity_high, missing

reg consultation_duration_min ///
    i.treatment##i.complexity_high ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

* Formal test: Does treatment effect differ by complexity?
test 1.treatment#1.complexity_high

* Treatment effect separately for low and high complexity
margins complexity_high, dydx(treatment)



****************************************************************************
**# 				4. Implementation phase
****************************************************************************

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
    consultation_duration_min {

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


reg consultation_duration_min ///
    i.treatment##i.late_phase ///
    i.counselor_num ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

* Formal interaction test
test 1.treatment#1.late_phase

* Treatment effect by phase
margins late_phase, dydx(treatment)

****************************************************************************
**# 				5. Counsellor / language group
****************************************************************************

* ******************************************************************
* A = Russian / Ukrainian
* B = Arabic
* C = Persian
* D = Turkish
* E = French
* Counsellor and language are closely linked.
* Interpret as counsellor/language-group heterogeneity,
* not as pure language effects.

foreach outcome in ///
    consultation_duration_min  {

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


****************************************************************************
**# 				6. Optional secondary heterogeneity: gender
****************************************************************************

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




display as text ///
    "06_heterogeneity_analysis.do completed successfully."

