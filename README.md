Hospital Operations & Patient Analytics
Project Overview

This project presents an end-to-end analysis of hospital patient encounters to understand patient volume, admission patterns, wait times, department performance, and patient satisfaction.

The project demonstrates a complete analytics workflow using:

Python ETL & Analysis → SQL Server Data Warehouse → Power BI Dashboard → Business Insights

The dataset contains 9,216 patient encounters.

Business Objective

The analysis was designed to answer key operational questions such as:

How many patient encounters and admissions occurred?
What is the overall admission rate?
What is the average patient wait time?
Which departments handle the highest patient volumes?
How does wait time vary across departments?
Are there differences in patient activity by time of day?
How do weekday and weekend operations compare?
How does patient satisfaction vary across departments and patient groups?
Is there a relationship between patient wait time and satisfaction?
Tools & Technologies
Python: Pandas, NumPy — data profiling, cleaning, transformation, ETL and statistical analysis
SQL Server: staging, dimensional modelling, data validation and analytical SQL
Power BI: data modelling, DAX measures, KPI reporting and interactive dashboards
Jupyter Notebook: Python ETL and exploratory analysis
End-to-End Analytics Workflow
1. Python ETL & Data Analysis

Python was used to:

Profile the raw hospital dataset
Clean and standardize the data
Convert and validate date fields
Handle missing values
Create derived fields for analysis
Validate categorical and numerical fields
Perform exploratory data analysis
Analyse the relationship between patient wait time and satisfaction

The cleaned dataset was then prepared for loading into SQL Server.

2. SQL Server Data Warehouse

A dimensional data model was created in SQL Server.

The model includes:

dim_patient
dim_department
dim_calendar
fact_patient_encounter

Primary and foreign key relationships were implemented to create a star-schema structure.

SQL was also used for:

Row-count validation
Duplicate and NULL checks
Fact-to-dimension validation
Department performance analysis
Admission analysis
Time-of-day analysis
Monthly encounter trends
Weekday vs weekend analysis
Age-group analysis
Overall hospital KPI analysis
3. Power BI Dashboard

Three Power BI dashboard pages were developed:

Executive Overview
Patient Experience & Satisfaction
Hospital Operational Analysis
Key KPIs
KPI	Result
Total Patient Encounters	9,216
Total Admissions	4,612
Admission Rate	50.04%
Average Wait Time	35.26 minutes
Average Satisfaction Score	4.99
Satisfaction Responses	2,517
Satisfaction Response Rate	27.31%
Key Findings
Patient Volume & Admissions
The dataset contains 9,216 patient encounters.
4,612 encounters resulted in admission, representing an admission rate of approximately 50.04%.
Patient encounter volumes were relatively stable across the analysed monthly period.
Department Performance
A large proportion of encounters had no specified department referral.
General Practice and Orthopedics were among the higher-volume specified departments.
Average wait times varied only modestly across departments.
Operational Patterns
Patient encounter volumes were relatively evenly distributed across different times of day.
Average wait times were also similar across time-of-day groups.
Weekdays recorded substantially more encounters than weekends.
Despite the difference in patient volume, weekday and weekend average wait times were very similar.
Patient Satisfaction
The overall average satisfaction score among available responses was approximately 4.99.
Satisfaction levels showed some variation across departments and patient age groups.
However, satisfaction results should be interpreted carefully because response coverage was limited.
Wait Time vs Patient Satisfaction

Python Pearson correlation analysis was performed to investigate whether longer patient wait times were associated with lower satisfaction scores.

Pearson correlation ≈ -0.021

This value is extremely close to zero, indicating almost no linear relationship between patient wait time and satisfaction score in this dataset.

The Power BI scatter plot also visually supported this finding.

This does not mean that wait time can never influence patient satisfaction. It means that the available data did not show a meaningful linear relationship between the two variables.

Data Limitation

Patient satisfaction scores were available for only:

2,517 out of 9,216 encounters — 27.31%

Therefore, satisfaction-related findings represent only the subset of encounters with recorded satisfaction responses.

The relatively low response rate means satisfaction findings should not automatically be generalized to the entire patient population.

Dashboard
Executive Overview




Patient Experience & Satisfaction




Operational Analysis




Business Recommendations

Based on the analysis:

Investigate why a large number of encounters have no specified department referral and improve department-data capture where appropriate.
Continue monitoring department-level wait times even though differences were relatively modest.
Investigate operational drivers behind monthly fluctuations in patient encounter volume.
Improve patient satisfaction survey participation to obtain more representative feedback.
Avoid assuming that wait time alone explains patient satisfaction; investigate additional factors such as service quality, communication, treatment experience and patient expectations.
Continue monitoring operational KPIs across time of day and weekday/weekend periods to support staffing and resource planning.
Repository Structure
Hospital-Operations-Patient-Analytics/
│
├── dashboard/
│   └── Hospital_Operations_Analytics.pbix
│
├── images/
│   ├── 01_Executive_Overview.png
│   ├── 02_Patient_Experience.png
│   └── 03_Operational_Analysis.png
│
├── notebooks/
│   └── 01_Hospital_ETL.ipynb
│
├── sql/
│   └── Hospital_Analytics_DW.sql
│
└── README.md
Skills Demonstrated

Python ETL | Pandas | Data Cleaning | Exploratory Data Analysis | Statistical Analysis | SQL Server | Data Warehousing | Star Schema | Analytical SQL | Power BI | DAX | KPI Reporting | Data Visualization | Business Analysis
