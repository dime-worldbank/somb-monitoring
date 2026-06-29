/********************************************************************
Project: SoMB / WB Vtiger Data
File:    03_infographic_clean_group.do

Purpose:
    Prepare infographic-ready variables and grouped categories.
    This file only changes/creates analytical variables and saves an
    infographic analysis dataset. Graph production is kept separate.

Inputs:
    $processed_path/SoMB_WB_Daten_cleaned_analysis.dta

Outputs:
    $processed_path/SoMB_WB_infographic_analysis.dta


********************************************************************/

version 18 
set more off

*============================================================*
* 0. Project paths
*============================================================*

* These globals should normally be defined in 00_master.do.
* Fallbacks make this do-file runnable as a standalone script.
if "$processed_path" == "" {
    di as error "Global processed_path not defined. Please run 00_master.do."
    exit 198
}

capture mkdir "$processed_path"

global clean_analysis_file "$processed_path/SoMB_analysis.dta"
global infographic_file   "$processed_path/SoMB_WB_infographic_analysis.dta"

capture confirm file "$clean_analysis_file"
if _rc {
    display as error "Input file not found: $clean_analysis_file"
    exit 601
}

use "$clean_analysis_file", clear

*============================================================*
* 1. Basic helper variables
*============================================================*

capture drop one_case
gen byte one_case = 1
label variable one_case "Case counter"

*============================================================*
* 2. Referral and anonymity indicators
*============================================================*

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

*============================================================*
* 3. Grouped counselling topic variable
*============================================================*

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

*============================================================*
* 4. Figure labels
*============================================================*

* Shorten long employment labels for figures only.
capture drop employment_status_fig
gen str80 employment_status_fig = employment_status
replace employment_status_fig = "Unemployed, receiving state benefits" ///
    if employment_status == "Unemployed, receiving benefits from Jobcenter/Federal Employment Agency"
replace employment_status_fig = "Employed, subject to social security contributions" ///
    if employment_status == "Employed subject to social security contributions"
label variable employment_status_fig "Employment status, shortened for figures"

*============================================================*
* 5. Save infographic analysis dataset
*============================================================*

compress
save "$infographic_file", replace

display "------------------------------------------------------------"
display "Infographic cleaning/grouping completed."
display "Saved: $infographic_file"
display "------------------------------------------------------------"
