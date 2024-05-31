globals [death-rate reg-repro response-movement infected active-color fund-short domain-death]
;globals [death-rate reg-repro response-movement infected active-color Domain-funding response-impact]

     ; death-rate = chance of the turtle dying
     ; response-movement = how many spaces the response has moved
     ; reg-repro = the chance a domain will reproduce when it is not active or a memory cell
     ; infected = records whether challenges have been inputted
     ; active-color = the color of the domain that responds to the challenge
breed [domains domain]  ; creating a set of domains
breed [challenges challenge]        ; creating a set of challenges
breed [responses response]     ; creating a set of responses
breed [paradigmshifts paradigmshift]          ; creating special paradigmshifts challenge
breed [educations education]        ; creating special education challenge
domains-own [active active-time reproduction-rate memory]
     ; active = whether the cell is active ( 0 is no ; 1 is yes )
     ; active-time = how much time left the cell has to be active
     ; reproduction-rate = how fast the cell reproducesx
     ; memory = records whether the domain is a memory cell (0 is no ; 1 is yes)
responses-own [energy]
     ; energy = how many ticks the response has left to live
paradigmshifts-own [paradigmshifts-duration]
educations-own [education-duration]
     ; education-duration = for how many ticks will the educations persist in the system

to setup
  clear-all
  clear-output
  ask patches [set pcolor black]
  set infected 0      ; at setup, the system is not infected with any challenges
  set death-rate 15   ; values fit to give best response, no inherent meaning to these rates
  set reg-repro 15
  set fund-short 1
  set domain-death 0
  set active-color one-of base-colors        ;set active color to a random domain color
  ;set active-color red
  set-default-shape domains "circle 2"     ; domains are circles
  set-default-shape challenges "question"       ; challenges are monsters
  set-default-shape paradigmshifts "warning"        ; measles are monsters, big red ones
  set-default-shape educations "book"       ; educations are greyed-out monsters
  set-default-shape responses "Y"           ; responses are Y-shaped
  create-domains 250  ; create the domains, then initialize their variables
  [
    set color one-of base-colors
    set active 0 ; all domains are initially inactive
    set active-time -1
    set reproduction-rate reg-repro ; all domains are initially inactive, so reproduce at regular rate
    set size 1  ; easier to see
    set label-color blue - 2
    setxy random-xcor random-ycor
    set memory 0
  ]
  reset-ticks
end

to go
  if not any? turtles [ stop ]
  replace-extinct
  ask challenges[
    move
    challenge-reproduce
  ]
  ask domains [
    bind
    activated
    move
    reproduce
    lymph-death
  ]
  ask responses [
    response-move
    set energy energy - 1
    response-death
  ]
  paradigmshifts-death
  education-death
  challenge-extinct
  tick
    if domain-death = 1
  [ stop ]
    if count responses < 100 and fund-short = .25
      [
        set fund-short 1
      ]
end

to replace-extinct           ; this is a "rescue effect", if any domain types (colors) go extinct we add one more to the population
  let counter 5
  while [counter < 200]      ; check all the colors
  [
    if count domains with [color = counter] = 0
  [
      create-domains 1  ; create the replacement domain, then initialize its variables
      [
        set color counter
        set active-time -1
        set active 0
        set reproduction-rate reg-repro
        set size 1
        set label-color blue - 2
        setxy random-xcor random-ycor
        ask n-of 1 domains [ die ]   ; kill a random lymphocyte to make up for the replacement
      ]
  ]
  set counter counter + 10
]
end

to move  ; challenge and domain procedure
  rt random 50
  lt random 50
  fd .5
end

to challenge-reproduce
   if random 18 < 2 and color != grey   ;; and statement keeps grey "education challenges" from reproducing
    [
      hatch 1 [ rt random 360 fd 1]
    ]
  if count challenges > 5000 and domain-death = 0
  [
    print "Unfortunately, your area of research has succumbed due to persistent invalidation. Please study something else."
    set domain-death 1
  ]

end

to bind                                          ; active-color domains are activated by the challenge
 if color = active-color[
   if (one-of challenges in-radius 1 != nobody) or (one-of educations in-radius 1 != nobody)
   [
     set active 1
     set active-time 25 + random 25   ;; length of typical cell lifespan if death rate is 10 CHNGED THIAS
   ]
  ]
end

to activated
  if active-time = 0                                 ; kills activated after time is up
    [
       die
      ]

  if active = 1
  [
    set reproduction-rate (Domain-funding * reg-repro * fund-short) ; start rapid reproduction
    set size 1.3               ; increase size
    set shape "target"  ; outline circle
    set color active-color
    hatch-responses 1       ; create responses
    [
      set color white
      rt random-float 360 fd 1  ; randomly pick a direction and move forward
      if response-impact = "high"
      [
          set energy 5
      ]

      if response-impact = "low"
      [
        set energy 2 ; for responses, energy tracks how many ticks the responses have left to live
      ]
      if (count challenges = 0) and (count responses > 10000)
      [
        set fund-short .25
      ]

    ]
   set active-time active-time - 1    ;; counts back down to inactivity
  ]
end

to reproduce  ; determine if the domain reproduces

 if random 100 < reproduction-rate
  [ ifelse memory = 1
    [
      hatch 1 [
        set shape "wheel"
        ;set active-time random 13
        rt random-float 360 fd 1]
    ]
    [
       ifelse active = 1 ; if active, produce both a memory cell and an active cell ; else, produce regular cell
        [
                  hatch-domains 2 [ set shape "wheel"
                  set color active-color
                  ;set active-time random 13
                  set active 0
                  set reproduction-rate 2
                  set size 1.3  ; easier to see
                  set label-color blue - 2
                  set memory 1
                  rt random-float 360 fd 1 ]

                  hatch 1 [ rt random-float 360 fd 1]
        ]
        [
            ifelse count domains < 235
               [
                        hatch 2 [ rt random-float 360 fd 1]
               ]
                [
                        hatch 1 [ rt random-float 360 fd 1]
                 ]
        ]
    ]
  ]
end

to lymph-death  ; determine if the domain dies
  if memory = 0 and random 100 < death-rate
      [
        die
      ]
  if memory = 1 and random 100 < 1
  [
    die
  ]
end

to response-move  ; the speed (distance moved each time step) ends up being a measure of potency of each activated cell
  set response-movement 0
  if response-impact = "high"
  [
     while [response-movement < 5]
     [fd 1
     kill-challenge  ; check to see if it is on the same spot as an challenge and if so, kill it
     set response-movement response-movement + .3
     ]
  ]

  if response-impact = "low"
  [
     while [response-movement < 2]
     [fd 1
     kill-challenge
     set response-movement response-movement + .3
     ]
  ]
end

to response-death
  if energy < 1
  [ die ]
end

to kill-challenge
  let prey one-of challenges-here
  if prey != nobody
  [
    ask prey[die]
  ]
end

to paradigmshifts-death
  ask paradigmshifts
  [
    if paradigmshifts-duration < 1
     [  die  ]
     set paradigmshifts-duration paradigmshifts-duration - 1
  ]
end

to education-death
  ask educations
  [
    move
    if education-duration < 1 [die]
    set education-duration education-duration - 1
  ]
end

to challenge-extinct
  if (count challenges = 0) and (infected = 1)
  [
     output-type "challenge clearance time "  output-print ticks
    set infected 0
  ]
end

to insert-challenges                               ; create an infection every button push
  output-type "challenge infection time "  output-print ticks
  set infected 1 ; noting that challenges have been put into the cell
    create-challenges challenge-load
    [
     set color active-color
     set size 1.25  ; easier to see
     set label-color blue - 2
     setxy random-xcor random-ycor
    ]
end

to infect-paradigmshifts
  output-type "paradigmshifts infection time "  output-print ticks
   create-paradigmshifts 1
    [
     set color red
     set size 20
     set label-color blue - 2
     setxy 0 0
     set paradigmshifts-duration 5
    ]

  ask domains
      [
        if random 100 < 95
        [ die ]
      ]
end

to insert-education
  output-type "education injection time "  output-print ticks
  create-educations education-load
    [
     set color active-color
     set size 1  ; easier to see
     set label-color blue - 2
     setxy random-xcor random-ycor
     set education-duration random 30
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
392
57
913
579
-1
-1
15.55
1
10
1
1
1
0
1
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
8
12
107
52
To Setup
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

BUTTON
111
12
192
52
to go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
7
58
390
205
Differential distribution of research domains
Time
Presence
0.0
250.0
0.0
250.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -5298144 true "" "plot count domains with [color = red]"
"pen-2" 1.0 0 -14730904 true "" "plot count domains with [color = blue]"
"pen-3" 1.0 0 -987046 true "" "plot count domains with [color = yellow]"
"pen-4" 1.0 0 -14439633 true "" "plot count domains with [color = lime]"
"pen-44" 1.0 0 -8431303 true "" "plot count domains with [color = brown]"
"pen-5" 1.0 0 -9276814 true "" "plot count domains with [color = grey]"
"pen-6" 1.0 0 -12345184 true "" "plot count domains with [color = cyan]"
"pen-7" 1.0 0 -3844592 true "" "plot count domains with [color = orange]"
"pen-8" 1.0 0 -2064490 true "" "plot count domains with [color = pink]"
"pen-9" 1.0 0 -7858858 true "" "plot count domains with [color = magenta]"
"pen-10" 1.0 0 -15040220 true "" "plot count domains with [color = green]"
"pen-11" 1.0 0 -14985354 true "" "plot count domains with [color = sky]"
"pen-12" 1.0 0 -15637942 true "" "plot count domains with [color = turquoise]"

PLOT
7
206
391
359
Amount of responses
Time
Responses
0.0
250.0
0.0
50.0
true
false
"" ""
PENS
"Responses" 1.0 0 -2674135 true "" "plot count responses"

BUTTON
396
583
564
616
Educate
insert-education
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
569
583
735
616
Paradigm shift
infect-paradigmshifts
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
740
583
909
616
Challenge theory
insert-challenges
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
7
521
393
672
Amount of challenges
Time
Challenges
0.0
250.0
0.0
50.0
true
false
"" ""
PENS
"Challenges" 1.0 0 -14439633 true "" "plot count challenges"

CHOOSER
568
627
734
672
response-impact
response-impact
"low" "high"
0

SLIDER
738
638
910
671
challenge-load
challenge-load
5
150
150.0
1
1
NIL
HORIZONTAL

SLIDER
395
639
567
672
education-load
education-load
5
150
50.0
1
1
NIL
HORIZONTAL

SLIDER
391
21
650
54
Domain-funding
Domain-funding
0
2
1.0
.1
1
million/semester
HORIZONTAL

MONITOR
316
78
381
123
Domains
count domains
17
1
11

PLOT
7
362
392
518
Domain's defensive memory
Time
Arguments
0.0
250.0
0.0
50.0
true
false
"" ""
PENS
"Domains" 1.0 0 -16777216 true "" "plot count domains with [ memory = 1 ]"

MONITOR
320
382
383
427
Memory
count domains with [ memory = 1 ]
17
1
11

MONITOR
654
10
799
55
Funding shortage factor
fund-short
17
1
11

MONITOR
320
225
383
270
Insights
count responses
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model demonstrates how T-regulatory (Treg) effectiveness correlates with inflammation in Rheumatoid Arthritis (RA). 

## LEGEND
"Y" cells = autoantibodies
Grey monsters = autoreactive Th1 cells
Green cells = T-regulatory cells 
Red squares = inflammation 
Yellow = the synovium  

## HOW IT WORKS

Rheumatoid Arthritis is an autoimmune disease. Autoimmunity occurs when the body is no longer able to differentiate between forgein invaders, such as viruses and pathogenic bacteria, from the body's own cells and tissues. This confusion causes the immune system to mistakenly attack the body's own cells and tissues. Autoantibodies and autoreactive T cells are two known contributing factors to the body attacking itself. In RA, autoantibodies and autoreactive T cells cause inflammation in the tissues that surround the joints (the synovium). The autoantibodies and autoreactive T cells can be suppressed, or deleted, by T-regulatory cells. However, in RA, it is known that the effectiveness of these T-regulatory cells can vary. Low T-regulatory effectiveness leads to a high population of autoantibodies, a high population of autoreactive T cells, and elevated inflammation - all playing a role in the progression of Rheumatoid Arthritis. Whereas, a higher T-regulatory effectiveness will enforce a lower population of autoantibodies and autoreactive T cells, in turn, showing decreased levels of inflammation. 
 
Adjust the Treg-effectiveness slider to compare levels of inflammation, autoantibodies, and autoreactive T cells in different Treg effective enviroments.   

## HOW TO USE IT

SETUP: Clears the world and displays autoreactive T cells, autoantibodies, and T-regulatory cells in the presence of a synovium lining a joint within the body. 

GO: Runs the simulation. 

TREG-EFFECTIVENESS SLIDER: The slider displays the effectiveness of Tregs and how successful they are in deleting autoantibodies and autoreactive T cells. A high value represents an efficient Treg population and a lower value represents a less effective Treg population. The effectiveness of the Treg population has an inverse relationship with the amount of inflammation present within the synovium, as well as, the amount of autoantibodies and autoreactive T cells.  

TREG-EFFECTIVENESS PLOT: Plots the number of autoantibodies and autoreactive T cells against time.

INFLAMMATION PLOT: Plots the amount of inflammation against time.

## THINGS TO NOTICE

A large population of autoantibodies and autoreactive T cells, as well as, low Treg-effectiveness will display elevated levels of inflammation. The inflammation decreases as the number of autoantibodies and autoreactive T cells decreases. 

## THINGS TO TRY

Increasing the Treg-effectiveness slider will create a more efficient Treg population. Decreasing the Treg slider will create a dysfunctional Treg population, leading to either a slower deletion or no deletion of autoantibodies and autoreactive T cells when the Treg-effectiveness slider is at 0. This, in turn, will cause inflammation and play a role in the progression of Rheumatoid Arthritis.

## EXTENDING THE MODEL

To create a more realistic Rhemuatoid Arthritis enviroment, try incorporating autoreactive effector B and T cells, as well as, adding other anti-inflammatory regulators, such as the cytokines TGFb and IL-10. Autoreactive effector B and T cells will represent proliferating autoreactive B and T cells that promote inflammation. TGFB and IL-10 will play a similar role to T-regulatory cells, where they will assist in depleting inflammation.  

## NETLOGO FEATURES

The "Tools-->Turtle Shapes Editor-->Import from Library" function allows you to edit the shapes of the turtles within the model

## RELATED MODELS

New Villi Food Model:
http://blog.modelingcommons.org/browse/one_model/5394#model_tabs_browse_info

Adaptive Immunity Model:
http://modelingcommons.org/browse/one_model/5691#model_tabs_browse_info

## CREDITS AND REFERENCES

Gift, S. and J.A. Klemens. (2017). Netlogo Adaptive Immunity Model 1.0. https://github.com/klemensj/Immune.

Wilensky, U. (2006). NetLogo Connected Chemistry 8 Gas Particle Sandbox model. http://ccl.northwestern.edu/netlogo/models/ConnectedChemistry8GasParticleSandbox. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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

book
false
3
Polygon -6459832 true true 30 195 150 255 270 135 150 75
Polygon -6459832 true true 30 135 150 195 270 75 150 15
Polygon -6459832 true true 30 135 30 195 90 150
Polygon -1 true false 39 139 39 184 151 239 156 199
Polygon -1 true false 151 239 254 135 254 90 151 197
Line -7500403 false 150 196 150 247
Line -7500403 false 43 159 138 207
Line -7500403 false 43 174 138 222
Line -7500403 false 153 206 248 113
Line -7500403 false 153 221 248 128
Polygon -1 true false 159 52 144 67 204 97 219 82

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

bulb
true
0
Circle -1184463 true false 73 0 152
Polygon -1184463 true false 219 104 205 133 185 165 174 190 165 210 165 225 150 225 147 119
Polygon -1184463 true false 79 103 95 133 115 165 126 190 135 210 135 225 150 225 154 120
Rectangle -7500403 true true 129 241 173 273
Line -16777216 false 135 225 135 240
Line -16777216 false 165 225 165 240
Line -16777216 false 150 225 150 240

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

dart
true
0
Polygon -7500403 true true 135 90 150 285 165 90
Polygon -7500403 true true 135 285 105 255 105 240 120 210 135 180 150 165 165 180 180 210 195 240 195 255 165 285
Rectangle -1184463 true false 135 45 165 90
Line -16777216 false 150 285 150 180
Polygon -16777216 true false 150 45 135 45 146 35 150 0 155 35 165 45
Line -16777216 false 135 75 165 75
Line -16777216 false 135 60 165 60

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

lightbulb
true
0
Polygon -7500403 true true 90 90 135 225 165 225 210 90 90 90
Polygon -7500403 true true 90 75 90 135
Polygon -7500403 true true 135 90 90 180
Circle -1184463 true false 75 15 148
Polygon -1184463 true false 90 90 120 195 180 195 210 90 75 90
Line -16777216 false 135 210 165 210
Line -16777216 false 120 195 180 195
Line -16777216 false 135 195 135 120
Line -16777216 false 165 195 165 90
Circle -16777216 false false 129 84 42
Circle -16777216 false false 135 75 30

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

monster
true
1
Polygon -7500403 true false 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true false 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true false 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true false 210 210 225 285 195 285 165 165
Polygon -7500403 true false 90 210 75 285 105 285 135 165
Rectangle -7500403 true false 135 165 165 270

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

question
true
1
Line -2674135 true 165 15 195 30
Line -2674135 true 225 90 210 120
Line -2674135 true 210 120 165 150
Line -2674135 true 105 45 90 75
Circle -2674135 true true 150 255 0
Line -2674135 true 150 195 165 150
Line -2674135 true 150 225 150 195
Line -2674135 true 225 75 225 90
Line -2674135 true 225 75 210 45
Line -2674135 true 210 45 195 30
Line -2674135 true 120 30 105 45
Line -2674135 true 150 15 165 15
Line -2674135 true 150 15 120 30
Circle -2674135 false true 135 240 28

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
1
Circle -2674135 false true 14 14 272
Circle -16777216 true false 15 15 270
Circle -7500403 true false 45 45 210
Circle -1 true false 60 60 180
Circle -16777216 true false 75 75 150
Circle -2674135 true true 120 120 60

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

warning
false
0
Polygon -7500403 true true 0 240 15 270 285 270 300 240 165 15 135 15
Polygon -16777216 true false 180 75 120 75 135 180 165 180
Circle -16777216 true false 129 204 42

wheel
false
1
Circle -7500403 true false 3 3 294
Circle -16777216 true false 30 30 240
Line -1 false 150 285 150 15
Line -1 false 15 150 285 150
Line -1 false 216 40 79 269
Line -1 false 40 84 269 221
Line -1 false 40 216 269 79
Line -1 false 84 40 221 269
Circle -2674135 true true 135 135 30
Circle -2674135 false true 0 0 300

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

y
true
0
Line -7500403 true 150 150 195 210
Line -7500403 true 150 150 105 210
Line -7500403 true 150 150 150 90
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
