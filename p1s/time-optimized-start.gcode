;===== machine: P1S (Optimized for Speed) ========================
;===== date: 20241205 =====================
;===== turn on the HB fan & MC board fan =================
M104 S75 ;set extruder temp to turn on the HB fan and prevent filament oozing from nozzle
M710 A1 S255 ;turn on MC fan by default(P1S)

;===== reset machine status =================
M290 X40 Y40 Z2.6666666
G91
M17 Z0.4 ; lower the z-motor current
G380 S2 Z30 F300 ; G380 is same as G38; lower the hotbed , to prevent the nozzle is below the hotbed
G380 S2 Z-25 F300 ;
G1 Z5 F300;
G90
M17 X1.2 Y1.2 Z0.75 ; reset motor current to default
M960 S5 P1 ; turn on logo lamp
G90
M220 S100 ;Reset Feedrate
M221 S100 ;Reset Flowrate
M73.2   R1.0 ;Reset left time magnitude
M1002 set_gcode_claim_speed_level : 5
M221 X0 Y0 Z0 ; turn off soft endstop to prevent protential logic problem
G29.1 Z{+0.0} ; clear z-trim value first
M204 S10000 ; init ACC set to 10m/s^2

;===== heatbed preheat ====================
M1002 gcode_claim_action : 2
M140 S[bed_temperature_initial_layer_single] ;set bed temp
M190 S[bed_temperature_initial_layer_single] ;wait for bed temp

;===== PLA jamming prevention & toolhead cooling =================
{if filament_type[initial_extruder]=="PLA"}
    {if (bed_temperature[initial_extruder] >45)||(bed_temperature_initial_layer[initial_extruder] >45)}
    M106 P3 S180
    {elsif (bed_temperature[initial_extruder] >50)||(bed_temperature_initial_layer[initial_extruder] >50)}
    M106 P3 S255
    {endif};Prevent PLA from jamming
{endif}
M106 P2 S100 ; turn on big fan ,to cool down toolhead

;===== prepare print temperature and material ==========
M104 S[nozzle_temperature_initial_layer] ;set extruder temp
G91
G0 Z10 F1200
G90
G28 ; single comprehensive home operation
M975 S1 ; turn on vibration suppression
G1 X60 F12000
G1 Y245
G1 Y265 F3000

;===== material loading (simplified) ==========
M620 M
M620 S[initial_extruder]A   ; switch material if AMS exist
    M109 S[nozzle_temperature_initial_layer]
    G1 X120 F12000
    G1 X20 Y50 F12000
    G1 Y-3
    T[initial_extruder]
    G1 X54 F12000
    G1 Y265
M621 S[initial_extruder]A
M620.1 E F{filament_max_volumetric_speed[initial_extruder]/2.4053*60} T{nozzle_temperature_range_high[initial_extruder]}

M412 S1 ; ===turn on filament runout detection===

;===== simplified filament preparation =================
M109 S250 ;set nozzle to common flush temp for safety
M106 P1 S0
G92 E0
G1 E25 F200 ; single purge instead of double
M400
M104 S[nozzle_temperature_initial_layer] ; set target temp
G92 E0
G1 E25 F200 ; second purge with temp transition for better flow
M400
M106 P1 S255
G92 E0
G1 E5 F300
M109 S{nozzle_temperature_initial_layer[initial_extruder]-20} ; drop temp slightly for retraction
G92 E0
G1 E-0.5 F300

;===== basic nozzle cleaning (simplified) ===============================
M1002 gcode_claim_action : 14
M975 S1
M106 S255
G1 X65 Y230 F18000
G1 Y264 F6000
G1 X100 F18000 ; first wipe
G1 X70 F15000
G1 X100 F5000  ; second wipe
G1 X70 F15000
G1 X100 F5000  ; third wipe
G1 X70 F15000
G1 X90 F5000   ; final positioning wipe

; Basic nozzle contact cleaning for safety
G0 X128 Y261 Z-1.5 F20000  ; move to exposed steel surface
M104 S140 ; set temp down to safe level
M106 S255 ; turn on fan (G28 has turn off fan)
M221 S; push soft endstop status
M221 Z0 ;turn off Z axis endstop
G0 Z0.5 F20000
G0 X125 Y260.5 Z-1.01 ; single controlled contact
G0 X131 F211
G0 X124
G0 Z0.5 F20000
G0 X128
G2 I0.5 J0 F300 ; single circular motion
G2 I0.5 J0 F300
M109 S140 ; wait for safe temp
M221 R; pop softendstop status
G1 Z10 F1200

; Shake to empty waste bin after cleaning (P1S specific)
G1 X70 F9000       ; position for shake
G1 X76 F15000      ; shake to put down garbage
G1 X65 F15000
G1 X76 F15000      ; repeat shake
G1 X65 F15000
G1 X80 F6000       ; slower move to wipe area
G1 X95 F15000      ; wipe and shake
G1 X80 F15000
G1 X165 F15000     ; extended wipe and shake
M400

;===== bed leveling ==================================
M1002 judge_flag g29_before_print_flag
M622 J1
    M1002 gcode_claim_action : 1
    G29 A X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}
    M400
    M500 ; save cali data
M623

;===== home after wipe mouth (safety measure) ============================
M1002 judge_flag g29_before_print_flag
M622 J0
    M1002 gcode_claim_action : 13
    G28 ; re-home for accuracy after cleaning
M623


;=============turn on fans to prevent PLA jamming=================
{if filament_type[initial_extruder]=="PLA"}
    {if (bed_temperature[initial_extruder] >45)||(bed_temperature_initial_layer[initial_extruder] >45)}
    M106 P3 S180
    {elsif (bed_temperature[initial_extruder] >50)||(bed_temperature_initial_layer[initial_extruder] >50)}
    M106 P3 S255
    {endif};Prevent PLA from jamming
{endif}
M106 P2 S100 ; turn on big fan ,to cool down toolhead


M104 S{nozzle_temperature_initial_layer[initial_extruder]} ; set extrude temp earlier, to reduce wait time
;===== single mech mode check (simplified) ============================
G1 X128 Y128 Z10 F20000
M400 P200 ; brief pause for stability
M970.3 Q1 A7 B30 C80 H15 K0
M974 Q1 S2 P0
M975 S1
G1 F30000
G1 X230 Y15 ; move to safe position
G28 X ; re-home X for accuracy after mech check

;===== adaptive purge line (reduces waste) ===============================
G90
M83
T1000
M109 S{nozzle_temperature_initial_layer[initial_extruder]} ; ensure proper temp

{if first_layer_print_min[0]<=25 or first_layer_print_min[1]<=25 or first_layer_print_min[0]>=205 or first_layer_print_min[1]>=205}
    ; Default purge line for edge cases (original P1S style)
    G1 X100.0 Y-2.5 Z0.8 F18000 ;Move to start position
    G1 Z0.2
    G0 E2 F300
    G0 X150 E5 F{outer_wall_volumetric_speed/(0.3*0.5) * 60}
    G0 Y-3 E0.500 F{outer_wall_volumetric_speed/(0.3*0.5)/4 * 60}
    G0 E0.2
    G0 X99 E5 F{outer_wall_volumetric_speed/(0.3*0.5) * 60}
{else}
    ;===== Adaptive purge line (L-shaped near print area) ===============================
    G92 E0.0 ; reset extruder
    G0 Z5 F18000 ; Lift Z before moving
    
    ; First line (vertical part of L) - positioned near print area
    G1 X{first_layer_print_min[0]-15} Y{first_layer_print_min[1]+20} F6000.0
    G1 Z0.8 F18000 ; Lower Z to printing height
    G1 X{first_layer_print_min[0]-15} Y{first_layer_print_min[1]-10} E15 F{outer_wall_volumetric_speed/(0.3*0.5) * 60}
    G92 E0.0 ; reset extruder
    
    ; Second line (horizontal part of L) - creates L shape
    G1 X{first_layer_print_min[0]-5} Y{first_layer_print_min[1]-10} E8 F{outer_wall_volumetric_speed/(0.3*0.5) * 60}
    G92 E0.0 ; reset extruder
    
    ; Finishing touches with varying speeds for better adhesion
    G1 X{first_layer_print_min[0]} Y{first_layer_print_min[1]-10} E0.5 F{outer_wall_volumetric_speed/(0.3*0.5)/4 * 60}
    G1 X{first_layer_print_min[0]+5} Y{first_layer_print_min[1]-10} E0.5 F{outer_wall_volumetric_speed/(0.3*0.5) * 60}
    G1 X{first_layer_print_min[0]+10} Y{first_layer_print_min[1]-10} E0.5 F{outer_wall_volumetric_speed/(0.3*0.5)/4 * 60}
    G92 E0.0 ; reset extruder
    
    ; Small retraction and Z lift
    G1 E-0.5 F2100 ; small retraction
    G0 Z5 F18000 ; Lift Z before final move
    
    ; Move to safe position near print start
    G1 X{first_layer_print_min[0]+5} Y{first_layer_print_min[1]+5} F6000.0
    G92 E0.0 ; reset extruder
{endif}

M400 ; ensure completion

;===== textured PEI plate compensation ==============
{if curr_bed_type=="Textured PEI Plate"}
G29.1 Z{-0.04} ; for Textured PEI Plate
{endif}

;===== final setup and start print =============
M1002 gcode_claim_action : 0
M106 S0 ; turn off fan
M106 P2 S0 ; turn off big fan  
M106 P3 S0 ; turn off chamber fan
M975 S1 ; turn on mech mode suppression