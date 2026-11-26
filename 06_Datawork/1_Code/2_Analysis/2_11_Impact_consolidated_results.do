/*************************************************************************
 *************************************************************************
				Social Media Bridge (SoMB) - Germany

1) Created by: 	Daniel Marquez
				DIME - World Bank
				dmarquezmuskus@worldbank.org

2) Reviewed by:

3) Date: 		Created  September 2026

4) Objective: 	Consolidate the main ITT results across every combination
				of fixed effects and clustering, export them to one
				workbook, and draw a standardized forest plot.

				The file has three independent blocks:

				  A. Estimate every specification once and post all the
				     inputs to a single results dataset.
				  B. Read that dataset and write the 9 Excel sheets.
				  C. Read that dataset and draw the figure.

				Blocks B and C never re-estimate anything, so changing the
				table layout or the figure does not require rerunning the
				regressions.

5) Output:		- ${analysis}/results_consolidated.dta
				- ${impact}/Tables/results_consolidate.xlsx
				     9 sheets FE_<fe>_cl_<cl>, plus one sheet with the
				     numbers behind the figure
				- ${impact}/Graphs/forest_main_standardized.png

6) Notes:		- "Cluster: both" means the counsellor-week cell
				  (counselor_week), which is the randomization unit. It is
				  not two-way clustering.

				- Standardized effects are b/sd(y), with sd taken on each
				  estimation sample. That is algebraically identical to
				  regressing the standardized outcome, so block C needs no
				  second set of regressions.

				- Cluster: counsellor has 5 clusters. Those standard
				  errors are not trustworthy on their own. Confirm
				  anything that matters with boottest or with
				  randomization inference.

				- Five of the seven outcomes are binary, so their
				  "standard deviation" is that of a Bernoulli. Read the
				  forest plot with that in mind.

				- case_volume is excluded on purpose: it is defined at
				  counsellor-week level and would not share the sample of
				  the other rows. It stays in 2_6.

				- Runtime is a few minutes. putexcel writes the workbook
				  to disk on every cell, and this file writes about 1,400
				  of them. The regressions themselves take seconds.

*************************************************************************
*************************************************************************/

clear all
set more off


****************************************************************************
**# 				1. Parameters
****************************************************************************

* Every case-level dependent variable estimated in 2_6 and 2_7
local outcomes ///
    consultation_duration_min ///
    form_duration_min ///
    referral_yes ///
    feedback_received_yes ///
    has_detailed_feedback ///
    lateris_yes ///
    other_ai_yes

* Standard errors used in the two "no cluster" columns.
* Empty means classical OLS standard errors, so those columns isolate what
* clustering alone does. Set to "robust" to contrast robust against
* clustered instead.
local nocluster_vce ""

* The three fixed-effect and the three clustering options
local fe_opts "week consul both"
local cl_opts "week consul both"

local results_dta "${analysis}/results_consolidated.dta"
local xlsx        "${impact}/Tables/results_consolidate.xlsx"
local graph_out   "${impact}/Graphs"

cap mkdir "${impact}/Tables"
cap mkdir "${impact}/Graphs"

local dfmt "%9.3f"


****************************************************************************
**# 				2. Load data and verify the analysis variables
****************************************************************************

use "${processing}/SoMB_WB_analysis.dta", clear

foreach v in treatment analysis_sample counselor_num project_week counselor_week {
    capture confirm variable `v'
    if _rc {
        display as error ///
            "ERROR: `v' not found. Run 1_4_Analysisvars_weekly.do first."
        exit 111
    }
}

foreach y of local outcomes {
    capture confirm variable `y'
    if _rc {
        display as error "ERROR: outcome `y' not found in the analysis dataset."
        exit 111
    }
}

count if analysis_sample == 1
display "Analysis sample: " r(N) " cases"

* Number of clusters available under each option, reported in the sheets
qui levelsof project_week if analysis_sample == 1, local(tmp)
local ncl_week : word count `tmp'

qui levelsof counselor_num if analysis_sample == 1, local(tmp)
local ncl_consul : word count `tmp'

qui levelsof counselor_week if analysis_sample == 1, local(tmp)
local ncl_both : word count `tmp'

display as text ///
    "Clusters -- week: `ncl_week' | counsellor: `ncl_consul' | counsellor-week: `ncl_both'"

if `ncl_consul' < 10 {
    display as text ///
        "NOTE: only `ncl_consul' counsellor clusters. Treat the " ///
        "Cluster: counsellor columns as indicative, not as inference."
}


****************************************************************************
**# 				A. Regressions and results dataset
****************************************************************************

/*
 There are only 16 distinct regressions per outcome, not 36:

   spec = none  ->  1  no FE, no cluster; the same column in all 9 sheets
   spec = fe    ->  3  one per FE option, no cluster
   spec = cl    ->  3  one per cluster option, no FE
   spec = both  ->  9  every FE by cluster pair

 Each sheet then reads its four columns out of this one dataset.
*/

tempname ph

postfile `ph' ///
    str32 outcome str80 outcome_lab ///
    str8 fe str8 cl str8 spec ///
    double(b se pval crit nobs r2 fstat sd_y mean_y) ///
    using "`results_dta'", replace

foreach y of local outcomes {

    local ylab : variable label `y'
    if `"`ylab'"' == "" local ylab "`y'"

    foreach spec in none fe cl both {

        * Which FE and cluster options this spec loops over
        if "`spec'" == "none" {
            local felist "none"
            local cllist "none"
        }
        else if "`spec'" == "fe" {
            local felist "`fe_opts'"
            local cllist "none"
        }
        else if "`spec'" == "cl" {
            local felist "none"
            local cllist "`cl_opts'"
        }
        else {
            local felist "`fe_opts'"
            local cllist "`cl_opts'"
        }

        foreach f of local felist {
        foreach c of local cllist {

            * Fixed effects
            local feterms ""
            if "`f'" == "week"   local feterms "i.project_week"
            if "`f'" == "consul" local feterms "i.counselor_num"
            if "`f'" == "both"   local feterms "i.counselor_num i.project_week"

            * Variance estimator
            local vcespec "`nocluster_vce'"
            if "`c'" == "week"   local vcespec "cluster project_week"
            if "`c'" == "consul" local vcespec "cluster counselor_num"
            if "`c'" == "both"   local vcespec "cluster counselor_week"

            local vceopt ""
            if "`vcespec'" != "" local vceopt "vce(`vcespec')"

            display as text _n "--> `y' | FE: `f' | cluster: `c'"

            * Built in two branches so the command never ends in a bare
            * comma when there is no vce() option
            if "`vceopt'" == "" {
                capture noisily ///
                    reg `y' treatment `feterms' if analysis_sample == 1
            }
            else {
                capture noisily ///
                    reg `y' treatment `feterms' if analysis_sample == 1, `vceopt'
            }

            if _rc {
                display as error ///
                    "    estimation failed (rc = " _rc "), row left missing"
                post `ph' ("`y'") (`"`ylab'"') ("`f'") ("`c'") ("`spec'") ///
                    (.) (.) (.) (.) (.) (.) (.) (.) (.)
                continue
            }

            * Pull everything out of e() and r(table) before anything else
            * overwrites them
            matrix R = r(table)
            local pos = colnumb(R, "treatment")

            local b    = R[1, `pos']
            local se   = R[2, `pos']
            local pval = R[4, `pos']
            local crit = R[8, `pos']

            local nobs  = e(N)
            local r2    = e(r2)
            local fstat = e(F)

            * Mean and SD of the outcome on this estimation sample.
            * sd_y is what block C divides by to get standard deviations.
            qui summarize `y' if e(sample)
            local mean_y = r(mean)
            local sd_y   = r(sd)

            post `ph' ("`y'") (`"`ylab'"') ("`f'") ("`c'") ("`spec'") ///
                (`b') (`se') (`pval') (`crit') (`nobs') (`r2') (`fstat') ///
                (`sd_y') (`mean_y')
        }
        }
    }
}

postclose `ph'

display as text _n "Results dataset saved: `results_dta'"


****************************************************************************
**# 				B. Consolidated tables
****************************************************************************

use "`results_dta'", clear

* Significance stars
gen str4 stars = ""
replace stars = "*"   if pval < 0.10 & !missing(pval)
replace stars = "**"  if pval < 0.05 & !missing(pval)
replace stars = "***" if pval < 0.01 & !missing(pval)

* The two lines that make up one cell
gen str32 cell_b  = ""
gen str32 cell_se = ""
replace cell_b  = strtrim(string(b, "`dfmt'")) + stars      if !missing(b)
replace cell_se = "(" + strtrim(string(se, "`dfmt'")) + ")" if !missing(se)

gen long idx = _n

* Row order follows the outcome list, not alphabetical order
gen int row_order = .
local k = 0
foreach y of local outcomes {
    local ++k
    replace row_order = `k' if outcome == "`y'"
}

* Readable labels for the two header rows
local lab_fe_none   "Sin FE"
local lab_fe_week   "FE: semana"
local lab_fe_consul "FE: consejero"
local lab_fe_both   "FE: consejero + semana"

local lab_cl_none   "Sin cluster"
local lab_cl_week   "Cluster: semana"
local lab_cl_consul "Cluster: consejero"
local lab_cl_both   "Cluster: consejero-semana"

local nout : word count `outcomes'

* Row geometry, derived so that adding an outcome does not break the layout
local r_top   = 3
local r_h1    = 4
local r_h2    = 5
local r_coef0 = 6
local r_coefN = `r_coef0' + `nout' - 1

local r_lab_n = `r_coefN' + 1
local r_n0    = `r_lab_n' + 1
local r_nN    = `r_n0' + `nout' - 1

local r_lab_f = `r_nN' + 1
local r_f0    = `r_lab_f' + 1
local r_fN    = `r_f0' + `nout' - 1

local r_lab_r2 = `r_fN' + 1
local r_r20    = `r_lab_r2' + 1
local r_r2N    = `r_r20' + `nout' - 1

local r_note = `r_r2N' + 2

local firstsheet = 1

foreach f of local fe_opts {
foreach c of local cl_opts {

    local sheet "FE_`f'_cl_`c'"

    if `firstsheet' == 1 {
        putexcel set "`xlsx'", sheet("`sheet'") replace
        local firstsheet = 0
    }
    else {
        putexcel set "`xlsx'", sheet("`sheet'", replace) modify
    }

    local felab "`lab_fe_`f''"
    local cllab "`lab_cl_`c''"
    local nclus "`ncl_`c''"

    * ---- Title ---------------------------------------------------------
    putexcel A1 = ///
        "Efecto ITT de la asignacion a Lateris (coeficiente de treatment)", bold
    putexcel A2 = "`felab' | `cllab' (`nclus' clusters)", italic

    * ---- Column headers, split over two rows -----------------------------
    * Column 1: no FE, no cluster       Column 2: FE only
    * Column 3: cluster only            Column 4: both
    putexcel A`r_h2' = "Variable dependiente", bold

    putexcel B`r_h1' = "`lab_fe_none'", hcenter txtwrap
    putexcel C`r_h1' = "`felab'",       hcenter txtwrap
    putexcel D`r_h1' = "`lab_fe_none'", hcenter txtwrap
    putexcel E`r_h1' = "`felab'",       hcenter txtwrap

    putexcel B`r_h2' = "`lab_cl_none'", hcenter txtwrap
    putexcel C`r_h2' = "`lab_cl_none'", hcenter txtwrap
    putexcel D`r_h2' = "`cllab'",       hcenter txtwrap
    putexcel E`r_h2' = "`cllab'",       hcenter txtwrap

    * ---- Coefficient block ------------------------------------------------
    local k = 0
    foreach y of local outcomes {

        local ++k
        local rr = `r_coef0' + `k' - 1

        * Row label: the variable label, as requested
        qui summarize idx if outcome == "`y'", meanonly
        if r(N) > 0 {
            local ilab = r(min)
            local rowlab = outcome_lab[`ilab']
        }
        else local rowlab "`y'"

        putexcel A`rr' = "`rowlab'", vcenter

        local ncol = 0
        foreach combo in "none none none" "fe `f' none" "cl none `c'" "both `f' `c'" {

            local ++ncol
            local col : word `ncol' of B C D E

            local sp : word 1 of `combo'
            local ff : word 2 of `combo'
            local cc : word 3 of `combo'

            qui summarize idx if outcome == "`y'" & spec == "`sp'" ///
                & fe == "`ff'" & cl == "`cc'", meanonly

            if r(N) == 1 {
                local i    = r(min)
                local bstr = cell_b[`i']
                local sstr = cell_se[`i']

                putexcel `col'`rr' = ("`bstr'" + char(10) + "`sstr'"), ///
                    txtwrap hcenter vcenter
            }
            else {
                putexcel `col'`rr' = "", hcenter
            }
        }
    }

    * ---- Statistics blocks -------------------------------------------------
    * N, F and R2 are specific to each outcome-by-column cell, so each one
    * gets its own block with the same rows as the coefficient block.
    putexcel A`r_lab_n'  = "Observaciones (N)", bold
    putexcel A`r_lab_f'  = "Estadistico F",     bold
    putexcel A`r_lab_r2' = "R cuadrado",        bold

    local k = 0
    foreach y of local outcomes {

        local ++k
        local rn  = `r_n0'  + `k' - 1
        local rf  = `r_f0'  + `k' - 1
        local rr2 = `r_r20' + `k' - 1

        qui summarize idx if outcome == "`y'", meanonly
        local ilab = r(min)
        local rowlab = outcome_lab[`ilab']

        putexcel A`rn'  = "`rowlab'"
        putexcel A`rf'  = "`rowlab'"
        putexcel A`rr2' = "`rowlab'"

        local ncol = 0
        foreach combo in "none none none" "fe `f' none" "cl none `c'" "both `f' `c'" {

            local ++ncol
            local col : word `ncol' of B C D E

            local sp : word 1 of `combo'
            local ff : word 2 of `combo'
            local cc : word 3 of `combo'

            qui summarize idx if outcome == "`y'" & spec == "`sp'" ///
                & fe == "`ff'" & cl == "`cc'", meanonly

            if r(N) == 1 {
                local i = r(min)

                local vN  = nobs[`i']
                local vF  = fstat[`i']
                local vR2 = r2[`i']

                putexcel `col'`rn' = (`vN'), hcenter nformat("#,##0")

                if !missing(`vF') {
                    putexcel `col'`rf' = (`vF'), hcenter nformat("0.00")
                }
                else {
                    putexcel `col'`rf' = ".", hcenter
                }

                putexcel `col'`rr2' = (`vR2'), hcenter nformat("0.000")
            }
        }
    }

    * ---- Rules --------------------------------------------------------------
    putexcel A`r_top':E`r_top'    , border(bottom, medium)
    putexcel A`r_h2':E`r_h2'      , border(bottom, thin)
    putexcel A`r_coefN':E`r_coefN', border(bottom, thin)
    putexcel A`r_r2N':E`r_r2N'    , border(bottom, medium)

    * ---- Notes ---------------------------------------------------------------
    local rn1 = `r_note'
    local rn2 = `r_note' + 1
    local rn3 = `r_note' + 2
    local rn4 = `r_note' + 3

    putexcel A`rn1' = ///
        "Cada celda: coeficiente de treatment con asteriscos y, debajo, el error estandar entre parentesis.", ///
        italic
    putexcel A`rn2' = ///
        "*** p<0.01, ** p<0.05, * p<0.1. Columnas sin cluster: errores estandar OLS clasicos.", ///
        italic
    putexcel A`rn3' = ///
        "Muestra: analysis_sample == 1, semanas 1-20 con asignacion aleatoria observada.", ///
        italic

    if "`c'" == "consul" {
        putexcel A`rn4' = ///
            "ADVERTENCIA: solo `nclus' clusters de consejero. Verificar con boottest o inferencia por aleatorizacion.", ///
            italic bold
    }

    display as text "  sheet written: `sheet'"
}
}

* Release the workbook so that export excel can reopen it in block C
putexcel clear

display as text _n "Workbook written: `xlsx'"


****************************************************************************
**# 				C. Standardized forest plot
****************************************************************************

* One specification only: both sets of fixed effects, clustered on the
* counsellor-week cell.

use "`results_dta'", clear

keep if spec == "both" & fe == "both" & cl == "both"
drop if missing(b) | missing(sd_y) | sd_y == 0

* Order rows as declared, then flip so the first outcome sits on top
gen int row_order = .
local k = 0
foreach y of local outcomes {
    local ++k
    replace row_order = `k' if outcome == "`y'"
}

sort row_order
gen int yorder = _N - _n + 1

* b/sd(y) is identical to regressing the standardized outcome
gen double b_std  = b  / sd_y
gen double se_std = se / sd_y

* crit is the t critical value at 95% with this model's degrees of freedom
gen double lo = b_std - crit*se_std
gen double hi = b_std + crit*se_std

gen str4 stars = ""
replace stars = "*"   if pval < 0.10 & !missing(pval)
replace stars = "**"  if pval < 0.05 & !missing(pval)
replace stars = "***" if pval < 0.01 & !missing(pval)

gen str32 estlab = strtrim(string(b_std, "%5.2f")) + stars

label variable b_std "ITT effect in standard deviations of the outcome"

* Axis labels built from the variable labels
local nrows = _N

local ylabs ""
forvalues i = 1/`nrows' {
    local yy = yorder[`i']
    local ll = outcome_lab[`i']
    local ylabs `"`ylabs' `yy' "`ll'""'
}

qui summarize lo
local xmin = min(r(min), 0)

qui summarize hi
local xmax = max(r(max), 0)

local pad = 0.15*(`xmax' - `xmin')

* Axis ranges resolved here so the twoway call carries no nested expressions
local xlo  = `xmin' - `pad'
local xhi  = `xmax' + `pad'
local ytop = `nrows' + 0.6

twoway ///
    (rcap lo hi yorder, horizontal lcolor(navy) lwidth(medthin)) ///
    (scatter yorder b_std, ///
        msymbol(D) msize(small) mcolor(navy) ///
        mlabel(estlab) mlabposition(12) mlabsize(vsmall) mlabcolor(black)) ///
    , ///
    xline(0, lpattern(dash) lcolor(gs8)) ///
    ylabel(`ylabs', angle(0) labsize(vsmall) noticks nogrid) ///
    yscale(range(0.4 `ytop') noline) ///
    ytitle("") ///
    xtitle("ITT effect in standard deviations of the outcome", size(small)) ///
    xlabel(, labsize(small) format(%4.2f)) ///
    xscale(range(`xlo' `xhi')) ///
    title("Standardized ITT effects", size(medium)) ///
    subtitle("Counsellor and week fixed effects, clustered on counsellor-week", size(small)) ///
    note("Bars: 95% confidence intervals. Coefficients are divided by the standard deviation" ///
         "of the outcome on its estimation sample. Five of the seven outcomes are binary." ///
         "*** p<0.01, ** p<0.05, * p<0.1", size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "`graph_out'/forest_main_standardized.png", replace width(2200)

display as text "Figure written: `graph_out'/forest_main_standardized.png"

* Keep the numbers behind the figure in the same workbook
preserve

    keep outcome outcome_lab nobs mean_y sd_y b se pval b_std se_std lo hi
    order outcome outcome_lab nobs mean_y sd_y b se pval b_std se_std lo hi

    export excel using "`xlsx'", ///
        sheet("forest_std", replace) firstrow(variables)

restore

display as text _n ///
    "2_11_Impact_consolidated_results.do completed successfully."
