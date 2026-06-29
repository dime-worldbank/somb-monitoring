/******************************************************************
 00_master.do
 Project: SoMB Digital Counselling Monitoring

 Purpose:
 Master script to reproduce the complete analysis pipeline.


******************************************************************/

clear all
set more off
version 18

*------------------------------------------------------------*
* 1. Define project paths
*------------------------------------------------------------*

global root "`c(pwd)'"

global code_path      "$root/code"
global raw_path       "$root/raw_data"
global processed_path "$root/processed"
global output_path    "$root/outputs"
global graph_path     "$output_path/graphs"
global table_path     "$output_path/tables"
global log_path       "$root/logs"

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

do "$code_path/05_weekly_tables.do"

do "$code_path/06_weekly_graphs.do"

display "==========================================="
display "Pipeline finished successfully."
display "Finished: `c(current_date)' `c(current_time)'"
display "==========================================="

log close