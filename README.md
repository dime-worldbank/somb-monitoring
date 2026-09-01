# somb-monitoring
Repository for automated monitoring and empirical analysis of the SOMB project.

The repository contains reproducible workflows for:

- data import and cleaning,
- high-frequency implementation monitoring,
- creation of monitoring indicators,
- empirical analysis,
- statistical analysis and robustness checks,
- and automated generation of tables and graphs.

## Data

The raw data are **not included** in this repository due to confidentiality.

To run the analysis, copy the raw CSV files from OneDrive into the `raw_data/` folder.

## Repository Structure

The weekly Vtiger data workflow is organized as follows:

```
weekly_vtiger_data/
├── code/
│   ├── high_frequency/
│   │   ├── 00_main_high_frequency.do
│   │   ├── 01_import_clean.do
│   │   ├── 02_create_indicators.do
│   │   ├── 03_weekly_tables.do
│   │   ├── 04_graphs.do
│   │   └── 05_stakeholder_graphs.do
│   │
│   ├── randomization/
│   │   └── 01_create_randomization_schedule.do
│   │
│   └── empirical/
│       ├── 00_main_analysis.do
│       ├── 01_create_analysis_variables.do
│       ├── 02_analysis_checks.do
│       ├── 03_descriptive_analysis.do
│       ├── 04_main_ols.do
│       ├── 05_secondary_outcomes.do
│       └── 06_heterogeneity_analysis.do
│
├── raw_data/
│
├── processed_data/
│   ├── SoMB_WB_clean_base.dta
│   ├── SoMB_WB_monitoring_indicators.dta
│   ├── randomization_schedule.dta
│   └── SoMB_WB_analysis.dta
│
└── outputs/
    ├── high_frequency/
    │   ├── tables/
    │   ├── graphs/
    │   └── logs/
    │
    └── empirical/
        ├── tables/
        ├── graphs/
        └── logs/

```
The separation between high_frequency/ and empirical/ ensures that routine implementation monitoring and the empirical impact analysis can be run and maintained independently while using the same underlying cleaned data.


### Weekly Vtiger data

Weekly Vtiger exports are available on Onedrive at:

```
03_Project_Documentation/
└── 03_Germany_Social Media Bridge/
    └── 04_Intervention/
        └── Data/
            └── Minor-Data Upload/
                └── Weekly Data Updates/
                    └── Raw data/
```

### Yearly Vtiger data

Yearly Vtiger exports are available at:

```
03_Project_Documentation/
└── 03_Germany_Social Media Bridge/
    └── 04_Intervention/
        └── Data/
            └── Minor-Data Upload/
                └── Yearly Data from Vtiger/
                    └── Raw data/
```

Copy the required CSV files into `weekly_vtiger_data/raw_data` or `yearly_vtiger_data/raw_data/`. Then open `weekly_vtiger_data/code/00_main.do` or `yearly_vtiger_data/code/00_main.do` in Stata and run it to produce the outputs.

## High-Frequency Monitoring

The high-frequency workflow is used for regular monitoring of project implementation and data quality.

It creates the cleaned base data and monitoring indicators used for weekly and biweekly monitoring products.

High-frequency analysis code is stored in:

weekly_vtiger_data/code/high_frequency/

Outputs are automatically stored in:

weekly_vtiger_data/outputs/high_frequency/
├── tables/
├── graphs/
└── logs/
## Empirical Analysis

The empirical workflow is used for the statistical analysis of the SOMB intervention.

It builds on the cleaned monitoring data and the randomization schedule to create the final analysis dataset:

weekly_vtiger_data/processed_data/SoMB_WB_analysis.dta

The empirical analysis code is stored in:

weekly_vtiger_data/code/empirical/

The main empirical workflow is executed through:

weekly_vtiger_data/code/empirical/main_analysis.do

This workflow runs the empirical analysis scripts in the required order, including:

01_create_analysis_variables.do
02_analysis_checks.do
...

Empirical results are automatically stored in:

weekly_vtiger_data/outputs/empirical/
├── tables/
├── graphs/
└── logs/

This keeps empirical results separate from the regular high-frequency monitoring outputs.