/*************************************************************************
                    Social Media Bridge (SoMB) - Germany
                         LATERIS Impact Evaluation

1) Created by:  Samrawit Degu Shibeshi
                DIME - World Bank
                sshibeshi@worldbank.org

2) Reviewed by: Daniel Márquez
                DIME - World Bank
                dmarquezmuskus@worldbank.org

3) Date:        Created January 2026
                Revised November 2026

4) Objective:   Estimate the intention-to-treat (ITT) effects of
                randomized access to Lateris on counselling outcomes
                and examine additional descriptive and dynamic effects.

5) Input:       SoMB_WB_analysis.dta

6) Output:      - Regression results
                - Descriptive statistics
                - Figures (SVG)

*************************************************************************/

****************************************************************************
**# 01. Impact on Consultation Duration
****************************************************************************

* Estimate the intention-to-treat (ITT) effect of access to Lateris
* on consultation duration (in minutes).
*
* The model includes counsellor and project-week fixed effects.
* Standard errors are clustered at the counsellor-week level,
* corresponding to the unit of randomization.

reg consultation_duration_min ///
    treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store m_consultation


*--------------------------------------------------------------------------
* 01a. Adjusted Mean Consultation Duration
*--------------------------------------------------------------------------

* Estimate adjusted means by randomized treatment assignment.

margins, at(treatment=(0 1))


*--------------------------------------------------------------------------
* 01b. Graph - English Version
*--------------------------------------------------------------------------

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_total%85) ///
        msymbol(circle) ///
        msize(vlarge)) ///
    ciopts( ///
        lcolor($col_total%65) ///
        lwidth(thick)) ///
    title("Consultation Duration", $title_style) ///
    subtitle("Adjusted means with 95% confidence intervals", ///
        size($axis_title_size)) ///
    xtitle("") ///
    ytitle("Consultation Duration (Minutes)", ///
        size(medium)) ///
    xlabel(0 "Control" ///
           1 "Treatment", ///
        labsize(medlarge) ///
        noticks) ///
    ylabel(16(1)21, ///
        labsize(medlarge) ///
        nogrid ///
        angle(horizontal)) ///
    xscale( ///
        range(-0.35 1.35) ///
        lwidth(thick)) ///
    yscale( ///
        range(15.5 21.1) ///
        lwidth(thick)) ///
    plotregion(margin(l=4 r=4 b=2 t=2)) ///
    graphregion(margin(l=3 r=3 b=3 t=3)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_a_main_consultation_duration.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 01c. Graph - German Version (Optional)
*--------------------------------------------------------------------------

/*

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_total%85) ///
        msymbol(circle) ///
        msize(vlarge)) ///
    ciopts( ///
        lcolor($col_total%65) ///
        lwidth(thick)) ///
    title("Beratungsdauer", $title_style) ///
    subtitle("Adjustierte Mittelwerte mit 95%-Konfidenzintervallen", ///
        size($axis_title_size)) ///
    xtitle("") ///
    ytitle("Beratungsdauer (Minuten)", ///
        size(medium)) ///
    xlabel(0 "Wochen ohne Lateris (C)" ///
           1 "Wochen mit Lateris (T)", ///
        labsize(medlarge) ///
        noticks) ///
    ylabel(16(1)21, ///
        labsize(medlarge) ///
        nogrid ///
        angle(horizontal)) ///
    xscale( ///
        range(-0.35 1.35) ///
        lwidth(thick)) ///
    yscale( ///
        range(15.5 21.1) ///
        lwidth(thick)) ///
    plotregion(margin(l=4 r=4 b=2 t=2)) ///
    graphregion(margin(l=3 r=3 b=3 t=3)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_a_main_consultation_duration_german.svg", ///
    replace width($export_w) height($export_h)

*/

****************************************************************************
**# 02. Impact on Case Volume
****************************************************************************

preserve

* Restrict the dataset to the analysis sample.

keep if analysis_sample == 1

* Aggregate consultation-level data to the counsellor-week level.
* Each observation represents one counsellor in one project week
* with at least one recorded consultation.

collapse ///
    (sum) case_volume = case_counter, ///
    by(counselor_id counselor_num project_week treatment)

egen counselor_week = group(counselor_num project_week)

label variable case_volume ///
    "Number of cases per counsellor-week"

label variable counselor_week ///
    "Counsellor-project week randomization unit"

summarize case_volume, detail

* Estimate the ITT effect of access to Lateris on weekly case volume.
* The model includes counsellor and project-week fixed effects.
* Standard errors are clustered at the counsellor-week level.

reg case_volume ///
    i.treatment ///
    i.counselor_num ///
    i.project_week, ///
    vce(cluster counselor_week)

estimates store m_case_volume


*--------------------------------------------------------------------------
* 02a. Adjusted Mean Case Volume
*--------------------------------------------------------------------------

margins treatment


*--------------------------------------------------------------------------
* 02b. Graph - English Version
*--------------------------------------------------------------------------

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_total%85) ///
        msymbol(circle) ///
        msize(vlarge)) ///
    ciopts( ///
        lcolor($col_total%65) ///
        lwidth(thick)) ///
    title("Case Volume", $title_style) ///
    subtitle("Adjusted means with 95% confidence intervals", ///
        size($axis_title_size)) ///
    xtitle("") ///
    ytitle("Cases per Counsellor-Week", ///
        size(medlarge)) ///
    xlabel(0 "Control" ///
           1 "Treatment", ///
        labsize(medlarge) ///
        noticks) ///
    ylabel(8(2)16, ///
        labsize(medlarge) ///
        nogrid ///
        angle(horizontal)) ///
    xscale( ///
        range(-0.5 1.5) ///
        lwidth(thick)) ///
    yscale( ///
        range(8 16) ///
        lwidth(thick)) ///
    plotregion(margin(l=4 r=4 b=2 t=2)) ///
    graphregion(margin(l=3 r=3 b=3 t=3)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_b_main_case_volume.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 02c. Graph - German Version 
*--------------------------------------------------------------------------

/*

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_total%85) ///
        msymbol(circle) ///
        msize(vlarge)) ///
    ciopts( ///
        lcolor($col_total%65) ///
        lwidth(thick)) ///
    title("Anzahl der Beratungsfälle", $title_style) ///
    subtitle("Adjustierte Mittelwerte mit 95%-Konfidenzintervallen", ///
        size($axis_title_size)) ///
    xtitle("") ///
    ytitle("Beratungsfälle pro beratender Person und Woche", ///
        size(small)) ///
    xlabel(0 "Wochen ohne Lateris (C)" ///
           1 "Wochen mit Lateris (T)", ///
        labsize(medlarge) ///
        noticks) ///
    ylabel(8(2)16, ///
        labsize(medium) ///
        nogrid ///
        angle(horizontal)) ///
    xscale( ///
        range(-0.5 1.5) ///
        lwidth(thick)) ///
    yscale( ///
        range(8 16) ///
        lwidth(thick)) ///
    plotregion(margin(l=4 r=4 b=2 t=2)) ///
    graphregion(margin(l=3 r=3 b=3 t=3)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_b_main_case_volume_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 03. Impact on Other AI Use
****************************************************************************

* Estimate the ITT effect of access to Lateris on the probability
* of using AI tools other than Lateris during a consultation.
*
* The linear probability model includes counsellor and project-week
* fixed effects. Standard errors are clustered at the counsellor-week
* level, corresponding to the unit of randomization.

reg other_ai_yes ///
    i.treatment ///
    i.counselor_num ///
    i.project_week ///
    if analysis_sample == 1, ///
    vce(cluster counselor_week)

estimates store m_other_ai


*--------------------------------------------------------------------------
* 03a. Descriptive Shares of Other AI Use
*--------------------------------------------------------------------------

* Report the observed shares and sample sizes by treatment assignment
* within the regression sample.

tab treatment other_ai_yes if e(sample), row

preserve

* Restrict the descriptive analysis to the regression sample.

keep if e(sample)

* Calculate the unadjusted share of consultations using other AI
* tools in each treatment group.

collapse (mean) other_ai_yes, by(treatment)

replace other_ai_yes = other_ai_yes * 100

* Create percentage labels for the graph.

gen label = string(other_ai_yes, "%4.1f") + "%"


*--------------------------------------------------------------------------
* 03b. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (bar other_ai_yes treatment if treatment == 0, ///
        barwidth(0.75) ///
        color($col_total%75) ///
        lcolor(none)) ///
    (bar other_ai_yes treatment if treatment == 1, ///
        barwidth(0.75) ///
        color($col_total%75) ///
        lcolor(none)) ///
    (scatter other_ai_yes treatment, ///
        msymbol(none) ///
        mlabel(label) ///
        mlabposition(12) ///
        mlabsize(medium) ///
        mlabcolor(black)), ///
    title("Use of AI Tools Outside Lateris", ///
        size(medium)) ///
    subtitle("Share of consultations using an AI tool other than Lateris", ///
        size(medium)) ///
    xtitle("") ///
    xlabel(0 "Control" ///
           1 "Treatment", ///
        labsize(medium) ///
        noticks ///
        nogrid) ///
    ytitle("Consultations using other AI (%)", ///
        size(medium)) ///
    ylabel(0(10)40, ///
        labsize(medium) ///
        nogrid ///
        angle(horizontal)) ///
    yscale(range(0 45)) ///
    xscale(range(-0.7 1.7)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_c_main_other_ai_use.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 03c. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (bar other_ai_yes treatment if treatment == 0, ///
        barwidth(0.75) ///
        color($col_total%75) ///
        lcolor(none)) ///
    (bar other_ai_yes treatment if treatment == 1, ///
        barwidth(0.75) ///
        color($col_total%75) ///
        lcolor(none)) ///
    (scatter other_ai_yes treatment, ///
        msymbol(none) ///
        mlabel(label) ///
        mlabposition(12) ///
        mlabsize(medium) ///
        mlabcolor(black)), ///
    title("Nutzung anderer KI-Tools", ///
        size(medium)) ///
    subtitle("Anteil der Beratungen mit KI-Tools außerhalb von Lateris", ///
        size(medium)) ///
    xtitle("") ///
    xlabel(0 "Wochen ohne Lateris (C)" ///
           1 "Wochen mit Lateris (T)", ///
        labsize(medium) ///
        noticks ///
        nogrid) ///
    ytitle("Beratungen mit anderen KI-Tools (%)", ///
        size(medium)) ///
    ylabel(0(10)40, ///
        labsize(medium) ///
        nogrid ///
        angle(horizontal)) ///
    yscale(range(0 45)) ///
    xscale(range(-0.7 1.7)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_c_main_other_ai_use_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 04. Reported Reasons for Other AI Use
****************************************************************************

preserve

* Restrict the sample to consultations in which other AI tools
* were used and at least one reason for their use was reported.

keep if analysis_sample == 1
keep if other_ai_yes == 1
keep if !missing(treatment)
keep if !missing(ai_usage_reason) ///
    & trim(ai_usage_reason) != ""


*--------------------------------------------------------------------------
* 04a. Define Denominator
*--------------------------------------------------------------------------

* Each consultation may have multiple reported reasons.
* Percentages are calculated relative to the number of consultations
* with at least one reported reason within each treatment group.

gen obs_id = _n

bysort treatment: gen n_cases = _N

count if treatment == 0
local n_control = r(N)

count if treatment == 1
local n_lateris = r(N)


*--------------------------------------------------------------------------
* 04b. Prepare Multiple-Response Data
*--------------------------------------------------------------------------

* Separate multiple reasons reported within the same consultation.

split ai_usage_reason, ///
    parse(" + ") ///
    gen(reason_)

reshape long reason_, ///
    i(obs_id) ///
    j(reason_number)

replace reason_ = strtrim(reason_)

drop if missing(reason_) | reason_ == ""

* Count reported reasons by treatment assignment.

gen one_mention = 1

collapse ///
    (sum) total_mentions = one_mention ///
    (first) n_cases, ///
    by(treatment reason_)

* Calculate the share of consultations reporting each reason.
* Percentages may sum to more than 100% due to multiple responses.

gen percent = 100 * total_mentions / n_cases

format percent %4.1f

sort treatment reason_

list treatment reason_ total_mentions n_cases percent, ///
    sepby(treatment) noobs


*--------------------------------------------------------------------------
* 04c. Prepare Data for Graph
*--------------------------------------------------------------------------

* Define a consistent order of reasons across treatment groups.

gen reason_order = .

replace reason_order = 1 if reason_ == "Translation"
replace reason_order = 2 if reason_ == "Information Synthesis"
replace reason_order = 3 if reason_ == "Faster Response"
replace reason_order = 4 if reason_ == "Source Support"
replace reason_order = 5 if reason_ == "Other"

* Verify that all reported reasons have been classified.

assert !missing(reason_order)

label define reason_order_lbl ///
    1 "Translation" ///
    2 "Information Synthesis" ///
    3 "Faster Response" ///
    4 "Source Support" ///
    5 "Other", replace

label values reason_order reason_order_lbl

* Reshape to one observation per reason.

keep reason_order treatment percent

reshape wide percent, ///
    i(reason_order) ///
    j(treatment)

rename percent0 percent_control
rename percent1 percent_lateris

* Assign zero where a reason was not reported in a treatment group.

replace percent_control = 0 if missing(percent_control)
replace percent_lateris = 0 if missing(percent_lateris)

* Define positions for the two side-by-side panels.

gen control_start = 0
gen control_end   = percent_control

gen lateris_start = 125
gen lateris_end   = 125 + percent_lateris

* Create percentage labels.

gen label_control = string(percent_control, "%3.0f") + "%"
gen label_lateris = string(percent_lateris, "%3.0f") + "%"


*--------------------------------------------------------------------------
* 04d. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (rbar control_start control_end reason_order, ///
        horizontal ///
        barwidth(.60) ///
        color($col_total%85) ///
        lcolor(none)) ///
    (scatter reason_order control_end, ///
        msymbol(none) ///
        mlabel(label_control) ///
        mlabposition(3) ///
        mlabsize(medium) ///
        mlabcolor(black)) ///
    (rbar lateris_start lateris_end reason_order, ///
        horizontal ///
        barwidth(.60) ///
        color($col_total%85) ///
        lcolor(none)) ///
    (scatter reason_order lateris_end, ///
        msymbol(none) ///
        mlabel(label_lateris) ///
        mlabposition(3) ///
        mlabsize(medium) ///
        mlabcolor(black)), ///
    title("Reported Reasons for Using AI Tools Outside Lateris", ///
        $title_style) ///
    text(.45 50 "Control weeks (n=`n_control')", ///
        size(medium) color(black)) ///
    text(.45 175 "Lateris weeks (n=`n_lateris')", ///
        size(medium) color(black)) ///
    ylabel( ///
        1 "Translation" ///
        2 "Information Synthesis" ///
        3 "Faster Response" ///
        4 "Source Support" ///
        5 "Other", ///
        labsize($axis_label_size) ///
        nogrid ///
        angle(horizontal) ///
        noticks) ///
    xlabel(none) ///
    xtitle("") ///
    xscale(range(0 230) off) ///
    yscale(range(.15 5.35) reverse) ///
    ytitle("") ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_d_main_other_ai_usage_reason_grouped.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 04e. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (rbar control_start control_end reason_order, ///
        horizontal ///
        barwidth(.60) ///
        color($col_total%85) ///
        lcolor(none)) ///
    (scatter reason_order control_end, ///
        msymbol(none) ///
        mlabel(label_control) ///
        mlabposition(3) ///
        mlabsize(medium) ///
        mlabcolor(black)) ///
    (rbar lateris_start lateris_end reason_order, ///
        horizontal ///
        barwidth(.60) ///
        color($col_total%85) ///
        lcolor(none)) ///
    (scatter reason_order lateris_end, ///
        msymbol(none) ///
        mlabel(label_lateris) ///
        mlabposition(3) ///
        mlabsize(medium) ///
        mlabcolor(black)), ///
    title("Gründe für die Nutzung anderer KI-Tools", ///
        $title_style) ///
    text(.45 50 "Wochen ohne Lateris (n=`n_control')", ///
        size(medium) color(black)) ///
    text(.45 175 "Lateris-Wochen (n=`n_lateris')", ///
        size(medium) color(black)) ///
    ylabel( ///
        1 "Übersetzung" ///
        2 "Informationsaufbereitung" ///
        3 "Schnellere Bearbeitung" ///
        4 "Quellenrecherche" ///
        5 "Sonstiges", ///
        labsize($axis_label_size) ///
        nogrid ///
        angle(horizontal) ///
        noticks) ///
    xlabel(none) ///
    xtitle("") ///
    xscale(range(0 230) off) ///
    yscale(range(.15 5.35) reverse) ///
    ytitle("") ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_d_main_other_ai_usage_reason_grouped_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 05. Treatment Effects by Project Week
****************************************************************************

preserve

keep if analysis_sample == 1

* Examine whether the effect of access to Lateris on consultation
* duration varies across project weeks.
*
* The model interacts treatment assignment with project week
* and includes counsellor fixed effects.
* Standard errors are clustered at the counsellor-week level.

reg consultation_duration_min ///
    i.treatment##i.project_week ///
    i.counselor_num, ///
    vce(cluster counselor_week)

estimates store m_project_week


*--------------------------------------------------------------------------
* 05a. Test for Variation in Treatment Effects
*--------------------------------------------------------------------------

* Joint test of whether treatment effects differ across project weeks.

testparm 1.treatment#i.project_week


*--------------------------------------------------------------------------
* 05b. Estimate Weekly Treatment Effects
*--------------------------------------------------------------------------

* Estimate the treatment effect separately for each project week.

margins project_week, dydx(treatment)


*--------------------------------------------------------------------------
* 05c. Graph - English Version
*--------------------------------------------------------------------------

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_russian%75) ///
        msymbol(circle) ///
        msize(medlarge)) ///
    ciopts( ///
        lcolor($col_russian%55) ///
        lwidth(medthick)) ///
    yline(0, ///
        lcolor(gs8) ///
        lpattern(dash) ///
        lwidth(thin)) ///
    title("Treatment Effect by Project Week", $title_style) ///
    subtitle("Estimated Lateris effect with 95% confidence intervals", ///
        size($axis_title_size)) ///
    xtitle("Project Week", ///
        size($axis_title_size)) ///
    ytitle("Effect on Consultation Duration (Minutes)", ///
        size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(-15(5)10, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(-15 10)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_e_treatment_effect_by_project_week.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 05d. Graph - German Version 
*--------------------------------------------------------------------------

/*

marginsplot, ///
    recast(scatter) ///
    recastci(rcap) ///
    plotopts( ///
        mcolor($col_russian%75) ///
        msymbol(circle) ///
        msize(medlarge)) ///
    ciopts( ///
        lcolor($col_russian%55) ///
        lwidth(medthick)) ///
    yline(0, ///
        lcolor(gs8) ///
        lpattern(dash) ///
        lwidth(thin)) ///
    title("Lateris-Effekt nach Projektwoche", $title_style) ///
    subtitle("Geschätzter Lateris-Effekt mit 95%-Konfidenzintervallen", ///
        size($axis_title_size)) ///
    xtitle("Projektwoche", ///
        size($axis_title_size)) ///
    ytitle("Effekt auf die Beratungsdauer (Minuten)", ///
        size($axis_title_size)) ///
    xlabel(1(1)20, ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(-15(5)10, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(-15 10)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_e_treatment_effect_by_project_week_DE.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 06. Lagged Treatment and Carryover Effects
****************************************************************************

preserve

keep if analysis_sample == 1

* Examine whether access to Lateris in the previous project week
* affects consultation duration in the current week.
*
* The model interacts current and previous treatment assignment
* and includes counsellor and project-week fixed effects.
* Standard errors are clustered at the counsellor-week level.

reg consultation_duration_min ///
    i.treatment##i.lag_treatment ///
    i.counselor_num ///
    i.project_week, ///
    vce(cluster counselor_week)

estimates store m_carryover


*--------------------------------------------------------------------------
* 06a. Adjusted Means by Treatment Sequence
*--------------------------------------------------------------------------

* Estimate adjusted mean consultation duration for the four
* possible combinations of previous and current treatment assignment.
*
* Previous week -> Current week:
* Control       -> Control
* Control       -> Treatment
* Treatment     -> Control
* Treatment     -> Treatment

tempfile lagged_margins

margins lag_treatment#treatment, ///
    saving(`lagged_margins', replace)


*--------------------------------------------------------------------------
* 06b. Estimate Carryover Effects
*--------------------------------------------------------------------------

* Estimate the effect of previous treatment assignment separately
* for current control and current treatment weeks.

margins, dydx(lag_treatment) ///
    at(treatment=(0 1))


*--------------------------------------------------------------------------
* 06c. Prepare Data for Graph
*--------------------------------------------------------------------------

use `lagged_margins', clear

rename _m1 lag_treatment
rename _m2 treatment

* Define positions for the four treatment sequences.
* Leave a gap between the two previous-assignment groups.

gen xpos = .

replace xpos = 1 if lag_treatment == 0 & treatment == 0
replace xpos = 2 if lag_treatment == 0 & treatment == 1
replace xpos = 4 if lag_treatment == 1 & treatment == 0
replace xpos = 5 if lag_treatment == 1 & treatment == 1


*--------------------------------------------------------------------------
* 06d. Graph - English Version
*--------------------------------------------------------------------------

twoway ///
    (bar _margin xpos if xpos == 1, ///
        barwidth(.7) ///
        color($col_total%75) ///
        lcolor($col_total)) ///
    (bar _margin xpos if xpos == 2, ///
        barwidth(.7) ///
        color($col_total%25) ///
        lcolor($col_total) ///
        lpattern(dash)) ///
    (bar _margin xpos if xpos == 4, ///
        barwidth(.7) ///
        color($col_russian%75) ///
        lcolor($col_russian)) ///
    (bar _margin xpos if xpos == 5, ///
        barwidth(.7) ///
        color($col_russian%25) ///
        lcolor($col_russian) ///
        lpattern(dash)) ///
    (rcap _ci_lb _ci_ub xpos, ///
        lcolor(gs3) ///
        lwidth(medthick)), ///
    xline(3, ///
        lcolor(gs10) ///
        lwidth(thin)) ///
    xlabel( ///
        1 "Control" ///
        2 "Treatment" ///
        4 "Control" ///
        5 "Treatment", ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(14(2)25, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(14 25)) ///
    text(24 1.5 "Previous week: Control", ///
        size($axis_label_size)) ///
    text(24 4.5 "Previous week: Treatment", ///
        size($axis_label_size)) ///
    title("Consultation Duration by Treatment Sequence", ///
        $title_style) ///
    subtitle("Adjusted means with 95% confidence intervals", ///
        size($axis_title_size)) ///
    xtitle("Current Assignment", ///
        size($axis_title_size)) ///
    ytitle("Consultation Duration (Minutes)", ///
        size($axis_title_size)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_f_lagged_treatment_sequences_bar.svg", ///
    replace width($export_w) height($export_h)


*--------------------------------------------------------------------------
* 06e. Graph - German Version 
*--------------------------------------------------------------------------

/*

twoway ///
    (bar _margin xpos if xpos == 1, ///
        barwidth(.7) ///
        color($col_total%75) ///
        lcolor($col_total)) ///
    (bar _margin xpos if xpos == 2, ///
        barwidth(.7) ///
        color($col_total%25) ///
        lcolor($col_total) ///
        lpattern(dash)) ///
    (bar _margin xpos if xpos == 4, ///
        barwidth(.7) ///
        color($col_russian%75) ///
        lcolor($col_russian)) ///
    (bar _margin xpos if xpos == 5, ///
        barwidth(.7) ///
        color($col_russian%25) ///
        lcolor($col_russian) ///
        lpattern(dash)) ///
    (rcap _ci_lb _ci_ub xpos, ///
        lcolor(gs3) ///
        lwidth(medthick)), ///
    xline(3, ///
        lcolor(gs10) ///
        lwidth(thin)) ///
    xlabel( ///
        1 "Ohne Lateris" ///
        2 "Mit Lateris" ///
        4 "Ohne Lateris" ///
        5 "Mit Lateris", ///
        labsize($axis_label_size) ///
        nogrid) ///
    ylabel(14(2)25, ///
        labsize($axis_label_size) ///
        nogrid) ///
    yscale(range(14 25)) ///
    text(24 1.5 "Vorwoche: Ohne Lateris", ///
        size($axis_label_size)) ///
    text(24 4.5 "Vorwoche: Mit Lateris", ///
        size($axis_label_size)) ///
    title("Beratungsdauer nach Lateris-Zuweisung", ///
        $title_style) ///
    subtitle("Adjustierte Mittelwerte mit 95%-Konfidenzintervallen", ///
        size($axis_title_size)) ///
    xtitle("Zuweisung in der aktuellen Woche", ///
        size($axis_title_size)) ///
    ytitle("Beratungsdauer (Minuten)", ///
        size($axis_title_size)) ///
    legend(off) ///
    $graph_style

graph export ///
    "${impact}/Graphs/02_f_lagged_treatment_sequences_bar_german.svg", ///
    replace width($export_w) height($export_h)

*/

restore

****************************************************************************
**# 07. End of Analysis
****************************************************************************

display as text ///
    "05_main_analysis.do completed successfully."

****************************************************************************
* End of do-file
****************************************************************************