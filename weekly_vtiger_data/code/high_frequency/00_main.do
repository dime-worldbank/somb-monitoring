/******************************************************************
 00_master_hf.do
 Project: SoMB / WB weekly Vtiger data
 Purpose: Run full high-frequency monitoring pipeline
******************************************************************/

clear all
set more off
version 18


/******************************************************************
 0. Project paths
******************************************************************/

* IMPORTANT:
* Open Stata in the main project folder:
* weekly_vtiger_data

global project_path "`c(pwd)'"

global hf_code_path    "$project_path/code/high_frequency"

global raw_path        "$project_path/raw_data"
global processed_path  "$project_path/processed_data"

global output_path     "$project_path/outputs"
global hf_output_path  "$output_path/high_frequency"

global table_path      "$hf_output_path/tables"
global graph_path      "$hf_output_path/graphs"
global log_path        "$hf_output_path/logs"


/******************************************************************
 1. Create folders if they do not exist
******************************************************************/

capture mkdir "$processed_path"

capture mkdir "$output_path"
capture mkdir "$hf_output_path"

capture mkdir "$table_path"
capture mkdir "$graph_path"
capture mkdir "$log_path"


/******************************************************************
 2. Start log file
******************************************************************/

capture log close

local today = subinstr("`c(current_date)'", " ", "_", .)
local now   = subinstr("`c(current_time)'", ":", "_", .)

log using ///
    "$log_path/weekly_monitoring_`today'_`now'.log", ///
    replace text


/******************************************************************
 3. Start monitoring pipeline
******************************************************************/

display "=================================================="
display "Starting high-frequency monitoring pipeline"
display "Project path: $project_path"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="


/******************************************************************
 4. Import and clean raw data
******************************************************************/

display "--------------------------------------------------"
display "Step 1: Importing and cleaning raw data"
display "--------------------------------------------------"

do "$hf_code_path/01_import_clean.do"


/******************************************************************
 5. Create monitoring indicators
******************************************************************/

display "--------------------------------------------------"
display "Step 2: Creating monitoring indicators"
display "--------------------------------------------------"

do "$hf_code_path/02_create_indicators.do"


/******************************************************************
 6. Create weekly tables
******************************************************************/

display "--------------------------------------------------"
display "Step 3: Creating weekly monitoring tables"
display "--------------------------------------------------"

do "$hf_code_path/03_weekly_tables.do"


/******************************************************************
 7. Create graphs
******************************************************************/

display "--------------------------------------------------"
display "Step 4: Creating monitoring graphs"
display "--------------------------------------------------"

do "$hf_code_path/04_graphs.do"


/******************************************************************
 8. Finish pipeline
******************************************************************/

display "=================================================="
display "High-frequency monitoring pipeline completed"
display "Date: `c(current_date)'"
display "Time: `c(current_time)'"
display "=================================================="


/******************************************************************
 9. Close log
******************************************************************/

log close