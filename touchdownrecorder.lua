-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Script:   touchdownrecorder.lua                                              
-- Version:  3.0
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
local touchdown_elev_table = {}
local touchdown_eng_table = {}
local touchdown_agl_table = {}
local touchdown_tm_table = {}

local _TD_CHART_HEIGHT = 200

local max_table_elements = 500

show_touchdown_counter = 3
collect_touchdown_data = true
ground_counter = 10

local lastVS = 1.0
local lastG = 1.0
local lastPitch = 1.0
local lastAir = false
local lastElev = 0.0
local lastEng = 0.0
local lastAgl = 0.0
local lastTm = 0.0

local gearFRef = XPLMFindDataRef("sim/flightmodel/forces/fnrml_gear")
local gForceRef = XPLMFindDataRef("sim/flightmodel2/misc/gforce_normal")
local vertSpeedRef = XPLMFindDataRef("sim/flightmodel/position/vh_ind_fpm2")
local pitchRef = XPLMFindDataRef("sim/flightmodel/position/theta")
local elevatorRef = XPLMFindDataRef("sim/flightmodel2/controls/pitch_ratio")
local engRef = XPLMFindDataRef("sim/flightmodel2/engines/throttle_used_ratio")
local aglRef = XPLMFindDataRef("sim/flightmodel/position/y_agl")
local tmRef = XPLMFindDataRef("sim/time/total_flight_time_sec")

local landingString = ""
local IsLogWritten = true
local IsTouchDown = false

local close_x = 0
local close_y = 0

function write_log_file()
    -- get airport info
    navref = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
    local logAirportId
    local logAirportName
    -- all output we are not intereted in can be send to variable _ (a dummy variable)
    _, _, _, _, _, _, logAirportId, logAirportName = XPLMGetNavAidInfo(navref)

    buf = string.format("%s [%s] %s %s %s\n", os.date(), PLANE_TAILNUMBER, logAirportId, logAirportName, landingString)
    local file = io.open(SCRIPT_DIRECTORY.."TouchDownRecorderLog.txt", "a+")
    file:write(buf)
    file:close()
    IsLogWritten = true
end


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
    lastElev = XPLMGetDataf(elevatorRef)
    lastAgl = XPLMGetDataf(aglRef)
    lastTm = XPLMGetDataf(tmRef)
    local engtb = XPLMGetDatavf(engRef,0,4)
    lastEng = engtb[0]
    
    -- fill the table
    table.insert(touchdown_vs_table, lastVS)
    table.insert(touchdown_g_table, lastG)
    table.insert(touchdown_pch_table, lastPitch)
    table.insert(touchdown_air_table, lastAir)
    table.insert(touchdown_elev_table, lastElev)
    table.insert(touchdown_eng_table, lastEng)
    table.insert(touchdown_agl_table, lastAgl)
    table.insert(touchdown_tm_table, lastTm)
    
    -- limit the table size to the given maximum
    if table.maxn(touchdown_vs_table) > max_table_elements then
        table.remove(touchdown_vs_table, 1)
        table.remove(touchdown_g_table, 1)
        table.remove(touchdown_pch_table, 1)
        table.remove(touchdown_air_table, 1)
        table.remove(touchdown_elev_table, 1)
        table.remove(touchdown_eng_table, 1)
        table.remove(touchdown_agl_table, 1)
        table.remove(touchdown_tm_table, 1)
    end
end

function get_max_val(mytable)
    -- calculate max data
    local mabs = math.abs
    local max_data = 0.0
    for k, el in pairs(mytable) do
        if mabs(el) > mabs(max_data) then
            max_data = el
        end
    end
    return max_data
end

function draw_curve(mytable, cr,cg,cb, text_to_print, x_text_start, y_text_start, x_orig, y_orig, x_start, y_start, max_axis, max_data)
    -- now draw the chart line orange
    graphics.set_color(cr, cg, cb, 1)
    graphics.set_width(1)
    -- print text
    local x_text = x_text_start
    local y_text = y_text_start
    local width_text_to_print = measure_string(text_to_print)
    draw_string(x_text, y_text, text_to_print, cr, cg, cb)
    x_text = x_text + width_text_to_print
    -- draw line
    local x_tmp = x_start
    local y_tmp = y_start
    local last_recorded = mytable[1]
    local draw_max_counter = 0
    for k, p in pairs(mytable) do
        graphics.draw_line(x_tmp, y_tmp + (last_recorded / max_axis * _TD_CHART_HEIGHT), x_tmp + 2, y_tmp + (p / max_axis * _TD_CHART_HEIGHT))
        if p == max_data then
            if draw_max_counter == 0 then
                graphics.draw_line(x_tmp, y_orig, x_tmp, y_orig + (_TD_CHART_HEIGHT))
            end
            draw_max_counter = draw_max_counter + 1
        end
        x_tmp = x_tmp + 2
        last_recorded = p
    end

    return x_text
end

function draw_touchdown_graph()
    if collect_touchdown_data == true then
        collect_flight_data()
    end

    -- dont draw when the function isn't wanted
    if show_touchdown_counter <= 0 then return end
    
    -- draw background first
    local x = (SCREEN_WIDTH / 2) - max_table_elements
    local y = SCREEN_HIGHT - 250
    XPLMSetGraphicsState(0,0,0,1,1,0,0)
    graphics.set_color(0, 0, 0, 0.50)
    graphics.draw_rectangle(x, y, x + (max_table_elements * 2), y + _TD_CHART_HEIGHT)

    -- draw center line
    graphics.set_color(0, 0, 0, 1)
    graphics.set_width(3)
    graphics.draw_line(x, y + (_TD_CHART_HEIGHT / 2), x + (max_table_elements * 2), y + (_TD_CHART_HEIGHT / 2))

    -- draw horizontal axis
    x_tmp = x
    local last_tm_recorded = touchdown_tm_table[1]
    for k, a in pairs(touchdown_tm_table) do
        -- second axis
        if a - last_tm_recorded >= 1.0 then
            -- 1 second
            graphics.draw_line(x_tmp, y, x_tmp, y + _TD_CHART_HEIGHT)
            last_tm_recorded = touchdown_tm_table[k]
        end
        x_tmp = x_tmp + 2
    end

    -- and print on the screen
    graphics.set_color(1, 1, 1, 1)
    graphics.set_width(3)
    -- title
    draw_string(x + 5, y + _TD_CHART_HEIGHT - 15, "TouchDownRecorder V3.0 by cpuwolf", "grey")

    local x_text = x + 5
    local y_text = y + 8
    -- draw touch point vertical lines
    x_tmp = x
    landingString = ""
    local last_air_recorded = touchdown_air_table[1]
    for k, a in pairs(touchdown_air_table) do
        if a ~= last_air_recorded then
            if a then
                IsTouchDown = true
                -- draw vertical line
                graphics.draw_line(x_tmp, y + (_TD_CHART_HEIGHT/4), x_tmp, y + (_TD_CHART_HEIGHT*3/4))
                -- print text
                landingVS = touchdown_vs_table[k]
                landingG = touchdown_g_table[k]
                landingPitch = touchdown_pch_table[k]
                text_to_print = string.format("%.02f", landingVS).."fpm "..string.format("%.02f", landingG).."G "..string.format("%.02f", landingPitch).."Degree | "
                landingString = landingString..text_to_print
                width_text_to_print = measure_string(text_to_print)
                draw_string(x_text, y_text, text_to_print)
                x_text = x_text + width_text_to_print
            end
        end
        x_tmp = x_tmp + 2
        last_air_recorded = a
    end

    -- now draw the chart line green
    max_vs_axis = 1000.0
    max_vs_recorded = get_max_val(touchdown_vs_table)
    text_to_p = "Max "..string.format("%.02f", max_vs_recorded).."fpm "
    x_text = draw_curve(touchdown_vs_table, 0,1,0, text_to_p, x_text, y_text, x, y, x, y + (_TD_CHART_HEIGHT / 2), max_vs_axis, max_vs_recorded)

    -- now draw the chart line red
    max_g_axis = 2.0
    max_g_recorded = get_max_val(touchdown_g_table)
    text_to_p = "Max "..string.format("%.02f", max_g_recorded).."G "
    x_text = draw_curve(touchdown_g_table, 1,0.68,0.78, text_to_p, x_text, y_text, x, y, x, y, max_g_axis, max_g_recorded)

    -- now draw the chart line light blue
    max_pch_axis = 14.0
    max_pch_recorded = get_max_val(touchdown_pch_table)
    text_to_p = "Max pitch "..string.format("%.02f", max_pch_recorded).."Degree "
    x_text = draw_curve(touchdown_pch_table, 0.6,0.85,0.87, text_to_p, x_text, y_text, x, y, x, y + (_TD_CHART_HEIGHT / 2), max_pch_axis, max_pch_recorded)

    -- now draw the chart line orange
    max_elev_axis = 2.0
    max_elev_recorded = get_max_val(touchdown_elev_table)
    text_to_p = "Max elevator "..string.format("%.02f", max_elev_recorded*100.0).."% "
    x_text = draw_curve(touchdown_elev_table, 1.0,0.49,0.15, text_to_p, x_text, y_text, x, y, x, y + (_TD_CHART_HEIGHT / 2), max_elev_axis, max_elev_recorded)

    -- now draw the chart line yellow
    max_eng_axis = 2.0
    max_eng_recorded = get_max_val(touchdown_eng_table)
    text_to_p = "Max eng "..string.format("%.02f", max_eng_recorded*100.0).."% "
    x_text = draw_curve(touchdown_eng_table, 1.0,1.0,0.0, text_to_p, x_text, y_text, x, y, x, y + (_TD_CHART_HEIGHT / 2), max_eng_axis, max_eng_recorded)

    -- now draw the chart line red
    max_agl_axis = 200.0
    max_agl_recorded = get_max_val(touchdown_agl_table)
    text_to_p = "Max AGL "..string.format("%.02f", max_agl_recorded).."M "
    x_text = draw_curve(touchdown_agl_table, 1.0,0.1,0.1, text_to_p, x_text, y_text, x, y, x, y + (_TD_CHART_HEIGHT / 2), max_agl_axis, max_agl_recorded)

    -- draw close button on top-right
    graphics.set_color(1, 1, 1, 1)
    close_x = x + (2*max_table_elements) - 18
    close_y = y + _TD_CHART_HEIGHT - 18
    draw_string_Helvetica_18( close_x, close_y, "X")

end

function check_click( point_x, point_y, rect_x, rect_y, rect_w, rect_h)
    if point_x < rect_x then return false end
    if point_x > rect_x+rect_w then return false end
    if point_y < rect_y then return false end
    if point_y > rect_y+rect_h then return false end
    return true
end

function mouse_clck()
    -- check mouse click
    if check_click(MOUSE_X, MOUSE_Y, close_x, close_y, 18, 18) then
        show_touchdown_counter = 0
    end
end

function calc_touchdown()
    is_gnd = is_on_ground()
    if is_gnd then
        ground_counter = ground_counter + 1
        -- ignore debounce takeoff
        if ground_counter == 2 then
            show_touchdown_counter = 4
        -- stop data collection
        elseif ground_counter == 3 then
            collect_touchdown_data = false
            if IsTouchDown then
                IsLogWritten = false
            end
        elseif ground_counter == 5 then
            if not IsLogWritten then
                write_log_file()
            end
        end
    else
        -- in the air
        ground_counter = 0
        collect_touchdown_data = true
        IsTouchDown = false
    end
    -- count down
    if show_touchdown_counter > 0 then
        show_touchdown_counter = show_touchdown_counter - 1
    end
end

function toggle_show()
    if show_touchdown_counter > 0 then
        show_touchdown_counter = 0
    else
        show_touchdown_counter = 60
    end
end

do_every_draw("draw_touchdown_graph()")
do_often("calc_touchdown()")
do_on_mouse_click( "mouse_clck()")

add_macro("Show TouchDownRecorder", "show_touchdown_counter = 60")

create_command("FlyWithLua/TouchDownRecorder/Show", "Show TouchDownRecorder Chart", "toggle_show()","","")
