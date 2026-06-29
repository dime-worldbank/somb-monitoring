/********************************************************************
Project: SoMB / WB Vtiger Data
File:    02_prepare_analysis.do

Purpose:
    Create analysis-ready variables from the clean base dataset.
    This includes indicators, grouped variables, channel clusters,
    selected language flags, topic clusters, and text-based theme flags.

Inputs:
    $processed_path/SoMB_clean_base.dta

Outputs:
    $processed_path/SoMB_analysis.dta


********************************************************************/

version 18
clear all
set more off

*============================================================*
* 0. Project paths
*============================================================*

capture confirm global processed_path
if _rc global processed_path "../02_data/processed"

capture mkdir "$processed_path"

global clean_file    "$processed_path/SoMB_clean_base.dta"
global analysis_file "$processed_path/SoMB_analysis.dta"

capture confirm file "$clean_file"
if _rc {
    display as error "Input file not found: $clean_file"
    display as error "Run 01_import_clean.do first."
    exit 601
}

use "$clean_file", clear

*============================================================*
* 1. Basic indicators
*============================================================*

capture drop one_case anonymous_yes referral_yes selected_language

gen byte one_case = 1
label variable one_case "Case counter"

gen byte anonymous_yes = .
replace anonymous_yes = 1 if inlist(anonymous_case, "Yes", "Ja", "yes", "YES")
replace anonymous_yes = 0 if inlist(anonymous_case, "No", "Nein", "no", "NO")
label variable anonymous_yes "Anonymous case dummy"

gen byte referral_yes = .
replace referral_yes = 1 if inlist(referral_provided, "Yes", "Ja", "yes", "YES")
replace referral_yes = 0 if inlist(referral_provided, "No", "Nein", "no", "NO")
label variable referral_yes "Referral provided dummy"

gen byte selected_language = inlist(language, ///
    "Arabic", "Persian", "Russian", "Turkish", "Ukrainian", "French")
label variable selected_language "Selected language group for main analysis"

*============================================================*
* 2. Group selected employment-related counselling topics
*============================================================*

capture drop topic21_group

gen topic21_group = .
replace topic21_group = 1 if regexm(topics_clean, "21.03|21.02|21.07")
replace topic21_group = 2 if regexm(topics_clean, "21.01|21.11")
replace topic21_group = 3 if regexm(topics_clean, "21.08|21.09|21.10|21.16")
replace topic21_group = 4 if regexm(topics_clean, "45.02|45.03|45.04")
replace topic21_group = 5 if regexm(topics_clean, "46.")
replace topic21_group = 6 if regexm(topics_clean, "27.06")
replace topic21_group = 7 if regexm(topics_clean, "20.03|beratung")
replace topic21_group = 8 if regexm(topics_clean, "23.05|47.")
replace topic21_group = 9 if missing(topic21_group)

label define topic21grp ///
    1 "Job search" ///
    2 "Labour market access/info" ///
    3 "Training & qualification" ///
    4 "Education & apprenticeship" ///
    5 "Language/integration support" ///
    6 "Housing-related barriers" ///
    7 "Counselling/admin support" ///
    8 "Discrimination/vulnerability" ///
    9 "Other", replace

label values topic21_group topic21grp
label variable topic21_group "Grouped employment-related counselling topic"

*============================================================*
* 3. Broader topic and channel groups
*============================================================*

capture drop topic_cluster channel_group

gen str40 topic_cluster = ""
replace topic_cluster = "Residence & Legal Status" if topic_main == 24
replace topic_cluster = "Employment & Labour Rights" if inlist(topic_main, 6, 8, 17, 18, 21)
replace topic_cluster = "Social Benefits" if inlist(topic_main, 12, 13)
replace topic_cluster = "Education & Qualification" if inlist(topic_main, 1, 45)
replace topic_cluster = "Language & Integration" if topic_main == 46
replace topic_cluster = "Other" if missing(topic_cluster) | topic_cluster == ""
label variable topic_cluster "Broad counselling topic cluster"

gen str20 channel_group = ""
replace channel_group = "Facebook" if strpos(channel, "Facebook") > 0
replace channel_group = "Telegram" if strpos(channel, "Telegram") > 0
replace channel_group = "TikTok" if strpos(channel, "TikTok") > 0
replace channel_group = "WhatsApp" if strpos(channel, "WhatsApp") > 0
replace channel_group = "Email" if channel == "Email"
replace channel_group = "Other" if missing(channel_group) | channel_group == ""
label variable channel_group "Grouped communication channel"

*============================================================*
* 4. Text-based issue indicators for community deep dives
*============================================================*

capture drop text_l job_search minijob language_course b2_course recognition ///
    jobcenter paragraph24 legal_problem no_german housing_job care_work ///
    cleaning_hotel education_kita ausbildung construction driver ///
    warehouse_factory kitchen_cleaning documents

gen strL text_l = ustrlower(original_text)
label variable text_l "Lower-case original text"

gen byte job_search = ustrregexm(text_l, ///
    "шукаю роботу|ищу работу|праця|роботу|ваканс|بحث عن عمل|ابحث عن عمل|شغل|وظيفة|عمل")

gen byte minijob = ustrregexm(text_l, ///
    "minijob|міні.?джоб|мини.?джоб|підробіт|ميني جوب|عمل جزئي")

gen byte language_course = ustrregexm(text_l, ///
    "курс|курси|sprachkurs|інтеграційн|b1|b2|с1|c1|a1|a2|لغة|دورة لغة|كورس")

gen byte b2_course = ustrregexm(text_l, ///
    "b2|в2|б2|beruf|беруф")

gen byte recognition = ustrregexm(text_l, ///
    "диплом|anerkennung|zab|анеркен|визнан|підтвердж|شهادة|اعتراف|معادلة")

gen byte jobcenter = ustrregexm(text_l, ///
    "джобцентр|jobcenter|arbeitsagentur|agentur|جوب سنتر|مكتب العمل")

gen byte paragraph24 = ustrregexm(text_l, ///
    "24|§24|параграф|فقرة")

gen byte legal_problem = ustrregexm(text_l, ///
    "звільн|зарплат|не виплат|адвокат|суд|скарг|kündigung|محامي|راتب|فصل|شكوى|محكمة")

gen byte no_german = ustrregexm(text_l, ///
    "без знання мови|немає мови|не володію|a1|a2|початкова|لا اتكلم الالمانية|بدون لغة|لا أعرف اللغة")

gen byte housing_job = ustrregexm(text_l, ///
    "з житлом|с проживанием|проживанням|житло|سكن|مع السكن")

gen byte care_work = ustrregexm(text_l, ///
    "pflege|флеге|догляд|опікун|сидел|альтен|رعاية|تمريض")

gen byte cleaning_hotel = ustrregexm(text_l, ///
    "прибиран|уборк|hotel|готел|housekeeping|покоїв|تنظيف|فندق|هاوسكيبنج")

gen byte education_kita = ustrregexm(text_l, ///
    "kita|садк|вихователь|erzieher|вчител|lehrer|школ|روضة|مدرسة|معلم")

gen byte ausbildung = ustrregexm(text_l, ///
    "ausbildung|аусбілд|умшул|umschulung|تدريب مهني|اوسبيلدونغ")

gen byte construction = ustrregexm(text_l, ///
    "будов|стройк|ремонт|електрик|зварюв|сантех|монтаж|بناء|دهان|كهرباء|حداد")

gen byte driver = ustrregexm(text_l, ///
    "воді|водит|кур.?єр|курьер|dhl|amazon|права|سائق|توصيل|رخصة")

gen byte warehouse_factory = ustrregexm(text_l, ///
    "склад|завод|фабрик|виробниц|пакув|سوبرمارкт|مخزن|مصنع|تغليف")

gen byte kitchen_cleaning = ustrregexm(text_l, ///
    "кухар|повар|кухн|кафе|готел|прибиран|مطعم|مطبخ|تنظيف")

gen byte documents = ustrregexm(text_l, ///
    "документ|дозвіл|fiktionsbescheinigung|ausweis|arbeitserlaubnis|контракт|وثيقة|اوراق|أوراق|اقامة|إقامة|تصريح|عقد")

label variable job_search        "Text flag: job search"
label variable minijob           "Text flag: minijob or side job"
label variable language_course   "Text flag: language course"
label variable b2_course         "Text flag: B2 or vocational language course"
label variable recognition       "Text flag: recognition of qualifications"
label variable jobcenter         "Text flag: Jobcenter or employment agency"
label variable paragraph24       "Text flag: Section 24"
label variable legal_problem     "Text flag: legal or employment dispute"
label variable no_german         "Text flag: limited German language"
label variable housing_job       "Text flag: housing and job"
label variable care_work         "Text flag: care work"
label variable cleaning_hotel    "Text flag: cleaning or hotel"
label variable education_kita    "Text flag: education, school, or kita"
label variable ausbildung        "Text flag: vocational training"
label variable construction      "Text flag: construction"
label variable driver            "Text flag: driver or courier"
label variable warehouse_factory "Text flag: warehouse or factory"
label variable kitchen_cleaning  "Text flag: kitchen or cleaning"
label variable documents         "Text flag: documents or work permit"

*============================================================*
* 5. Basic post-cleaning checks
*============================================================*

misstable summarize ///
    residence_status employment_status nationality gender language ///
    federal_state city channel anonymous_case consultation_type topic_main

*============================================================*
* 6. Save analysis dataset
*============================================================*

compress
save "$analysis_file", replace

display "------------------------------------------------------------"
display "Analysis preparation completed."
display "Saved: $analysis_file"
display "------------------------------------------------------------"
