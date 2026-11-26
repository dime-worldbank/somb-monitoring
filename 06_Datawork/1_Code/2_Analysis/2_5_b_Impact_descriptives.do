****************************************************************************
**#  Load Data and Global Graph Settings
****************************************************************************

*--------------------------------------------------------------------------
*  Load Analysis Dataset
*--------------------------------------------------------------------------

capture confirm file "${processing}/SoMB_WB_analysis.dta"

if _rc {
    display as error ///
        "Input file not found: ${processing}/SoMB_WB_analysis.dta"
    exit 601
}

use "${processing}/SoMB_WB_analysis.dta", clear


*--------------------------------------------------------------------------
*  Global Graph Settings
*--------------------------------------------------------------------------

* Export dimensions
global export_w 3000
global export_h 1800

* Font sizes
global title_size      "medium"
global axis_title_size "small"
global axis_label_size "small"
global legend_size     "small"

* Title style
global title_style ///
    size($title_size) ///
    color(black)

* Graph background
global graph_style ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    bgcolor(white)

* Bar labels
global blabel_count ///
    blabel(bar, size(vsmall) color(black) format(%9.0f))

global blabel_pct ///
    blabel(bar, size(vsmall) color(black) format(%4.0f))


*--------------------------------------------------------------------------
*  Color Palette
*--------------------------------------------------------------------------

* Treatment groups
global col_lateris     "eltblue"
global col_control     "gs12"

* General colors
global col_total       "eltblue"
global col_neutral     "gs12"

* Categorical colors
global col_1           "eltblue"
global col_2           "forest_green"
global col_3           "cranberry"
global col_4           "teal"
global col_5           "sand"
global col_6           "purple"
global col_7           "orange_red"
global col_8           "navy"
global col_9           "dkgreen"
global col_10          "maroon"
global col_11          "green"

* Gender
global col_female      "forest_green%55"
global col_male        "orange_red%45"

* Languages
global col_arabic      "$col_1"
global col_persian     "$col_2"
global col_russian     "$col_3"
global col_turkish     "$col_4"
global col_ukrainian   "$col_5"
global col_french      "$col_6"
global col_other       "$col_7"

****************************************************************************
**# 01. Counselling Cases by Language
****************************************************************************

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Exclude Vietnamese (one observation) from the visualization.

drop if language == "21: Vietnamesisch"

* Report the sample size and language distribution.

count
tab language, missing
tab language treatment


*--------------------------------------------------------------------------
* 01a. Prepare Data for Graph
*--------------------------------------------------------------------------

* Count consultations by language and treatment assignment.

gen one_case = 1

collapse ///
    (sum) n_cases = one_case, ///
    by(language treatment)

* Reshape to one observation per language.

reshape wide n_cases, ///
    i(language) ///
    j(treatment)

rename n_cases0 control_cases
rename n_cases1 lateris_cases

* Replace missing group counts with zero.

replace control_cases = 0 if missing(control_cases)
replace lateris_cases = 0 if missing(lateris_cases)

* Calculate total consultations by language.

gen total_cases = control_cases + lateris_cases


*--------------------------------------------------------------------------
* 01b. Graph - English Version
*--------------------------------------------------------------------------

graph hbar control_cases lateris_cases, ///
    over(language, ///
        sort(total_cases) descending ///
        label(labsize($axis_label_size))) ///
    stack ///
    bar(1, ///
        color($col_1%25) ///
        lcolor(none)) ///
    bar(2, ///
        color($col_total%85) ///
        lcolor(none)) ///
    blabel(total, ///
        format(%9.0f) ///
        size(small) ///
        color(black)) ///
    title("Cases by Language", $title_style) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend( ///
        order(1 "Non-Lateris weeks (C)" ///
              2 "Lateris weeks (T)") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_3_cases_by_language_treatment_hbar.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 01c. Graph - German Version 
*--------------------------------------------------------------------------

/*

* Translate language labels into German.

replace language = "Arabisch"    if language == "Arabic"
replace language = "Englisch"    if language == "English"
replace language = "Französisch" if language == "French"
replace language = "Deutsch"     if language == "German"
replace language = "Persisch"    if language == "Persian"
replace language = "Russisch"    if language == "Russian"
replace language = "Türkisch"    if language == "Turkish"
replace language = "Ukrainisch"  if language == "Ukrainian"

graph hbar control_cases lateris_cases, ///
    over(language, ///
        sort(total_cases) descending ///
        label(labsize($axis_label_size))) ///
    stack ///
    bar(1, ///
        color($col_1%25) ///
        lcolor(none)) ///
    bar(2, ///
        color($col_total%85) ///
        lcolor(none)) ///
    blabel(total, ///
        format(%9.0f) ///
        size(small) ///
        color(black)) ///
    title("Anzahl der Beratungsfälle nach Sprache", $title_style) ///
    ytitle("Anzahl der Beratungsfälle", size($axis_title_size)) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend( ///
        order(1 "Wochen ohne Lateris (C)" ///
              2 "Wochen mit Lateris (T)") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_3_cases_by_language_treatment_hbar_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 02. Counselling Cases by Project Week
****************************************************************************

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Report the sample size.

count


*--------------------------------------------------------------------------
* 02a. Prepare Data for Graph
*--------------------------------------------------------------------------

* Count consultations by project week and treatment assignment.

gen one_case = 1

collapse ///
    (sum) n_cases = one_case, ///
    by(project_week treatment)

* Reshape to one observation per project week.

reshape wide n_cases, ///
    i(project_week) ///
    j(treatment)

rename n_cases0 control_cases
rename n_cases1 lateris_cases

* Replace missing group counts with zero.

replace control_cases = 0 if missing(control_cases)
replace lateris_cases = 0 if missing(lateris_cases)

* Calculate total consultations per project week.

gen total_cases = control_cases + lateris_cases

* Define the baseline for the stacked area graph.

gen zero = 0

sort project_week


*--------------------------------------------------------------------------
* 02b. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (rarea zero control_cases project_week, ///
        color($col_5%20) ///
        lcolor($col_5%40)) ///
    (rarea control_cases total_cases project_week, ///
        color($col_11%20) ///
        lcolor($col_11%40)) ///
    (connected total_cases project_week, ///
        lcolor($col_total) ///
        mcolor($col_total) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(vsmall)), ///
    title("Counselling Cases by Project Week", $title_style) ///
    xtitle("Project Week", size($axis_title_size)) ///
    ytitle("Number of Cases", size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(0 .)) ///
    legend( ///
        order(1 "Non-Lateris weeks (C)" ///
              2 "Lateris weeks (T)" ///
              3 "Total") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_1_cases_by_project_week_stacked.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 02c. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (rarea zero control_cases project_week, ///
        color($col_5%20) ///
        lcolor($col_5%40)) ///
    (rarea control_cases total_cases project_week, ///
        color($col_11%20) ///
        lcolor($col_11%40)) ///
    (connected total_cases project_week, ///
        lcolor($col_total) ///
        mcolor($col_total) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(vsmall)), ///
    title("Beratungsfälle nach Projektwoche", $title_style) ///
    xtitle("Projektwoche", size($axis_title_size)) ///
    ytitle("Anzahl der Beratungsfälle", size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(0 .)) ///
    legend( ///
        order(1 "Wochen ohne Lateris (C)" ///
              2 "Wochen mit Lateris (T)" ///
              3 "Gesamt") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_1_cases_by_project_week_stacked_german.svg", ///
    replace width($export_w) height($export_h)

*/


restore

****************************************************************************
**# 03. Average Consultation Duration by Project Week
****************************************************************************

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Exclude consultations with missing duration.

keep if !missing(consultation_duration_min)

* Report the sample size.

count


*--------------------------------------------------------------------------
* 03a. Prepare Data for Graph
*--------------------------------------------------------------------------

* Calculate the unadjusted mean consultation duration
* by project week and treatment assignment.

collapse ///
    (mean) avg_duration = consultation_duration_min, ///
    by(project_week treatment)

sort treatment project_week


*--------------------------------------------------------------------------
* 03b. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (connected avg_duration project_week if treatment == 0, ///
        lcolor($col_russian%45) ///
        mcolor($col_russian%45) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(small)) ///
    (connected avg_duration project_week if treatment == 1, ///
        lcolor($col_persian%65) ///
        mcolor($col_persian%65) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(small)), ///
    title("Consultation Duration by Project Week", $title_style) ///
    xtitle("Project Week", ///
        size($axis_title_size)) ///
    ytitle("Average Consultation Duration (Minutes)", ///
        size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(0(5)30, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend( ///
        order(1 "Non-Lateris weeks (C)" ///
              2 "Lateris weeks (T)") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_1_consultation_duration_over_time_treatment.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 03c. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (connected avg_duration project_week if treatment == 0, ///
        lcolor($col_russian%45) ///
        mcolor($col_russian%45) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(small)) ///
    (connected avg_duration project_week if treatment == 1, ///
        lcolor($col_persian%65) ///
        mcolor($col_persian%65) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(small)), ///
    title("Beratungsdauer nach Projektwoche", $title_style) ///
    xtitle("Projektwoche", ///
        size($axis_title_size)) ///
    ytitle("Durchschnittliche Beratungsdauer (Minuten)", ///
        size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(0(5)30, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend( ///
        order(1 "Wochen ohne Lateris (C)" ///
              2 "Wochen mit Lateris (T)") ///
        position(6) ///
        rows(1) ///
        size($legend_size)) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_1_consultation_duration_over_time_treatment_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 04. Gender Distribution
****************************************************************************

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Report the sample size and gender distribution,
* including missing values.

count
tab gender, missing

* Exclude the category "Divers" from the visualization.

drop if gender == "Divers"

* Report the number of observations included in the graph.

count if !missing(gender)


*--------------------------------------------------------------------------
* 04a. Graph - English Version
*--------------------------------------------------------------------------

graph bar (count), ///
    over(gender, ///
        label(labsize($axis_label_size))) ///
    bar(1, ///
        color($col_1%85) ///
        lcolor(none)) ///
    bar(2, ///
        color($col_2%85) ///
        lcolor(none)) ///
    bar(3, ///
        color($col_total%50) ///
        lcolor(none)) ///
    blabel(bar, ///
        format(%9.0f) ///
        size($axis_label_size) ///
        color(black)) ///
    title("Gender Distribution", $title_style) ///
    ytitle("Number of Cases", ///
        size($axis_title_size)) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_2_gender_distribution_bar.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 04b. Graph - German Version
*--------------------------------------------------------------------------

/*

* Translate gender categories into German.

replace gender = "Frauen" ///
    if gender == "Female"

replace gender = "Männer" ///
    if gender == "Male"

replace gender = "Nicht identifizierbar" ///
    if gender == "Not identifiable"

graph bar (count), ///
    over(gender, ///
        label(labsize($axis_label_size))) ///
    bar(1, ///
        color($col_1%85) ///
        lcolor(none)) ///
    bar(2, ///
        color($col_2%85) ///
        lcolor(none)) ///
    bar(3, ///
        color($col_total%50) ///
        lcolor(none)) ///
    blabel(bar, ///
        format(%9.0f) ///
        size($axis_label_size) ///
        color(black)) ///
    title("Geschlechterverteilung", $title_style) ///
    ytitle("Anzahl der Beratungsfälle", ///
        size($axis_title_size)) ///
    ylabel(, ///
        labsize($axis_label_size) ///
        nogrid) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/01_2_geschlechterverteilung_bar.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 05. Geographic Distribution of Counselling Cases
****************************************************************************

*--------------------------------------------------------------------------
* 05a. Required Stata Packages
*--------------------------------------------------------------------------

* The following packages are required to generate the map.
* Installation is only necessary once.

* ssc install moremata
* ssc install palettes
* ssc install colrspace

* net install geoframe, ///
*     from("https://raw.githubusercontent.com/benjann/geoframe/main/")

* net install geoplot, ///
*     from("https://raw.githubusercontent.com/benjann/geoplot/main/")

* Verify that the required commands are available.

which geoframe
which geoplot


*--------------------------------------------------------------------------
* 05b. Prepare Case Counts by Federal State
*--------------------------------------------------------------------------

* Store the name of the original data frame.

local original_frame "`c(frame)'"

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Report the geographic distribution before exclusions.

tab federal_state, missing

* Exclude consultations without an identifiable federal state.

drop if federal_state == "0: Nicht bestimmbar"
drop if missing(federal_state)

count

* Count consultations by federal state.

gen cases = 1

collapse (sum) cases, by(federal_state)

* Extract the numeric state identifier from the original variable.

gen state_num = real(substr(federal_state, ///
    1, strpos(federal_state, ":") - 1))


*--------------------------------------------------------------------------
* 05c. Harmonize Federal State Identifiers
*--------------------------------------------------------------------------

* Convert project-specific state identifiers to official
* Federal Agency for Cartography and Geodesy (BKG) state codes.

gen str2 SN_L = ""

replace SN_L = "08" if state_num == 1   // Baden-Württemberg
replace SN_L = "09" if state_num == 2   // Bayern
replace SN_L = "11" if state_num == 3   // Berlin
replace SN_L = "12" if state_num == 4   // Brandenburg
replace SN_L = "04" if state_num == 5   // Bremen
replace SN_L = "02" if state_num == 6   // Hamburg
replace SN_L = "06" if state_num == 7   // Hessen
replace SN_L = "13" if state_num == 8   // Mecklenburg-Vorpommern
replace SN_L = "03" if state_num == 9   // Niedersachsen
replace SN_L = "05" if state_num == 10  // Nordrhein-Westfalen
replace SN_L = "07" if state_num == 11  // Rheinland-Pfalz
replace SN_L = "10" if state_num == 12  // Saarland
replace SN_L = "14" if state_num == 13  // Sachsen
replace SN_L = "15" if state_num == 14  // Sachsen-Anhalt
replace SN_L = "01" if state_num == 15  // Schleswig-Holstein
replace SN_L = "16" if state_num == 16  // Thüringen

* Verify that all state identifiers have been matched.

assert !missing(SN_L)

keep SN_L cases

isid SN_L

tempfile cases_state

save `cases_state'

restore


*--------------------------------------------------------------------------
* 05d. Load Geographic Data
*--------------------------------------------------------------------------

* Geographic boundaries are based on the BKG VG250 dataset.

local shpdir "${data}/map_data/vg250-ew_12-31.utm32s.shape.ebenen/vg250-ew_ebenen_1231"

capture confirm file "`shpdir'/VG250_LAN.shp"

if _rc {
    display as error "Federal state shapefile not found."
    exit 601
}

* Create a separate geographic frame.

geoframe create states using ///
    "`shpdir'/VG250_LAN.shp", ///
    dtype(esri) replace current


*--------------------------------------------------------------------------
* 05e. Merge Consultation Counts with Geographic Data
*--------------------------------------------------------------------------

merge m:1 SN_L using `cases_state'

* Verify the geographic merge.

tab _merge

assert _merge != 2

* Assign zero consultations to states without recorded cases.

replace cases = 0 if _merge == 1

drop _merge

list GEN SN_L cases, clean


*--------------------------------------------------------------------------
* 05f. Prepare Map Labels
*--------------------------------------------------------------------------

* Create a separate frame containing one label per federal state.

frame copy states state_labels, replace

frame change state_labels

bysort SN_L (_ID): keep if _n == 1

* Verify that all 16 federal states are represented.

assert _N == 16

* Adjust label positions to improve readability around Berlin
* and Brandenburg.

replace _CX = _CX + 40000 if GEN == "Berlin"
replace _CY = _CY - 20000 if GEN == "Berlin"

replace _CX = _CX - 30000 if GEN == "Brandenburg"
replace _CY = _CY + 25000 if GEN == "Brandenburg"

frame change states


*--------------------------------------------------------------------------
* 05g. Graph - English Version
*--------------------------------------------------------------------------

geoplot ///
    (area states cases, ///
        cuts(0 10 30 60 100 200 250) ///
        color(Blues) ///
        lcolor(white) ///
        lwidth(vthin)) ///
    (label state_labels cases, ///
        size(small) ///
        color(black)), ///
    legend( ///
        title("Number of Cases") ///
        order(1 "0–10" ///
              2 "11–30" ///
              3 "31–60" ///
              4 "61–100" ///
              5 "101–200" ///
              6 "201–250") ///
        position(3)) ///
    graphregion(color(white))

graph export ///
    "${impact}/Graphs/geoframe_federal_state.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 05h. Graph - German Version 
*--------------------------------------------------------------------------

/*

geoplot ///
    (area states cases, ///
        cuts(0 10 30 60 100 200 250) ///
        color(Blues) ///
        lcolor(white) ///
        lwidth(vthin)) ///
    (label state_labels cases, ///
        size(small) ///
        color(black)), ///
    legend( ///
        title("Anzahl der Beratungsfälle") ///
        order(1 "0–10" ///
              2 "11–30" ///
              3 "31–60" ///
              4 "61–100" ///
              5 "101–200" ///
              6 "201–250") ///
        position(3)) ///
    graphregion(color(white))

graph export ///
    "${impact}/Graphs/geoframe_federal_state_german.svg", ///
    replace width($export_w) height($export_h)

*/


*--------------------------------------------------------------------------
* 05i. Restore Original Data Frame
*--------------------------------------------------------------------------

frame change `original_frame'

capture frame drop state_labels
capture frame drop states

****************************************************************************
**# 06. Implementation Fidelity
****************************************************************************

preserve

* Restrict the sample to the intervention period and consultations
* with a valid randomized treatment assignment.

keep if inrange(project_week, 1, 20)
keep if inlist(treatment, 0, 1)

* Exclude consultations with missing information on Lateris use.

keep if !missing(lateris_yes)

* Verify that Lateris use is coded as a binary variable.

assert inlist(lateris_yes, 0, 1)


*--------------------------------------------------------------------------
* 06a. Overall Adherence to Treatment Assignment
*--------------------------------------------------------------------------

* Report actual Lateris use by randomized treatment assignment.
* This captures both treatment adherence and control-group contamination.

tab treatment lateris_yes, row


*--------------------------------------------------------------------------
* 06b. Weekly Implementation Fidelity
*--------------------------------------------------------------------------

* Implementation fidelity is defined as the share of consultations
* using Lateris during Lateris-assigned weeks.

keep if treatment == 1

count

* Calculate weekly implementation fidelity.

collapse ///
    (count) total_cases   = lateris_yes ///
    (sum)   lateris_cases = lateris_yes ///
    (mean)  fidelity      = lateris_yes, ///
    by(project_week)

* Convert proportions to percentages.

replace fidelity = fidelity * 100

* Calculate overall implementation fidelity across all
* treatment-assigned consultations.
*
* The overall measure is weighted by the number of consultations
* in each project week.

quietly summarize lateris_cases

local used = r(sum)

quietly summarize total_cases

local total = r(sum)

local overall = 100 * `used' / `total'

display as text "Consultations assigned to Lateris: " ///
    as result `total'

display as text "Consultations using Lateris: " ///
    as result `used'

display as text "Overall implementation fidelity: " ///
    as result %5.2f `overall' "%"

* Report weekly case counts and fidelity.

list project_week total_cases lateris_cases fidelity, noobs

sort project_week


*--------------------------------------------------------------------------
* 06c. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (connected fidelity project_week, ///
        lcolor($col_lateris) ///
        mcolor(black) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(medium) ///
        mlabel(fidelity) ///
        mlabformat(%3.0f) ///
        mlabposition(12) ///
        mlabsize(small)), ///
    yline(`overall', ///
        lpattern(dash) ///
        lcolor(gs8)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(0(20)100, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(0 105)) ///
    xtitle("Project Week", ///
        size($axis_title_size)) ///
    ytitle("Lateris Use (%)", ///
        size($axis_title_size)) ///
    title("Implementation Fidelity Over Time", ///
        $title_style) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/implementation_fidelity_over_time.svg", ///
    replace width(3600) height(2200)


*--------------------------------------------------------------------------
* 06d. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (connected fidelity project_week, ///
        lcolor($col_lateris) ///
        mcolor(black) ///
        lwidth(medthick) ///
        msymbol(circle) ///
        msize(medium) ///
        mlabel(fidelity) ///
        mlabformat(%3.0f) ///
        mlabposition(12) ///
        mlabsize(small)), ///
    yline(`overall', ///
        lpattern(dash) ///
        lcolor(gs8)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(0(20)100, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(0 105)) ///
    xtitle("Projektwoche", ///
        size($axis_title_size)) ///
    ytitle("Lateris-Nutzung (%)", ///
        size($axis_title_size)) ///
    title("Implementierungstreue im Zeitverlauf", ///
        $title_style) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/implementation_fidelity_over_time_DE.svg", ///
    replace width(3600) height(2200)

*/

restore
