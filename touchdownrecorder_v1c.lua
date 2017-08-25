-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Script:   touchdownrecorder.lua                                              
-- Version:  1.0
-- Build:    2017-08-23 03:24z +08
-- Author:   Wei Shuai <cpuwolf@gmail.com>
-- website:  https://github.com/cpuwolf/TouchDownRecorder
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
local touchdown_air_table = {}

local _TD_CHART_HEIGHT = 200

local max_table_elements = 500

show_touchdown_recorder = false
collect_touchdown_data = true
ground_counter = 0

local lastVS = 1.0
local lastG = 1.0
local lastPitch = 1.0
local lastAir = false

local gearFRef = XPLMFindDataRef("sim/flightmodel/forces/fnrml_gear")
local gForceRef = XPLMFindDataRef("sim/flightmodel2/misc/gforce_normal")
local vertSpeedRef = XPLMFindDataRef("sim/flightmodel/position/vh_ind_fpm2")
local pitchRef = XPLMFindDataRef("sim/flightmodel/position/theta")


function check_ground(n)
    if 0.0 ~= n then
        return true
        -- LAND
    end

    return false
    -- AIR
end

function is_on_ground()
    return check_ground(XPLMGetDataf(gearFRef))
end

function collect_flight_data()
    lastVS = XPLMGetDataf(vertSpeedRef)
    lastG = XPLMGetDataf(gForceRef)
    lastPitch = XPLMGetDataf(pitchRef)
    lastAir = check_ground(XPLMGetDataf(gearFRef))
    
    -- fill the table
    table.insert(touchdown_vs_table, lastVS)
    table.insert(touchdown_g_table, lastG)
    table.insert(touchdown_pch_table, lastPitch)
    table.insert(touchdown_air_table, lastAir)
    
    -- limit the table size to the given maximum
    if table.maxn(touchdown_vs_table) > max_table_elements then
        table.remove(touchdown_vs_table, 1)
        table.remove(touchdown_g_table, 1)
        table.remove(touchdown_pch_table, 1)
        table.remove(touchdown_air_table, 1)
    end
end

function draw_touchdown_graph()
    if collect_touchdown_data == true then
        collect_flight_data()
    end

    -- dont draw when the function isn't wanted
    if show_touchdown_recorder == false then return end
    
    -- draw background first
    local x = (SCREEN_WIDTH / 2) - max_table_elements
    local y = (SCREEN_HIGHT / 2) - 100
    XPLMSetGraphicsState(0,0,0,1,1,0,0)
    graphics.set_color(0, 0, 0, 0.50)
    graphics.draw_rectangle(x, y, x + (max_table_elements * 2), y + _TD_CHART_HEIGHT)
    
    -- calculate max vspeed
    max_vs_recorded = 0.0
    for k, vm in pairs(touchdown_vs_table) do
        if math.abs(vm) > math.abs(max_vs_recorded) then
            max_vs_recorded = vm
        end
    end
    max_vs_axis = 1000.0

    -- calculate max gforce
    max_g_recorded = 1.0
    for k, g in pairs(touchdown_g_table) do
        if g > max_g_recorded then
            max_g_recorded = g
        end
    end
    max_g_axis = 2.2

    -- calculate max pitch
    max_pch_recorded = 1.0
    for k, p in pairs(touchdown_pch_table) do
        if math.abs(p) > math.abs(max_pch_recorded) then
            max_pch_recorded = p
        end
    end
    max_pch_axis = 10.0
    
    -- and print on the screen
    graphics.set_color(1, 1, 1, 1)
    graphics.set_width(1)
    -- title
    draw_string(x + 5, y + _TD_CHART_HEIGHT - 15, "TouchDownRecorder V1.0 by cpuwolf")

    -- draw touch point vertical lines
    x_tmp = x
    local last_air_recorded = touchdown_air_table[1]
    for k, a in pairs(touchdown_air_table) do
        if a ~= last_air_recorded then
            graphics.draw_line(x_tmp, y, x_tmp, y + _TD_CHART_HEIGHT)
        end
        x_tmp = x_tmp + 2
        last_air_recorded = a
    end
    --graphics.draw_line(x + (max_table_elements * 2), y + _TD_CHART_HEIGHT, x + (max_table_elements * 2) + 10, y + _TD_CHART_HEIGHT)
    --graphics.draw_line(x + (max_table_elements * 2), y, x + (max_table_elements * 2) + 10, y)


    x_text = x + 5
    y_text = y + 15
    
    -- now draw the chart line
    graphics.set_color(0, 1, 0, 1)
    graphics.set_width(1)
    -- print text
    text_to_print = "Max "..string.format("%.02f", max_vs_recorded).." fpm "
    width_text_to_print = measure_string(text_to_print)
    draw_string_Helvetica_12(x_text, y_text, text_to_print)
    x_text = x_text + width_text_to_print
    -- draw line
    x_tmp = x
    y_tmp = y + (_TD_CHART_HEIGHT / 2)
    local last_vs_recorded = touchdown_vs_table[1]
    for k, v in pairs(touchdown_vs_table) do
        graphics.draw_line(x_tmp, y_tmp + (last_vs_recorded / max_vs_axis * _TD_CHART_HEIGHT), x_tmp + 2, y_tmp + (v / max_vs_axis * _TD_CHART_HEIGHT))
        if v == max_vs_recorded then
            graphics.draw_line(x_tmp, y, x_tmp, y + (_TD_CHART_HEIGHT))
        end
        x_tmp = x_tmp + 2
        last_vs_recorded = v
    end
    -- now draw the chart line
    graphics.set_color(0.054, 0.388, 1.0, 1)
    graphics.set_width(2)
    -- print text
    text_to_print = "Max "..string.format("%.02f", max_g_recorded).." G "
    width_text_to_print = measure_string(text_to_print)
    draw_string_Helvetica_12(x_text, y_text, text_to_print)
    x_text = x_text + width_text_to_print
    -- draw line
    x_tmp = x
    local last_g_recorded = touchdown_g_table[1]
    for k, g in pairs(touchdown_g_table) do
        graphics.draw_line(x_tmp, y + (last_g_recorded / max_g_axis * _TD_CHART_HEIGHT), x_tmp + 2, y + (g / max_g_axis * _TD_CHART_HEIGHT))
        if g == max_g_recorded then
            graphics.draw_line(x_tmp, y, x_tmp, y + (_TD_CHART_HEIGHT))
        end
        x_tmp = x_tmp + 2
        last_g_recorded = g
    end
    -- now draw the chart line
    graphics.set_color(1, 0, 0, 1)
    graphics.set_width(1)
    -- print text
    text_to_print = "Max "..string.format("%.02f", max_pch_recorded).." Degree "
    width_text_to_print = measure_string(text_to_print)
    draw_string_Helvetica_12(x_text, y_text, text_to_print)
    x_text = x_text + width_text_to_print
    -- draw line
    x_tmp = x
    y_tmp = y + (_TD_CHART_HEIGHT / 2)
    local last_pch_recorded = touchdown_pch_table[1]
    for k, p in pairs(touchdown_pch_table) do
        graphics.draw_line(x_tmp, y_tmp + (last_pch_recorded / max_pch_axis * _TD_CHART_HEIGHT), x_tmp + 2, y_tmp + (p / max_pch_axis * _TD_CHART_HEIGHT))
        if p == max_pch_recorded then
            graphics.draw_line(x_tmp, y, x_tmp, y + (_TD_CHART_HEIGHT))
        end
        x_tmp = x_tmp + 2
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
        if ground_counter == 4 then
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

add_macro("Show TouchDownRecorder", "show_touchdown_recorder = true", "show_touchdown_recorder = false", "deactivate")