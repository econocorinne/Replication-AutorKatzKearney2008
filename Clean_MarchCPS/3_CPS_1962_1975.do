/*==============================================================================
	DESCRIPTION: clean CPS-ASEC years 1962-1975
==============================================================================*/		

/*------------------------------------------------------------------------------
	Set paths here
------------------------------------------------------------------------------*/
do "/XX.do"

/*------------------------------------------------------------------------------
	CPS ASEC cleaning, 1962-1975
------------------------------------------------------------------------------*/
* data downloaded from IPUMS
use "$data_raw/cps_asec.dta", clear

* keep relevant years
keep if inrange(year, 1962, 1975)

* exclude armed forces (missing variables some years)
keep if popstat==1 
drop popstat

/*------------------------------------------------------------------------------
	Demographics
------------------------------------------------------------------------------*/
* keep those who were at least age 16 last year (i.e. age>=17)
keep if age>=17

* redefine age topcode to be 90 (varies by year)
replace age=90 if age>=90

* create female variable
gen female=sex==2
lab var female "Female (1:yes 0:no)"
drop sex

* create race groups
replace race=1 if race==100
replace race=2 if race==200
replace race=3 if race==700
gen white=race==1
gen black=race==2
gen other=race==3
assert white+black+other==1
lab var white "Race: white"
lab var black "Race: black"
lab var other "Race: other"

* relabel variable "race"
label define race 1 "White" 2 "Black" 3 "Other"
label values race race

* keep those who worked at least 1 week last year
keep if wkswork2>=1 & wkswork2<=6

* create allocated flag
gen allocated=(qincwage==1)

/*------------------------------------------------------------------------------
	Education
------------------------------------------------------------------------------*/
* create school variable
gen school=1 if (educ<=71)
replace school=2 if (educ==72)
replace school=3 if (educ>=73 & educ<=100)
replace school=4 if (educ>=110 & educ<=121) 
replace school=5 if (educ>=122)

assert school!=.
label define school 1 "HSD" 2 "HSG" 3 "SMC" 4 "CLG" 5 "GTC"
label values school school
lab var school "Highest schooling completed (5 groups)"

* 9 schooling groups: 0-4, 5-8, 9, 10, 11, 12, 13-15, 16, 17 
gen ed0_4=(educ<=14) 
gen ed5_8=(educ>=21 & educ<=32)
gen ed9=(educ==40)
gen ed10=(educ==50)
gen ed11=(educ==60 | educ==71)
gen ed12=(educ==72)
gen ed13_15=(educ>=73 & educ<=100)
gen ed16=(educ==110)
gen ed17p=(educ>=122)

* create consistent education categories
drop if educ==999
if year<=1974 {
	gen ed8 = educ<=32
	gen edhsg = (educ==72 | educ==73)
	gen edsmc = (educ>=73 & educ<=100)
	gen edclg = (educ>=110 & educ<=121)
	gen edgtc = (educ>=122)
}
if year==1975 {
	gen ed8 = educ<=32
	gen edhsg = (educ==72)
	gen edsmc = (educ>=73 & educ<=100)
	gen edclg = (educ>=110 & educ<=121)
	gen edgtc = (educ>=122)
}
// assert ed8+ed9+ed10+ed11+edhsg+edsmc+edclg+edgtc==1
gen edhsd = ed8+ed9+ed10+ed11


/* In Autor's cleaning code, he constructs an educational attainment variable "educomp" 
 based on two other variables: 1) "_grdhi" (Autor) or "higrade" in IPUMS CPS, 
 and 2) "grdcom". The variable "educomp" is equivalent to "educ" in IPUMS CPS 
 except with different values.  I create "educomp" based on the IPUMS "educ" variable. */
gen educomp=.
replace educomp=0 if educ==1 | educ==2
replace educomp=1 if educ==11
replace educomp=2 if educ==12
replace educomp=3 if educ==13
replace educomp=4 if educ==14
replace educomp=5 if educ==21
replace educomp=6 if educ==22
replace educomp=7 if educ==31
replace educomp=8 if educ==32
replace educomp=9 if educ==40
replace educomp=10 if educ==50
replace educomp=11 if educ==60
replace educomp=12 if educ==72 
replace educomp=13 if educ==73 | educ==80
replace educomp=14 if educ==90
replace educomp=15 if educ==100
replace educomp=16 if educ==110
replace educomp=17 if educ==121
replace educomp=18 if educ==122

/*------------------------------------------------------------------------------
	Experience
------------------------------------------------------------------------------*/
* create experience variable
gen exp=max(age-educomp-7,0)
lab var exp "Experience (years)"

* create age last year (agely): age=71 for age>=71
gen agely=age-1 if age>=17 & age<=71
replace agely=71 if age>=72
drop age

* experience education interactions
gen exp1=exp
gen exp2 = (exp1^2)/100
gen exp3 = (exp1^3)/1000
gen exp4 = (exp1^4)/10000

gen e1edhsd = exp1*edhsd
gen e1edsmc = exp1*edsmc
gen e1edclg = exp1*(edclg|edgtc)

gen e2edhsd = exp2*edhsd
gen e2edsmc = exp2*edsmc
gen e2edclg = exp2*(edclg|edgtc)

gen e3edhsd = exp3*edhsd
gen e3edsmc = exp3*edsmc
gen e3edclg = exp3*(edclg|edgtc)

gen e4edhsd = exp4*edhsd
gen e4edsmc = exp4*edsmc
gen e4edclg = exp4*(edclg|edgtc)

* create education-experience interactions
gen exphsd=exp*edhsd
gen exphsg=exp*edhsg
gen expsmc=exp*edsmc
gen expclg=exp*edclg
gen expgtc=exp*edgtc

gen expsq=exp^2
gen expsqhsd=expsq*edhsd
gen expsqhsg=expsq*edhsg
gen expsqsmc=expsq*edsmc
gen expsqclg=expsq*edclg
gen expsqgtc=expsq*edgtc

/*------------------------------------------------------------------------------
	Worker characteristics
------------------------------------------------------------------------------*/
* variable for those who were going to school last year and worked part-year (_wklyr<=49). Just 1962!!
gen studently=actnlfly==3 & wkswork1<=5 & year==1962
drop actnlfly

/* new variables: "fulltime"=1 if individual worked 35+ hrs/wk last yr, 
"hours0" if worked 0 hours, "NILF", and interactions */
gen fulltime=fullpart==1
label var fulltime "usually worked 35+ hours per week last year"
gen NILF=0
replace NILF=1 if empstat==31 | empstat==32 | empstat==33 | empstat==34 | empstat==35
replace ahrsworkt=0 if NILF==1
gen NILF_fulltime=NILF*fulltime
gen hours0=ahrsworkt==0
gen hours29=ahrsworkt>=15 & ahrsworkt<=29
gen hours34=ahrsworkt>=30 & ahrsworkt<=34
gen hours39=ahrsworkt>=35 & ahrsworkt<=39
gen hours40=ahrsworkt==40
gen hours48=ahrsworkt>=41 & ahrsworkt<=48
gen hours59=ahrsworkt>=49 & ahrsworkt<=59
gen hours60=ahrsworkt>=60
gen hours0_fulltime=hours0*fulltime
gen hours29_fulltime=hours29*fulltime
gen hours34_fulltime=hours34*fulltime
gen hours39_fulltime=hours39*fulltime
gen hours40_fulltime=hours40*fulltime
gen hours48_fulltime=hours48*fulltime
gen hours59_fulltime=hours59*fulltime
gen hours60_fulltime=hours60*fulltime
drop empstat

* part-time and full-time full-year
gen pt=!fulltime // part-time

/*------------------------------------------------------------------------------
	Weights and top coding of hours
------------------------------------------------------------------------------*/
* "wgt" has two unwritten decimal places; exclude negative weights
rename asecwt wgt
replace wgt=wgt/100
keep if wgt>=0 & wgt~=.

* redefine top coding for "ahrsworkt" and "uhrsworkly" to be 98 for all years
replace ahrsworkt=0 if ahrsworkt==100 & year==1962
replace ahrsworkt=98 if ahrsworkt==99 & year==1962
replace ahrsworkt=0 if ahrsworkt==99 & (year>=1964 & year<=1967)
replace ahrsworkt=98 if ahrsworkt==99 & (year>=1968 & year<=1975)

/*------------------------------------------------------------------------------
	Imputations from 1976-1978
------------------------------------------------------------------------------*/

* create variable weeks worked last year ("weeks") using calculations from years 1976-78
append using "$data_out/ASEC_1976_1978_wkslyr.dta"
gen weeks=0
sort female race X13 
by female race: replace weeks=X13[1] if wkswork2==1
sort female race X26 
by female race: replace weeks=X26[1] if wkswork2==2
sort female race X39 
by female race: replace weeks=X39[1] if wkswork2==3
sort female race X47 
by female race: replace weeks=X47[1] if wkswork2==4
sort female race X49 
by female race: replace weeks=X49[1] if wkswork2==5
sort female race X52 
by female race: replace weeks=X52[1] if wkswork2==6
drop X*
drop if year>=1976

* impute usual hours worked per week last year ("hrslyr") from 1976-78 regressions
append using "$data_out/ASEC_1976_1978_uhrsworkly.dta"
gsort female race -year
by female race: gen hrslyr = c_cons[1] + c_hours0[1]*hours0 + c_hours29[1]*hours29 + ///
	c_hours34[1]*hours34 + c_hours39[1]*hours39 + c_hours40[1]*hours40 + ///
	c_hours48[1]*hours48 + c_hours59[1]*hours59 + c_hours60[1]*hours60 + ///
	c_fulltime[1]*fulltime + c_NILF[1]*NILF + c_hours0_fulltime[1]*hours0_fulltime + ///
	c_hours29_fulltime[1]*hours29_fulltime + c_hours34_fulltime[1]*hours34_fulltime + ///
	c_hours39_fulltime[1]*hours39_fulltime + c_hours40_fulltime[1]*hours40_fulltime + ///
	c_hours48_fulltime[1]*hours48_fulltime + c_hours59_fulltime[1]*hours59_fulltime + ///
	c_hours60_fulltime[1]*hours60_fulltime + c_NILF_fulltime[1]*NILF_fulltime
drop if year>=1976
drop hours* NILF* c_*

* define new weights
gen wgt_wks=wgt*weeks
gen wgt_hrs=wgt*weeks*hrslyr
gen wgt_hrs_ft=wgt*hrslyr
lab var wgt_wks "Weight x weeks last yr"
lab var wgt_hrs "Weight x weeks last yr x weekly hours worked"
lab var wgt_hrs_ft "Weight x hours worked per week"
	
/*------------------------------------------------------------------------------
	Worker characteristics
------------------------------------------------------------------------------*/
* create flag if HH main industry last year is private sector
gen phh=(indly==32 & year==1962)
replace phh=1 if indly==33 & inrange(year,1964,1967)
replace phh=1 if indly==816 & inrange(year,1968,1970)
replace phh=1 if indly==769 & inrange(year,1971,1975)

* create wage-worker and self-employed variables
gen wageworker=(classwly==22 | classwly==24)
gen selfemp=(classwly==10)
keep if wageworker==1 | selfemp==1
lab var wageworker "Wage worker"
lab var selfemp "Self-employed"

* create fullyear worker variable (40-52 weeks)
gen fullyear=(wkswork2>=4 & wkswork2<=6)
label var fullyear "Full year workers (40-52 weeks last year)"
gen ftfy=fulltime*fullyear // full-time and full-year

* GDP deflator corresponds to year prior to CPS year, hence subtract 1 from year before merging
replace year=year-1
merge m:1 year using "$data_out/deflator_pce.dta", keepusing(deflator) keep(matched) nogen
replace year=year+1

/* !!  This is very important.  The IPUMS CPS has coding for missing variables and 
those not in the universe (NIU). This is not the case in AKK's source files. */ 
* not in universe
foreach var of varlist incwage inctot incbus incfarm inclongj {
	replace `var'=. if `var'==99999999	
}
* missing
foreach var of varlist incbus incfarm inctot {
	replace `var'=. if `var'==99999998 & year>=1962 & year<=1964
}
replace incwage=. if incwage==99999998 & year>=1962 & year<=1966
replace ahrsworkt=. if ahrsworkt==999

* top codes and restrictions
replace incbus=incbus*1.5 if incbus==90000 & year>=1962 & year<=1964 
replace incfarm=incfarm*1.5 if incfarm==90000 & year>=1962 & year<=1964 
replace incwage=incwage*1.5 if incwage==90000 & year>=1962 & year<=1964 

replace incbus=incbus*1.5 if incbus==99900 & year>=1965 & year<=1967 
replace incfarm=incfarm*1.5 if incfarm==99900 & year>=1965 & year<=1967 
replace incwage=incwage*1.5 if incwage==99900 & year>=1965 & year<=1967 

replace incbus=incbus*1.5 if incbus==50000 & year>=1968 & year<=1981 
replace incfarm=incfarm*1.5 if incfarm==50000 & year>=1968 & year<=1981 
replace incwage=incwage*1.5 if incwage==50000 & year>=1968 & year<=1981 

replace incbus=incbus*1.5 if incbus==75000 & year>=1982 & year<=1984 
replace incfarm=incfarm*1.5 if incfarm==75000 & year>=1982 & year<=1984 
replace incwage=incwage*1.5 if incwage==75000 & year>=1982 & year<=1984 

replace incbus=incbus*1.5 if incbus==99999 & year>=1985 & year<=1987 
replace incfarm=incfarm*1.5 if incfarm==99999 & year>=1985 & year<=1987 
replace incwage=incwage*1.5 if incwage==99999 & year>=1985 & year<=1987 

gen tcwkwg=0 
replace tcwkwg=1 if (incwage/weeks)>(99900*1.5/40) & year>=1962 & year<=1967 
replace tcwkwg=1 if (incwage/weeks)>(50000*1.5/40) & year>=1968 & year<=1981 
replace tcwkwg=1 if (incwage/weeks)>(75000*1.5/40) & year>=1982 & year<=1984 
replace tcwkwg=1 if (incwage/weeks)>(99999*1.5/40) & year>=1985 & year<=1987 

gen tchrwg=0 
replace tchrwg=1 if (incwage/(weeks*hrslyr))>(99900*1.5/1400) & year>=1962 & year<=1967
replace tchrwg=1 if (incwage/(weeks*hrslyr))>(50000*1.5/1400) & year>=1968 & year<=1981
replace tchrwg=1 if (incwage/(weeks*hrslyr))>(75000*1.5/1400) & year>=1982 & year<=1984
replace tchrwg=1 if (incwage/(weeks*hrslyr))>(99999*1.5/1400) & year>=1985 & year<=1987

/* create consistent wage measures:
1) flag those who earn below $1/hr using PCE deflator
2) flag their hourly AND weekly wage since both implictly depend on $1 per hour */

gen winc_ws=incwage/weeks if wageworker==1 & incwage>0 
label var winc_ws "Weekly wage" 

gen hinc_ws=winc_ws/hrslyr if wageworker==1 & incwage>0 
label var hinc_ws "Hourly wage" 

// gen bcwkwg=(winc_ws*deflator)<(40*(100/48.439))
gen bcwkwg=(winc_ws*deflator)<(40*(100/44.771))
label var bcwkwg "wkwage<$40/wk in 1982$, using GDP PCE deflator" 

// gen bchrwg=(winc_ws*deflator/hrslyr)<(1*(100/48.439))
gen bchrwg=(winc_ws*deflator/hrslyr)<(1*(100/44.771))
label var bchrwg "hrwage<$1/hr in 1982$, using GDP PCE deflator" 

// gen bcwkwgkm=(winc_ws*deflator)<(67*(100/48.439))
gen bcwkwgkm=(winc_ws*deflator)<(67*(100/44.771))
label var bcwkwgkm "wkwage<$67/wk in 1982$, using GDP PCE deflator" 

// gen bchrwgkm=(winc_ws*deflator/hrslyr)<(1.675*(100/48.439))
gen bchrwgkm=(winc_ws*deflator/hrslyr)<(1.675*(100/44.771))
label var bchrwgkm "hrwage<$1.675/hr in 1982$, using GDP PCE deflator" 

* windsorize final wages
replace hinc_ws=(99900*1.5/1400) if tchrwg & year>=1962 & year<=1967
replace hinc_ws=(50000*1.5/1400) if tchrwg & year>=1968 & year<=1981 & wageworker==1 & incwage>0 

/*------------------------------------------------------------------------------
	Real wages
------------------------------------------------------------------------------*/
gen rwinc = winc_ws*deflator
label var rwinc "Real earnings (2017$)"

gen lnrwinc=ln(rwinc)
label var lnrwinc "Log of real earnings (2017$)"

gen rhinc = hinc_ws*deflator
label var rhinc "Real hourly wage (2017$)"

gen lnrhinc=ln(hinc_ws)
label var lnrhinc "Log of real hourly wage (2017$)"

/*------------------------------------------------------------------------------
	Labeling variables
------------------------------------------------------------------------------*/
label var statefip "State fip"
label var wgt "ASEC weight"
label var higrade "High school grade completed"
label var inctot "Total personal income"
label var incwage "Income, wage and salary"
label var incbus "Income, non-farm business"
label var incfarm "Income, farm"
label var inclongj "Earnings from longest job"
label var studently "Attended school and worker part-time"
label var agely "Age last year"
label var phh "Household industry is private industry"
label var fulltime "Fulltime worker, 35+ hours"
label var weeks "Weeks worked last year"
label var allocated "Allocated flag"
label var uhrsworkly "Usual weekly hours, last yr"
label variable year "Year income earned" 
rename ahrsworkt hrslwk
label variable hrslwk "Hours last week"
gen weeks_lastyear=weeks
label var weeks_lastyear "Heeks worked last year"
gen hours_lastyear=hrslyr
label var hours_lastyear "Weekly hours worked last year"

* keep necessary variables
keep ed* wgt* agely exp* female year school fulltime fullyear wageworker selfemp deflator* ///
	white black other inc* wkswork2 weeks uhrsworkly hrslwk phh studently higrade ///
	winc_ws hinc_ws tchrwg tcwkwg bchrwg bcwkwg bchrwgkm bcwkwgkm statefip allocated cpsidp ///
	weeks_lastyear hours_lastyear educomp lnr* ftfy rwinc rhinc e1* e2* e3* e4* pt

* saving 
compress
save "$data_out/ASEC_1962_1975_cleaned.dta", replace	

