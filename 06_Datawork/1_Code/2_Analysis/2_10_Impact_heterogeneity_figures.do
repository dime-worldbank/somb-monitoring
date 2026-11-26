/*************************************************************************
 *************************************************************************
				Social Media Bridge (SoMB) - Germany

1) Created by: 	Daniel Márquez
				DIME - World Bank
				dmarquezmuskus@worldbank.org

2) Date: 		September 2026

3) Objective: 	NBER-style forest plots of subgroup ITT effects of the
				randomized Lateris assignment. One figure per outcome,
				built by hand with twoway. Structure follows the Peru
				CBT IE forest plots

4) Output:		- 3_Output/Impact/Graphs/forest_plot_*.png
				- 3_Output/Impact/Tables/heterogeneity_estimates.xlsx
				- 2_Data/2_Analysis/SoMB_WB_hte_estimates.dta

5) Method:		Each row is its own regression on that subsample:
					reg outcome treatment i.counselor_num i.project_week ///
						[if subgroup], vce(cluster counselor_week)
				b = _b[treatment], CI = b +/- 1.96*se.
				Two panels drop fixed effects that would absorb the
				treatment: the counsellor panel drops both (inside one
				counsellor, treatment is a function of the week) and the
				phase panel drops the week effects (phase is calendar
				time). See get_subgroup_stats

6) Stars:		Test each subgroup against the BASE category of its own
				block, not against zero. Subgroups within a block never
				overlap, so this is the z-test for the difference of two
				independent coefficients:
					z = (b_sub - b_base) / sqrt(se_base^2 + se_sub^2)
				The base row never gets stars

7) Notes:		- Complexity is rated by the counsellor and may respond to
				  Lateris: read that block as descriptive
				- Translation enters only if it is recorded for control
				  cases too, otherwise the block is dropped
				- SEs are optimistic with 5 counsellors. Confirm anything
				  that matters with randomization inference

*************************************************************************
*************************************************************************/

clear all
set more off


****************************************************************************
**# 				1. Parameters
****************************************************************************

local scratch_dir "${analysis}\forest_scratch"
cap mkdir "`scratch_dir'"
cap mkdir "${impact}\Graphs"
cap mkdir "${impact}\Tables"

* Outcome variables and the axis label each one gets
local outcomes ///
    consultation_duration_min ///
    form_duration_min ///
    referral_yes ///
    feedback_received_yes


****************************************************************************
**# 				2. Helper: load data and build the subgroups
****************************************************************************

* Called again before every outcome: draw_forest replaces the data in
* memory with the small plotting dataset.

cap program drop prep_data
program define prep_data

    use "${processing}/SoMB_WB_analysis.dta", clear
    keep if analysis_sample == 1

    * Respondent gender. Base: male.
    cap drop gender_binary
    gen gender_binary = .
    replace gender_binary = 0 if gender == "Male"
    replace gender_binary = 1 if gender == "Female"

  
    * Implementation phase. Base: weeks 1-10.
    cap drop late_phase
    gen late_phase = .
    replace late_phase = 0 if inrange(project_week,  1, 10)
    replace late_phase = 1 if inrange(project_week, 11, 20)

end


****************************************************************************
**# 				3. Helper: full-sample effect (dashed line)
****************************************************************************

cap program drop get_full_sample_b
program define get_full_sample_b, rclass
    args outcome

    qui reg `outcome' treatment i.counselor_num i.project_week, ///
        vce(cluster counselor_week)
    return scalar b = _b[treatment]
end


****************************************************************************
**# 				4. Helper: one subgroup regression
****************************************************************************

* fespec carries the fixed effects for this cell, so the two panels that
* cannot keep them pass a shorter string. Kept separate from post_row so
* the same b/se pair feeds both the plotted CI and the significance test.

cap program drop get_subgroup_stats
program define get_subgroup_stats, rclass
    args outcome ifcond fespec

    cap reg `outcome' treatment `fespec' if `ifcond', ///
        vce(cluster counselor_week)

    if (_rc != 0 | missing(e(N)) | e(N) < 30) {
        di as error "  skipped: `outcome' if `ifcond' (rc=" _rc ")"
        return scalar b  = .
        return scalar se = .
        return scalar n  = .
        exit
    }
    return scalar b  = _b[treatment]
    return scalar se = _se[treatment]
    return scalar n  = e(N)
end


****************************************************************************
**# 				5. Helper: star for one non-base subgroup
****************************************************************************

cap program drop get_stars_indep
program define get_stars_indep, rclass
    args b_base se_base b_sub se_sub

    if missing(`b_base') | missing(`b_sub') {
        return local stars ""
        exit
    }

    local se_diff = sqrt(`se_base'^2 + `se_sub'^2)
    local z       = (`b_sub' - `b_base') / `se_diff'
    local pval    = 2*(1 - normal(abs(`z')))

    if `pval' <= 0.01           return local stars "***"
    else if `pval' <= 0.05      return local stars "**"
    else if `pval' <= 0.10      return local stars "*"
    else                        return local stars ""
end


****************************************************************************
**# 				6. Helper: post one row
****************************************************************************

cap program drop post_row
program define post_row
    args grouplabel sublabel n b se order0 stars postname

    if missing(`b') {
        post `postname' ("`grouplabel'") ("`sublabel'") (.) (.) (.) (.) ///
            (`order0') ("`stars'")
        exit
    }

    local lo = `b' - 1.959964*`se'
    local hi = `b' + 1.959964*`se'

    post `postname' ("`grouplabel'") ("`sublabel'") (`n') (`b') (`lo') (`hi') ///
        (`order0') ("`stars'")
end


****************************************************************************
**# 				7. Build: assemble the results for one outcome
****************************************************************************

cap program drop build_forest_data
program define build_forest_data
    args outcome dtapath

    local fe_full  "i.counselor_num i.project_week"
    local fe_cnsl  ""
    local fe_phase "i.counselor_num"

    tempname ph
    postfile `ph' str40 group str46 subgroup n double b double lo double hi ///
        double order str10 stars using "`dtapath'", replace

    local k = 0

    * ------------------------------------------------------------------
    * d1: counsellor. No fixed effects: the counsellor is constant in
    * the cell and treatment is a function of the week, so i.project_week
    * would absorb it. counselor_num is the encoded counselor_id, A=1..E=5,
    * which keeps quotes out of the if-condition passed through args.
    * Base: counsellor A.
    * 
    * get_subgroup_stats and get_stars_indep are both rclass, so each call
    * replaces the previous r(). Every returned value is copied into a
    * local straight away, before the next call runs.
    * ------------------------------------------------------------------
    get_subgroup_stats `outcome' "counselor_num==1" "`fe_cnsl'"
    local b0 = r(b)
    local se0 = r(se)
    local n0 = r(n)
    local ++k
    post_row "Counsellor" "A - Russian / Ukrainian" `n0' `b0' `se0' `k' "" `ph'

    get_subgroup_stats `outcome' "counselor_num==2" "`fe_cnsl'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Counsellor" "B - Arabic" `n1' `b1' `se1' `k' "`st'" `ph'

    get_subgroup_stats `outcome' "counselor_num==3" "`fe_cnsl'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Counsellor" "C - Persian" `n1' `b1' `se1' `k' "`st'" `ph'

    get_subgroup_stats `outcome' "counselor_num==4" "`fe_cnsl'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Counsellor" "D - Turkish" `n1' `b1' `se1' `k' "`st'" `ph'

    get_subgroup_stats `outcome' "counselor_num==5" "`fe_cnsl'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Counsellor" "E - French" `n1' `b1' `se1' `k' "`st'" `ph'

    * ------------------------------------------------------------------
    * d2: respondent gender. Base: male.
    * ------------------------------------------------------------------
    get_subgroup_stats `outcome' "gender_binary==0" "`fe_full'"
    local b0 = r(b)
    local se0 = r(se)
    local n0 = r(n)
    local ++k
    post_row "Gender" "Male" `n0' `b0' `se0' `k' "" `ph'

    get_subgroup_stats `outcome' "gender_binary==1" "`fe_full'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Gender" "Female" `n1' `b1' `se1' `k' "`st'" `ph'


 

    * ------------------------------------------------------------------
    * d6: implementation phase. Base: weeks 1-10. The week fixed
    * effects come out, since phase is itself a split on calendar time.
    * ------------------------------------------------------------------
    get_subgroup_stats `outcome' "late_phase==0" "`fe_phase'"
    local b0 = r(b)
    local se0 = r(se)
    local n0 = r(n)
    local ++k
    post_row "Implementation phase" "Weeks 1-10" `n0' `b0' `se0' `k' "" `ph'

    get_subgroup_stats `outcome' "late_phase==1" "`fe_phase'"
    local b1 = r(b)
    local se1 = r(se)
    local n1 = r(n)
    get_stars_indep `b0' `se0' `b1' `se1'
    local st = "`r(stars)'"
    local ++k
    post_row "Implementation phase" "Weeks 11-20" `n1' `b1' `se1' `k' "`st'" `ph'

  
   postclose `ph'
end

****************************************************************************
**# 				8. Draw: forest plot renderer
****************************************************************************

cap program drop draw_forest
program define draw_forest
    args dtapath xtitle_lab full_sample_b output_path output_name note1 note2

    use "`dtapath'", clear
    drop if missing(b)
    sort order

    local txtsize  "vsmall"
    local notesize "tiny"

    local N = _N

    gen double yorder = .
    local text_labels `""'
    local text_n      `""'
    local text_ci     `""'

    * Horizontal geometry: the plot occupies the middle, the label column
    * sits to its left and the estimate column to its right, all placed in
    * data units on a widened x axis with no visible frame.
    qui su lo
    local data_min = min(r(min), 0)
    qui su hi
    local data_max = max(r(max), 0)
    local data_range = `data_max' - `data_min'

    local plot_min = `data_min' - 0.15*`data_range'
    local plot_max = `data_max' + 0.15*`data_range'

    local x_label = `plot_min' - 1.05*`data_range'
    local x_n     = `plot_min' - 0.22*`data_range'
    * The estimate column clears the zero line by a wide margin, so the
    * two never collide when the effects sit far from zero.
    local x_ci    = `plot_max' + 0.42*`data_range'

    local axis_min = `x_label' - 0.10*`data_range'
    local axis_max = `x_ci'    + 0.80*`data_range'

    * Round tick spacing to a 1/2/5 step
    local rawstep = `data_range' / 4
    local pexp  = floor(log10(`rawstep'))
    local pbase = 10^`pexp'
    local pmant = `rawstep' / `pbase'
    if `pmant' < 1.5           local nicestep = 1 * `pbase'
    else if `pmant' < 3.5      local nicestep = 2 * `pbase'
    else if `pmant' < 7.5      local nicestep = 5 * `pbase'
    else                       local nicestep = 10 * `pbase'

    * Zero always stays on the axis: it is the null each interval is
    * being read against.
    local tick_lo = min(floor(`data_min' / `nicestep') * `nicestep', 0)
    local tick_hi = max(ceil(`data_max'  / `nicestep') * `nicestep', 0)

    * Column headers
    local vr = 1
    local hdr_y = -`vr'
    local text_labels `"`text_labels' text(`hdr_y' `x_label' "{bf:Subgroup}", justification(left) size(`txtsize') color(black))"'
    local text_n      `"`text_n' text(`hdr_y' `x_n' "{bf:N}", justification(right) size(`txtsize') color(black))"'
    local text_ci     `"`text_ci' text(`hdr_y' `x_ci' "{bf:Effect (95% CI)}", justification(left) size(`txtsize') color(black))"'

    local prev_group `""'

    * One blank line under the column headers
    local vr = `vr' + 1

    forvalues i = 1/`N' {

        local this_group = group[`i']

        * Blank line between blocks, then the block header
        if (`"`this_group'"' != `"`prev_group'"') {
            if (`i' > 1) local vr = `vr' + 1
            local vr = `vr' + 1
            local hdr_y = -`vr'
            local text_labels `"`text_labels' text(`hdr_y' `x_label' "{bf:`this_group'}", justification(left) size(`txtsize') color(black))"'
        }

        local vr = `vr' + 1
        local row_y = -`vr'
        qui replace yorder = `row_y' in `i'

        local sg = subgroup[`i']
        local text_labels `"`text_labels' text(`row_y' `x_label' "   `sg'", justification(left) size(`txtsize') color(black))"'

        local nval = n[`i']
        local text_n `"`text_n' text(`row_y' `x_n' "`nval'", justification(right) size(`txtsize') color(black))"'

        local bval  = strtrim(string(b[`i'],  "%6.3f"))
        local loval = strtrim(string(lo[`i'], "%6.3f"))
        local hival = strtrim(string(hi[`i'], "%6.3f"))
        local st    = stars[`i']
        local text_ci `"`text_ci' text(`row_y' `x_ci' "`bval' (`loval', `hival') `st'", justification(left) size(`txtsize') color(black))"'

        local prev_group `"`this_group'"'
    }

    local ymax_axis = 0
    local ymin_axis = -`vr' - 1

    * CI and point estimate in one blue; the full-sample effect as a
    * lighter dashed line so it reads as sitting behind the rows; zero
    * as a plain grey rule.
    twoway ///
        (rcap lo hi yorder, horizontal lcolor(ebblue) lwidth(medium)) ///
        (scatter yorder b, msymbol(square) mcolor(ebblue) msize(small)) ///
        , ///
        `text_labels' `text_n' `text_ci' ///
        xline(0, lcolor(gs8) lpattern(solid) lwidth(thin)) ///
        xline(`full_sample_b', lcolor(ebblue%55) lpattern(dash) lwidth(medthin)) ///
        xscale(range(`axis_min' `axis_max') noline) ///
        xlabel(`tick_lo'(`nicestep')`tick_hi', labsize(`txtsize') notick nogrid) ///
        xtitle("`xtitle_lab'", size(`txtsize')) ///
        yscale(range(`ymin_axis' `ymax_axis') noline) ///
        ylabel(, nolabels noticks nogrid) ///
        ytitle("") ///
        legend(off) ///
        graphregion(color(white) lcolor(white) lwidth(none) margin(l=8)) ///
        plotregion(color(white) lcolor(white) lwidth(none) margin(zero)) ///
        note("`note1'" "`note2'", size(`notesize') color(gs7) span) ///
        name(forest_plot, replace)

    graph export "`output_path'/`output_name'.png", ///
        replace width(3000) height(2400)

    di as result _newline "Saved: `output_path'/`output_name'.png"
end



****************************************************************************
**# 				10. One forest plot per outcome
****************************************************************************

local note1 "Notes: Subgroup-specific treatment effects. Standard errors clustered at the counsellor-week randomization unit."
local note2 "Dashed line: full-sample treatment effect. Solid line: zero. Formal interaction tests are reported separately."


foreach y of local outcomes {

    if "`y'" == "consultation_duration_min" ///
        local xlab "Effect on consultation duration (minutes)"
    if "`y'" == "form_duration_min" ///
        local xlab "Effect on form completion time (minutes)"
    if "`y'" == "referral_yes" ///
        local xlab "Effect on probability a referral was provided"
    if "`y'" == "feedback_received_yes" ///
        local xlab "Effect on probability feedback was received"

    di as text _n "{hline 70}"
    di as text "Forest plot: `y'"
    di as text "{hline 70}"

    local dta "`scratch_dir'/forest_data_`y'.dta"

    prep_data
    build_forest_data `y' "`dta'"

    prep_data
    get_full_sample_b `y'
    local full_b = r(b)

    draw_forest "`dta'" "`xlab'" `full_b' ///
        "${impact}/Graphs" "forest_plot_`y'" "`note1'" "`note2'"
}


****************************************************************************
**# 				11. Keep the numbers behind the figures
****************************************************************************

clear
tempfile allest
local first = 1

foreach y of local outcomes {
    preserve
        qui use "`scratch_dir'/forest_data_`y'.dta", clear
        qui gen str32 outcome = "`y'"
        if `first' == 1 qui save `allest', replace
        else {
            qui append using `allest'
            qui save `allest', replace
        }
    restore
    local first = 0
}

use `allest', clear
order outcome group subgroup n b lo hi stars order
sort outcome order
drop order
compress
save "${analysis}/SoMB_WB_hte_estimates.dta", replace

local sheetn = 0
foreach y of local outcomes {
    preserve
        keep if outcome == "`y'"
        drop outcome
        local ++sheetn
        if `sheetn' == 1 local opt "replace"
        else             local opt "sheetreplace"
        export excel using "${impact}/Tables/heterogeneity_estimates.xlsx", ///
            sheet("`y'") firstrow(variables) `opt'
    restore
}


****************************************************************************
**# 				12. Formal tests of effect heterogeneity
****************************************************************************

* The forest plot shows whether subgroup intervals overlap, which is not a
* test. These interaction tests are the ones to quote.

prep_data

foreach y in consultation_duration_min form_duration_min {

    di as text _n "{hline 70}"
    di as text "Tests of effect heterogeneity: `y'"
    di as text "{hline 70}"


    *------------------------------------------------------------
    * Counsellor / language
    *------------------------------------------------------------
    qui reg `y' i.treatment##i.counselor_num i.project_week, ///
        vce(cluster counselor_week)

    di as text _n "Treatment x counsellor"
    testparm 1.treatment#i.counselor_num


    *------------------------------------------------------------
    * Gender
    *------------------------------------------------------------
    qui reg `y' i.treatment##i.gender_binary ///
        i.counselor_num i.project_week ///
        if !missing(gender_binary), ///
        vce(cluster counselor_week)

    di as text _n "Treatment x gender"
    testparm 1.treatment#i.gender_binary


    *------------------------------------------------------------
    * Implementation phase
    *------------------------------------------------------------
    qui reg `y' i.treatment##i.late_phase i.counselor_num ///
        if !missing(late_phase), ///
        vce(cluster counselor_week)

    di as text _n "Treatment x implementation phase"
    testparm 1.treatment#i.late_phase

}

di as text _n "2_10_Impact_heterogeneity_figures.do completed successfully."
