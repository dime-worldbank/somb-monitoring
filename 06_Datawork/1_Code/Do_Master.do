/*************************************************************************
 *************************************************************************
                Master Do-File

1) Created by: 	Daniel Márquez
				DIME - World Bank
				dmarquezmuskus@worldbank.org

2) Date: 		September 2026

3) Project:     SoMB - Social Media Bridge (Germany)
                Lateris AI-assisted counselling

4) Pipelines:   A. High-frequency monitoring   (weekly Vtiger CSVs)
                B. Impact analysis / RCT       (weekly Vtiger CSVs)
                C. Yearly infographic          (yearly Vtiger .dta)

                A and B share the weekly processing. C is independent.
                To skip a step, comment out its do-file below.
                Logs are opened by each do-file, not here.

*************************************************************************
*************************************************************************/

cls
clear all
set more off
cap log close

****************************************************************************
* Project paths
****************************************************************************

global projectfolder "C:\Users\samis\OneDrive\Desktop\WB-Data\somb-monitoring"

global code "$project_folder\06_Datawork\1_Code"

****************************************************************************
* Ado paths
****************************************************************************

sysdir set PLUS "$code\ado\plus"
sysdir set PERSONAL "$code\ado\personal"



****************************************************************************
* Required packages (uncomment if running for the first time)
***************************************************************************

*net install scheme-modern, replace ///
    from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
*ssc install heatplot, replace     // needed by 2_9_Infographic_graphs.do
*ssc install palettes, replace     // heatplot dependency
*ssc install colrspace, replace    // heatplot dependency



****************************************************************************
* Globals
****************************************************************************

* Users project folder path
if "`c(username)'" ==       "danie"           {
    global projectfolder    "C:\Users\danie\Dropbox\1. World Bank (copies)\Germany"
}
if "`c(username)'" ==       "samis"                {
    global projectfolder    "C:\Users\samis\OneDrive\Desktop\WB-Data\somb-monitoring"
}


* Project folder
global root             "${projectfolder}\06_Datawork"

* Coding folders
global code             "${root}\1_Code"

* Data folders
global data             "${root}\2_Data"
global raw              "${data}\0_Raw"
global weekly           "${raw}\1_Weekly_vtiger"
global yearly           "${raw}\2_Yearly_vtiger"
global processing       "${data}\1_Processing"
global analysis         "${data}\2_Analysis"

* Output
global output           "${root}\3_Output"
global monitoring       "${output}\Monitoring"
global impact           "${output}\Impact"
global infographic      "${output}\Infographic"
global logs             "${output}\Logs"


****************************************************************************
* Version and packages location
****************************************************************************

* Folders
foreach d in processing analysis monitoring impact infographic logs {
    cap mkdir "${`d'}"
}
cap mkdir "${monitoring}\Tables"
cap mkdir "${monitoring}\Graphs"
cap mkdir "${impact}\Tables"
cap mkdir "${impact}\Graphs"
cap mkdir "${infographic}\Graphs"

* Version
version 18

* Packages (kept inside the project so the code is self-contained)
cap mkdir "${code}\ado"
cap mkdir "${code}\ado\plus"
cap mkdir "${code}\ado\personal"
sysdir set PLUS     "${code}\ado\plus"
sysdir set PERSONAL "${code}\ado\personal"

* Re-index the Mata libraries that ship with the packages above. Stata builds
* its index at start-up, before PLUS is redirected here, so without this
* heatplot fails in 2_9 with "class ColrSpace undefined".
mata: mata mlib index

* Font
graph set window fontface "Times New Roman"

* Graph scheme. Set here and nowhere else: no do-file downstream
* overrides it, so every figure in the project comes out the same.
* scheme-modern is not a Stata built-in and is not part of schemepack;
* it ships in ado/plus/s/scheme-modern.scheme. The old code called it
* with "capture set scheme modern", which silently swallowed the error
* whenever it was missing, so the figures were never actually drawn
* with it.
set scheme modern


****************************************************************************
**#                     1. Do-files
****************************************************************************

* Processing - randomization
* One-time only. Re-running draws a new schedule and overwrites the one
* the impact analysis is built on. Left commented on purpose.

do "${code}/1_Processing/1_1_Randomization_schedule.do"


* Processing - weekly Vtiger data
do "${code}/1_Processing/1_2_Import_weekly.do"
do "${code}/1_Processing/1_3_Indicators_weekly.do"
do "${code}/1_Processing/1_4_Analysisvars_weekly.do"


* Processing - yearly Vtiger data
do "${code}/1_Processing/1_5_Import_yearly.do"
do "${code}/1_Processing/1_6_Prepare_yearly.do"
do "${code}/1_Processing/1_7_Infographicprep_yearly.do"
do "${code}/1_Processing/1_8_Baseline_comparison"


* Analysis - high-frequency monitoring
do "${code}/2_Analysis/2_1_Monitoring_tables.do"
do "${code}/2_Analysis/2_2_Monitoring_graphs.do"
do "${code}/2_Analysis/2_3_Monitoring_stakeholder.do"


* Analysis - impact / RCT
do "${code}/2_Analysis/2_4_Impact_checks.do"
do "${code}/2_Analysis/2_5_a_Impact_descriptives.do"
do "${code}/2_Analysis/2_5_b_Impact_descriptives.do"
do "${code}/2_Analysis/2_6_Impact_mainols.do"
do "${code}/2_Analysis/2_7_Impact_secondary.do"
do "${code}/2_Analysis/2_8_Impact_heterogeneity.do"
do "${code}/2_Analysis/2_10_Impact_heterogeneity_figures.do"


* Analysis - yearly infographic
do "${code}/2_Analysis/2_9_Infographic_graphs.do"
