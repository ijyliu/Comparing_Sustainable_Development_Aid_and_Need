* Set working directory here.

use merged_IDOS_wide, clear

* Cross-time Analysis
* Tracking Absolute Mismatch over time for all countries
keep amm*
duplicates drop
gen trickVar = "a"
local ammInds "ammextPoorCt ammcostSolvePov ammSN_ITK_DEFCN ammHfinGap ammEfinGap ammilliterate ammwomNoDecCt ammunpaidDomGap ammpopUnpaidDomGap ammnoSafeWater ammnoSafeSan ammnoElec ammunemployedCt ammTfinGap ammEnfinGap ammsi_pov_gini ammuSlumPop ammVC_DSR_GDPLS ammco2pgdp ammNRenShare ammPMrnPGap ammPLandPGap ammPLandGap ammvc_idp_tocv ammNPSI ammNRM ammNSCS"
reshape long `ammInds', i(trickVar) j(year)
drop trickVar

*For aesthetics and graph production
label var ammextPoorCt "Count of Extreme Poor" 
label var ammcostSolvePov "Cost to Solve Poverty (Perf. Targ.)"
label var ammSN_ITK_DEFCN "Count of Undernourished"
label var ammHfinGap "Health Financing Gap"
label var ammEfinGap "Education Financing Gap"
label var ammilliterate "Count of Illiterate"
label var ammwomNoDecCt "Women Without Decision Authority"
label var ammunpaidDomGap "Gap in Unpaid Dom. Labor"
label var ammpopUnpaidDomGap "Pop. Weighted Gap Unpaid Dom. Labor"
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
tsset year
foreach indicator in `ammInds'{
twoway (tsline `indicator',  cmissing(n)), ytitle(Mean Absolute Mismatch) yscale(range(0 0.05)) ylabel(#5) ttitle(Year) title(`: var label `indicator'')
* Special treament including missing values or cutting the number of years for TFinGap or Urban Slum Pop? Could make this loop with an if/else split.
graph save `indicator', replace
}
* Create a table of graphs
graph combine "ammextPoorCt" "ammcostSolvePov" "ammSN_ITK_DEFCN" "ammHfinGap" "ammEfinGap" "ammilliterate" "ammwomNoDecCt" "ammunpaidDomGap" "ammpopUnpaidDomGap", iscale(0.4)
graph export firstNine, as(png) name("Graph") replace
graph combine "ammnoSafeWater" "ammnoSafeSan" "ammnoElec" "ammunemployedCt" "ammTfinGap" "ammEnfinGap" "ammsi_pov_gini" "ammuSlumPop" "ammVC_DSR_GDPLS", iscale(0.4)
graph export secondNine, as(png) name("Graph") replace
graph combine "ammco2pgdp" "ammNRenShare" "ammPMrnPGap" "ammPLandPGap" "ammPLandGap" "ammvc_idp_tocv" "ammNPSI" "ammNRM" "ammNSCS", iscale(0.4)
graph export thirdNine, as(png) name("Graph") replace

sum amm*