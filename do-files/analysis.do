* Analysis file - run regressions, store tables/figures in output

use "data\cleandata.dta", clear

*****************
* SUMMARY TABLES * 
*****************

* Table 1

forvalues i=1/7 {
	label var w`i'status "Wave `i'"
}
eststo: qui estpost sum w*status
esttab using "output/table1.tex", cells((count mean sd min max)) note("Note: Response status variables were recoded to be binary such that status = 0 for a given household indicates that the household's responses are incomplete (i.e. either answered by only child or only parent, or were excluded from analysis by the creator of the dataset) and status = 1 indicates that the household's responses are complete (answered by both child and parent). No response at all was coded as a missing value. Thus, a mean of 0.984 suggests that 98.4% of the sample in wave 1, conditional on having sent some kind of response, is complete data.") nomti l replace nonum

* Table 2

eststo clear
forvalues i=1/7 {
	replace w`i'status = . if w`i'status == 0
	qui eststo w`i': estpost tab grade`i' w`i'status, nototal
}
esttab using "output/table2.tex", cells(colpct(fmt(2))) unstack mtitles nodepvar nonumber replace note("Note: Column percentages")

* Table 3
eststo clear
label var selective_pre_ranked "Selective aspiration, grade 9"
label var selective_post_ranked "Selective aspiration, grade 10"
label var female "Female"
label var income_pre "Household income"
label var investment_pre "Monthly investment in child"
label var level_pre "Aspired level of education"
gen track_pre_bin = (track_pre >= 4)
replace track_pre_bin = . if track_pre == 3
label var track_pre_bin "STEM track"
label var score_japanese_pre "Japanese score"
label var score_english_pre "English score"
label var score_math_pre "Math score"
label var score_science_pre "Science score"
label var score_social_pre "Social studies score"
eststo: qui estpost sum selective_pre_ranked selective_post_ranked badupdate female fatheredu motheredu income_pre investment_pre level_pre  track_pre_bin score_japanese_pre score_english_pre score_math_pre score_science_pre score_social_pre
esttab using "output/table3.tex", cells((count mean(fmt(3)) sd(fmt(3)) min max)) l nonumber note("Note: All but bad update and otherwise specified are as recorded in grade 9, just prior to high school admission") title("Summary statistics") replace

dtable selective_pre_ranked female fatheredu motheredu income_pre investment_pre level_pre  track_pre_bin score_japanese_pre score_english_pre score_math_pre score_science_pre score_social_pre, by(badupdate, tests nototals) export("output/appendix.docx", replace) statistics() 

*****************
* MAIN FINDINGS * 
*****************
local background_ctrl i.income_pre i.fatheredu i.motheredu i.investment_pre
local academic_ctrl i.track_pre i.score_japanese_pre i.score_math_pre i.score_english_pre i.score_science_pre i.score_social_pre i.score_track_pre

* Table 4. Baseline 2-period OLS
eststo clear
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate i.female `background_ctrl' `academic_ctrl', r
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate##i.female `background_ctrl' `academic_ctrl', r
qui eststo: reg sel_post_bin i.sel_pre_bin##i.badupdate i.female `background_ctrl' `academic_ctrl', r
esttab using "output\table4.rtf", nobase se indicate("Background controls = `=subinstr("`background_ctrl'", "i.", "*.", .)'" "Academic controls = `=subinstr("`academic_ctrl'", "i.", "*.", .)'" ) title("Table 4. Linear regression of post-transition selective aspiration") note("Note: Background controls include household income, highest father and mother education, and monthly investment in child; academic controls include STEM/humanities track, and scores in school subjects.") replace nomti l

* Table 5. 2-period OLS with pre-matched aspirations
cem sel_pre_bin aspedu_pre income_pre, tr(badupdate)
eststo clear
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate##i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r
qui eststo: reg sel_post_bin i.sel_pre_bin##i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r
esttab using "output\table5.rtf", nobase se indicate("Background controls = `=subinstr("`background_ctrl'", "i.", "*.", .)'" "Academic controls = `=subinstr("`academic_ctrl'", "i.", "*.", .)'") title("Table 5. Linear regression of post-transition selective aspiration, pre-matched on aspiration") replace nomti l

* Table 6. Two way FE with pre-matched aspirations
use "data\timedata.dta", clear
cem sel_pre_bin aspedu_pre, tr(badupdate)

local ctrl1 i.income i.fatheredu i.motheredu i.investment 
local ctrl2 i.track i.score_japanese i.score_math i.score_english i.score_science i.score_social
local timeFE i.grade i.wave

eststo clear
qui eststo: reg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], r 
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo: areg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace

esttab using "output\table6.rtf", nobase se l indicate("Background controls = `=subinstr("`ctrl1'", "i.", "*.", .)'" "Academic controls = `=subinstr("`ctrl2'", "i.", "*.", .)'") title("Table 6. With time and individual fixed effects, pre-matched on aspiration") drop(*.grade *.wave) s(timefixed IDfixed N,label("Time FE" "Individual FE")) nomti replace

* Table 7. Time FE with pre-matched aspirations by gender
local ctrl1 i.income i.fatheredu i.motheredu i.investment 
local ctrl2 i.track i.score_japanese i.score_math i.score_english i.score_science i.score_social
local timeFE i.grade i.wave

eststo clear
qui eststo male: reg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2'  if female == 0, r
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo female: reg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2' if female == 1, r
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo male_weight: reg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2' [iweight=cem_weights] if female == 0, r
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo female_weight: reg selective i.badupdate_t `timeFE' `ctrl1' `ctrl2' [iweight=cem_weights] if female == 1, r
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace

esttab using "output\table7.rtf", nobase se l indicate("Background controls = `=subinstr("`ctrl1'", "i.", "*.", .)'" "Academic controls = `=subinstr("`ctrl2'", "i.", "*.", .)'") title("Table 7. By gender, matched on pre-transition aspirations") drop(*.grade *.wave) s(timefixed IDfixed N,label("Time FE" "Individual FE")) note("Note: The first two columns did not pre-match on aspiration; the second two did.") mtitles replace


********************************
* SUPPLEMENTARY SPECIFICATIONS * 
********************************

* Alternate outcomes
* Table A2
local ctrl1 i.income i.fatheredu i.motheredu i.investment 
local ctrl2 i.track i.score_japanese i.score_math i.score_english i.score_science i.score_social 
local timeFE i.grade i.wave

qui eststo: reg national_imputed i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], r 
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo: areg national_imputed i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace

esttab using "output\appendix.rtf", nobase se l indicate("Background controls = `=subinstr("`ctrl1'", "i.", "*.", .)'" "Academic controls = `=subinstr("`ctrl2'", "i.", "*.", .)'") title("2 way FE with national aspiration, CEM") drop(*.grade *.wave) s(timefixed IDfixed N,label("Time FE" "Individual FE")) nomti append 

* Table 8. Alternate outcome, two-way FE with CEM
eststo clear
qui eststo: reg aspedu i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], r 
estadd local IDfixed "No", replace
estadd local timefixed "Yes", replace
qui eststo: areg aspedu i.badupdate_t `timeFE' `ctrl1' `ctrl2' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace

esttab using "output\table8.rtf", nobase se l indicate("Background controls = `=subinstr("`ctrl1'", "i.", "*.", .)'" "Academic controls = `=subinstr("`ctrl2'", "i.", "*.", .)'") title("Table 8. Aspired highest level of education, pre-matched aspirations") drop(*.grade *.wave) s(timefixed IDfixed N,label("Time FE" "Individual FE")) nomti replace 


* Figure 1. Multi-period DID with and without synthetic control

use "data\cleandata.dta", clear

local controlvar_9 "investment	score_japanese	score_math	score_science	score_social	score_english"
foreach x of local controlvar_9 {
	gen `x'_g9 = .
	forvalues i=1/7 {
		replace `x'_g9 = `x'`i' if grade`i' == 9
		replace `x'_g9 = `x'`i' if grade`i' == 8 & `x'_g9 == .
		replace `x'_g9 = `x'`i' if grade`i' == 7 & `x'_g9 == .
	}
}
keep PanelID investment_g9 score_japanese_g9 score_math_g9 score_science_g9 score_social_g9 score_english_g9
foreach x of local controlvar_9 {
	local newname = subinstr("`x'", "_g9", "", 1) 
	rename `x' `newname'
}
merge 1:m PanelID using "data\timedata.dta"

foreach x in female fatheredu motheredu income {
	bys PanelID (grade): egen mean_`x' = mean(`x')
	bys PanelID (grade): replace `x' = round(mean_`x') if `x' == .
}

drop if grade < 7 | grade > 12
drop if selective == .

keep PanelID selective grade badupdate_t female income fatheredu motheredu investment score_japanese score_math score_science score_social score_english track aspedu 

local controlvar "female	income	fatheredu	motheredu	investment	score_japanese	score_math	score_science	score_social	score_english"
foreach x of local controlvar {
	drop if `x' == .
}
bys PanelID: gen unbalanced = _N if _N != 6
sort unbalanced PanelID
drop if unbalanced != .
xtset PanelID grade
local controlvar "female	income	fatheredu	motheredu	investment	score_japanese	score_math	score_science	score_social	score_english"

* [i] DID
sdid selective PanelID grade badupdate_t, vce(placebo) reps(200) seed(101010) covariates(`controlvar') method(did)
matrix didse = sqrt(e(V)[1,1]/e(N_clust))
matrix didresult = e(b) , didse
matrix colnames didresult = "ATT Coefficient estimate" "ATT Variance estimate"
esttab m(didresult) using "output\didtable.rtf", replace
matrix didA=e(series)
matrix colnames didA = didgrade_series didYco10 didYtr10
qui svmat didA, names(col)
twoway (line didYco10 didgrade_series) (line didYtr10 didgrade_series), xline(9.5) legend(order(1 "{stSerif:Control}" 2 "{stSerif:Bad update}") pos(12) col(2)) xtitle("{stSerif:Grade}") ytitle("{stSerif:Mean selective aspiration}")
graph export "output\did.png", replace

* [ii] Synthetic DID 
sdid selective PanelID grade badupdate_t, vce(placebo) reps(200) seed(101010) covariates(`controlvar') method(sdid)
matrix sdidse = sqrt(e(V)[1,1]/e(N_clust))
matrix sdidresult = e(b) , sdidse
matrix colnames sdidresult = "ATT Coefficient estimate" "ATT Variance estimate"
esttab m(sdidresult) using "output\sdidtable.rtf", replace
matrix sdidA=e(series)
matrix colnames sdidA = sdidgrade_series sdidYco10 sdidYtr10
qui svmat sdidA, names(col)
twoway (line sdidYco10 sdidgrade_series) (line sdidYtr10 sdidgrade_series), xline(9.5) legend(order(1 "{stSerif:Control}" 2 "{stSerif:Bad update}") pos(12) col(2))
graph export "output\sdid.png", replace

twoway (line didYtr10 didgrade_series, lc(red)) (line didYco10 didgrade_series, lc(purple%60)) (line sdidYco10 sdidgrade_series, lc(blue)), xline(9.5) legend(order(1 "{stSerif:Bad update}"  2 "{stSerif:No bad update}" 3 "{stSerif:Synthetic Control}") pos(12) row(1)) xtitle("{stSerif: Grade}") ytitle("{stSerif: Mean selective aspiration}")
graph export "output\figure1.png", replace

matrix resulttable = didresult \ sdidresult
matrix rownames resulttable = "DID" "Synthetic DID"
matrix colnames resulttable = "Coef" "St err"
esttab m(resulttable) using "output\Atable4.rtf", replace title("Appendix Table 4. ATT estimates from DID and synthetic DID") note("Standard errors produced by 200 bootstrap repetitions")

* [iii] Synthetic event study
local controlvar "female	income	fatheredu	motheredu	investment	score_japanese	score_math	score_science	score_social	score_english"
set seed 101010
sdid_event selective PanelID grade badupdate_t, vce(placebo) brep(200) covariates(`controlvar') placebo(all)

matrix esdidresult = e(H)
esttab m(esdidresult) using "output\sdid_eventtable.rtf", replace
clear
mat esdidres = e(H)[2..7,1..5]
svmat esdidres
gen esdidid = _n - 1 if !missing(esdidres1)
replace esdidid = 3 - _n if _n > 3 & !missing(esdidres1)
sort esdidid
twoway (rarea esdidres3 esdidres4 esdidid, lc(gs10) fc(gs11%50)) (scatter esdidres1 esdidid, mc(blue)), legend(off) title("{stSerif:Event study}") yline(0) xtitle("{stSerif:Time to high school transition}") ytitle("{stSerif:Treatment effect}")
graph export "output\figureA2.png", replace



* Alternate treatment
use "data\cleandata.dta", clear

gen asppath = asppath6 if grade6 == 9 & grade7 == 10
gen alumnipath = alumnipath7 if grade6 == 9 & grade7 == 10
label values alumnipath path_labels
label values asppath path_labels

replace asppath = 3 if asppath == 4
replace alumnipath = 3 if alumnipath == 4
replace asppath = 2 if asppath == 5
replace alumnipath = 2 if alumnipath == 5

gen badupdate_alt = (alumnipath - asppath > 0) if asppath != . & alumnipath != .
replace badupdate_alt = 1 if badupdate == 1
label var badupdate_alt "Alternate bad update" 

save "data/alt_cleandata.dta", replace

use "data/alt_cleandata.dta", clear
local background_ctrl i.income_pre i.fatheredu i.motheredu i.investment_pre
local academic_ctrl i.track_pre i.score_japanese_pre i.score_math_pre i.score_english_pre i.score_science_pre i.score_social_pre i.score_track_pre 

eststo clear
drop if badupdate_alt == .
cem sel_pre_bin, tr(badupdate_alt) 
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate_alt i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r
qui eststo: reg sel_post_bin i.sel_pre_bin i.badupdate_alt##i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r
qui eststo: reg sel_post_bin i.sel_pre_bin##i.badupdate_alt i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights], r

esttab using "output\table9.rtf", nobase se l indicate("Background controls = `=subinstr("`background_ctrl'", "i.", "*.", .)'" "Academic controls = `=subinstr("`academic_ctrl'", "i.", "*.", .)'" ) title("Table 9. Alternate treatment: worse type of high school") replace nomti 

	
* Figure 2	
use "data/timedata", clear

loc figurevarA selective aspedu national
loc figurevargph
foreach x of loc figurevarA {
	preserve
	collapse (mean) y = `x' (semean) se_y = `x', by(grade female badupdate)
	drop if grade < 7
	gen yu = y + 1.96*se_y
	gen yl = y - 1.96*se_y
	twoway (scatter y grade if female==0 & badupdate==0, mc(blue)) (rcap yu yl grade if female==0 & badupdate==0, lc(blue)) (line y grade if female==0 & badupdate==0, lc(blue)) ///
		(scatter y grade if female==1 & badupdate==0, mc(red)) (rcap yu yl grade if female==1 & badupdate==0, lc(red)) (line y grade if female==1 & badupdate==0, lc(red)) ///
		(scatter y grade if female==0 & badupdate==1, mc(blue%20)) (rcap yu yl grade if female==0 & badupdate==1, lc(blue%20)) (line y grade if female==0 & badupdate==1, lc(blue%20)) ///
		(scatter y grade if female==1 & badupdate==1, mc(red%20)) (rcap yu yl grade if female==1 & badupdate==1, lc(red%20)) (line y grade if female==1 & badupdate==1, lc(red%20)), ///
		title("{stSerif:`x'}") ytitle("") xtitle("{stSerif:Grade}") legend(order(3 "{stSerif:Male, no BU}" 6 "{stSerif:Female, no BU}" 9 "{stSerif:Male, BU}" 12 "{stSerif:Female, BU}") rows(1) pos(6)) saving(`x', replace) 
	restore
	loc figurevargph `figurevargph' `x'.gph
}
grc1leg2 `figurevargph', pos(6) imargin(0 0 1 1)  ysize(4) xsize(10) rows(1)
graph export "output/figure2.png", replace


* Figure 3
use "data/timedata", clear

loc figurevarB score_all score_track score_mock score_parent
loc figurevargph
foreach x of loc figurevarB {
	preserve
	collapse (mean) y = `x' (semean) se_y = `x', by(grade female badupdate)
	drop if grade < 7
	gen yu = y + 1.96*se_y
	gen yl = y - 1.96*se_y
	twoway (scatter y grade if female==0 & badupdate==0, mc(blue)) (rcap yu yl grade if female==0 & badupdate==0, lc(blue)) (line y grade if female==0 & badupdate==0, lc(blue)) ///
		(scatter y grade if female==1 & badupdate==0, mc(red)) (rcap yu yl grade if female==1 & badupdate==0, lc(red)) (line y grade if female==1 & badupdate==0, lc(red)) ///
		(scatter y grade if female==0 & badupdate==1, mc(blue%20)) (rcap yu yl grade if female==0 & badupdate==1, lc(blue%20)) (line y grade if female==0 & badupdate==1, lc(blue%20)) ///
		(scatter y grade if female==1 & badupdate==1, mc(red%20)) (rcap yu yl grade if female==1 & badupdate==1, lc(red%20)) (line y grade if female==1 & badupdate==1, lc(red%20)), ///
		title("{stSerif:`x'}") ytitle("") xtitle("{stSerif:Grade}") legend(order(3 "{stSerif:Male, no BU}" 6 "{stSerif:Female, no BU}" 9 "{stSerif:Male, BU}" 12 "{stSerif:Female, BU}") rows(1) pos(6)) saving(`x', replace) 
	restore
	loc figurevargph `figurevargph' `x'.gph
}
grc1leg2 `figurevargph', pos(6) imargin(0 0 1 1)  ysize(6) xsize(8) 
graph export "output/figure3.pdf", replace

* Figure A2
use "data/timedata", clear
loc figurevarC investment track homework study
loc figurevargph
foreach x of loc figurevarC {
	preserve
	collapse (mean) y = `x' (semean) se_y = `x', by(grade female badupdate)
	drop if grade < 7
	gen yu = y + 1.96*se_y
	gen yl = y - 1.96*se_y
	twoway (scatter y grade if female==0 & badupdate==0, mc(blue)) (rcap yu yl grade if female==0 & badupdate==0, lc(blue)) (line y grade if female==0 & badupdate==0, lc(blue)) ///
	(scatter y grade if female==1 & badupdate==0, mc(red)) (rcap yu yl grade if female==1 & badupdate==0, lc(red)) (line y grade if female==1 & badupdate==0, lc(red)) ///
	(scatter y grade if female==0 & badupdate==1, mc(blue%20)) (rcap yu yl grade if female==0 & badupdate==1, lc(blue%20)) (line y grade if female==0 & badupdate==1, lc(blue%20)) ///
	(scatter y grade if female==1 & badupdate==1, mc(red%20)) (rcap yu yl grade if female==1 & badupdate==1, lc(red%20)) (line y grade if female==1 & badupdate==1, lc(red%20)), ///
	title("{stSerif:`x'}") ytitle("") xtitle("{stSerif:Grade}") legend(order(3 "{stSerif:Male, no BU}" 6 "{stSerif:Female, no BU}" 9 "{stSerif:Male, BU}" 12 "{stSerif:Female, BU}") rows(1) pos(6)) saving(`x', replace)
	restore
	loc figurevargph `figurevargph' `x'.gph
}
grc1leg2 `figurevargph', pos(6) imargin(0 0 1 1)  ysize(6) xsize(8) 
graph export "output/figureA2.pdf", replace

* Figure A3
use "data/timedata", clear
loc figurevarD learnnew mycareer mycollege noscold
loc figurevargph
foreach x of loc figurevarD {
	preserve
	collapse (mean) y = `x' (semean) se_y = `x', by(grade female badupdate)
	drop if grade < 7
	gen yu = y + 1.96*se_y
	gen yl = y - 1.96*se_y
	twoway (scatter y grade if female==0 & badupdate==0, mc(blue)) (rcap yu yl grade if female==0 & badupdate==0, lc(blue)) (line y grade if female==0 & badupdate==0, lc(blue)) ///
	(scatter y grade if female==1 & badupdate==0, mc(red)) (rcap yu yl grade if female==1 & badupdate==0, lc(red)) (line y grade if female==1 & badupdate==0, lc(red)) ///
	(scatter y grade if female==0 & badupdate==1, mc(blue%20)) (rcap yu yl grade if female==0 & badupdate==1, lc(blue%20)) (line y grade if female==0 & badupdate==1, lc(blue%20)) ///
	(scatter y grade if female==1 & badupdate==1, mc(red%20)) (rcap yu yl grade if female==1 & badupdate==1, lc(red%20)) (line y grade if female==1 & badupdate==1, lc(red%20)), ///
	title("{stSerif:`x'}") ytitle("") xtitle("{stSerif:Grade}") legend(order(3 "{stSerif:Male, no BU}" 6 "{stSerif:Female, no BU}" 9 "{stSerif:Male, BU}" 12 "{stSerif:Female, BU}") rows(1) pos(6)) ylabel(2(0.5)3.5) saving(`x', replace)
	restore
	loc figurevargph `figurevargph' `x'.gph
}
grc1leg2 `figurevargph', pos(6) imargin(0 0 1 1)  ysize(6) xsize(8) 
graph export "output/figureA3.png", replace

*********************
* ROBUSTNESS CHECKS * 
*********************
* Appendix Table 1. Varying sets of controls for main table
use "data\timedata.dta", clear
cem sel_pre_bin aspedu_pre, tr(badupdate)

local ctrl1 i.income i.fatheredu i.motheredu i.investment 
local ctrl2 i.track i.score_japanese i.score_math i.score_english i.score_science i.score_social 
local ctrl3 i.PFworktype i.PMworktype
local ctrl4 i.cram
local ctrl5 i.border
local ctrl6 score_track
local timeFE i.grade i.wave

eststo clear
qui eststo: areg selective i.badupdate_t  `ctrl1'  `ctrl2' `ctrl3' `timeFE' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace
qui eststo: areg selective i.badupdate_t  `ctrl1'  `ctrl2' `ctrl3' `ctrl4'  `timeFE' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace
qui eststo: areg selective i.badupdate_t  `ctrl1'  `ctrl2' `ctrl3' `ctrl4' `ctrl5' `timeFE' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace
qui eststo: areg selective i.badupdate_t  `ctrl1'  `ctrl2' `ctrl3' `ctrl4' `ctrl5' `ctrl6' `timeFE' [aweight=cem_weights], absorb(PanelID) vce(robust) 
estadd local IDfixed "Yes", replace
estadd local timefixed "Yes", replace

esttab using "output\Atable1.rtf", nobase se l indicate("Background controls = `=subinstr("`ctrl1'", "i.", "*.", .)'" "Academic controls = `=subinstr("`ctrl2'", "i.", "*.", .)'" "Parent work status = `=subinstr("`ctrl3'", "i.", "*.", .)'" "Cram school attendance = `=subinstr("`ctrl4'", "i.", "*.", .)'" "Birth order = `=subinstr("`ctrl5'", "i.", "*.", .)'" "Track performance = `=subinstr("`ctrl6'", "i.", "*.", .)'") title("Appendix Table 1. Replication of main findings with additional controls") drop(*.grade *.wave) s(timefixed IDfixed N,label("Time FE" "Individual FE")) note("Note: Replicates model 2 of Table 6, two-way fixed effects over all time periods, with pre-matched aspirations. Additional controls are parental employment status, attendance of cram school, birth order, and academic performance in declared track (STEM/humanities).") nomti replace compress

* Appendix Table 2. Probit specification of Table 5
use "data/cleandata", clear
cem sel_pre_bin aspedu_pre income_pre, tr(badupdate)

eststo clear
local background_ctrl i.income_pre i.fatheredu i.motheredu i.investment_pre
local academic_ctrl i.track_pre i.score_japanese_pre i.score_math_pre i.score_english_pre i.score_science_pre i.score_social_pre score_track_pre

qui: probit sel_post_bin i.sel_pre_bin i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
qui: probit sel_post_bin i.sel_pre_bin i.badupdate##i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
qui: probit sel_post_bin i.sel_pre_bin##i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
esttab using "output/Atable2.rtf", nobase se l replace title("Appendix Table 2. Probit specification of Table 5") note("Note: Marginal effects from probit specification of Table 5, 2-period unconstrained DID, with pre-matched aspirations. (1) Basic with controls (2) Allowing for bad update x female interaction (3) Allowing for bad update x pre-aspiration interaction. Estimates are average marginal effects at female = 0 and female = 1.")

* Appendix Table 3. Ordered probit specification of Table 5
use "data/cleandata", clear
cem sel_pre_bin aspedu_pre income_pre, tr(badupdate)

eststo clear
local background_ctrl i.income_pre i.fatheredu i.motheredu i.investment_pre
local academic_ctrl i.track_pre i.score_japanese_pre i.score_math_pre i.score_english_pre i.score_science_pre i.score_social_pre score_track_pre

qui: oprobit selective_post_ranked i.selective_pre_ranked i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
qui: oprobit selective_post_ranked i.selective_pre_ranked i.badupdate##i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
qui: oprobit selective_post_ranked i.selective_pre_ranked##i.badupdate i.female `background_ctrl' `academic_ctrl' [iweight=cem_weights]
qui eststo: margins, dydx(badupdate) at(female=(0 1)) post
esttab using "output/Atable3.rtf", nobase se l replace title("Appendix Table 3. Ordered probit specification of Table 5") note("Note: Marginal effects from probit specification of Table 5, 2-period unconstrained DID, with pre-matched aspirations. (1) Basic with controls (2) Allowing for bad update x female interaction (3) Allowing for bad update x pre-aspiration interaction. Estimates are predicted probabilities at female = 0 and female = 1 and levels of selective aspiration, 1 being the least and 4 being the most. ")

