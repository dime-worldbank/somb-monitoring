/******************************************************************
 04_graphs.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Create weekly monitoring graphs for cases, Lateris use,
          timing, quality, language composition, AI use, referral
          and anonymous cases

 Notes:
 - This file creates graphs only.
 - Excel tables are created in 03_weekly_tables.do.
******************************************************************/

clear
set more off

/******************************************************************
 0. Graph settings and files
******************************************************************/

capture set scheme modern

global export_w 3000
global export_h 1800

global title_size "medium"
global subtitle_size "small"
global axis_title_size "small"
global axis_label_size "small"
global legend_size "small"

global title_style ///
    size($title_size) ///
    color(black)

global graph_style ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    bgcolor(white)

global col_total     "eltblue"
global col_lateris   "eltblue"
global col_nolateris "sand"
global col_mean      "eltblue"
global col_median    "sand"
global col_yes       "eltblue"
global col_no        "sand"

global indicator_file "$processed_path/SoMB_WB_monitoring_indicators.dta"

capture mkdir "$graph_path"

/******************************************************************
 1. Load indicator dataset
******************************************************************/

use "$indicator_file", clear

capture drop case_counter
gen case_counter = 1

label define lateris_status_lbl 0 "No Lateris" 1 "Lateris", replace
capture label values lateris_yes lateris_status_lbl

/******************************************************************
 2. Weekly case volume
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter, ///
    by(project_week project_week_start)

sort project_week

twoway ///
    (line total_cases project_week, lwidth(medthick)) ///
    (scatter total_cases project_week, ///
        mlabel(total_cases) mlabposition(12) mlabsize(small)), ///
    title("Weekly Case Volume", $title_style) ///
    subtitle("Total cases per project week") ///
    xtitle("Project week") ///
    ytitle("Number of cases") ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/01_weekly_case_volume.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 3. Weekly Lateris share
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week project_week_start)

replace share_lateris = share_lateris * 100
sort project_week

twoway ///
    (line share_lateris project_week, lwidth(medthick)) ///
    (scatter share_lateris project_week, ///
        mlabel(lateris_cases) mlabposition(12) mlabsize(small)), ///
    title("Weekly Lateris Use", $title_style) ///
    subtitle("Share of cases with Lateris used; labels show Lateris case counts") ///
    xtitle("Project week") ///
    ytitle("Lateris used (%)") ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    xlabel(, labsize(small)) ///
    $graph_style

graph export "$graph_path/02_weekly_lateris_share.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 4. Weekly consultation duration: 5-minute bins
******************************************************************/

preserve

keep if !missing(consultation_duration_min)

gen consultation_duration_bin5 = floor(consultation_duration_min / 5) * 5

collapse ///
    (sum) cases = case_counter, ///
    by(project_week consultation_duration_bin5)

sort project_week consultation_duration_bin5

graph bar cases, ///
    over(consultation_duration_bin5, label(labsize(vsmall) angle(45))) ///
    by(project_week, ///
        title("Weekly Consultation Duration") ///
        note("Duration bins are 5 minutes")) ///
    ytitle("Number of cases") ///
    $graph_style

graph export "$graph_path/03a_weekly_consultation_duration_bins.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 4b. Weekly average consultation duration by Lateris status
******************************************************************/

preserve

keep if !missing(consultation_duration_min) & !missing(lateris_yes)

collapse ///
    (mean) avg_consultation_duration = consultation_duration_min, ///
    by(project_week project_week_start lateris_yes)

sort project_week lateris_yes

twoway ///
    (line avg_consultation_duration project_week if lateris_yes == 1, ///
        lwidth(medthick)) ///
    (scatter avg_consultation_duration project_week if lateris_yes == 1) ///
    (line avg_consultation_duration project_week if lateris_yes == 0, ///
        lwidth(medthick)) ///
    (scatter avg_consultation_duration project_week if lateris_yes == 0), ///
    title("Weekly Average Consultation Duration", $title_style) ///
    subtitle("Separated by Lateris and no Lateris") ///
    xtitle("Project week") ///
    ytitle("Average consultation duration, minutes") ///
    legend(order(1 "Lateris" 3 "No Lateris") pos(6) rows(1) size(small)) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/03b_weekly_avg_consultation_duration_by_lateris.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 5. Weekly form duration: 5-minute bins
******************************************************************/

preserve

keep if !missing(form_duration_min)

gen form_duration_bin5 = floor(form_duration_min / 5) * 5

collapse ///
    (sum) cases = case_counter, ///
    by(project_week form_duration_bin5)

sort project_week form_duration_bin5

graph bar cases, ///
    over(form_duration_bin5, label(labsize(vsmall) angle(45))) ///
    by(project_week, ///
        title("Weekly Form Duration") ///
        note("Duration bins are 5 minutes")) ///
    ytitle("Number of cases") ///
    $graph_style

graph export "$graph_path/03c_weekly_form_duration_bins.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 6. Weekly consultation duration: mean and median
******************************************************************/

preserve

keep if !missing(consultation_duration_min)

collapse ///
    (mean) avg_consultation_duration = consultation_duration_min ///
    (median) med_consultation_duration = consultation_duration_min, ///
    by(project_week project_week_start)

sort project_week

twoway ///
    (line avg_consultation_duration project_week, lwidth(medthick)) ///
    (scatter avg_consultation_duration project_week) ///
    (line med_consultation_duration project_week, ///
        lpattern(dash) lwidth(medthick)), ///
    title("Weekly Consultation Duration", $title_style) ///
    subtitle("Mean and median minutes") ///
    xtitle("Project week") ///
    ytitle("Minutes") ///
    legend(order(1 "Mean" 3 "Median") pos(6) rows(1) size(small)) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/03d_weekly_consultation_duration_mean_median.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 7. Weekly form duration: mean and median
******************************************************************/

preserve

keep if !missing(form_duration_min)

collapse ///
    (mean) avg_form_duration = form_duration_min ///
    (median) med_form_duration = form_duration_min, ///
    by(project_week project_week_start)

sort project_week

twoway ///
    (line avg_form_duration project_week, lwidth(medthick)) ///
    (scatter avg_form_duration project_week) ///
    (line med_form_duration project_week, ///
        lpattern(dash) lwidth(medthick)), ///
    title("Weekly Form Duration", $title_style) ///
    subtitle("Mean and median minutes") ///
    xtitle("Project week") ///
    ytitle("Minutes") ///
    legend(order(1 "Mean" 3 "Median") pos(6) rows(1) size(small)) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/03e_weekly_form_duration_mean_median.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 8. Weekly quality ratings, compiled by dimension
******************************************************************/

preserve

collapse ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness, ///
    by(project_week project_week_start)

sort project_week

foreach q in accuracy clarity appropriateness speed completeness {

    local title = proper("`q'")

    twoway ///
        (line avg_`q' project_week, lwidth(medthick)) ///
        (scatter avg_`q' project_week), ///
        title("`title'", $title_style) ///
        xtitle("Project week") ///
        ytitle("Rating") ///
        ylabel(1(1)5, labsize(small) nogrid) ///
        xlabel(, labsize(small)) ///
        $graph_style ///
        name(q_`q', replace)
}

graph combine q_accuracy q_clarity q_appropriateness q_speed q_completeness, ///
    title("Weekly Quality Ratings") ///
    subtitle("Separate dimensions; scale 1-5") ///
    graphregion(color(white))

graph export "$graph_path/04_weekly_quality_ratings_compiled.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 9. Cases by language - overall
******************************************************************/

preserve

keep if !missing(language) & trim(language) != ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(language)

graph hbar total_cases, ///
    over(language, sort(1) descending label(labsize(small))) ///
    title("Cases by Language", $title_style) ///
    subtitle("All project weeks combined") ///
    ytitle("Number of cases") ///
    blabel(bar, format(%9.0f) size(vsmall)) ///
    $graph_style

graph export "$graph_path/05a_cases_by_language_overall.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 10. Cases by language and week - stacked
******************************************************************/

preserve

keep if !missing(language) & trim(language) != ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(project_week language)

sort project_week language

graph bar total_cases, ///
    over(language, label(labsize(vsmall) angle(45))) ///
    over(project_week, label(labsize(small))) ///
    asyvars stack ///
    title("Cases by Language and Week", $title_style) ///
    subtitle("Weekly language composition") ///
    ytitle("Number of cases") ///
    legend(pos(6) rows(2) size(vsmall)) ///
    $graph_style

graph export "$graph_path/05b_cases_by_language_week.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 11. Cases by language - one box per week
******************************************************************/

preserve

keep if !missing(language) & trim(language) != ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(project_week language)

drop if project_week < 0

levelsof project_week, local(weeks)

local graphlist ""

foreach w of local weeks {

    local cleanw = subinstr("`w'", "-", "m", .)

    graph hbar total_cases if project_week == `w', ///
        over(language, sort(1) descending label(labsize(vsmall))) ///
        title("Week `w'") ///
        ytitle("Cases") ///
        blabel(bar, format(%9.0f) size(small)) ///
        ylabel(0(5)30, labsize(small) nogrid) ///
        $graph_style ///
        name(lang_week_`cleanw', replace)

    local graphlist "`graphlist' lang_week_`cleanw'"
}

graph combine `graphlist', ///
    title("Cases by Language and Week") ///
    subtitle("Separate panel for each project week") ///
    graphregion(color(white)) ///
    rows(2)

graph export "$graph_path/06_cases_by_language_weekly_boxes.png", ///
    replace width(3200) height(2200)

restore

/******************************************************************
 12. Weekly Lateris use by language
******************************************************************/

preserve

keep if !missing(language) & trim(language) != "" & !missing(lateris_yes)

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week language)

replace share_lateris = share_lateris * 100

sort project_week language

graph bar share_lateris, ///
    over(language, label(labsize(vsmall) angle(45))) ///
    by(project_week, ///
        title("Weekly Lateris Use by Language") ///
        note("Bars show percentage of cases with Lateris used")) ///
    ytitle("Lateris used (%)") ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    blabel(bar, format(%9.1f) size(vsmall)) ///
    $graph_style

graph export "$graph_path/07_weekly_lateris_by_language.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 13. Lateris use by language - overall
******************************************************************/

preserve

keep if !missing(language) & trim(language) != "" & !missing(lateris_yes)

collapse ///
    (mean) share_lateris = lateris_yes, ///
    by(language)

replace share_lateris = share_lateris * 100

graph hbar share_lateris, ///
    over(language, sort(1) descending label(labsize(small))) ///
    title("Lateris Use by Language", $title_style) ///
    subtitle("Overall share across all project weeks") ///
    ytitle("Lateris used (%)") ///
    blabel(bar, format(%9.1f) size(vsmall)) ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/08_lateris_use_by_language.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 14. AI tools used - overall
******************************************************************/

preserve

keep if !missing(ai_tool_used) & trim(ai_tool_used) != ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(ai_tool_used)

graph hbar total_cases, ///
    over(ai_tool_used, sort(1) descending label(labsize(vsmall))) ///
    title("AI Tools Used", $title_style) ///
    subtitle("All cases combined") ///
    ytitle("Number of cases") ///
    blabel(bar, format(%9.0f) size(vsmall)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/09_ai_tools_used_overall.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 15. AI tools used by Lateris status
******************************************************************/

preserve

keep if !missing(ai_tool_used) & trim(ai_tool_used) != "" & !missing(lateris_yes)

collapse ///
    (sum) total_cases = case_counter, ///
    by(lateris_yes ai_tool_used)

label values lateris_yes lateris_status_lbl

graph hbar total_cases, ///
    over(ai_tool_used, sort(1) descending label(labsize(vsmall))) ///
    over(lateris_yes, label(labsize(small))) ///
    title("AI Tools Used by Lateris Status", $title_style) ///
    subtitle("Lateris vs. no Lateris") ///
    ytitle("Number of cases") ///
    blabel(bar, format(%9.0f) size(vsmall)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/10_ai_tools_used_by_lateris.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 16. AI usage reasons by Lateris status
******************************************************************/

preserve

keep if !missing(ai_usage_reason) & trim(ai_usage_reason) != "" & !missing(lateris_yes)

collapse ///
    (sum) total_cases = case_counter, ///
    by(lateris_yes ai_usage_reason)

label values lateris_yes lateris_status_lbl

graph hbar total_cases, ///
    over(ai_usage_reason, sort(1) descending label(labsize(vsmall))) ///
    over(lateris_yes, label(labsize(small))) ///
    title("Reasons for AI Tool Use", $title_style) ///
    subtitle("By Lateris status") ///
    ytitle("Number of cases") ///
    blabel(bar, format(%9.0f) size(vsmall)) ///
    ylabel(, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/11_ai_usage_reasons_by_lateris.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 17. Referral provided by Lateris status
******************************************************************/

preserve

keep if !missing(referral_yes) & !missing(lateris_yes)

collapse ///
    (mean) share_referral = referral_yes, ///
    by(lateris_yes)

replace share_referral = share_referral * 100

label values lateris_yes lateris_status_lbl

graph bar share_referral, ///
    over(lateris_yes, label(labsize(small))) ///
    title("Referral Provided", $title_style) ///
    subtitle("Share of cases by Lateris status") ///
    ytitle("Referral provided (%)") ///
    blabel(bar, format(%9.1f) size(small)) ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/12_referral_provided_by_lateris.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 18. Referral provided - overall
******************************************************************/

preserve

keep if !missing(referral_yes)

collapse ///
    (mean) share_referral = referral_yes

replace share_referral = share_referral * 100

gen category = "All cases"

graph bar share_referral, ///
    over(category, label(labsize(small))) ///
    title("Referral Provided", $title_style) ///
    subtitle("Overall share across all cases") ///
    ytitle("Referral provided (%)") ///
    blabel(bar, format(%9.1f) size(small)) ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/13_referral_provided_overall.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 19. Anonymous cases - overall
******************************************************************/

preserve

keep if !missing(anonymous_yes)

collapse ///
    (mean) share_anonymous = anonymous_yes

replace share_anonymous = share_anonymous * 100

gen category = "All cases"

graph bar share_anonymous, ///
    over(category, label(labsize(small))) ///
    title("Anonymous Cases", $title_style) ///
    subtitle("Overall share across all cases") ///
    ytitle("Anonymous cases (%)") ///
    blabel(bar, format(%9.1f) size(small)) ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/14_anonymous_cases_overall.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 20. Anonymous cases by Lateris status
******************************************************************/

preserve

keep if !missing(anonymous_yes) & !missing(lateris_yes)

collapse ///
    (mean) share_anonymous = anonymous_yes, ///
    by(lateris_yes)

replace share_anonymous = share_anonymous * 100

label values lateris_yes lateris_status_lbl

graph bar share_anonymous, ///
    over(lateris_yes, label(labsize(small))) ///
    title("Anonymous Cases", $title_style) ///
    subtitle("Share of cases by Lateris status") ///
    ytitle("Anonymous cases (%)") ///
    blabel(bar, format(%9.1f) size(small)) ///
    ylabel(0(20)100, labsize(small) nogrid) ///
    $graph_style

graph export "$graph_path/15_anonymous_cases_by_lateris.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 21. Save graph-ready dataset
******************************************************************/

save "$indicator_file", replace
