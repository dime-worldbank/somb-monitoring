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

4) Objective: 	Build the harmonised visualisations for the SoMB counselling
				infographic

5) Output:		- 14 .svg  (3_Output/Infographic/Graphs)

*************************************************************************
*************************************************************************/

clear all
set more off


****************************************************************************
**#  Load Data
****************************************************************************

* This do-file produces descriptive visualizations for the
* SoMB monitoring infographic.
*
* The analysis is independent of the impact evaluation.
* Infographic-specific variables and sample restrictions
* are used exclusively for descriptive monitoring purposes.
*
* The underlying input dataset is not modified or overwritten.


if "${processing}" == "" | "${infographic}" == "" {
    display as error "Run the master do-file first: processing and infographic globals are required."
    exit 198
}

capture confirm file ///
    "${processing}/SoMB_WB_monitoring_indicators.dta"

if _rc {
    display as error "Monitoring dataset not found."
    exit 601
}

use "${processing}/SoMB_WB_monitoring_indicators.dta", clear

* Ensure that the graph output directory exists.

capture mkdir "${infographic}/Graphs"

* All transformations are in memory; no input dataset is saved.



****************************************************************************
**# 1. Infographic-Specific Data Preparation
****************************************************************************

* Variables generated in this section are used exclusively
* for descriptive monitoring and infographic visualizations.


*--------------------------------------------------------------------------
* 01a. Case Counter
*--------------------------------------------------------------------------

capture drop one_case
gen byte one_case = 1

label variable one_case "Counselling case counter"

assert one_case == 1


*--------------------------------------------------------------------------
* 01b. Communication Platforms
*--------------------------------------------------------------------------

capture drop channel_group

gen str20 channel_group = ""

replace channel_group = "Facebook" ///
    if strpos(channel, "Facebook") > 0

replace channel_group = "TikTok" ///
    if strpos(channel, "TikTok") > 0

replace channel_group = "Threads" ///
    if strpos(channel, "Threads") > 0

replace channel_group = "WhatsApp" ///
    if strpos(channel, "WhatsApp") > 0

replace channel_group = "Email" ///
    if strpos(channel, "E-Mail") > 0

replace channel_group = "Vkontakte" ///
    if strpos(channel, "Vkontakte") > 0

replace channel_group = "Telegram" ///
    if strpos(channel, "Telegram") > 0

label variable channel_group "Communication platform"

tab channel_group, missing

count if missing(channel_group) & !missing(channel)
if r(N) > 0 display as error "Warning: unmapped channels excluded from Graph 1.1."


*--------------------------------------------------------------------------
* 01c. Referral Indicator
*--------------------------------------------------------------------------

* Reuse the existing binary referral indicator.

assert inlist(referral_yes, 0, 1) if !missing(referral_yes)

capture drop referral_dummy

clonevar referral_dummy = referral_yes

label variable referral_dummy "Referral provided"

capture confirm variable referral_provided
if !_rc {
    tab referral_provided referral_dummy, missing
}
label define infographic_referral 0 "No" 1 "Yes", replace
label values referral_dummy infographic_referral


*--------------------------------------------------------------------------
* 01d. Employment Status
*--------------------------------------------------------------------------

* Harmonize employment categories for English-language visualizations.

capture drop employment_status_fig

gen str50 employment_status_fig = ""

replace employment_status_fig = "Not identifiable" ///
    if employment_status == "0: Nicht bestimmbar"

replace employment_status_fig = "Employment subject to social insurance" ///
    if employment_status == "1: SVP-beschäftigt"

replace employment_status_fig = "Marginal employment" ///
    if employment_status == "2: geringfügig beschäftigt"

replace employment_status_fig = "Registered jobseeker" ///
    if employment_status == "4: arbeitssuchend gemeldet"

replace employment_status_fig = "Unemployed - registered with Jobcenter" ///
    if employment_status == "5: arbeitslos - beim JC gemeldet"

replace employment_status_fig = "Unemployed - not registered with Jobcenter" ///
    if employment_status == "6: arbeitslos - nicht beim JC gemeldet"

replace employment_status_fig = "Unemployed - receiving benefits" ///
    if employment_status == "7: arbeitslos - Leistungen vom JC/BA"

replace employment_status_fig = "Education or vocational training" ///
    if employment_status == "9: in Studium/Ausbildung"

label variable employment_status_fig "Employment status"

tab employment_status_fig, missing

count if missing(employment_status_fig) & !missing(employment_status)
if r(N) > 0 display as error "Warning: unmapped employment categories excluded from Graph 2.4."


****************************************************************************
**# 				2. How users access the service
****************************************************************************

*------------------------------------------------------------*
* Graph 1.1: Cases by communication channel
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/01_1_communication_channel.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 1.2: Referral provided
*------------------------------------------------------------*

preserve
capture noisily {
keep if !missing(referral_dummy)
contract referral_dummy

display "------------------------------------------------------------"
display "Graph 1.2: Referral Provided"
summ _freq
display "Sample used: " r(sum)
display "------------------------------------------------------------"

graph pie _freq, ///
    over(referral_dummy) ///
    plabel(_all percent, format(%4.1f) size(small) color(black)) ///
    title("Referral Provided", $title_style) ///
    legend(size($legend_size) position(6) rows(1)) ///
    pie(1, color($col_total%55)) ///
    pie(2, color($col_support)) ///
    $graph_style

graph export "${infographic}/Graphs/01_2_referral_provided.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 1.3: Monthly share of anonymous cases
*------------------------------------------------------------*

preserve
capture noisily {
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
    (area anonymous_share created_month, sort color($col_total%25)) ///
    (line anonymous_share created_month, sort lcolor($col_total%85) lwidth(medthick)), ///
    title("Monthly Share of Anonymous Cases", $title_style) ///
    xtitle("Month", size($axis_title_size)) ///
    ytitle("Anonymous Cases (%)", size($axis_title_size)) ///
    xlabel(`min_month'(1)`max_month', format(%tmMon_CCYY) angle(45) labsize($axis_label_size)) ///
    ylabel(0(10)100, labsize($axis_label_size) nogrid) ///
    yscale(range(0 100)) ///
    legend(off) ///
    $graph_style

graph export "${infographic}/Graphs/01_3_anonymous_cases_over_time.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."


****************************************************************************
**# 3. Who uses the service
****************************************************************************

*------------------------------------------------------------*
* Graph 2.1: Cases by language
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/02_1_language_distribution.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 2.2: Geographic concentration by language
*------------------------------------------------------------*

preserve
capture noisily {
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

gsort -total_cases federal_state
keep if _n <= 10
gen state_order = _n

graph bar ///
    n_casesArabic ///
    n_casesPersian ///
    n_casesRussian ///
    n_casesTurkish ///
    n_casesUkrainian ///
    n_casesFrench, ///
    over(federal_state, sort(state_order) ///
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

graph export "${infographic}/Graphs/02_2_geographic_concentration_by_language.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 2.3: Residence status
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/02_3_residence_status.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 2.4: Employment status
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/02_4_employment_status.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."


****************************************************************************
**# 4. How counselling demand changes over time
****************************************************************************

*------------------------------------------------------------*
* Graph 3.1: Monthly counselling cases
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/03_1_monthly_counselling_cases.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 3.2: Monthly topic shares
*------------------------------------------------------------*

capture confirm variable topic_cluster
if _rc {
    capture confirm string variable topic_group
    if !_rc {
        quietly count if inlist(topic_group, "Employment & Labour Rights", ///
            "Residence & Legal Status", "Social Benefits", ///
            "Education & Qualification", "Language & Integration")
        if r(N) > 0 {
            quietly count if !missing(topic_group) & !inlist(topic_group, ///
                "Employment & Labour Rights", "Residence & Legal Status", ///
                "Social Benefits", "Education & Qualification", "Language & Integration")
            if r(N) == 0 clonevar topic_cluster = topic_group
        }
    }
}
capture confirm string variable topic_cluster
if _rc {
    display as error "Graph 3.2 skipped: topic_cluster missing or not a string. Verify topic mapping."
}
else {
preserve
capture noisily {

keep if !missing(created_month) & !missing(topic_cluster)

display "------------------------------------------------------------"
display "Graph 3.2: Monthly Topic Shares"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(created_month topic_cluster)

fillin created_month topic_cluster
replace n_cases = 0 if missing(n_cases)

bysort created_month: egen total_month = total(n_cases)
gen topic_share = n_cases / total_month * 100

format created_month %tmMon_CCYY
summ created_month, meanonly
local min_month = r(min)
local max_month = r(max)

twoway ///
    (connected topic_share created_month if topic_cluster == "Employment & Labour Rights", ///
        sort lcolor(ebblue%75) mcolor(ebblue%75) lwidth(medthick) msymbol(circle) msize(vsmall)) ///
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

graph export "${infographic}/Graphs/03_2_monthly_topic_shares.svg", ///
    replace width($export_w) height($export_h)

}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."
}

*------------------------------------------------------------*
* Graph 3.3: Monthly counselling demand by language
*------------------------------------------------------------*

preserve
capture noisily {
keep if !missing(created_month) ///
    & inlist(language, "Arabic", "Persian", "Russian", ///
        "Turkish", "Ukrainian", "French")

display "------------------------------------------------------------"
display "Graph 3.3: Monthly Counselling Demand by Language"
count
display "Sample used: " r(N)
display "------------------------------------------------------------"

collapse (sum) n_cases = one_case, by(created_month language)
fillin created_month language
replace n_cases = 0 if missing(n_cases)

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

graph export "${infographic}/Graphs/03_3_monthly_demand_by_language.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."


****************************************************************************
**# 5. Main counselling needs
****************************************************************************

*------------------------------------------------------------*
* Graph 4.1: Counselling topics by language group
*------------------------------------------------------------*

capture which heatplot
if _rc {
    display as error "heatplot is not installed. Run: ssc install heatplot, replace"
}
else {

    preserve

    capture noisily {

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

    encode topic_group, gen(topic_heat)
    encode language, gen(language_heat)

    heatplot share topic_heat language_heat, ///
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

    graph export "${infographic}/Graphs/04_1_heatmap_topic_by_language.svg", ///
        replace width(4000) height(2500)

    }

    local graph_rc = _rc

    restore

    if `graph_rc' display as error "Graph failed (return code `graph_rc')."
}

*------------------------------------------------------------*
* Graph 4.2: Referral rate by counselling topic
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/04_2_referral_rate_by_topic.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."

*------------------------------------------------------------*
* Graph 4.3: Referral rate by language group
*------------------------------------------------------------*

preserve
capture noisily {
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

graph export "${infographic}/Graphs/04_3_referral_rate_by_language.svg", ///
    replace width($export_w) height($export_h)
}
local graph_rc = _rc
restore
if `graph_rc' display as error "Graph failed (return code `graph_rc')."


****************************************************************************
**# 6. Optional community deep dives
****************************************************************************

* This section keeps the original qualitative theme graphs, but runs only
* if all required variables exist.

local theme_vars ///
    job_search minijob language_course b2_course recognition ///
    jobcenter paragraph24 legal_problem no_german housing_job care_work ///
    cleaning_hotel education_kita ausbildung construction driver ///
    warehouse_factory kitchen_cleaning documents

local all_theme_vars_exist 1
foreach var in language gender original_text {
    capture confirm variable `var'
    if _rc local all_theme_vars_exist 0
}
foreach var of local theme_vars {
    capture confirm numeric variable `var'
    if _rc local all_theme_vars_exist 0
}

if `all_theme_vars_exist' == 1 {

    foreach deep_lang in Arabic Ukrainian {

        preserve
        capture noisily {

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

        graph export "${infographic}/Graphs/`export_name'", ///
            replace width($export_w) height($export_h)

        }
        local graph_rc = _rc
        restore
        if `graph_rc' display as error "Deep-dive graph failed (return code `graph_rc')."
    }
}
else {
    display as text "Optional deep-dive graphs skipped: one or more theme variables are missing."
}

display "------------------------------------------------------------"
display "Infographic graph run completed. Review warnings for skipped or failed graphs."
display "Graphs saved in: ${infographic}/Graphs"
display "------------------------------------------------------------"


****************************************************************************
* End of do-file