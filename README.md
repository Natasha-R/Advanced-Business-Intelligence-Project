## Advanced Business Intelligence and Analytics Project

The final project of the TH Köln module ["Advanced Business Intelligence and Analytics"](https://digital-sciences.de/en/modules/advanced-business-intelligence-and-analytics/) as part of the Digital Sciences Master's Degree.

The purpose of the project was to design and implement a business intelligence infrastructure to support decision making regarding study lifecycles at a university, and to subsequently analyse the predictability of academic success. Only the code is available in this repository, as the original dataset has not been made public.

**[Data Profiling](profiling.sas):** Staging of the raw data, data exploration and understanding through metadata discovery. Includes full-table profiling, single variable profiling, and profiling of inter-variable relations.

**[Data Quality Checking and Handling](quality_screening_handling.sas):** Screening for the conformity of data to syntactical and structural rules, utilising Kimball's error event schema. Handling the data quality problems appropriately.

**[Data Vault](data_vault.sas):** Data warehousing using the data vault 2.0 methodology. Designed by considering the relevant business ontology and defining the core business entities to develop the hubs. The key business processes and relationships form the links. Satellites are developed from the data perspective. [Data vault architecture diagram.](data_vault.png)

**[Information Marts](information_marts.sas):** Uses a multidimensional structure with star schema. Contains dimensions, which connect to transactional fact tables, periodic snapshot fact tables, and accumulation snapshot fact tables. [Information marts architecture diagram](information_marts.png).

**[Analytics](analysis.sas):** Analysing the transformed data in the data warehouse, to transform it into useful information and add value. Reporting on key figures, and applying statistical analysis techniques, including multiple logistic and linear regression, chi-squared test of independence, and ANOVA.

