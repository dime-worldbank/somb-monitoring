/*******************************************************************
Project: SoMB / WB Vtiger Data
File:    04_infographic_graphs.do

Purpose:
    Create harmonized visualizations for the SoMB counselling
    infographic. This file only produces graphs and does not create
    permanent analytical variables.

Inputs:
    $processed_path/SoMB_WB_infographic_analysis.dta

Outputs:
    $graph_path/.svg and selected *.png

Notes:
    - Run 03_infographic_clean_group.do before this file.
    - Designed to be run from 00_master.do.
    - Uses project-relative globals if they are already defined.
    - If run standalone, default relative folders are used.
    - Requires the user-written heatplot package for Graph 4.1.
      Install once with: ssc install heatplot, replace

*******************************************************************/

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

capture confirm global outputs_path
if _rc global outputs_path "../04_outputs"

capture confirm global graph_path
if _rc global graph_path "$outputs_path/graphs/infographic"

capture mkdir "$outputs_path"
capture mkdir "$outputs_path/graphs"
capture mkdir "$graph_path"

global infographic_file "$processed_path/SoMB_WB_infographic_analysis.dta"

capture confirm file "$infographic_file"
if _rc {
    display as error "Input file not found: $infographic_file"
    display as error "Run 03_infographic_clean_group.do first."
    exit 601
}

use "$infographic_file", clear

*============================================================*
* 1. Global graph settings
*============================================================*

capture set scheme modern

global export_w 3000
global export_h 1800

global title_size      "medium"
global axis_title_size "small"
global axis_label_size "small"
global legend_size     "small"

global title_style ///
    size($title_size) ///
    color(black)

global graph_style ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    bgcolor(white)

global blabel_count ///
    blabel(bar, size(vsmall) color(black) format(%9.0f))

global blabel_pct ///
    blabel(bar, size(vsmall) color(black) format(%4.0f))

* Muted graph palette.
global col_total      "eltblue"
global col_support    "gs12"
global col_arabic     "eltblue"
global col_persian    "forest_green"
global col_russian    "cranberry"
global col_turkish    "teal"
global col_ukrainian  "sand"
global col_french     "purple"
global col_female     "forest_green%55"
global col_male       "orange_red%45"

*============================================================*
* 2. How users access the service
*============================================================*

*------------------------------------------------------------*
* Graph 1.1: Cases by communication channel
*------------------------------------------------------------*

display "------------------------------------------------------------"
display "Graph 1.1: Cases by Communication Channel"
count if !missing(channel_group)
display "Sample used: " r(N)
count if missing(channel_group)
display "Missing channel group observations: " r(N)
display "------------------------------------------------------------"

graph hbar (count) if !missing(channel_group), ///
    over(channel_group, sort(1) descending label(labsize($axis_label_size))) ///
    title("Cases by Communication Channel", $title_style) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    bar(1, color($col_total%60)) ///
    $blabel_count ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    $graph_style

graph export "$graph_path/01_1_communication_channel.svg", ///
    replace width($export_w) height($export_h)

*------------------------------------------------------------*
* Graph 1.2: Referral provided
*------------------------------------------------------------*

preserve

keep if !missing(referral_provided)
contract referral_provided

display "------------------------------------------------------------"
display "Graph 1.2: Referral Provided"
summ _freq
display "Sample used: " r(sum)
display "------------------------------------------------------------"

graph pie _freq, ///
    over(referral_provided) ///
    plabel(_all percent, format(%4.1f) size(small) color(black)) ///
    title("Referral Provided", $title_style) ///
    legend(size($legend_size) position(6) rows(1)) ///
    pie(1, color($col_total%55)) ///
    pie(2, color($col_support)) ///
    $graph_style

graph export "$graph_path/01_2_referral_provided.svg", ///
    replace width($export_w) height($export_h)

restore

*------------------------------------------------------------*
* Graph 1.3: Monthly share of anonymous cases
*------------------------------------------------------------*

preserve

keep if !missing(created_month) & !missing(anonymous_yes)

display "------------------------------------------------------------"
display "Graph 1.3: Monthly Share of Anonymous Cases"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse ///
    (sum) total_cases = one_case ///
    (sum) anonymous_cases = anonymous_yes, ///
    by(created_month)

gen anonymous_share = anonymous_cases / total_cases * 100

format created_month %tmMon_CCYY
summ created_month, meanonly
local min_month = r(min)
local max_month = r(max)

twoway ///
    (area anonymous_share created_month, color($col_total%25)) ///
    (line anonymous_share created_month, lcolor($col_total%85) lwidth(medthick)), ///
    title("Monthly Share of Anonymous Cases", $title_style) ///
    xtitle("Month", size($axis_title_size)) ///
    ytitle("Anonymous Cases (%)", size($axis_title_size)) ///
    xlabel(`min_month'(1)`max_month', format(%tmMon_CCYY) angle(45) labsize($axis_label_size)) ///
    ylabel(0(10)100, labsize($axis_label_size) nogrid) ///
    yscale(range(0 100)) ///
    legend(off) ///
    $graph_style

graph export "$graph_path/01_3_anonymous_cases_over_time.svg", ///
    replace width($export_w) height($export_h)

restore

*============================================================*
* 4. Who uses the service
*============================================================*

*------------------------------------------------------------*
* Graph 2.1: Cases by language
*------------------------------------------------------------*

display "------------------------------------------------------------"
display "Graph 2.1: Cases by Language"
count if !missing(language)
display "Sample used: " r(N)
count if missing(language)
display "Missing language observations: " r(N)
display "------------------------------------------------------------"

graph hbar (count) if !missing(language), ///
    over(language, sort(1) descending label(labsize($axis_label_size))) ///
    title("Cases by Language", $title_style) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    bar(1, color($col_persian%75)) ///
    $blabel_count ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    $graph_style

graph export "$graph_path/02_1_language_distribution.svg", ///
    replace width($export_w) height($export_h)

*------------------------------------------------------------*
* Graph 2.2: Geographic concentration by language
*------------------------------------------------------------*

preserve

keep if federal_state != "Not identifiable" ///
    & !missing(federal_state) ///
    & !missing(language)

keep if inlist(language, ///
    "Arabic", "Persian", "Russian", "Turkish", "Ukrainian", "French")

display "------------------------------------------------------------"
display "Graph 2.2: Geographic Concentration by Language"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(federal_state language)

reshape wide n_cases, i(federal_state) j(language) string

foreach lang in Arabic Persian Russian Turkish Ukrainian French {
    capture gen n_cases`lang' = 0
    capture replace n_cases`lang' = 0 if missing(n_cases`lang')
}

gen total_cases = ///
    n_casesArabic + n_casesPersian + n_casesRussian + ///
    n_casesTurkish + n_casesUkrainian + n_casesFrench

gsort -total_cases
keep in 1/10

graph bar ///
    n_casesArabic ///
    n_casesPersian ///
    n_casesRussian ///
    n_casesTurkish ///
    n_casesUkrainian ///
    n_casesFrench, ///
    over(federal_state, sort(total_cases) descending ///
        label(angle(45) labsize(vsmall))) ///
    stack ///
    title("Geographic Concentration by Language", $title_style) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    ylabel(, labsize($axis_label_size) nogrid) ///
    legend(order(1 "Arabic" 2 "Persian" 3 "Russian" ///
                 4 "Turkish" 5 "Ukrainian" 6 "French") ///
        position(6) rows(2) size(vsmall)) ///
    bar(1, color($col_arabic%80)) ///
    bar(2, color($col_persian%80)) ///
    bar(3, color($col_russian%80)) ///
    bar(4, color($col_turkish%80)) ///
    bar(5, color($col_ukrainian%80)) ///
    bar(6, color($col_french%80)) ///
    $graph_style

graph export "$graph_path/02_2_geographic_concentration_by_language.svg", ///
    replace width($export_w) height($export_h)

restore

*------------------------------------------------------------*
* Graph 2.3: Residence status
*------------------------------------------------------------*

display "------------------------------------------------------------"
display "Graph 2.3: Residence Status"
count if residence_status != "Not identifiable" & !missing(residence_status)
display "Sample used: " r(N)
count if residence_status == "Not identifiable" | missing(residence_status)
display "Missing or not identifiable observations: " r(N)
display "------------------------------------------------------------"

graph hbar (percent) if residence_status != "Not identifiable" ///
    & !missing(residence_status), ///
    over(residence_status, sort(1) descending label(labsize($axis_label_size))) ///
    title("Residence Status", $title_style) ///
    ytitle("Share of Cases (%)", size($axis_title_size)) ///
    bar(1, color($col_total)) ///
    $blabel_pct ///
    ylabel(0(20)100, labsize($axis_label_size) nogrid) ///
    $graph_style

graph export "$graph_path/02_3_residence_status.svg", ///
    replace width($export_w) height($export_h)

*------------------------------------------------------------*
* Graph 2.4: Employment status
*------------------------------------------------------------*

display "------------------------------------------------------------"
display "Graph 2.4: Employment Status"
count if employment_status_fig != "Not identifiable" & !missing(employment_status_fig)
display "Sample used: " r(N)
count if employment_status_fig == "Not identifiable" | missing(employment_status_fig)
display "Missing or not identifiable observations: " r(N)
display "------------------------------------------------------------"

graph hbar (percent) if employment_status_fig != "Not identifiable" ///
    & !missing(employment_status_fig), ///
    over(employment_status_fig, sort(1) descending label(labsize($axis_label_size))) ///
    title("Employment Status", $title_style) ///
    ytitle("Share of Cases (%)", size($axis_title_size)) ///
    bar(1, color(cranberry%45)) ///
    $blabel_pct ///
    ylabel(0(20)100, labsize($axis_label_size) nogrid) ///
    $graph_style

graph export "$graph_path/02_4_employment_status.svg", ///
    replace width($export_w) height($export_h)

*============================================================*
* 5. How counselling demand changes over time
*============================================================*

*------------------------------------------------------------*
* Graph 3.1: Monthly counselling cases
*------------------------------------------------------------*

preserve

keep if !missing(created_month)

display "------------------------------------------------------------"
display "Graph 3.1: Monthly Counselling Cases"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(created_month)

format created_month %tmMon_CCYY
summ created_month, meanonly
local min_month = r(min)
local max_month = r(max)

twoway ///
    (connected n_cases created_month, ///
        lcolor(ebblue) mcolor(ebblue) ///
        lwidth(medthick) msymbol(circle) msize(small)), ///
    title("Monthly Counselling Cases", $title_style) ///
    xtitle("Month", size($axis_title_size)) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    xlabel(`min_month'(1)`max_month', format(%tmMon_CCYY) angle(45) labsize($axis_label_size)) ///
    ylabel(0(50)400, labsize($axis_label_size) nogrid) ///
    yscale(range(0 .)) ///
    legend(off) ///
    $graph_style

graph export "$graph_path/03_1_monthly_counselling_cases.svg", ///
    replace width($export_w) height($export_h)

restore

*------------------------------------------------------------*
* Graph 3.2: Monthly topic shares
*------------------------------------------------------------*

preserve

keep if !missing(created_month) & !missing(topic_cluster)

display "------------------------------------------------------------"
display "Graph 3.2: Monthly Topic Shares"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(created_month topic_cluster)

bysort created_month: egen total_month = total(n_cases)
gen topic_share = n_cases / total_month * 100

format created_month %tmMon_CCYY
summ created_month, meanonly
local min_month = r(min)
local max_month = r(max)

twoway ///
    (connected topic_share created_month if topic_cluster == "Employment & Labour Rights", ///
        lcolor(ebblue%75) mcolor(ebblue%75) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected topic_share created_month if topic_cluster == "Residence & Legal Status", ///
        lcolor(cranberry%50) mcolor(cranberry%50) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected topic_share created_month if topic_cluster == "Social Benefits", ///
        lcolor(forest_green%75) mcolor(forest_green%75) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected topic_share created_month if topic_cluster == "Education & Qualification", ///
        lcolor(orange_red%50) mcolor(orange_red%50) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected topic_share created_month if topic_cluster == "Language & Integration", ///
        lcolor(purple%50) mcolor(purple%50) lwidth(medthick) msymbol(circle) msize(vsmall)), ///
    title("Monthly Shares by Counselling Topic", $title_style) ///
    xtitle("Month", size($axis_title_size)) ///
    ytitle("Share of Monthly Counselling Cases (%)", size($axis_title_size)) ///
    xlabel(`min_month'(1)`max_month', format(%tmMon_CCYY) angle(45) labsize($axis_label_size) nogrid) ///
    ylabel(0(20)100, labsize($axis_label_size)) ///
    yscale(range(0 100)) ///
    legend(order(1 "Employment & Labour Rights" ///
                 2 "Residence & Legal Status" ///
                 3 "Social Benefits" ///
                 4 "Education & Qualification" ///
                 5 "Language & Integration") ///
        position(6) rows(2) size(vsmall)) ///
    $graph_style

graph export "$graph_path/03_2_monthly_topic_shares.svg", ///
    replace width($export_w) height($export_h)

restore

*------------------------------------------------------------*
* Graph 3.3: Monthly counselling demand by language
*------------------------------------------------------------*

preserve

keep if !missing(created_month) ///
    & inlist(language, "Arabic", "Persian", "Russian", ///
        "Turkish", "Ukrainian", "French")

display "------------------------------------------------------------"
display "Graph 3.3: Monthly Counselling Demand by Language"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(created_month language)

format created_month %tmMon_CCYY
summ created_month, meanonly
local min_month = r(min)
local max_month = r(max)

twoway ///
    (connected n_cases created_month if language == "Arabic", ///
        lcolor($col_arabic%80) mcolor($col_arabic%80) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected n_cases created_month if language == "Persian", ///
        lcolor($col_persian%80) mcolor($col_persian%80) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected n_cases created_month if language == "Russian", ///
        lcolor($col_russian%80) mcolor($col_russian%80) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected n_cases created_month if language == "Turkish", ///
        lcolor($col_turkish%80) mcolor($col_turkish%80) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected n_cases created_month if language == "Ukrainian", ///
        lcolor($col_ukrainian%80) mcolor($col_ukrainian%80) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
    (connected n_cases created_month if language == "French", ///
        lcolor($col_french%80) mcolor($col_french%80) lwidth(medthick) msymbol(circle) msize(vsmall)), ///
    title("Monthly Counselling Cases by Language", $title_style) ///
    xtitle("Month", size($axis_title_size)) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    xlabel(`min_month'(1)`max_month', format(%tmMon_CCYY) angle(45) labsize($axis_label_size)) ///
    ylabel(0(20)120, labsize($axis_label_size) nogrid) ///
    yscale(range(0 120)) ///
    legend(order(1 "Arabic" 2 "Persian" 3 "Russian" ///
                 4 "Turkish" 5 "Ukrainian" 6 "French") ///
        position(6) rows(2) size(vsmall)) ///
    $graph_style

graph export "$graph_path/03_3_monthly_demand_by_language.svg", ///
    replace width($export_w) height($export_h)

restore

*============================================================*
* 6. Main counselling needs
*============================================================*

*------------------------------------------------------------*
* Graph 4.1: Counselling topics by language group
*------------------------------------------------------------*

capture which heatplot
if _rc {
    display as error "heatplot is not installed. Run: ssc install heatplot, replace"
}
else {

    preserve

    keep if !missing(topic_group) ///
        & !missing(language) ///
        & !inlist(language, "German", "English")

    display "------------------------------------------------------------"
    display "Graph 4.1: Counselling Topics by Language Group"
    count
    display "Sample used: " r(N)
    display "------------------------------------------------------------"

    contract topic_group language
    fillin topic_group language
    replace _freq = 0 if missing(_freq)

    bysort language: egen total_language = total(_freq)
    gen share = _freq / total_language * 100

    label variable topic_group "Counselling topic group"
    label variable language "Language group"
    label variable share "Share of counselling requests (%)"

    heatplot share topic_group language, ///
        color(Oranges) ///
        cuts(0 10 20 40 60 80 100) ///
        values(format(%4.0f) size(vsmall)) ///
        ylab(, labsize(small) angle(horizontal)) ///
        xlab(, angle(45) labsize($axis_label_size)) ///
        xtitle("") ///
        ytitle("") ///
        title("Counselling Topics by Language Group", $title_style) ///
        legend(title("Share of counselling requests (%)", size(small))) ///
        p(lcolor(white) lwidth(thin)) ///
        graphregion(color(white) margin(l+3 r+3 t+3 b+3)) ///
        plotregion(color(white) margin(zero))

    graph export "$graph_path/04_1_heatmap_topic_by_language.svg", ///
        replace width(4000) height(2500)

    restore
}

*------------------------------------------------------------*
* Graph 4.2: Referral rate by counselling topic
*------------------------------------------------------------*

preserve

keep if !missing(referral_dummy) ///
    & !missing(topic_group)

display "------------------------------------------------------------"
display "Graph 4.2: Referral Rate by Counselling Topic"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse ///
    (mean) referral_rate = referral_dummy ///
    (count) n_cases = referral_dummy, ///
    by(topic_group)

gen referral_rate_pct = referral_rate * 100

graph hbar referral_rate_pct, ///
    over(topic_group, sort(1) descending label(labsize(small))) ///
    title("Referral Rate by Counselling Topic", $title_style) ///
    ytitle("Referral Rate (%)", size($axis_title_size)) ///
    bar(1, color(lavender%40)) ///
    ylabel(0(20)100, labsize($axis_label_size) nogrid) ///
    blabel(bar, format(%4.0f) size(vsmall) color(black)) ///
    $graph_style

graph export "$graph_path/04_2_referral_rate_by_topic.svg", ///
    replace width($export_w) height($export_h)

restore

*------------------------------------------------------------*
* Graph 4.3: Referral rate by language group
*------------------------------------------------------------*

preserve

keep if !missing(referral_dummy) ///
    & !missing(language) ///
    & !inlist(language, "German", "English")

display "------------------------------------------------------------"
display "Graph 4.3: Referral Rate by Language Group"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse ///
    (mean) referral_rate = referral_dummy ///
    (count) n_cases = referral_dummy, ///
    by(language)

gen referral_rate_pct = referral_rate * 100

graph bar referral_rate_pct, ///
    over(language, sort(1) descending label(angle(35) labsize($axis_label_size))) ///
    title("Referral Rate by Language Group", $title_style) ///
    ytitle("Referral Rate (%)", size($axis_title_size)) ///
    bar(1, color(teal%70)) ///
    ylabel(0(10)100, labsize($axis_label_size) nogrid) ///
    blabel(bar, format(%4.0f) size(vsmall) color(black)) ///
    $graph_style

graph export "$graph_path/04_3_referral_rate_by_language.svg", ///
    replace width($export_w) height($export_h)

restore

*============================================================*
* 7. Optional community deep dives
*============================================================*

* This section keeps the original qualitative theme graphs, but runs only
* if all required variables exist.

local theme_vars ///
    job_search minijob language_course b2_course recognition ///
    jobcenter paragraph24 legal_problem no_german housing_job care_work ///
    cleaning_hotel education_kita ausbildung construction driver ///
    warehouse_factory kitchen_cleaning documents

local all_theme_vars_exist 1
foreach var of local theme_vars {
    capture confirm variable `var'
    if _rc local all_theme_vars_exist 0
}

if `all_theme_vars_exist' == 1 {

    foreach deep_lang in Arabic Ukrainian {

        preserve

        keep if language == "`deep_lang'"
        keep if inlist(gender, "Female", "Male")
        keep if !missing(original_text)

        display "------------------------------------------------------------"
        display "Graph 5: Top 5 Issues in `deep_lang'-Language Posts by Gender"
        count
        display "Sample used: " r(N)
        display "------------------------------------------------------------"

        collapse (sum) `theme_vars', by(gender)

        foreach var of local theme_vars {
            rename `var' theme_`var'
        }

        reshape long theme_, i(gender) j(topic) string
        rename theme_ count

        gen str40 topic_label = ""
        replace topic_label = "Job Search"              if topic == "job_search"
        replace topic_label = "Minijob / Side Job"      if topic == "minijob"
        replace topic_label = "Language Course"         if topic == "language_course"
        replace topic_label = "B2 Course"               if topic == "b2_course"
        replace topic_label = "Recognition"             if topic == "recognition"
        replace topic_label = "Jobcenter"               if topic == "jobcenter"
        replace topic_label = "Paragraph 24"            if topic == "paragraph24"
        replace topic_label = "Legal Problem"           if topic == "legal_problem"
        replace topic_label = "No German"               if topic == "no_german"
        replace topic_label = "Housing + Job"           if topic == "housing_job"
        replace topic_label = "Care Work"               if topic == "care_work"
        replace topic_label = "Cleaning / Hotel"        if topic == "cleaning_hotel"
        replace topic_label = "Education / Kita"        if topic == "education_kita"
        replace topic_label = "Vocational Training"     if topic == "ausbildung"
        replace topic_label = "Construction"            if topic == "construction"
        replace topic_label = "Driver / Courier"        if topic == "driver"
        replace topic_label = "Warehouse / Factory"     if topic == "warehouse_factory"
        replace topic_label = "Kitchen / Cleaning"      if topic == "kitchen_cleaning"
        replace topic_label = "Documents / Work Permit" if topic == "documents"

        keep if count > 0

        gsort gender -count topic_label
        by gender: gen rank_gender = _n
        keep if rank_gender <= 5

        if "`deep_lang'" == "Arabic" {
            local color1 "ebblue%75"
            local color2 "navy*0.8"
            local export_name "05_1_top5_issues_arabic_by_gender.svg"
        }
        else if "`deep_lang'" == "Ukrainian" {
            local color1 "sand%85"
            local color2 "dkorange%65"
            local export_name "05_2_top5_issues_ukrainian_by_gender.svg"
        }

        graph bar count, ///
            over(gender, label(labsize($axis_label_size))) ///
            over(topic_label, sort(1) descending label(angle(35) labsize($axis_label_size))) ///
            asyvars ///
            bar(1, color(`color1')) ///
            bar(2, color(`color2')) ///
            title("Top 5 Issues in `deep_lang'-Language Posts by Gender", $title_style) ///
            ytitle("Number of Posts", size($axis_title_size)) ///
            ylabel(, labsize($axis_label_size) nogrid) ///
            legend(order(1 "Women" 2 "Men") ///
                position(6) rows(1) size(vsmall) region(lcolor(none))) ///
            $graph_style

        graph export "$graph_path/`export_name'", ///
            replace width($export_w) height($export_h)

        restore
    }
}
else {
    display as text "Optional deep-dive graphs skipped: one or more theme variables are missing."
}

display "------------------------------------------------------------"
display "Infographic graphs completed."
display "Graphs saved in: $graph_path"
display "------------------------------------------------------------"