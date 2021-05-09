################################################################################
## Script para el ánalisis de datos con datos de cámaras tramapa ###############
########## Por Cristian Barros-Diaz ############################################
################################################################################
################################################################################

#Este paquete proporciona un flujo de trabajo optimizado para procesar 
#los datos generados en estudios de vida silvestre basados en cámaras trampa 
#y prepara la entrada para análisis adicionales, particularmente en los marcos
#de ocupación y captura-recaptura espacial. Sugiere una estructura de datos 
#simple y proporciona funciones para administrar fotografías (y videos) de 
#trampas de cámaras digitales, generar tablas de registro, mapas de riqueza 
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

#Sys.which("exiftool.exe") Sirve para saber si R leyó el software

#Muchas guías sugieren descomprimir y alojar el programa en la carpeta
#Windows, pero con la funcion anterior le estamos diciendo a R, donde 
#debe buscar el programa



###############################################
#Si hay un error en la fecha y hora de las fotos, se puede corregir
#con las siguientes funciones

#Primero se debe decirle a R donde debe buscar.
setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Correcion fotos") 


fotos_correcion_AE <- file.path("Fecha fotos")


Tabla_correción_AE <- read.csv("Correción fecha y hora.csv", header = TRUE)


Fotos_correcion_AE <- timeShiftImages(inDir = fotos_correcion_AE,
                                         timeShiftTable = Tabla_correción_AE,
                                         stationCol = "Station", 
                                         hasCameraFolders = FALSE,
                                         timeShiftColumn = "timeshift",
                                         timeShiftSignColumn = "sign",
                                         undo = F)




#########
#Un aspecto importante es que las fotos deben ser renombradas primero y después
#clasificadas por especie, si se hace a la inversa se pierde la clasificación cuando 
#las fotos son copiadas a la nueva carpeta. Las carpetas de cámaras que no contengan
#fotos no serán copiadas a la carpeta de fotos renombradas.

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR") 


fototrampeo_AE <- file.path("Fotos original")

fotos_renombradas_AE <- file.path("Fotos renombradas")


carpeta_renombradas_AE <- imageRename(inDir = fototrampeo_AE,
                                              outDir = fotos_renombradas_AE,
                                              hasCameraFolders = FALSE,
                                              keepCameraSubfolders = FALSE,
                                              copyImages = TRUE)

#Otro aspecto importante es que se recomienda guardar a parte las fotos originales 
#que fueron extraídas de las tarjetas SD. La carpeta con las fotos renombradas no 
#puede ser guardada dentro de la carpeta principal, debe colocarse en un directorio 
#diferente. Una vez que las fotos fueron renombradas, se puede agregar a los metadatos
#de cada foto el nombre del proyecto y la institución a la que pertenecen.


proyecto_CHo_Colonche <- "Proyecto Cordillera Chongon Colonche"

addCopyrightTag(inDir = fotos_renombradas_AE,
                copyrightTag = proyecto_CHo_Colonche,
                askFirst = FALSE)

#Para verificar que aparece la información en los metadatos se utiliza la siguiente 
#función y se pueden visualizar los metadatos:

exifTagNames(fotos_renombradas_AE, returnMetadata = TRUE)

################################################################################
#Ánalisis de datos##############################################################
################################################################################


#Se debe definir la carpeta donde se han ubicado las fotos por estaciones
#y en cada estación por especie

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
                                     IDfrom = "directory", #leer la identificación de especies de las etiquetas
                                     minDeltaTime = 60,  #diferencia horaria entre registros de la misma especie en la misma estación
                                     deltaTimeComparedTo = "lastRecord", #Para que dos eventos se consideren independientes
                                     exclude = c("No Id", "No especies","People", "Aves","Birds", "Gente", "Gente","No species","Video", "Videos", "Cattles","Cattle","roedores","Rodents", "Stenocercus iridescens", "Holcosus septemlineatus","Reptiles", "Simosciurus nebouxii", "Nada"),
                                     timeZone = "America/Lima",
                                     metadataSpeciesTag = "Species", 
                                     writecsv = T, 
                                     removeDuplicateRecords = T,
                                     outDir = out_dir) # #al no usar out_dir Recordtable aparece en la carpeta de fotos

head(RecordTable_AE) 

nrow(RecordTable_AE) #Número final de registros (independientes)

str(RecordTable_AE) #Que hay aqui?
head(RecordTable_AE)

#Se debe abrir Record Table
RecordTable_AE <- read.csv(file.choose(), sep=",", h=T) #record table


#tabular el número de detecciones por especie
(Eventos_Independientes_por_especies <- as.data.frame(table(RecordTable_AE$Species)))

(names(Eventos_Independientes_por_especies) <- c("Especies","N_obs"))
Eventos_Independientes_por_especies

#Ahora le decimos a R que debe guardar en outputs - recordatable

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs/Record table") 
write.csv(Eventos_Independientes_por_especies, "Eventos Independientes por especies.csv")


#tabular el número de detecciones por especie y estación

(Especies_por_estacion <- table(RecordTable_AE$Species, RecordTable_AE$Station))

write.csv(Especies_por_estacion, "Especies por estacion.csv")

#tabular el número de detecciones por estación y especie

(Estación_por_especie <- table(RecordTable_AE$Station, RecordTable_AE$Species))

write.csv(Estación_por_especie, "Estación por especie.csv")


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
#Curva de acumulación############################################################
#################################################################################


#install.packages("BiodiversityR")
library("BiodiversityR")


(C_Acumulacion <- table(RecordTable_AE$Station, RecordTable_AE$Species))

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/outputs/Curva de acumulación de especies")
write.csv(C_Acumulacion, "C_Acumulacion.csv")


C_Acumulacion<-read.csv("C_Acumulacion.csv", header=T, row.names=1)
names(C_Acumulacion)

#Cada columna de la matriz son los registros independientes de 23 especies 
#de mamíferos medianos y grandes en 15 cámaras-trampa, las cuales serán usadas 
#como medida de esfuerzo de muestreo.

#Con la funcion collector nos muestra el número de especies registradas por cámara, 
#en el orden en que están los datos.

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
                                       main = "Curva de acumulación", 
                                       xlab = "Estaciones", 
                                       ylab = "Especies") 



#La edición y calidad de las gráficas puede mejorarse mediante los siguientes codigos:

#Para guardar el gráfico
setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Graficos/Curvaacumulación")

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
     main = "Curva de acumulación Las Balsas", 
     xlab = "Cámaras trampa", 
     ylab = "Especies")


dev.off()

###############################################################################
#Evaluar el patrón de actividad usando la densidad kernel######################
###############################################################################


#El estimador de densidad por Kernel (EDK) resuelve los inconvenientes del origen, 
#discontinuidad y se pueden implementar estimadores con un ancho de intervalo 
#ajustable al número de datos, además evita la subjetividad del análisis ya que 
#funciona como una guía para desprender al investigador de una selección arbitraria
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

#Histograma del número de fotos por hora

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

#Gráfica circular 

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


#Para comparar los patrones, es un poco más largo

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
#Estimación de riqueza y diversidad "Vegan"#####################################
################################################################################

#Llevaremos a cabo un analisis de diversidad usando índices y la serie de Hill. 

#-Serie de números de Hill- Es una serie de números que permiten calcular el número efectivo 
#de especies en una muestra, es decir, una medida del número de especies cuando cada especie 
#es ponderada por su abundancia relativa (Hill, 1973; Magurran, 1988)

#El paquete Vegan contiene analisis de diversidad, ordenación de comunidades y 
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


#Riqueza esécífica (N0) - Número total de eventos independientes por especie

(N0 <- rowSums(Analisis_de_diversidad_sp >0))


#Índice de Shannoner-Wiener

ÍndiceSW_sp <- diversity(Analisis_de_diversidad_sp, index = "shannon")
(round(ÍndiceSW_sp,2))                        

#"shannon", "simpson" or "invsimpson"

#Equidad de Pielou

(EP_sp <- round(ÍndiceSW_sp/log(N0), 2))

#Serie de números de Hill

(N1 <- round(exp(ÍndiceSW_sp), 2))


#Media
mean(N0)

#Desviación

sd(N0)

#Serie de números de Hill
mean(N1)

sd(N1)

#AHORA POR ESTACIÓN!
#Cargar la matriz de datos, debe ser especies vs estaciones (Recuerda eventos independientes)

Analisis_de_diversidad_Estacion <- read.csv("Spp_por_especie.csv", row.names = 1)
Analisis_de_diversidad_Estacion


#Riqueza esécífica (N0) - Número total de eventos independientes por especie

(N0 <- rowSums(Analisis_de_diversidad_Estacion >0))


#Índice de Shannoner-Wiener

ÍndiceSW_Estacion <- diversity(Analisis_de_diversidad_Estacion, index = "shannon")
(round(ÍndiceSW_Estacion,2))                        




################################################################################
#Inter/extrapolación de diversidad: iNEXT#######################################
################################################################################


#Debido a la dificultad al intentar comparar los distintos tipos de indices,
#Hill(1973) sugirió realizar transformaciones matemáticas a los indices, denominada
#serie de números de diversidad Hill, siendo cada vez más utilizados para cuantificar
#la diversidad taxonomica, ya que estadisticamente más riguroso.

#INEXT proporcina funciones simples para calcular y graficar curvas de muestreo
#basadas en el tamaño de la muestra, cobertura y datos de abundancia e incidencia relativa.


#DIVERSIDAD DE HILL - Están parametrizados por un orden de diversidad q, que determina
#la sensibilidad de las medidas a las abundancias relativas de las especies:

#Diversidad del orden 0, (q = 0) = Da el mismo peso a todas las especies (riqueza de especies)
#Diversodad del orden 1, (q = 1) = Da más peso a las especies comunes (D. Shannon)
#Diversidad del orden 2, (q = 2) = Da más peso a las especies abundantes (D. Simpson)

#El inventario es avaluado mediante la cobertura de la muestra, que mide proporción del número 
#total de individuos en una comunidad que pertenece a las representadas en la muestra


#Funciones de iNEXT: Rerefacción/extrapol


install.packages("iNEXT")

library(iNEXT)
library(ggplot2)


#se procede a cargar los datos

(Curva_abudancia_LB <- read.table(file = "Especies por estacion.csv",
                                 header = T, sep = ","))

#Se debe eliminar la columna Especie para poder trabajar las variables

(Curva_abudancia_LBM <- (Curva_abudancia_LB [,2:16]))
  
#Se debe dar valor de extrapolación (doble de eventos)

(t <- seq(1,834))

#Luego se ejecuta el ánalisis


(analisisInext <- iNEXT(Curva_abudancia_LBM, q = 0, datatype = "abundance"))


lapply(analisisInext, function(x) write.table(data.frame(x), "analisisInext.csv", 
                                               append= T, sep= ","))

#Gráfico iNext

#Basado en el tamaño de la muestra: Representa las estimaciones de diversidad
#con intervalo de confianza


graficoinext1 <- ggiNEXT(analisisInext, type = 1, se = T,
                        color.var = "site", grey = F) +
                        theme_classic(base_size = 14) +
                         theme(legend.position = "bottom",
                            text = element_text(size = 10),
                             legend.title = element_blank()) +
                               labs (x = "Número de individuos",
                                     y = "Diversidad de especies") 
              

#Curva de cobertura de la muestra o completitud del muestreo, con
#intervalos de confianza. Traza la cobertura de muestra con respecto al 
#tamaño de la muestra para el mismo rango descrito en el tipo 1

(graficoinext2 <- ggiNEXT(analisisInext, type = 2, se = T,
                         color.var = "site", grey = F) +
                         theme_classic(base_size = 12) +
                         theme(legend.position = "bottom",
                               text = element_text(size = 12),
                               legend.title = element_blank()) +
                         labs (x = "Número de individuos",
                              y = "Cobertura de muestra")) 

#Curva de R/E basada en la cobertura de la muestra


(graficoinext2 <- ggiNEXT(analisisInext, type = 3, se = T,
                          color.var = "site", grey = F) +
                          theme_classic(base_size = 12) +
                          theme(legend.position = "bottom",
                                text = element_text(size = 12),
                                legend.title = element_blank()) +
                                labs (x = "Número de individuos",
                                      y = "Diversidad de especie")) 




################################################################################
#Crear un historial de detección de especies para el análisis de ocupación######
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
                                occasionLength = 1, #Duración de la ocasión de muestreo en días
                                day1 = "station", #las ocasiones donde comienzan la fecha de configuraci?n de la estaci?n
                                includeEffort = FALSE, #Calcular el esfuerzo de captura (n?mero de d?as de captura de c?mara activa por estaci?n y ocasiones
                                scaleEffort = FALSE, #No escale y centre la matriz de esfuerzo
                                writecsv = TRUE,
                                outDir = Historial_de_deteccion_por_especie))


#Vea el historial de detección de Leopardus pardalis. Esto se escribe automáticamente en csv según lo anterior

setwd("C:/Users/Diaz/Dropbox/Mi PC (DESKTOP-FH4JI1V)/Desktop/Curso CamtrapR/Ocupacion")

Historia_CT_ocelote
write.csv(Historia_CT_ocelote, "Historia CT ocelote.csv")


#Análisis de ocupación. Se calcula las probabilidades de ocupación y detección específicas de covariables

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
#Función para crear una grid de cámaras-trampa para el campo####################
################################################################################














































