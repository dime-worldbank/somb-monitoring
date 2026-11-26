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

4) Objective: 	Draw the consultant-week randomization schedule for the Lateris
				trial. Each of the five consultants (A-E) gets 8 AI and 8 No-AI
				weeks, with no more than 3 consecutive weeks of the same status

5) Output:		- randomization_schedule.dta
				- rct_randomization_schedule_wide.dta
				- randomization_schedule.xlsx
				- rct_randomization_schedule_wide.xlsx

*************************************************************************
*************************************************************************/

clear all
set more off
set seed 20023

****************************************************************************
**# 				1. Randomization schedule
****************************************************************************

* 5 Consultants A–E
set obs 5
gen consultant = ""
replace consultant = "A" in 1
replace consultant = "B" in 2
replace consultant = "C" in 3
replace consultant = "D" in 4
replace consultant = "E" in 5

* create 16 weeks for each consultant
expand 16
bys consultant: gen week = _n

* create AI assignment for first 16 weeks
gen ai = .

levelsof consultant, local(conslist)

foreach c of local conslist {

    local ok = 0
    local tries = 0

    while (`ok' == 0) {
        local ++tries

        if (`tries' > 5000) {
            di as error "Could not find a valid 16-week schedule for consultant `c'."
            exit 498
        }

        quietly {
            replace ai = . if consultant == "`c'"

            gen double u_tmp = runiform() if consultant == "`c'"
            bys consultant (u_tmp): replace ai = (_n <= 8) if consultant == "`c'"
            drop u_tmp

            sort consultant week
            gen byte change = (ai != ai[_n-1]) if consultant == "`c'"
            replace change = 1 if consultant == "`c'" & week == 1

            bys consultant: gen int run_id = sum(change) if consultant == "`c'"
            bys consultant run_id: gen int run_len = _N if consultant == "`c'"

            summarize run_len if consultant == "`c'", meanonly
            local maxrun = r(max)

            drop change run_id run_len
        }

        if (`maxrun' <= 3) local ok = 1
    }

    di "Consultant `c': valid 16-week schedule found after `tries' tries."
}

* add weeks 17–20, keeping weeks 1–16 unchanged
expand 5 if week == 16
bys consultant (week): replace week = _n
replace ai = . if week >= 17

* randomize weeks 17–20: exactly 2 AI and 2 No AI per consultant
foreach c of local conslist {

    local ok = 0
    local tries = 0

    while (`ok' == 0) {
        local ++tries

        if (`tries' > 5000) {
            di as error "Could not find a valid 4-week extension for consultant `c'."
            exit 498
        }

        quietly {
            replace ai = . if consultant == "`c'" & week >= 17

            gen double u_ext = runiform() if consultant == "`c'" & week >= 17
            bys consultant (u_ext): gen ext_rank = _n if consultant == "`c'" & week >= 17

            replace ai = (ext_rank <= 2) if consultant == "`c'" & week >= 17

            drop u_ext ext_rank

            * check max 3 consecutive weeks across all 20 weeks
            sort consultant week
            gen byte change = (ai != ai[_n-1]) if consultant == "`c'"
            replace change = 1 if consultant == "`c'" & week == 1

            bys consultant: gen int run_id = sum(change) if consultant == "`c'"
            bys consultant run_id: gen int run_len = _N if consultant == "`c'"

            summarize run_len if consultant == "`c'", meanonly
            local maxrun = r(max)

            drop change run_id run_len
        }

        if (`maxrun' <= 3) local ok = 1
    }

    di "Consultant `c': valid 20-week schedule found after `tries' tries."
}

* labels
label define ai_lbl 0 "No AI" 1 "AI"
label values ai ai_lbl

* checks
bys consultant: tab ai

* display plan
sort consultant week
list consultant week ai, sepby(consultant)


 *Save long randomization schedule for analysis


sort consultant week

rename consultant counselor_id
rename week project_week

save "${processing}/randomization_schedule.dta", replace

export excel using ///
    "${processing}/randomization_schedule.xlsx", ///
    firstrow(variables) replace

 * Save wide version for manual review
 
preserve

rename counselor_id consultant
rename project_week week

reshape wide ai, i(consultant) j(week)

save "${processing}/rct_randomization_schedule_wide.dta", replace

export excel using ///
    "${processing}/rct_randomization_schedule_wide.xlsx", ///
    firstrow(variables) replace

restore


