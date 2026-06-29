/******************************************************************
 00_master.do
 Project: SoMB Digital Counselling Monitoring

 Purpose:
 Master script to reproduce the complete analysis pipeline.


******************************************************************/
clear 
set more off
version 18

*------------------------------------------------------------*
* 1. Define project paths
*------------------------------------------------------------*
global project_path "`c(pwd)'/.."

global code_path      "$project_path/code"
global raw_path       "$project_path/raw_data"
global processed_path "$project_path/processed"
global output_path    "$project_path/outputs"
global graph_path     "$output_path/graphs"
global table_path     "$output_path/tables"
global log_path       "$project_path/logs"

capture mkdir "$processed_path"
capture mkdir "$output_path"
capture mkdir "$graph_path"
capture mkdir "$table_path"
capture mkdir "$log_path"

capture log close
log using "$log_path/master.log", replace text

display "==========================================="
display "Running SoMB Monitoring Pipeline"
display "Started: `c(current_date)' `c(current_time)'"
display "==========================================="

*------------------------------------------------------------*
* 2. Data preparation
*------------------------------------------------------------*

do "$code_path/01_import_clean.do"

do "$code_path/02_prepare_analysis.do"

do "$code_path/03_infographic_clean_group.do"

*------------------------------------------------------------*
* 3. Outputs
*------------------------------------------------------------*

do "$code_path/04_infographic_graphs.do"


display "==========================================="
display "Pipeline finished successfully."
display "Finished: `c(current_date)' `c(current_time)'"
display "==========================================="

log close