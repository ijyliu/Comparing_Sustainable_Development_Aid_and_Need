// IDOS Research Paper
// Sustainable Development Aid and Need
// Isaac Liu

*****************************************************************************

clear
macro drop _all

// Set paths
* The root directory line below should be the only setting which a user has to customize for their computer
global Root = "~/repo/Comparing_Sustainable_Development_Aid_and_Need"
global Input = "${Root}/Input"
global Output = "${Root}/Output"
global Intermediate_Data = "${Output}/Intermediate_Data"
global Intermediate_Figures = "${Output}/Intermediate_Figures"
global Tables = "${Output}/Tables"
global Regressions = "${Output}/Regressions"
global Figures = "${Output}/Figures"

* Programs needed
ssc install wbopendata, replace
ssc install estout, replace

*****************************************************************************

// Setting up Aid Data

// Download SDG Financing Data from: https://sdg-financing-lab.oecd.org/explore?country=All%20providers&distribution=providers&finance=Disbursement&from=2012&oda=true&oof=false&other%20private%20flows=false&private%20grants=false&target=All%20Recipients&to=2017

// Convert to XLSX File Format, load into Stata
import excel "${Input}/AP ODA 12-17 Dis.xlsx", firstrow

// Data Cleaning- Variable Renaming
label var Value_USD "Disbursements, Millions USD"
rename Name SDG_Name

// Check for missing values and outliers
sum
// Years and SDG Numbers appear to present no clear inconsistencies and there is no missing data.
// Check for Value_USD outliers
sort RecipientName
by RecipientName: sum Value_USD

// Scanning the output we can see that Afghanistan, Turkey, and a few others receive massive amounts of aid. Concerning is the fact Afghanistan, for example has mean aid at least 3 times higher than the Asia, Middle East, and South Asia regions, which does not make sense if regional aggregates contains Afghan aid. So for future, we note that regional data may not be particularly reliable.

// One possibility is that these are allocations for regional projects, but this does not appear to be the case when using the Financing Lab's Interface- as Asia as a region and individual country of analysis have the same values.

// Check on very large values
// Afghanistan has a max value of 1815.86
// Cuba has a max of 2578.46
// Cote d`Ivoire has a max of 2341.87
// Egypt has a max of 1977.05
// Myanmar has a max of 3855.84
browse if Value_USD > 1000 & RecipientName != "Bilateral, unspecified"
// Massive expense on "Institutions" in Afgh makes sense given the war
// Many other very large disbursements are under goal 17- "Partnerships for the goals." Examples include Cuba for 2.5B in 2016, similar figure for Ivory Coast in 2012, about 4B for Myanmar 2013.
// These findings throw some doubt onto the coding behind the algorithm's detection of goal 17 projects. Goal 17 generally aims for targets relating to ODA, FDI, remittances, debt service, technology, trade, and capacity building (statistical, technical, etc). Sample projects are not readily available to see specifics on this classification. But these large amounts of aid, at least for Cuba and Myanmar could represent responses to normalization of diplomatic relations and democratization over this period; Cuba normalized relations with the US around 2015, and Myanmar began to democratize in the early 2010s, perhaps leading to "partnerships" based aid.
// Other allocations over 1B generally appear reasonable- for example, India has a massive population, and Egypt has the largest population in the Arab World. Nigeria and Pakistan are massive nations well known to rely on aid and received help with health and energy. Turkey and Vietnam received allocations which were not particularly unbelievable given their size and strategic importance. Serbia received about 1B for partnerships towards the goals in 2017 which does not appear out of the question given past ethnic conflict.

// Check other variables for consistency
tab DonorName
// All "All Donors", good
tab Category
// All "ODA", good
tab TypeFlow
// All "Disbursements", good
// Hence these variables are unneeded
drop DonorName Category TypeFlow

// Methodological issue: OECD Separates aid flows for each country, year, sdg into two categories by the indicator "Double_Count." One observation has Double_Count as 0 and the other as 1. A zero indicates the sum of disbursements for projects falling only under that SDG- a one indicates projects falling under multiple SDGs. 

// Although this is an interesting direction for further analysis, here we are not interested in multiple allocation and simply sum the values.

collapse (sum) Value_USD, by(Year RecipientName SDG_num)

// Aid- Move data into a wider format
reshape wide Value_USD, i(Year RecipientName) j(SDG_num)

// Put in widest format
reshape wide Value*, i(RecipientName) j(Year)

// Save dataset
save "${Intermediate_Data}/Clean_Disbursements", replace

*****************************************************************************

// Setting up Need Data

// Fetching all needed indicators from WBOpenData for 2012 to 2017
wbopendata, indicator(SP.POP.TOTL; NY.GDP.MKTP.PP.KD; AG.LND.TOTL.K2; SI.POV.DDAY; SI.POV.GAPS; SH.XPD.CHEX.PP.CD; SP.DYN.LE00.IN; SE.XPD.TOTL.GD.ZS; SE.ADT.LITR.ZS; SH.H2O.SMDW.ZS; SH.STA.SMSS.ZS; EG.ELC.ACCS.ZS; NY.GDP.PCAP.KD.ZG; SL.UEM.TOTL.ZS; SI.POV.GINI; EN.POP.SLUM.UR.ZS; SP.URB.TOTL; EN.ATM.CO2E.PP.GD.KD; EG.ELC.RNEW.ZS; ER.LND.PTLD.ZS; ER.MRN.PTMR.ZS; VC.IDP.TOCV; IQ.CPA.PUBS.XQ; IQ.CPA.REVN.XQ; IQ.SCI.OVRL; SL.TLF.TOTL.IN; SG.DMK.ALLD.FN.ZS; SP.POP.1564.FE.IN; SG.TIM.UWRK.FE; SG.TIM.UWRK.MA; IE.PPI.TRAN.CD; IE.PPI.ENGY.CD) year(2012:2017) long clear
// These are, respectively: population, PPP GDP in 2011 international dollars, land area in sq km, pov headcount at $1.90 2011 PPP, average pov gap at $1.90 2011 PPP, current health spending per capita PPP I$, life expectancy at birth, Govt exp on education as percent of GDP, Literacy rate 15 and above, percent of pop using safely managed drinking water, percent... using safely managed sanitation, percent of pop with access to electricity, GDP per capita growth, ILO adj unemployment rate, Gini index, percent of urban pop in slums, urban population, emissions per 2011 PPP GDP, renewable energy as percent of total electricity output, percent terrestrial prot areas, percent marine prot areas, internally displaced persons by violence, public sector and institutions index, domestic resource mobilization and efficiency of revenue mobilization score, statistical capacity score. Total labor force, ILO thousands. Decision making participation by women on three key decisions, female population of decision making age, proportion of day spent on unpaid dom work for women, for men. Investment in transport with private participation, investment in energy with private participation (current USD).

// Fix excessively long name
ren en_atm_co2e_pp_gd_kd co2pgdp

// Creating some composite indicators
gen extPoorCt = (si_pov_dday/100)*sp_pop_totl
gen costSolvePov = (si_pov_gaps/100)*1.90*sp_pop_totl
gen illiterate = (1-(se_adt_litr_zs/100))*sp_pop_totl
gen noSafeWater = (1-(sh_h2o_smdw_zs/100))*sp_pop_totl
gen noSafeSan = (1-(sh_sta_smss_zs/100))*sp_pop_totl
gen noElec = (1-(eg_elc_accs_zs/100))*sp_pop_totl
gen uSlumPop = (en_pop_slum_ur_zs/100)*sp_urb_totl
gen unproLand = (1-(er_lnd_ptld_zs/100))*ag_lnd_totl_k2
gen unemployedCt = (sl_uem_totl_zs/100)*sl_tlf_totl_in
gen womNoDecCt = (1-(sg_dmk_alld_fn_zs/100))*sp_pop_1564_fe_in
gen unpaidDomGap = (sg_tim_uwrk_fe - sg_tim_uwrk_ma)/100
gen popUnpaidDomGap = unpaidDomGap*sp_pop_totl
gen NRenShare = (1-eg_elc_rnew_zs)/100

// Invert the indices for SDG 16 and 17
// Public sector scale of 1 to 5, revenue of 1 to 5, stat cap 1 to 100.
gen NPSI = 1 - (iq_cpa_pubs_xq/5)
gen NRM = 1 - (iq_cpa_revn_xq/5)
gen NSCS = 1 - (iq_sci_ovrl/100)

// For comparisons with high income mean variables:
// Health Spending shortfall from high income mean
by year, sort: egen HICHealthPCMeanYear = mean(cond(incomelevel == "HIC", sh_xpd_chex_pp_cd, .))
gen HfinGap = (HICHealthPCMeanYear - sh_xpd_chex_pp_cd)*sp_pop_totl
replace HfinGap = 0 if HfinGap < 0

// Ed Spending shortfall from high income mean
gen govEdSpendPC = ((se_xpd_totl_gd_zs/100)*ny_gdp_mktp_pp_kd)/sp_pop_totl
by year, sort: egen HICEdPCMeanYear = mean(cond(incomelevel == "HIC", govEdSpendPC, .))
gen EfinGap = (HICEdPCMeanYear - govEdSpendPC)*sp_pop_totl
replace EfinGap = 0 if EfinGap < 0

// Create an protected land to rich country levels variable
by year, sort: egen HICPLandMeanYear = mean(cond(incomelevel == "HIC", er_lnd_ptld_zs, .))
gen PLandPGap = (HICPLandMeanYear - er_lnd_ptld_zs)/100
replace PLandPGap = 0 if PLandPGap < 0
gen PLandGap = PLandPGap*ag_lnd_totl_k2

// Create a protected water to rich country levels variable
by year, sort: egen HICPMrnMeanYear = mean(cond(incomelevel == "HIC", er_mrn_ptmr_zs, .))
gen PMrnPGap = (HICPMrnMeanYear - er_mrn_ptmr_zs)/100
replace PMrnPGap = 0 if PMrnPGap < 0

// Transport spending to rich country levels shortfall
gen tranSpendPC = ie_ppi_tran_cd/sp_pop_totl
by year, sort: egen HICTranPCMeanYear = mean(cond(incomelevel == "HIC", tranSpendPC, .))
gen TfinGap = (HICTranPCMeanYear - tranSpendPC)*sp_pop_totl
replace TfinGap = 0 if TfinGap < 0

// Energy spending to rich country levels shortfall
gen enSpendPC = ie_ppi_engy_cd/sp_pop_totl
by year, sort: egen HICEnPCMeanYear = mean(cond(incomelevel == "HIC", enSpendPC, .))
gen EnfinGap = (HICEnPCMeanYear - enSpendPC)*sp_pop_totl
replace EnfinGap = 0 if EnfinGap < 0

// Create a macro for the indicators for convenience
local WBOrigInd "sp_pop_totl ny_gdp_mktp_pp_kd ag_lnd_totl_k2 si_pov_dday si_pov_gaps sh_xpd_chex_pp_cd sp_dyn_le00_in se_xpd_totl_gd_zs se_adt_litr_zs sh_h2o_smdw_zs sh_sta_smss_zs eg_elc_accs_zs ny_gdp_pcap_kd_zg sl_uem_totl_zs si_pov_gini en_pop_slum_ur_zs sp_urb_totl co2pgdp eg_elc_rnew_zs er_lnd_ptld_zs er_mrn_ptmr_zs vc_idp_tocv iq_cpa_pubs_xq iq_cpa_revn_xq iq_sci_ovrl sl_tlf_totl_in sg_dmk_alld_fn_zs sp_pop_1564_fe_in sg_tim_uwrk_fe sg_tim_uwrk_ma ie_ppi_tran_cd ie_ppi_engy_cd"
// (Note here that periods are converted to underscores vis-a-vis the actual WB indicator codes)
local WBCreatedInd "extPoorCt costSolvePov illiterate noSafeWater noSafeSan noElec uSlumPop unproLand unemployedCt HfinGap EfinGap PLandPGap PLandGap PMrnPGap TfinGap EnfinGap NRenShare NPSI NRM NSCS"
* Removed gender indicators 4/19
local WBindicators "`WBOrigInd' `WBCreatedInd'"

// Data cleaning
sum
browse if si_pov_dday > 75 & si_pov_dday != .
browse if se_xpd > 10 & se_xpd != .
browse if se_adt < 30 & se_adt != .
browse if sh_h2 < 10 & sh_h2 != .
hist sh_h2
browse if eg_elc_a < 10 & eg_elc_a != .
browse if ny_gdp_pca < -20 & ny_gdp_pca != .
browse if ny_gdp_pca > 10 & ny_gdp_pca != .
browse if sl_uem < 3 & sl_uem != .
browse if sl_uem > 25 & sl_uem != .
browse if en_pop_slu < 10 & en_pop_slu != .
browse if en_pop_slu > 90 & en_pop_slu != .
browse if co2pgdp > 1.25 & co2pgdp != .
browse if co2pgdp < 0.1 & co2pgdp != .
hist eg_elc_rn
browse if eg_elc_rn == 100
browse if eg_elc_rn == 0
browse if er_lnd < 1 & er_lnd != .
browse if er_lnd > 50 & er_lnd != .
browse if er_mrn == 0
browse if er_mrn == 100
browse if vc_idp > 1000000 & vc_idp != .
// Check for strange min/max values. Most figures appear reasonable when considering regional and continental and world values. DRC and Madagascar have very large poverty rates. Values expressed as percentages stay <= 100. Life expectancy is in a reasonable range. Micronesia spent 12% of GDP on education in 2015 while the highest reached for any other nation was 8%; this not totally unreasonable with a GDP of several hundred million dollars. Chad has extremely low literacy rates which match known facts. Sierra Leone, Uganda and others have extremely low access to safely managed water (under 10 percent)- this seems somewhat suspicious, but on the other hand this is a stricter definition than just basic access. Figures are similar and slightly more realistic for sanitation. Burundi and others do indeed face very low electrification. Macao and oil and war torn nations have large GDP fluctuations down; Libya saw a 120%+ growth in GDP in 2012 (this fact was verified with other sources), and other nations appear to have been in war recovery or oil booms. Unemployment rates generally seem reasonable given self-employ in many nations, oil production, and schemes such as NREGS in India. High unemp arises in several EU states, south africa, and the west bank, all verified independently. Ginis appear to be in correct ranges and attached to low values for EU nations, high ones for SSA. The slum population variable is missing for most nations and times, but it is highest in several African nations and low in Costa Rica, Tunisia, etc. likely the richest nations for which data were collected. Slum figures in excess of 90 percent also seem to be verified. Curacao has large oil refineries and massive co2 emissions; low emit countries appear to be Switzerland or in Africa. The Swiss figure is far below other EU countries, but not unreasonable given similar environmental policies and a massive service/banking sector low on emissions. A number of countries have no renewable electricity and all renewables- albania, laos, lesotho, and nepal are completely renewable at one point (all hydropower small nations), and numerous island and oil producing nations are fully non-renewable. Some mena and small island nations have almost no protected lands and Monaco, New Caledonia, and some others have over half. For marine areas it appears that landlocked nations have no observations and that others such as haiti have no protected areas, while slovenia is the only nation with 100% protection, possessing a small coastline with very limited fishing. Finally, high IDP nations involve Afghanistan, Congo, Colombia, Iraw, Nigeria, Pakistan, Sudan, Somalia, Syria, Turkey, Ukraine, and Yemen, all in civil wars or conflicts.

// For the created indices, count of extreme poor ranges from 0 to 900 million which is reasonable for worldwide value. Cost to solve poverty is zero to about 500m per day, which seems reasonable. Illiteracy ranges from just 87 individuals to 1B plus, again in range. No safe water goes up to 2B, no safe san up to 4V, no electric up to 1B, all good. slum population goes to similar values with a lower value of 17000. unprotected land goes up to about 100m sq kms, which is logical. Unemployed count goes to 170m, reasonable. High income health pc is about 3k, ed 5k. Financing gaps goe up to 10 trillion, not unreasonable as a global figure. Protected land gaps go up to 20 percent, and 8 million sq km. Water gaps go up to 16 percent.

// For gender, decision making shares go from 6 to 90 percent. Female pop of the decision making age goes up to 2.4 bill. Women spend 8 to 30 percent of time in dom work, men 2 to 10. Number of women without decision ability reaches as high as 150m. The unpaid domestic gender gap goes form zero to 20 percent of time.

// Transport investment goes to 60 bilion, energy to 80 billion. Per capita this goes to 500 USD, energy to 900. The high income average per capita is from basically zero to 100 dollars, which is a bit strange. Financing gap ranges from zero to 500B, and even 1.5Tr for energy. These seem like perhaps excessive values, but not impossible ones given regional and global aggregates.

// Further investigation.
hist TfinGap
hist EnfinGap
// The gaps are all quite large, if existent.
sum TfinGap, detail
browse if TfinGap > 1.71e+09 & TfinGap != .
sum EnfinGap, detail
browse if EnfinGap > 1.24e+09 & EnfinGap != .

// Check for duplicates
duplicates report
// no duplicates

// missing values analysis- poverty hcrs, gaps, literacy rates, ginis have large gaps. Much data on slums is missing- this is probably the variable with the least data. There are some gaps in IDPs and marine and land protected areas. For most variables filling missing values with last observations would seem to be appropriate if needed. For others, such as slums, one may assume values of zero for high income nations. Thankfully most created indices have sufficient data, thanks to high coverage of GDP and pop, although some financing gap measures can become very scarce.

// Remove unneeded data
drop countrycode region* adminregion* incomelevelname lending*
keep country year incomelevel `WBindicators'

// Prepare for merging
rename country RecipientName

// Put in widest format
reshape wide `WBindicators', i(RecipientName) j(year)

// Align Recipient Names
replace RecipientName = "China (People's Republic of)" if RecipientName == "China"
replace RecipientName = "Congo" if RecipientName == "Congo, Rep."
replace RecipientName = "Democratic Republic of the Congo" if RecipientName == "Congo, Dem. Rep."
replace RecipientName = "Côte d'Ivoire" if RecipientName == "Cote d'Ivoire"
replace RecipientName = "Democratic People's Republic of Korea" if RecipientName == "Korea, Dem. People’s Rep."
replace RecipientName = "Egypt" if RecipientName == "Egypt, Arab Rep."
replace RecipientName = "Gambia" if RecipientName == "Gambia, The"
replace RecipientName = "Iran" if RecipientName == "Iran, Islamic Rep."
replace RecipientName = "Kyrgyzstan" if RecipientName == "Kyrgyz Republic"
replace RecipientName = "Lao People's Democratic Republic" if RecipientName == "Lao PDR"
replace RecipientName = "Micronesia" if RecipientName == "Micronesia, Fed. Sts."
replace RecipientName = "Saint Kitts and Nevis" if RecipientName == "St. Kitts and Nevis"
replace RecipientName = "Saint Lucia" if RecipientName == "St. Lucia"
replace RecipientName = "Saint Vincent and the Grenadines" if RecipientName == "St. Vincent and the Grenadines"
replace RecipientName = "Venezuela" if RecipientName == "Venezuela, RB"
replace RecipientName = "Viet Nam" if RecipientName == "Vietnam"
replace RecipientName = "West Bank and Gaza Strip" if RecipientName == "West Bank and Gaza"
replace RecipientName = "Yemen" if RecipientName == "Yemen, Rep."

// (Optional) Align Region Names

// Save World Bank Indicators
save "${Intermediate_Data}/Clean_WB", replace

*****************************************************************************

clear

// Pull any remaining desired UNStat data- respectively in order of codes these are
// Econ loss due to natural disasters (current USD), and as share of GDP
// Count of undernourished people (in lieu of preferable calorie data)
import excel "${Input}/UNSTAT Hunger and Disaster Econ Loss.xlsx", sheet("data") firstrow

keep if SeriesCode == "VC_DSR_GDPLS" | SeriesCode == "VC_DSR_LSGP" | SeriesCode == "SN_ITK_DEFCN"
keep SeriesCode TimePeriod GeoAreaName Value

// Macro for convenience
local UNStatInd "VC_DSR_GDPLS VC_DSR_LSGP SN_ITK_DEFCN"

// Data Cleaning UNSTAT
duplicates drop

// Handle "NA" and "<" for undernourished
replace Value = subinstr(Value, "NA", "", .)
replace Value = subinstr(Value, "<", "", .)
// Here I treat the number of undernourished for < as equal to that number- maximizing possible number of undernourished.

// UNStat Data in wider format
reshape wide Value, i(GeoAreaName TimePeriod) j(SeriesCode) string

// Convert to numerics
destring ValueVC_DSR_GDPLS, gen(VC_DSR_GDPLS)
destring ValueVC_DSR_LSGP, gen(VC_DSR_LSGP)
destring ValueSN_ITK_DEFCN, gen(SN_ITK_DEFCN)
drop Value*

sum
hist VC_DSR_GDPLS
browse if VC_DSR_GDPLS > 1000000000 & VC_DSR_GDPLS != .
// Sense check
// Numbers for undernourished in millions do seem reasonable. Econ loss due to disasters in USD has a number of extremely low and extremely high numbers. A wide range of nations report sizable losses. Unfortunately, a number of estimates for the USA appear to be missing. Largest values appear to be in Colombia over several years. For percentage of GDP, no value is greater than about 1.5%, which seems somewhat unreasonable.
// Missing values- there are a lot of missing values for the disaster variables. This is not particularly serious, as it is likely disasters are rare.

// Prepare for merging
rename GeoAreaName RecipientName

// Align recipient names
replace RecipientName = "Bolivia" if RecipientName == "Bolivia (Plurinational State of)"
replace RecipientName = "China (People's Republic of)" if RecipientName == "China"
replace RecipientName = "Iran" if RecipientName == "Iran (Islamic Republic of)"
replace RecipientName = "Tanzania" if RecipientName == "United Republic of Tanzania"
replace RecipientName = "Venezuela" if RecipientName == "Venezuela (Bolivarian Republic of)"
replace RecipientName = "Wallis and Futuna" if RecipientName == "Wallis and Futuna Islands"

// Reshape into widest format
reshape wide `UNStatInd', i(RecipientName) j(TimePeriod)

// Save
save "${Intermediate_Data}/Clean_UNSTAT", replace

*****************************************************************************

* For health: consider Maternal and child mortality- need the info on number of live births, or could calculate around this by births per woman, and then number of women

// Polity democracy data- add if desired, use stata thesis copy
import excel "${Input}/p4v2018.xls", firstrow clear

keep country year polity2
drop if year < 2012 | year > 2017

// Clean check
sum
// Nothing missing. Polity2 scores appear to be in correct ranges (-10 to 10).

// Prepare for merging
rename country RecipientName

// Align recipient names
replace RecipientName = "Bosnia and Herzegovina" if RecipientName == "Bosnia"
replace RecipientName = "Cabo Verde" if RecipientName == "Cape Verde"
replace RecipientName = "China (People's Republic of)" if RecipientName == "China"
replace RecipientName = "Congo" if RecipientName == "Congo Brazzaville"
replace RecipientName = "Côte d'Ivoire" if RecipientName == "Cote D'Ivoire"
replace RecipientName = "Democratic People's Republic of Korea'" if RecipientName == "Korea North"
replace RecipientName = "Democratic Republic of the Congo" if RecipientName == "Congo Kinshasa"
replace RecipientName = "Eswatini" if RecipientName == "Swaziland"
replace RecipientName = "North Macedonia" if RecipientName == "Macedonia"
replace RecipientName = "Lao People's Democratic Republic" if RecipientName == "Laos"
replace RecipientName = "Myanmar" if RecipientName == "Myanmar (Burma)"
replace RecipientName = "Sudan" if RecipientName == "Sudan-North"
replace RecipientName = "Syrian Arab Republic" if RecipientName == "Syria"
replace RecipientName = "Timor-Leste" if RecipientName == "Timor Leste"
replace RecipientName = "Viet Nam" if RecipientName == "Vietnam"

// Reshape to wider format
reshape wide polity2, i(RecipientName) j(year)

save "${Intermediate_Data}/Clean_Polity4", replace

*****************************************************************************

// Find a gender inequality index somewhere on the web and download it here. Focus on legal measures.
* UN HDI Gender
import excel "${Input}/HDI Gender.xlsx", sheet("HDI Gender") firstrow clear

ren Country RecipientName
ren B GI2012
ren C GI2013
ren D GI2014
ren E GI2015
ren F GI2016
ren G GI2017

// Create year macro for convenience
local years "2012 2013 2014 2015 2016 2017"

foreach year in `years' {
    replace GI`year' = "." if GI`year' == ".."
    destring GI`year', replace
}

* Data cleaning
summarize
* Very few missing observations. The index ranges from near 0.04 to 0.85ish. This could be normalized if desired.
duplicates drop
* No issues here

* Align country names- try the same UN code
replace RecipientName = "Bolivia" if RecipientName == "Bolivia (Plurinational State of)"
replace RecipientName = "China (People's Republic of)" if RecipientName == "China"
replace RecipientName = "Democratic Republic of the Congo" if RecipientName == "Congo (Democratic Republic of the)"
replace RecipientName = "Eswatini" if RecipientName == "Eswatini (Kingdom of)"
replace RecipientName = "Iran" if RecipientName == "Iran (Islamic Republic of)"
replace RecipientName = "Moldova" if RecipientName == "Moldova (Republic of)"
replace RecipientName = "Tanzania" if RecipientName == "Tanzania (United Republic of)"
replace RecipientName = "Venezuela" if RecipientName == "Venezuela (Bolivarian Republic of)"

save "${Intermediate_Data}/Clean_HDI_Gender", replace

*****************************************************************************

* World Bank: Women, Business, and the Law
import excel "${Input}/WB WBL.xlsx", sheet("WBL1971-2020") firstrow clear

ren A RecipientName
ren B year
ren C WBLIndex
drop in 1

destring year, replace
destring WBLIndex, replace

drop if (year < 2012 | year > 2017) & year != .

* Data cleaning
sum
* Very little missing data. Index goes from 26.3 to 100.
duplicates drop
* No duplicates

*Invert the index to represent need
replace WBLIndex = 100 - WBLIndex

* Align country names.
* Try the same routine as WB data
replace RecipientName = "China (People's Republic of)" if RecipientName == "China"
replace RecipientName = "Congo" if RecipientName == "Congo, Rep."
replace RecipientName = "Democratic Republic of the Congo" if RecipientName == "Congo, Dem. Rep."
replace RecipientName = "Côte d'Ivoire" if RecipientName == "Cote d'Ivoire"
replace RecipientName = "Democratic People's Republic of Korea" if RecipientName == "Korea, Dem. People’s Rep."
replace RecipientName = "Egypt" if RecipientName == "Egypt, Arab Rep."
replace RecipientName = "Gambia" if RecipientName == "Gambia, The"
replace RecipientName = "Iran" if RecipientName == "Iran, Islamic Rep."
replace RecipientName = "Kyrgyzstan" if RecipientName == "Kyrgyz Republic"
replace RecipientName = "Lao People's Democratic Republic" if RecipientName == "Lao PDR"
replace RecipientName = "Micronesia" if RecipientName == "Micronesia, Fed. Sts."
replace RecipientName = "Saint Kitts and Nevis" if RecipientName == "St. Kitts and Nevis"
replace RecipientName = "Saint Lucia" if RecipientName == "St. Lucia"
replace RecipientName = "Saint Vincent and the Grenadines" if RecipientName == "St. Vincent and the Grenadines"
replace RecipientName = "Venezuela" if RecipientName == "Venezuela, RB"
replace RecipientName = "Viet Nam" if RecipientName == "Vietnam"
replace RecipientName = "West Bank and Gaza Strip" if RecipientName == "West Bank and Gaza"
replace RecipientName = "Yemen" if RecipientName == "Yemen, Rep."
replace RecipientName = "Sao Tome and Principe" if RecipientName == "São Tomé and Príncipe"

*Prep for merging
reshape wide WBLIndex, i(RecipientName) j(year)

save "${Intermediate_Data}/Clean_WBL", replace

*****************************************************************************

* Merge all datasets, toss out situations with data which is not in the aid dataset (this also tosses out situations where there is no aid data/countries are developed). merge code 2 means using (or importing data) only.

use "${Intermediate_Data}/Clean_Disbursements", clear

merge 1:1 RecipientName using "${Intermediate_Data}/Clean_WB", gen(merge1)
drop if merge1 == 2
merge 1:1 RecipientName using "${Intermediate_Data}/Clean_UNSTAT", gen(merge2)
drop if merge2 == 2
merge 1:1 RecipientName using "${Intermediate_Data}/Clean_Polity4", gen(merge3)
drop if merge3 == 2
merge 1:1 RecipientName using "${Intermediate_Data}/Clean_HDI_Gender", gen(merge4)
drop if merge4 == 2
merge 1:1 RecipientName using "${Intermediate_Data}/Clean_WBL", gen(merge5)
drop if merge5 == 2
drop merge*
*also add in some other merge vars for any other need datasets merge ops

* If you want to run only from 396ish quickly activate the following:
* local years "2012 2013 2014 2015 2016 2017"

* Split off here for regional analysis.

* Consider population weighting gender inequality indices. I don't know if i'll use these in future- will just leave out of analysis for now. I didn't weight the Ginis.
*foreach year in `years' {
    *gen pGI`year' = GI`year'*sp_pop_totl`year'
    *gen pWBLIndex`year' = WBLIndex`year'*sp_pop_totl`year'
*}

* Toss out regions to focus on country data only
drop if strpos(RecipientName, "regional") != 0
drop if strpos(RecipientName, "unspecified") != 0
drop if strpos(RecipientName, "Yugoslavia") != 0
tab RecipientName

save "${Intermediate_Data}/fmergedready", replace

*****************************************************************************

* Collect summary statistics
estpost sum
esttab . using "${Tables}/sumstatsWide.tex", cells("mean sd count") noobs replace label

// Identify aggregable indicators, create macro
local aggInd "extPoorCt costSolvePov SN_ITK_DEFCN HfinGap EfinGap illiterate GI WBLIndex noSafeWater noSafeSan noElec unemployedCt TfinGap EnfinGap si_pov_gini uSlumPop VC_DSR_GDPLS co2pgdp NRenShare PMrnPGap PLandPGap PLandGap vc_idp_tocv NPSI NRM NSCS"

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
        *esttab matrix(A, fmt(%5.2f)) using sp`indicator'`year'.tex, replace
        *eststo clear
    }

    *Regression analysis. Sample size unfortanately probably kind of small here.
    *foreach indicator in `aggInd' {
        *capture: reg ais`indicator'`year' ns`indicator'`year', robust
        *capture: eststo ncols`indicator'`year'
        *Throw in controls, and print their output. Just democracy (polity2) for now.
        *capture: reg ais`indicator'`year' ns`indicator'`year' polity2`year', robust
        *capture: eststo p2ols`indicator'`year'
        *capture: esttab ncols`indicator'`year' p2ols`indicator'`year' using "ols`indicator'`year'.tex"
        *eststo clear
    *}

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
save "${Intermediate_Data}/merged_IDOS_wide", replace

*****************************************************************************

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
    graph save "${Intermediate_Figures}/`indicator'", replace
}

* Create a table of graphs- three batches
graph combine "${Intermediate_Figures}/ammextPoorCt" "${Intermediate_Figures}/ammcostSolvePov" "${Intermediate_Figures}/ammSN_ITK_DEFCN" "${Intermediate_Figures}/ammHfinGap" "${Intermediate_Figures}/ammEfinGap" "${Intermediate_Figures}/ammilliterate" "${Intermediate_Figures}/ammGI" "${Intermediate_Figures}/ammWBLIndex" "${Intermediate_Figures}/ammnoSafeWater", iscale(0.4)
graph export "${Figures}/firstNine", as(png) name("Graph") replace

graph combine  "${Intermediate_Figures}/ammnoSafeSan" "${Intermediate_Figures}/ammnoElec" "${Intermediate_Figures}/ammunemployedCt" "${Intermediate_Figures}/ammTfinGap" "${Intermediate_Figures}/ammEnfinGap" "${Intermediate_Figures}/ammsi_pov_gini" "${Intermediate_Figures}/ammuSlumPop" "${Intermediate_Figures}/ammVC_DSR_GDPLS" "${Intermediate_Figures}/ammco2pgdp", iscale(0.4)
graph export "${Figures}/secondNine", as(png) name("Graph") replace

graph combine "${Intermediate_Figures}/ammNRenShare" "${Intermediate_Figures}/ammPMrnPGap" "${Intermediate_Figures}/ammPLandPGap" "${Intermediate_Figures}/ammPLandGap" "${Intermediate_Figures}/ammvc_idp_tocv" "${Intermediate_Figures}/ammNPSI" "${Intermediate_Figures}/ammNRM" "${Intermediate_Figures}/ammNSCS", iscale(0.4)
graph export "${Figures}/thirdEight", as(png) name("Graph") replace

*****************************************************************************

* New code with min and max graphs
tsset year
foreach indicator in `aggInd'{
    twoway (connect amm`indicator' year,  cmissing(n)) (connect minamm`indicator' year,  cmissing(n)) (connect maxamm`indicator' year,  cmissing(n)), ytitle(Absolute Mismatch)  ttitle(Year) title(Max-Mean-Min: `: var label amm`indicator'') legend(off)
    graph save "${Intermediate_Figures}/maxtominamm`indicator'", replace
}

* Create a table of graphs
graph combine "${Intermediate_Figures}/maxtominammextPoorCt" "${Intermediate_Figures}/maxtominammcostSolvePov" "${Intermediate_Figures}/maxtominammSN_ITK_DEFCN" "${Intermediate_Figures}/maxtominammHfinGap" "${Intermediate_Figures}/maxtominammEfinGap" "${Intermediate_Figures}/maxtominammilliterate" "${Intermediate_Figures}/maxtominammGI" "${Intermediate_Figures}/maxtominammWBLIndex" "${Intermediate_Figures}/maxtominammnoSafeWater", iscale(0.35)
graph export "${Figures}/mtmfirstNine", as(png) name("Graph") replace

graph combine  "${Intermediate_Figures}/maxtominammnoSafeSan" "${Intermediate_Figures}/maxtominammnoElec" "${Intermediate_Figures}/maxtominammunemployedCt" "${Intermediate_Figures}/maxtominammTfinGap" "${Intermediate_Figures}/maxtominammEnfinGap" "${Intermediate_Figures}/maxtominammsi_pov_gini" "${Intermediate_Figures}/maxtominammuSlumPop" "${Intermediate_Figures}/maxtominammVC_DSR_GDPLS" "${Intermediate_Figures}/maxtominammco2pgdp", iscale(0.35)
graph export "${Figures}/mtmsecondNine", as(png) name("Graph") replace

graph combine "${Intermediate_Figures}/maxtominammNRenShare" "${Intermediate_Figures}/maxtominammPMrnPGap" "${Intermediate_Figures}/maxtominammPLandPGap" "${Intermediate_Figures}/maxtominammPLandGap" "${Intermediate_Figures}/maxtominammvc_idp_tocv" "${Intermediate_Figures}/maxtominammNPSI" "${Intermediate_Figures}/maxtominammNRM" "${Intermediate_Figures}/maxtominammNSCS", iscale(0.35)
graph export "${Figures}/mtmthirdEight", as(png) name("Graph") replace

*****************************************************************************

* Produce a global amm graph across all indicators
egen totAmm = rowmean(amm*)
twoway (connect totAmm year), ytitle(Absolute Mismatch) yscale(range(0 0.05)) ylabel(#7) title(Worldwide Absolute Mismatch (Indicators Eq Weight))
graph export "${Figures}/wwAggAMM.png", as(png) name("Graph") replace
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
graph export "${Figures}/ewwAggAMM.png", as(png) name("Graph") replace

*****************************************************************************

*Throwing mins and maxes into the WW graphs
*First, eq weight to all indicators
egen mintotAmm = rowmin(minamm*)
egen maxtotAmm = rowmax(maxamm*)

twoway (connect totAmm year) (connect mintotAmm year) (connect maxtotAmm year), ytitle(Absolute Mismatch) title(Max-Mean-Min Absolute Mismatch (Indicators Eq Weight)) legend(off)
graph export "${Figures}/MtMwwAggAMM.png", as(png) name("Graph") replace

*Weighting by goal
twoway (connect etotAmm year) (connect mintotAmm year) (connect maxtotAmm year), ytitle(Absolute Mismatch) title(Max-Mean-Min Absolute Mismatch (Goals Eq Weight)) legend(off)
graph export "${Figures}/eMtMwwAggAMM.png", as(png) name("Graph") replace

* Back to normal
restore

*****************************************************************************

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
    graph save "${Intermediate_Figures}/`indicator'", replace
}

* Create a table of graphs
graph combine "${Intermediate_Figures}/spextPoorCt" "${Intermediate_Figures}/spcostSolvePov" "${Intermediate_Figures}/spSN_ITK_DEFCN" "${Intermediate_Figures}/spHfinGap" "${Intermediate_Figures}/spEfinGap" "${Intermediate_Figures}/spilliterate" "${Intermediate_Figures}/spGI" "${Intermediate_Figures}/spWBLIndex" "${Intermediate_Figures}/spnoSafeWater", iscale(0.4)
graph export "${Figures}/spfirstNine", as(png) name("Graph") replace

graph combine  "${Intermediate_Figures}/spnoSafeSan" "${Intermediate_Figures}/spnoElec" "${Intermediate_Figures}/spunemployedCt" "${Intermediate_Figures}/spTfinGap" "${Intermediate_Figures}/spEnfinGap" "${Intermediate_Figures}/spsi_pov_gini" "${Intermediate_Figures}/spuSlumPop" "${Intermediate_Figures}/spVC_DSR_GDPLS" "${Intermediate_Figures}/spco2pgdp", iscale(0.4)
graph export "${Figures}/spsecondNine", as(png) name("Graph") replace

graph combine "${Intermediate_Figures}/spNRenShare" "${Intermediate_Figures}/spPMrnPGap" "${Intermediate_Figures}/spPLandPGap" "${Intermediate_Figures}/spPLandGap" "${Intermediate_Figures}/spvc_idp_tocv" "${Intermediate_Figures}/spNPSI" "${Intermediate_Figures}/spNRM" "${Intermediate_Figures}/spNSCS", iscale(0.4)
graph export "${Figures}/spthirdEight", as(png) name("Graph") replace

* Produce a global amm graph across all indicators
egen totsp = rowmean(sp*)
twoway (connect totsp year), ytitle(Spearman Coefficient) yscale(range(0 0.05)) ylabel(#7) title(Mean Spearman Coeff (Indicators Eq Weight))
graph export "${Figures}/spwwAggAMM.png", as(png) name("Graph") replace
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
graph export "${Figures}/ewwAggsp.png", as(png) name("Graph") replace

*Back to normal
restore

*****************************************************************************

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
esttab . using "${Tables}/sumstatsLong.tex", label cells("mean sd count") noobs replace
restore

save "${Intermediate_Data}/merged_IDOS_long", replace

*****************************************************************************

* Disproportionate country analysis

* Make more space
drop mm* amm* sp*
foreach indicator in `aggInd'{
    preserve
    keep if abs(Def`indicator') > 0.1 & Def`indicator' != .
    capture: export excel RecipientName year Def`indicator' `indicator' aid`indicator' ais`indicator' ns`indicator' using "${Tables}/disC`indicator'.xlsx", firstrow(var) replace
    restore
}

*Spearman analysis across time by indicator
foreach indicator in `aggInd'{
    capture: spearman ais`indicator' ns`indicator'
    matrix A = r(rho)
    esttab matrix(A, fmt(%5.2f)) using "${Tables}/sp`indicator'.tex", replace
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
*Get back to correct directions
gen PSI = 1 - NPSI
gen RM = 1 - NRM
label var PSI "WGI Public Sector/Institutions score (higher = stronger)"
label var RM "WGI Revenue Mobilization Score (higher = stronger)"

*Execute regressions
foreach indicator in `aggInd' {
    capture: reg ais`indicator' ns`indicator', robust
    capture: eststo ncols`indicator'
    *Throw in controls, and print their output. Democracy/polity 2, fixed effects, and eventually institutions and domestic resource mobilization.
    capture: reg ais`indicator' ns`indicator' polity2, robust
    capture: eststo p2ols`indicator'
    capture: reg ais`indicator' ns`indicator' polity2 PSI, robust
    capture: eststo winstp`indicator'
    capture: reg ais`indicator' ns`indicator' polity2 PSI RM, robust
    capture: eststo winstdrm`indicator'
    capture: esttab ncols`indicator' p2ols`indicator' winstp`indicator' winstdrm`indicator' using "${Regressions}/regs`indicator'.tex", label replace compress r2
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
capture: reg avgais avgns polity2 PSI, robust
capture: eststo avgwinstp
capture: reg avgais avgns polity2 PSI RM, robust
capture: eststo avgwinstdrm
capture: esttab avgncols avgp2ols avgwinstp avgwinstdrm using "${Regressions}/avgregs.tex", label replace compress

*Analysis for countries by year across all indicators. Optional, perhaps return to later, not too interesting beyond what was already done in disprop c analysis likely.
*preserve
*Clear out variables
*drop *2012 *2013 *2014 *2015 *2016 *2017
*Bring back adefs
*foreach indicator in `aggInd' {
    *gen adef`indicator' = abs(Def`indicator'`year')
*}
*Create a mean adef indicator for a country
*egen cma = rowmean(adef*)
*Plot these means adefs over time, perhaps for highly disprop nations.
*restore
*Single/overall spearman and regression for need and aid for all indicators.
*In both of these cases, do means.

save "${Intermediate_Data}/merged_IDOs_end", replace

* Regional analysis: reload if desired.