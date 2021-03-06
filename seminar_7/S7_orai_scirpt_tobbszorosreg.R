	
# # Tobbszoros regresszio	
# 	
# ## Abstract	
# 	
# Ennek a gyakorlatnak az a celja hogy az egyszeru regressziorol szerzett tudast altalanositsuk olyan esetekre, ahol tobb prediktor (bejoslo valtozo) is szerepel a modellben.	
# 	
# Ennek a dokumentumnak a legfrissebb valtozatat megtalalod itt:	
# https://osf.io/e23by/	
# 	
# 	
# ## Package-ek betoltese	
# 	
# A kovetkezo package-ek betoltesere lesz szukseg:	
# 	
# 	
library(car)# for scatter3d	
library(psych) # for describe	
library(lm.beta) # for lm.beta	
library(tidyverse) # for tidy format	
library(gridExtra) # for grid.arrange	
# 	
# 	
# ### Sajat script betoltese	
# 	
# Ez a sajat funkcio arra valo hogy a regresszios modell eredmenyeit tablazatban megjelenitsuk. A funkcio tartalmat nem szukseges megerteni.	
# 	
# 	
coef_table = function(model){	
  require(lm.beta)	
  mod_sum = summary(model)	
  mod_sum_p_values = as.character(round(mod_sum$coefficients[,4], 3))		
  mod_sum_p_values[mod_sum_p_values != "0" & mod_sum_p_values != "1"] = substr(mod_sum_p_values[mod_sum_p_values != "0" & mod_sum_p_values != "1"], 2, nchar(mod_sum_p_values[mod_sum_p_values != "0" & mod_sum_p_values != "1"]))		
  mod_sum_p_values[mod_sum_p_values == "0"] = "<.001"		
  	
  	
  mod_sum_table = cbind(as.data.frame(round(cbind(coef(model), confint(model), c(0, lm.beta(model)$standardized.coefficients[c(2:length(model$coefficients))])), 2)), mod_sum_p_values)		
  names(mod_sum_table) = c("b", "95%CI lb", "95%CI ub", "Std.Beta", "p-value")		
  mod_sum_table["(Intercept)","Std.Beta"] = "0"		
  return(mod_sum_table)	
}	
# 	
# 	
# ## Az adatfajl betoltese: Lakasarak adattabla	
# 	
# Ebben a gyakorlatban lakasok es hazak arait fogjuk megbecsulni.	
# 	
# Egy **Kaggle**-rol szarmazo adatbazist hasznalunk, melyben olyan adatok szerepelnek, melyeket valoszinusithetoen alkalmasak **lakasok eladasi aranak bejoslasara**. Az adatbazisban az USA Kings County-bol szarmaznak az adatok (Seattle es kornyeke).	
# 	
# Az adatbazisnak csak egy kis reszet hasznaljuk (N = 200).	
# 	
# 	
data_house = read_csv("https://raw.githubusercontent.com/kekecsz/PSZB17-210-Data-analysis-seminar/master/seminar_7/data_house_small_sub.csv")	
# 	
# 	
# ## Adatellenoryes	
# 	
# Mindig ellenorizd az adatok strukturajat es integritasat.	
# 	
# Eloszor atvaltjuk az USA dollar-t millio forint mertekegysegre, es a negyzetlab adatokat negyzetmeterre.	
# 	
# 	
data_house %>% 	
  summary()	
	
data_house = data_house %>% 	
  mutate(price_HUF = (price * 293.77)/1000000,	
         sqm_living = sqft_living * 0.09290304,	
         sqm_lot = sqft_lot * 0.09290304,	
         sqm_above = sqft_above * 0.09290304,	
         sqm_basement = sqft_basement * 0.09290304,	
         sqm_living15 = sqft_living15 * 0.09290304,	
         sqm_lot15 = sqft_lot15 * 0.09290304	
         )	
	
	
# 	
# 	
# 	
# Egyszeru leiro statisztikak es abrak.	
# 	
# Kezdetben a lakasok arat a **sqm_living** (a lakas lakoreszenek alapterulete negyzetmeterben), es a **grade** (a lakas altalanos  minositese a King County grading system szerint, ami a lakas minoseget, poziciojat, a haz minoseget stb. is tartalmazza) prediktorok felhasznalasaval josoljuk majd be. Kesobb a **has_basement** (tartozik-e a lakashoz pince) valtozot is hasznaljuk majd. Szoval fokuszaljunk ezekre a valtozokra az adatellenorzes soran.	
# 	
# 	
	
# leiro statiszikaka	
describe(data_house)	
	
# hisztogramok	
data_house %>% 	
  ggplot() +	
  aes(x = price_HUF) +	
  geom_histogram( bins = 50)	
	
	
data_house %>% 	
  ggplot() +	
  aes(x = sqm_living) +	
  geom_histogram( bins = 50)	
	
data_house %>% 	
  ggplot() +	
  aes(x = grade) +	
  geom_bar() +	
  scale_x_continuous(breaks = 4:12)	
	
	
# scatterplot	
data_house %>% 	
  ggplot() +	
  aes(x = sqm_living, y = price_HUF) +	
  geom_point()	
	
data_house %>% 	
  ggplot() +	
  aes(x = grade, y = price_HUF) +	
  geom_point()	
	
# leiro statisztika	
table(data_house$has_basement)	
	
# violin plot	
data_house %>% 	
  ggplot() +	
  aes(x = has_basement, y = price_HUF)+	
  geom_violin() +	
  geom_jitter()	
	
# 	
# 	
# ## Tobbszoros regresszio	
# 	
# ### A regresszios modell felepitese (fitting a regression model)	
# 	
# A tobbszoros regresszios modellt ugyan ugy epeitjuk mint az egyszeru regresszios modellt, csak csak tobb prediktort is betehetunk a modellbe. Ezeket a prediktorvaltozokat + jellen valasztjuk el egymastol a regresszios formulaban.	
# 	
# Alabb **price_HUF** a bejosolt valtozo, es a **sqm_living** es a **grade** a prediktorok.	
# 	
# 	
# 	
mod_house1 = lm(price_HUF ~ sqm_living + grade, data = data_house)	
# 	
# 	
# A regresszios egyenletet a modell objektumon keresztul erhetjuk el:	
# 	
# 	
mod_house1	
# 	
# 	
# 	
# A tobbszoros regresszios modellek vizualizacioja nem olyan egyertelmu mint az egyszeru regresszios modelleke.	
# 	
# Az egyik megoldas hogy a paronkenti osszefuggeseket vizualizaljuk egyenkent, de ez nem ragadja meg a modell tobbvaltozos jelleget.	
# 	
# 	
# scatterplot	
plot1 = data_house %>% 	
  ggplot() +	
  aes(x = sqm_living, y = price_HUF) +	
  geom_point()+	
  geom_smooth(method = "lm")	
	
plot2 = data_house %>% 	
  ggplot() +	
  aes(x = grade, y = price_HUF) +	
  geom_point()+	
  geom_smooth(method = "lm")	
	
grid.arrange(plot1, plot2, nrow = 1)	
# 	
# 	
# Egy alternativa hogy egy haromdimenzios abran abrazoljuk a regresszios sikot.Bar ez szepen nez ki, de nem tul hasznos, es ez is csak ket prediktorvaltozoig mukodik, harom es tobb prediktor eseten mar egy tobbdimenzios terben kepzelheto csak el a regresszios felulet, ezert a vizualizaciora altalaban megis az paronkenti scatterplot-ot szoktuk hasznalni.	
# 	
# 	
# plot the regression plane (3D scatterplot with regression plane)	
scatter3d(price_HUF ~ sqm_living + grade, data = data_house)	
	
# 	
# 	
# ### Becsles (prediction)	
# 	
# Ugyan ugy ahogy az egyszeru regresszional, itt is kerhetjuk a prediktorok bizonyos uj ertekekeire a kimeneti valtozo ertekenek megbecsleset a predict() fuggveny segitsegevel.	
# 	
# Fontos, hogy a prediktorok ertekeit egy data.frame vagy tibble formatumban kell megadnunk, es a prediktorvaltozok valtozoneveinek meg kell egyeznie a regresszios modellben hasznalt valtozonevekkel.	
# 	
# 	
sqm_living = c(60, 60, 100, 100)	
grade = c(6, 9, 6, 9)	
newdata_to_predict = as.data.frame(cbind(sqm_living, grade))	
predicted_price_HUF = predict(mod_house1, newdata = newdata_to_predict)	
	
cbind(newdata_to_predict, predicted_price_HUF)	
# 	
# 	
# ### Hogyan kozoljuk az eredmenyeinket egy kutatasi jelentesben	
# 	
# Egy kutatsi jelentesben (pl. cikk, muhelymunka, ZH) a kovetkezo informaciokat kell leirni a regresszios modellrol:	
# 	
# Eloszor is le kell irni a regresszios **modell tulajdonsagait** (altalaban a "Modszerek" reszben):	
# 	
# "Egy linearis regresszios modellt illesztettem, melyben a lakas arat (millio HUF-ban) a lakas lakoreszenek teruletevel (m^2-ben) es a lakas King County lakas-minosites ertekevel becsultem meg." 	
# 	
# "I built a linar regression model in which I predicted housing price (in million HUF) with the size of the living area (in m^2) and King County housing grade as predictors."	
# 	
# Ezutan a **teljes modell bejoslasi hatekonysagat** kell jellemezni. Ezt a modellhez tartozo adjusted R^2 ertek (modositott R^2), es a modell-t a null-modellel osszehasonlito anova F-tesztjenek statiszikainak megadasaval szoktuk tenni (F-ertek, df, p-ertek). Mindezen informaciot a summary() funkcioval tudjuk lekerdezni. A modell illeszkedeset az AIC (Akaike information criterion) ertekkel is szoktuk jellemezni, amit az AIC() funcio ad meg.	
# 	
# Az APA publikacios kezikonyv alapjan minden szamot ket tizedesjegy pontossaggal kell megadni, kiveve a p erteket, amit harom tizedesjegy pontossaggal.	
# 	
# 	
sm = summary(mod_house1)	
sm	
	
AIC(mod_house1)	
# 	
# 	
# Vagyis az "Eredmenyek" reszben igy irnank a fenti pelda eredmenyeirol: 	
# 	
# "A tobbszoros regresszios modell mely tartalmazta a lakoterulet es a lakas minosites prediktorokat hatekonyabban tudta bejosolni a lakas arat mint a null modell. A modell a lakasar varianciajanak `r round(sm$adj.r.squared, 4)*100`%-at magyarazta (F `r paste("(", round(sm$fstatistic[2]), ", ", round(sm$fstatistic[3]), ")", sep = "")` =  `r round(sm$fstatistic[1], 2)`, `r if(round(pf(sm$fstatistic[1],sm$fstatistic[2],sm$fstatistic[3],lower.tail=F), 3) == 0){"p < .001"} else {paste("p = ", round(pf(sm$fstatistic[1],sm$fstatistic[2],sm$fstatistic[3],lower.tail=F), 3), sep = ")")}`, Adj. R^2 = `r round(sm$adj.r.squared, 2)`, AIC = `r round(AIC(mod_house1), 2)`)."	
# 	
# Ezen felul meg kell adnunk a **regresszios egyenletre es az egyes prediktorok becsleshez valo hozzajarulasara vontkozo adatokat**. Ezt altalaban egy osszefoglalo tablazatban szoktuk megadni, melyben a kovetkezo adatok szerepelnek prediktoronkent:	
# 	
# - regresszios egyutthato (regression coefficients, estimates) - summary()	
# - az egyutthatokhoz tartozo konfidencia intervallum (coefficient confidence intervals) - confint()	
# - standard beta ertekek (standardized beta values) - lm.beta() az lm.beta pakcage-ben	
# - a t-teszthez tartozo p-ertek (p-values of the t-test) -summary()	
# 	
# 	
	
confint(mod_house1)	
lm.beta(mod_house1)	
# 	
# 	
# A vegso tablazat valahogy igy nez majd ki (ennek az elkeszitesehez a fenti coef_table() sajat funkciot hasznaltam. Nem fontos ezt hasznalni, manualisan is ki lehet irogatni az eredmenyeket a kulonbozo tablazatokbol.):	
# 	
# 	
sm_table = coef_table(mod_house1)	
sm_table	
# 	
# 	
# ### regresszios egyutthato ertelmezese	
# 	
# A regresszios egyutthatot ugy lehet ertelmezni, hogy a prediktor ertekenek egy ponttal valo novekedese eseten a kimeneti valtozo erteke ennyivel valtozik. Pl. ha a sqm_living-hez tartozo regresszios egyutthato `r round(sm_table["sqm_living","b"], 2)`, az azt jelenti hogy minden egyes ujabb negyzetmeter teruletnovekedes `r round(sm_table["sqm_living","b"], 2)` millio forint arvaltozassal jar.	
# 	
# ### az intercept-hez tartozo regresszios egyutthato ertelmezese	
# 	
# Az intercept egyutthatoja azt mutatja meg, hogy mi lenne a bejosolt (fuggo) valtozo becsult erteke, ha minden prediktor 0 erteket vesz fel. Ez nem mindig egy realis becsles, hiszen attol fuggoen hogy milyen prediktorokat hasznalunk, lehet hogy egy adott prediktoron a 0 ertek nem ertelmes. Ettol fuggetlenul az intercept matematikai ertelmezese mindig ugyan ez marad. Az intercept egyfajta allando ertek, ami fuggetlen a prediktorok erteketol.	
# 	
# 	
# ### standard beta ertelmezese	
# 	
# A regresszios egyutthato elonye, hogy a kimeneti valtozo mertekegysegeben van, es nagyon egyszeru ertelemzni. Ezert ez egy "nyers" hatasmeret mutato. Viszont a hatranya hogy az erteke a hozza tartozo prediktor valtozo skalajan mozog. Ez azt jelenti, hogy az egyes egyutthato ertekek nem konnyen osszehasonlithatoak, mert a prediktorok mas skalan mozognak. Pl. az sqm_living egyutthatoja alacsonyabb mint az grade egyutthatoja, de ez onmagaban nem mond arrol semmit, hogy melyik prediktornak van nagyobb szerepe a kimeneti valtozo bejoslasaban, mert a sqm_living skalaja sokkal kiterjedtebb (50-400 m^2) mint a grade skalaja (5-11).	
# 	
# Ahhoz hogy ossze tudjuk hasonlitani az egyes prediktorok becsleshez hozzaadott erteket, a ket egyutthatot ugyan arra a skalara kell helyeznunk, amit standardizalassal erhetunk el. A standard Beta egy ilyen standardizalt mutato. Ez mar direkt modon osszehasonlithato a prediktorok kozott. Ebbol mar latszik hogy a sqm_living hozzaadott erteke a price_HUF bejoslasahoz nagyobb mint a grade hozzaadott erteke.	
# 	
# Amikor tobb prediktor van, ez nem feltetlenul jelenti azt, hogy ha egyenkent megneznenk a prediktorok korrelaciojat a kimeneti valtozoval, akkor ugyan ilyen osszefuggest kapnank. Ez az egyutthato es a std.Beta ertek a prediktor egesz modellben betoltott szerepet  jeloli, a tobbi prediktor bejoslo erejenek leszamitasaval. Vagyis elkepzelheto, hogy egy prediktor onmagaban jobban korrelal a kimeneti valtozoval mint barmelyik masik prediktor, viszont a modellben kisebb szerepet jatszik, mert a tobbi prediktor ugyan azt a reszet magyarazza a kimeneti valtozo varianciajanak, mint ez a prediktor.	
# 	
# **______Gyakorlas_______**	
# 	
# 1. Epits egy tobbszoros linearis regresszio modellt az lm() fugvennyel amiben az **price_HUF** a kimeneti valtozot becsuljuk meg. Hasznalhatod a **data_house** adatbazisban szereplo barmelyik valtozot felhasznalhatod a modellben, ami szerinted realisan hozzajarulhat a lakas aranak meghatarozasahoz.	
# 2. Hatarozd meg, hogy szignifikansan jobb-e a modelled mint a null modell (a teljese modell F-teszthez tartozo p-ertek alapjan)?	
# 3. Mekkora a teljes modell altal bejosolt varianciaarany (adj.R^2)?	
# 4. Melyik az a prediktor, mely a legnagyobb hozzadaott ertekkel bir a becslesben?	
# 	
# **________________________**	
