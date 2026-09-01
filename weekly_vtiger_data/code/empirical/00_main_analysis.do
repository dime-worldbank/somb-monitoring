/******************************************************************
 main_analysis.do
 Project: SoMB / WB empirical analysis
 Purpose: Run full empirical analysis pipeline
******************************************************************/

clear all
set more off
version 18


/******************************************************************
 0. Project paths
******************************************************************/


* IMPORTANT:
* Set Stata working directory to project root:
* weekly_vtiger_data

* main_analysis.do is stored in:
* code/empirical/
*
* Move two levels up to the project root:
* weekly_vtiger_data/

*cd "../.."

* Project root
cd "../.."

global project_path "`c(pwd)'"

* Code
global empirical_code_path ///
    "$project_path/code/empirical"

* Shared data folders
global raw_path ///
    "$project_path/raw_data"

global processed_path ///
    "$project_path/processed_data"

* Outputs
global output_path ///
    "$project_path/outputs"

global empirical_output_path ///
    "$output_path/empirical"

global table_path ///
    "$empirical_output_path/tables"

global graph_path ///
    "$empirical_output_path/graphs"

global log_path ///
    "$empirical_output_path/logs"


/******************************************************************
 1. Create output folders if they do not exist
******************************************************************/

capture mkdir "$processed_path"
capture mkdir "$output_path"
capture mkdir "$empirical_output_path"
capture mkdir "$table_path"
capture mkdir "$graph_path"
capture mkdir "$log_path"


/******************************************************************
 2. Check paths
******************************************************************/

display "Project root:       $project_path"
display "Empirical code:     $empirical_code_path"
display "Raw data:           $raw_path"
display "Processed data:     $processed_path"
display "Empirical outputs:  $empirical_output_path"


/******************************************************************
 2. Define analysis files
******************************************************************/

global clean_file ///
    "$processed_path/SoMB_WB_clean_base.dta"

global indicator_file ///
    "$processed_path/SoMB_WB_monitoring_indicators.dta"

global randomization_file ///
    "$processed_path/randomization_schedule.dta"

global analysis_file ///
    "$processed_path/SoMB_WB_analysis.dta"


/******************************************************************
 3. Check required input files
******************************************************************/

capture confirm file "$indicator_file"

if _rc {
    di as error "ERROR: Indicator dataset not found:"
    di as error "$indicator_file"
    di as error "Run the monitoring data preparation pipeline first."
    exit 601
}


capture confirm file "$randomization_file"

if _rc {
    di as error "ERROR: Randomization schedule not found:"
    di as error "$randomization_file"
    exit 601
}


/******************************************************************
 4. Start analysis log
******************************************************************/

capture log close

local today = subinstr("`c(current_date)'", " ", "_", .)
local now   = subinstr("`c(current_time)'", ":", "_", .)

log using ///
    "$log_path/empirical_analysis_`today'_`now'.log", ///
    replace text


/******************************************************************
 5. Start analysis pipeline
******************************************************************/

display "=================================================="
display "Starting empirical analysis pipeline"
display "Project path: $project_path"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="


/******************************************************************
 6. Create analysis variables
******************************************************************/

display "--------------------------------------------------"
display "Step 1: Creating analysis variables"
display "--------------------------------------------------"

**# Bookmark #2
do "$empirical_code_path/01_create_analysis_variables.do"


/******************************************************************
 7. Analysis sample and randomization checks
******************************************************************/

display "--------------------------------------------------"
display "Step 2: Running analysis checks"
display "--------------------------------------------------"

do "$empirical_code_path/02_analysis_checks.do"


/******************************************************************
 8. Descriptive analysis
******************************************************************/

display "--------------------------------------------------"
display "Step 3: Running descriptive analysis"
display "--------------------------------------------------"

do "$empirical_code_path/03_descriptive_analysis.do"


/******************************************************************
 9. Main treatment effects
******************************************************************/

display "--------------------------------------------------"
display "Step 4: Running main OLS analysis"
display "--------------------------------------------------"

do "$empirical_code_path/04_main_ols.do"



/******************************************************************
 10. Outcome families
******************************************************************/

display "--------------------------------------------------"
display "Step 5: Running outcome-family analysis"
display "--------------------------------------------------"

do "$empirical_code_path/05_secondary_outcomes.do"



/******************************************************************
 11. Heterogeneity analysis
******************************************************************/

display "--------------------------------------------------"
display "Step 6: Running heterogeneity analysis"
display "--------------------------------------------------"

do "$empirical_code_path/06_heterogeneity_analysis.do" 

here

/*
/******************************************************************
 12. Robustness checks
******************************************************************/

display "--------------------------------------------------"
display "Step 7: Running robustness checks"
display "--------------------------------------------------"

do "$empirical_code_path/07_robustness.do"


/******************************************************************
 13. Finish pipeline
******************************************************************/

display "=================================================="
display "Empirical analysis pipeline completed successfully"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="


/******************************************************************
 14. Close log
******************************************************************/

log close