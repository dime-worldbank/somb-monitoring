# somb-monitoring
Repository for automated high-frequency monitoring of the SOMB project, including data management, reproducible analysis workflows, visualization scripts, and implementation monitoring outputs. The repository supports streamlined updates through standardized data inputs and automated generation of monitoring products.

## Data

The raw data are **not included** in this repository due to confidentiality.

To run the analysis, copy the raw CSV files from OneDrive into the `raw_data/` folder.

### Weekly Vtiger data

Weekly Vtiger exports are available at:

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
