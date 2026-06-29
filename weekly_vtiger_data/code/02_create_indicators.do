/******************************************************************
 02_create_indicators.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Create monitoring indicators for Lateris use, duration,
          quality ratings, review, feedback and data quality
******************************************************************/

clear
set more off

/******************************************************************
 0. Define files
******************************************************************/

global clean_file     "$processed_path/SoMB_WB_clean_base.dta"
global indicator_file "$processed_path/SoMB_WB_monitoring_indicators.dta"

/******************************************************************
 1. Load clean base dataset
******************************************************************/

use "$clean_file", clear
describe

/******************************************************************
 2. Create Lateris usage indicator
******************************************************************/

gen lateris_yes = .

capture confirm variable lateris_used
if !_rc {
    replace lateris_yes = 1 if inlist(lateris_used, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace lateris_yes = 0 if inlist(lateris_used, "Nein", "No", "no", "NO", "0", "0: Nein")
}

capture confirm variable lateris_used_alt
if !_rc {
    replace lateris_yes = 1 if inlist(lateris_used_alt, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace lateris_yes = 0 if inlist(lateris_used_alt, "Nein", "No", "no", "NO", "0", "0: Nein") ///
        & missing(lateris_yes)
}

label define lateris_lbl 0 "No" 1 "Yes", replace
label values lateris_yes lateris_lbl
label variable lateris_yes "Lateris used"

tab lateris_yes, missing

/******************************************************************
 3. Create consultation and form duration variables
******************************************************************/

gen double consultation_start_time = .
gen double consultation_end_time   = .
gen double form_start_time         = .
gen double form_end_time           = .

capture confirm variable consultation_start
if !_rc {
    replace consultation_start_time = clock(consultation_start, "hms")
}

capture confirm variable consultation_end
if !_rc {
    replace consultation_end_time = clock(consultation_end, "hms")
}

capture confirm variable form_start
if !_rc {
    replace form_start_time = clock(form_start, "hms")
}

capture confirm variable form_end
if !_rc {
    replace form_end_time = clock(form_end, "hms")
}

format consultation_start_time consultation_end_time %tcHH:MM:SS
format form_start_time form_end_time %tcHH:MM:SS

gen consultation_duration_min = ///
    (consultation_end_time - consultation_start_time) / 60000 ///
    if !missing(consultation_start_time, consultation_end_time)

gen form_duration_min = ///
    (form_end_time - form_start_time) / 60000 ///
    if !missing(form_start_time, form_end_time)

replace consultation_duration_min = . if consultation_duration_min < 0
replace form_duration_min = . if form_duration_min < 0

label variable consultation_duration_min "Consultation duration in minutes"
label variable form_duration_min "Form completion duration in minutes"

summarize consultation_duration_min form_duration_min, detail

/******************************************************************
 4. Create duration flags
******************************************************************/

gen flag_long_consultation = consultation_duration_min > 120 ///
    if !missing(consultation_duration_min)

gen flag_long_form = form_duration_min > 60 ///
    if !missing(form_duration_min)

gen flag_missing_consultation_time = missing(consultation_start_time) | missing(consultation_end_time)
gen flag_missing_form_time = missing(form_start_time) | missing(form_end_time)

label variable flag_long_consultation "Consultation duration above 120 minutes"
label variable flag_long_form "Form duration above 60 minutes"
label variable flag_missing_consultation_time "Missing consultation start or end time"
label variable flag_missing_form_time "Missing form start or end time"

tab flag_long_consultation, missing
tab flag_long_form, missing

/******************************************************************
 5. Clean quality rating variables
******************************************************************/

foreach var in accuracy clarity appropriateness speed completeness question_complexity {
    
    capture confirm variable `var'
    
    if !_rc {
        
        capture confirm string variable `var'
        
        if !_rc {
            replace `var' = strtrim(`var')
            replace `var' = "" if !regexm(`var', "^[0-9]+(\.0)?$")
            replace `var' = string(real(`var')/10) if inlist(real(`var'), 10, 20, 30, 40, 50)
            destring `var', replace
        }
        
        replace `var' = . if `var' < 1 | `var' > 6
        label variable `var' "`var' rating, cleaned numeric 1-6"
    }
}

/******************************************************************
 6. Create quality availability indicators
******************************************************************/

foreach var in accuracy clarity appropriateness speed completeness question_complexity {
    
    capture confirm variable `var'
    
    if !_rc {
        gen has_`var' = !missing(`var')
        label variable has_`var' "Non-missing `var' rating"
    }
}

gen has_any_quality_rating = 0

foreach var in accuracy clarity appropriateness speed completeness {
    capture confirm variable `var'
    if !_rc {
        replace has_any_quality_rating = 1 if !missing(`var')
    }
}

label variable has_any_quality_rating "At least one quality rating available"

tab has_any_quality_rating, missing

/******************************************************************
 7. Human review and legal review indicators
******************************************************************/

label define yesno_lbl 0 "No" 1 "Yes", replace

gen human_review_yes = .

capture confirm variable human_review
if !_rc {
    replace human_review_yes = 1 if inlist(human_review, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace human_review_yes = 0 if inlist(human_review, "Nein", "No", "no", "NO", "0", "0: Nein")
}

gen legal_review_yes = .

capture confirm variable legally_reviewed
if !_rc {
    replace legal_review_yes = 1 if inlist(legally_reviewed, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace legal_review_yes = 0 if inlist(legally_reviewed, "Nein", "No", "no", "NO", "0", "0: Nein")
}

label values human_review_yes yesno_lbl
label values legal_review_yes yesno_lbl

label variable human_review_yes "Human review conducted"
label variable legal_review_yes "Legal review conducted"

tab human_review_yes, missing
tab legal_review_yes, missing

/******************************************************************
 8. Misinformation and feedback indicators
******************************************************************/

gen feedback_received_yes = .

capture confirm variable feedback_received
if !_rc {
    replace feedback_received_yes = 1 if inlist(feedback_received, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace feedback_received_yes = 0 if inlist(feedback_received, "Nein", "No", "no", "NO", "0", "0: Nein")
}

gen misinformation_yes = .

capture confirm variable misinformation_flag
if !_rc {
    replace misinformation_yes = 1 if inlist(misinformation_flag, "Ja", "Yes", "yes", "YES", "1", "1: Ja")
    replace misinformation_yes = 0 if inlist(misinformation_flag, "Nein", "No", "no", "NO", "0", "0: Nein")
}

gen has_detailed_feedback = 0
capture confirm variable detailed_feedback
if !_rc {
    replace has_detailed_feedback = !missing(detailed_feedback) & trim(detailed_feedback) != ""
}

gen has_misinformation_text = 0
capture confirm variable misinformation_text
if !_rc {
    replace has_misinformation_text = !missing(misinformation_text) & trim(misinformation_text) != ""
}

gen has_notes = 0
capture confirm variable notes
if !_rc {
    replace has_notes = !missing(notes) & trim(notes) != ""
}

label values feedback_received_yes yesno_lbl
label values misinformation_yes yesno_lbl

label variable feedback_received_yes "Feedback received"
label variable misinformation_yes "Misinformation flagged"
label variable has_detailed_feedback "Detailed feedback text available"
label variable has_misinformation_text "Misinformation text available"
label variable has_notes "Notes available"

tab feedback_received_yes, missing
tab misinformation_yes, missing

/******************************************************************
 9. Referral, translation and anonymity indicators
******************************************************************/

gen referral_yes = .

capture confirm variable referral_provided
if !_rc {
    replace referral_provided = strtrim(referral_provided)
    
    replace referral_yes = 1 if inlist(referral_provided, ///
        "1: Ja", "Ja", "Yes", "yes", "YES", "1")
    
    replace referral_yes = 0 if inlist(referral_provided, ///
        "0: Nein", "Nein", "No", "no", "NO", "0")
}

gen translation_yes = .

capture confirm variable translation_flag
if !_rc {
    replace translation_flag = strtrim(translation_flag)
    
    replace translation_yes = 1 if inlist(translation_flag, ///
        "1: Ja", "Ja", "Yes", "yes", "YES", "1")
    
    replace translation_yes = 0 if inlist(translation_flag, ///
        "0: Nein", "Nein", "No", "no", "NO", "0")
}

gen anonymous_yes = .

capture confirm variable anonymous_case
if !_rc {
    replace anonymous_case = strtrim(anonymous_case)
    
    replace anonymous_yes = 1 if inlist(anonymous_case, ///
        "1: Ja", "Ja", "Yes", "yes", "YES", "1")
    
    replace anonymous_yes = 0 if inlist(anonymous_case, ///
        "0: Nein", "Nein", "No", "no", "NO", "0")
}

label values referral_yes yesno_lbl
label values translation_yes yesno_lbl
label values anonymous_yes yesno_lbl

label variable referral_yes "Referral provided"
label variable translation_yes "Translation used"
label variable anonymous_yes "Anonymous case"

tab referral_yes, missing
tab translation_yes, missing
tab anonymous_yes, missing

/******************************************************************
 10. Basic categorical harmonisation
******************************************************************/

capture confirm variable language
if !_rc {
    replace language = "English"   if language == "0: Englisch"
    replace language = "French"    if language == "5: Französisch"
    replace language = "Arabic"    if language == "8: Arabisch"
    replace language = "Russian"   if language == "9: Russisch"
    replace language = "German"    if language == "12: Deutsch"
    replace language = "Persian"   if language == "13: Persisch"
    replace language = "Turkish"   if language == "14: Türkisch"
    replace language = "Ukrainian" if language == "19: Ukrainisch"
}

capture confirm variable gender
if !_rc {
    replace gender = "Female" if ///
        gender == "0: Female" | gender == "0: Weiblich" | gender == "Weiblich"

    replace gender = "Male" if ///
        gender == "1: Male" | gender == "1: Männlich" | gender == "Männlich"

    replace gender = "Divers" if gender == "2: Divers"

    replace gender = "Not identifiable" if ///
        gender == "3: Not identifiable" | ///
        gender == "3: nicht bestimmbar" | ///
        gender == "Nicht bestimmbar"
}

capture confirm variable residence_status
if !_rc {
    replace residence_status = "Not identifiable" ///
        if residence_status == "0: Nicht bestimmbar"

    replace residence_status = "Section 13 Asylum Act (AsylG)" ///
        if residence_status == "1: §13 AsylG"

    replace residence_status = "Section 63a Asylum Act (AsylG)" ///
        if residence_status == "2: §63a AsylG"

    replace residence_status = "Temporary protection under Section 24 Residence Act (AufenthG)" ///
        if residence_status == "6: §24 AufenthG"

    replace residence_status = "Residence permit under Section 25 Residence Act (AufenthG)" ///
        if residence_status == "7: §25 AufenthG"

    replace residence_status = "Temporary suspension of deportation (Duldung)" ///
        if residence_status == "9: Duldung"

    replace residence_status = "Other residence status" ///
        if residence_status == "13: anderer Aufenthaltsstatus"
}

/******************************************************************
 11. Data quality indicators
******************************************************************/

capture confirm variable case_id
if !_rc {
    duplicates tag case_id, gen(flag_duplicate_case_id)
}
else {
    gen flag_duplicate_case_id = .
}

gen flag_missing_language = 0
capture confirm variable language
if !_rc {
    replace flag_missing_language = missing(language) | trim(language) == ""
}

gen flag_missing_gender = 0
capture confirm variable gender
if !_rc {
    replace flag_missing_gender = missing(gender) | trim(gender) == ""
}

gen flag_missing_lateris = missing(lateris_yes)

gen flag_missing_created_date = 0
capture confirm variable created_date
if !_rc {
    replace flag_missing_created_date = missing(created_date)
}

gen flag_qual_miss_lateris_case = ///
    lateris_yes == 1 & has_any_quality_rating == 0

gen flag_any_data_quality_issue = ///
    flag_duplicate_case_id > 0 | ///
    flag_missing_language == 1 | ///
    flag_missing_gender == 1 | ///
    flag_missing_lateris == 1 | ///
    flag_missing_created_date == 1 | ///
    flag_long_consultation == 1 | ///
    flag_long_form == 1 | ///
    flag_qual_miss_lateris_case == 1

label variable flag_duplicate_case_id "Duplicate case ID"
label variable flag_missing_language "Missing language"
label variable flag_missing_gender "Missing gender"
label variable flag_missing_lateris "Missing Lateris indicator"
label variable flag_missing_created_date "Missing creation date"
label variable flag_qual_miss_lateris_case "Lateris case without quality rating"
label variable flag_any_data_quality_issue "Any data quality issue"

tab flag_any_data_quality_issue, missing

/******************************************************************
 12. Save indicator dataset
******************************************************************/

compress
save "$indicator_file", replace