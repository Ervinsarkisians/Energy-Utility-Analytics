\# Energy Utility Analytics



\## Project Overview



This project analyzes energy utility operations across

customers, billing, energy consumption, assets,

maintenance activity, and service outages.



The objective is to transform operational data into

actionable business insights using SQL Server and

Power BI.



\## Business Objectives



\- Monitor customer activity

\- Analyze billing and payment performance

\- Identify energy consumption trends

\- Evaluate asset maintenance

\- Analyze outage frequency and duration

\- Improve operational visibility



\## Tools \& Technologies



\- SQL Server

\- T-SQL

\- Power BI

\- DAX

\- Power Query

\- Data Modeling

\- ETL



\## Data Pipeline



Raw Data

↓

SQL Staging

↓

Data Cleaning

↓

Transformation

↓

Analytics Tables

↓

Power BI Data Model

↓

Interactive Dashboard



\## Dashboard



!\[Executive Overview](Screenshots/01\_Executive\_Overview.png)



\## Customer Analysis



!\[Customer Overview](Screenshots/02\_Customer\_Overview.png)



\## Billing \& Payments



!\[Billing \& Payments](Screenshots/03\_Billing\_Payments.png)



\## Energy Usage



!\[Energy Usage](Screenshots/04\_Energy\_Usage.png)



\## Assets \& Maintenance



!\[Assets \& Maintenance](Screenshots/05\_Assets\_Maintenance.png)



\## Outage Analysis



!\[Outages](Screenshots/06\_Outages.png)



\## SQL Analysis



The SQL analysis includes:



\- Data exploration

\- Data validation

\- Data cleaning

\- Transformations

\- Aggregations

\- KPI calculations

\- Business analysis



\## Key Findings



\### Customer Overview



\- 150 customers support 200 utility accounts, indicating that some customers maintain multiple accounts.

\- September recorded the highest account creation volume with 35 accounts, representing 17.5% of the total accounts.

\- Account ownership is concentrated among a small number of customers, with the highest individual customers maintaining up to 9 accounts.



\### Billing \& Payments



\- Total billed amount was $82.08K compared with $81.53K in recorded payments, resulting in approximately 99% payment coverage.

\- The remaining outstanding balance was approximately $554.72.

\- Overdue bills were concentrated in specific months, with September recording the highest count at 21 overdue bills, followed by January with 20.

\- Annual billing volume peaked in 2023 at approximately $23.5K before declining to approximately $19.2K in 2024.



\### Energy Usage



\- Total recorded energy consumption was approximately 251.09K kWh.

\- Average recorded daily energy usage was approximately 502.18 kWh.

\- Approximately 45% of recorded usage events were classified as peak usage.

\- Peak usage activity varied across customers, with Kenneth recording the highest number of peak-usage events among the customers displayed.



\### Assets \& Maintenance



\- The infrastructure inventory contains 100 assets and 200 recorded maintenance events, representing approximately two maintenance events per asset.

\- Annual maintenance activity remained relatively stable from 2021 through 2024, ranging from 49 to 51 events per year.

\- Lines and transformers represent the largest asset categories within the infrastructure inventory.



\### Outage Analysis



\- The dataset contains 50 recorded outages affecting approximately 26K customers.

\- 2023 recorded the highest customer impact, with approximately 8.7K customers affected.

\- 2024 followed with approximately 6.4K affected customers.

\- Weather is a recurring recorded outage cause within the dataset.



\## Recommendations



\### Customer Management



\- Analyze multi-account customers to better understand account structures and improve customer segmentation.

\- Investigate periods of higher account creation, particularly September, to identify potential drivers of customer growth and align onboarding resources accordingly.



\### Billing \& Collections



\- Prioritize payment follow-up and customer outreach during months with historically higher overdue-bill volumes, particularly January and September.

\- Investigate the decline in annual billed amounts after 2023 by analyzing changes in account activity, energy usage, billing amounts, and customer composition.



\### Energy Management



\- Analyze peak-period consumption by customer, month, and rate plan to identify opportunities for demand-management initiatives.

\- Identify customers with consistently high peak-usage activity for targeted usage-monitoring and energy-efficiency programs.



\### Asset \& Maintenance Planning



\- Maintain proactive inspection and maintenance schedules for high-volume asset categories, particularly lines and transformers.

\- Combine asset age, maintenance frequency, and maintenance type to identify assets that may require replacement rather than continued repair.



\### Outage \& Reliability Management



\- Strengthen outage preparedness during periods associated with higher historical customer impact, with particular attention to weather-related events.

\- Analyze outage frequency and customer impact together to identify affected areas and events that create the greatest operational impact and should receive additional reliability planning.

\## Project Structure



SQL/

PowerBI/

Screenshots/

Data/

Documentation/



\## Skills Demonstrated



SQL Server | T-SQL | Power BI | DAX | Power Query |

ETL | Data Modeling | Data Cleaning | KPI Analysis

