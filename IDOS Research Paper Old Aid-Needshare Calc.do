// IDOS Research Paper
// Sustainable Development Aid and Need
// Isaac Liu

clear
macro drop _all
// Set Working Directory
cd "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations"

// Setting up Aid Data

// Download SDG Financing Data from: https://sdg-financing-lab.oecd.org/explore?country=All%20providers&distribution=providers&finance=Disbursement&from=2012&oda=true&oof=false&other%20private%20flows=false&private%20grants=false&target=All%20Recipients&to=2017

// Convert to XLSX File Format, load into Stata
import excel "AP ODA 12-17 Dis", firstrow

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
save Clean_Disbursements, replace

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
local WBCreatedInd "extPoorCt costSolvePov illiterate noSafeWater noSafeSan noElec uSlumPop unproLand unemployedCt womNoDecCt unpaidDomGap popUnpaidDomGap HfinGap EfinGap PLandPGap PLandGap PMrnPGap TfinGap EnfinGap NRenShare NPSI NRM NSCS"
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
save Clean_WB, replace
clear

// Pull any remaining desired UNStat data- respectively in order of codes these are
// Econ loss due to natural disasters (current USD), and as share of GDP
// Count of undernourished people (in lieu of preferable calorie data)
import excel "UNSTAT Hunger and Disaster Econ Loss", sheet("data") firstrow
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
save Clean_UNSTAT, replace

// Maternal and child mortality- need the info on number of live births, or could calculate around this by births per woman, and then number of women

// Find a gender index/legal measure for SDG 5

// Polity democracy data- add if desired, use stata thesis copy
import excel "p4v2018", firstrow clear
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

save Clean_Polity4, replace

// Find a gender inequality index somewhere on the web and download it here. Focus on legal measures.

* Merge all datasets, toss out situations with data which is not in the aid dataset (this also tosses out situations where there is no aid data/countries are developed). merge code 2 means using (or importing data) only.
use Clean_Disbursements, clear
merge 1:1 RecipientName using Clean_WB, gen(merge1)
drop if merge1 == 2
merge 1:1 RecipientName using Clean_UNSTAT, gen(merge2)
drop if merge2 == 2
merge 1:1 RecipientName using Clean_Polity4, gen(merge3)
drop if merge3 == 2
*also add in some other merge vars for any other need datasets merge ops

// Split off here for regional analysis.

// Toss out regions to focus on country data only
drop if strpos(RecipientName, "regional") != 0
drop if strpos(RecipientName, "unspecified") != 0
drop if strpos(RecipientName, "Yugoslavia") != 0
tab RecipientName

* Collect summary statistics
estpost sum
esttab . using "sumstatsWide.rtf", cells("mean sd count") noobs replace

// Create year macro for convenience
local years "2012 2013 2014 2015 2016 2017"

// Create aid by goal macro
local goalAid "Value_USD1 Value_USD2 Value_USD3 Value_USD4 Value_USD5 Value_USD6 Value_USD7 Value_USD8 Value_USD9 Value_USD10 Value_USD11 Value_USD12 Value_USD13 Value_USD14 Value_USD15 Value_USD16 Value_USD17"

// Identify aggregable indicators
local aggInd "extPoorCt costSolvePov SN_ITK_DEFCN HfinGap EfinGap illiterate womNoDecCt unpaidDomGap popUnpaidDomGap noSafeWater noSafeSan noElec unemployedCt TfinGap EnfinGap si_pov_gini uSlumPop VC_DSR_GDPLS co2pgdp NRenShare PMrnPGap PLandPGap PLandGap vc_idp_tocv NPSI NRM NSCS"

// Stationary (within single-year) analysis
foreach year in `years' {

*Compute shares of need
foreach indicator in `aggInd' {
egen ti`indicator'`year' = total(`indicator'`year')
gen ns`indicator'`year' = `indicator'`year'/ti`indicator'`year'
*Save variable space
drop ti`indicator'`year'
}

*Compute shares of aid
foreach goal in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 {
egen tg`goal'`year' = total(Value_USD`goal'`year')
gen ais`goal'`year' = Value_USD`goal'`year'/tg`goal'`year'
*Save variable space
drop tg`goal'`year'
}

*Dealing with few indicator observation years- correct aidshare to be only among those (denom only including) which have need data? Similar correction for needshare.
*This may actually be a somewhat different interpretation, since perhaps aid should or can only be given to countries for which there is data available on indicators.
*See the updated file for a fix at this.

*Need and aid deviation (shares), computed for each need indicator
gen DefextPoorCt`year' = ais1`year' - nsextPoorCt`year'
gen DefcostSolvePov`year' = ais1`year' - nscostSolvePov`year'
gen DefSN_ITK_DEFCN`year' = ais2`year' - nsSN_ITK_DEFCN`year'
gen DefHfinGap`year' = ais3`year' - nsHfinGap`year'
gen DefEfinGap`year' = ais4`year' - nsEfinGap`year'
gen Defilliterate`year' = ais4`year' - nsilliterate`year'
gen DefwomNoDecCt`year' = ais5`year' - nswomNoDecCt`year'
gen DefunpaidDomGap`year' = ais5`year' - nsunpaidDomGap`year'
gen DefpopUnpaidDomGap`year' = ais5`year' - nspopUnpaidDomGap`year'
gen DefnoSafeWater`year' = ais6`year' - nsnoSafeWater`year'
gen DefnoSafeSan`year' = ais6`year' - nsnoSafeSan`year'
gen DefnoElec`year' = ais7`year' - nsnoElec`year'
gen DefunemployedCt`year' = ais8`year' - nsunemployedCt`year'
gen DefTfinGap`year' = ais9`year' - nsTfinGap`year'
gen DefEnfinGap`year' = ais9`year' - nsEnfinGap`year'
gen Defsi_pov_gini`year' = ais10`year' - nssi_pov_gini`year'
gen DefuSlumPop`year' = ais11`year' - nsuSlumPop`year'
gen DefVC_DSR_GDPLS`year' = ais11`year' - nsVC_DSR_GDPLS`year'
gen Defco2pgdp`year' = ais12`year' - nsco2pgdp`year'
gen DefNRenShare`year' = ais13`year' - nsNRenShare`year'
gen DefPMrnPGap`year' = ais14`year' - nsPMrnPGap`year'
gen DefPLandPGap`year' = ais15`year' - nsPLandPGap`year'
gen DefPLandGap`year' = ais15`year' - nsPLandGap`year'
gen Defvc_idp_tocv`year' = ais16`year' - nsvc_idp_tocv`year'
gen DefNPSI`year' = ais16`year' - nsNPSI`year'
gen DefNRM`year' = ais17`year' - nsNRM`year'
gen DefNSCS`year' = ais17`year' - nsNSCS`year'

*Create the mismatch index (and variants) for each indicator
foreach indicator in `aggInd' {
egen mm`indicator'`year' = mean(Def`indicator'`year')
gen adef`indicator'`year' = abs(Def`indicator'`year')
egen amm`indicator'`year' = mean(adef`indicator'`year')
gen sdef`indicator'`year' = (Def`indicator'`year')^2
egen smm`indicator'`year' = mean(sdef`indicator'`year')
}

*Spearman's rank coefficient analysis
*Take advantage of the fact shares are ordinally the same as actual values.
foreach indicator in `aggInd'{
*back out aid share by indicator (make use of the prior goal match)
gen ais`indicator'`year' = Def`indicator'`year' + ns`indicator'`year'
capture: spearman ais`indicator'`year' ns`indicator'`year'
matrix A = r(rho)
esttab matrix(A, fmt(%5.2f)) using sp`indicator'`year'.rtf, replace
eststo clear
}

*Regression analysis. Sample size unfortanately probably kind of small here.
foreach indicator in `aggInd' {
capture: reg ais`indicator'`year' ns`indicator'`year', robust
capture: eststo ncols`indicator'`year'
*Throw in controls, and print their output. Just democracy (polity2) for now.
capture: reg ais`indicator'`year' ns`indicator'`year' polity2`year', robust
capture: eststo p2ols`indicator'`year'
capture: esttab ncols`indicator'`year' p2ols`indicator'`year' using "ols`indicator'`year'.rtf"
eststo clear
}

}

*Save the wide format dataset
save merged_IDOS_wide, replace

* Cross-time Analysis
* Tracking Absolute Mismatch over time for all countries
preserve
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

* Produce a global amm graph across all indicators
egen totAmm = rowmean(amm*)
twoway (tsline totAmm), ytitle(Mean Absolute Mismatch) yscale(range(0 0.05)) ylabel(#7) title(Worldwide Mean Absolute Mismatch (All Indicator Means))
graph export "C:\Users\Isaac Liu\OneDrive - Georgetown University\Senior\Spring Class\International Development Organizations\wwAggAMM.png", as(png) name("Graph") replace
* Look at regular mismatch or squared mismatch if desired. Not very interpretable though.
restore

* More micro and cross-time analysis
* Get into long form
local DefInds "DefextPoorCt DefcostSolvePov DefSN_ITK_DEFCN DefHfinGap DefEfinGap Defilliterate DefwomNoDecCt DefunpaidDomGap DefpopUnpaidDomGap DefnoSafeWater DefnoSafeSan DefnoElec DefunemployedCt DefTfinGap DefEnfinGap Defsi_pov_gini DefuSlumPop DefVC_DSR_GDPLS Defco2pgdp DefNRenShare DefPMrnPGap DefPLandPGap DefPLandGap Defvc_idp_tocv DefNPSI DefNRM DefNSCS"
local aisInds "aisextPoorCt aiscostSolvePov aisSN_ITK_DEFCN aisHfinGap aisEfinGap aisilliterate aiswomNoDecCt aisunpaidDomGap aispopUnpaidDomGap aisnoSafeWater aisnoSafeSan aisnoElec aisunemployedCt aisTfinGap aisEnfinGap aissi_pov_gini aisuSlumPop aisVC_DSR_GDPLS aisco2pgdp aisNRenShare aisPMrnPGap aisPLandPGap aisPLandGap aisvc_idp_tocv aisNPSI aisNRM aisNSCS"
local nsInds "nsextPoorCt nscostSolvePov nsSN_ITK_DEFCN nsHfinGap nsEfinGap nsilliterate nswomNoDecCt nsunpaidDomGap nspopUnpaidDomGap nsnoSafeWater nsnoSafeSan nsnoElec nsunemployedCt nsTfinGap nsEnfinGap nssi_pov_gini nsuSlumPop nsVC_DSR_GDPLS nsco2pgdp nsNRenShare nsPMrnPGap nsPLandPGap nsPLandGap nsvc_idp_tocv nsNPSI nsNRM nsNSCS"
local valueUSDs "Value_USD1 Value_USD2 Value_USD3 Value_USD4 Value_USD5 Value_USD6 Value_USD7 Value_USD8 Value_USD9 Value_USD10 Value_USD11 Value_USD12 Value_USD13 Value_USD14 Value_USD15 Value_USD16 Value_USD17"
reshape long `aggInd' `goalAid' `DefInds' `aisInds' `nsInds' `ValueUSDs' polity2, i(RecipientName) j(year `years')

save merged_IDOS_long, replace

* Disproportionate country analysis
* Make more space
drop mm* amm* smm*
foreach indicator in `aggInd'{
preserve
keep if abs(Def`indicator') > 0.1 & Def`indicator' != .
export excel RecipientName year Def`indicator' `indicator' `valueUSDs' ais`indicator' ns`indicator' using "disC`indicator'.xlsx", firstrow(var) replace
restore
}

*Spearman analysis across time by indicator
foreach indicator in `aggInd'{
capture: spearman ais`indicator' ns`indicator'
matrix A = r(rho)
esttab matrix(A, fmt(%5.2f)) using sp`indicator'.rtf, replace
eststo clear
}

*Regression analysis across time by indicator
*Prep for a panel analysis
encode RecipientName, gen(rName)
xtset rName year
*Execute regressions
foreach indicator in `aggInd' {
capture: reg ais`indicator' ns`indicator', robust
capture: eststo ncols`indicator'
*Throw in controls, and print their output. Just democracy (polity2) for now.
capture: reg ais`indicator' ns`indicator' polity2, robust
capture: eststo p2ols`indicator'
capture: xtreg ais`indicator' ns`indicator' polity2, fe vce(cluster rName)
capture: eststo pfe`indicator'
capture: esttab ncols`indicator' p2ols`indicator' pfe`indicator' using "regs`indicator'.rtf"
eststo clear
}

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

save merged_IDOs_end, replace

// Regional analysis
* Reload the whole dataset I guess. Need the preserve/restore for other stuff