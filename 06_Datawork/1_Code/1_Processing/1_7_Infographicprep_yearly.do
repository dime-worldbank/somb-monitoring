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

4) Objective: 	Build the infographic variables, grouped categories and figure
				labels

5) Output:		- SoMB_WB_infographic_analysis.dta

*************************************************************************
*************************************************************************/

clear all
set more off

****************************************************************************
**# 				1. Load data
****************************************************************************

capture confirm file "${processing}/SoMB_yearly_analysis.dta"
if _rc {
    display as error "Input file not found: ${processing}/SoMB_yearly_analysis.dta"
    exit 601
}

use "${processing}/SoMB_yearly_analysis.dta", clear


****************************************************************************
**# 				2. Basic helper variables
****************************************************************************

capture drop one_case
gen byte one_case = 1
label variable one_case "Case counter"


****************************************************************************
**# 				3. Referral and anonymity indicators
****************************************************************************

capture drop referral_dummy
gen byte referral_dummy = .
replace referral_dummy = 1 if inlist(referral_provided, "Yes", "Ja", "yes", "YES")
replace referral_dummy = 0 if inlist(referral_provided, "No",  "Nein", "no",  "NO")
label variable referral_dummy "Referral provided"

capture drop anonymous_yes
gen byte anonymous_yes = .
replace anonymous_yes = 1 if inlist(anonymous_case, "Yes", "Ja", "yes", "YES")
replace anonymous_yes = 0 if inlist(anonymous_case, "No",  "Nein", "no",  "NO")
label variable anonymous_yes "Anonymous case"


****************************************************************************
**# 				4. Grouped counselling topic variable
****************************************************************************

capture drop topic_group
gen str40 topic_group = ""

replace topic_group = "Employment & Labour Market" ///
    if inlist(topic_main_text, ///
        "Access to labor market and vocational training", ///
        "Employment contract / collective agreement", ///
        "Illegal employment", ///
        "Mini-job / part-time / full-time employment", ///
        "Termination of employment relationships")

replace topic_group = "Career Orientation & Training" ///
    if topic_main_text == "Career orientation: internships / training / studies"

replace topic_group = "Social Benefits & Assistance" ///
    if inlist(topic_main_text, ///
        "Information about SGB II", ///
        "Supplementary social benefits and social assistance")

replace topic_group = "Language Support" ///
    if topic_main_text == "Language support"

replace topic_group = "Administrative & Tax Support" ///
    if topic_main_text == "Other: tax documents/ advisory services"

replace topic_group = "Qualification Recognition" ///
    if inlist(topic_main_text, ///
        "Recognition of qualifications / equivalency of degrees", ///
        "Recognition of qualifications / equivalence of degrees")

replace topic_group = "Residence & Legal Status" ///
    if topic_main_text == "Residence law issues for non-EU citizens"

label variable topic_group "Counselling topic group"

* Keep a copy with the old graph-specific name in case older scripts use it.
capture drop referral_topic_group
gen str40 referral_topic_group = topic_group
label variable referral_topic_group "Counselling topic group for referral graphs"


****************************************************************************
**# 				5. Figure labels
****************************************************************************

* Shorten long employment labels for figures only.
capture drop employment_status_fig
gen str80 employment_status_fig = employment_status
replace employment_status_fig = "Unemployed, receiving state benefits" ///
    if employment_status == "Unemployed, receiving benefits from Jobcenter/Federal Employment Agency"
replace employment_status_fig = "Employed, subject to social security contributions" ///
    if employment_status == "Employed subject to social security contributions"
label variable employment_status_fig "Employment status, shortened for figures"


****************************************************************************
**# 				6. Save infographic analysis dataset
****************************************************************************

compress
save "${processing}/SoMB_WB_infographic_analysis.dta", replace

display "------------------------------------------------------------"
display "Infographic cleaning/grouping completed."
display "Saved: ${processing}/SoMB_WB_infographic_analysis.dta"
display "------------------------------------------------------------"


