\# Immigration \& Housing in the Netherlands



\*\*Exploratory Data Analysis • Statistical Tests • KPIs • Dashboards\*\*



\### Purpose



Understand how migration patterns relate to housing availability and identify simple, defensible KPIs to communicate the story clearly.



\### Key Questions



1\. How has \*\*housing availability (vacancy)\*\* evolved nationally and by region?

2\. How fast did \*\*immigration inflows\*\* grow, and what’s the most reliable way to describe the trend?

3\. Which categorical relationships are strongest (e.g., \*\*nationality, age, gender, motive/domain, status\*\*) and \*\*where\*\* do the significant deviations occur?



---



\## Data



\* \*\*Housing stock\*\*: `housing\_stock`



&nbsp; \* Columns: `id`, `status\_of\_occupancy` (occupied/unoccupied), `regions`, `period` (year), `owned\_by\_association`, `owned\_by\_other\_landlords`.

&nbsp; \* Derived: \*\*stock = owned\\\_by\\\_association + owned\\\_by\\\_other\\\_landlords\*\*.

\* \*\*Immigration flows by domain\*\*: `family\_final`, `study\_final`, `work\_final`, `asylum\_final`



&nbsp; \* Columns: `immigration\_year`, `amount\_immigrant`.

&nbsp; \* Combined conceptually into a \*\*total by year\*\* (sum across domains).



> Note: `regions` mixes provinces and municipalities; we optionally filter to the 12 provinces for province-level views.



---



\## Methods \& Workflow



\### 1) Data wrangling (Notebook)



\* Standardized datatypes, unified year fields (`period` vs `immigration\_year`), created \*\*stock\*\*.

\* Built national and region–year aggregates for \*\*occupied/unoccupied\*\*.

\* Combined immigration domains to get \*\*total inflow by year\*\*.

\* Produced tidy tables for Tableau (national series, province/municipality series, owner-type splits).



\### 2) Statistical Testing (Notebook)



\* \*\*Chi-Square\*\* tests of independence with \*\*standardized residual / cell-contribution heatmaps\*\* to reveal \*where\* deviations from independence occur (e.g., nationality × age, nationality × gender).

\* \*\*Cramér’s V\*\* for \*\*effect size (0–1)\*\* across categorical pairs and by domain (e.g., V of nationality×age within Family/Study/Work/Asylum).



\### 3) KPIs (Notebook)



\* \*\*Vacancy (availability) rate\*\* = unoccupied / (occupied + unoccupied).



&nbsp; \* \*\*National KPI:\*\* \\~\*\*5.9%\*\* in \*\*2024\*\* (down from \\~\*\*6.4%\*\* in 2012; \*\*−0.5 percentage points\*\* overall).

\* \*\*Immigration growth:\*\* computed \*\*YoY\*\* but emphasized \*\*5-year CAGR\*\* and an \*\*index (base=100)\*\* to avoid misleading spikes caused by low/zero prior-year bases.

\* Optional diagnostics: province-year correlations between immigration levels and vacancy rate.



\### 4) SQL (Staging \& Aggregation)



\*(High-level description of what we did — no code)\*



\* \*\*Staging\*\*: loaded housing and the four immigration domain tables into SQL (schema-aligned columns and types).

\* \*\*Cleaning\*\*: normalized region names (to one canonical label), ensured years are integers, and removed obvious duplicates.

\* \*\*Derived fields \& views\*\*:



&nbsp; \* Created a \*\*stock\*\* view from association + other landlords.

&nbsp; \* Built \*\*yearly national aggregates\*\* and \*\*region–year aggregates\*\* for occupied/unoccupied.

&nbsp; \* Created \*\*owner-type\*\* shares (Association vs Other Landlords) per region–year.

&nbsp; \* Materialized \*\*immigration totals by year\*\* by unioning the domain tables.

\* \*\*Exports\*\*: produced compact, analysis-ready views/tables for Tableau (national series, province series, owner splits).



\### 5) Tableau (Dashboards)



\* \*\*Design principles\*\*: consistent province colors across sheets; minimal labels; % formatting for rates.

\* \*\*Views built\*\*:



&nbsp; \* \*Period Trend per Province\* (area/stacked view with province labels).

&nbsp; \* \*Percentage Occupied/Unoccupied per Province\* — \*\*100% stacked bars\*\* with \*\*owner-type split\*\* (Association vs Other Landlords).

&nbsp; \* Additional stacked and line charts for immigration and housing stories.

\* \*\*Techniques used\*\*:



&nbsp; \* \*\*Measure Names/Measure Values\*\* to plot multiple measures and convert to \*\*% of total\*\*.

&nbsp; \* Province color \*\*synchronization\*\* (Edit Colors → Apply to all sheets using this field).

&nbsp; \* \*\*Dashboard filtering\*\* via “Use as Filter” + \*\*Apply to Worksheets → All Using This Data Source\*\* so province selections update all views.

\* \*\*Publishing\*\*: Tableau Public (web). Since the web editor doesn’t bundle multiple dashboards into one workbook with tabs, we connected separate dashboards with \*\*consistent colors\*\*, optional \*\*navigation buttons\*\*, and a \*\*menu/overview\*\* slide.



---



\## Findings (Short)



\* \*\*Availability\*\*: vacancy rate is \*\*below 6% nationally in 2024\*\*; path: lower through \\~2017, bump \\~2020–21, easing afterwards.

\* \*\*Immigration trend\*\*: large YoY swings (base effects). Trend is clearer with \*\*CAGR / index\*\*; use those in KPI cards.

\* \*\*Chi-Square\*\*: many tables significant (large N). Residual heatmaps highlight the \*\*specific nationality×age / nationality×gender cells\*\* driving significance.

\* \*\*Cramér’s V\*\*: overall \*\*small–to–moderate\*\* associations. Strongest around \*\*status ↔ motive/domain\*\*; \*\*gender\*\* is weakest. By domain, \*\*Study (\\~0.26) > Work (\\~0.15) > Family (\\~0.13) > Asylum (\\~0.11)\*\* for the age×nationality association.



---



\## What to Look For in the Dashboards



\* \*\*National KPI cards\*\*: vacancy %, immigration level trend (plus 5-yr CAGR).

\* \*\*Province views\*\*: who is tightest/loosest on vacancy (latest year), and how owner types differ.

\* \*\*Interactive filtering\*\*: click a province to update all views consistently.



---



\## Limitations



\* `regions` mixes geographic levels (province vs municipality); results are shown at both levels depending on the view.

\* Year gaps and very small prior-year counts create \*\*YoY volatility\*\*; hence the preference for \*\*CAGR\*\* and \*\*indexing\*\*.

\* Chi-square significance is common with large samples; interpretation relies on \*\*residuals\*\* and \*\*effect sizes (Cramér’s V)\*\* rather than p-values alone.



---



\## Next Steps



\* Build a tidy region hierarchy (province → municipality) for drill-down.

\* Track owner-type vacancy as a standing KPI by province and over time.

\* Add a compact “insight narrative” to the dashboards (callouts with KPI numbers and short context sentences).



---

[Sources](https://opendata.cbs.nl/statline/#/CBS/nl/navigatieScherm/thema)



