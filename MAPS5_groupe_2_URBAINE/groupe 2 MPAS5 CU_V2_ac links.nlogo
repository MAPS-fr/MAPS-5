extensions       [gis table]
breed            [maires maire]


globals [
         limites_communales          ;; variable qui stocke les couches SIG
        ]

maires-own [
            id_ma_commune            ;; identifiant de la commune d'appartenance du maire, récupéré dans les données de la couche SIG
            mon_ratio                ;; ratio emplois/logements de la commune
            seuil                    ;; niveau de ratio acceptable, peut varier à l'aide du slider "nb_logements_par_emplois"
            partener                 ;; renseigne le partenaire du maire lors d'une coopération entre communes
            ma_couleur               ;; définit la couleur qui représente le ratio de la commune dans le graphique 
           ]


patches-own[
             id_communes             ;; identifiant de la commune du patch, récupéré dans les données de la couche SIG
             nb-logements            ;; nombre de logements présents dans le patch, égal à 0 ou 1 dans cette version
             nb-emplois              ;; nombre d'emplois présents dans le patch, égal à 0 ou 1 dans cette version
             vide?                   ;; indique si le patch est vide (soit sans emploi ET sans logements)
             potentiel_logements     ;; moyenne de l'inverse des distances du patch aux patches emplois
             potentiel_emplois       ;; moyenne de l'inverse des distances du patch aux patches logements
             sortie                  ;; pour la sortie raster
           ]


;; ####################### INITIALISATION DU MONDE ########################################

to setup                             ;;création du monde
  ca
  reset-ticks
  initialise_communes                ;; chargement des limites communales
  initialise_patches                 ;; affectation des premiers lieux de logements et d'activités
end

to initialise_communes
  
  set limites_communales                                                                 ;; chargement des couches SIG
      gis:load-dataset (word "Couches_SIG_bis/" nb_communes "_Communes_region.shp")      ;; le nombre de couches chargées dépend de la valeur du slider "nb_communes"
      
  gis:set-world-envelope (gis:envelope-union-of
                                                (gis:envelope-of limites_communales)     ;; adapte la couche SIG à la taille du monde
                         ) 
  
  gis:apply-coverage limites_communales "ID" id_communes       ;; récupération du champ ID des couches SIG pour mettre à jour l'id_communes
  
  gis:set-drawing-color white                                  ;; choix de la symbologie de la couche SIG
  gis:draw limites_communales 1                                ;; affichage de la couche SIG
  
  foreach (gis:feature-list-of limites_communales)             ;; CREATION DES MAIRES
   [ 
    let maire gis:location-of gis:centroid-of ?                ;; les maires sont placés sur les centroïdes des communes
    if not empty? maire 
     [
      create-maires 1 
       [
        set xcor item 0 maire
        set ycor item 1 maire
        set size 4
        set color 125
        set shape "star"
        set partener "zzz"                                     
        set id_ma_commune [id_communes] of patch-here
        set ma_couleur  one-of base-colors                     ;; choix de la couleur du stylo du graphique
       ]
     ] 
   ]
   
end

to initialise_patches                 ;; création des premiers patches logements et emplois
  
  ask patches
   [
    set vide? true 
    ifelse id_communes >= 0 [   ]   [ set id_communes 0]            
   ]
   
  ask maires
    [
      let tempo-nb-logements (random 4) + 1         ;; variables temporaires qui déterminent le nombre de patches logements et emplois à créer à l'initialisation
      let tempo-nb-emplois (random 4) + 1
     
      ask n-of tempo-nb-logements patches with [                                                               ;; création des premiers logements de la commune 
                                                id_communes = [id_ma_commune] of myself                        ;; localisés sur un patch "vide" et situés dans le voisinage du centroïde
                                                and 
                                                vide? = true
                                                and
                                                any? neighbors4 with [ any? maires-here  or vide? = false]
                                               ]
       
        [
          set pcolor green              ;; mise à jour des variables de patch en conséquence
          set nb-logements 1
          set vide? false
        ]

        ask n-of tempo-nb-emplois patches with [ 
                                                 id_communes = [id_ma_commune] of myself                      ;; création des premiers emplois de la commune 
                                                 and                                                          ;; localisés sur un patch "vide" et situés dans le voisinage du centroïde
                                                 vide? = true
                                                 and
                                                 any? neighbors4 with [ any? maires-here  or vide? = false]
                                                 ]
        [
          set pcolor yellow             ;; mise à jour des variables de patch en conséquence
          set nb-emplois 1 
          set vide? false
        ]
    ]
    
end



;; ################# PROCESSUS #########################


to go
  
 tick
  
  if Cooperation?                ;; vérification du mode (coopération / non_coopération)
    [
     decision_cooperation        ;; en mode coopération, sélection du maire partenaire
    ]
  
  
  calcul_ratio                   ;; calcul du ratio emplois/logements, quelque soit le mode
  
  ask maires                     ;; suppression des maires lorsque tous les patches de leur commune sont affectés
    [
     if not any? patches with [id_communes = [id_ma_commune] of myself and vide?]      
        [die]
    ]
    
  if not any? maires            ;; la simulation s'arrete lorsque tous les patches sont affectés
    [stop]
    
    ask maires 
    [
    
     decision_maires_non_cooperatifs
    ]
    
  Graphics                      ;; mise à jour du graphique

end

;; #################################################################


;; ############## CALCUL DES RATIOS EMPLOIS/COMMUNES #############

to calcul_ratio            
  
  ask maires
   [
    let tempo_emplois_ici 
                         count patches with [nb-emplois = 1 and ( id_communes = [id_ma_commune] of myself  or id_communes =  [partener] of myself )]
                         + 
                         count patches with [nb-emplois = 1 and ( id_communes = [id_ma_commune] of myself or id_communes =  [partener] of myself )]
    
    
    let tempo_residence_ici 
                        count patches with [nb-logements = 1  and   (  id_communes = [id_ma_commune] of myself  or id_communes =  [partener] of myself )]
                        + 
                        count patches with [nb-logements = 1 and  (  id_communes = [id_ma_commune] of myself  or id_communes =  [partener] of myself )]
   
    set mon_ratio (tempo_emplois_ici / tempo_residence_ici)
    ;show mon_ratio
   ]
   
end

;; #######################################################


;; ############## PRISE DE DECISION DES MAIRES


to decision_cooperation                        ;; SELECTION DU MAIRE PARTENAIRE, uniquement en cas de coopération
                                               ;; si un patch emploi/logement d'une commune est contigu à une autre
   ask patches with [vide? = false]            ;; le maire coopère avec cette voisine
     [
      let temp-comm id_communes
     
       if any? neighbors4 with [id_communes != temp-comm and id_communes > 0 ] 
       [
          show temp-comm
         let patch_autre_commune one-of  neighbors4 with [id_communes != temp-comm ]
         ;ask patch_autre_commune [ set pcolor blue]
         ;set pcolor red
         ask maires with [ id_ma_commune = temp-comm]
          [
             set partener [id_communes] of patch_autre_commune 
             show (word "je suis le maire de " id_ma_commune " est je veux cooperer avec la commune " partener)
            if Afficher_lien?
            [
               ;;;verifier qu'il y un lienv ; si oui tuer le lien
               if  link ([who] of one-of maires with [ id_ma_commune = temp-comm] )   ([who] of one-of maires with [ id_ma_commune = [partener] of myself ]) != nobody
               [
                 ask  link ([who ] of one-of maires with [ id_ma_commune = temp-comm] )   ([who] of one-of maires with [ id_ma_commune = [partener] of myself ])
                   [ die ]
               ]
                ; sinon creer un lien orienté 
               create-link-to one-of maires with [id_ma_commune = [ partener] of myself]
               [
                 set thickness 1
                 set color red
                 set shape "courbe"
               ]
            ]
           
             
             
               
          ]
       ]
     ]
 if Afficher_lien? = false [ clear-links ]
 
end


to decision_maires_non_cooperatifs                     ;; procédures de choix d'actions des maires en mode de non_coopération
  
       set seuil ( 1 / nb_logements_par_emplois)       ;; on calcule le seuil en fonction de la valeur du slider "nb_logements_par_emplois"
       
       ifelse mon_ratio < seuil
           [creer_emplois]                             ;; si le ratio est inférieur au seuil, création d'emplois
           [ifelse mon_ratio > seuil
               [creer_logements]                       ;; s'il est supérieur, création de logements
               [
                 let mon_choix random 3                ;; s'il est égal au seuil (donc si la situation est équilibrée)
                    if mon_choix = 1                   ;; le maire peut créer soit un logement, soit un emploi, soit les 2, soit aucun
                        [creer_emplois]
                    if mon_choix = 2
                        [creer_logements]
                    if mon_choix = 3
                        [creer_emplois
                         creer_logements]
                ]
             
             ]

end

;; #################################################################


;; ######################## CREATION DES EMPLOIS/LOGEMENTS

to creer_emplois                 ;; le patch choisi pour l'affection de l'emploi créé dépend du mode de mitage
                                 ;; mitage non actif : l'emploi va sur le patch le plus proche des emplois (*) ET des logements (*)
  calcul_potentiel_emploi        ;; mitage actif : l'emploi va sur le patch le plus proche des logements (*) ET le plus loin des emplois (*)
                                 ;; (*) de la commune et de l'éventuelle commune partenaire
  let patch_choisi []
       ifelse mitage?  
        [
          set patch_choisi (max-one-of patches with [  (id_communes = [id_ma_commune] of myself or id_communes  = [partener] of myself   )     and vide?] [(potentiel_logements - potentiel_emplois   ) ])
        ]
        
        
        
        [set patch_choisi (max-one-of patches with [ (id_communes = [id_ma_commune] of myself  or id_communes  = [partener] of myself   )     and vide?] [potentiel_emplois  + potentiel_logements ])]
       
       
   ask patch_choisi
      [
        set vide? false
        set nb-emplois 1
        set pcolor yellow
       ]
     
end


to creer_logements                  ;; le patch choisi pour l'affection du logement est le plus proche des activités de la commune et de l'éventuel partenaire
                                    
  calcul_potentiel_logement   
  
       let patch_choisi (max-one-of patches with [ (id_communes = [id_ma_commune] of myself  or id_communes  = [partener] of myself   ) and vide?] [potentiel_logements])
       
       ask patch_choisi
           [set vide? false
            set nb-logements 1
            set pcolor green
           ]
     
end

;; ##################################################


;;########## CALCUL DES POTENTIELS EMPLOIS ET LOGEMENTS ############


to calcul_potentiel_logement          ;; le potentiel logement le plus élevé correspond au patch le plus proche des zones d'emplois

   let com_maire id_ma_commune
   let id_partener partener
   let nb_emplois count patches with [  (id_communes = com_maire or id_communes = id_partener )   and nb-emplois = 1]

   ask patches with [ (id_communes = com_maire or id_communes = id_partener ) and vide?]
     [ 
       set potentiel_logements 0
      ]
       
   ask patches with [( id_communes = com_maire or id_communes = id_partener ) and nb-emplois = 1]
      [
       ask patches with [( id_communes = com_maire or id_communes = id_partener) and vide?]
          [
            set potentiel_logements  potentiel_logements  + (1 / (distance myself) ) 
           ]
      ]
         
   set potentiel_logements (potentiel_logements / nb_emplois)     
       
end



to calcul_potentiel_emploi         ;; le potentiel emploi le plus élevé correspond au patch le plus proche des zones de logements

    let com_maire id_ma_commune
    let id_partener partener
       
    
    let nb_logements count patches with [( id_communes = com_maire or id_communes = id_partener ) and nb-logements = 1]

    ask patches with [( id_communes = com_maire or id_communes = id_partener ) and vide?]

      [ set potentiel_emplois 0]

    ask patches with [ ( id_communes = com_maire or id_communes = id_partener ) and nb-emplois = 1]
      [
        ask patches with  [ (id_communes = com_maire or id_communes = id_partener ) and vide?]
          [
            set potentiel_emplois potentiel_emplois + (1 / (distance myself))
           ]
      ]


      set potentiel_emplois (potentiel_emplois / nb_logements)
  
end

;;###################################################


;; ###### MISE A JOUR DU GRAPHIQUE

to Graphics
  
  set-current-plot  "Ratio emploi/logement"
  ask maires
   [
     create-temporary-plot-pen (word id_ma_commune )
     set-plot-pen-color ma_couleur
     plot mon_ratio * 1000
   ] 
 
 create-temporary-plot-pen "seuil"
  set-plot-pen-color black
  plot ((1 /  nb_logements_par_emplois) * 1000 )
  
end

;;####################################################

;; ####### Export raster

to export_raster
  ask patches
  [
    set sortie nb-logements + (nb-emplois * 2)
  ]
  gis:store-dataset gis:patch-dataset sortie "extension_urbaine"
end


;; ################################################################
;; ################################################################
;; ################################################################










@#$#@#$#@
GRAPHICS-WINDOW
345
-5
828
499
50
50
4.6832
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
880
20
1037
53
Initialisation du modèle
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
70
70
242
103
nb_communes
nb_communes
2
10
8
1
1
NIL
HORIZONTAL

BUTTON
880
65
1002
98
Lancer le modèle
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
65
165
272
198
nb_logements_par_emplois
nb_logements_par_emplois
1
50
2
1
1
NIL
HORIZONTAL

BUTTON
1015
65
1217
98
Lancer une itération du modèle
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
65
260
168
293
mitage?
mitage?
0
1
-1000

SWITCH
25
375
152
408
Cooperation?
Cooperation?
0
1
-1000

PLOT
850
130
1215
400
Ratio emploi/logement
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

TEXTBOX
55
10
205
28
NIL
11
0.0
1

TEXTBOX
25
30
215
66
(1) Choix du nombre de communes :
15
0.0
1

TEXTBOX
20
120
275
156
(2) Nombre de logements acceptables par emplois
15
0.0
1

TEXTBOX
20
230
285
266
Choix du mode d'extension urbaine
15
0.0
1

TEXTBOX
180
260
330
346
ON : les nouveaux emplois sont localisés le plus près des logements et le plus loin des autres emplois\n\nOFF : les nouveaux emplois sont localisés le plus près des logements et des emplois\n\n
9
3.0
1

TEXTBOX
25
355
240
391
Choix du mode de coopération
15
0.0
1

TEXTBOX
160
380
310
445
ON : coopération possible en cas d'extension aux frontières de 2 communes\n\nOFF : coopération impossible
9
3.0
1

TEXTBOX
855
105
1225
161
Evolution des ratios emplois/logements des communes
15
0.0
1

BUTTON
1075
410
1212
443
EXPORTER RASTER
export_raster
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
460
142
493
Afficher_lien?
Afficher_lien?
0
1
-1000

TEXTBOX
15
435
165
451
Afficher les liens
15
0.0
1

@#$#@#$#@
## WHAT IS IT?

Ce modèle théorique se place dans le contexte de la croissance urbaine. Il a pour but de comprendre en quoi les stratégies de coopération des maires influencent les morphologies urbaines. L’hypothèse de départ est que les coopérations entre les maires vont diriger les morphologies urbaines.
Le modèle est construit à l’échelle spatiale d’un semis de villes contigues comprises dans des limites communales déterminées (import d'un shapefile). Le pas de temps est d'une année.
Les indicateurs de sorties sont:
- un taux de remplissage des communes
- un ratio emploi/logement par commune (spécialisation fonctionnelle)
- une empreinte spatiale (nombre de tâches urbaines)

## HOW IT WORKS

#A l'initialisation
- chargement du contour des communes
- initialisation des maires au centroide des communes
- création par les maires de n-patches logements et n-patches emplois au centroide de chaque commune

#A chaque itération:
-Assignation aux patches d'un potentiel logement et d'un potentiel emploi (comme étant la moyenne de l'inverse de la distance les séparant des patches emplois/logements de la commune)
- Calcul pour chaque maire de son ratio emploi/logement et tentative d'équilibrage à un certain seuil par la création d'un nouveau logement ou d'un nouvel emploi sur le patch ayant le plus fort potentiel pour l'accueillir

#Coopération
- Coopération des communes lorsqu'un de leur patch est contigu à une commune voisine
- lorsque les communes coopèrent, les potentiels sont calculés sur l'ensemble des communes coopérant

## HOW TO USE IT

- "nb-logement-par-emploi", définit un niveau d'équilibre emploi/logement que le maire doit atteindre
- "nombre de communes"
- "mitage?" autorise-t-on le mitage ou tous les emplois et logements doivent-ils être contigus?



## THINGS TO NOTICE



## THINGS TO TRY



## EXTENDING THE MODEL

- intégration d'une contrainte à la croissance, par exemple un impôt collecté à l'échelle de la population résidente afin de produire des logements et/ou des activités
- possibilité qu'un patch logement devienne un patch activité
- possibilité qu'un patch occupé devienne vide.
- prise en compte des formes urbaines et des différences de densité sur les patches
- ajout d'individus, d'un niveau de satisfaction individuel et la possibilité de déménager en cas d'insatisfaction.
- ajout d'espaces protégés
- ajout de coopérations à plus de deux partenaires
- initialisation de différentes hiérarchies urbaines


## NETLOGO FEATURES

GIS Extension

## RELATED MODELS

Urban Suite NetLogo Library

## CREDITS AND REFERENCES

Maximin Chabrol <maxchabrol@free.fr>, Chloé Desgranges <chloe.desgranges@gmail.com>, Bérengère Gautier <berengere.gautier@parisgeo.cnrs.fr>, Cyril Jayet <cyril_jayet@yahoo.fr>, Virginia Kolb <virginia.kolb@univ-lr.fr>,  Cyril Pivano <cyril.pivano@unpc.fr>, Frederic Rousseaux <frederic.rousseaux@univ-lr.fr>
@MAPS5_2013 @Bungalow33_La_Vieille_Perrotine
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

courbe
5.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
