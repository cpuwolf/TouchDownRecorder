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
-- a TouchDown Graphic will be printed on your screen when airplane is down to the ground
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

require "graphics"

local touchdown_vs_table = {}
local max_table_elements = 500
show_touchdown_recorder = false

local lastVS = 1.0
local lastG = 1.0

local gearKoofRef = XPLMFindDataRef("sim/flightmodel/forces/faxil_gear");
local gForceRef = XPLMFindDataRef("sim/flightmodel2/misc/gforce_normal");
local vertSpeedRef = XPLMFindDataRef("sim/flightmodel/position/vh_ind_fpm2");

function draw_touchdown_graph()
    -- do nothing when the function isn't wanted
    if show_touchdown_recorder == false then return end

    lastVS = math.floor(XPLMGetDataf(vertSpeedRef));
    lastG = math.floor(XPLMGetDataf(gForceRef));
    
    -- fill the table
    table.insert(touchdown_vs_table, lastVS)
    
    -- limit the table size to the given maximum
    if table.maxn(touchdown_vs_table) > max_table_elements then
        table.remove(touchdown_vs_table, 1)
    end
    
    -- draw touch down graph
    -- draw background first
    local x = (SCREEN_WIDTH / 2) - max_table_elements
    local y = (SCREEN_HIGHT / 2) - 100
    XPLMSetGraphicsState(0,0,0,1,1,0,0)
    graphics.set_color(0, 0, 0, 0.75)
    graphics.draw_rectangle(x, y, x + (max_table_elements * 2), y + 200)
    
    -- calculate the maximum
    local max_vs_recorded = 0
    for k, v in pairs(touchdown_vs_table) do
        if v > max_vs_recorded then
            max_vs_recorded = v
        end
    end
    
    -- and print it on the screen
    graphics.set_color(1, 1, 1, 1)
    graphics.draw_line(x + (max_table_elements * 2), y + 200, x + (max_table_elements * 2) + 10, y + 200)
    graphics.draw_line(x + (max_table_elements * 2), y, x + (max_table_elements * 2) + 10, y)
    draw_string_Helvetica_12(x + (max_table_elements * 2) + 15, y, "  0 fpm")
    draw_string_Helvetica_12(x + (max_table_elements * 2) + 15, y + 200, tostring(max_vs_recorded).." fpm")
    
    -- now draw the chart line
    graphics.set_color(0, 1, 0, 1)
    graphics.set_width(3)
    local last_vs_recorded = touchdown_vs_table[1]
    for k, v in pairs(touchdown_vs_table) do
        graphics.draw_line(x, y + (last_vs_recorded / max_vs_recorded * 200), x + 2, y + (v / max_vs_recorded * 200))
        x = x + 2
        last_vs_recorded = v
    end
end

do_every_draw("draw_touchdown_graph()")

add_macro("Show TouchDown Recorder", "show_touchdown_recorder = true", "show_touchdown_recorder = false", "deactivate")