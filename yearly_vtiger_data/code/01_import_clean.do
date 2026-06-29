/********************************************************************
Project: SoMB / WB Vtiger Data
File:    01_import_clean.do

Purpose:
    Import and clean the raw Vtiger dataset. This file performs only
    general cleaning steps that are needed for all downstream analysis:
    variable renaming, translating, date construction, category harmonisation, and
    basic counselling topic coding.

Inputs:
    $raw_path/SoMB_WB_Daten_2025_03_2026.dta

Outputs:
    $processed_path/SoMB_clean_base.dta

Notes:
    - Designed to be run from 00_master.do.
    - Uses project-relative globals if already defined.
    - If run standalone, default relative folders are used.
********************************************************************/

version 18
clear all
set more off

*============================================================*
* 0. Project paths
*============================================================*

capture confirm global raw_path
if _rc global raw_path "../01_data/raw"

capture confirm global processed_path
if _rc global processed_path "../02_data/processed"

capture mkdir "$processed_path"

global raw_file   "$raw_path/SoMB_WB_Daten_2025_03_2026.dta"
global clean_file "$processed_path/SoMB_clean_base.dta"

capture confirm file "$raw_file"
if _rc {
    display as error "Input file not found: $raw_file"
    exit 601
}

use "$raw_file", clear

*============================================================*
* 1. Rename variables to English
*============================================================*

capture rename wohnortbundesland          federal_state
capture rename wohnortstadt               city
capture rename feedbackerhalten           feedback_received
capture rename falschinfos                misinformation_flag
capture rename ausführlichesfeedback      detailed_feedback
capture rename falschinfostext            misinformation_text
capture rename verweisberatungerfolgt     referral_provided
capture rename erstellt                    created_raw
capture rename kanal                       channel
capture rename wannwurdediefragegestellt  question_time
capture rename geschlechtfrage            gender
capture rename sprache                     language
capture rename drittpersonbetroffen       third_party_affected
capture rename anonym_soms                anonymous_case
capture rename beratungsthemen            consultation_topics
capture rename somb_verweis               somb_referral
capture rename somb_aufenthaltsstatus     residence_status
capture rename somb_erwerbsstatus         employment_status
capture rename beratungsbeginn            consultation_start
capture rename beratungsende              consultation_end
capture rename plattform_gruppenname      platform_group
capture rename anzahlvonreaktionen        reactions_count
capture rename somb_zugang_gruppe         group_access
capture rename andereskitoolbenutzt       other_ai_tool_used
capture rename welcheskitool              ai_tool_used
capture rename laterisgenutzt             lateris_used
capture rename genauigkeit                accuracy
capture rename grundkinutzung             ai_usage_reason
capture rename klarheit                   clarity
capture rename angemessenheit             appropriateness
capture rename komplexitätderfrage        question_complexity
capture rename menschlicheüberprüfung     human_review
capture rename nationalitäten             nationalities
capture rename nationalität               nationality
capture rename übersetzung                translation_flag
capture rename geschwindigkeit            speed
capture rename vollständigkeit_relevanteinfos completeness
capture rename quellen                    sources
capture rename textoriginal               original_text
capture rename antwort                    response_text
capture rename beratungerfolgt            consultation_provided
capture rename erstoderfolgeberatung      consultation_type
capture rename notizen                    notes
capture rename antwortjuristischgeprüft   legally_reviewed
capture rename v45                        lateris_used_alt

*============================================================*
* 2. Clean and construct date variables
*============================================================*

capture confirm variable created_raw
if _rc {
    display as error "Variable created_raw not found. Check raw data export names."
    exit 111
}

capture drop len_created_raw is_valid_created_date created_datetime ///
    created_date created_month created_year created_month_num

gen len_created_raw = strlen(created_raw)

gen is_valid_created_date = regexm(created_raw, ///
    "^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$")

gen double created_datetime = clock(created_raw, "DMY hms") ///
    if is_valid_created_date == 1
format created_datetime %tc

gen created_date = dofc(created_datetime)
format created_date %td

gen created_month = mofd(created_date)
format created_month %tmMon_CCYY

gen created_year = year(created_date)
gen created_month_num = month(created_date)

label variable created_datetime  "Creation datetime"
label variable created_date      "Creation date"
label variable created_month     "Creation month"
label variable created_year      "Creation year"
label variable created_month_num "Creation month number"

keep if is_valid_created_date == 1

*============================================================*
* 3. Translate and harmonise categorical variables
*============================================================*

* Federal state
replace federal_state = "Not identifiable" if federal_state == "0: Nicht bestimmbar"
replace federal_state = "Baden-Wuerttemberg" if federal_state == "1: Baden-Württemberg"
replace federal_state = "Bavaria" if federal_state == "2: Bayern"
replace federal_state = "Berlin" if federal_state == "3: Berlin"
replace federal_state = "Brandenburg" if federal_state == "4: Brandenburg"
replace federal_state = "Bremen" if federal_state == "5: Bremen"
replace federal_state = "Hamburg" if federal_state == "6: Hamburg"
replace federal_state = "Hesse" if federal_state == "7: Hessen"
replace federal_state = "Mecklenburg-Western Pomerania" if federal_state == "8: Mecklenburg-Vorpommern"
replace federal_state = "Lower Saxony" if federal_state == "9: Niedersachsen"
replace federal_state = "North Rhine-Westphalia" if federal_state == "10: Nordrhein-Westfalen"
replace federal_state = "Rhineland-Palatinate" if federal_state == "11: Rheinland-Pfalz"
replace federal_state = "Saarland" if federal_state == "12: Saarland"
replace federal_state = "Saxony" if federal_state == "13: Sachsen"
replace federal_state = "Saxony-Anhalt" if federal_state == "14: Sachsen-Anhalt"
replace federal_state = "Schleswig-Holstein" if federal_state == "15: Schleswig-Holstein"
replace federal_state = "Thuringia" if federal_state == "16: Thüringen"

* Channel
replace channel = "Facebook group" if channel == "1100: Facebook-Gruppe"
replace channel = "Facebook community chat" if channel == "1101: Facebook-Community-Chat"
replace channel = "Facebook page" if channel == "1200: Facebook-Seite"
replace channel = "Facebook page messenger" if channel == "1201: Facebook-Seiten-Messenger"
replace channel = "Facebook profile" if channel == "1300: Facebook-Profil"
replace channel = "Facebook profile messenger" if channel == "1301: Facebook-Profil-Messenger"
replace channel = "TikTok" if channel == "14000: TikTok"
replace channel = "TikTok private message" if channel == "14001: TikTok – private Nachricht"
replace channel = "WhatsApp group chat" if channel == "4000: WhatsApp - Gruppenchat"
replace channel = "Email" if channel == "5000: E-Mail"
replace channel = "Telegram group chat" if channel == "8000: Telegram - Gruppenchat"
replace channel = "Telegram private message" if channel == "8001: Telegram - private Nachricht"

* Employment status
replace employment_status = "Not identifiable" if employment_status == "0: Nicht bestimmbar"
replace employment_status = "Employed subject to social security contributions" if employment_status == "1: SVP-beschäftigt"
replace employment_status = "Marginal employment" if employment_status == "2: geringfügig beschäftigt"
replace employment_status = "Registered as job-seeking" if employment_status == "4: arbeitssuchend gemeldet"
replace employment_status = "Unemployed, registered with Jobcenter" if employment_status == "5: arbeitslos - beim JC gemeldet"
replace employment_status = "Unemployed, not registered with Jobcenter" if employment_status == "6: arbeitslos - nicht beim JC gemeldet"
replace employment_status = "Unemployed, receiving benefits from Jobcenter/Federal Employment Agency" if employment_status == "7: arbeitslos - Leistungen vom JC/BA"
replace employment_status = "Unemployed, receiving asylum seeker benefits" if employment_status == "8: arbeitslos - Leistungen AsylBLG"
replace employment_status = "In studies or vocational training" if employment_status == "9: in Studium/Ausbildung"

* Language
replace language = "English"   if language == "0: Englisch"
replace language = "French"    if language == "5: Französisch"
replace language = "Arabic"    if language == "8: Arabisch"
replace language = "Russian"   if language == "9: Russisch"
replace language = "German"    if language == "12: Deutsch"
replace language = "Persian"   if language == "13: Persisch"
replace language = "Turkish"   if language == "14: Türkisch"
replace language = "Ukrainian" if language == "19: Ukrainisch"

* Residence status
replace residence_status = "Not identifiable" if residence_status == "0: Nicht bestimmbar"
replace residence_status = "Section 13 Asylum Act (AsylG)" if residence_status == "1: §13 AsylG"
replace residence_status = "Section 63a Asylum Act (AsylG)" if residence_status == "2: §63a AsylG"
replace residence_status = "Temporary protection under Section 24 Residence Act (AufenthG)" if residence_status == "6: §24 AufenthG"
replace residence_status = "Residence permit under Section 25 Residence Act (AufenthG)" if residence_status == "7: §25 AufenthG"
replace residence_status = "Temporary suspension of deportation (Duldung)" if residence_status == "9: Duldung"
replace residence_status = "Other residence status" if residence_status == "13: anderer Aufenthaltsstatus"

* Gender
replace gender = "Female" if inlist(gender, "0: Female", "0: Weiblich", "Weiblich")
replace gender = "Male" if inlist(gender, "1: Male", "1: Männlich", "Männlich")
replace gender = "Divers" if gender == "2: Divers"
replace gender = "Not identifiable" if inlist(gender, ///
    "3: Not identifiable", "3: nicht bestimmbar", "Nicht bestimmbar")

* Binary and person-related variables
replace referral_provided = "No"  if referral_provided == "0: Nein"
replace referral_provided = "Yes" if referral_provided == "1: Ja"

replace anonymous_case = "No"  if anonymous_case == "0: Nein"
replace anonymous_case = "Yes" if anonymous_case == "1: Ja"

replace third_party_affected = "No" if third_party_affected == "0: Nein"
replace third_party_affected = "Yes - male" if third_party_affected == "1: Ja, männlich"
replace third_party_affected = "Yes - female" if third_party_affected == "2: Ja, weiblich"
replace third_party_affected = "Yes - not identifiable" if third_party_affected == "4: Ja, nicht bestimmbar"
replace third_party_affected = "Not identifiable" if third_party_affected == "5: Nicht bestimmbar"

*============================================================*
* 4. Clean and code counselling topics
*============================================================*

capture drop topics_clean topic_code topic_main topic_main_text

gen strL topics_clean = consultation_topics
replace topics_clean = trim(topics_clean)
replace topics_clean = itrim(topics_clean)
replace topics_clean = lower(topics_clean)

gen topic_code = regexs(1) if regexm(topics_clean, "^([0-9]+\.[0-9]+)")
gen topic_main = real(substr(topic_code, 1, strpos(topic_code, ".") - 1))

label define topic_main_lbl ///
    1  "Recognition of qualifications / equivalence of degrees" ///
    6  "Employment contract / collective agreement" ///
    8  "Termination of employment relationships" ///
    12 "Supplementary social benefits and social assistance" ///
    13 "Information about SGB II" ///
    17 "Mini-job / part-time / full-time employment" ///
    18 "Illegal employment" ///
    20 "Other: tax documents/ advisory services" ///
    21 "Access to labor market and vocational training" ///
    24 "Residence law issues for non-EU citizens" ///
    45 "Career orientation: internships / training / studies" ///
    46 "Language support", replace

label values topic_main topic_main_lbl
decode topic_main, gen(topic_main_text)

label variable topics_clean    "Cleaned counselling topic text"
label variable topic_code      "Detailed topic code"
label variable topic_main      "Main counselling topic code"
label variable topic_main_text "Main counselling topic label"

*============================================================*
* 5. Save clean base dataset
*============================================================*

compress
save "$clean_file", replace

display "------------------------------------------------------------"
display "Import and cleaning completed."
display "Saved: $clean_file"
display "------------------------------------------------------------"
