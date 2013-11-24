breed [chercheurs chercheur]

globals [nombre-technologies age-moyen nb-turnovers ]

undirected-link-breed [liens-sociaux lien-social]

chercheurs-own
[
  discipline
  ;; institution
  techno-preferee
  liste-technos-maitrisees
  age
]

liens-sociaux-own [ poids techno ]

patches-own [
  libre?
]

;; to initialiser-mouse
   ;; every 0.1 [if mouse-down?
 ;;[ask patch mouse-xcor mouse-ycor [ sprout-centre 1] ] 
  ;; ]
 ;;  wait 0.5
;; end



to init-simulation
  __clear-all-and-reset-ticks
  
  ifelse choix-depart 
    []
  [localisation-chercheur]

    
  
  set nombre-technologies 0
  
  if modalite-apparition-technologie = "distribution initiale" [donne-techno]
  ;ask patches [ set pcolor white ]
 ;; create-chercheurs nb-chercheurs
 ;; [
 ;;   set discipline random nb-disciplines
    ;; set institution random nb-institutions
  ;;  set techno-preferee -1
  ;;  set liste-technos-maitrisees [0 0]
   
    ;; if institution = 1
    ;; [ set shape "circle" ]
    
    ;; if institution = 2
    ;;[ set shape "square" ]

    ;;if institution = 3
    ;;[ set shape "triangle" ]

    ;;if institution = 4
    ;;[ set shape "star" ]
    

    
    ;;setxy random-xcor random-ycor
    ;; attracteur selon l'institution
    
   ;; set color (discipline * 10) + 5
    ;; set size 0.5
  ;; ]
end

to localisation-chercheur
    ask patches [set libre? true]
  ;;setxy random-xcor random-ycor
    ;; attracteur selon l'institution
    let group1 nb-chercheurs * 30 / 100
    let group2 nb-chercheurs * 10 / 100
    let group3 nb-chercheurs * 10 / 100
    let group4 nb-chercheurs * 50 / 100
    
        
    
  create-chercheurs group1 ;; nb-chercheurs
  [
    let patch1 patch (world-width / 4) (world-height / 4)
    let patches-libres []
    ask patch1 [set patches-libres (patches in-radius 10 with [libre?])]
    init-un-chercheur patches-libres
    ]
  
  create-chercheurs group2 ;; nb-chercheurs
  [    let patch2 patch ((world-width / 4) * 3) ((world-height / 4) * 3)
    let patches-libres []
      ask patch2 [set patches-libres (patches in-radius 5 with [libre?])]
       init-un-chercheur patches-libres
    ]
  
    create-chercheurs group3 ;; nb-chercheurs
  [    let patch3 patch ((world-width / 4) * 3) (world-height / 4)
    let patches-libres []
    
    ask patch3 [set patches-libres (patches in-radius 5 with [libre?])]
    init-un-chercheur patches-libres
    ]
  
    create-chercheurs group4 ;; nb-chercheurs
  [    let patch4 patch (world-width / 4) ((world-height / 4) * 3)
    let patches-libres []
    ask patch4 [set patches-libres (patches in-radius 10 with [libre?])]
    init-un-chercheur patches-libres
    ]
end

;; to choix-position


;; if mouse-down?
 ;;  [ask patch mouse-xcor mouse-ycor [ set pcolor red ] ]
 ;   ask patches [set libre? true]
 ; create-chercheurs nb-chercheurs 
 ; [let depart1 patch mouse-xcor mouse-ycor
  ;  let patches-libres []
  ;  ask depart1 [set patches-libres (patches in-radius 10 with [libre?])]
  ;  init-un-chercheur patches-libres]

;; end

to initialiser-mouse
  every 0.1 [if mouse-down? [
   ask patches [set libre? true]
 create-chercheurs nb-chercheurs 
 [let depart1 patch mouse-xcor mouse-ycor
  let patches-libres []
  ask depart1 [set patches-libres (patches in-radius 5 with [libre?])]
  init-un-chercheur patches-libres]]]
end


to creation-liens-sociaux
  ask chercheurs
  [
    let my-discipline discipline
    ;; let my-institution institution
    let my-techno-preferee techno-preferee
    
    ask other chercheurs  with [ link-with myself = nobody ]
    [
      let delta-discipline (abs (discipline - my-discipline)) ;;/ nb-disciplines
      let delta-distance (distance myself)/(2 * sqrt ( max-pxcor * max-pxcor + max-pycor * max-pycor ) ) ;; pythagore
     ;; let delta-institution 0
      let delta-techno-preferee 0
      
      ;; if (institution = my-institution)
        ;; [ set delta-institution 1 ]

      if (techno-preferee = my-techno-preferee)
        [ set delta-techno-preferee 1 ]
      
      let score-affinite ((coeff-distance / ((100 * delta-distance + 1) * (100 * delta-distance + 1))  ) + (coeff-discipline / (delta-discipline + 1)) + (coeff-techno-preferee * delta-techno-preferee))
      ;; (coeff-institution * delta-institution) ;; (10 * delta-distance + 1) * ;;
      
      let score-max (coeff-distance + coeff-discipline + coeff-techno-preferee)  
      ;; + coeff-institution 
        
      let seuil-creation-lien-social 1 - ( densite-sociale * score-affinite / score-max ) 
          
      if (random-float 1.0 >= seuil-creation-lien-social) 
      [
        ;if count link-neighbors < nb-liens-sociaux-max
        ;[
          create-lien-social-with myself
          [
           set techno -1
          ]
          set size 0.5 + (( count link-neighbors ) * 0.2 )
          ;;set size (size + 0.4)
        ;]
      ]
            
    ]

    ifelse montre-nb-liens?
      ;;[ set label count link-neighbors ]
      [ set label my-discipline ]
      [ set label "" ]
  ]
end

to init-un-chercheur [liste-patches]
  
  set discipline random nb-disciplines
  set liste-technos-maitrisees [0 0]
  set techno-preferee -1
  set age 25 + random 50
   ;; set institution random nb-institutions
   
   ;; if institution = 1
   ;; [ set shape "circle" ]
   
   ;; if institution = 2
    ;; [ set shape "square" ]

   ;; if institution = 3
   ;; [ set shape "triangle" ]

   ;; if institution = 4
  ;;   [ set shape "star" ]
    
  set color 5
  set size 1
    ifelse any? liste-patches [
      let mon-patch one-of liste-patches
      move-to mon-patch
      ask mon-patch [set libre? false]]
      [
    move-to one-of patches with [libre? = true]
    ]
        
end

to distribution-techno
  ask chercheurs [set color 5]
   ask n-of (distribution-initiale-techno1 * nb-chercheurs) chercheurs
 [set techno-preferee 0 
   set color red] 
  
  ask n-of (distribution-initiale-techno2 * nb-chercheurs) (chercheurs with [techno-preferee != 1])
 [set techno-preferee 1
   set color blue] 
end

to donne-techno
   ask n-of (distribution-initiale-techno1 * count chercheurs) chercheurs
 [set techno-preferee 0 
   set color red] 
  
  ask n-of (distribution-initiale-techno2 * count chercheurs) (chercheurs with [techno-preferee != 1])
 [set techno-preferee 1
   set color blue] 
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
            
            let value ((item techno-end2 liste-technos-maitrisees) + 1) 
            set liste-technos-maitrisees replace-item techno-end2 liste-technos-maitrisees value
            
            set techno-preferee ( position ( max liste-technos-maitrisees ) liste-technos-maitrisees )
          ]
         if techno-preferee = -1 [set color 5]
            if techno-preferee = 0 [set color red]
            if techno-preferee = 1 [set color blue]
          
          
        ]
        
        ask end2
        [
          ;transmission d'un point d'expérience au chercheur 2      
          if (techno-end1 != -1)
          [
            let value ((item techno-end1 liste-technos-maitrisees) + 1)
            set liste-technos-maitrisees replace-item techno-end1 liste-technos-maitrisees value
            
            set techno-preferee ( position ( max liste-technos-maitrisees ) liste-technos-maitrisees )
            if techno-preferee = -1 [set color 5]
            if techno-preferee = 0 [set color red]
            if techno-preferee = 1 [set color blue]
                               
          ]
          if techno-preferee = -1 [set color 5]
            if techno-preferee = 0 [set color red]
            if techno-preferee = 1 [set color blue]
        ]   
      ]
    ]
end

to mise-a-jour-liens
  ask liens-sociaux
  [
   set poids poids + 1
   set thickness (log poids 10) * 0.1
   survie-lien
  ]
end

to survie-lien
  let seuil-maintien-lien-social poids / (1 + poids)
  if (random-float 1 >= seuil-maintien-lien-social) 
  [
    die
  ]
end


to apparition-technologie
  if (nombre-technologies < 2)
  [
    if (random-float 1 < 0.1)
    [
     set nombre-technologies (nombre-technologies + 1)
     ask one-of chercheurs with [techno-preferee = -1]
     [
       set techno-preferee (nombre-technologies - 1)
       set color pink
     ] 
    ]
  ]
end

to pas-simulation
  if modalite-apparition-technologie = "emergence progressive" [apparition-technologie]
  creation-liens-sociaux     ;; P1
  incrementation-experiences-technologies ;; P2
  mise-a-jour-liens          ;; P3
  ask chercheurs [set age age + 0.1]
 
  tick
  
  turnover
  
  if any? chercheurs
  [
   ;; print (word "chercheur 1 : " ([liste-technos-maitrisees] of chercheur 1)) 
   ;; print (word "chercheur 10 : " ([liste-technos-maitrisees] of chercheur 10)) 
   ;; print (word "chercheur 30 : " ([liste-technos-maitrisees] of chercheur 30)) 
  ]
  
end


to reorganisation-liens-sociaux
  layout-spring (chercheurs with [any? link-neighbors]) links 0.4 10 1
end

to turnover
 ask chercheurs [
   if age > 75.0
   [ init-un-chercheur patches in-radius 3 with [libre?]
      
     set age 25
      set nb-turnovers nb-turnovers + 1
    ]
  ]
  end

to carte-france
  import-pcolors "fond_carte_france.png"
end
  
@#$#@#$#@
GRAPHICS-WINDOW
346
10
994
679
-1
-1
6.32
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
100
0
100
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
1
100
4
1
1
NIL
HORIZONTAL

BUTTON
27
446
124
479
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
144
445
236
478
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
7
1
1
NIL
HORIZONTAL

SLIDER
13
110
185
143
nb-institutions
nb-institutions
1
5
4
1
1
NIL
HORIZONTAL

SWITCH
13
155
161
188
montre-nb-liens?
montre-nb-liens?
1
1
-1000

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
0.01
0.01
1
NIL
HORIZONTAL

PLOT
1011
94
1211
244
Liens totaux
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot count links"

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
0.001
0.5
0.051
0.05
1
NIL
HORIZONTAL

PLOT
1010
258
1210
408
Nombre utilisateurs
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot count chercheurs with [techno-preferee = 0]"
"pen-1" 1.0 0 -13345367 true "" "plot count chercheurs with [techno-preferee = 1]"

CHOOSER
33
489
231
534
modalite-apparition-technologie
modalite-apparition-technologie
"distribution initiale" "emergence progressive"
0

SLIDER
36
541
236
574
distribution-initiale-techno1
distribution-initiale-techno1
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
35
590
235
623
distribution-initiale-techno2
distribution-initiale-techno2
0
1  - distribution-initiale-techno1
0.4
0.1
1
NIL
HORIZONTAL

MONITOR
1018
24
1127
69
NIL
count chercheurs
17
1
11

SWITCH
10
202
136
235
choix-depart
choix-depart
0
1
-1000

BUTTON
217
37
336
70
NIL
initialiser-mouse
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
221
86
330
119
NIL
donne-techno
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
225
130
326
163
NIL
carte-france
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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
