** Old interpolation code to go at the end. also testing extrapolation.

clear
macro drop _all
eststo clear

// Set Working Directory
cd "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations"

* Interpolated values analysis-
*Create interpolated values- and also extrapolation test for now

use fmergedready, clear

local aggInd "extPoorCt costSolvePov SN_ITK_DEFCN HfinGap EfinGap illiterate GI WBLIndex noSafeWater noSafeSan noElec unemployedCt TfinGap EnfinGap si_pov_gini uSlumPop VC_DSR_GDPLS co2pgdp NRenShare PMrnPGap PLandPGap PLandGap vc_idp_tocv NPSI NRM NSCS"
local vUSDs = "Value_USD1 Value_USD2 Value_USD3 Value_USD4 Value_USD5 Value_USD6 Value_USD7 Value_USD8 Value_USD9 Value_USD10 Value_USD11 Value_USD12 Value_USD13 Value_USD14 Value_USD15 Value_USD16 Value_USD17"
local years "2012 2013 2014 2015 2016 2017"

reshape long `aggInd' `vUSDs' polity2, i(RecipientName) j(year 2012 2013 2014 2015 2016 2017)

keep RecipientName year `aggInd' `vUSDs' polity2

foreach indicator in `aggInd' {
by RecipientName: ipolate `indicator' year, gen(ip`indicator') epolate
replace `indicator' = ip`indicator'
drop ip`indicator'
}

reshape wide `aggInd' `vUSDs' polity2, i(RecipientName) j(year 2012 2013 2014 2015 2016 2017)

* Collect summary statistics
estpost sum
esttab . using "ipsumstatsWide.rtf", cells("mean sd count") noobs replace label

// Stationary (within single-year) analysis
foreach year in `years' {
*Put aid in indicator, not goal terms
gen aidextPoorCt`year' = Value_USD1`year'
gen aidcostSolvePov`year' = Value_USD1`year'
gen aidSN_ITK_DEFCN`year' = Value_USD2`year'
gen aidHfinGap`year' = Value_USD3`year'
gen aidEfinGap`year' = Value_USD4`year'
gen aidilliterate`year' = Value_USD4`year'
gen aidGI`year' = Value_USD5`year'
gen aidWBLIndex`year' = Value_USD5`year'
gen aidnoSafeWater`year' = Value_USD6`year'
gen aidnoSafeSan`year' = Value_USD6`year'
gen aidnoElec`year' = Value_USD7`year'
gen aidunemployedCt`year' = Value_USD8`year'
gen aidTfinGap`year' = Value_USD9`year'
gen aidEnfinGap`year' = Value_USD9`year'
gen aidsi_pov_gini`year' = Value_USD10`year'
gen aiduSlumPop`year' = Value_USD11`year'
gen aidVC_DSR_GDPLS`year' = Value_USD11`year'
gen aidco2pgdp`year' = Value_USD12`year'
gen aidNRenShare`year' = Value_USD13`year'
gen aidPMrnPGap`year' = Value_USD14`year'
gen aidPLandPGap`year' = Value_USD15`year'
gen aidPLandGap`year' = Value_USD15`year'
gen aidvc_idp_tocv`year' = Value_USD16`year'
gen aidNPSI`year' = Value_USD16`year'
gen aidNRM`year' = Value_USD17`year'
gen aidNSCS`year' = Value_USD17`year'
drop Value_USD1`year' Value_USD2`year' Value_USD3`year' Value_USD4`year' Value_USD5`year' Value_USD6`year' Value_USD7`year' Value_USD8`year' Value_USD9`year' Value_USD10`year' Value_USD11`year' Value_USD12`year' Value_USD13`year' Value_USD14`year' Value_USD15`year' Value_USD16`year' Value_USD17`year'

*Compute shares of need, among only those with aid data present
foreach indicator in `aggInd' {
egen ti`indicator'`year' = total(cond(aid`indicator'`year' !=  ., `indicator'`year', .))
gen ns`indicator'`year' = `indicator'`year'/ti`indicator'`year'
*Save variable space
drop ti`indicator'`year'
}

*Compute shares of aid
foreach indicator in `aggInd' {
egen ta`indicator'`year' = total(cond(`indicator'`year' != ., aid`indicator'`year', .))
gen ais`indicator'`year' = aid`indicator'`year'/ta`indicator'`year'
*Save variable space
drop ta`indicator'`year'
}

*Note: corrected aidshare to deal with few indicator observation years- aidshare should be among those (denom/total only including) which have need data? Similar correction for needshare. Judge only overlapping cases.
*This may actually be a somewhat different interpretation, since perhaps aid should or can only be given to countries for which there is data available on indicators. So the old dofile is still saved.

*Need and aid deviation (shares), computed for each need indicator
foreach indicator in `aggInd' {
gen Def`indicator'`year' = ais`indicator'`year' - ns`indicator'`year'
}

*Create the mismatch index (and variants) for each indicator
foreach indicator in `aggInd' {
egen mm`indicator'`year' = mean(Def`indicator'`year')
gen adef`indicator'`year' = abs(Def`indicator'`year')
egen amm`indicator'`year' = mean(adef`indicator'`year')
egen maxamm`indicator'`year' = max(adef`indicator'`year')
egen minamm`indicator'`year' = min(adef`indicator'`year')
*gen sdef`indicator'`year' = (Def`indicator'`year')^2
*egen smm`indicator'`year' = mean(sdef`indicator'`year')
}

*Spearman's rank coefficient analysis
*Take advantage of the fact shares are ordinally the same as actual values.
foreach indicator in `aggInd'{
capture: spearman ais`indicator'`year' ns`indicator'`year'
capture: gen sp`indicator'`year' = r(rho)
*matrix A = r(rho)
*esttab matrix(A, fmt(%5.2f)) using sp`indicator'`year'.rtf, replace
*eststo clear
}

}

* Starting at a ranking or bump chart
* Need to interpolate first due to data availability?
* Scratch this actually, since it's persistently broken
*foreach `year' in `years' {
*foreach `indicator' in `aggInd' {
*egen rankaid`indicator'`year' = rank(-ais`indicator'`year')
*egen rankneed`indicator'`year' = rank(-ns`indicator'`year')
*}
*}

*Save the wide format dataset
save ipmerged_IDOS_wide, replace
use ipmerged_IDOS_wide, clear

* Cross-time Analysis
* Tracking Absolute Mismatch over time for all countries
preserve
keep amm* minamm* maxamm*
duplicates drop
gen trickVar = "a"
local ammInds "ammextPoorCt ammcostSolvePov ammSN_ITK_DEFCN ammHfinGap ammEfinGap ammilliterate ammGI ammWBLIndex ammnoSafeWater ammnoSafeSan ammnoElec ammunemployedCt ammTfinGap ammEnfinGap ammsi_pov_gini ammuSlumPop ammVC_DSR_GDPLS ammco2pgdp ammNRenShare ammPMrnPGap ammPLandPGap ammPLandGap ammvc_idp_tocv ammNPSI ammNRM ammNSCS"
local minammInds "minammextPoorCt minammcostSolvePov minammSN_ITK_DEFCN minammHfinGap minammEfinGap minammilliterate minammGI minammWBLIndex minammnoSafeWater minammnoSafeSan minammnoElec minammunemployedCt minammTfinGap minammEnfinGap minammsi_pov_gini minammuSlumPop minammVC_DSR_GDPLS minammco2pgdp minammNRenShare minammPMrnPGap minammPLandPGap minammPLandGap minammvc_idp_tocv minammNPSI minammNRM minammNSCS"
local maxammInds "maxammextPoorCt maxammcostSolvePov maxammSN_ITK_DEFCN maxammHfinGap maxammEfinGap maxammilliterate maxammGI maxammWBLIndex maxammnoSafeWater maxammnoSafeSan maxammnoElec maxammunemployedCt maxammTfinGap maxammEnfinGap maxammsi_pov_gini maxammuSlumPop maxammVC_DSR_GDPLS maxammco2pgdp maxammNRenShare maxammPMrnPGap maxammPLandPGap maxammPLandGap maxammvc_idp_tocv maxammNPSI maxammNRM maxammNSCS"
reshape long `ammInds' `minammInds' `maxammInds', i(trickVar) j(year)
drop trickVar

*For aesthetics and graph production
label var ammextPoorCt "Count of Extreme Poor" 
label var ammcostSolvePov "Cost to Solve Poverty (Perf. Targ.)"
label var ammSN_ITK_DEFCN "Count of Undernourished"
label var ammHfinGap "Health Financing Gap"
label var ammEfinGap "Education Financing Gap"
label var ammilliterate "Count of Illiterate"
label var ammGI "UN HDI Gender Ineq."
label var ammWBLIndex "Women Business and the Law Index"
label var ammnoSafeWater "Count Without Safe Drinking Water"
label var ammnoSafeSan "Count Without Safe Sanitation"
label var ammnoElec "Count Without Electricity"
label var ammunemployedCt "Count of Unemployed"
label var ammTfinGap "Transport Financing Gap"
label var ammEnfinGap "Energy Financing Gap"
label var ammsi_pov_gini "Gini Index"
label var ammuSlumPop "Urban Slum Population"
label var ammVC_DSR_GDPLS "Economic Loss to Disasters"
label var ammco2pgdp "CO2 per unit of GDP"
label var ammNRenShare "Share Non-renewable Energy"
label var ammPMrnPGap "Marine Protected Areas Percentage Gap"
label var ammPLandPGap "Protected Land Percentage Gap"
label var ammPLandGap "Protected Land Gap"
label var ammvc_idp_tocv "Internally Displaced Persons (Violence)"
label var ammNPSI "Public Sector and Institutions Need"
label var ammNRM "Revenue Mobilization Need"
label var ammNSCS "Statistical Capacity Need"

* Produce indicator amm graphs over time.
* Old code: just the means
tsset year
foreach indicator in `ammInds'{
twoway (connect `indicator' year,  cmissing(n)), ytitle(Mean Absolute Mismatch) yscale(range(0 0.05)) ylabel(#5) ttitle(Year) title(`: var label `indicator'')
* Special treament including missing values or cutting the number of years for TFinGap or Urban Slum Pop? Could make this loop with an if/else split.
graph save `indicator', replace
}

* Create a table of graphs
graph combine "ammextPoorCt" "ammcostSolvePov" "ammSN_ITK_DEFCN" "ammHfinGap" "ammEfinGap" "ammilliterate" "ammGI" "ammWBLIndex" "ammnoSafeWater", iscale(0.4)
graph export ipfirstNine, as(png) name("Graph") replace
graph combine  "ammnoSafeSan" "ammnoElec" "ammunemployedCt" "ammTfinGap" "ammEnfinGap" "ammsi_pov_gini" "ammuSlumPop" "ammVC_DSR_GDPLS" "ammco2pgdp", iscale(0.4)
graph export ipsecondNine, as(png) name("Graph") replace
graph combine "ammNRenShare" "ammPMrnPGap" "ammPLandPGap" "ammPLandGap" "ammvc_idp_tocv" "ammNPSI" "ammNRM" "ammNSCS", iscale(0.4)
graph export ipthirdEight, as(png) name("Graph") replace

* New code with min and max graphs
tsset year
foreach indicator in `aggInd'{
twoway (connect amm`indicator' year,  cmissing(n)) (connect minamm`indicator' year,  cmissing(n)) (connect maxamm`indicator' year,  cmissing(n)), ytitle(Absolute Mismatch)  ttitle(Year) title(Max-Mean-Min: `: var label amm`indicator'') legend(off)
graph save ipmaxtominamm`indicator', replace
}

* Create a table of graphs
graph combine "maxtominammextPoorCt" "maxtominammcostSolvePov" "maxtominammSN_ITK_DEFCN" "maxtominammHfinGap" "maxtominammEfinGap" "maxtominammilliterate" "maxtominammGI" "maxtominammWBLIndex" "maxtominammnoSafeWater", iscale(0.35)
graph export ipmtmfirstNine, as(png) name("Graph") replace
graph combine  "maxtominammnoSafeSan" "maxtominammnoElec" "maxtominammunemployedCt" "maxtominammTfinGap" "maxtominammEnfinGap" "maxtominammsi_pov_gini" "maxtominammuSlumPop" "maxtominammVC_DSR_GDPLS" "maxtominammco2pgdp", iscale(0.35)
graph export ipmtmsecondNine, as(png) name("Graph") replace
graph combine "maxtominammNRenShare" "maxtominammPMrnPGap" "maxtominammPLandPGap" "maxtominammPLandGap" "maxtominammvc_idp_tocv" "maxtominammNPSI" "maxtominammNRM" "maxtominammNSCS", iscale(0.35)
graph export ipmtmthirdEight, as(png) name("Graph") replace

* Produce a global amm graph across all indicators
egen totAmm = rowmean(amm*)
twoway (connect totAmm year), ytitle(Absolute Mismatch) yscale(range(0 0.05)) ylabel(#7) title(Worldwide Absolute Mismatch (Indicators Eq Weight))
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipwwAggAMM.png", as(png) name("Graph") replace
* Look at regular mismatch or squared mismatch if desired. Not very interpretable though.

* Global amm graph, but weighting each goal equally.
egen ammSDG1 = rowmean(ammextPoorCt ammcostSolvePov)
gen ammSDG2 = ammSN_ITK_DEFCN
gen ammSDG3 = ammHfinGap
egen ammSDG4 = rowmean(ammEfinGap ammilliterate)
egen ammSDG5 = rowmean(ammGI ammWBLIndex)
egen ammSDG6 = rowmean(ammnoSafeWater ammnoSafeSan)
gen ammSDG7 = ammnoElec
gen ammSDG8 = ammunemployedCt
egen ammSDG9 = rowmean(ammTfinGap ammEnfinGap)
gen ammSDG10 = ammsi_pov_gini
egen ammSDG11 = rowmean(ammuSlumPop ammVC_DSR_GDPLS)
gen ammSDG12 = ammco2pgdp
gen ammSDG13 = ammNRenShare
gen ammSDG14 = ammPMrnPGap
egen ammSDG15 = rowmean(ammPLandGap ammPLandPGap)
egen ammSDG16 = rowmean(ammvc_idp_tocv ammNPSI)
egen ammSDG17 = rowmean(ammNRM ammNSCS)
egen etotAmm = rowmean(ammSDG*)
twoway (connect etotAmm year), ytitle(Mean Absolute Mismatch) yscale(range(0 0.05)) ylabel(#7) title(Worldwide Mean Absolute Mismatch (Goals Eq Weight))
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipewwAggAMM.png", as(png) name("Graph") replace

*Throwing mins and maxes into the WW graphs
*First, eq weight to all indicators
egen mintotAmm = rowmin(minamm*)
egen maxtotAmm = rowmax(maxamm*)
twoway (connect totAmm year) (connect mintotAmm year) (connect maxtotAmm year), ytitle(Absolute Mismatch) title(Max-Mean-Min Absolute Mismatch (Indicators Eq Weight)) legend(off)
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipMtMwwAggAMM.png", as(png) name("Graph") replace

*Weighting by goal
twoway (connect etotAmm year) (connect mintotAmm year) (connect maxtotAmm year), ytitle(Absolute Mismatch) title(Max-Mean-Min Absolute Mismatch (Goals Eq Weight)) legend(off)
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipeMtMwwAggAMM.png", as(png) name("Graph") replace

* Back to normal
restore

*Spearman graphing
preserve

keep sp*
drop sp_*
duplicates drop
gen trickVar = "a"
local spInds "spextPoorCt spcostSolvePov spSN_ITK_DEFCN spHfinGap spEfinGap spilliterate spGI spWBLIndex spnoSafeWater spnoSafeSan spnoElec spunemployedCt spTfinGap spEnfinGap spsi_pov_gini spuSlumPop spVC_DSR_GDPLS spco2pgdp spNRenShare spPMrnPGap spPLandPGap spPLandGap spvc_idp_tocv spNPSI spNRM spNSCS"
reshape long `spInds', i(trickVar) j(year)
drop trickVar

label var spextPoorCt "Count of Extreme Poor" 
label var spcostSolvePov "Cost to Solve Poverty (Perf. Targ.)"
label var spSN_ITK_DEFCN "Count of Undernourished"
label var spHfinGap "Health Financing Gap"
label var spEfinGap "Education Financing Gap"
label var spilliterate "Count of Illiterate"
label var spGI "UN HDI Gender Ineq."
label var spWBLIndex "Women Business and the Law Index"
label var spnoSafeWater "Count Without Safe Drinking Water"
label var spnoSafeSan "Count Without Safe Sanitation"
label var spnoElec "Count Without Electricity"
label var spunemployedCt "Count of Unemployed"
label var spTfinGap "Transport Financing Gap"
label var spEnfinGap "Energy Financing Gap"
label var spsi_pov_gini "Gini Index"
label var spuSlumPop "Urban Slum Population"
label var spVC_DSR_GDPLS "Economic Loss to Disasters"
label var spco2pgdp "CO2 per unit of GDP"
label var spNRenShare "Share Non-renewable Energy"
label var spPMrnPGap "Marine Protected Areas Percentage Gap"
label var spPLandPGap "Protected Land Percentage Gap"
label var spPLandGap "Protected Land Gap"
label var spvc_idp_tocv "Internally Displaced Persons (Violence)"
label var spNPSI "Public Sector and Institutions Need"
label var spNRM "Revenue Mobilization Need"
label var spNSCS "Statistical Capacity Need"

* Produce indicator sp graphs over time.
tsset year
foreach indicator in `spInds'{
twoway (connect `indicator' year,  cmissing(n)), ytitle(Spearman Coefficient) yscale(range(0 1)) ylabel(#5) ttitle(Year) title(`: var label `indicator'')
* Special treament including missing values or cutting the number of years for TFinGap or Urban Slum Pop? Could make this loop with an if/else split.
graph save `indicator', replace
}

* Create a table of graphs
graph combine "spextPoorCt" "spcostSolvePov" "spSN_ITK_DEFCN" "spHfinGap" "spEfinGap" "spilliterate" "spGI" "spWBLIndex" "spnoSafeWater", iscale(0.4)
graph export ipspfirstNine, as(png) name("Graph") replace
graph combine  "spnoSafeSan" "spnoElec" "spunemployedCt" "spTfinGap" "spEnfinGap" "spsi_pov_gini" "spuSlumPop" "spVC_DSR_GDPLS" "spco2pgdp", iscale(0.4)
graph export ipspsecondNine, as(png) name("Graph") replace
graph combine "spNRenShare" "spPMrnPGap" "spPLandPGap" "spPLandGap" "spvc_idp_tocv" "spNPSI" "spNRM" "spNSCS", iscale(0.4)
graph export ipspthirdEight, as(png) name("Graph") replace

* Produce a global amm graph across all indicators
egen totsp = rowmean(sp*)
twoway (connect totsp year), ytitle(Spearman Coefficient) yscale(range(0 0.05)) ylabel(#7) title(Mean Spearman Coeff (Indicators Eq Weight))
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipspwwAggAMM.png", as(png) name("Graph") replace
* Look at regular mismatch or squared mismatch if desired. Not very interpretable though.

* Global amm graph, but weighting each goal equally.
egen spSDG1 = rowmean(spextPoorCt spcostSolvePov)
gen spSDG2 = spSN_ITK_DEFCN
gen spSDG3 = spHfinGap
egen spSDG4 = rowmean(spEfinGap spilliterate)
egen spSDG5 = rowmean(spGI spWBLIndex)
egen spSDG6 = rowmean(spnoSafeWater spnoSafeSan)
gen spSDG7 = spnoElec
gen spSDG8 = spunemployedCt
egen spSDG9 = rowmean(spTfinGap spEnfinGap)
gen spSDG10 = spsi_pov_gini
egen spSDG11 = rowmean(spuSlumPop spVC_DSR_GDPLS)
gen spSDG12 = spco2pgdp
gen spSDG13 = spNRenShare
gen spSDG14 = spPMrnPGap
egen spSDG15 = rowmean(spPLandGap spPLandPGap)
egen spSDG16 = rowmean(spvc_idp_tocv spNPSI)
egen spSDG17 = rowmean(spNRM spNSCS)
egen etotsp = rowmean(spSDG*)
twoway (connect etotsp year), ytitle(Spearman Coefficient) yscale(range(0 1)) ylabel(#7) title(Mean Spearman Coeff (Goal Eq Weight))
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\ipewwAggsp.png", as(png) name("Graph") replace

*Back to normal
restore

* More micro and cross-time analysis
* Get into long form
local DefInds "DefextPoorCt DefcostSolvePov DefSN_ITK_DEFCN DefHfinGap DefEfinGap Defilliterate DefGI DefWBLIndex DefnoSafeWater DefnoSafeSan DefnoElec DefunemployedCt DefTfinGap DefEnfinGap Defsi_pov_gini DefuSlumPop DefVC_DSR_GDPLS Defco2pgdp DefNRenShare DefPMrnPGap DefPLandPGap DefPLandGap Defvc_idp_tocv DefNPSI DefNRM DefNSCS"
local aisInds "aisextPoorCt aiscostSolvePov aisSN_ITK_DEFCN aisHfinGap aisEfinGap aisilliterate aisGI aisWBLIndex aisnoSafeWater aisnoSafeSan aisnoElec aisunemployedCt aisTfinGap aisEnfinGap aissi_pov_gini aisuSlumPop aisVC_DSR_GDPLS aisco2pgdp aisNRenShare aisPMrnPGap aisPLandPGap aisPLandGap aisvc_idp_tocv aisNPSI aisNRM aisNSCS"
local nsInds "nsextPoorCt nscostSolvePov nsSN_ITK_DEFCN nsHfinGap nsEfinGap nsilliterate nsGI nsWBLIndex nsnoSafeWater nsnoSafeSan nsnoElec nsunemployedCt nsTfinGap nsEnfinGap nssi_pov_gini nsuSlumPop nsVC_DSR_GDPLS nsco2pgdp nsNRenShare nsPMrnPGap nsPLandPGap nsPLandGap nsvc_idp_tocv nsNPSI nsNRM nsNSCS"
local aidInds "aidextPoorCt aidcostSolvePov aidSN_ITK_DEFCN aidHfinGap aidEfinGap aidilliterate aidGI aidWBLIndex aidnoSafeWater aidnoSafeSan aidnoElec aidunemployedCt aidTfinGap aidEnfinGap aidsi_pov_gini aiduSlumPop aidVC_DSR_GDPLS aidco2pgdp aidNRenShare aidPMrnPGap aidPLandPGap aidPLandGap aidvc_idp_tocv aidNPSI aidNRM aidNSCS"
reshape long `aggInd' `aidInds' `DefInds' `aisInds' `nsInds' polity2, i(RecipientName) j(year `years')

*Get sumstats and save this long format
preserve
keep `aggInd' `aidInds' polity2
estpost sum
esttab . using "ipsumstatsLong.rtf", label cells("mean sd count") noobs replace
restore
save merged_IDOS_long, replace

* Disproportionate country analysis
* Make more space
drop mm* amm* sp*
foreach indicator in `aggInd'{
preserve
keep if abs(Def`indicator') > 0.1 & Def`indicator' != .
capture: export excel RecipientName year Def`indicator' `indicator' aid`indicator' ais`indicator' ns`indicator' using "ipdisC`indicator'.xlsx", firstrow(var) replace
restore
}

*Spearman analysis across time by indicator
foreach indicator in `aggInd'{
capture: spearman ais`indicator' ns`indicator'
matrix A = r(rho)
esttab matrix(A, fmt(%5.2f)) using ipsp`indicator'.rtf, replace
eststo clear
}

*Regression analysis across time by indicator
*Prep for a panel analysis
encode RecipientName, gen(rName)
xtset rName year
*Set up some labels
* SHOULD I CHANGE THE AIDSHARE LABELS BACK TO SDG NAMES??? Yes.
label var aisextPoorCt "SDG 1 (Aid Share)" 
label var aiscostSolvePov "SDG 1 (Aid Share)"
label var aisSN_ITK_DEFCN "SDG 2 (Aid Share)"
label var aisHfinGap "SDG 3 (Aid Share)"
label var aisEfinGap "SDG 4 (Aid Share)"
label var aisilliterate "SDG 4 (Aid Share)"
label var aisGI "SDG 5 (Aid Share)"
label var aisWBLIndex "SDG 5 (Aid Share)"
label var aisnoSafeWater "SDG 6 (Aid Share)"
label var aisnoSafeSan "SDG 6 (Aid Share)"
label var aisnoElec "SDG 7 (Aid Share)"
label var aisunemployedCt "SDG 8 (Aid Share)"
label var aisTfinGap "SDG 9 (Aid Share)"
label var aisEnfinGap "SDG 9 (Aid Share)"
label var aissi_pov_gini "SDG 10 (Aid Share)"
label var aisuSlumPop "SDG 11 (Aid Share)"
label var aisVC_DSR_GDPLS "SDG 11 (Aid Share)"
label var aisco2pgdp "SDG 12 (Aid Share)"
label var aisNRenShare "SDG 13 (Aid Share)"
label var aisPMrnPGap "SDG 14 (Aid Share)"
label var aisPLandPGap "SDG 15 (Aid Share)"
label var aisPLandGap "SDG 15 (Aid Share)"
label var aisvc_idp_tocv "SDG 16 (Aid Share)"
label var aisNPSI "SDG 16 (Aid Share)"
label var aisNRM "SDG 17 (Aid Share)"
label var aisNSCS "SDG 17 (Aid Share)"
label var nsextPoorCt "Count of Extreme Poor (Need Share)" 
label var nscostSolvePov "Cost to Solve Poverty (Perf. Targ.) (Need Share)"
label var nsSN_ITK_DEFCN "Count of Undernourished (Need Share)"
label var nsHfinGap "Health Financing Gap (Need Share)"
label var nsEfinGap "Education Financing Gap (Need Share)"
label var nsilliterate "Count of Illiterate (Need Share)"
label var nsGI "UN HDI Gender Ineq. (Need Share)"
label var nsWBLIndex "Women Business and the Law Index (Need Share)"
label var nsnoSafeWater "Count Without Safe Drinking Water (Need Share)"
label var nsnoSafeSan "Count Without Safe Sanitation (Need Share)"
label var nsnoElec "Count Without Electricity (Need Share)"
label var nsunemployedCt "Count of Unemployed (Need Share)"
label var nsTfinGap "Transport Financing Gap (Need Share)"
label var nsEnfinGap "Energy Financing Gap (Need Share)"
label var nssi_pov_gini "Gini Index (Need Share)"
label var nsuSlumPop "Urban Slum Population (Need Share)"
label var nsVC_DSR_GDPLS "Economic Loss to Disasters (Need Share)"
label var nsco2pgdp "CO2 per unit of GDP (Need Share)"
label var nsNRenShare "Share Non-renewable Energy (Need Share)"
label var nsPMrnPGap "Marine Protected Areas Percentage Gap (Need Share)"
label var nsPLandPGap "Protected Land Percentage Gap (Need Share)"
label var nsPLandGap "Protected Land Gap (Need Share)"
label var nsvc_idp_tocv "Internally Displaced Persons (Violence) (Need Share)"
label var nsNPSI "Public Sector and Institutions Need (Need Share)"
label var nsNRM "Revenue Mobilization Need (Need Share)"
label var nsNSCS "Statistical Capacity Need (Need Share)"
label var polity2 "Polity (Revised) Combined Democracy Score"
*Execute regressions
foreach indicator in `aggInd' {
capture: reg ais`indicator' ns`indicator', robust
capture: eststo ncols`indicator'
*Throw in controls, and print their output. Democracy/polity 2, fixed effects, and eventually institutions and domestic resource mobilization.
capture: reg ais`indicator' ns`indicator' polity2, robust
capture: eststo p2ols`indicator'
capture: reg ais`indicator' ns`indicator' polity2 NPSI, robust
capture: eststo winstp`indicator'
capture: reg ais`indicator' ns`indicator' polity2 NPSI NRM, robust
capture: eststo winstdrm`indicator'
capture: esttab ncols`indicator' p2ols`indicator' winstp`indicator' winstdrm`indicator' using "ipregs`indicator'.rtf", label replace compress
eststo clear
}

*Across all indicators/sectors regressions.
egen avgais = rowmean(ais*)
egen avgns = rowmean(ns*)
capture: reg avgais avgns, robust
capture: eststo avgncols
*Throw in controls, and print their output. Democracy/polity 2, fixed effects, and eventually institutions and domestic resource mobilization.
capture: reg avgais avgns polity2, robust
capture: eststo avgp2ols
capture: reg avgais avgns polity2 NPSI, robust
capture: eststo avgwinstp
capture: reg avgais avgns polity2 NPSI NRM, robust
capture: eststo avgwinstdrm
capture: esttab avgncols avgp2ols avgwinstp avgwinstdrm using "ipavgregs.rtf", label replace compress

save ipmerged_IDOs_end, replace

// Regional analysis
* Reload the whole dataset I guess. Need the preserve/restore for other stuff