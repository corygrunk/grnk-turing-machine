-- grunk-turing-machine
-- crow is now a turing machine

Tab = require('tabutil')
local enc1 = 0
local enc2 = 0
local enc3 = 1.0

counter = 0
data = {999,999,999,999,999,999,999,999}
scale = {0,3,5,7,9,12,999}
knob_val = 0

function init() 
  clock.run(redraw_clock)
  
  crow.input[1].mode('stream', 0.1)
  crow.output[2].action = "ar(0.01, 0.5, 8, 'linear')"
  clock.run(main_clock)
  
  screen_dirty = true
end

function main_clock()
  while true do
    clock.sync(1)
    counter = counter + 1
    if counter > #data then counter = 1 end
    if knob_val == 0 then
      for i = 1, #data do
        data[i] = scale[math.random(1, #scale)]
      end
      
    else
        
    end
    if data[counter] ~= 999 then
      crow.output[1].volts = data[counter]/12
      crow.output[2]()
    end

    screen_dirty = true
  end
end

crow.input[1].stream = function(v)
  knob_val = math.floor(v)
end



function key(n,z)
  if n == 1 and z == 1 then
    print('Key 1')
  elseif n == 2 and z == 1 then
    print('Key 2')
  elseif n == 3 and z == 1 then
    print('Key 3')
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    enc1 = util.clamp(enc1 + d,0,100)
  elseif n == 2 then
    enc2 = util.clamp(enc2 + d,0,100)
  elseif n == 3 then
    enc3 = util.clamp(enc3 + d/100,0,2)
  end
  screen_dirty = true
end


function redraw()
  screen.clear()
  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  -- screen.pixel(0, 0) ----------- make a pixel at the north-western most terminus
  -- screen.pixel(127, 0) --------- and at the north-eastern
  -- screen.pixel(127, 63) -------- and at the south-eastern
  -- screen.pixel(0, 63) ---------- and at the south-western

  screen.move(10, 15)
  screen.text('Turning machine')
  
  for i = 1, #data do
    screen.move(i*10, 30)
    if data[i] == 999 then
      screen.level(0)
    else
      screen.level(6)
    end
    if counter == i then
      screen.level(15)
    end
    screen.move(i*10, 40 + data[i])
    screen.line_rel(6,0)
    screen.stroke()
  end
  
  screen.level(2)
  screen.move(10, 55)
  screen.line_rel(76,0)
  screen.stroke()


  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space

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
