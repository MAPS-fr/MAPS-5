breed [chercheurs chercheur]

globals [nombre-technologies densite-techno-0 densite-techno-1 compteur-turnovers nb-institutions max-maitrise-techno compteur-remise-en-cause]

undirected-link-breed [liens-sociaux lien-social]

chercheurs-own
[
  discipline
  institution
  techno-preferee
  liste-technos-maitrisees
  age
]

patches-own [libre?]

liens-sociaux-own [ poids techno ]

;;Différents scénarios initiaux

to repartition-initiale-aleatoire
  create-chercheurs nb-chercheurs
  [
    init-un-chercheur-aleatoire
  ]
end


to init-un-chercheur-aleatoire  
  set discipline random nb-disciplines
  set institution random nb-institutions
  set techno-preferee -1
  set liste-technos-maitrisees [0 0]
  set age random limite-age    
 
  let liste-shape ["circle" "square" "triangle" "star"]
  set shape item institution liste-shape 

  setxy random-xcor random-ycor
  
  set color 5
  set size 0.5
end


to repartition-initiale-geographique
    ask patches [set libre? true]
    let group1 nb-chercheurs * 30 / 100
    let group2 nb-chercheurs * 10 / 100
    let group3 nb-chercheurs * 10 / 100
    let group4 nb-chercheurs * 50 / 100
 
  create-chercheurs group1 ;; nb-chercheurs
  [
    let patch1 patch (world-width / 4) (world-height / 4)
    let patches-libres []
    ask patch1 [set patches-libres (patches in-radius 10 with [libre?])]
    set institution 0
    init-un-chercheur patches-libres
    ]
  
  create-chercheurs group2 ;; nb-chercheurs
  [
    let patch2 patch ((world-width / 4) * 3) ((world-height / 4) * 3)
    let patches-libres []
    ask patch2 [set patches-libres (patches in-radius 5 with [libre?])]
    set institution 1
    init-un-chercheur patches-libres
    ]
  
    create-chercheurs group3 ;; nb-chercheurs
    [    
     let patch3 patch ((world-width / 4) * 3) (world-height / 4)
     let patches-libres []
     ask patch3 [set patches-libres (patches in-radius 5 with [libre?])]
     set institution 2
     init-un-chercheur patches-libres
    ]
  
    create-chercheurs group4 ;; nb-chercheurs
    [
     let patch4 patch (world-width / 4) ((world-height / 4) * 3)
     let patches-libres []
     ask patch4 [set patches-libres (patches in-radius 10 with [libre?])]
     set institution 3
     init-un-chercheur patches-libres
    ]
end

to init-un-chercheur [liste-patches]
  
  set discipline random nb-disciplines
  set liste-technos-maitrisees [0 0]
  set techno-preferee -1
  set age random limite-age

  set color 5
  set size 1
    ifelse any? liste-patches [
      let mon-patch one-of liste-patches
      move-to mon-patch
      ask mon-patch [set libre? false]]
      [
       move-to one-of patches with [libre? = true]
      ]
      
  let liste-shape ["circle" "square" "triangle" "star"]
  set shape item institution liste-shape 

end

to distribution-technologique-initiale
   ask n-of (distribution-initiale-techno1 * nb-chercheurs) chercheurs
   [
     set techno-preferee 0 
     set color ( 15 + techno-preferee * 70 )
     set liste-technos-maitrisees replace-item techno-preferee liste-technos-maitrisees (random max-maitrise-techno)
   ] 
  
  ask n-of (distribution-initiale-techno2 * nb-chercheurs) (chercheurs with [techno-preferee != 0])
  [
    set techno-preferee 1
    set color ( 15 + techno-preferee * 70 )
    set liste-technos-maitrisees replace-item techno-preferee liste-technos-maitrisees (random max-maitrise-techno)
  ] 
end


to init-simulation
  
  ;; variables globales
  __clear-all-and-reset-ticks
  set nombre-technologies 0
  set nb-institutions 4
  set max-maitrise-techno 50
  set compteur-remise-en-cause 0

  if (repartition-initiale-chercheurs = "aleatoire") [ repartition-initiale-aleatoire ]
  if (repartition-initiale-chercheurs = "geographique") [ repartition-initiale-geographique ]
  
  if (distribution-technologique = "initiale") [ distribution-technologique-initiale ]

end

to-report calcule-coeff-distance [d]
  let alpha 0
  let d1 0.05 
  let d2 0.1
  let diff (coeff-distance - coeff-distance / 1000) / (d2 - d1)
  if (d <= d1) [set alpha coeff-distance]
  if ((d > d1) and (d <= d2)) [set alpha (coeff-distance - diff * (d - d1))]
  if (d > d2) [set alpha coeff-distance / 1000]
  report alpha
end
  

to creation-liens-sociaux
  ;;prendre chaque chercheur pour essayer de créer des liens sociaux
  ask chercheurs
  [
    let my-discipline discipline
    let my-institution institution
    let my-techno-preferee techno-preferee
    
    ask other chercheurs  with [ link-with myself = nobody ]
    [
      
      ;;distance entre deux individus sur les différentes dimensions
      let delta-discipline (abs (discipline - my-discipline))
      let delta-distance (distance myself)/(2 * sqrt ( max-pxcor * max-pxcor + max-pycor * max-pycor ) ) ;; pythagore
      let delta-institution 0
      let delta-techno-preferee 0
      
      if (institution = my-institution)
        [ set delta-institution 1 ]

      if (techno-preferee = my-techno-preferee)
        [ set delta-techno-preferee 1 ]
      
      ;;calcul de l'affinité
      let score-affinite ((calcule-coeff-distance delta-distance) + (coeff-discipline / (delta-discipline + 1)) + (coeff-institution * delta-institution) + (coeff-techno-preferee * delta-techno-preferee))
      let score-max (coeff-distance + coeff-discipline + coeff-institution + coeff-techno-preferee)  
        
      let seuil-creation-lien-social 1 - ( densite-sociale * score-affinite / score-max ) 
      
      ;;création aléatoire de lien    
      if (random-float 1.0 >= seuil-creation-lien-social) 
      [
        create-lien-social-with myself
        [
         set techno -1
        ]
        set size 0.5 + (( count link-neighbors ) * 0.2 )
       ]
      ]

    ifelse montrer-informations?
      [ set label my-discipline ]
      [ set label "" ]
  ]
end


to incrementation-experiences-technologies
  ask liens-sociaux
  [

    ;tentative d'établir une relation technologique qui permet un échange d'expérience
    let seuil 1 - (poids / (1 + 10 * poids))
    if (random-float 1 >= seuil)
    [

      let techno-end1 ( [ techno-preferee ] of end1 )
      let techno-end2 ( [ techno-preferee ] of end2 )
             
        ;transmission d'un point d'expérience au chercheur 1      
        ask end1
        [
          if (techno-end2 != -1)
          [
            
            if (item techno-end2 liste-technos-maitrisees < max-maitrise-techno )
            [
              let value ((item techno-end2 liste-technos-maitrisees) + 1) 
              set liste-technos-maitrisees replace-item techno-end2 liste-technos-maitrisees value
            ]
          ]
          
        ]
        
        ;transmission d'un point d'expérience au chercheur 2      
        ask end2
        [          
          if (techno-end1 != -1)
          [
            if (item techno-end1 liste-technos-maitrisees < max-maitrise-techno )
            [
              let value ((item techno-end1 liste-technos-maitrisees) + 1)
              set liste-technos-maitrisees replace-item techno-end1 liste-technos-maitrisees value
            ]
                               
          ]
        ]   
    
       ;;informations sur le lien
       if (techno-end1 = techno-end2)
       [
         set techno techno-end1
         set color ( 15 + techno-end1 * 70 )
       ]
        
       ;;remise en cause des compétences technologies 
       if ( (techno-end1 != -1) and (techno-end2 != -1) and (techno-end1 != techno-end2))
       [
         set compteur-remise-en-cause ( compteur-remise-en-cause + 1 )
       ]
        
      ]
    ]
end


to choix-techno-preferee
  ask chercheurs
  [
   ;;distinction de deux cas : experts polymorphes ou autre
   ifelse ( (item 0 (sort liste-technos-maitrisees)) = max-maitrise-techno)
   [
     ;; arbitrage social à partir du voisinage
     let poids-reseau [0 0]
     ask link-neighbors     
     [
       if (techno-preferee != -1)
       [
         let poids-lien [poids] of lien-social-with myself
         set poids-reseau replace-item techno-preferee poids-reseau ((item techno-preferee poids-reseau) + poids-lien)
       ]
     ]

     set techno-preferee ( position ( max poids-reseau ) poids-reseau )
     set color ( 15 + techno-preferee * 70 )
   ]
   [
     if (last (sort liste-technos-maitrisees) != 0)
     [
       ;; technologie la mieux maîtrisé
       set techno-preferee ( position ( max liste-technos-maitrisees ) liste-technos-maitrisees )
       set color ( 15 + techno-preferee * 70 )
     ]
   ] 
  ]
end

;; évolution des liens sociaux chaque tour
to mise-a-jour-liens
  ask liens-sociaux
  [
   set poids poids + 1
   set thickness (log poids 10) * 0.1
   survie-lien
  ]
end

;; mise à l'épreuve de la survie du lien
to survie-lien
  let seuil-maintien-lien-social poids / (1 + poids)
  if (random-float 1 >= seuil-maintien-lien-social) 
  [
    die
  ]
end


;; gestion de l'apparition de la technologie
to distribution-technologique-progressive
  if (nombre-technologies < 2)
  [
    if (random-float 1 < 0.1)
    [
     set nombre-technologies (nombre-technologies + 1)
     ask one-of chercheurs with [techno-preferee = -1]
     [
       set techno-preferee (nombre-technologies - 1)
       set color pink
       set liste-technos-maitrisees replace-item (nombre-technologies - 1) liste-technos-maitrisees 50
     ] 
    ]
  ]
end

to turnover
  ask chercheurs
  [
    
    set age ( age +  1)
    
    if (age > limite-age)
    [ 
      if (repartition-initiale-chercheurs = "aleatoire")
      [ 
        init-un-chercheur-aleatoire
      ]
      
      if (repartition-initiale-chercheurs = "geographique")
      [     
        init-un-chercheur patches in-radius 3 with [libre?] 
        set age random limite-age
      ]
      
      ask my-liens-sociaux [ die ]
      
      set compteur-turnovers compteur-turnovers + 1
    ]
    
  ]
end

;; fonction principale de déroulement
to pas-simulation
  set compteur-remise-en-cause 0
  if (distribution-technologique = "progressive") [ distribution-technologique-progressive ]
  creation-liens-sociaux
  incrementation-experiences-technologies
  choix-techno-preferee
  mise-a-jour-liens
  if (activer-age? = true) [ turnover ]
  
  ;; indicateurs de sortie
  
  ;;densité
  let elmt-techno-0 (count chercheurs with [techno-preferee = 0] * ((count chercheurs with [techno-preferee = 0]) - 1))
  let elmt-techno-1 (count chercheurs with [techno-preferee = 1] * ((count chercheurs with [techno-preferee = 1]) - 1))
  ifelse (elmt-techno-0 = 0)
  [
    set densite-techno-0 0
  ]
  [
    set densite-techno-0 (2 * (count liens-sociaux with [techno = 0] / elmt-techno-0))
    if (densite-techno-0 > 0.2) [set densite-techno-0 0.2]
  ]  
  
  ifelse (elmt-techno-1 = 0)
  [
    set densite-techno-1 0
  ]
  [
    set densite-techno-1 (2 * (count liens-sociaux with [techno = 1] / elmt-techno-1))
    if (densite-techno-1 > 0.2) [set densite-techno-1 0.2]
  ]
  
  tick
end


to reorganisation-liens-sociaux
  layout-spring (chercheurs with [any? link-neighbors]) links 0.4 10 1
end
@#$#@#$#@
GRAPHICS-WINDOW
244
10
660
447
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
50
0
50
0
0
1
ticks
30.0

SLIDER
12
23
184
56
nb-chercheurs
nb-chercheurs
0
100
50
10
1
NIL
HORIZONTAL

BUTTON
114
443
211
476
Initialisation
init-simulation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
17
443
109
476
Lancement
pas-simulation
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
13
66
185
99
nb-disciplines
nb-disciplines
1
10
4
1
1
NIL
HORIZONTAL

SWITCH
13
107
229
140
montrer-informations?
montrer-informations?
0
1
-1000

BUTTON
16
479
130
512
Réorganisation
reorganisation-liens-sociaux
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
16
247
218
280
coeff-discipline
coeff-discipline
0
1.0
0
0.01
1
NIL
HORIZONTAL

SLIDER
15
289
218
322
coeff-institution
coeff-institution
0
1.0
0
0.01
1
NIL
HORIZONTAL

SLIDER
16
329
190
362
coeff-techno-preferee
coeff-techno-preferee
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
16
368
188
401
coeff-distance
coeff-distance
0
1
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
17
404
189
437
densite-sociale
densite-sociale
0.0001
0.1
0.0161
0.001
1
NIL
HORIZONTAL

PLOT
784
343
984
493
Proportion Utilisateurs
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
"techno 1" 1.0 0 -2674135 true "" "plot 100 * ( count chercheurs with [techno-preferee = 0] ) / nb-chercheurs"
"techno 2" 1.0 0 -13791810 true "" "plot 100 * ( count chercheurs with [techno-preferee = 1] ) / nb-chercheurs"

PLOT
833
10
993
143
Nb Liens
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
"techno 1" 1.0 0 -2674135 true "" "plot count liens-sociaux with [techno = 0]"
"techno 2" 1.0 0 -13791810 true "" "plot count liens-sociaux with [techno = 1]"
"total" 1.0 0 -16777216 true "" "plot count links"

PLOT
782
177
982
327
Densité
NIL
NIL
0.0
0.2
0.0
0.2
true
true
"" ""
PENS
"techno 1" 1.0 0 -2674135 true "" "plot densite-techno-0"
"techno 2" 1.0 0 -11221820 true "" "plot densite-techno-1"

CHOOSER
235
513
474
558
repartition-initiale-chercheurs
repartition-initiale-chercheurs
"geographique" "aleatoire"
0

CHOOSER
236
456
451
501
distribution-technologique
distribution-technologique
"initiale" "progressive"
0

SLIDER
494
446
749
479
distribution-initiale-techno1
distribution-initiale-techno1
0
1
0.9
0.05
1
NIL
HORIZONTAL

SLIDER
494
483
749
516
distribution-initiale-techno2
distribution-initiale-techno2
0
1 - distribution-initiale-techno1
0.1
0.05
1
NIL
HORIZONTAL

INPUTBOX
818
503
979
563
limite-age
200
1
0
Number

PLOT
669
10
829
142
Tension compétitive techno
temps
nombre confrontation
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot compteur-remise-en-cause"

SWITCH
20
163
164
196
activer-age?
activer-age?
1
1
-1000

MONITOR
684
172
793
217
NIL
count chercheurs
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="nb-liens-sociaux-max">
      <value value="78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-chercheurs">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="montre-nb-liens?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densite-sociale">
      <value value="0.026"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coeff-institution">
      <value value="0.38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-institutions">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coeff-distance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coeff-discipline">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coeff-techno-preferee">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-disciplines">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

@#$#@#$#@
0
@#$#@#$#@
