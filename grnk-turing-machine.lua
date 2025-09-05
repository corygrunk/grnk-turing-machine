-- GRNK Turing Machine
-- Turing maching for norns

-- enc1: go from random to locked
-- enc2: loop length
-- key2: randomize sequence
-- key3: clear sequence

engine.name = 'PolyPerc'

Tab = require('tabutil')
MusicUtil = require('musicutil')

scale_names = {}
notes = {}

alt_mode = false
counter = 0
loop_length = 8
data = {999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999}
knob_val = 0
internal_knob_val = 0
rand_display = {'\u{0f8}', '\u{0b0}', '\u{02a}', '\u{07e}' } -- locked, evolve a little, evolve, random

function init() 
  crow.input[1].mode('stream', 0.1)
  crow.output[2].action = "ar(0.01, 0.5, 8, 'linear')"
  
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, MusicUtil.SCALES[i].name)
  end

  params:add_separator("TURING MACHINE")
  
  -- setting root notes using params
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end} -- by employing build_scale() here, we update the scale

  -- setting scale type using params
  params:add{type = "option", id = "scale", name = "scale",
    options = scale_names, default = 5,
    action = function() build_scale() end} -- by employing build_scale() here, we update the scale

  build_scale() -- builds initial scale
  
  params:add{type = "option", id = "outs", name = "outs",
  options = {"audio", "crow", "jf"},
  default = 1}
  
  params:add{type = "option", id = "note_div", name = "note division",
  options = {1, 2, 4, 8, 16},
  default = 3}

  params:add{type = "number", id = "prob", name = "probability",
  min = 0, max = 100, default = 75}
  
  clock.run(redraw_clock)
  clock.run(main_clock)
  
  screen_dirty = true
end

function build_scale()
  -- Generate scale notes (MIDI note numbers)
  local scale_notes = MusicUtil.generate_scale(params:get("root_note"), params:get("scale"), 2)
  
  -- Convert to CV voltages (semitones relative to C4)
  notes = {}
  for i = 1, #scale_notes do
    local cv_value = (scale_notes[i] - 60) -- Convert MIDI to semitones from C4
    table.insert(notes, cv_value)
  end
  
  -- Add rest value
  table.insert(notes, 999)
end

function main_clock()
  while true do
    clock.sync(1/params:get("note_div"))
    counter = counter + 1
    if counter > loop_length then counter = 1 end
    if counter == 1 and params:get('outs') == 1 then
      randomize_seq(internal_knob_val)
    elseif counter == 1 and params:get('outs') == 2 then
      randomize_seq(knob_val)
    else
        
    end
    if data[counter] ~= 999 then
      if math.random(0,99) < params:get("prob") then
        
        if params:get('outs') == 1 then -- 'audio'
          local freq = MusicUtil.note_num_to_freq(params:get("root_note") + data[counter])
          engine.hz(freq)
          engine.release(math.random(1,20) * 0.1)
        
        elseif params:get('outs') == 2 then  -- 'crow'
        -- Convert display value back to actual CV relative to root note
        local actual_cv = (params:get("root_note") + data[counter] - 60) / 12
        crow.output[1].volts = actual_cv
        crow.output[2]()
        
        elseif params:get('outs') == 3 then -- 'jf'
          print('jf')
        end
      end
    end
    screen_dirty = true
  end
end

function randomize_seq(strength)
  if strength == 0 then
    for i = 1, #data do
      data[i] = notes[math.random(1, #notes)]
    end
  elseif strength == -1 or strength == 1 then
    -- Stronger partial randomization (40% of loop_length)
    local num_to_change = math.max(1, math.floor(loop_length * 0.4 + 0.5))
    
    -- Create a list of indices we can change -- change this to preserve first note: for i = 2, loop_length do
    local changeable_indices = {}
    for i = 1, loop_length do
      table.insert(changeable_indices, i)
    end
    
    -- Randomly select which indices to change
    for j = 1, num_to_change do
      if #changeable_indices > 0 then
        local random_idx = math.random(1, #changeable_indices)
        local idx_to_change = changeable_indices[random_idx]
        
        -- Change the note at this index
        data[idx_to_change] = notes[math.random(1, #notes)]
        
        -- Remove this index so we don't change it again
        table.remove(changeable_indices, random_idx)
      end
    end
  elseif strength == -3 or strength == -2 or strength == 2 or strength == 3 then
    -- Calculate how many notes to change (15% of loop_length, minimum 1)
    local num_to_change = math.max(1, math.floor(loop_length * 0.15 + 0.5))
    
    -- Create a list of indices we can change -- change this to preserve first note: for i = 2, loop_length do
    local changeable_indices = {}
    for i = 1, loop_length do
      table.insert(changeable_indices, i)
    end
    
    -- Randomly select which indices to change
    for j = 1, num_to_change do
      if #changeable_indices > 0 then
        local random_idx = math.random(1, #changeable_indices)
        local idx_to_change = changeable_indices[random_idx]
        
        -- Change the note at this index
        data[idx_to_change] = notes[math.random(1, #notes)]
        
        -- Remove this index so we don't change it again
        table.remove(changeable_indices, random_idx)
      end
    end
  elseif strength == -4 or strength == -5 or strength == 4 or strength == 5 then
    -- sequence locked   
  end
end

function clear_seq()
  for i = 1, #data do
    data[i] = 999
  end    
end

crow.input[1].stream = function(v)
  knob_val = math.floor(v)
end

function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 and alt_mode == false then
    randomize_seq(0)
  elseif n == 3 and z == 1 and alt_mode == false then
    clear_seq()
  end
  screen_dirty = true
end

function enc(n,d)
  if n == 1 then
    internal_knob_val = util.clamp(internal_knob_val + d,0,5)
  elseif n == 2  and alt_mode == false then
    loop_length = util.clamp(loop_length + d,1,16)
  elseif n == 3  and alt_mode == false then
    -- encoder 3
  end
  screen_dirty = true
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  
  -- for troubleshooting
  -- screen.move(10, 15)
  -- screen.text(internal_knob_val)
  
  screen.move(120, 15)
  
  if params:get('outs') == 1 then
    if internal_knob_val == -5 or internal_knob_val == -4 or internal_knob_val == 4 or internal_knob_val == 5 then
      screen.text_right(rand_display[1])
    elseif internal_knob_val == -3 or internal_knob_val == -2 or internal_knob_val == 2 or internal_knob_val == 3 then
      screen.text_right(rand_display[2])
    elseif internal_knob_val == -1 or internal_knob_val == 1 then
      screen.text_right(rand_display[3])
    else
      screen.text_right(rand_display[4])
    end     
  elseif params:get('outs') == 2 or params:get('outs') == 3 then
    if knob_val == -5 or knob_val == -4 or knob_val == 4 or knob_val == 5 then
      screen.text_right(rand_display[1])
    elseif knob_val == -3 or knob_val == -2 or knob_val == 2 or knob_val == 3 then
      screen.text_right(rand_display[2])
    elseif knob_val == -1 or knob_val == 1 then
      screen.text_right(rand_display[3])
    else
      screen.text_right(rand_display[4])
    end    
  end

  
  -- Calculate step width to fit 16 steps across screen with padding
  local start_x = 8
  local end_x = 120
  local step_width = (end_x - start_x) / (#data - 1)
  
  for i = 1, #data do
    local x_pos = start_x + (i - 1) * step_width
    
    if data[i] == 999 or i > loop_length then
      screen.level(0)
    else
      screen.level(6)
    end
    if counter == i then
      screen.level(15)
    end
    
    -- Draw horizontal line representing the step value
    -- Add offset to keep lines above baseline (15 is baseline offset, +12 keeps negative values visible)
    screen.move(x_pos, 15 + data[i] + 12)
    screen.line_rel(5, 0)
    screen.stroke()
  end
  
  -- Draw baseline
  screen.level(2)
  screen.move(start_x, 55)
  local baseline_end_x = start_x + (loop_length) * step_width
  screen.line_rel(baseline_end_x - start_x, 0)
  screen.stroke()
  
  screen.fill()
  screen.update()
  screen_dirty = false
end

function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end


-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
