/******************************************************************
 00_master.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Run full weekly monitoring pipeline
******************************************************************/

clear all
set more off

/******************************************************************
 0. Project paths
******************************************************************/

* IMPORTANT:
* Open Stata in the main project folder before running this file.


global project_path "`c(pwd)'/.."

global code_path      "$project_path/code"
global raw_path       "$project_path/raw_data"
global processed_path "$project_path/processed_data"
global output_path    "$project_path/outputs"
global table_path     "$output_path/tables"
global graph_path     "$output_path/graphs"
global log_path       "$output_path/logs"

/******************************************************************
 1. Create folders if they do not exist
******************************************************************/

capture mkdir "$processed_path"
capture mkdir "$output_path"
capture mkdir "$table_path"
capture mkdir "$graph_path"
capture mkdir "$log_path"

/******************************************************************
 2. Start log file
******************************************************************/

capture log close

local today = subinstr("`c(current_date)'", " ", "_", .)
local now   = subinstr("`c(current_time)'", ":", "_", .)

log using "$log_path/weekly_monitoring_`today'_`now'.log", replace text

/******************************************************************
 3. Run pipeline
******************************************************************/

display "=================================================="
display "Starting weekly monitoring pipeline"
display "Project path: $project_path"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="

do "$code_path/01_import_clean.do"
do "$code_path/02_create_indicators.do"
do "$code_path/03_weekly_tables.do"
do "$code_path/04_graphs.do"

display "=================================================="
display "Weekly monitoring pipeline completed successfully"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="

/******************************************************************
 4. Close log
******************************************************************/

log close