/******************************************************************
 01_import_clean.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Import raw Vtiger CSV files, rename variables, clean IDs,
          create date/week variables, and save cleaned base dataset
******************************************************************/

clear
set more off

/******************************************************************
 0. Define files
******************************************************************/

global clean_file "$processed_path/SoMB_WB_clean_base.dta"

/******************************************************************
 1. Import and append all raw CSV files
******************************************************************/

clear

tempfile master
save `master', emptyok replace
local files : dir "$raw_path" files "*.csv"

foreach file of local files {

    display "Importing: `file'"

    import delimited ///
        "$raw_path/`file'", ///
        clear varnames(1) stringcols(_all)

    gen source_file = "`file'"

    append using `master'
    save `master', replace
}

/******************************************************************
 2. Rename variables to English
******************************************************************/

capture rename wohnortbundesland federal_state
capture rename wohnortstadt city
capture rename feedbackerhalten feedback_received
capture rename falschinfos misinformation_flag
capture rename ausführlichesfeedback detailed_feedback
capture rename falschinfostext misinformation_text
capture rename verweisberatungerfolgt referral_provided
capture rename erstellt created_raw
capture rename kanal channel
capture rename wannwurdediefragegestellt question_time
capture rename geschlechtfrage gender
capture rename sprache language
capture rename drittpersonbetroffen third_party_affected
capture rename anonym_soms anonymous_case
capture rename beratungsthemen consultation_topics
capture rename somb_verweis somb_referral
capture rename somb_aufenthaltsstatus residence_status
capture rename somb_erwerbsstatus employment_status
capture rename beratungsbeginn consultation_start
capture rename beratungsende consultation_end
capture rename plattform_gruppenname platform_group
capture rename anzahlvonreaktionen reactions_count
capture rename somb_zugang_gruppe group_access
capture rename erfassungsanfang form_start
capture rename erfassungsende form_end
capture rename andereskitoolbenutzt other_ai_tool_used
capture rename welcheskitool ai_tool_used
capture rename laterisgenutzt lateris_used
capture rename genauigkeit accuracy
capture rename grundkinutzung ai_usage_reason
capture rename klarheit clarity
capture rename angemessenheit appropriateness
capture rename komplexitätderfrage question_complexity
capture rename menschlicheüberprüfung human_review
capture rename nationalitäten nationalities
capture rename nationalität nationality
capture rename übersetzung translation_flag
capture rename geschwindigkeit speed
capture rename vollständigkeit_relevanteinfos completeness
capture rename quellen sources
capture rename textoriginal original_text
capture rename antwort response_text
capture rename erstoderfolgeberatung consultation_type
capture rename notizen notes
capture rename antwortjuristischgeprüft legally_reviewed
capture rename beratungsnr case_id

* Alternative Lateris variables if present in different exports
capture rename v49 lateris_used_alt
capture rename v48 lateris_used_alt
capture rename v45 lateris_used_alt

/******************************************************************
 3. Basic string cleaning
******************************************************************/

ds, has(type string)

foreach var of varlist `r(varlist)' {
    replace `var' = strtrim(`var')
    replace `var' = "" if `var' == "."
}

/******************************************************************
 4. Clean and check case ID
******************************************************************/

capture confirm variable case_id

if _rc {
    display as error "Variable case_id not found. Temporary IDs will be created."
    gen case_id = ""
}

replace case_id = "" if trim(case_id) == ""

gen temp_id = "TEMP_" + string(_n) if missing(case_id)
replace case_id = temp_id if missing(case_id)
drop temp_id

duplicates report case_id
count if missing(case_id)

/******************************************************************
 5. Create date, month and project week variables
******************************************************************/

capture confirm variable created_raw

if _rc {
    display as error "Variable created_raw not found. Check raw export variable names."
    exit 111
}

gen is_valid_created_date = regexm(created_raw, ///
    "^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$")

tab is_valid_created_date, missing

gen double created_datetime = clock(created_raw, "DMY hms") ///
    if is_valid_created_date == 1

format created_datetime %tc

gen created_date = dofc(created_datetime)
format created_date %td

gen created_week = wofd(created_date)
format created_week %tw

gen created_month = mofd(created_date)
format created_month %tm

label variable created_datetime "Creation datetime"
label variable created_date "Creation date"
label variable created_week "Creation week"
label variable created_month "Creation month"

* Project week definition:
* Week 1 = 13 Apr 2026 - 19 Apr 2026
* Week 2 = 20 Apr 2026 - 26 Apr 2026
* Week -1 = 30 Mar 2026 - 05 Apr 2026

gen project_week = floor((created_date - td(13apr2026)) / 7) + 1 ///
    if !missing(created_date)

gen project_week_start = td(13apr2026) + (project_week - 1) * 7 ///
    if !missing(project_week)

gen project_week_end = project_week_start + 6 ///
    if !missing(project_week_start)

format project_week_start project_week_end %td

label variable project_week "Project week relative to 13 Apr 2026"
label variable project_week_start "Project week start date"
label variable project_week_end "Project week end date"

tab project_week, missing
summarize created_date

/******************************************************************
 6. Clean AI usage reason labels
******************************************************************/

capture confirm variable ai_usage_reason

if !_rc {
    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "1: Übersetzung", "Translation", .)

    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "2: Geschwindigkeit", "Faster Response", .)

    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "3: Aggregation aller relevanten Informationen", ///
        "Information Synthesis", .)

    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "4: Hinzufügen zuverlässiger Quellen", ///
        "Source Support", .)

    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "Sonstiges", "Other", .)

    replace ai_usage_reason = subinstr(ai_usage_reason, ///
        "|##|", " + ", .)
}

/******************************************************************
 7. Keep monitoring period
******************************************************************/

keep if created_date >= td(01apr2026) & !missing(created_date)

* Exclude days with known data collection or technical issues
drop if inlist(created_date, ///
    td(08may2026), ///
    td(13may2026), ///
    td(27may2026))

tab project_week, missing
summarize created_date

/******************************************************************
 8. Save clean base dataset
******************************************************************/

compress
save "$clean_file", replace