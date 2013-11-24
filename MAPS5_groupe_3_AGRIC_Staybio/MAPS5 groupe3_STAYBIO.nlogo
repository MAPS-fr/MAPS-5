globals[
  beta 
  long_listVoisin 
  listVoisin 
  Shannon 
  logS
  tickAllSame
  rendement-bio
  rendement-ogm 
  social-bio 
  social-ogm 
  nbpatchestotal 
  pct-ogm 
  epsilon 
  FraG
  meMoireSHannon ; stock du Shannon précédent
  politiquespubliques-values
  count-bio
  count-ogm
  singletaxes
  ]


patches-own [
  type-agriculture
  Socialbis
  Rendement
  Social
  coeff1
  coeff2
  foncUtility
  Diffpropvoisin
  utility
  cluster
 
]

to setup-globals
  
  set rendement-bio 0.8
  set rendement-ogm 1
  set social-bio 1
  set social-ogm 1
  set nbpatchestotal count patches
  set epsilon 0.0001  ;intervale de variation minimal de l'ind de Shannon signifiant la fin de simulation
  set politiquespubliques-values slide-politiquespubliques
end


to setup
  ca ;;clear all
  reset-ticks
  setup-globals
  set beta 1 - alpha  ; coefficient régulant la rentabilité et la satisfaction sociale
  
  set listVoisin []  ; initialisation d'une liste vide pour calcul indice de Shannon
  ask patches [
   set pcolor random (count patches)
   set type-agriculture "BIO"  ; tous les patches sont déclarés en BIO
   set Social social-bio       ; Au départ Social (I) = 1             
  ]
  let proOGM (ro * count patches) / 100  ; création de ro % (parcelle OGM)
  ask n-of proOGM patches [
    set type-agriculture "OGM"         ; s'applique alors le type OGM
    set Social social-ogm
  ]
  ask patches [
   ifelse type-agriculture = "OGM" [
     set Rendement rendement-ogm            ; le rendement des OGM = 1
     set pcolor yellow    
   ][
     set Rendement rendement-bio      ; le rendement des BIO = 0.8 
     set pcolor green
   ]
   ifelse type-agriculture = "OGM" [   ; si agriculture = OGM
    set coeff1 alpha                  ; définition d'un coefficient 1
    set coeff2 beta                ; définition d'un coefficient 2
    ][
    set coeff1 beta
    set coeff2 alpha  
     ]
    set foncUtility updateStat rendement social  ; appel d'un reporter "updateStat"
    set count-bio count patches with [type-agriculture = "BIO"] 
    set count-ogm count patches with [type-agriculture = "OGM"] 
  ]
  calcul-frac
  CalculH
  updatePlots
end



to go
  ask patches [
    calculeVoisin
    calculSocialbis
    calculRendement
    calculutility
    updateUse
    
  ]
  calcul-frac
  updateVar
  CalculH
  updatePlots
  
  
 if ticks > 1 [    ; si tick sup à 1 dans ce cas le calcul peut se faire car si inférieur à 1 on a pas d'indice de calculer 
   
  if abs (meMoireSHannon - Shannon) <  epsilon [
    print word "meMoireSHannon " meMoireSHannon
    print word "Shannon " Shannon
   show  abs (meMoireSHannon - Shannon)
    stop
   ]
 ]
 set meMoireSHannon Shannon 
  tick
end

to calculeVoisin ;patches context
  let nb-voisin count neighbors ; compte le nombre de voisins
  let nb-voisin-diff count  neighbors with [type-agriculture != [type-agriculture] of myself]  ; compte le nombre de voisins différents (agri différentes)
  set Diffpropvoisin ((nb-voisin-diff) / nb-voisin) ; rapport voisin différents sur voisin tot
end

to calculSocialBis
  set Socialbis Social - Diffpropvoisin  ; calcul du I (Valeur social - Diffpropvoisin)
 if Socialbis < 0 [set pcolor black]
end

to calculRendement
  if type-agriculture = "BIO" [
  set Rendement Rendement - Diffpropvoisin
  if Rendement < 0 [set Rendement 0]
  ] 
end

to calculUtility   ; contexte de patches
 
  ifelse type-agriculture = "OGM" [
    set coeff1 alpha
    set coeff2 beta 
    ][
    set coeff1 beta
    set coeff2 alpha  
     ]
      
  if type-agriculture ="BIO" [ ; aides publiques au BIO
    set Rendement rendement +  politiquespubliques-values
    if Rendement > 1 [
      set Rendement 1 ]
    ] 

if type-agriculture ="OGM" [ ; taxes sur les OGM
   set singletaxes count-bio * politiquespubliques-values / count-ogm
   set Rendement rendement - singletaxes 
    ] 
    
  set foncUtility updateStat Rendement Socialbis 
 ; if foncUtility < 0 [
;print word "rendement " [Rendement] of patches 
; print word "social " [Social] of patches 
;  ]
end

to-report updateStat [Rendement-report social-report] ;;patches context
 report (Rendement-report * coeff1) + (social-report * coeff2) 
 
end

to updateUse ; patches context
  ifelse foncUtility <= seuil [      ; si foncUtility est inférieur au seuil (cf:slide)
    ifelse type-agriculture = "OGM" [     
      set type-agriculture "BIO"    ; OGM devient BIO
      set Social social-bio                  
      set pcolor green
      set Rendement rendement-bio
    ][
      set type-agriculture "OGM" 
      set Social social-ogm
      set pcolor yellow
      set Rendement rendement-ogm
    ]
  ][
  ifelse type-agriculture = "OGM" [
    set Social social-ogm
    set Rendement rendement-ogm
  ][
    set Social social-bio
    set Rendement rendement-bio
  ]
  ] 
 end


to CalculH
  ask patches [
    set listVoisin lput Diffpropvoisin listVoisin  ;Chaque patch dépose sa valeur de "Diifropvoisin" dans une liste appélée listVoisin
  ]
  set listVoisin remove-duplicates listVoisin   ; Suppression des valeurs présentes plusieurs fois
  set long_listVoisin length listVoisin     ; Compte la longueur de la liste
  set logS log long_listVoisin 2     ; calcul le log de 2 de la liste (cf: indice de Shannon)

  let poI 0  ; initialisation d'1 paramètre
  let oneH 0  ; initialisation d'1 paramètre
  let listH []   ; création liste vide
 foreach  listVoisin [    ; pour chaque valeur de la liste
   set poI (count patches with [Diffpropvoisin = ?]) / count patches   ; MAJ de poI =  compte le nbr patches qui ont le même nbr de voisin que lui / nbr de patches tot
   if poI > 0 [
   set oneH poI * log poI 2
   ]
   set listH lput oneH listH
 ]
 set Shannon sum listH * -1
end
;;;;;;;;;;;;Calcul de la framentation
to calcul-frac
  ask patches [
    set plabel ""
    set cluster nobody
    ]
  find-clusters
  set Frag (max [plabel] of patches + 1)
end

to find-clusters
  loop [
    let seed one-of patches with [cluster = nobody]
    if seed = nobody
    [ show-clusters
      stop ]
    ask seed
    [ set cluster self
      grow-cluster ]
  ]
end

to show-clusters
  let counter 0
  loop
  [ let p one-of patches with [plabel = ""]
    if p = nobody
      [ stop ]
    ask p
    [ ask patches with [cluster = [cluster] of myself]
      [ set plabel counter ] ]
    set counter counter + 1 
    ]
end

to grow-cluster  
  ask neighbors4 with [(cluster = nobody) and
    (pcolor = [pcolor] of myself)]
  [ set cluster [cluster] of myself
    grow-cluster 
   ]
end

to updateVar
  if (count patches with [type-agriculture = "OGM"] = 0) OR (count patches with [type-agriculture = "BIO"] =  0)[
    if tickAllSame = 0 [
      set tickAllSame ticks
    ]
 ]
 set count-bio count patches with [type-agriculture = "BIO"] 
  set count-ogm count patches with [type-agriculture = "OGM"] 
  set pct-ogm ((count patches with [type-agriculture = "OGM"] * 100) / nbpatchestotal)
end



to updatePlots
  set-current-plot "utility"
  ask patches [
   set-plot-pen-color pcolor
   plotxy ticks foncUtility
  ]
  
  set-current-plot "social"
  ask patches [
   set-plot-pen-color pcolor
   plotxy ticks Socialbis
  ]
  
  set-current-plot "rendement"
  ask patches [
   set-plot-pen-color pcolor
   plotxy ticks Rendement
  ]
  
  set-current-plot "FraG"
  set-current-plot-pen "FraG"
  plot FraG
  
  
end
@#$#@#$#@
GRAPHICS-WINDOW
220
15
714
530
34
34
7.0244
1
10
1
1
1
0
0
0
1
-34
34
-34
34
0
0
1
ticks
30.0

BUTTON
16
15
89
48
NIL
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
10
105
182
138
ro
ro
0
100
10
10
1
NIL
HORIZONTAL

BUTTON
90
15
153
48
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
720
35
920
185
utility
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

TEXTBOX
15
145
100
163
% de patches OGM
9
0.0
1

SLIDER
10
265
182
298
seuil
seuil
0
1
0.4
0.01
1
NIL
HORIZONTAL

TEXTBOX
10
235
160
256
Poids Rendement OGM\nPoids Satisfaction BIO
9
0.0
1

TEXTBOX
120
235
230
256
Poids Satisfaction OGM\nPoids Rendement BIO
9
0.0
1

PLOT
720
195
920
345
Social
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
720
355
920
505
rendement
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

TEXTBOX
15
305
165
341
seuil de basculement de la fonction d'utilité\nU = R * alpha + I * Beta
9
0.0
1

INPUTBOX
10
170
85
230
alpha
0.4
1
0
Number

PLOT
1005
390
1205
540
plot shannon
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
"default" 1.0 0 -16777216 true "" "plot Shannon"

MONITOR
925
435
995
480
NIL
Shannon
3
1
11

MONITOR
120
460
207
505
NIL
tickAllSame
17
1
11

MONITOR
120
180
200
225
NIL
beta
16
1
11

BUTTON
135
515
197
548
test
let test one-of patches with [foncutility < 0]\nask test [set pcolor red ]\ninspect test
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
90
50
162
83
go-step
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

MONITOR
930
80
987
125
NIL
pct-ogm
3
1
11

PLOT
1005
230
1205
380
FraG
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
"FraG" 1.0 0 -16777216 true "" ""

MONITOR
940
290
997
335
NIL
FraG
17
1
11

SLIDER
10
350
217
383
slide-politiquespubliques
slide-politiquespubliques
0
0.2
0
0.01
1
NIL
HORIZONTAL

PLOT
995
35
1240
225
ogmVSbio
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
"default" 1.0 0 -8330359 true "" "plot count patches with [type-agriculture = \"BIO\"]"
"pen-1" 1.0 0 -1184463 true "" "plot count patches with [type-agriculture = \"OGM\"]"

MONITOR
25
460
107
505
NIL
singletaxes
17
1
11

@#$#@#$#@
## HOW IT WORKS

The general subject of this model is to assess the possible dynamics in agricultural landscape structures under the condition of the coexistence of two different agricultural practices. The model aims to show how the introduction of GMO in an agricultural landscape could affect the distribution of other practices, in particular the organic ones. The expressed hypotheses are:
* each farm is represented by one field (patch)
* the rentability of GMO practices is in average 20% more than the organic ones (data from the agricultural chamber of the Vosges region, France),
* the organic farmers benefit from a positive social environment whereas the GMO farming systems are subject to a negative social pressure.

## HOW IT WORKS

Agricultural practices are randomly distributed at the initiation of the model respecting the percentage of GMO at the start chosen by the operator.

Each farm is controled by one farmer (they go by pair).

A utility function is used to define the general satisfaction of the farmer. This function is represented by an equation that mixes benefits and social pressure. Benefits and social pressure do not have the same weight on GMO Farmers and Organic Farmers.

If the general satisfaction of the farmer is under a threshold chosen by the operator, he will change his agricultural pratice (GMO to Organic, Organic to GMO).

## HOW TO USE IT

1) Set the threshold and GMOatStart sliders
2) Define the alpha parameter
3) Press setup
4) Press go

Parameters:
GMOatStart: The initial percent of patches with an OGM agriculture
alpha: The weight of the social pressure on Organic farmers and of the benefits on OGM farmers. This implies a weight of 1-alpha on the other parameter for each type of practice.
threshold : Defines the threshold of the utility value under which farmers will change their practices.   

## THINGS TO NOTICE

When the threshold is too low or too high, the changes of practices tend never to happen or happen at every timestep. Intermediate thresholds allow a better understanding of the possibilities.
Notice that in many cases, GMOs tend to become the unique practice in the landscape.
What could explain this according to the choices behind the model ?

What could be used to allow the Organics to take over the landscape ?


## THINGS TO TRY

Try adjusting the parameters under various settings. How sensitive is the stability of both agricultural practices to the particular parameters?

Can you find any parameters that generate a stable patchwork that including both practices ?

Try setting alpha around 0.4, the threshold around 0.3 and the GMOatStart around 30. This will give you some interesting dynamics.

Try changing the rules that determine the utility function. What could influence the change of practices ?


## EXTENDING THE MODEL

We had many ideas in order to go further with this model. Higher political levels can influence the practices by introducing financial aids. We can also imagine the influence of rarity on prices, meaning the rarer the practice the higher the benefits.
Don't hesitate to contact us if you find any interesting extensions !


## NETLOGO FEATURES

Note the use of patches to model farms.
Note use of the UtilityFunction reporter to calculate the utility for each patch.

## CREDITS AND REFERENCES

Marta DEBOLINI (marta.debolini@paca.inra.fr), Etienne DELAY (etienne.delay@etu.unilim.fr), Aurélie GAUDIEUX (aurelie.gaudieux@gmail.com or Aurelie.Gaudieux@univ-reunion.fr), Romain REULIER (romain.reulier@unicaen.fr), Hugo THIERRY (hugo.thierry@ensat.fr)

We also thank the MAPS Network for their help conceiving this project !
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
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Shannon</metric>
    <metric>tickAllSame</metric>
    <metric>ticks</metric>
    <metric>nbpatchestotal</metric>
    <metric>pct-ogm</metric>
    <metric>FraG</metric>
    <steppedValueSet variable="alpha" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="seuil" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="ro" first="0" step="10" last="100"/>
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
1
@#$#@#$#@
