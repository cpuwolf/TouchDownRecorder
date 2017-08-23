-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Script:   touchdownrecorder.lua                                              
-- Version:  1.0
-- Build:    2017-08-23 03:24z +08
-- Author:   Wei Shuai <cpuwolf@gmail.com>
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Usage
--
-- Just copy this file into the "Scripts" directory of FlyWithLua.
--
-- a TouchDown Graphic will be printed on your screen when airplane touch down to the ground
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

require "graphics"

local touchdown_vs_table = {}
local touchdown_g_table = {}
local touchdown_pch_table = {}

local max_table_elements = 500

show_touchdown_recorder = false
collect_touchdown_data = true
ground_counter = 0

local lastVS = 1
local lastG = 1.0
local lastPitch = 1

local gearFRef = XPLMFindDataRef("sim/flightmodel/forces/fnrml_gear")
--local gearFRef = XPLMFindDataRef("sim/flightmodel/forces/faxil_gear")
local gForceRef = XPLMFindDataRef("sim/flightmodel2/misc/gforce_normal")
local vertSpeedRef = XPLMFindDataRef("sim/flightmodel/position/vh_ind_fpm2")
local pitchRef = XPLMFindDataRef("sim/flightmodel/position/theta")


function is_on_ground()
    if 0.0 ~= XPLMGetDataf(gearFRef) then
        return 1
        -- LAND
    end

    return 0
    -- AIR
end

function collect_flight_data()
    lastVS = math.floor(XPLMGetDataf(vertSpeedRef))
    lastG = XPLMGetDataf(gForceRef)
    lastPitch = math.floor(XPLMGetDataf(pitchRef))
    
    -- fill the table
    table.insert(touchdown_vs_table, lastVS)
    table.insert(touchdown_g_table, lastG)
    table.insert(touchdown_pch_table, lastPitch)
    
    -- limit the table size to the given maximum
    if table.maxn(touchdown_vs_table) > max_table_elements then
        table.remove(touchdown_vs_table, 1)
        table.remove(touchdown_g_table, 1)
        table.remove(touchdown_pch_table, 1)
    end
end

function draw_touchdown_graph()
    if collect_touchdown_data == true then
        collect_flight_data()
    end

    -- dont draw when the function isn't wanted
    if show_touchdown_recorder == false then return end
    
    -- draw touch down chart
    -- draw background first
    local x = (SCREEN_WIDTH / 2) - max_table_elements
    local y = (SCREEN_HIGHT / 2) - 100
    XPLMSetGraphicsState(0,0,0,1,1,0,0)
    graphics.set_color(0, 0, 0, 0.75)
    graphics.draw_rectangle(x, y, x + (max_table_elements * 2), y + 200)
    
    -- calculate max vspeed
    for k, v in pairs(touchdown_vs_table) do
        if v > max_vs_recorded then
            max_vs_recorded = v
        end
    end
    --local max_vs_recorded = 1200.0

    -- calculate max gforce
    for k, g in pairs(touchdown_g_table) do
        if g > max_g_recorded then
            max_g_recorded = g
        end
    end
    --local max_g_recorded = 2.2

    -- calculate max pitch
    for k, p in pairs(touchdown_pch_table) do
        if p > max_pch_recorded then
            max_pch_recorded = p
        end
    end
    --local max_pch_recorded = 10
    
    -- and print on the screen
    graphics.set_color(1, 1, 1, 1)
    graphics.draw_line(x + (max_table_elements * 2), y + 200, x + (max_table_elements * 2) + 10, y + 200)
    graphics.draw_line(x + (max_table_elements * 2), y, x + (max_table_elements * 2) + 10, y)

    --text_to_print = "Max "..string.format("%.02f", max_g_recorded).." G"
    --width_text_to_print = measure_string(text_to_print)
    draw_string_Helvetica_12(x + (max_table_elements * 2) + 15, y, "Max "..string.format("%.02f", max_g_recorded).." G")
    draw_string_Helvetica_12(x + (max_table_elements * 2) + 15, y + 100, "Max "..tostring(max_vs_recorded).." fpm")
    draw_string_Helvetica_12(x + (max_table_elements * 2) + 15, y + 200, "Max "..tostring(max_pch_recorded).." degree")
    draw_string_Helvetica_12(x, y, "TouchDownRecorder V1.0")
    
    -- now draw the chart line
    graphics.set_color(0, 1, 0, 1)
    graphics.set_width(3)
    local last_vs_recorded = touchdown_vs_table[1]
    for k, v in pairs(touchdown_vs_table) do
        graphics.draw_line(x, y + (last_vs_recorded / max_vs_recorded * 200), x + 2, y + (v / max_vs_recorded * 200))
        if v == max_vs_recorded then
            graphics.draw_line(x, y, x, y + (v / max_vs_recorded * 200))
        end
        x = x + 2
        last_vs_recorded = v
    end
    -- now draw the chart line
    graphics.set_color(0, 0, 1, 1)
    graphics.set_width(3)
    local last_g_recorded = touchdown_g_table[1]
    for k, g in pairs(touchdown_g_table) do
        graphics.draw_line(x, y + (last_g_recorded / max_g_recorded * 200), x + 2, y + (g / max_g_recorded * 200))
        if g == max_g_recorded then
            graphics.draw_line(x, y, x, y + (g / max_g_recorded * 200))
        end
        x = x + 2
        last_g_recorded = g
    end
    -- now draw the chart line
    graphics.set_color(1, 0, 0, 1)
    graphics.set_width(3)
    local last_pch_recorded = touchdown_pch_table[1]
    for k, p in pairs(touchdown_pch_table) do
        graphics.draw_line(x, y + (last_pch_recorded / last_pch_recorded * 200), x + 2, y + (p / last_pch_recorded * 200))
        if p == max_pch_recorded then
            graphics.draw_line(x, y, x, y + (p / last_pch_recorded * 200))
        end
        x = x + 2
        last_pch_recorded = p
    end
end

function calc_touchdown()
    is_gnd = is_on_ground()
    if is_gnd then
        ground_counter = ground_counter + 1
        -- ignore debounce
        if ground_counter == 2 then
            show_touchdown_recorder = true
        end
        -- stop data collection
        if ground_counter == 10 then
            collect_touchdown_data = false
        end
        -- hide chart
        if ground_counter > 30 then
            show_touchdown_recorder = false
        end
    else
        ground_counter = 0
        collect_touchdown_data = true
    end
end


do_every_draw("draw_touchdown_graph()")
do_often("calc_touchdown()")

add_macro("Show TouchDown Recorder", "show_touchdown_recorder = true", "show_touchdown_recorder = false", "deactivate")