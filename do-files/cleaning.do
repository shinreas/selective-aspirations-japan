* This do-file starts from the original dataset, subsets, cleans, and translates key variables. Outputs cleandata.dta and timedata.dta

***************
* 1. CLEANING * 
***************

* Subset original data
use "data\JLSCP.dta", clear
drop if PanelID >= 9999991 

* Response flag
label define status_labels 1 "Parent and child" 2 "Only parent" 3 "Only child" 4 "No response" 5 "Excl from analysis" 6 "Outside sample"
label define simple_status_labels 1 "Complete" 0 "Incomplete"
foreach x of varlist w*回答フラグ {
    local newvar = subinstr("`x'", "回答フラグ", "status", 1)  
    clonevar `newvar' = `x'                                 
	label values `newvar' status_labels
	local newlabel = subinstr("`x'", "回答フラグ", " response status", 1)
	label var `newvar' "`newlabel'"
	
	// The following lines are for generating summary statistics only
	replace `newvar' = . if inlist(`newvar', 4, 6)
	replace `newvar' = 1 if inlist(`newvar', 1)
	replace `newvar' = 0 if inlist(`newvar', 2, 3, 5)
	label values `newvar' simple_status_labels
}

* Keep only students whose data overlaps the middle-high transition 
replace w1学年 = . if w1学年 == 8888
replace w3学年 = . if w3学年 == 8888

egen max_grade = rowmax(w*学年)
egen min_grade = rowmin(w*学年)
drop if max_grade < 10
drop if min_grade > 9

* Grade
label define grade_labels 4 "Elementary 4" 5 "Elementary 5" 6 "Elementary 6" 7 "Middle 1" 8 "Middle 2" 9 "Middle 3" 10 "High 1" 11 "High 2" 12 "High 3" 13 "Not in school"
foreach x of varlist w*学年 {
    local newvar = subinstr("`x'", "学年", "", 1)  
	local newvar = subinstr("`newvar'", "w", "grade", 1)  
    clonevar `newvar' = `x'                                 
	local newlabel = subinstr("`newvar'", "grade", " grade",1) 
	label var `newvar' "`newlabel'"
	label values `newvar' grade_labels
}

* Consolidating gender responses
gen female = 1 if w1子ども性別 == 2

foreach x of varlist w*子ども性別 {
	replace female = 1 if `x' == 2
	replace female = 0 if `x' == 1
}

label define gender_labels 0 "Male" 1 "Female"
label values female gender_labels
label var female "Sex"

* Household income ds0000000052_w*p
foreach x of varlist ds0000000052_w*p {
    local newvar = subinstr("`x'", "ds0000000052_w", "income", 1)  
	local newvar `=substr("`newvar'", 1,7)'
    clonevar `newvar' = `x'                                 
	local newlabel = subinstr("`newvar'", "income_", "Household income, ",1) 
	label var `newvar' "`newlabel'"
	replace `newvar' = . if inlist(`newvar', 11, 8888, 9999)
}

label define income_labels 1 "Below 2 million JPY" 2 "Below 2-3 million JPY" 3 "Below 3-4 million JPY" 4 "Below 4-5 million JPY" 5 "Below 5-6 million JPY" 6 "Below 6-8 million JPY" 7 "Below 8-10 million JPY" 8 "Below 10-15 million JPY" 9 "Below 15-20 million JPY" 10 "Above 20 million JPY"
gen income_pre = .

// Define pre-transition hh income as the most recently reported income value up to grade 9
forvalues j = 1/9 {
	forvalues i = 1/7 {
		replace income_pre = income`i' if grade`i' == `j' & income`i' != .
	}
}
label values income_pre income_labels

* Average income of a given household across waves
egen avgincome = rmean(income*)
gen avgincome0 = round(avgincome)

label values avgincome0 income_labels
label var avgincome0 "Average income across waves"

* Parent education
foreach x of varlist P*ED** {
	replace `x' = . if inlist(`x', 7, 8, 9999) // Mark missing if "other", "don't know", or no response
}
egen fatheredu = rowmax(PFED**)
label var fatheredu "Father's highest level of education"
egen motheredu = rowmax(PMED**)
label var motheredu "Mother's highest level of education"
label define parentedu_labels 1 "Middle school" 2 "High school" 3 "Vocational school" 4 "Junior college" 5 "4-6 year college" 6 "Graduate school" 
label values fatheredu parentedu_labels
label values motheredu parentedu_labels

* Parental investment per child, monthly average ds0000000143_w*p
label define investment_labels 1 "About 1000 JPY" 2 "1000-2500 JPY" 3 "2500-5000 JPY" 4 "5000-10,000 JPY" 5 "10,000-15,000 JPY" 6 "15,000-20,000 JPY" 7 "20,000-30,000 JPY" 8 "30,000-40,000 JPY" 9 "40,000-50,000 JPY" 10 "Over 50,000 JPY" 
foreach x of varlist ds0000000143_w*p {
	local newvar = subinstr("`x'", "ds0000000143_w", "investment", 1)  
	local newvar `=substr("`newvar'", 1,11)'
    clonevar `newvar' = `x'                                 
	label values `newvar' investment_labels
	local newlabel = subinstr("`x'", "ds0000000143_", "Monthly investment per child ", 1)
	label var `newvar' "`newlabel'"
	replace `newvar' = . if `newvar' == 9999
}
gen investment_pre = .
forvalues i = 1/7 {
	replace investment_pre = investment`i' if grade`i' == 9
	replace investment_pre = investment`i' if grade`i' == 8 & investment_pre == .
	replace investment_pre = investment`i' if grade`i' == 7 & investment_pre == .
}
label values investment_pre investment_labels

gen investment_post = .
forvalues i = 1/7 {
	replace investment_post = investment`i' if grade`i' == 10
	replace investment_post = investment`i' if grade`i' == 11 & investment_post == .
	replace investment_post = investment`i' if grade`i' == 12 & investment_post == .


}
label values investment_post investment_labels

* Cram school attendance ds0000000121_w*p
foreach x of varlist ds0000000121_w*p {
    local newvar = subinstr("`x'", "ds0000000121_w", "cram", 1) 
	local newvar `=substr("`newvar'", 1,5)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 9999)
}

* Type of cram school ds0000000122_w*p - transform cram school attendance from bin to ranked
foreach x of varlist ds0000000122_w*p {
    local newvar = subinstr("`x'", "ds0000000122_w", "typecram", 1) 
	local newvar `=substr("`newvar'", 1,9)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 8888)
}

* Generate ranked cram school variable
label define cram_labels 0 "Not going" 1 "Going" 2 "Going for exam prep"
foreach x of varlist cram* {
	replace `x' = 0 if `x' == 2
	loc cramtypename = subinstr("`x'", "cram", "typecram", 1) 
	replace `x' = 2 if `cramtypename' == 3
	replace `x' = 1 if inlist(`cramtypename', 1, 2) 
	label values `x' cram_labels
}

gen cram_pre = .
forvalues i = 1/7 {
	replace cram_pre = cram`i' if grade`i' == 9
	replace cram_pre = cram`i' if grade`i' == 8 & cram_pre == .
	replace cram_pre = cram`i' if grade`i' == 7 & cram_pre == .
}

* Aspired education level ds0000000198_w*c
label define aspedu_levels 1 "Middle school" 2 "High school" 3 "Technical college" 4 "Vocational school" 5 "Junior college" 6 "4-6 year college" 7 "Graduate school" 8 "Other" 9 "Not sure yet" 
foreach x of varlist ds0000000198_w*c {
    local newvar = subinstr("`x'", "ds0000000198_w", "aspedu", 1)  
	local newvar `=substr("`newvar'", 1,7)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 8, 9, 9999)
	label values `newvar' aspedu_labels
}

* Take 3rd year of middle school's response as aspiration in middle school
gen aspedu_pre = .
forvalues i = 1/7 {
	replace aspedu_pre = aspedu`i' if grade`i' == 9
	replace aspedu_pre = aspedu`i' if grade`i' == 8 & aspedu_pre == .
	replace aspedu_pre = aspedu`i' if grade`i' == 7 & aspedu_pre == .
}

label var aspedu_pre "Aspired level of education (middle school)"
label values aspedu_pre aspedu_levels

gen level_pre = 1 if inlist(aspedu_pre, 2)
replace level_pre = 2 if inlist(aspedu_pre, 3,4,5)
replace level_pre = 3 if inlist(aspedu_pre, 6)
replace level_pre = 4 if inlist(aspedu_pre, 7)

label define asplevel_labels 1 "High school" 2 "Vocational/technical/junior college" 3 "4-6 year college" 4 "Graduate school"

label values level_pre asplevel_labels

* Take 3rd year of high school's response as aspiration in high school
gen aspedu_post = .
forvalues i = 1/7 {
    replace aspedu_post = aspedu`i' if grade`i' == 12
	replace aspedu_post = aspedu`i' if aspedu_post == . & grade`i' == 11
	replace aspedu_post = aspedu`i' if aspedu_post == . & grade`i' == 10
}

label var aspedu_post "Aspired level of education (high school)"
label values aspedu_post aspedu_levels

gen level_post = 1 if inlist(aspedu_post, 2)
replace level_post = 2 if inlist(aspedu_post, 3,4,5)
replace level_post = 3 if inlist(aspedu_post, 6)
replace level_post = 4 if inlist(aspedu_post, 7)

label values level_post asplevel_labels 

* Selective aspiration ds0000000371_w**
label define response_labels 1 "Very applicable" 2 "Somewhat applicable" 3 "Not very applicable" 4 "Not applicable at all" 
foreach x of varlist ds0000000371_w*c {
    local newvar = subinstr("`x'", "ds0000000371_w", "selectivecat_old", 1)  
	local newvar `=substr("`newvar'", 1,17)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 8888, 9999)
	label values `newvar' response_labels
}
forvalues i=1/7 {
	vreverse selectivecat_old`i', generate(selectivecat`i')
	gen selective`i' = 1 if inlist(selectivecat`i', 3, 4)
	replace selective`i' = 0 if inlist(selectivecat`i', 1, 2)
}

* Use response from last year of middle/high school 
gen selective_pre = .
forvalues i = 1/7 {
    replace selective_pre = selectivecat_old`i' if grade`i' == 9 & selective_pre == .
	replace selective_pre = selectivecat_old`i' if grade`i' == 8 & selective_pre == .
	replace selective_pre = selectivecat_old`i' if grade`i' == 7 & selective_pre == .
}
label values selective_pre response_labels
label var selective_pre "Aspiration for selective school in Middle 3"

gen selective_post = .
forvalues i = 1/7 {
    replace selective_post = selectivecat_old`i' if grade`i' == 10 & selective_post == .
	replace selective_post = selectivecat_old`i' if grade`i' == 11 & selective_post == .
	replace selective_post = selectivecat_old`i' if grade`i' == 12 & selective_post == .

}
label values selective_post response_labels
label var selective_post "Aspiration for selective school in High 1"

vreverse selective_pre, generate(selective_pre_ranked)
vreverse selective_post, generate(selective_post_ranked) 

* Binarize selective_post_ranked, selective_pre_ranked
label define yesno_lab 0 "No selective aspiration" 1 "Selective aspiration"
gen sel_post_bin = 1 if inlist(selective_post_ranked, 3, 4)
replace sel_post_bin = 0 if inlist(selective_post_ranked, 1, 2)
label values sel_post_bin yesno_lab
gen sel_pre_bin = 1 if inlist(selective_pre_ranked, 3, 4)
replace sel_pre_bin = 0 if inlist(selective_pre_ranked, 1, 2)
label values sel_pre_bin yesno_lab

* Bad update ds0000000196_w**
label define topchoice_labels 1 "Top choice" 2 "Second choice" 3 "Third or below" 4 "Didn't care"

gen topchoice = .
forvalues i = 2/7 {
    replace topchoice = ds0000000196_w`i'c if grade`i' == 10 // first year of hs
}
replace topchoice = . if inlist(topchoice, 7777, 8888, 9999)
label values topchoice topchoice_labels

gen badupdate = 1 if topchoice == 3
replace badupdate = 0 if badupdate == .
label var badupdate "Bad update"

* Weights for bad update (how decided their top choice was)
label define weight_labels 1 "Not yet" 2 "Mostly" 3 "Very"
foreach x of varlist ds0000000204_w*c {
	local newvar = subinstr("`x'", "ds0000000204_w", "choiceweight", 1)  
	local newvar `=substr("`newvar'", 1, 13)'
	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	vreverse `x', generate(`newvar')	
	label values `newvar' weight_labels
}

forvalues i = 1/7 {
	gen weight`i' = choiceweight`i' if grade`i' == 10
}
egen weight = rowmax(weight*)

* Type of aspired high school ds0000000202_w*c
label define type_old_labels 1 "Public" 2 "National" 3 "Private" 4 "Other" 5 "Not sure yet"
label define type_labels 1 "Public/other" 2 "Private" 3 "National"

foreach x of varlist ds0000000202_w*c {
    local newvar = subinstr("`x'", "ds0000000202_w", "hightype_old", 1)  
	local newvar `=substr("`newvar'", 1,13)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 8888, 9999)
	replace `newvar' = 5 if `newvar' == 6
	label values `newvar' type_old_labels
}
forvalues i=1/7 {
	gen hightype`i' = 1 if inlist(hightype_old`i', 1, 4)
	replace hightype`i' = 2 if hightype_old`i' == 3
	replace hightype`i' = 3 if hightype_old`i' == 2
	label values hightype`i' type_labels
}

* Aspired type of university ds0000000206_w**
foreach x of varlist ds0000000206_w*c {
    local newvar = subinstr("`x'", "ds0000000206_w", "unitype_old", 1)  
	local newvar `=substr("`newvar'", 1,12)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 8888, 9999)
	replace `newvar' = 5 if `newvar' == 6
	label values `newvar' type_old_labels
}

forvalues i=1/7 {
	gen national`i' = 1 if unitype_old`i' == 2
	replace national`i' = 0 if inlist(unitype_old`i', 1, 3, 4, 5)
	drop if national`i' != . & grade`i' < 10
}

forvalues i=1/7 {
	gen unitype`i' = 1 if inlist(unitype_old`i', 1, 4)
	replace unitype`i' = 2 if unitype_old`i' == 3
	replace unitype`i' = 3 if unitype_old`i' == 2
	label values unitype`i' type_labels
}

gen unitype_post = .
forvalues i = 1/7 {
    replace unitype_post = ds0000000206_w`i'c if grade`i' == 10
}
replace unitype_post = . if inlist(unitype_post, 7777, 8888, 9999)
replace unitype_post = 5 if unitype_post == 6
label var unitype_post "Aspired type of university"
label values unitype_post type_old_labels

gen national_post = 1 if unitype_post == 2
replace national_post = 0 if inlist(unitype_post, 1, 3, 4, 5)

gen unitype_post_ranked = 1 if inlist(unitype_post, 1, 4)
replace unitype_post_ranked = 2 if unitype_post == 3
replace unitype_post_ranked = 3 if unitype_post == 2

label values unitype_post_ranked type_labels

* Common post-grad path for alumni of aspired HS ds0000000814_w*c
label define path_labels 1 "Selective university" 2 "Mid-tier university" 3 "Technical school" 4 "Employment" 5 "Not sure"
foreach x of varlist ds0000000814_w*c {
    local newvar = subinstr("`x'", "ds0000000814_w", "asppath", 1)  
	local newvar `=substr("`newvar'", 1,8)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 8888, 9999)
	replace `newvar' = 5 if `newvar' == 6
	label values `newvar' path_labels
}

* Common post-grad path for alumni of current HS ds0000000197_w*c
foreach x of varlist ds0000000197_w*c {
    local newvar = subinstr("`x'", "ds0000000197_w", "alumnipath", 1)  
	local newvar `=substr("`newvar'", 1,11)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 8888, 9999)
	replace `newvar' = 5 if `newvar' == 6
	label values `newvar' path_labels
}

* Mock exam performance ds0000000153_w**
label define performance_labels 1 "Low" 2 "Below average" 3 "Average" 4 "Above average" 5 "High" 6 "Don't know/haven't taken"
foreach x of varlist ds0000000153_w*c {
    local newvar = subinstr("`x'", "ds0000000153_w", "score_mock", 1)  
	local newvar `=substr("`newvar'", 1,11)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 7777, 9999)
	label values `newvar' performance_labels
	
	local temporaryvar = subinstr("`newvar'", "score_mock", "score_mock_temp", 1)  
    clonevar `temporaryvar' = `newvar'                                 
	replace `temporaryvar' = . if inlist(`temporaryvar', 6)
	label values `temporaryvar' performance_labels
}
egen avgscore_mock = rmean(score_mock_temp*)
replace avgscore_mock = round(avgscore_mock)
label values avgscore_mock performance_labels
label var avgscore_mock "Average mock exam performance"
drop score_mock_temp*

forvalues i = 2/7 {
	drop if score_mock`i' != . & grade`i' < 10
}

* Humanities vs. STEM
label define track_labels 1 "Strongly humanities" 2 "Slightly humanities" 3 "Neither" 4 "Slightly STEM" 5 "Strongly STEM" 
foreach x of varlist ds0000000180_w*c {
    local newvar = subinstr("`x'", "ds0000000180_w", "track", 1)  
	local newvar `=substr("`newvar'", 1,6)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 7777, 8888, 9999)
	label values `newvar' track_labels
}

gen track_pre = .
forvalues i = 1/7 {
	replace track_pre = track`i' if grade`i' == 9
}	
label values track_pre track_labels
	
* Performance by subject
label define score_labels 1 "Low" 2 "Below average" 3 "Average" 4 "Above average" 5 "High" 
foreach x of varlist ds0000000148_w*c {
    local newvar = subinstr("`x'", "ds0000000148_w", "score_japanese", 1) 
	local newvar `=substr("`newvar'", 1,15)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 9999)
	label values `newvar' score_labels
}
foreach x of varlist ds0000000149_w*c {
    local newvar = subinstr("`x'", "ds0000000149_w", "score_math", 1)  
	local newvar `=substr("`newvar'", 1,11)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 9999)
	label values `newvar' score_labels
}
foreach x of varlist ds0000000150_w*c {
    local newvar = subinstr("`x'", "ds0000000150_w", "score_science", 1) 
	local newvar `=substr("`newvar'", 1,14)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 9999)
	label values `newvar' score_labels
}
foreach x of varlist ds0000000151_w*c {
    local newvar = subinstr("`x'", "ds0000000151_w", "score_social", 1) 
	local newvar `=substr("`newvar'", 1,13)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 9999)
	label values `newvar' score_labels
}
foreach x of varlist ds0000000152_w*c {
    local newvar = subinstr("`x'", "ds0000000152_w", "score_english", 1)  
	local newvar `=substr("`newvar'", 1,14)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 7777, 8888, 9999)
	label values `newvar' score_labels
}
loc scores "score_japanese score_math score_science score_social score_english"
foreach x of local scores {
	gen `x'_pre = .
	forvalues i=1/7 {
		replace `x'_pre = `x'`i' if grade`i' == 9
		replace `x'_pre = `x'`i' if grade`i' == 8 & `x'_pre == .
		replace `x'_pre = `x'`i' if grade`i' == 7 & `x'_pre == .
	}
}

* Track score - if self-declared humanities, performance in Japanese, social studies, and English ; if self-declared STEM, performance in math and science; if neither, then average performance over all subjects

gen score_track_pre = .
forvalues i = 1/7 {
	gen score_track`i' = .
	egen score_stem`i' = rmean(score_science`i' score_math`i')
	egen score_hum`i' = rmean(score_japanese`i' score_social`i' score_english`i')
	egen score_all`i' = rmean(score_science`i' score_math`i' score_japanese`i' score_social`i' score_english`i')
	replace score_track`i' = score_stem`i' if inlist(track`i', 4, 5)
	replace score_track`i' = score_hum`i' if inlist(track`i', 1, 2)
	replace score_track`i' = score_all`i' if track`i' == 3
	replace score_track_pre = score_track`i' if grade`i' == 9
}
replace score_track_pre = round(score_track_pre)


* Parent-reported child's overall performance
foreach x of varlist ds0000000147_w*p {
    local newvar = subinstr("`x'", "ds0000000147_w", "score_parent", 1)
	local newvar `=substr("`newvar'", 1,13)'
    clonevar `newvar' = `x'                                 
	replace `newvar' = . if inlist(`newvar', 6, 8888, 9999)
	label values `newvar' performance_labels
}

gen score_parent_pre = .
forvalues j = 7/9 {
	forvalues i = 1/7 {
		replace score_parent_pre = score_parent`i' if grade`i' == `j' & score_parent`i' != .
	}
}
label values score_parent_pre score_labels

* Confidence (I have confidence in myself) ds0000000360_w*c (waves 3-7)
label define response_labels_reverse 1 "Not applicable at all" 2 "Not very applicable" 3 "Somewhat applicable" 4 "Very applicable" 
foreach x of varlist ds0000000360_w*c {
	replace `x' = . if inlist(`x', 9999)
    local newvar = subinstr("`x'", "ds0000000360_w", "confidence", 1)
	local newvar `=substr("`newvar'", 1,11)'
	vreverse `x', generate(`newvar')
	label values `newvar' response_labels_reverse
}

gen confidence_pre = .
forvalues j = 7/9 {
	forvalues i = 3/7 {
		replace confidence_pre = confidence`i' if grade`i' == `j' & confidence`i' != .
	}
}
label values confidence_pre response_labels_reverse

gen confident_pre = 1 if inlist(confidence_pre, 3, 4)
replace confident_pre = 0 if inlist(confidence_pre, 1, 2)

* Confidenceback (Even if I fail, I can regain confidence) ds0000000361_w*c (all waves but 3)
foreach x of varlist ds0000000361_w*c {
	replace `x' = . if inlist(`x', 9999)
    local newvar = subinstr("`x'", "ds0000000361_w", "confidenceback", 1)
	local newvar `=substr("`newvar'", 1,15)'
    vreverse `x', generate(`newvar')                            
	label values `newvar' response_labels_reverse
}
forvalues i = 1/2 {
	forvalues j = 7/9 {
	replace confidence_pre = confidenceback`i' if grade`i' == `j' & confidenceback2 != . & confidence_pre == .
}
}

* Ambition (I want to challenge myself to do new or difficult things) ds0000000363_w*c
foreach x of varlist ds0000000363_w*c {
    replace `x' = . if inlist(`x', 9999)
	local newvar = subinstr("`x'", "ds0000000363_w", "ambition", 1)  
	local newvar `=substr("`newvar'", 1,9)'
    vreverse `x', generate(`newvar')                           
	label values `newvar' response_labels_reverse
}

gen ambition_pre = .
forvalues j = 7/9 {
	forvalues i = 1/7 {
		replace ambition_pre = ambition`i' if grade`i' == `j' & ambition`i' != .
	}
}
label values ambition_pre response_labels_reverse

gen ambitious_pre = 1 if inlist(ambition_pre, 3, 4)
replace ambitious_pre = 0 if inlist(ambition_pre, 1, 2)

* Competitiveness ds0000000227_w** (waves 2-7)
foreach x of varlist ds0000000227_w** {
 	replace `x' = . if inlist(`x', 9999)
	local newvar = subinstr("`x'", "ds0000000227_w", "competitiveness", 1)  
	local newvar `=substr("`newvar'", 1,16)'
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}

gen competitiveness_pre = .
forvalues j = 7/9 {
	forvalues i = 2/7 {
		replace competitiveness_pre = competitiveness`i' if grade`i' == `j' & competitiveness`i' != .
	}
}
label values competitiveness_pre response_labels_reverse

gen competitive_pre = 1 if inlist(competitiveness_pre, 3, 4)
replace competitive_pre = 0 if inlist(competitiveness_pre, 1, 2)

* Self-esteem ds0000000359_w*c
foreach x of varlist ds0000000359_w*c {
	replace `x' = . if inlist(`x', 9999)    
	local newvar = subinstr("`x'", "ds0000000359_w", "esteem", 1) 
	local newvar `=substr("`newvar'", 1,7)'
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}

gen esteem_pre = .
forvalues j = 7/9 {
	forvalues i = 1/7 {
		replace esteem_pre = esteem`i' if grade`i' == `j' & esteem`i' != .
	}
}
label values esteem_pre response_labels_reverse

gen hasesteem_pre = 1 if inlist(esteem_pre, 3, 4)
replace hasesteem_pre = 0 if inlist(esteem_pre, 1, 2)

* Order of birth of surveyed child ds0000000079_w*p
label define border_label 1 "1st born" 2 "2nd born" 3 "3rd born" 4 "4th born" 5 "5th born or later"
clonevar border = ds0000000079_w1p
replace border = . if inlist(border, 7777, 9999) 
replace border = 5 if border >= 5
label values border border_label

* Part-time work ds0000000265_w*c
foreach x of varlist ds0000000265_w*c {
	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000265_w", "work", 1)
	local newvar `=substr("`newvar'", 1,5)'	
	clonevar `newvar' = `x'
	recode `newvar' (3 = 0) (1 2 = 1)
	label values `newvar' .
}

* Time spent doing homework ds0000000095_w*c
label define time_label 1 "0" 2 "5 min" 3 "10 min" 4 "15 min" 5 "30 min" 6 "1 hr" 7 "2 hr" 8 "3 hr" 9 "4 hr" 10 ">4 hr"
foreach x of varlist ds0000000095_w*c {
	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000095_w", "homework", 1)
	local newvar `=substr("`newvar'", 1,9)'	
	clonevar `newvar' = `x'
	label values `newvar' time_label
}

* Time spent studying ds0000000096_w*c
foreach x of varlist ds0000000096_w*c {
	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000096_w", "study", 1)
	local newvar `=substr("`newvar'", 1,6)'	
	clonevar `newvar' = `x'
	label values `newvar' time_label
}

* Parent employment status 
label define pemp_label 1 "Full time" 2 "Part time" 3 "Contract" 4 "Temporary" 5 "Self-employed" 6 "Other" 7 "Unemployed (incl. housewife)"
foreach x of varlist P*worktype* {
	replace `x' = . if inlist(`x', 8, 7777, 8888, 9999)
	label values `x' pemp_label
}
forvalues i=15/21 {
	loc j = `i'-14
	rename PMworktype`i' PMworktype`j'
	rename PFworktype`i' PFworktype`j'
}

* Study motivation
* learn new things ds0000000224_w*c
foreach x of varlist ds0000000224_w*c {
	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000224_w", "learnnew", 1)
	local newvar `=substr("`newvar'", 1,9)'	
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}
* to get into college i want
foreach x of varlist ds0000000228_w** {
 	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000228_w", "mycollege", 1)  
	local newvar `=substr("`newvar'", 1,10)'
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}
* because i dont want to be scolded
foreach x of varlist ds0000000230_w** {
 	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000230_w", "noscold", 1)  
	local newvar `=substr("`newvar'", 1,8)'
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}
* to have the career i want
foreach x of varlist ds0000000232_w** {
 	replace `x' = . if inlist(`x', 7777, 8888, 9999)
	local newvar = subinstr("`x'", "ds0000000232_w", "mycareer", 1)  
	local newvar `=substr("`newvar'", 1,9)'
    vreverse `x', generate(`newvar')                                 
	label values `newvar' response_labels_reverse
}

drop ds* P*workhome* P*worktime* P*workjob* w*回答フラグ w*学年 w*子ども性別 P*ED* unitype_old* selectivecat_old* hightype_old*

save "data\cleandata.dta", replace

*******************
* 2. RUNNING TIME * 
*******************

reshape long grade selective selectivecat income investment aspedu unitype hightype choiceweight national asppath alumnipath cram score_mock track score_japanese score_math score_science score_social score_english score_hum score_stem score_all score_track score_parent confidence confidenceback ambition competitiveness esteem work homework study PFworktype PMworktype learnnew mycollege noscold mycareer, i(PanelID) j(wave)

* indicate badupdate starting grade 10
gen badupdate_t = 1 if badupdate == 1 & grade >= 10
replace badupdate_t = 0 if badupdate_t == .
label var badupdate_t "Bad update" 

* indicate if student has ever aspired for a 4-year college
bys PanelID: egen college_ever = max(aspedu)
replace college_ever = 0 if college_ever < 6
replace college_ever = 1 if college_ever >= 6

* since national has no responses in middle school, approximate yes if selective aspiration
clonevar national_imputed = national
replace national_imputed = 1 if grade < 10 & selective > 2
replace national_imputed = 0 if grade < 10 & selective <= 2

* binarize personality measures
recode confidence (1 2 = 0) (3 4 = 1), generate(confident)
recode ambition (1 2 = 0) (3 4 = 1), generate(ambitious)
recode competitiveness (1 2 = 0) (3 4 = 1), generate(competitive)
recode esteem (1 2 = 0) (3 4 = 1), generate(hasesteem)
label var confident "Confident"
label var ambitious "Ambitious"
label var competitive "Competitive"
label var hasesteem "Has esteem"

* set as panel
drop if grade == . | grade > 12
duplicates tag PanelID grade, gen(repeated)
drop if repeated != 0
xtset PanelID grade

save "data\timedata.dta", replace