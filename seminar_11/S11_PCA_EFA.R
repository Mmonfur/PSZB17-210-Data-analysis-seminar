# # Absztrakt	

# Ebben a gyakorlatban a "dimenzionalitas atkaval" birkozunk meg. Ezt a valtozok szamanak csokkentesevel oldjuk meg a fokomponenselemzes es az exploratoros faktorelemzes segitsegevel.	

# Ez a gyakorlat nagy mertekben a DataCamp Dimensionality Reduction in R kurzusa alapjan lett osszeallitva.	
# https://www.datacamp.com/courses/dimensionality-reduction-in-r	

# # Adat kezeles es leiro statisztikak	

# ## Csomagok betoltese	

# Ennek a gyakorlatnak a soran az alabbi csomagokat fogjuk hasznalni:	


library(tidyverse) # for tidy code	
library(GGally) # for ggcorr	
library(corrr) # network_plot	
library(ggcorrplot) # for ggcorrplot	
library(FactoMineR) # multiple PCA functions	
library(factoextra) # visualisation functions for PCA (e.g. fviz_pca_var)	
library(paran) # for paran	
	
library(psych) # for the mixedCor, cortest.bartlett, KMO, fa functions	
library(GPArotation) # for the psych fa function to have the required rotation functionalities	
library(MVN) # for mvn function	
library(ICS) # for multivariate skew and kurtosis test	
	


# ## Sajat funkciok betoltese	


fviz_loadnings_with_cor <- function(mod, axes = 1, loadings_above = 0.4){	
  require(factoextra)	
  require(dplyr)	
  require(ggplot2)	
	
	
	
if(!is.na(as.character(mod$call$call)[1])){	
  if(as.character(mod$call$call)[1] == "PCA"){	
  contrib_and_cov = as.data.frame(rbind(mod[["var"]][["contrib"]], mod[["var"]][["cor"]]))	
	
vars = rownames(mod[["var"]][["contrib"]])	
attribute_type = rep(c("contribution","correlation"), each = length(vars))	
contrib_and_cov = cbind(contrib_and_cov, attribute_type)	
contrib_and_cov	
	
plot_data = cbind(as.data.frame(cbind(contrib_and_cov[contrib_and_cov[,"attribute_type"] == "contribution",axes], contrib_and_cov[contrib_and_cov[,"attribute_type"] == "correlation",axes])), vars)	
names(plot_data) = c("contribution", "correlation", "vars")	
	
plot_data = plot_data %>% 	
  mutate(correlation = round(correlation, 2))	
	
plot = plot_data %>% 	
  ggplot() +	
  aes(x = reorder(vars, contribution), y = contribution, gradient = correlation, label = correlation)+	
  geom_col(aes(fill = correlation)) +	
  geom_hline(yintercept = mean(plot_data$contribution), col = "red", lty = "dashed") + scale_fill_gradient2() +	
  xlab("variable") +	
  coord_flip() +	
  geom_label(color = "black", fontface = "bold", position = position_dodge(0.5))	
	
	
}	
} else if(!is.na(as.character(mod$Call)[1])){	
  	
  if(as.character(mod$Call)[1] == "fa"){	
    loadings_table = mod$loadings %>% 	
      matrix(ncol = ncol(mod$loadings)) %>% 	
      as_tibble() %>% 	
      mutate(variable = mod$loadings %>% rownames()) %>% 	
      gather(factor, loading, -variable) %>% 	
      mutate(sign = if_else(loading >= 0, "positive", "negative"))	
  	
  if(!is.null(loadings_above)){	
    loadings_table[abs(loadings_table[,"loading"]) < loadings_above,"loading"] = NA	
    loadings_table = loadings_table[!is.na(loadings_table[,"loading"]),]	
  }	
  	
  if(!is.null(axes)){	
  	
  loadings_table = loadings_table %>% 	
     filter(factor == paste0("V",axes))	
  }	
  	
  	
  plot = loadings_table %>% 	
      ggplot() +	
      aes(y = loading %>% abs(), x = reorder(variable, abs(loading)), fill = loading, label =       round(loading, 2)) +	
      geom_col(position = "dodge") +	
      scale_fill_gradient2() +	
      coord_flip() +	
      geom_label(color = "black", fill = "white", fontface = "bold", position = position_dodge(0.5)) +	
      facet_wrap(~factor) +	
      labs(y = "Loading strength", x = "Variable")	
  }	
}	
	
	
	
	
	
	
return(plot)	
	
}	




# ## A cars beepitett adatbazis betoltese	

# A cars adatbazist fogjuk hasznalni, ami egy beepitett adatbazis az R-ben. Az adatbazis 32 kulonbozo automodellrol tartalmaz informaciokat az Motor Trend magazine 1974-es szamabol. Minden autonak 11 karakkterisztikajat tartalmazza az adattabla. Ezek a kovetkezok:	

# - mpg: uzemanyaghatekonysag: hany merfoldet tudunk megtenni az autoval 1 gallon benzinnel	
# - cyl: hengerek szama	
# - disp: hengerterfogat	
# - hp: loero	
# - drat: Rear axle ratio, ennek az uzemanyaghatekonysaghoz van koze, minel magasabb ez a szam annal rosszabb az uzemanyaghatekonysag	
# - wt: suly	
# - qsec: hany masodperc alatt tesz meg 1/4 merfoldet az auto. a gyorsulassal es sebesseggel fugg ossze	
# - vs: kategorikus valtozo: a motorblokk alakjarol szol: egyenes alaku (0), V alaku (1)	
# - am: kategorikus valtozo: automata valtos auto (0) kezi valtos auto (1).	
# - gear: sebessegek szama	
# - carb: karburatorok szama	



data("mtcars")	


# ## Az adatsor megtekintese	

# Vizsgaljuk meg az adatok strukturajat es az alapveto leiro statisztikakat	


	
str(mtcars)	
	
summary(mtcars)	
	
	


# Tegyuk fel hogy autot szeretnenk vasarolni es szeretnenk a leheto legjobb dontest hozni azzal kapcsolatban hogy melyik autot valasszuk, de nem ertunk kulonosebben az autokhoz. Amikor megnezzuk a Motor Trend magazint, latjuk ezt a 11 karakterisztikat, de nincs idonk minden autot osszehasonlitani mind a 11 karakterisztika alapjan. Szeretnenk valahogy egyszerusiteni a helyzetet, es megtudni, mik a legfontosabb alapveto tulajdonsagain egy autonak ami alapjan a dontesunket meghozhatjuk. 	

# Nezzuk meg az adatok korrelacios matrixat, hogy jobb kepet kapjunk arrol, mely valtozok fuggenek ossze egymassal es milyen szorosan.	

# A korrelacios matrixot tobbfajta modon is vizualizalhatjuk. Az eredmeny alapjan lathato hogy vannak korrelacios "klaszterek", vagyis olyan valtozok amik csoportosan osszefuggenek egymassal, de a kep egyelore tul bonyolult, mert tul sok a valtozo.	

# Az alabbi peldaban hasznalt network_plot() funcio neha nem ranzolja ki a vonalakat. Sajnos ennek nem jottem ra a megoldasara. Ezt masok is tapasztaltak, itt lehet kovetni ezt a hibajelentest: https://github.com/tidymodels/corrr/issues/63	


	
cor = mtcars %>% 	
  cor()	
cor	
	
ggcorr(cor)	
	
ggcorrplot(cor(mtcars), p.mat = cor_pmat(mtcars), hc.order=TRUE, type='lower')	
	
cor %>% network_plot(min_cor=0.6)	
	




# # Fokomponenselemzes	

# ## A fokomponenselemzes modell megepitese	

# Nehany valtozo osszefuggeset konnyen atlathatova tehetjuk vizualizacion keresztul. Azonban ha sok valtozoval van dolgunk, a vizualizacio es egyeb korabban tanult feltaro adatelemzesi technikak kudarcot vallhatnak egyszeruen azert mert tul sok az informacio amit nehez atlatni es vizualizalni. Ebben a helyzetben segithet a fokomponenselemzes, amit arra hasznalunk hogy lecsokkentsuk a valtozok szamat amivel dolgoznunk kell, ugy, hogy kozben a leheto legtobb informaciot tartunk meg az adatok variabilitasarol.	

# A fokomponenselemzest a PCA() (principal component analysis) funkcioval tudjuk elvegezni a FactoMineR package-bol. Az elemzes eredmenyet egy pca_mod modell objektumba mentettem el. A egybol kiad ket abrat a ket legfontosabb fokomponensrol (dimenziorol) amik a leghatekoonyabban irjak le az adatokat.	

# Az egyik abran az latszik, hogy az egyes megfigyelesek (ebben az esetben az egyes auto-modellek) hol helyezkednek el a ket dimenzio menten. A masodik abra pedig arrol szol, hogy a dimenziok milyen korrelaciot mutatnak az eredeti valtozokkal. A szaggatott vonalak mutatjak a fokomponenseket. A nyilak minel kozelebb fekszenek a szaggatott vonalhoz, a valtozo annal inkabb egyuttjar az adott dimenzioval a masik dimenzioval szemben.	

# Peladaul a cyl es az mpg valtozokat sokkal jobban leirja a Dim1 mint a Dim2. (a nyil iranya alapjan megallapithato hogy az mpg negativan, a cyl pozitivan korrelal a Dim1-el.) Ezzel szemben az ?carb valtozok nyila a ket dimenzio kozott helyezkedik el, ami azt jelenti hogy vagy midkettovel nagyjabol azonos mertekben korrelalnak (ez lehet nagyon kicsi, vagy akar nagyon nagy korrelacio is).	



	
pca_mod <- PCA(mtcars)	
	



# Arra oda kell figyelnunk hogy kategorikus valtozok ne keruljenek a fokomponenselemzes valtozoi koze. a vs es am valtozok kategorikus valtozok (csak 0 es 1 erteket vehetnek fel), es a cyl valtozo is tekintheto kategorikusnak, hiszen csak harom erteket vesz fel az adattablankban: 4, 6, 8. 	

# A PCA() funkcioban lehetosegunk van arra hogy meghatarozzunk olyan valtozokat az adatbazisban, amiket nem szeretnenk beepiteni a PCA modellbe. Azokat a folytonos valtozokat, amiket nem szeretnenk figyelembevenni a PCA soran, a quanti.sup parameterben kell megadnunk, azokat pedig amik kategorikusak a quali.sup parameterben. Itt az addott valtozo oszlopszamat kell megadnunk, nem pedig a nevet, igy ezt eloszor ki kell keresnunk. Ezt megtehetjuk a which(names(mtcars) == "valtozo neve") funkcioval.	

# Az alabbi peldaban a drat folytonos, es a cyl, vs, es az am kategorikus valtozokat kiemeljuk a modellbol, igy azok nincsenek figyelembe veve a pca_mod3 fokomponenseinek meghatarozasa soran, de az abrakon ettol meg szerepelnek. Ebben az esetben termeszetesen a modell ujra illesztesre kerul, es a szamszeru ertekek megvaltoznak a korabbi futtatashoz kepest amikor ezek a valtozok meg szerepeltek a modellben.	



	
which(names(mtcars) == "drat")	
which(names(mtcars) == "cyl")	
which(names(mtcars) == "vs")	
which(names(mtcars) == "am")	
	
	
pca_mod2 <- PCA(mtcars, quanti.sup = 5, quali.sup = c(2, 8, 9))	
	
summary(pca_mod2)	



# ## Hany uj dimenziot generaljunk?	

# A fokomponenselemzes egy dmienzioredukcios technika, vagyis celunk hogy kevesebb dimenzionk legyen az elemzes vegere, mint ahany valtozoval kezdtuk az elemzest. Viszont hogyha ranezunk a model summary-ra, lathatjuk hogy a PCA funkcio alapertelmezett modon pontosan annyi dimenziot generalt mint amennyi valtozonk volt. Meg kell mondanunk a PCA funkcionak, hany dimenaziot akarunk kinyerni. De hogyan tudjuk eldonteni, mennyi az idealis szamu dimenzio?	

# Erre szamos modszer letezik. 	

# **1. Scree test**	

# A legismertebb talan a scree-test, ami a megmagyarazott varianciaaranyt abrazolo abra alapjan vegezheto el. Ehhez eloszor a fviz_screeplot() funkcioval abrazolnunk kell az egyes fokomponensek altal megmagyarazott variancia merteket, majd az abra alapjan meg kell allapitanunk, hol van a "tores" a scree-plotban, vagyis hol talalhato az a pont, ami utan mar ellaposodik a megmagyarazott varianciaaranyt abrazolo gorbe. A torespont elotti dimenzional kell hogy megalljon a dimenzio-extrakcio, vagyis annal a dimenzional, ami meg szignifikansan tobb varianciat kepes megmagyarazni, mint a kesobb kinyerd dimenziok. Ezt a megallasi szabalyt ugy is nevezik hogy a "konyok kriterium", mivel a scree plot egy konyokre emlekeztet, es mi a konyokpontot keressuk a gorbeben.	

# Ezen az abran ugy tunik, hogy a masodik dimenzio utan mar nem erdemes tovabbmennunk, hiszen a harmadik dimenzional megtorik a gorbe es onnantol mar nagyon alacsony a megmagyarazott varianciaarany. Vagyis az idealis dimenzioszam ezen az adaton 2.	


	
fviz_screeplot(pca_mod2, addlabels = TRUE, ylim = c(0, 85))	
	
	


# **The Kaiser-Guttman szabaly**	

# Egy masik jol ismert kriterium, hogy azokat a dimenziokat kell megtartanunk, amelyeknek az eigenvalue erteke 1-nel magasabb. Ez azert van, mert az 1-nel alacsonyabb eigenvalue azt jelenti, hogy a dimenzio kevesebb varianciat magyaraz meg mint az eredeti valtozok atlagosan. A fokomponens elemzes lenyege hogy hasznos osszefoglalo valtozokat generaljunk amik tobb valtozo informaciojat tartalmazzak osszevonva. Azt pedig nem szeretnenk hogy meg az eredeti valtozoinknal is haszontalanabb valtozokat generaljunk, ezert az atlagos valtozoinknal kisebb varianciat megmagyarazo dimenziokat elutasitjuk.	

# A peldankban ez az elemzes is azt sugallja, hogy ket dimenziot tartsunk meg, hiszen a harmadik dimenziohoz tartozo eigenvalue mar 1-nel kisebb.	



	
get_eigenvalue(pca_mod2)	
	
	


# **Parallel elemzes**	

# A harmadik (es egyben jelenleg a legelfogadottabb) technika a parallel elemzes technika. Ennek a lenyege hogy az eredeti adattablankhoz hasonlo karakterisztikakkal rendelkezo adatokat generalunk veletlenszeruen, de ugy, hogy abban a valtozok ne korrelaljanak egymassal. Ezt nagyon sokszor megismeteljuk, es ez alapjan a nagy mennyisegu random minta alapjan kiszamoljuk, mi a veletlenszeruen varhato eigenvalue mintazat. Ez egyfajta "null modelkent" funkcional, amihez hasonlithatjuk a sajat adatainkon kapott eignevalue-kat. Azokat a dimenziokat tartjuk meg, amiknek az eigenvalue-ja magasabb mint a random mintakban az adott dimenziohoz tartozo null-eigenvalue. 	

# Ezt a parallel elemzest begezhetjuk el a paran() funkcioval a paran package-bol. Ez a funkcio a null eigenvalue gorbe vizualizalasara is kepes a graph = TRUE prameter beallitasaval, melyet osszehasonlithatunk az adatainkban kapott eigenvalue-val. Az output objektum $Retained komponense megmutatja, az elemzes hany dimenzio megtartasat javasolja.	




	
mtcars_pca_ret = paran(mtcars[,-c(2, 5, 8, 9)], 	
                    graph = TRUE)	
	
mtcars_pca_ret$Retained	
	
	




# Amint meghataroztuk az idealis dimenziok szamat, ujra lefuttathatjuk az elemzesunket, de ezuttal mar specifikalmva, mennyi dimenziot szeretnenk, a npc parameter beallitasaval.	


	
pca_mod3 <- PCA(mtcars, ncp = 2, quanti.sup = 5, quali.sup = c(2, 8, 9))	
	
summary(pca_mod3)	
	
	






# ## Fokomponenselemzes eredmenyeinek ertelmezese	

# ### a PCA modell opjektum reszei	

# A modell osszefoglalobol (model summary) tovabbi hasznos informaciok olvashatok ki. Az Eigenvalues reszben megtudhatjuk hogy az egyes dimenziok az adatok teljes varianciajanak hany szazalekat magyarazzak meg (% of var), es hogy a legfontosabbtol a legalacsonyabbig egyesevel osszevonva mekkora a tobb dimenzio altal megmagyarazott osszesitett varianciaarany (Cumulative % of var). Vagyis a Dim.3-hoz tartozo % of variance ertek (`r round(pca_mod3[["eig"]][,"percentage of variance"][3],2)`) azt mutatja, hogy a harmadikkent kinyert dimenzio az adatok varianciajanak `r round(pca_mod3[["eig"]][,"percentage of variance"][3],2)*100`%-at tudja megmagyarazni onmagaban. Az Dim.3-hoz tartozo dim Cumulative % of var ertek (`r round(pca_mod3[["eig"]][,"cumulative percentage of variance"][3],2)` pedig azt mutatja, hogy a Dimenzio 3 a Dim.1 es Dim.2-vel egyutt kozosen az adatok varianciajanak (`r round(pca_mod3[["eig"]][,"cumulative percentage of variance"][3],2)*100`%-at kepesek megmagyarazni. Ha csak az eigenvalue-t es a megmagyarazaott varianaciaaranyokat tartalmazo tablazat erdekel minket, ezt kinyerhetjuk ugy hogy csak a  pca_mod3$eig komponenst listazzuk ki.	

# A model summary arrol is tartalmaz informaciot a Variables reszeben, hogy az egyes valtozok hogyan korrelalnak az egyes uj dimenziokkal (a Dim.1, Dim.2, Dim.2 ... oszlopokaban), es hogy mekkora a hozzajarulasuk az adott valtozo altal megmagyarazott varianciahoz (a ctr oszlopban). Ez egy nagyon fontos tablazat, mert innen tudjuk leolvasni (az abrak mellett) hogy az egyes valtozokat mely dimenziok (faktorok) irjak le leginkabb. Bovebb informaciot talalunk ha kilistazzuk a pca_mod3$var komponenst.	



# Get the summary the outputs.	
summary(pca_mod3)	
	
pca_mod3$eig	
	
pca_mod3$var	


# ### Az eredmenyek vizualizalasa	

# Az eredmenyek vizualizalasa segithet a komponensek ertelmezeseben. A fviz_pca_var()  es a fviz_pca_ind() segitsegevel reprodukalhatjuk a PCA funcio altal eredetileg general abrakat. Sot, a kettot ossze is vonhatjuk a fviz_pca_biplot() funkcioval. Igy egyszerre lathatjuk hogy a ket legfontosabb dimenzio menten hol helyezkednek el az egyes megfigyelesek (az autok), es hogy a dimenziok foleg mely valtozokat reprezentaljak. (A repel = T parameterbeallitas arra jo hogy a feliratok ne fedjek egymast hanem elcsusztatva szerepeljenek az abran ha tul kozel lennenek egymashoz) 	


fviz_pca_var(pca_mod3, repel = T)	
fviz_pca_ind(pca_mod3, repel = T)	
fviz_pca_biplot(pca_mod3, repel = T)	
	


# Az abrakat tovabb tunningolhatjuk azzal, hogy abrazoljuk rajtuk az egyes valtozok vagy megfigyelesek hozzajarulasat (contribution) az abrazolt dimenziohoz a , col.var = "contrib" es , col.ind = "contrib" parametereken keresztul. 	

# Azt is megtehetjuk, hogy a select.ind = parameteren keresztul hogy csak bizonyos megfigyeleseket teszunk az abrara.Pl. cos^2 ertek azt mutatja, hogy az adott megfigyeles vagy valtozo menyire jol reprezentalt az adott dimenzio altal. A select.ind = list(cos2 = 10) parameter beallitasaval meghatarozhatjuk, hogy csak az a 10 megfigyeles szerepeljen az abran, akiknek a ket diemnziora vonatkozo cos^2 osszege a legmagasabb. Vagyis a ket dimenzio altal leirt dimenzioter 10 legreprezentativabb megfigyelese.	

# Ez az abra azt mutatja hogy az alacsony Dim.1, kozepes Dim.2 legtipikusabb tagjai pl. a Honda Civic, a Toyota Corolla, a magas Dim.2. kozepes Dim.1 legtipikusabb tagja talan a Ferrari Dino, mig a magas Dim1. es magas Dim.2. legtipikusabb tagja a Maserati Bora. Ez fontos lehet a dimenziok ertemezeseben.	




	
fviz_pca_ind(pca_mod3, select.ind = list(cos2 = 10), repel = T)	
	


# Egy masik fontos abratipus az egyes dimenziok ertelmezesenek elosegitesehez a  fviz_contrib() altal generalt barchart, ami az egyes valtozok egyes dimenziokhoz valo hozzajarulasat mutatja meg. Az axes = parameterrel allithatjuk be, melyik dimenziora vagyunk kivancsiak. A piros szaggatott vonal azt mutatja, hogy mi lenne az elvart hozzajarulas szazaleka abban az esetben ha minden valtozo azonos mertekben jarulna hozza a dimenzio megmagyarazasahoz.	

# Ez az abra akkor lenne igazab informativ ha a korrelacio merteke es iranya is egyertelmu lenne rola. Ezt onmagaban nem tartalmazza a fviz_contrib() funkcio, ezert a fviz_loadnings_with_cor() sajat funkcio hasznalataval helyettesitjuk, melyen az oszlopok a korrelacio szerint vannak szinezve es a korrelacio feliratkent is szerepel az abran.	

# Ezek az abra azt mutatjak, hogy a Dim.1-hez elsosorban az mpg, dist, hp, es wt valtozok jarulnak hozza, mig a Dim.2-hoz elsosorban a gear qsec es a carb valtozok jarulnak hozza.	

# Ezek alapjan az abrak alapjan, es a reprezentativ esetek abraja alapjan mit gondolsz, hogyan nevezhetnek el az egyes es a kettes dimenziot?	


# original functions in factoextra	
# fviz_contrib(pca_mod3, choice = "var", axes = 1)	
# fviz_contrib(pca_mod3, choice = "var", axes = 2)	
	
# using custom function for correlation color gradient	
fviz_loadnings_with_cor(mod = pca_mod3, axes = 1)	
fviz_loadnings_with_cor(mod = pca_mod3, axes = 2)	
	


# A vizualizaciot arra is hasznalhatjuk, hogy csoportositsuk a megfigyeleseket a dimenziokon mutatott ertekuk alapjan. Ezt az addEllipses = T parameterrel adhatjuk meg.	

# Hogyan jellemezned az egyes elipszisekben talalhato autokat az alapjan, hogy az 1. es 2. dimenzion milyen ertekekt vesznek fel?	


	
fviz_pca_ind(pca_mod3, 	
             label = "ind",	
             repel = T,	
    habillage=factor(mtcars$cyl),	
    addEllipses = T)	
	


# # Bevezetes a feltaro faktorelemzesbe (Exploratory Factor Analysis - EFA)	

# A faktorelemzes egy masik dimenzioredukcios technika ami hasonlit a fokomponenselemzeshez. A ketto kozott fontos kulonbseg hogy a faktorelemzest akkor hasznaljuk, ha feltetelezzuk hogy a sok valtozonk hattereben kozos okok, ugynevezett latens faktorok allnak, es ez okozza, hogy a megfigyelt valtozoink korrelalnak egymassal.	

# Amikor egy feltaro faktorelemzesi (EFA) modellt epitunk, nem probaljuk megmagyarazni a teljes varianciat az adatokban, mert megengedjuk hogy a latens faktorok csak reszben magyarazzak a megfigyelt valtozok varianciajat. A fennmarado varianciat vagy meresi hiba, vagy olyan faktorok befolyasoljak, amik egyediak a megfigyelt valtozora. Ezert az EFA-ban minden egyes megfigyelt valtozohoz tartozik egy "kommunalitas" (communality) ertek. Ez az ertek azt mutatja meg, hogy az adott valtozoban megfigyelheto variancia mekkora hanyadat magyarazzak a latens faktorok. A fennmarado varianciat a valtozora egyedi faktor vagy meresi hiba magyarazza (ezt egyedisegnek, vagy uniqueness-nek is nevezzuk).	

# A faktorelemzes legfontsabb lepesei:	

# - Faktoralhatosag ellenorzese	
# - Faktorkinyeres	
# - Idealis faktorszam kivalasztasa	
# - Faktorforgatas	
# - Faktorok ertelmezese	

# ## Uj adatok	

# Alabb betoltjuk a "Human Styles Questionnaire" adatbazist, ami a Martin et. al. (2003). kutatasabol szarmazik, akik a HSQ kerdoivet vettek fel 1071 szemellyel.	

# Az adatbazis elso 32 oszlopa Q1-Q32 a kerdoiv egyes teteleire adott valaszokat tartalmazza minden szemelytol. A valaszadoknak mind a 32 allitasrol ertekelnie kellett, hogy mennyire igaz az ra nezve. A valaszok ordinalis skalan mozognak, 1-tol 5-ig: 1="soha vagy nagyon ritkan igaz"", 5="nagyon gyakran vagy soha nem igaz". Ilyen allitasok szerepelnek a kerdoivben mint: "Q1: Altalaban nem nevetek vagy viccelodok masokkal." (Q1: "I usually don't laugh or joke around much with other people.")	

# A faktorelemzessel az a celunk, hogy azonositsuk a hatterben megbuvo pszichologiai vonasokat, amik meghatarozzak az egyes embereke hogyan valaszolnak ezekre a tetelekre.	


	
hsq <- read_csv("https://raw.githubusercontent.com/kekecsz/PSZB17-210-Data-analysis-seminar/master/seminar_11/hsq.csv")	
	
hsq %>% 	
describe()	
	




# ## Adatok faktoralhatosaga	

# Az adatfaktoralhatosag tesztelesekor azt a kerdest valaszoljuk meg, hogy van-e elegendo egyuttjaras (korrelacio) a megfigyelheto valtozok kozott, ami lehetove teszi az EFA elvegzeset. Ennek tesztelesere ket modszert is alkalmazunk: a Bartlett sphericity tesztet es a Kaiser-Meyer-Olkin tesztet.	

# Mindenek elott azonban az adatok korrelacios matrixara van szuksegunk, amin ezeket a teszteket lefuttathatjuk. Ezt megkaphatnank a cor() funkcioval ha folytonos valtozokkal dolgoznank, de ebben az adatbazisban ordinalis adatokkal van dolgunk, igy egy masik funkciot hasznalunk aminek a neve mixedCor() a psych package-bol. Ez a funkcio kepes az ordinalis adatok eseten hasznalatos "Polychoric Correlation" meghatarozasara. A mixedCor() funkcioban meghatarozzuk hogy melyek a folytonos valtozok, es melyek az ordinalis valtozok. A Q1-Q32 mind ordinalis, ezert csak a p = 1:32-t hatarozzuk meg, a c=-t pedig NULL-ra allitjuk, mert nincs folytonos skalan mozgo (continuous) valtozo.	

# Fontos, hogy a korrelacios matrixot a mixedCor() a $rho komponenseben tarolja, ezert ezt kell elmentenunk egy uj adatobjektumba. Mentsuk el ezt a hsq_correl nevu objektumba.	


	
hsq_mixedCor <- mixedCor(hsq, c=NULL, p=1:32)	
hsq_correl = hsq_mixedCor$rho	
	


# **___________________Gyakorlas___________________**	

# A fentebb tanultak alapjan vizualizald a valtozok kozotti korrelaciot. Hasznalj tobb modszert is, pl. ggcorr(), ggcorrplot() hc.order=TRUE-val kombinalva, vagy network_plot().	


# **_______________________________________________**	


# **Bartlett sphericity teszt**	

# A bartlett teszt lenyege hogy a valos korrelacios matrixot osszehasonlitjuk egy hipotetikus null-korrelacios matrix-al, amiben minden korrelacio 0 erteket vesze fel (identity matrix). A null hipotezis amit itt tesztelunk az, hogy a ket korrelacios matrix nem kulonbozik egymastol. Ha a teszt szignifikans, az azt jelenti hogy az adattabla valtozoi korrelalnak egymassal.	

# Azonban fontos megjegyezni, hogy a Bartlett tesztnek van egy hatulutoje, megpedig hogy nagy elemszamoknal szinte biztosan szignifikans eredmenyt ad. Csak olyankor erdemes erre a mutatora hagyatkozni a faktoralhatosag megallapitasakor amikor amikor a megfigyelesek szama es a megfigyelt valtozok szamanak aranya kisebb mint 5. A mi esetunkben ez az arany 1071/32 = 33.5, vagyis a Bartlett teszt eredmenye nem megbizhato.	




	
bfi_factorability <- cortest.bartlett(hsq_correl)	
bfi_factorability	
	


# **Kaiser-Meyer-Olkin (KMO) teszt**	

# A KMO teszt a parcialis korrelacios matrixot hasonlitja ossze a szokasos korrelacios matrixal. A parcialis korrelacio soran meghatarozzuk hogy mekkora ket valtozo kozotti korrelacio, ha kivonjuk a tobbi valtozo hatasat a korrelaciobol. A KMO ertek azt mutatja, hogy mekkora a kulonbseg a parcialis korrelaciok es a szokasos korrelaciok kozott. A KMO egy kulonbseg ertek, a parcialis korrelaciok es a szokasos korrelaciok kozotti kulonbseget jelzi. Azokban az esetekben ahol a valtozok sok kozos varianciat hordoznak (vagyis valoszinu hogy mogottuk egy kozos latens faktor all), a parcialis korrelaciok alacsonyak, vagyis a KMO index magas. A KMO tesztben az 1-hez kozeli ertekek jok jo faktoralhatosagot mutatnak. A KMO index-nek legalabb 0.6-nak kell lennie hogy ugy iteljuk hogy a valtozok faktoralhatoak.	

# A mi peldankban a KMO minden valtozo eseten magasabb 0.6-nal, es az osszesitett KMO is magasabb 0.6-nal, igy faktoralhatonak tekinthetok a valtozok.	


	
KMO(hsq_correl)	
	


# ## Faktorextrakcio	

# A faktorokat az fa() funkcioval fogjuk kinyerni. Ez a funkcio tobb faktorextrakcios modszert is kinal. A leggyakrabban hasznalt modszer a **Maximum Likelihood Estimation** (mle) akkor ha a megfigyelt valtozok megfelelnek a tobbvaltozos normalitas feltetelenek, mig a **Principal Axis Factoring** (paf) a preferalt modszer akkor, ha a valtozok nem mutatnak tobbvaltozos normalis eloszlast.	

# Az mvn() funkcio az MVN package-bol es a mvnorm.kur.test() es a mvnorm.skew.test() funkciok az ICS package-bol segithet eldonteni, hogy tobbvaltozos normalis eloszlast mutatnak-e az adatok. Ha ezeknek a teszteknek a p-erteke alacsonyabb 0.05-nel, akkor az a tobbvaltozos normalitas serulesere utal.	


	
	
result <- mvn(hsq[,1:32], mvnTest = "hz")	
result$multivariateNormality	
	
mvnorm.kur.test(na.omit(hsq[,1:32]))	
mvnorm.skew.test(na.omit(hsq[,1:32]))	
	


# Fent lathato hogy mind a Henze-Zirkler teszt mind a tobbvaltozos ferdeseg es csucsossag tesztek a normalitas feltetelenek serulesere utal. Igy a paf extrakcios modszert hasznaljuk majd. 	

# A faktorextrakciora a psych package fa() funkciojat hasznaljuk. Ezen belul megadhatjuk a faktoreztrakcios modszert az fm = parameteren belul. Itt fm = "pa"-t hatarozunk meg, mert a paf modszert szeretnenk hasznalni, de ha a tobbvaltozos normalitas nem serult volna, akkor ehelzett "mle"-t hasznaltunk volna. Az alabbi peldaban meg nem akartam faktorforgatast alkalmazni, hogy lepesrol lepesre tudjam bemutatni a faktorelemzes modszeret, igy a rotate = erteket "none"-ra allittam, de altalaban a faktorokat egybol el is forgatjuk valamelyik modszerrel (lasd alabb). Az nfactors = parameterrel adhatjuk meg, hany faktort szeretnenk kinyerni. Egyelore allitsuk ezt 5-re, lentebb tartgyaljuk majd, hogyan valasztjuk ki az idealis faktormennyiseget.	

# A modell objektum $communality komponenseben talaljuk a valtozokhoz tartozo kommunalitas ertekekt. Ezt legmagasabbtol legalacsonyabbig sorbarendezzuk es kilistazzuk. Ahogy fentebb emlitettuk a kommunalitas azt jelzi, hogy az egyes megifigyelt valtozokban tapasztalhato variancia mekkora hanyadat magyarazzak a kinyert faktorok.  Az output azt mutatja, hogy a Q17  "Altalaban nem szeretek viccelodni, vagy masokat szorakoztatni" ("I usually don't like to tell jokes or amuse people.") a legjobban reprezentalt item az 5 faktoros strukturaban, aminek 68%-at kepesek megmagyarazni az uj faktorok. Ezzel szemben a Q22 "Amikor szomoru vagy ideges vagyok altalaban elvesztem a humorerzekemet" ("If I am feeling sad or upset, I usually lose my sense of humor.") a legkevesbe reprezentalt item, varianciajanak csak 25%-at magyarazza a jelenlegi faktorstruktura.	

# Neha ahhoz hogy a faktorstruktura jol mukodjon, erdemes a rosszul reprezentalt itemeket kizarni. Ez foleg akkor fontos, ha kicsi a mintaelemszam. Ha a megfigyelesek szama 250 alatti, akkor MacCallum et al. szerint elvarhato hogy az itemek atlagos kommunalitasa legalabb 0.6 legyen. A mi esetunkben ennel megengedobbek is lehetunk, mert az elemszamunk nagyobb, de egy melyebb faktorelemzes eseten igy is erdemes lehet elgondolkodni a rosszul reprezentalt itemek kizarasan.	

# MacCallum, R. C., Widaman, K. F., Zhang, S., & Hong, S. (1999). Sample size in factor analysis. Psychological methods, 4(1), 84.	


	
EFA_mod1 <- fa(hsq_correl, nfactors = 5, fm="pa")	
	
# Sorted communality 	
EFA_mod1_common <- as.data.frame(sort(EFA_mod1$communality, decreasing = TRUE))	
EFA_mod1_common 	
	
mean(EFA_mod1$communality)	
	



# ## Idealis faktorszam kivalasztasa	

# A fokomponenselemzeshez hasonloan meg kell hataroznunk, hany faktort szeretnenk kinyerni az adatokbol. Ahogy azt a fokomponenselemzesnel is lattuk, ennek az eldontesere hasznalhatjuk a scree-tesztet, a Kaiser-Guttman kriteriumot, vagy a parallel tesztet. Ezen felul a psych pacakge ket ujabb modszert is felkinal a donteshozas elosegitesere: a very simple structure (VSS) kriteriumot, es a Wayne Velicer's Minimum Average Partial (MAP) kriteriumot. (A vss() funkcio a psych package-ben)	

# Az alabbi peldaban a psych package fa.parallel funciojat es az nfactors funkciot hasznaljuk arra, hogy a kulonbozo kriteriumok szerint eldonthessuk, hany faktor megtartasa lenne idealis.	

# A kulonbozo technikak altal javasolt idealis faktorszamok a kovetkezok:	

# - scree-tesztet: 4	
# - Kaiser-Guttman kriterium: 4	
# - Parallel tesztet: 7	
# - VSS: 3-4	
# - MAP: 4	

# Ezek alapjan ugy tunik, a legtobb technika szerint 4 latens faktor irja le az adatok variabilitasat a legjobban. Alabb meg is epitjuk ezt a 4-faktoros modellt, es megvizsgaljuk a kommunalitas-tablazatot. A faktorelemzes soran nagyon gyakori, hogy a folyamatot ujra es ujra megismeteljuk kulonbozo bemeneti valtozokkal es kulonozo faktorszamokkal es rotacios modszerekkel, amig elerjuk a veglegesnek tekintheto faktorstrukturat. A vegleges faktorstruktura idealis esetben jol ertelmezheto a faktorok es a hozzajuk tartozo valtozo-toltesek alapjan.	


	
	
fa.parallel(hsq_correl, n.obs = nrow(hsq),	
        fa = "fa", fm = "pa")	
	
nfactors(hsq_correl, n.obs = nrow(hsq))	
	
EFA_mod2 <- fa(hsq_correl, nfactors = 4, fm="pa")	
	
EFA_mod2_common <- as.data.frame(sort(EFA_mod2$communality, decreasing = TRUE))	
EFA_mod2_common 	
	
mean(EFA_mod2$communality)	
	
	




# ## Faktorforgatas	
#  	
# A faktorforgatas celja hogy megkonnyitse a faktorok ertelmezeset. Igy elkerulheto hogy az egesz faktorstruktura 1 vagy ket nagyon dominans faktorbol alljon, amire angyon erosek a toltesek, mig a tobbi faktor ertelmezese kodos. A faktorforgatas soran az eredeti valtozok ugyan ott maradnak a "faktorterben", viszont a faktorok dimenzio tengelyeit elforgatjuk, hogy jobban railleszkedjenek egyes valtozocsoportokra. 	

# A faktorforgatasnak szamos modszere ismert, de ezek ket fo csoportba sorolhatok: ortogonalis es oblique modszerek koze. Az ortogonalis modszerek (mint pl. Quartimax, Equimax, vagy a pszichologiaban leggyakrabban hasznalt **Varimax** modszer) soran a faktor dimenziok egymasra merolegesek maradnak (ez azt jelenti hogy egymassal nem korrelalnak majd a vegso faktorok). Az oblique modszerek (mint pl. **Direct Oblimin** vagy a Promax) eseten viszont megengedett hogy a vegso faktorok valamellyest korrelaljanak egymassal. Az exploratoros faktorelemzes soran tobb modszert is kiprobalhatunk, de itt fontos az elmeleti megalapozottsag is. Elkepzelheto hogy a faktorok korrelaljanak egymassal? Ha igen, akkor az oblique modszerekre erdemes hagyatkozni. (Altalaban a korrelalatlan faktorokat konnyebb ertelmezni).	

# Az alapertelmezett faktorforgatasi modszer a Direct Oblimin ("oblimin"). Probaljuk ki a Promax ("promax) es a Varimax ("varimax") modszereket is.	



	
EFA_mod2$rotation	
	
EFA_mod_promax <- fa(hsq_correl, nfactors = 4, fm="pa", rotate = "promax")	
	
EFA_mod_varimax <- fa(hsq_correl, nfactors = 4, fm="pa", rotate = "varimax")	
	


# ## Faktorok interpretacioja	

# A faktorok ertelmezese nem konnyu feladat. Sok teruletspecifikus tudasra van szuseg a helyes faktrostruktura kivalasztasahoz es a helyes faktorertelmezeshez. Itt ezert csak a kulonbozo vizualizacios modszereket mutatjuk be amik segithetnek a faktorok ertelmezeseben.	

# Az fa.diagram() funkcio kirajzolja a model objektum alapjan a faktorstrukturat, es azt, hogy melyik valtozo melyik faktorra mutatja a legnagyobb faktortoltest (melyik faktorral a legnagyobb a korrelacioja). Az abran lathatoak az egyes korrelacios egyutthatok is. A fekete nyilak pozitiv, mig a piros nyilak negativ korrelaciokat jeleznek. 	

# Tovabbi segitseget nyujthat a sajat funkcio amit a fokomponsneselemzesnel is hasznaltunk: fviz_loadnings_with_cor(). Itt a fa() modelek eseten megadhatjuk a loading_above = parameterst is, ahol specifikalhatjuk, hogy csak a bizonyos abszolut faktortoltes (korrelacio) feletti megfigyelt valtozokat abrazoljuk. Ez megkonnyitheti az abra atlathatosagat.	


	
fa.diagram(EFA_mod2)	
	
fviz_loadnings_with_cor(EFA_mod2, axes = 1, loadings_above = 0.4)	
	
fviz_loadnings_with_cor(EFA_mod2, axes = 2, loadings_above = 0.4)	
	
fviz_loadnings_with_cor(EFA_mod2, axes = 3, loadings_above = 0.4)	
	
fviz_loadnings_with_cor(EFA_mod2, axes = 4, loadings_above = 0.4)	
	
	




# **___________________Gyakorlas___________________**	

# A fent tanult technikakat a Big Five Inventory (bfi) adatbazison gyakorolhatod. Ez a psych package-be beepitett adatbazis, ami 2800 szemely valaszait tartalmazza a Big Five szemelyisegkerdoiv kerdeseira. Az elso 25 oszlop a kerdoiv kerdeseire adott valaszokat tartalmazza, az utolso harom oszlop (gender, education, es age) pedig demografiai kerdeseket tartalmaz. A reszleteket az egyes itemekhez tartozo kerdesekrol es a valaszok kodolasarol elolvashatod ha lefuttatod a ?bfi parancsot.	

# Az adatbazist betoltheted a kovetkezo parancsokkal. 	


	
?bfi	
	
data(bfi)	
my_data_bfi = bfi[,1:25]	
	
	


# Ebben a feladatban csak az elso 25 oszlopot hasznald, az eredeti kerdoiv kerdeseit. Vegezz el feltaro faktorelemzest, es ez alapjan hatarozd meg, hany faktor megtartasa az idealis, mely faktorokra mely itemek toltenek leginkabb, es ez alapjan hogyan nevezned el a faktorokat. Melyek a faktorstruktura altal leginkabb es a legkevesbe reprezentalt itemek?	

# **_______________________________________________**	

