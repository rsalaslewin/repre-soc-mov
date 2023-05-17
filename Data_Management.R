#DISSERTATION - MSC POLITICAL SCIENCE AND POLITICAL ECONOMY, LSE.

#Clean workspace.

rm(list=ls())

#Fix folder.

setwd(" ")

#Open databases.

muni<-read.csv("MUNI_POB.csv", sep=";", encoding="UTF-8")
turnout_2012<-read.csv("Turnout_2012.csv", sep=";", encoding="UTF-8")
turnout_2013a<-read.csv("Turnout_2013a.csv", sep=";", encoding="UTF-8")
turnout_2013b<-read.csv("Turnout_2013b.csv", sep=";", encoding="UTF-8")
turnout_2016<-read.csv("Turnout_2016.csv", sep=";", encoding="UTF-8")
turnout_2017a<-read.csv("Turnout_2017a.csv", sep=";", encoding="UTF-8")
turnout_2017b<-read.csv("Turnout_2017b.csv", sep=";", encoding="UTF-8")
pob2008<-read.csv("POB_2008.csv", sep=";", encoding="UTF-8")
pob2000_04<-read.csv("POB_2000_2004.csv", sep=";", encoding="UTF-8")
turnout_2008<-read.csv("Turnout_2008.csv", sep=";", encoding="UTF-8")
turnout_2000<-read.csv("Turnout_2000.csv", sep=";", encoding="UTF-8")
turnout_2004<-read.csv("Turnout_2004.csv", sep=";", encoding="UTF-8")
pob2012_16<-read.csv("POB_2012_2016.csv", sep=";", encoding="UTF-8")
turnout_2021<-read.csv("Turnout_2021.csv", sep=";", encoding="UTF-8")
inscritos_2004<-read.csv("Inscritos_2004.csv", sep=";", encoding="UTF-8")
inscritos_2008<-read.csv("Inscritos_2008.csv", sep=";", encoding="UTF-8")

#Merge.

presi <- merge(turnout_2013a, turnout_2013b, by="Comuna")
presi <- merge(presi, turnout_2017a, by="Comuna")
presi <- merge(presi, turnout_2017b, by="Comuna")

ptrend <- merge(turnout_2012, turnout_2016, by="Comuna")
ptrend<-merge(ptrend, presi, by="Comuna")
ptrend <- merge(muni, ptrend, by="Comuna")

ptrend <- merge(ptrend, pob2008, by="COD")
ptrend <- merge(ptrend, pob2000_04, by="COD")
ptrend <- merge(ptrend, pob2012_16, by="COD")
ptrend <- merge(ptrend, turnout_2008, by="Comuna")

t2000_04<- merge(turnout_2004, turnout_2000, by="Comuna", all = T)
ptrend<-merge(t2000_04, ptrend, by="Comuna", all=T)

ptrend$X <- NULL 

ptrend <- merge(ptrend, turnout_2021, by="Comuna", all = T)
ptrend <- merge(ptrend, inscritos_2004, by="Comuna")
ptrend <- merge(ptrend, inscritos_2008, by="Comuna")

#Save data.

library(openxlsx)
write.xlsx(ptrend, "ptrend.xlsx")

#Add total protests.

library(readxl)
prot<-read_xlsx("20200701 BASE ACCIONES 2009-2019 v.02.xlsx")
library(dplyr)
table(prot$P5b)
table(prot$P5c)
prot<-filter(prot, P5c==19)
prot<-filter(prot, P5b==10 | P5b==11 | P5b==12)
summary(prot$P8)
unique(prot$P8)
protcom<-as.data.frame(table(prot$P8))
protcom<-rename(protcom, COD=Var1, n_prot=Freq)
ptrend1 <- merge(ptrend, protcom, by="COD", all=T)
ptrend1$n_prot[is.na(ptrend1$n_prot)]<-0
summary(ptrend1$n_prot)

#Treatment dummy variable.

ptrend1$prot_dum<-NA
ptrend1$prot_dum[ptrend1$n_prot>0]<-1
ptrend1$prot_dum[is.na(ptrend1$prot_dum)]<-0
table(ptrend1$prot_dum)

ptrend1$treat<-NA
ptrend1$treat[ptrend1$prot_dum==1]<-"Treated"
ptrend1$treat[ptrend1$prot_dum==0]<-"Control"

#Pre voluntary vote.
#Number of voters given total registered.

ptrend1$Participacion_2008<-((ptrend1$Votacion_2008*100)/ptrend1$Inscritos_2008)/100
ptrend1$Participacion_2004<-((ptrend1$Votacion_2004*100)/ptrend1$Inscritos_2004)/100

#Participation 2021.
ptrend1$Participacion_2021<-ptrend1$Porcentaje_2021/100

#Eliminate non-cities.

#ptrend1<-filter(ptrend1, POB_2019>=5000)

#Save data.

library(openxlsx)
write.xlsx(ptrend1, "ptrend1.xlsx")

#Save only municipalities and treatment.

basetreat<-ptrend1[c("COD", "Comuna", "n_prot", "prot_dum", "treat")]
write.xlsx(basetreat, "basetreat.xlsx")

#Parallel trends.

#Mean % voters.

medias1<-ptrend1[c("Participacion_2004", "Participacion_2008", "Participacion_2012", "Participacion_2016", 
                   "Participacion_2021", "treat")]

medias1 <- aggregate(medias1[,c("Participacion_2004", "Participacion_2008", "Participacion_2012", "Participacion_2016", 
                                "Participacion_2021")], by=list(medias1$treat), FUN=mean, na.rm=T)

library(data.table)
medias1<-transpose(medias1, keep.names="Year", make.names="Group.1")
medias1$Year[medias1$Year=="Participacion_2004"]<-2004
medias1$Year[medias1$Year=="Participacion_2008"]<-2008
medias1$Year[medias1$Year=="Participacion_2012"]<-2012
medias1$Year[medias1$Year=="Participacion_2016"]<-2016
medias1$Year[medias1$Year=="Participacion_2021"]<-2021


library(tidyr)
medias1 <- pivot_longer(medias1, !Year, names_to = "Group", values_to = "Turnout")

library(ggplot2)
medias1 %>%
  ggplot( aes(x=Year, y=Turnout, group=Group, color=Group)) +
  geom_line() +
  geom_point()+
  labs(y="Turnout",x="Year of Election", 
       colour = "Group",
       title = "Mean Turnout Proportion") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10), limits=c(0,1)) +
  theme_minimal() + theme(legend.position = "bottom", plot.title = element_text(size=12))

#Number of protests per year.

library(readxl)
protestas<-read_xlsx("20200701 BASE ACCIONES 2009-2019 v.02.xlsx")
library(dplyr)
table(protestas$P5c)
totalprot<-as.data.frame(table(protestas$P5c))

totalprot$Freq <- as.numeric(totalprot$Freq)
totalprot$Var1 <- as.factor(totalprot$Var1)

library(dplyr)
totalprot <- mutate(totalprot, Var1 = car::recode(totalprot$Var1, "9=2009; 10=2010; 11=2011;
                                                  12=2012; 13=2013; 14=2014; 15=2015; 16=2016; 17=2017;
                                                  18=2018; 19=2019")) 

eventos<-totalprot %>%
  ggplot(aes(x=Var1, y=Freq, group = 1)) +
  geom_line(color="darkturquoise", size=1) +
  geom_point(color="darkturquoise") +
  labs(y="Number of Protests",x="Year",
       title = "Number of Protests Over Time") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10), limits=c(0, 5000)) +
  theme_minimal() + theme(plot.title = element_text(size=12))
eventos

ggsave("/Users/rsalaslewin/Documents/MSc LSE/Dissertation/DataEventos.png", plot = eventos)

#Electoral results.

#Open data.

alcaldes<-read.csv("elecciones_2004_2016.csv", sep=";", encoding="UTF-8")

#Collapse.

alcaldes<-alcaldes[c("A??o.de.Elecci??n", "Comuna", "Candidato..a.", "Sigla.Partido",
                     "Lista", "Votos.Totales")]

alcaldesagg <- aggregate(Votos.Totales ~ A??o.de.Elecci??n + Comuna + Candidato..a. + Sigla.Partido + Lista, 
                         data = alcaldes, sum)

alcaldesagg$Sigla.Partido[alcaldesagg$Sigla.Partido==" "] <- NA
alcaldesagg$Lista[alcaldesagg$Lista==" "] <- NA
alcaldesagg$Sigla.Partido[alcaldesagg$Sigla.Partido==""] <- NA
alcaldesagg$Lista[alcaldesagg$Lista==""] <- NA

alcaldesagg <- alcaldesagg[order(alcaldesagg$A??o.de.Elecci??n),]
alcaldesagg <- alcaldesagg[order(alcaldesagg$Comuna),]

alcaldesagg$Comuna[alcaldesagg$Comuna=="AISEN"]<-"AYSEN"
alcaldesagg$Comuna[alcaldesagg$Comuna=="LLAY-LLAY"]<-"LLAY LLAY"
alcaldesagg$Comuna[alcaldesagg$Comuna=="O'HIGGINS"]<-"OHIGGINS"
alcaldesagg$Comuna[alcaldesagg$Comuna=="CABO DE HORNOS Y ANTARTICA"]<-"CABO DE HORNOS"
alcaldesagg$Comuna <- gsub("??", "N", alcaldesagg$Comuna)

alcaldes_2021<-read.csv("alcaldes_2021.csv", sep=";", encoding="UTF-8")
alcaldes_2021<-alcaldes_2021[c("A??o.de.Elecci??n", "Comuna", "Candidato..a.", "Sigla.Partido",
                               "Lista", "Votos.Totales")]
alcaldesagg <- rbind(alcaldesagg, alcaldes_2021)
alcaldesagg <- alcaldesagg[order(alcaldesagg$Comuna),]
alcaldesagg<-alcaldesagg[alcaldesagg$Comuna !="ANTARTICA",]
unique(alcaldesagg$Comuna)
table(alcaldesagg$Comuna)

basetreat<-read_xlsx("ptrend1.xlsx")
alcaldesagg <- merge(alcaldesagg, basetreat, by="Comuna")
summary(alcaldesagg$COD)

library(openxlsx)
write.xlsx(alcaldesagg, "alcaldesagg.xlsx")

#Create total right-wing by municipality.

derecha <- filter(alcaldesagg, (A??o.de.Elecci??n==2004 & Lista=="B") | (A??o.de.Elecci??n==2008 & Lista=="E") |
                    (A??o.de.Elecci??n==2012 & Lista=="H") | (A??o.de.Elecci??n==2016 & Lista=="F") |
                    (A??o.de.Elecci??n==2021 & Lista=="XX"))

derecha <- derecha[c("A??o.de.Elecci??n", "Comuna", "Votos.Totales", "Votacion_2004",
                     "Votacion_2008", "Votacion_2012", "Votacion_2016", "Votacion_2021", "treat")]

derecha <- aggregate(Votos.Totales ~ A??o.de.Elecci??n + Comuna + treat + Votacion_2004 +
                       Votacion_2008 + Votacion_2012 + Votacion_2016 + Votacion_2021, data = derecha, sum)

derecha$derecha_prop<-NA
derecha$derecha_prop<-ifelse(derecha$A??o.de.Elecci??n==2004, ((derecha$Votos.Totales*100)/derecha$Votacion_2004)/100, NA)
derecha$derecha_prop<-ifelse(derecha$A??o.de.Elecci??n==2008, ((derecha$Votos.Totales*100)/derecha$Votacion_2008)/100, derecha$derecha_prop)
derecha$derecha_prop<-ifelse(derecha$A??o.de.Elecci??n==2012, ((derecha$Votos.Totales*100)/derecha$Votacion_2012)/100, derecha$derecha_prop)
derecha$derecha_prop<-ifelse(derecha$A??o.de.Elecci??n==2016, ((derecha$Votos.Totales*100)/derecha$Votacion_2016)/100, derecha$derecha_prop)
derecha$derecha_prop<-ifelse(derecha$A??o.de.Elecci??n==2021, ((derecha$Votos.Totales*100)/derecha$Votacion_2021)/100, derecha$derecha_prop)

derechamerge<-pivot_wider(derecha, names_from=A??o.de.Elecci??n, values_from=c(Votos.Totales, derecha_prop))

derecha <- aggregate(derecha[,"derecha_prop"], by=list(derecha$A??o.de.Elecci??n, derecha$treat), FUN=mean, na.rm=T)

derecha %>%
  ggplot(aes(x=Group.1, y=x, group=Group.2, color=Group.2)) +
  geom_line() +
  geom_point()+
  labs(y="Vote Share", x="Year of Election", 
       colour = "Group",
       title = "Mean Vote Share Traditional Right-Wing in Mayoral Elections") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 6), limits=c(0, 0.5)) +
  scale_x_continuous(breaks = c(2004,2008,2012,2016,2021))+
  theme_minimal( ) + theme(legend.position = "bottom", plot.title = element_text(size=12))

#Create total left-wing by municipality.

concerta <- filter(alcaldesagg, (A??o.de.Elecci??n==2004 & Lista=="C") | (A??o.de.Elecci??n==2008 & (Lista=="C" | Lista=="F")) |
                     (A??o.de.Elecci??n==2012 & (Lista=="E" | Lista=="F")) | (A??o.de.Elecci??n==2016 & Lista=="E") |
                     (A??o.de.Elecci??n==2021 & (Lista=="K" | Lista=="XU")))

concerta <- concerta[c("A??o.de.Elecci??n", "Comuna", "Votos.Totales", "Votacion_2004",
                       "Votacion_2008", "Votacion_2012", "Votacion_2016", "Votacion_2021", "treat")]

concerta <- aggregate(Votos.Totales ~ A??o.de.Elecci??n + Comuna + treat + Votacion_2004 +
                        Votacion_2008 + Votacion_2012 + Votacion_2016 + Votacion_2021, data = concerta, sum)

concerta$concerta_prop<-NA
concerta$concerta_prop<-ifelse(concerta$A??o.de.Elecci??n==2004, ((concerta$Votos.Totales*100)/concerta$Votacion_2004)/100, NA)
concerta$concerta_prop<-ifelse(concerta$A??o.de.Elecci??n==2008, ((concerta$Votos.Totales*100)/concerta$Votacion_2008)/100, concerta$concerta_prop)
concerta$concerta_prop<-ifelse(concerta$A??o.de.Elecci??n==2012, ((concerta$Votos.Totales*100)/concerta$Votacion_2012)/100, concerta$concerta_prop)
concerta$concerta_prop<-ifelse(concerta$A??o.de.Elecci??n==2016, ((concerta$Votos.Totales*100)/concerta$Votacion_2016)/100, concerta$concerta_prop)
concerta$concerta_prop<-ifelse(concerta$A??o.de.Elecci??n==2021, ((concerta$Votos.Totales*100)/concerta$Votacion_2021)/100, concerta$concerta_prop)

concertamerge<-pivot_wider(concerta, names_from=A??o.de.Elecci??n, values_from=c(Votos.Totales, concerta_prop))

concerta <- aggregate(concerta[,"concerta_prop"], by=list(concerta$A??o.de.Elecci??n, concerta$treat), FUN=mean, na.rm=T)

concerta %>%
  ggplot(aes(x=Group.1, y=x, group=Group.2, color=Group.2)) +
  geom_line() +
  geom_point() +
  labs(y="Vote Share", x="Year of Election", 
       colour = "Group",
       title = "Mean Vote Share Traditional Centre-Left in Mayoral Elections") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 5), limits=c(0, 0.5)) +
  scale_x_continuous(breaks = c(2004,2008,2012,2016,2021))+
  theme_minimal( ) + theme(legend.position = "bottom", plot.title = element_text(size=12))

#Create total independents by municipality.

independientes <- filter(alcaldesagg, (A??o.de.Elecci??n==2004 & Lista=="CI") | (A??o.de.Elecci??n==2008 & Lista=="CI") |
                     (A??o.de.Elecci??n==2012 & (is.na(Lista) & Candidato..a.!="VOTOS EN BLANCO" & Candidato..a.!="VOTOS NULOS")) | 
                       (A??o.de.Elecci??n==2016 & Lista=="T") | (A??o.de.Elecci??n==2021 & Lista=="IND"))

independientes <- independientes[c("A??o.de.Elecci??n", "Comuna", "Votos.Totales", "Votacion_2004",
                       "Votacion_2008", "Votacion_2012", "Votacion_2016", "Votacion_2021", "treat")]

independientes <- aggregate(Votos.Totales ~ A??o.de.Elecci??n + Comuna + treat + Votacion_2004 +
                        Votacion_2008 + Votacion_2012 + Votacion_2016 + Votacion_2021, data = independientes, sum)

independientes$indep_prop<-NA
independientes$indep_prop<-ifelse(independientes$A??o.de.Elecci??n==2004, ((independientes$Votos.Totales*100)/independientes$Votacion_2004)/100, NA)
independientes$indep_prop<-ifelse(independientes$A??o.de.Elecci??n==2008, ((independientes$Votos.Totales*100)/independientes$Votacion_2008)/100, independientes$indep_prop)
independientes$indep_prop<-ifelse(independientes$A??o.de.Elecci??n==2012, ((independientes$Votos.Totales*100)/independientes$Votacion_2012)/100, independientes$indep_prop)
independientes$indep_prop<-ifelse(independientes$A??o.de.Elecci??n==2016, ((independientes$Votos.Totales*100)/independientes$Votacion_2016)/100, independientes$indep_prop)
independientes$indep_prop<-ifelse(independientes$A??o.de.Elecci??n==2021, ((independientes$Votos.Totales*100)/independientes$Votacion_2021)/100, independientes$indep_prop)

indepmerge<-pivot_wider(independientes, names_from=A??o.de.Elecci??n, values_from=c(Votos.Totales, indep_prop))

independientes <- aggregate(independientes[,"indep_prop"], by=list(independientes$A??o.de.Elecci??n, independientes$treat), FUN=mean, na.rm=T)

independientes %>%
  ggplot(aes(x=Group.1, y=x, group=Group.2, color=Group.2)) +
  geom_line() +
  geom_point() +
  labs(y="Vote Share", x="Year of Election", 
       colour = "Group",
       title = "Mean Vote Share Independent Candidates in Mayoral Elections") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 5), limits=c(0, 0.5)) +
  scale_x_continuous(breaks = c(2004,2008,2012,2016,2021))+
  theme_minimal( ) + theme(legend.position = "bottom", plot.title = element_text(size=12))

#Create total alternative by municipality.

otros <- filter(alcaldesagg, (A??o.de.Elecci??n==2004 & (Lista=="A" | Lista=="D" | Lista=="E")) | 
                  (A??o.de.Elecci??n==2008 & (Lista=="A" | Lista=="B" | Lista=="D")) | 
                  (A??o.de.Elecci??n==2012 & (Lista=="A" | Lista=="B" | Lista=="C" | Lista=="D" | Lista=="G" | Lista=="I")) | 
                  (A??o.de.Elecci??n==2016 & (Lista=="A" | Lista=="C" | Lista=="D" | Lista=="I" | Lista=="K" | Lista=="M"| Lista=="N" | Lista=="O" | Lista=="P"| Lista=="Q" | Lista=="R")) | 
                  (A??o.de.Elecci??n==2021 & (Lista=="M" | Lista=="XE" | Lista=="XO" | Lista=="XS" | Lista=="XY" | Lista=="XZ"| Lista=="YC" | Lista=="YG" | Lista=="ZB")))

otros <- otros[c("A??o.de.Elecci??n", "Comuna", "Votos.Totales", "Votacion_2004",
                                   "Votacion_2008", "Votacion_2012", "Votacion_2016", "Votacion_2021", "treat")]

otros <- aggregate(Votos.Totales ~ A??o.de.Elecci??n + Comuna + treat + Votacion_2004 +
                              Votacion_2008 + Votacion_2012 + Votacion_2016 + Votacion_2021, data = otros, sum)

otros$otros_prop<-NA
otros$otros_prop<-ifelse(otros$A??o.de.Elecci??n==2004, ((otros$Votos.Totales*100)/otros$Votacion_2004)/100, NA)
otros$otros_prop<-ifelse(otros$A??o.de.Elecci??n==2008, ((otros$Votos.Totales*100)/otros$Votacion_2008)/100, otros$otros_prop)
otros$otros_prop<-ifelse(otros$A??o.de.Elecci??n==2012, ((otros$Votos.Totales*100)/otros$Votacion_2012)/100, otros$otros_prop)
otros$otros_prop<-ifelse(otros$A??o.de.Elecci??n==2016, ((otros$Votos.Totales*100)/otros$Votacion_2016)/100, otros$otros_prop)
otros$otros_prop<-ifelse(otros$A??o.de.Elecci??n==2021, ((otros$Votos.Totales*100)/otros$Votacion_2021)/100, otros$otros_prop)

otrosmerge<-pivot_wider(otros, names_from=A??o.de.Elecci??n, values_from=c(Votos.Totales, otros_prop))

otros <- aggregate(otros[,"otros_prop"], by=list(otros$A??o.de.Elecci??n, otros$treat), FUN=mean, na.rm=T)

otros %>%
  ggplot(aes(x=Group.1, y=x, group=Group.2, color=Group.2)) +
  geom_line() +
  geom_point() +
  labs(y="Vote Share", x="Year of Election", 
       colour = "Group",
       title = "Mean Vote Share Alternative Coalitions in Mayoral Elections") +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 5), limits=c(0, 0.5)) +
  scale_x_continuous(breaks = c(2004,2008,2012,2016,2021))+
  theme_minimal( ) + theme(legend.position = "bottom", plot.title = element_text(size=12))

#STATA DATA.

derechamerge<-derechamerge[c("Comuna", "Votos.Totales_2004", "Votos.Totales_2008", "Votos.Totales_2012",
                             "Votos.Totales_2016", "Votos.Totales_2021", "derecha_prop_2004", "derecha_prop_2008", 
                             "derecha_prop_2012", "derecha_prop_2016", "derecha_prop_2021")]

derechamerge<-rename(derechamerge, derechatotal_2004=Votos.Totales_2004, derechatotal_2008=Votos.Totales_2008, 
                     derechatotal_2012=Votos.Totales_2012, derechatotal_2016=Votos.Totales_2016, 
                     derechatotal_2021=Votos.Totales_2021)

derechamerge[is.na(derechamerge)] <- 0

concertamerge<-concertamerge[c("Comuna", "Votos.Totales_2004", "Votos.Totales_2008", "Votos.Totales_2012",
                               "Votos.Totales_2016", "Votos.Totales_2021", "concerta_prop_2004", "concerta_prop_2008", 
                               "concerta_prop_2012", "concerta_prop_2016", "concerta_prop_2021")]

concertamerge<-rename(concertamerge, concertatotal_2004=Votos.Totales_2004, concertatotal_2008=Votos.Totales_2008, 
                      concertatotal_2012=Votos.Totales_2012, concertatotal_2016=Votos.Totales_2016, 
                      concertatotal_2021=Votos.Totales_2021)

concertamerge[is.na(concertamerge)] <- 0

results_elections <- merge(concertamerge, derechamerge, by="Comuna", all = T)

indepmerge<-indepmerge[c("Comuna", "Votos.Totales_2004", "Votos.Totales_2008", "Votos.Totales_2012",
                               "Votos.Totales_2016", "Votos.Totales_2021", "indep_prop_2004", "indep_prop_2008", 
                               "indep_prop_2012", "indep_prop_2016", "indep_prop_2021")]

indepmerge<-rename(indepmerge, indeptotal_2004=Votos.Totales_2004, indeptotal_2008=Votos.Totales_2008, 
                   indeptotal_2012=Votos.Totales_2012, indeptotal_2016=Votos.Totales_2016, 
                   indeptotal_2021=Votos.Totales_2021)

indepmerge[is.na(indepmerge)] <- 0

results_elections <- merge(results_elections, indepmerge, by="Comuna", all = T)

otrosmerge<-otrosmerge[c("Comuna", "Votos.Totales_2004", "Votos.Totales_2008", "Votos.Totales_2012",
                         "Votos.Totales_2016", "Votos.Totales_2021", "otros_prop_2004", "otros_prop_2008", 
                         "otros_prop_2012", "otros_prop_2016", "otros_prop_2021")]

otrosmerge<-rename(otrosmerge, otrostotal_2004=Votos.Totales_2004, otrostotal_2008=Votos.Totales_2008, 
                   otrostotal_2012=Votos.Totales_2012, otrostotal_2016=Votos.Totales_2016, 
                   otrostotal_2021=Votos.Totales_2021)

otrosmerge[is.na(otrosmerge)] <- 0

results_elections <- merge(results_elections, otrosmerge, by="Comuna", all = T)

results_elections[is.na(results_elections)] <- 0

base_turnout<-basetreat[c("COD", "Comuna", "Votacion_2004", "Votacion_2008", "Votacion_2012", 
                          "Votacion_2016", "Votacion_2021", "Participacion_2004", "Participacion_2008", 
                          "Participacion_2012", "Participacion_2016", "Participacion_2021", 
                          "Inscritos_2004", "Inscritos_2008", "Inscritos_Total_2012", 
                          "Inscritos_Total_2016", "Inscritos_Total_2021", "n_prot", "prot_dum", 
                          "treat")]

diss_data<- merge(base_turnout, results_elections, by="Comuna")
write.csv(diss_data, file="diss_data.csv", row.names = F)




