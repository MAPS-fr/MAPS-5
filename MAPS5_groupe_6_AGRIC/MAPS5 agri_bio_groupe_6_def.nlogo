; permet de commenter le code

;---------------------------------------------------------------------------------
; les variables
;---------------------------------------------------------------------------------

globals [ seuil-faillite nbNouveaux nbTransmissions nbFaillites nbDisparitions]


; définir un agent : invidivus = liste d'exploitation (classe d'agent), 
; exploitation : nom qu'on définit nous même qui crée automatiquement une classe
; exploitations : nom de la liste des agents, choix libre
breed [exploitations exploitation]
;breed [noyaux noyau]


exploitations-own [
  parcelles 
  typeExploitation
  taille
  capital
  age
  compteur_bio
  ;target 
  ;disttarget
]


; ajouter une variable à une espèce d'agent
patches-own [
  monExploitation
  usageSol 
  fertilite
  libre? 
  production
  coeff_fertilite_myself
  coeff_fertilite_voisins
  cout
  gain
]



;---------------------------------------------------------------------------------
; init
;---------------------------------------------------------------------------------

; initialise la distribution des exploitations et de leurs parcelles
to init-simulation
  ; reinit le pas de simul et l'affichage (attention à __)
  __clear-all-and-reset-ticks
  
;  create-ordered-noyaux 3 [
;     move-to one-of patches
;  ]


  set seuil-faillite 0
  ;set ratio-bio 0.2
  ;set nouveauxAgri 0.3
  
  ; variables de monitoring
  set nbNouveaux 0
  set nbTransmissions 0
  set nbFaillites 0
  set nbDisparitions 0
  
  ; toutes parcelles du terrain sont libres au départ
  ask patches  [set libre? true ] 
  
  
  ;appelle la création de nombre_exploitation_conventionnelle exploitations conventionnelles
  create-exploitations nombre_exploitation_conventionnelle 
  [

    set typeExploitation "conventionnelle"
    set parcelles []
    init-parcelles red self 6
    set color black
    set shape "flag"
    set size 1.5
    set age random 25
    set capital 100
  ]  
  
  ;appelle la création de  nombre_exploitation_bio exploitations bio
  create-exploitations nombre_exploitation_bio 
  [

    set typeExploitation "bio"
    set parcelles []
    init-parcelles green self 3
    ;set color green
    set shape "flower"
    set size 1.5
    ;set pcolor pink
    set age random 25
    set capital 100
    
;    set disttarget ((random 3) + 3)
;    setxy random-xcor random-ycor
;    set target one-of noyaux
;    face target

  ]
  ;repeat nombre_exploitation_bio [create-exploitation_bio]

  
end




; fabrique les parcelles d'une exploitation
to init-parcelles [colorp exploitant nbparcelles]
  ; prendre un patch sans exploitation
  ; setxy random-xcor random-ycor  
  
  ;let center xcor ycor

 ; créée les parcelles de une exploitation - 
  ask exploitant [
    
    ifelse (typeExploitation = "bio")[  ; exploitation bio --
      ; creer les premieres 
      ifelse count exploitations with [typeExploitation = "bio"] > 3
      
      [move-to one-of exploitations with [typeExploitation = "bio"] move-to one-of patches in-radius distanceD with [libre?] ]
      [move-to one-of patches with [libre? ]]
      
      
        let patch-possible (one-of neighbors with [libre?])
        if (patch-possible != nobody)[
          create-parcelle colorp "reserve" exploitant patch-possible
        ]
        
        set patch-possible (one-of neighbors with [libre?])
        if (patch-possible != nobody)[
          create-parcelle colorp "culture" exploitant patch-possible
        ]        
      
       repeat nbparcelles - 2 [
        set patch-possible (one-of neighbors with [libre?])
        if (patch-possible != nobody)[

          let probaLU random-float 1
          if (probaLU < 0.25)[ 
                    create-parcelle colorp "prairie" exploitant patch-possible]
           if (probaLU >= 0.25 and probaLU < 0.50)[ 
                    create-parcelle colorp "culture" exploitant patch-possible]
           if (probaLU >= 0.5)[ 
                    create-parcelle colorp "reserve" exploitant patch-possible]
          ]   
        ] 
      ];fin creation parcelles bio --
    
      [; exploitation conventionelle --
      ; creer les premieres 
      move-to one-of patches with [libre? ]
        let patch-possible (one-of neighbors with [libre?])
        if (patch-possible != nobody)[
          create-parcelle colorp "culture" exploitant patch-possible
        ]      
         
       repeat nbparcelles - 1 [
        set patch-possible (one-of neighbors with [libre?])
        if (patch-possible != nobody)[

          let probaLU random-float 1
          if (probaLU < 0.4)[ 
                    create-parcelle colorp "prairie" exploitant patch-possible]
           if (probaLU >= 0.4 and probaLU < 0.8)[ 
                    create-parcelle colorp "culture" exploitant patch-possible]
           if (probaLU >= 0.8)[ 
                    create-parcelle colorp "reserve" exploitant patch-possible]         
         ]   
        ] 
      ] ; fin creation parcelles conventionelle --   
  ]
  
  ; si il ne reste pas assez de parcelles libres, l'exploitation n'est pas valide, elle meurt
  if (not is-agentset? parcelles) [
    ;show "meurt à l'init"
    die
  ] 

  ;soit X; //let X
  ;x<- 1// set X 1
  ;soit X = 1 // let X 1
end


 

; fabriquer une parcelle : affecter au patch libre un usage du sol, 
; et l'affecter à l'exploitation propriétaire
to create-parcelle [colorp usage exploitant patch-possible]
  move-to patch-possible
  set parcelles (patch-set parcelles patch-here)
      ;patch-at 1 1 
   ask patch-here
    [
      set libre? false
      set usageSol usage 
      set fertilite 100
      set monExploitation exploitant
      init-param-parcelle  exploitant
    ]
   
end  

to init-param-parcelle [ exploitant]
      if (usageSol = "reserve")[
        set pcolor yellow
        set production 0
        set coeff_fertilite_myself 2
        set coeff_fertilite_voisins 1
       ]
      
      if (usageSol = "culture")[
        set pcolor orange
        ask exploitant[
          ifelse (typeExploitation = "bio")[
             set production 1
             set coeff_fertilite_myself 1
             set coeff_fertilite_voisins 0
          ] [
             set production 1.5
             set coeff_fertilite_myself -2
             set coeff_fertilite_voisins -1
          ]
        ]
      ]
      
      if (usageSol = "prairie")[
        set pcolor green
        set production 0.2 
        set coeff_fertilite_myself 1
        set coeff_fertilite_voisins 1
       ]
end


;;---------------------------------------------------------------------------------
;; Voir/Représentation
;;---------------------------------------------------------------------------------
;

; Voir l'extension spatiale des exploitations (parcelles colorisées suivant la couleur de leur agent)
to voir_exploitations
  ask exploitations [
   ask parcelles [
     set pcolor ([color] of myself)
   ]  
  ]
end 

;;-----------------------------------------------
;indicateur de dispersion des exploitations bio
to indicateur-disp
  ask exploitations with [typeExploitation = "bio"]
  [set compteur_bio (count exploitations with [typeExploitation = "bio"] in-radius 5)]
 
end

;;---------------------------------------------------------------------------------
;; actions
;;---------------------------------------------------------------------------------
;



;;procedures ST 26 juin:
;; sert q mettre jour la fertilite
;to update-fertilite
; ask exploitations [
;   ask parcelles [
;     set fertilite (fertilite + coeff_fertilite_myself)
;     let tot_voisin 0
;     ask neighbors [
;       ; set fertilite of myself ([fertilite] of myself + coeff_fertilite_voisin)
;       set tot_voisin (coeff_fertilite_voisins + tot_voisin)
;       
;     ]
;     set fertilite (fertilite + tot_voisin)
;   ]
; ]
;
;end

;; calculer le gain de chaque parcelles
;to calculGain  
;  ask parcelles
;    [ 
;    if (usageSol = "reserve")[ set cout 0]
;            
;   if (usageSol = "culture")
;   [ ask exploitations [ifelse (typeExploitation = "bio")[
;             set cout 50 - fertilite             
;          ] 
;          [
;             set cout 50 - production
;                      ]
;    if (usageSol = "prairie")[set cout 50]
;      
;  
;   ] ]]
;  ifelse (usageSol = "reserve")
;  [set gain 0] 
;  [set 
;    gain  ( (production * fertilite) - cout )
;  ]
;end

; appelé chaque année pour mettre à jour le capital ; christine ; remplacer par code Sylvain
;to updateCapital
;  ask exploitations [
;    calculGain
;    let bilanAnnuel 0
;    ask parcelles [
;      set bilanAnnuel (bilanAnnuel + gain)
;    ]
;    set capital (capital + bilanAnnuel)
;  ]
;end

; calculer la succession si une exploitation est remise en jeu après faillite ou retraite
to succession [une-exploitation]
  let probaBio random-float 1
   ask une-exploitation [
     ifelse (capital > seuil-faillite)[
       show "le fils est intéressé par la reprise"
       ; le fils est intéressé par la reprise 
       set nbTransmissions (nbTransmissions + 1)

       ifelse (probaBio < ratio-bio)
        [ ; exploitation bio
          convert-exploitation "bio" self
        ]    
        [ ; exploitation conventionnelle
          convert-exploitation "conventionnelle" self
        ] 
     ] 
     [ ; c'est un nouvel arrivant, qui reprend, s'il existe
       show "c'est un nouvel arrivant, qui reprend, s'il existe"
        let probaNouveau random-float 1
        ifelse (probaNouveau < nouveauxAgri)
        [ ; il existe un nouvel arrivant
          show "Un nouvel arrivant prend l exploitation"
          set nbNouveaux (nbNouveaux + 1)
          ifelse (probaBio < ratio-bio)
          [ ; exploitation bio
            convert-exploitation "bio" self
          ]    
          [ ; exploitation conventionnelle
            convert-exploitation "conventionnelle" self
          ] 
        ]    
        [ ; sinon l'exploitation qui disparait ou bien est rachetée en entier par ses voisins
           show "Demembrement"
          demembrement self
        ]           
     ]   

   ]
end

; appelé par succession en cas de rachat possible par plusieurs voisins, bio ou conventionels
to demembrement [exploitation-en-vente]
  ; trouver les acheteurs
  ;show "demembrement pour "
  ;show exploitation-en-vente
  
  let acheteurs-possible  []
  ask exploitation-en-vente [
  ask parcelles [
      ; set pcolor ([color] of myself)
      ask neighbors with [not libre?] [

          ;show "le possible racheteur"
          ;show monExploitation
        
        if ((monExploitation != nobody) and (monExploitation != exploitation-en-vente) and not member? monExploitation acheteurs-possible ) [; 2 [1 2 3]
          ;show monExploitation
          set acheteurs-possible (turtle-set monExploitation acheteurs-possible)
        ]
      ]
   ]  
   ;show count acheteurs-possible
  ]
  
  ; tester les acheteurs possible
  ifelse (not is-agentset? acheteurs-possible ) [;not any? acheteurs-possible
     ask exploitation-en-vente [
       ask parcelles [
         set libre? true
         set pcolor black
       ]
       set nbDisparitions (nbDisparitions + 1)
       ;show "disparue"       
       show "je meurs"
       die
     ]
  ] [
   ; faire la transmission
   let acheteur (one-of acheteurs-possible)
   ask acheteur [
     convert-exploitation typeExploitation exploitation-en-vente
     ;show "vendue"
   ]

  ]
  
end

; appelée lors d'une succession, d'une reprise par un nouvel agriculteur, ou un démembrement
; le type d'exploitation pour la conversion, et l'exploitation à modifier (vendue ou transmise)
to convert-exploitation [typeExploit exploitationTransmise]
  ask exploitationTransmise [
    update-parcelles myself typeExploit

 ;   detruire_exploitation
    set typeExploitation typeExploit
    set age 0
    set capital 100
    set size 1.5
    
    ifelse (typeExploit = "conventionnelle") [
      set shape "flag"
      set color black
    ] [
      set shape "flower"
    ]        
   ]
end

to detruire_exploitation
;    show "exploitation en faillite avec capital " 
;    show capital 
;    show " age "
;    show age
;    show "typeExploitation"
;    show typeExploitation
    die 
end

; il y a eu transmission à un exploitant pour un certain type d'exploitation
; changer les occupations "culture" en trop dans exploitations bio en "reserve"
to update-parcelles [exploitant typeExploit]
  ;show "le recuperateur"
  ;show exploitant
 ask parcelles [
   ; par défaut, les occupations du sol des parcelles ne changent pas. 
   ; Mais leur propriétés fertilite et production changent car elles sont fonction du propriétaire
   set monExploitation exploitant 
   init-param-parcelle exploitant
 ] 
 if ((typeExploit = "bio") and (count parcelles with [usageSol = "culture"] > 2)) [   
    ask n-of ((count parcelles with [usageSol = "culture"] - 2)) parcelles
    [ ; passent en reserve
      update-parcelle green "reserve" exploitant
    ]
  ]
end 


; mettre à jour l'occupation du sol d'une parcelle
; et l'affecter à l'exploitation propriétaire
to update-parcelle [colorp usage exploitant]
   set usageSol usage 
   set monExploitation exploitant
   init-param-parcelle exploitant   
end  


; appelée tous les 5 ans
to bilan
   show "debut du bilan"
  ask exploitations [
    if (capital < seuil-faillite)[
      show "je suis en faillite"
       set nbFaillites (nbFaillites + 1)  
      show  "fin faillites"
      succession self
    
    ]
  ]  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-fertilite
  ;mise à jour de la fertilité de la parcelle
 ask parcelles [
   set fertilite (fertilite + coeff_fertilite_myself) 
      
   ;calcul de l'influence des voisins de la parcelle                                   
    let tot_voisin 0
   ask neighbors [
       ; set fertilite of myself ([fertilite] of myself + coeff_fertilite_voisins)
      set tot_voisin (coeff_fertilite_voisins + tot_voisin)
      
       ]
   ; ajout de l'influence de mes voisins à ma propre fertilité
   set fertilite (fertilite + tot_voisin)
 ]

 ; la fertilité est obligatoirement est comprise entre 0 et 200
  
 ask parcelles 
 [if fertilite < 0 [set fertilite 0]
 ]
 
 ask parcelles
 [if fertilite > 200 [set fertilite 200]]
end

;;;;calcul du cout d'exploitation de la parcelle

to calcul-cout

    ask parcelles
    [ if (usageSol = "reserve")[ set cout 100]
            
      if (usageSol = "culture")
         [ifelse ([typeExploitation] of myself = "conventionnelle")
           [set cout ((100) - fertilite)       ] 
           [set cout ((100) - production)
                      ]
      if (usageSol = "prairie")[set cout 50]
      
  
   ] ]
end

;;;;calcul du gain généré par parcelle

to calculGain
  ask parcelles  
  [ifelse (usageSol = "reserve")[set gain 0]
[set gain  ( (production * fertilite) - cout )
]]
end

;;;;addition de l'ensemble des gains au niveau de l'exploitation pour chaque itération

to update-capital
  ask exploitations 
  [set capital  ( capital + (sum [gain] of parcelles))]
end



to check-and-update-age-exploation 
  ask exploitations [
  ifelse (age < 25)
  [set age age + 1]
  [succession self] 
  ]  
end


;;;; to go bidon
to go-bidon
  ask exploitations   [
    update-fertilite  
    calcul-cout
    calculGain]
  
  update-capital
  
  ; test couleur faillite
  
  ask exploitations
  [if capital < 0 [set color white set size 3]]
 
  if ticks = 200 [stop]
  tick
end

;
;; doit etre appelé au niveau observer (choix dans Interface)
to pas-simulation
;  if (ticks = 1) [
;    demembrement one-of exploitations
;  ]
  
  ask exploitations   [
    ;faire mettre à jour leur fertilite
    update-fertilite  
    calcul-cout
    calculGain
  ]
    
  update-capital
  
  ask exploitations
  [if capital < seuil-faillite [set color white set size 3]]
 
  if ticks = 500 [stop] ;critere arret  
  if (ticks mod 5 = 0) [ bilan ]

  
  indicateur-disp
  ; incremente le pas de simulation (avance l'horloge)
  tick
end  
;
;
@#$#@#$#@
GRAPHICS-WINDOW
759
21
1294
547
-1
-1
15.0
1
14
1
1
1
0
1
1
1
0
34
0
32
0
0
1
ticks
30.0

BUTTON
9
407
115
440
initialisation
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
134
406
197
439
go
pas-simulation\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
18
124
174
184
nombre_exploitation_conventionnelle
50
1
0
Number

INPUTBOX
18
54
173
114
nombre_exploitation_bio
20
1
0
Number

BUTTON
86
237
149
270
voir
voir_exploitations
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
515
268
754
418
compte exploitations
temps
nb exploitations
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"toutes" 1.0 0 -16777216 true "" "plot count exploitations"
"nb bio" 1.0 0 -13840069 true "" "plot count exploitations with [typeExploitation = \"bio\"]"
"nb conv" 1.0 0 -2674135 true "" "plot count exploitations with [typeExploitation = \"conventionnelle\"]"

PLOT
515
22
755
261
indicateurs_suivi
temps
nombre_de
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"faillites" 2.0 0 -955883 true "" "plot nbFaillites"
"nouveaux" 1.0 0 -14985354 true "" "plot nbNouveaux"
"transmissions" 1.0 0 -2064490 true "" "plot nbTransmissions"
"disparus" 1.0 0 -7500403 true "" "plot nbDisparitions"

SLIDER
175
298
347
331
ratio-bio
ratio-bio
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
170
355
342
388
nouveauxAgri
nouveauxAgri
0
1
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
25
351
175
396
Chances de reprise par un nouveau si le fils ne reprend pas ?
12
0.0
1

TEXTBOX
22
295
172
313
Quel type d'exploitation ?
12
0.0
1

PLOT
513
426
753
576
niveau aggregation bio (rayon 5 cellules)
temps
nb moyen bio
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"niveau " 1.0 0 -15575016 true "" "plot ((sum [compteur_bio] of exploitations with [typeExploitation = \"bio\"]) / (0.01 + count exploitations with [typeExploitation = \"bio\"]))"

PLOT
1306
20
1506
170
capital
temps
capital
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"bio" 1.0 0 -13840069 true "" "plot (sum [capital] of exploitations with [typeExploitation = \"bio\"])"
"conv" 1.0 0 -2674135 true "" "plot (sum [capital] of exploitations with [typeExploitation = \"conventionnelle\"])"

SLIDER
8
200
180
233
distanceD
distanceD
0
20
10
1
1
NIL
HORIZONTAL

PLOT
1306
179
1506
329
fertilité
temps
fertilité
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"bio" 1.0 0 -13840069 true "" "plot (sum [fertilite] of exploitations with [typeExploitation = \"bio\"])"
"conv" 1.0 0 -2674135 true "" "plot (sum [fertilite] of exploitations with [typeExploitation = \"conventionnelle\"])"

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
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="true">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="500"/>
    <metric>count exploitations with [typeExploitation] = "bio"</metric>
    <metric>count exploitations with [typeExploitation] = "conventionnelle"</metric>
    <enumeratedValueSet variable="nombre_exploitation_bio">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nombre_exploitation_conventionnelle">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
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
