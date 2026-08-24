/******************************************************************
 03_weekly_tables.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Create weekly monitoring tables for summary KPIs,
          weekly real values/counts, language monitoring,
          Lateris quality and timing

 Notes:
 - This file creates Excel tables only.
 - All graphs are created in 04_graphs.do.
******************************************************************/

clear
set more off

/******************************************************************
 0. Define files
******************************************************************/

global indicator_file "$processed_path/SoMB_WB_monitoring_indicators.dta"
global weekly_excel   "$table_path/weekly_monitoring_tables.xlsx"

capture mkdir "$table_path"

/******************************************************************
 1. Load indicator dataset
******************************************************************/

use "$indicator_file", clear

capture drop case_counter
gen case_counter = 1

/******************************************************************
 2. Weekly top-level summary
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (median) med_consultation_duration = consultation_duration_min ///
    (mean) avg_form_duration = form_duration_min ///
    (median) med_form_duration = form_duration_min ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness, ///
    by(project_week project_week_start project_week_end)

replace share_lateris = share_lateris * 100

order project_week project_week_start project_week_end ///
      total_cases lateris_cases share_lateris ///
      avg_consultation_duration med_consultation_duration ///
      avg_form_duration med_form_duration ///
      avg_accuracy avg_clarity avg_appropriateness avg_speed avg_completeness

sort project_week

export excel using "$weekly_excel", ///
    sheet("weekly_summary") firstrow(variables) replace

restore

/******************************************************************
 3. Weekly duration raw values
******************************************************************/

preserve

keep project_week project_week_start project_week_end ///
     case_id language lateris_yes consultation_duration_min form_duration_min

sort project_week language case_id

export excel using "$weekly_excel", ///
    sheet("weekly_duration_raw") firstrow(variables) sheetreplace

restore

/******************************************************************
 4. Weekly duration distribution in 5-minute bins
******************************************************************/

preserve

gen consultation_duration_bin5 = floor(consultation_duration_min / 5) * 5 ///
    if !missing(consultation_duration_min)

keep if !missing(consultation_duration_bin5)

collapse (sum) cases = case_counter, ///
    by(project_week project_week_start project_week_end consultation_duration_bin5)

rename consultation_duration_bin5 duration_bin5
gen duration_type = "Consultation"

tempfile consultation_bins
save `consultation_bins', replace

restore

preserve

gen form_duration_bin5 = floor(form_duration_min / 5) * 5 ///
    if !missing(form_duration_min)

keep if !missing(form_duration_bin5)

collapse (sum) cases = case_counter, ///
    by(project_week project_week_start project_week_end form_duration_bin5)

rename form_duration_bin5 duration_bin5
gen duration_type = "Form"

append using `consultation_bins'

order duration_type project_week project_week_start project_week_end duration_bin5 cases
sort duration_type project_week duration_bin5

export excel using "$weekly_excel", ///
    sheet("duration_bins_5min") firstrow(variables) sheetreplace

restore

/******************************************************************
 5. Weekly cases by language
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness, ///
    by(project_week project_week_start project_week_end language)

replace share_lateris = share_lateris * 100

order project_week project_week_start project_week_end language ///
      total_cases lateris_cases share_lateris ///
      avg_accuracy avg_clarity avg_appropriateness avg_speed avg_completeness

sort project_week language

export excel using "$weekly_excel", ///
    sheet("by_language") firstrow(variables) sheetreplace

restore

/******************************************************************
 6. Case-level language entries
******************************************************************/

preserve

keep project_week project_week_start project_week_end ///
     case_id language lateris_yes accuracy clarity appropriateness speed completeness

sort project_week language case_id

export excel using "$weekly_excel", ///
    sheet("by_language_raw") firstrow(variables) sheetreplace

restore

/******************************************************************
 7. Weekly cases by gender
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week project_week_start project_week_end gender)

replace share_lateris = share_lateris * 100

sort project_week gender

export excel using "$weekly_excel", ///
    sheet("by_gender") firstrow(variables) sheetreplace

restore

/******************************************************************
 8. Weekly cases by employment status
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week project_week_start project_week_end employment_status)

replace share_lateris = share_lateris * 100

sort project_week employment_status

export excel using "$weekly_excel", ///
    sheet("by_employment") firstrow(variables) sheetreplace

restore

/******************************************************************
 9. Weekly cases by channel
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week project_week_start project_week_end channel)

replace share_lateris = share_lateris * 100

sort project_week channel

export excel using "$weekly_excel", ///
    sheet("by_channel") firstrow(variables) sheetreplace

restore

/******************************************************************
 10. Weekly Lateris quality table
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness ///
    (mean) avg_complexity = question_complexity, ///
    by(project_week project_week_start project_week_end lateris_yes)

order project_week project_week_start project_week_end lateris_yes total_cases ///
      avg_accuracy avg_clarity avg_appropriateness avg_speed avg_completeness avg_complexity

sort project_week lateris_yes

export excel using "$weekly_excel", ///
    sheet("lateris_quality") firstrow(variables) sheetreplace

restore

/******************************************************************
 11. Overall Lateris quality totals
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness ///
    (mean) avg_complexity = question_complexity, ///
    by(lateris_yes)

sort lateris_yes

export excel using "$weekly_excel", ///
    sheet("lateris_quality_total") firstrow(variables) sheetreplace

restore

/******************************************************************
 12. Weekly Lateris use by language
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week project_week_start project_week_end language)

replace share_lateris = share_lateris * 100

order project_week project_week_start project_week_end language ///
      total_cases lateris_cases share_lateris

sort project_week language

export excel using "$weekly_excel", ///
    sheet("lateris_by_language") firstrow(variables) sheetreplace

restore

/******************************************************************
 13. Weekly timing table
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (median) med_consultation_duration = consultation_duration_min ///
    (mean) avg_form_duration = form_duration_min ///
    (median) med_form_duration = form_duration_min ///
    (sum) long_consultations = flag_long_consultation ///
    (sum) long_forms = flag_long_form, ///
    by(project_week project_week_start project_week_end lateris_yes)

sort project_week lateris_yes

export excel using "$weekly_excel", ///
    sheet("timing") firstrow(variables) sheetreplace

restore

/******************************************************************
 14. Internal data quality table
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) duplicate_case_ids = flag_duplicate_case_id ///
    (sum) missing_language = flag_missing_language ///
    (sum) missing_gender = flag_missing_gender ///
    (sum) missing_lateris = flag_missing_lateris ///
    (sum) missing_created_date = flag_missing_created_date ///
    (sum) long_consultations = flag_long_consultation ///
    (sum) long_forms = flag_long_form ///
    (sum) qual_miss_lateris_cases = flag_qual_miss_lateris_case ///
    (sum) any_data_quality_issue = flag_any_data_quality_issue, ///
    by(project_week project_week_start project_week_end)

sort project_week

export excel using "$weekly_excel", ///
    sheet("internal_data_quality") firstrow(variables) sheetreplace

restore

/******************************************************************
 15a. AI tool use and usage reasons - weekly
******************************************************************/

preserve

keep if !missing(ai_tool_used) | !missing(ai_usage_reason)

collapse ///
    (sum) total_cases = case_counter, ///
    by(project_week project_week_start project_week_end ///
       lateris_yes ai_tool_used ai_usage_reason)

sort project_week lateris_yes ai_tool_used ai_usage_reason

export excel using "$weekly_excel", ///
    sheet("ai_tool_reason_weekly") firstrow(variables) sheetreplace

restore

/******************************************************************
 15b. AI tool use and usage reasons - overall
******************************************************************/

preserve

keep if !missing(ai_tool_used) | !missing(ai_usage_reason)

collapse ///
    (sum) total_cases = case_counter, ///
    by(lateris_yes ai_tool_used ai_usage_reason)

sort lateris_yes ai_tool_used ai_usage_reason

export excel using "$weekly_excel", ///
    sheet("ai_tool_reason_overall") firstrow(variables) sheetreplace

restore

/******************************************************************
 16. Referral provided by Lateris status - table
******************************************************************/

preserve

keep if !missing(referral_yes) & !missing(lateris_yes)

collapse ///
    (count) total_cases = referral_yes ///
    (mean) share_referral = referral_yes, ///
    by(lateris_yes)

replace share_referral = share_referral * 100

sort lateris_yes

export excel using "$weekly_excel", ///
    sheet("referral_by_lateris") firstrow(variables) sheetreplace

restore

/******************************************************************
 16a. Referral provided - overall table
******************************************************************/

preserve

keep if !missing(referral_yes)

collapse ///
    (count) total_cases = referral_yes ///
    (mean) share_referral = referral_yes

replace share_referral = share_referral * 100

export excel using "$weekly_excel", ///
    sheet("referral_overall") firstrow(variables) sheetreplace

restore

/******************************************************************
 17a. Anonymous cases - overall table
******************************************************************/

preserve

keep if !missing(anonymous_yes)

collapse ///
    (count) total_cases = anonymous_yes ///
    (mean) share_anonymous = anonymous_yes

replace share_anonymous = share_anonymous * 100

export excel using "$weekly_excel", ///
    sheet("anonymous_overall") firstrow(variables) sheetreplace

restore

/******************************************************************
 17b. Anonymous cases by Lateris status - table
******************************************************************/

preserve

keep if !missing(anonymous_yes) & !missing(lateris_yes)

collapse ///
    (count) total_cases = anonymous_yes ///
    (mean) share_anonymous = anonymous_yes, ///
    by(lateris_yes)

replace share_anonymous = share_anonymous * 100

sort lateris_yes

export excel using "$weekly_excel", ///
    sheet("anonymous_by_lateris") firstrow(variables) sheetreplace

restore

/******************************************************************
 18. Save table-ready dataset
******************************************************************/

save "$indicator_file", replace
