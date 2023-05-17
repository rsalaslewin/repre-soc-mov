
//MSC POLITICAL SCIENCE AND POLITICAL ECONOMY - CANDIDATE 14071
//DISSERTATION.

cls
clear all

//Fix folder and open database.
cd " "

import delimited "diss_data.csv", delimiter(",") clear
browse

////PERCENTAGES AND MERGE COVARIATES////

foreach v of varlist participacion_* derecha_prop_* concerta_prop_* indep_prop_* otros_prop_* {
    gen per_`v' = `v'*100
}

merge 1:1 cod using "SINIM_CARACTERIZACION.dta"
drop _merge
merge 1:1 cod using "SINIM_DESARROLLO.dta"
drop _merge
merge 1:1 cod using "SINIM_SOCIAL_COMUNITARIA.dta"
drop _merge
merge 1:1 cod using "SINIM_EDUC_SALUD.dta"
drop _merge
merge 1:1 cod using "SINIM_ADMIN.dta"
drop _merge

////RECODING////.

gen turnout_dif=per_participacion_2021-per_participacion_2016
gen concerta_dif=per_concerta_prop_2021-per_concerta_prop_2016
gen derecha_dif=per_derecha_prop_2021-per_derecha_prop_2016
gen indep_dif=per_indep_prop_2021-per_indep_prop_2016
gen otros_dif=per_otros_prop_2021-per_otros_prop_2016

//For placebos.
gen turnout_dif2=per_participacion_2016-per_participacion_2012
gen concerta_dif2=per_concerta_prop_2016-per_concerta_prop_2012
gen derecha_dif2=per_derecha_prop_2016-per_derecha_prop_2012
gen indep_dif2=per_indep_prop_2016-per_indep_prop_2012
gen otros_dif2=per_otros_prop_2016-per_otros_prop_2012

recode region (.=16)

foreach v of varlist pob_20* {
    gen l_`v' = log(`v')
}

gen per_urbana_2019 = (pob_urbana_2019*100)/pob_2019
gen per_mas18_2016 = (mas18_2016*100)/pob_2016
gen per_mas18_2019 = (mas18_2019*100)/pob_2019

gen percap_org_comunitarias_2016 = org_comunitarias_2016/pob_2016
gen percap_org_comunitarias_2019 = org_comunitarias_2019/pob_2019
gen percap_gasto_2016 = gasto_2016/pob_2016
gen percap_gasto_2019 = gasto_2019/pob_2019

save "diss_data_recode", replace

////EXPLORE////.

sum region provincia
tab region provincia
tab prot_dum
sum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg
sum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019
sum percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019
sum per_participacion_* per_concerta_prop_* per_derecha_prop_* per_indep_prop_* per_otros_prop_*
sum prot_dum n_prot

codebook region provincia
codebook l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg
codebook ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019
codebook percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019
codebook per_participacion_* per_concerta_prop_* per_derecha_prop_* per_indep_prop_* per_otros_prop_*
codebook prot_dum n_prot

////DESCRIPTIVES////.

tabstat per_participacion_2021 per_concerta_prop_2021 per_derecha_prop_2021 per_indep_prop_2021 per_otros_prop_2021, statistics(mean, median, sd, min, max, n) by(treat)
tabstat per_participacion_2016 per_concerta_prop_2016 per_derecha_prop_2016 per_indep_prop_2016 per_otros_prop_2016, statistics(mean, median, sd, min, max, n) by(treat)
tabstat per_participacion_2012 per_concerta_prop_2012 per_derecha_prop_2012 per_indep_prop_2012 per_otros_prop_2012, statistics(mean, median, sd, min, max, n) by(treat)
tabstat per_participacion_2008 per_concerta_prop_2008 per_derecha_prop_2008 per_indep_prop_2008 per_otros_prop_2008, statistics(mean, median, sd, min, max, n) by(treat)
tabstat per_participacion_2004 per_concerta_prop_2004 per_derecha_prop_2004 per_indep_prop_2004 per_otros_prop_2004, statistics(mean, median, sd, min, max, n) by(treat)
tabstat turnout_dif concerta_dif derecha_dif indep_dif otros_dif, statistics(mean, median, sd, min, max, n) by(treat)

tabstat region provincia
tabstat l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, statistics(mean, median, sd, min, max, n) by(treat)
tabstat ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, statistics(mean, median, sd, min, max, n) by(treat)
tabstat percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, statistics(mean, median, sd, min, max, n) by(treat)

tabstat n_prot, statistics(mean, median, sd, min, max, n) by(region)
tabstat n_prot, statistics(mean, median, sd, min, max, n) by(provincia)
tabstat n_prot, statistics(mean, median, sd, min, max, n) by(treat)
tab treat

////PARALLEL TRENDS WITHOUT OUTCOME////.

use "diss_data_recode", clear

collapse (mean) per_participacion_* per_derecha_prop_* per_concerta_prop_* per_indep_prop_* per_otros_prop_*, by(prot_dum)
drop per_participacion_2021 per_derecha_prop_2021 per_concerta_prop_2021 per_indep_prop_2021 per_otros_prop_2021
reshape long per_participacion_ per_derecha_prop_ per_concerta_prop_ per_indep_prop_ per_otros_prop_, i(prot_dum) j(year) 

//Turnout.
separate per_participacion_, by(prot_dum)
twoway line per_participacion_? year, sort title("Turnout", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Turnout (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) lcolor(midgreen purple)
graph export turnout_ptrend.png, as(png) replace

//Right-wing coalition vote share. 
separate per_derecha_prop_, by(prot_dum)
twoway line per_derecha_prop_? year, sort title("Traditional Centre-Right Coalition (ex-Alianza/Chile Vamos)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) lcolor(midgreen purple)
graph export derecha_ptrend.png, as(png) replace

//Left-wing coalition vote share.
separate per_concerta_prop_, by(prot_dum)
twoway line per_concerta_prop_? year, sort title("Traditional Centre-Left Coalition (ex-Concertación/Nueva Mayoría)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) lcolor(midgreen purple)
graph export concerta_ptrend.png, as(png) replace

//Independent candidates vote share.
separate per_indep_prop_, by(prot_dum)
twoway line per_indep_prop_? year, sort title("Independent Candidates (Out of List)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) lcolor(midgreen purple)
graph export indep_ptrend.png, as(png) replace

//Other lists vote share.
separate per_otros_prop_, by(prot_dum)
twoway line per_otros_prop_? year, sort title("Alternative Coalitions", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) lcolor(midgreen purple)
graph export otros_ptrend.png, as(png) replace

////PARALLEL TRENDS WITH 2021 (OUTCOME)////.

use "diss_data_recode", clear

collapse (mean) per_participacion_* per_derecha_prop_* per_concerta_prop_* per_indep_prop_* per_otros_prop_*, by(prot_dum)
reshape long per_participacion_ per_derecha_prop_ per_concerta_prop_ per_indep_prop_ per_otros_prop_, i(prot_dum) j(year) 

//Turnout.
separate per_participacion_, by(prot_dum)
twoway line per_participacion_? year, sort title("Turnout", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Turnout (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016 2021, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) xline(2019, lcolor(black) lstyle(unextended) lpattern(dash) lwidth(medium)) lcolor(midgreen purple)
graph export outcome_turnout.png, as(png) replace

//Right-wing coalition vote share. 
separate per_derecha_prop_, by(prot_dum)
twoway line per_derecha_prop_? year, sort title("Traditional Centre-Right Coalition (ex-Alianza/Chile Vamos)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016 2021, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) xline(2019, lcolor(black) lstyle(unextended) lpattern(dash) lwidth(medium)) lcolor(midgreen purple)
graph export outcome_derecha.png, as(png) replace

//Left-wing coalition vote share.
separate per_concerta_prop_, by(prot_dum)
twoway line per_concerta_prop_? year, sort title("Traditional Centre-Left Coalition (ex-Concertación/Nueva Mayoría)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016 2021, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) xline(2019, lcolor(black) lstyle(unextended) lpattern(dash) lwidth(medium)) lcolor(midgreen purple)
graph export outcome_concerta.png, as(png) replace

//Independent candidates vote share.
separate per_indep_prop_, by(prot_dum)
twoway line per_indep_prop_? year, sort title("Independent Candidates (Out of List)", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016 2021, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) xline(2019, lcolor(black) lstyle(unextended) lpattern(dash) lwidth(medium)) lcolor(midgreen purple)
graph export outcome_indep.png, as(png) replace

//Other lists vote share.
separate per_otros_prop_, by(prot_dum)
twoway line per_otros_prop_? year, sort title("Alternative Coalitions", size(medium) color(black)) lwidth(medthick medthick) legend(lab(1 "Did not protest") lab(2 "Protested") size(small) region(lcolor(white))) ytitle("Mean Vote Share (%)", size(small)) xtitle("Year", size(small)) graphregion(color(white)) xlabel(2004 2008 2012 2016 2021, angle(45) labsize(small)) ylabel(0(10)100,labsize(small)) xline(2019, lcolor(black) lstyle(unextended) lpattern(dash) lwidth(medium)) lcolor(midgreen purple)
graph export outcome_otros.png, as(png) replace

////REGRESSIONS WITHOUT FIXED EFFECTS////

use "diss_data_recode", clear

//TURNOUT.

reg turnout_dif prot_dum, robust
outreg2 using "REG_TURNOUT.xls", replace excel dec(2)
//Characterization.
reg turnout_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "REG_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "REG_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "REG_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "REG_TURNOUT.xls", append excel dec(2)

//Placebos.
reg turnout_dif2 prot_dum, robust
outreg2 using "PLACEBO_TURNOUT.xls", replace excel dec(2)
//Characterization.
reg turnout_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif2 prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "PLACEBO_TURNOUT.xls", append excel dec(2)

//RIGHT.

reg derecha_dif prot_dum, robust
outreg2 using "REG_DERECHA.xls", replace excel dec(2)
//Characterization.
reg derecha_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "REG_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "REG_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "REG_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "REG_DERECHA.xls", append excel dec(2)

//Placebos.
reg derecha_dif2 prot_dum, robust
outreg2 using "PLACEBO_DERECHA.xls", replace excel dec(2)
//Characterization.
reg derecha_dif2 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif2 prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "PLACEBO_DERECHA.xls", append excel dec(2)

//LEFT.

reg concerta_dif prot_dum, robust
outreg2 using "REG_CONCERTA.xls", replace excel dec(2)
//Characterization.
reg concerta_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "REG_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "REG_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "REG_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif prot_dum  ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "REG_CONCERTA.xls", append excel dec(2)

//Placebos.
reg concerta_dif2 prot_dum, robust
outreg2 using "PLACEBO_CONCERTA.xls", replace excel dec(2)
//Characterization.
reg concerta_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif2 prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "PLACEBO_CONCERTA.xls", append excel dec(2)

//OTHERS.

reg otros_dif prot_dum, robust
outreg2 using "REG_OTROS.xls", replace excel dec(2)
//Characterization.
reg otros_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "REG_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "REG_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "REG_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "REG_OTROS.xls", append excel dec(2)

//Placebos.
reg otros_dif2 prot_dum, robust
outreg2 using "PLACEBO_OTROS.xls", replace excel dec(2)
//Characterization.
reg otros_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif2 prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "PLACEBO_OTROS.xls", append excel dec(2)

//INDEPENDENTS.

reg indep_dif prot_dum, robust
outreg2 using "REG_INDEPENDIENTES.xls", replace excel dec(2)
//Characterization.
reg indep_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "REG_INDEPENDIENTES.xls", append excel dec(2)

//Placebos.
reg indep_dif2 prot_dum, robust
outreg2 using "PLACEBO_INDEPENDIENTES.xls", replace excel dec(2)
//Characterization.
reg indep_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019, robust
//outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg, robust
outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif2 prot_dum percap_gasto_2019 presup_precap_2019, robust
//outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019, robust
outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019, robust
outreg2 using "PLACEBO_INDEPENDIENTES.xls", append excel dec(2)

////REGRESSIONS WITH REGION FIXED EFFECTS////

use "diss_data_recode", clear

//TURNOUT.

reg turnout_dif prot_dum, robust
outreg2 using "FE_REG_TURNOUT.xls", replace excel dec(2)
//FE.
reg turnout_dif prot_dum i.region, robust
outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//Characterization.
reg turnout_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019  i.region, robust
outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019  i.region, robust
outreg2 using "FE_REG_TURNOUT.xls", append excel dec(2)

//Placebos.
reg turnout_dif2 prot_dum, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", replace excel dec(2)
//FE.
reg turnout_dif2 prot_dum i.region, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Characterization.
reg turnout_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif2 prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_PLACEBO_TURNOUT.xls", append excel dec(2)

//RIGHT.

reg derecha_dif prot_dum, robust
outreg2 using "FE_REG_DERECHA.xls", replace excel dec(2)
//FE.
reg derecha_dif prot_dum i.region, robust
outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//Characterization.
reg derecha_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_REG_DERECHA.xls", append excel dec(2)

//Placebos.
reg derecha_dif2 prot_dum, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", replace excel dec(2)
//FE.
reg derecha_dif2 prot_dum i.region, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Characterization.
reg derecha_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif2 prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_PLACEBO_DERECHA.xls", append excel dec(2)

//LEFT.

reg concerta_dif prot_dum, robust
outreg2 using "FE_REG_CONCERTA.xls", replace excel dec(2)
//FE.
reg concerta_dif prot_dum i.region, robust
outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//Characterization.
reg concerta_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif prot_dum  ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)

//Placebos.
reg concerta_dif2 prot_dum, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", replace excel dec(2)
//FE.
reg concerta_dif2 prot_dum i.region, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Characterization.
reg concerta_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif2 prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_PLACEBO_CONCERTA.xls", append excel dec(2)

//OTHERS.

reg otros_dif prot_dum, robust
outreg2 using "FE_REG_OTROS.xls", replace excel dec(2)
//FE.
reg otros_dif prot_dum i.region, robust
outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//Characterization.
reg otros_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_REG_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_REG_OTROS.xls", append excel dec(2)

//Placebos.
reg otros_dif2 prot_dum, robust
outreg2 using "FE_PLACEBO_OTROS.xls", replace excel dec(2)
//FE.
reg otros_dif2 prot_dum i.region, robust
outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//Characterization.
reg otros_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif2 prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_PLACEBO_OTROS.xls", append excel dec(2)

//INDEPENDENTS.

reg indep_dif prot_dum, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", replace excel dec(2)
//FE.
reg indep_dif prot_dum i.region, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Characterization.
reg indep_dif prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_REG_INDEPENDIENTES.xls", append excel dec(2)

//Placebos.
reg indep_dif2 prot_dum, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", replace excel dec(2)
//FE.
reg indep_dif2 prot_dum i.region, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Characterization.
reg indep_dif2 prot_dum l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif2 prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif2 prot_dum ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)

////PRE-TRENDS MATCHING////.

use "diss_data_recode", clear
teffects psmatch (turnout_dif) (prot_dum participacion_2004 participacion_2008 participacion_2012 participacion_2016), nneighbor(1) control(0) generate(match) vce(robust)
outreg2 using "MATCHING_PRETRENDS.xls", replace excel dec(2)
teffects psmatch (derecha_dif) (prot_dum derecha_prop_2004 derecha_prop_2008 derecha_prop_2012 derecha_prop_2016), nneighbor(1) control(0) generate(match2) vce(robust)
outreg2 using "MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (concerta_dif) (prot_dum concerta_prop_2004 concerta_prop_2008 concerta_prop_2012 concerta_prop_2016), nneighbor(1) control(0) generate(match3) vce(robust)
outreg2 using "MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (otros_dif) (prot_dum otros_prop_2004 otros_prop_2008 otros_prop_2012 otros_prop_2016), nneighbor(1) control(0) generate(match4) vce(robust)
outreg2 using "MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (indep_dif) (prot_dum indep_prop_2004 indep_prop_2008 indep_prop_2012 indep_prop_2016), nneighbor(1) control(0) generate(match5) vce(robust)
outreg2 using "MATCHING_PRETRENDS.xls", append excel dec(2)

//Placebos.
teffects psmatch (turnout_dif2) (prot_dum participacion_2004 participacion_2008 participacion_2012), nneighbor(1) control(0) generate(match6) vce(robust)
outreg2 using "PLACEBO_MATCHING_PRETRENDS.xls", replace excel dec(2)
teffects psmatch (derecha_dif2) (prot_dum derecha_prop_2004 derecha_prop_2008 derecha_prop_2012), nneighbor(1) control(0) generate(match7) vce(robust)
outreg2 using "PLACEBO_MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (concerta_dif2) (prot_dum concerta_prop_2004 concerta_prop_2008 concerta_prop_2012), nneighbor(1) control(0) generate(match8) vce(robust)
outreg2 using "PLACEBO_MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (otros_dif2) (prot_dum otros_prop_2004 otros_prop_2008 otros_prop_2012), nneighbor(1) control(0) generate(match9) vce(robust)
outreg2 using "PLACEBO_MATCHING_PRETRENDS.xls", append excel dec(2)
teffects psmatch (indep_dif2) (prot_dum indep_prop_2004 indep_prop_2008 indep_prop_2012), nneighbor(1) control(0) generate(match10) vce(robust)
outreg2 using "PLACEBO_MATCHING_PRETRENDS.xls", append excel dec(2)

///INTENSITY OF PROTEST WITH F.E.///

use "diss_data_recode", clear

//TURNOUT.

reg turnout_dif n_prot, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", replace excel dec(2)
//FE.
reg turnout_dif n_prot i.region, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//Characterization.
reg turnout_dif n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019  i.region, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019  i.region, robust
outreg2 using "INT_FE_REG_TURNOUT.xls", append excel dec(2)

//Placebos.
reg turnout_dif2 n_prot, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", replace excel dec(2)
//FE.
reg turnout_dif2 n_prot i.region, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Characterization.
reg turnout_dif2 n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Social.
//reg turnout_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Characterization and social.
reg turnout_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//Municipal economy.
//reg turnout_dif2 n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//All above.
reg turnout_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)
//All above + organizations.
reg turnout_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_TURNOUT.xls", append excel dec(2)

//RIGHT.

reg derecha_dif n_prot, robust
outreg2 using "INT_FE_REG_DERECHA.xls", replace excel dec(2)
//FE.
reg derecha_dif n_prot i.region, robust
outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//Characterization.
reg derecha_dif n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_REG_DERECHA.xls", append excel dec(2)

//Placebos.
reg derecha_dif2 n_prot, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", replace excel dec(2)
//FE.
reg derecha_dif2 n_prot i.region, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Characterization.
reg derecha_dif2 n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Social.
//reg derecha_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Characterization and social.
reg derecha_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//Municipal economy.
//reg derecha_dif2 n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//All above.
reg derecha_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)
//All above + organizations.
reg derecha_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_DERECHA.xls", append excel dec(2)

//LEFT.

reg concerta_dif n_prot, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", replace excel dec(2)
//FE.
reg concerta_dif n_prot i.region, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)
//Characterization.
reg concerta_dif n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "FE_REG_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif n_prot  ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_REG_CONCERTA.xls", append excel dec(2)

//Placebos.
reg concerta_dif2 n_prot, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", replace excel dec(2)
//FE.
reg concerta_dif2 n_prot i.region, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Characterization.
reg concerta_dif2 n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Social.
//reg concerta_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Characterization and social.
reg concerta_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//Municipal economy.
//reg concerta_dif2 n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//All above.
reg concerta_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)
//All above + organizations.
reg concerta_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_CONCERTA.xls", append excel dec(2)

//OTHERS.

reg otros_dif n_prot, robust
outreg2 using "INT_FE_REG_OTROS.xls", replace excel dec(2)
//FE.
reg otros_dif n_prot i.region, robust
outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//Characterization.
reg otros_dif n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_REG_OTROS.xls", append excel dec(2)

//Placebos.
reg otros_dif2 n_prot, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", replace excel dec(2)
//FE.
reg otros_dif2 n_prot i.region, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//Characterization.
reg otros_dif2 n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//Social.
//reg otros_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//Characterization and social.
reg otros_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//Municipal economy.
//reg otros_dif2 n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//All above.
reg otros_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)
//All above + organizations.
reg otros_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_OTROS.xls", append excel dec(2)

//INDEPENDENTS.

reg indep_dif n_prot, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", replace excel dec(2)
//FE.
reg indep_dif n_prot i.region, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Characterization.
reg indep_dif n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif prot_dum percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_REG_INDEPENDIENTES.xls", append excel dec(2)

//Placebos.
reg indep_dif2 n_prot, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", replace excel dec(2)
//FE.
reg indep_dif2 n_prot i.region, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Characterization.
reg indep_dif2 n_prot l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Social.
//reg indep_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 i.region, robust
//outreg2 using "FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Characterization and social.
reg indep_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg i.region, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//Municipal economy.
//reg indep_dif2 n_prot percap_gasto_2019 presup_precap_2019 i.region, robust
//outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above.
reg indep_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)
//All above + organizations.
reg indep_dif2 n_prot ind_pobreza_casen_2019 cobertura_agua_2019 cob_educ_2019 cob_saludprimmuni_2019 l_pob_2019 per_urbana_2019 feminina_per_2019 per_mas18_2019 densidad_pobkm2_2019 km_capreg percap_gasto_2019 presup_precap_2019 percap_org_comunitarias_2019 i.region, robust
outreg2 using "INT_FE_PLACEBO_INDEPENDIENTES.xls", append excel dec(2)


////MAP PROTESTS PROVINCE////.
use "diss_data_recode", clear
collapse (mean) n_prot, by(provincia)
save "formap", replace
shp2dta using Provincias, database(chidb) coordinates(chicoord) replace
use chidb, clear
describe
rename cod_prov provincia
merge 1:1 provincia using "formap.dta"
drop if _merge!=3
tab n_prot
spmap n_prot using "chicoord.dta" if provincia != 52, id(_ID) fcolor(BuGn) clmethod(custom) clbreaks(0 1 5 10 110) legend(size(vlarge vlarge vlarge vlarge vlarge))
graph export map_provincia.png, as(png) height(5000) replace

