/******************************************************************
 05_stakeholder_graphs.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Create stakeholder-facing monitoring graphs for weeks 1-7

 Notes:
 - This file creates presentation-ready graphs for the stakeholder deck ( biweekly meeting) .
 - It uses the indicator dataset created in 02_create_indicators.do.
 - It only keeps project weeks 1 to 7.
 - Days with known technical/data collection issues are excluded.
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
    plotregion(color(white) lcolor(none)) ///
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
 1. Load indicator dataset and keep stakeholder period
******************************************************************/

use "$indicator_file", clear

capture drop case_counter
gen case_counter = 1

keep if inrange(project_week, 1, 7)

drop if inlist(created_date, ///
    td(08may2026), ///
    td(13may2026), ///
    td(27may2026))

label define lateris_status_lbl 0 "No Lateris" 1 "Lateris", replace
capture label values lateris_yes lateris_status_lbl

/******************************************************************
 2. Weekly case volume and Lateris use
******************************************************************/

preserve

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes, ///
    by(project_week)

sort project_week

twoway ///
    (line total_cases project_week, ///
        lcolor($col_total) ///
        lwidth(medthick)) ///
    (scatter total_cases project_week, ///
        mcolor($col_total) ///
        msymbol(circle) ///
        msize(medium) ///
        mlabel(total_cases) ///
        mlabposition(12) ///
        mlabsize(small) ///
        mlabcolor(black)) ///
    (line lateris_cases project_week, ///
        lcolor($col_nolateris) ///
        lwidth(medthick)) ///
    (scatter lateris_cases project_week, ///
        mcolor($col_nolateris) ///
        msymbol(circle) ///
        msize(medium) ///
        mlabel(lateris_cases) ///
        mlabposition(6) ///
        mlabsize(small) ///
        mlabcolor(black)), ///
    title("Weekly Case Volume and Lateris Use", $title_style) ///
    xtitle("Project week", size($axis_title_size)) ///
    ytitle("Number of cases", size($axis_title_size)) ///
    xlabel(1(1)7, labsize($axis_label_size) nogrid) ///
    ylabel(0(20)100, labsize($axis_label_size) nogrid) ///
    yscale(range(0 100)) ///
    legend( ///
        order(1 "Total cases" 3 "Lateris cases") ///
        pos(6) ///
        rows(1) ///
        size($legend_size) ///
        region(lcolor(none))) ///
    $graph_style

graph export "$graph_path/stakeholder_01_weekly_case_volume_and_lateris_use.svg", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 3. Weekly Lateris use by language
******************************************************************/

preserve

drop if inlist(language, ///
    "German", "Deutsch", ///
    "Vietnamese", "Vietnamesisch", "21: Vietnamesisch")

keep if !missing(language) & trim(language) != ""
keep if !missing(lateris_yes)

collapse ///
    (sum) total_cases = case_counter ///
    (sum) lateris_cases = lateris_yes ///
    (mean) share_lateris = lateris_yes, ///
    by(project_week language)

replace share_lateris = share_lateris * 100

graph bar share_lateris, ///
    over(language, sort(1) descending label(labsize(vsmall) angle(45))) ///
    by(project_week, ///
        rows(2) ///
        title("Lateris Adherence by Language and Project Week", $title_style) ///
        note("")) ///
    ytitle("Lateris used (%)", size($axis_title_size)) ///
    ylabel(0 50 100, labsize($axis_label_size) nogrid) ///
    yscale(range(0 100)) ///
    blabel(bar, format(%9.0f) size(vsmall) color(black)) ///
    bar(1, color($col_lateris)) ///
    $graph_style

graph export "$graph_path/stakeholder_02_weekly_lateris_use_by_language_panels.svg", ///
    replace width(3600) height(2200)

restore

/******************************************************************
 4. Cases by language, all stakeholder weeks combined
******************************************************************/

preserve

drop if inlist(language, ///
    "Vietnamese", "Vietnamesisch", "21: Vietnamesisch")

keep if !missing(language) & trim(language) != ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(language)

graph hbar total_cases, ///
    over(language, sort(1) descending label(labsize($axis_label_size))) ///
    bar(1, color($col_total)) ///
    title("Cases by Language", $title_style) ///
    ytitle("Number of cases", size($axis_title_size)) ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    blabel(bar, format(%9.0f) size(vsmall) color(black)) ///
    $graph_style

graph export "$graph_path/stakeholder_03_cases_by_language_combined.svg", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 5. Weekly quality ratings: mean + n
******************************************************************/

preserve

collapse ///
    (mean) avg_accuracy = accuracy ///
    (mean) avg_clarity = clarity ///
    (mean) avg_appropriateness = appropriateness ///
    (mean) avg_speed = speed ///
    (mean) avg_completeness = completeness ///
    (count) n_accuracy = accuracy ///
    (count) n_clarity = clarity ///
    (count) n_appropriateness = appropriateness ///
    (count) n_speed = speed ///
    (count) n_completeness = completeness, ///
    by(project_week)

sort project_week

foreach q in accuracy clarity appropriateness speed completeness {

    local panel_title = proper("`q'")
    if "`q'" == "appropriateness" local panel_title "Appropriateness"

    twoway ///
        (line avg_`q' project_week, ///
            lcolor($col_lateris) ///
            lwidth(medthick)) ///
        (scatter avg_`q' project_week, ///
            mcolor($col_lateris) ///
            mlabel(n_`q') ///
            mlabposition(12) ///
            mlabsize(vsmall) ///
            mlabcolor(black)), ///
        title("`panel_title'", size(small) color(black)) ///
        xtitle("Project week", size(vsmall)) ///
        ytitle("") ///
        xlabel(1(1)7, labsize(vsmall) nogrid) ///
        ylabel(1 "Excellent" 2 "Good" 3 "Adequate" 4 "Poor" 5 "Very poor", ///
            angle(0) labsize(vsmall) nogrid) ///
        yscale(reverse range(0.8 5.2)) ///
        legend(off) ///
        $graph_style ///
        name(q_`q', replace)
}

graph combine ///
    q_accuracy q_clarity q_appropriateness q_speed q_completeness, ///
    rows(2) ///
    title("Weekly Quality Ratings", $title_style) ///
    subtitle("Mean ratings by dimension; point labels show n", size($subtitle_size)) ///
    graphregion(color(white))

graph export "$graph_path/stakeholder_04_weekly_quality_ratings_separate_panels.png", ///
    replace width(3600) height(2200)

restore

/******************************************************************
 6. Weekly consultation duration: mean + median + n
******************************************************************/

preserve

keep if !missing(consultation_duration_min)

collapse ///
    (mean) mean_duration = consultation_duration_min ///
    (median) median_duration = consultation_duration_min ///
    (count) n_duration = consultation_duration_min, ///
    by(project_week)

sort project_week

twoway ///
    (line mean_duration project_week, ///
        lcolor($col_mean) ///
        lwidth(medthick)) ///
    (scatter mean_duration project_week, ///
        mcolor($col_mean) ///
        mlabel(n_duration) ///
        mlabposition(12) ///
        mlabsize(vsmall) ///
        mlabcolor(black)) ///
    (line median_duration project_week, ///
        lcolor($col_median) ///
        lpattern(dash) ///
        lwidth(medthick)) ///
    (scatter median_duration project_week, ///
        mcolor($col_median)), ///
    title("Weekly Consultation Duration", $title_style) ///
    subtitle("Mean and median minutes; point labels show n", size($subtitle_size)) ///
    xtitle("Project week", size($axis_title_size)) ///
    ytitle("Minutes", size($axis_title_size)) ///
    xlabel(1(1)7, labsize($axis_label_size)) ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    legend(order(1 "Mean" 3 "Median") pos(6) rows(1) size($legend_size)) ///
    $graph_style

graph export "$graph_path/stakeholder_05_weekly_consultation_duration_mean_median_n.svg", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 7. Weekly form duration: mean + median + n
******************************************************************/

preserve

keep if !missing(form_duration_min)

collapse ///
    (mean) mean_form_duration = form_duration_min ///
    (median) median_form_duration = form_duration_min ///
    (count) n_form_duration = form_duration_min, ///
    by(project_week)

sort project_week

twoway ///
    (line mean_form_duration project_week, ///
        lcolor($col_mean) ///
        lwidth(medthick)) ///
    (scatter mean_form_duration project_week, ///
        mcolor($col_mean) ///
        mlabel(n_form_duration) ///
        mlabposition(12) ///
        mlabsize(vsmall) ///
        mlabcolor(black)) ///
    (line median_form_duration project_week, ///
        lcolor($col_median) ///
        lpattern(dash) ///
        lwidth(medthick)) ///
    (scatter median_form_duration project_week, ///
        mcolor($col_median)), ///
    title("Weekly Form Duration", $title_style) ///
    subtitle("Mean and median minutes; point labels show n", size($subtitle_size)) ///
    xtitle("Project week", size($axis_title_size)) ///
    ytitle("Minutes", size($axis_title_size)) ///
    xlabel(1(1)7, labsize($axis_label_size)) ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    legend(order(1 "Mean" 3 "Median") pos(6) rows(1) size($legend_size)) ///
    $graph_style

graph export "$graph_path/stakeholder_06_weekly_form_duration_mean_median_n.png", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 8. Other AI tool used by Lateris status
******************************************************************/

preserve

keep if !missing(other_ai_tool_used) & trim(other_ai_tool_used) != ""
keep if !missing(lateris_yes)

contract lateris_yes other_ai_tool_used, freq(n_cases)

bysort lateris_yes: egen total_group = total(n_cases)
gen share = n_cases / total_group * 100

label define lateris_week_lbl 0 "No Lateris" 1 "Lateris", replace
label values lateris_yes lateris_week_lbl

graph bar share, ///
    over(other_ai_tool_used, label(labsize($axis_label_size))) ///
    over(lateris_yes, label(labsize($axis_label_size))) ///
    asyvars ///
    bar(1, color($col_yes)) ///
    bar(2, color($col_no)) ///
    title("Use of Other AI Tools", $title_style) ///
    ytitle("Share of cases (%)", size($axis_title_size)) ///
    ylabel(0 50 100, labsize($axis_label_size) nogrid) ///
    yscale(range(0 100)) ///
    blabel(bar, format(%9.0f) size(small) color(black)) ///
    legend(order(1 "Yes" 2 "No") ///
        pos(6) rows(1) size($legend_size) region(lcolor(none))) ///
    $graph_style

graph export "$graph_path/stakeholder_07a_other_ai_used_by_lateris_status.svg", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 9. Reasons for AI tool use by Lateris status
******************************************************************/

preserve

keep if !missing(ai_usage_reason) & trim(ai_usage_reason) != ""
keep if !missing(lateris_yes)

* Split multiple-response categories into separate reasons.
split ai_usage_reason, parse(" + ") gen(reason_)

reshape long reason_, i(case_id) j(reason_number)

drop if missing(reason_)
replace reason_ = strtrim(reason_)
drop if reason_ == ""

collapse ///
    (sum) total_cases = case_counter, ///
    by(lateris_yes reason_)

label define lateris_reason_lbl 0 "No Lateris" 1 "Lateris", replace
label values lateris_yes lateris_reason_lbl

graph hbar total_cases, ///
    over(reason_, sort(1) descending label(labsize(small))) ///
    by(lateris_yes, ///
        cols(1) ///
        note("") ///
        graphregion(color(white)) ///
        title("Reasons for AI Tool Use", $title_style)) ///
    bar(1, color($col_lateris)) ///
    ytitle("Number of mentions", size($axis_title_size)) ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    $graph_style

graph export "$graph_path/stakeholder_07b_ai_usage_reasons_by_lateris_status.svg", ///
    replace width($export_w) height($export_h)

restore

/******************************************************************
 10. Save stakeholder graph-ready dataset
******************************************************************/

save "$indicator_file", replace
