################################################################################
## Script para el �nalisis de datos con datos de c�maras tramapa ###############
########## Por Cristian Barros-Diaz ############################################
################################################################################
################################################################################

#Este paquete proporciona un flujo de trabajo optimizado para procesar 
#los datos generados en estudios de vida silvestre basados en c�maras trampa 
#y prepara la entrada para an�lisis adicionales, particularmente en los marcos
#de ocupaci�n y captura-recaptura espacial. Sugiere una estructura de datos 
#simple y proporciona funciones para administrar fotograf�as (y videos) de 
#trampas de c�maras digitales, generar tablas de registro, mapas de riqueza 
#de especies y detecciones de especies y diagramas de actividad de especies

rm(list = ls()) #Sirve para limpiar el entorno en R


#Solo se instala la primera vez 
#install.packages("camtrapR")
#install.packages("exiftoolr")


#Se corre cada vez que se abre R
library("camtrapR") 
library("exiftoolr") 

#Se inicia diciendole a R donde buscar Exitool

exiftool_dir <-"C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Exiftool"

exiftoolPath (exiftoolDir = exiftool_dir)

#Sys.which("exiftool.exe") Sirve para saber si R ley� el software

#Muchas gu�as sugieren descomprimir y alojar el programa en la carpeta
#Windows, pero con la funcion anterior le estamos diciendo a R, donde 
#debe buscar el programa



###############################################
#Si hay un error en la fecha y hora de las fotos, se puede corregir
#con las siguientes funciones

#Primero se debe decirle a R donde debe buscar.
setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Correcion fotos") 


fotos_correcion_AE <- file.path("Fecha fotos")


Tabla_correci�n_AE <- read.csv("Correci�n fecha y hora.csv", header = TRUE)


Fotos_correcion_AE <- timeShiftImages(inDir = fotos_correcion_AE,
                                         timeShiftTable = Tabla_correci�n_AE,
                                         stationCol = "Station", 
                                         hasCameraFolders = FALSE,
                                         timeShiftColumn = "timeshift",
                                         timeShiftSignColumn = "sign",
                                         undo = F)




#########
#Un aspecto importante es que las fotos deben ser renombradas primero y despu�s
#clasificadas por especie, si se hace a la inversa se pierde la clasificaci�n cuando 
#las fotos son copiadas a la nueva carpeta. Las carpetas de c�maras que no contengan
#fotos no ser�n copiadas a la carpeta de fotos renombradas.

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR") 


fototrampeo_AE <- file.path("Fotos original")

fotos_renombradas_AE <- file.path("Fotos renombradas")


carpeta_renombradas_AE <- imageRename(inDir = fototrampeo_AE,
                                              outDir = fotos_renombradas_AE,
                                              hasCameraFolders = FALSE,
                                              keepCameraSubfolders = FALSE,
                                              copyImages = TRUE)

#Otro aspecto importante es que se recomienda guardar a parte las fotos originales 
#que fueron extra�das de las tarjetas SD. La carpeta con las fotos renombradas no 
#puede ser guardada dentro de la carpeta principal, debe colocarse en un directorio 
#diferente. Una vez que las fotos fueron renombradas, se puede agregar a los metadatos
#de cada foto el nombre del proyecto y la instituci�n a la que pertenecen.


proyecto_CHo_Colonche <- "Proyecto Cordillera Chongon Colonche"

addCopyrightTag(inDir = fotos_renombradas_AE,
                copyrightTag = proyecto_CHo_Colonche,
                askFirst = FALSE)

#Para verificar que aparece la informaci�n en los metadatos se utiliza la siguiente 
#funci�n y se pueden visualizar los metadatos:

exifTagNames(fotos_renombradas_AE, returnMetadata = TRUE)

################################################################################
#�nalisis de datos##############################################################
################################################################################


#Se debe definir la carpeta donde se han ubicado las fotos por estaciones
#y en cada estaci�n por especie

CT_fotos_AE <- "C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Fotos/AEN"

#Definir la carpeta donde se grabaran los resultados

out_dir <- "C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs"

#Primero se debe decirle a R donde debe buscar la tabla

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/CT operation") 

#Cargar la tabla de operacion de cada localidad,las localidades no deben contener espacios

camtraps_2021_AE <- read.csv("Hoja de datos AE.csv", h=T)
head(camtraps_2021_AE)

#Crear la matriz de operacion de las camaras limpiar tabla, solo dejar las columnas necesarias

CTtable_2021_AE <- cameraOperation(CTtable      = camtraps_2021_AE, 
                                          stationCol   = "Station",              
                                          setupCol     = "Setup_date",          
                                          retrievalCol = "Retrieval_date",      
                                          hasProblems  = F,            #True cuando hubo problemas con las c?maras
                                          dateFormat   = "%d/%m/%Y",    
                                          writecsv     = T,
                                          outDir = out_dir)                    


#Extracion de datos

RecordTable_AE <- recordTable(inDir = CT_fotos_AE,
                                     IDfrom = "directory", #leer la identificaci�n de especies de las etiquetas
                                     minDeltaTime = 60,  #diferencia horaria entre registros de la misma especie en la misma estaci�n
                                     deltaTimeComparedTo = "lastRecord", #Para que dos eventos se consideren independientes
                                     exclude = c("No Id", "No especies","People", "Aves","Birds", "Gente", "Gente","No species","Video", "Videos", "Cattles","Cattle","roedores","Rodents", "Stenocercus iridescens", "Holcosus septemlineatus","Reptiles", "Simosciurus nebouxii", "Nada"),
                                     timeZone = "America/Lima",
                                     metadataSpeciesTag = "Species", 
                                     writecsv = T, 
                                     removeDuplicateRecords = T,
                                     outDir = out_dir) # #al no usar out_dir Recordtable aparece en la carpeta de fotos

head(RecordTable_AE) 

nrow(RecordTable_AE) #N�mero final de registros (independientes)

str(RecordTable_AE) #Que hay aqui?
head(RecordTable_AE)

#Se debe abrir Record Table
RecordTable_AE <- read.csv(file.choose(), sep=",", h=T) #record table


#tabular el n�mero de detecciones por especie
(Eventos_Independientes_por_especies <- as.data.frame(table(RecordTable_AE$Species)))

(names(Eventos_Independientes_por_especies) <- c("Especies","N_obs"))
Eventos_Independientes_por_especies

#Ahora le decimos a R que debe guardar en outputs - recordatable

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs/Record table") 
write.csv(Eventos_Independientes_por_especies, "Eventos Independientes por especies.csv")


#tabular el n�mero de detecciones por especie y estaci�n

(Especies_por_estacion <- table(RecordTable_AE$Species, RecordTable_AE$Station))

write.csv(Especies_por_estacion, "Especies por estacion.csv")

#tabular el n�mero de detecciones por estaci�n y especie

(Estaci�n_por_especie <- table(RecordTable_AE$Station, RecordTable_AE$Species))

write.csv(Estaci�n_por_especie, "Estaci�n por especie.csv")


#Crear un reporte por cada muestreo

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs")

SurveyReport_2021_AE <- surveyReport (recordTable = RecordTable_AE,
                                       CTtable = camtraps_2021_AE,
                                       speciesCol = "Species",
                                       stationCol = "Station",
                                       setupCol = "Setup_date",
                                       retrievalCol = "Retrieval_date",
                                       CTDateFormat = "%d/%m/%Y",
                                       recordDateTimeCol = "DateTimeOriginal",
                                       recordDateTimeFormat = "%Y-%m-%d %H:%M:%S",
                                       CTHasProblems = FALSE,
                                       Xcol = "Long",
                                       Ycol = "Lat",
                                       sinkpath = out_dir)


str(SurveyReport_2021_AE)


(Reporte_especies_por_estacion <- SurveyReport_2021_AE$species_by_station)
write.csv(Reporte_especies_por_estacion, "Reporte especies por estacion.csv")


(Reporte_Eventos_por_especies <- SurveyReport_2021_AE$events_by_species)
write.csv(Reporte_Eventos_por_especies, "Reporte Eventos por especie.csv")

(Reporte_Eventos_por_especies2 <- SurveyReport_2021_AE$events_by_station2)
write.csv(Reporte_Eventos_por_especies2, "Reporte Eventos por especie 2.csv")



################################################################################
#Crear mapas y diagramas de actividades#########################################
################################################################################

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/")

sppPlots <- file.path("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Plot especies") 

spRichness <- detectionMaps(CTtable = camtraps_2021_AE,
                            recordTable = RecordTable_AE,
                            Xcol = "Long",
                            Ycol = "Lat",
                            #speciestoshow = Leopardus pardalis #especies a incluir en los mapas. si falta, todas las especies
                            printLabels = TRUE, #agregar etiquetas de estaci?n a las parcelas
                            writePNG = TRUE, #escribir un archivo PNG con el mapa (en el directorio de trabajo)
                            plotDirectory = sppPlots) #guardar la imagen en el directorio de trabajo  



#################################################################################
#Curva de acumulaci�n############################################################
#################################################################################


#install.packages("BiodiversityR")
library("BiodiversityR")


(C_Acumulacion <- table(RecordTable_AE$Station, RecordTable_AE$Species))

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs/Curva de acumulaci�n de especies")
write.csv(C_Acumulacion, "C_Acumulacion.csv")


C_Acumulacion<-read.csv("C_Acumulacion.csv", header=T, row.names=1)
names(C_Acumulacion)

#Cada columna de la matriz son los registros independientes de 23 especies 
#de mam�feros medianos y grandes en 15 c�maras-trampa, las cuales ser�n usadas 
#como medida de esfuerzo de muestreo.

#Con la funcion collector nos muestra el n�mero de especies registradas por c�mara, 
#en el orden en que est�n los datos.

Curva_Acumulacion_Collector <- accumresult(C_Acumulacion, method="collector")
plot(Curva_Acumulacion_Collector, las= 1, col= "black")


#ranndom - aleatorio" agrega sitios en orden aleatorio

Curva_Acumulacion_random <- accumresult(C_Acumulacion, method="random")
plot(Curva_Acumulacion_random, las= 1, col= "black")

#exact - encuentra la riqueza esperada (media) de especies

Curva_Acumulacion_exact <- accumresult(C_Acumulacion, method="exact")
plot(Curva_Acumulacion_exact, las= 1, col= "black")

#coleman - encuentra la riqueza esperada siguiendo a Coleman et al. 1982

Curva_Acumulacion_coleman <- accumresult(C_Acumulacion, method="coleman")
plot(Curva_Acumulacion_coleman, las= 1, col= "black")

#rarefaction - encuentra la media cuando se acumulan individuos en los lugares de muestreo

(Curva_Acumulacion_rarefaction <- accumresult(C_Acumulacion, method="rarefaction"))
par(mfcol=c(1,1), mar=c(5,5,5,5))
Curva_Acumulacion_rarefaction2 <- plot(Curva_Acumulacion_rarefaction, ci.type="polygon", 
                                       ylim=c(0,25), 
                                       xlim=c(0,15), 
                                       lwd=1, 
                                       ci.lty=0, 
                                       ci.col="gray80", 
                                       last=1,frame.plot=F, 
                                       pch = 1, 
                                       cex.lab = 1, 
                                       cex.axis = 1,
                                       col="black", 
                                       las=1,
                                       main = "Curva de acumulaci�n", 
                                       xlab = "Estaciones", 
                                       ylab = "Especies") 



#La edici�n y calidad de las gr�ficas puede mejorarse mediante los siguientes codigos:

#Para guardar el gr�fico
setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Curvaacumulaci�n")

png("Curva Acumulacion rarefaction.png")

par(mfcol=c(1,1), mar=c(5,5,5,5))
plot(Curva_Acumulacion_rarefaction, 
     ci.type="polygon", 
     ylim=c(0,25), 
     xlim=c(0,16), 
     lwd=1, 
     ci.lty=0, 
     ci.col="gray80", 
     last=1,frame.plot=F, 
     pch = 1, 
     cex.lab = 1, 
     cex.axis = 1,
     col="black", 
     las=1,
     main = "Curva de acumulaci�n Las Balsas", 
     xlab = "C�maras trampa", 
     ylab = "Especies")


dev.off()

###############################################################################
#Evaluar el patr�n de actividad usando la densidad kernel######################
###############################################################################


#El estimador de densidad por Kernel (EDK) resuelve los inconvenientes del origen, 
#discontinuidad y se pueden implementar estimadores con un ancho de intervalo 
#ajustable al n�mero de datos, adem�s evita la subjetividad del an�lisis ya que 
#funciona como una gu�a para desprender al investigador de una selecci�n arbitraria
#del origen del histograma o pol?gono de frecuencia a utilizar (Salgado-Ugarte, 
#2002; Sanvicente-A?orve et al., 2003)


Graficos_activityDensity <- file.path("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Patrones de actividad/ActivityDensity")

P_A_activityDensity <- activityDensity (recordTable = RecordTable_AE,
                                         #species = "Leopardus pardalis", 
                                           allSpecies = TRUE,
                                           xlab = "Hora", 
                                           ylab = "Densidad",
                                           recordDateTimeFormat = "%d/%m/%Y %H:%M",
                                           writePNG = TRUE, 
                                           plotDirectory = Graficos_activityDensity)

#Histograma del n�mero de fotos por hora

Graficos_activityHistogram <- file.path("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Patrones de actividad/ActivityHistogram")

P_A_activityHistogram <- activityHistogram(recordTable = RecordTable_AE, 
                                            #species = "Leopardus pardalis",
                                            allSpecies = TRUE,
                                            xlab = "Hora", 
                                            ylab = "Densidad",
                                            recordDateTimeFormat = "%d/%m/%Y %H:%M",
                                            writePNG = TRUE,
                                            plotR = TRUE,
                                            plotDirectory = Graficos_activityHistogram)

#Gr�fica circular 

Graficos_activityRadial <- file.path("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Patrones de actividad/ActivityRadial")

P_A_activityRadial <- activityRadial(recordTable = RecordTable_AE2,
                                     #species = "Leopardus pardalis",
                                     allSpecies = TRUE,
                                     lwd = 3,
                                     line.col= "blue", 
                                     cex.lab= 0.5,
                                     writePNG = TRUE, 
                                     plotR = TRUE,
                                     plotDirectory = Graficos_activityRadial)


#Para comparar los patrones, es un poco m�s largo

Graficos_Comparativos <- file.path("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Patrones de actividad/Comparativos")

P_A_Ocelote_Paca <- activityOverlap(recordTable = RecordTable_AE,
                                    speciesA = "Leopardus pardalis",
                                    speciesB = "Cuniculus paca",
                                    writePNG = TRUE,
                                    plotDirectory = Graficos_Comparativos,
                                    plotR = TRUE,
                                    addLegend = TRUE,
                                    legendPosition = "topright",
                                    linecol = c("grey", "black"),
                                    linewidth = c(3,3),
                                    add.rug = TRUE,
                                    xlab = "Hora",
                                    ylab = "Densidad",
                                    ylim = c(0,0.25))



################################################################################
#Estimaci�n de riqueza y diversidad "Vegan"#####################################
################################################################################

#Llevaremos a cabo un analisis de diversidad usando �ndices y la serie de Hill. 

#-Serie de n�meros de Hill- Es una serie de n�meros que permiten calcular el n�mero efectivo 
#de especies en una muestra, es decir, una medida del n�mero de especies cuando cada especie 
#es ponderada por su abundancia relativa (Hill, 1973; Magurran, 1988)

#El paquete Vegan contiene analisis de diversidad, ordenaci�n de comunidades y 
#analisis de disimiluitud.

#Primero se debe decirle a R donde debe buscar la tabla.
setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs") 

#install.packages("labdsv")
#install.packages("ade4")
#install.packages("BiodiversityR")
#install.packages("vegan")

library("labdsv")
library("ade4")
library("BiodiversityR")
library("vegan")


#Cargar la matriz de datos, debe ser especies vs estaciones (Recuerda eventos independientes)

Analisis_de_diversidad_sp <- read.csv("Especies por estacion.csv", row.names = 1)
Analisis_de_diversidad_sp


#Riqueza es�c�fica (N0) - N�mero total de eventos independientes por especie

(N0 <- rowSums(Analisis_de_diversidad_sp >0))


#�ndice de Shannoner-Wiener

�ndiceSW_sp <- diversity(Analisis_de_diversidad_sp, index = "shannon")
(round(�ndiceSW_sp,2))                        

#"shannon", "simpson" or "invsimpson"

#Equidad de Pielou

(EP_sp <- round(�ndiceSW_sp/log(N0), 2))

#Serie de n�meros de Hill

(N1 <- round(exp(�ndiceSW_sp), 2))


#Media
mean(N0)

#Desviaci�n

sd(N0)

#Serie de n�meros de Hill
mean(N1)

sd(N1)

#AHORA POR ESTACI�N!
#Cargar la matriz de datos, debe ser especies vs estaciones (Recuerda eventos independientes)

Analisis_de_diversidad_Estacion <- read.csv("Spp_por_especie.csv", row.names = 1)
Analisis_de_diversidad_Estacion


#Riqueza es�c�fica (N0) - N�mero total de eventos independientes por especie

(N0 <- rowSums(Analisis_de_diversidad_Estacion >0))


#�ndice de Shannoner-Wiener

�ndiceSW_Estacion <- diversity(Analisis_de_diversidad_Estacion, index = "shannon")
(round(�ndiceSW_Estacion,2))                        




################################################################################
#Inter/extrapolaci�n de diversidad: iNEXT#######################################
################################################################################


#Debido a la dificultad al intentar comparar los distintos tipos de indices,
#Hill(1973) sugiri� realizar transformaciones matem�ticas a los indices, denominada
#serie de n�meros de diversidad Hill, siendo cada vez m�s utilizados para cuantificar
#la diversidad taxonomica, ya que estadisticamente m�s riguroso.

#INEXT proporcina funciones simples para calcular y graficar curvas de muestreo
#basadas en el tama�o de la muestra, cobertura y datos de abundancia e incidencia relativa.


#DIVERSIDAD DE HILL - Est�n parametrizados por un orden de diversidad q, que determina
#la sensibilidad de las medidas a las abundancias relativas de las especies:

#Diversidad del orden 0, (q = 0) = Da el mismo peso a todas las especies (riqueza de especies)
#Diversodad del orden 1, (q = 1) = Da m�s peso a las especies comunes (D. Shannon)
#Diversidad del orden 2, (q = 2) = Da m�s peso a las especies abundantes (D. Simpson)

#El inventario es avaluado mediante la cobertura de la muestra, que mide proporci�n del n�mero 
#total de individuos en una comunidad que pertenece a las representadas en la muestra


#Funciones de iNEXT: Rerefacci�n/extrapol


install.packages("iNEXT")

library(iNEXT)
library(ggplot2)


#se procede a cargar los datos

(Curva_abudancia_LB <- read.table(file = "Especies por estacion.csv",
                                 header = T, sep = ","))

#Se debe eliminar la columna Especie para poder trabajar las variables

(Curva_abudancia_LBM <- (Curva_abudancia_LB [,2:16]))
  
#Se debe dar valor de extrapolaci�n (doble de eventos)

(t <- seq(1,834))

#Luego se ejecuta el �nalisis


(analisisInext <- iNEXT(Curva_abudancia_LBM, q = 0, datatype = "abundance"))


lapply(analisisInext, function(x) write.table(data.frame(x), "analisisInext.csv", 
                                               append= T, sep= ","))

#Gr�fico iNext

#Basado en el tama�o de la muestra: Representa las estimaciones de diversidad
#con intervalo de confianza


graficoinext1 <- ggiNEXT(analisisInext, type = 1, se = T,
                        color.var = "site", grey = F) +
                        theme_classic(base_size = 14) +
                         theme(legend.position = "bottom",
                            text = element_text(size = 10),
                             legend.title = element_blank()) +
                               labs (x = "N�mero de individuos",
                                     y = "Diversidad de especies") 
              

#Curva de cobertura de la muestra o completitud del muestreo, con
#intervalos de confianza. Traza la cobertura de muestra con respecto al 
#tama�o de la muestra para el mismo rango descrito en el tipo 1

(graficoinext2 <- ggiNEXT(analisisInext, type = 2, se = T,
                         color.var = "site", grey = F) +
                         theme_classic(base_size = 12) +
                         theme(legend.position = "bottom",
                               text = element_text(size = 12),
                               legend.title = element_blank()) +
                         labs (x = "N�mero de individuos",
                              y = "Cobertura de muestra")) 

#Curva de R/E basada en la cobertura de la muestra


(graficoinext2 <- ggiNEXT(analisisInext, type = 3, se = T,
                          color.var = "site", grey = F) +
                          theme_classic(base_size = 12) +
                          theme(legend.position = "bottom",
                                text = element_text(size = 12),
                                legend.title = element_blank()) +
                                labs (x = "N�mero de individuos",
                                      y = "Diversidad de especie")) 




################################################################################
#Crear un historial de detecci�n de especies para el an�lisis de ocupaci�n######
################################################################################

Historial_de_deteccion_por_especie <- "C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs/Historial de deteccion por especie"

(Historia_CT_ocelote <- detectionHistory(recordTable = RecordTable_AE,
                                camOp = CTtable_2021_AE,
                                species = "Leopardus pardalis",#La especie para la cual se calcula el historial de detecci?n
                                speciesCol = "Species",
                                stationCol = "Station",
                                recordDateTimeCol = "DateTimeOriginal",
                                recordDateTimeFormat = "%Y-%m-%d %H:%M:%S",
                                timeZone = "America/Lima",
                                occasionLength = 1, #Duraci�n de la ocasi�n de muestreo en d�as
                                day1 = "station", #las ocasiones donde comienzan la fecha de configuraci?n de la estaci?n
                                includeEffort = FALSE, #Calcular el esfuerzo de captura (n?mero de d?as de captura de c?mara activa por estaci?n y ocasiones
                                scaleEffort = FALSE, #No escale y centre la matriz de esfuerzo
                                writecsv = TRUE,
                                outDir = Historial_de_deteccion_por_especie))


#Vea el historial de detecci�n de Leopardus pardalis. Esto se escribe autom�ticamente en csv seg�n lo anterior

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Ocupacion")

Historia_CT_ocelote
write.csv(Historia_CT_ocelote, "Historia CT ocelote.csv")


#An�lisis de ocupaci�n. Se calcula las probabilidades de ocupaci�n y detecci�n espec�ficas de covariables

#install.packages("unmarked")
#install.packages("ggplot2")

library("unmarked")
library("ggplot2")

LasBalsas_ocupacion_Ocelote <- read.csv("Historia CT ocelote.csv") 

(Detectabilidad <- LasBalsas_ocupacion_Ocelote[,-1])
Detectabilidad


Detectabilidad_LasBalsas <- unmarkedFrameOccu(y = Detectabilidad) 
summary(Detectabilidad_LasBalsas)


################################################################################
#Funci�n para crear una grid de c�maras-trampa para el campo####################
################################################################################














































