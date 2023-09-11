-- RCP CAN Bus Logger Script
-- Copyright (c) 2023 The SECRET Ingredient!
-- GNU General Public License v3.0
--
-- https://thesecretingredient.neocities.org
--
-- This is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This software is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- 
-- See the GNU General Public License for more details. You should
-- have received a copy of the GNU General Public License along with
-- this code. If not, see <http://www.gnu.org/licenses/>.
--
-- This script is useful when reverse-engineering CAN
-- bus data and trying to detect behavior patterns.
-- It will passively monitor and log CAN message that 
-- are read from the bus.
-- 
-- The RaceCapture Serial Terminal CLI can be used to
-- view the log. Terminal capture can also be used to 
-- pipe the log stream to a local logfile.
--
-- This script is best used in conjunction with the 
-- following post processing scripts:
--
-- captureLog.sh - Captures the log to a text file
-- checkLog.sh   - Checks log files for errors/inconsistencies
-- processLog.sh - Processes log file for analysis
-- splitLog.sh   - Splits log files into separate files by messsage ID
--

-- CAN Bus Port Settings { Port 1, Port 2 }
local canEnable = { true, true }
local canBaud   = { 500000, 500000 }
local canTerm   = { 0, 0 }
local canTimout = { 5, 5 } 
local canLimit  = { 100, 100 } 
local canFilter = {} 

-- CAN Bus 1 Filter Configuration
canFilter[1] = { 
  {0,    }, -- Use 29-Bit CAN ID
  {0x000,}, -- Filters
  {0x000,}, -- Filter Masks
}

-- CAN Bus 2 Filter Configuration
canFilter[2] = { 
  {0,    }, -- Use 29-Bit CAN ID
  {0x000,}, -- Filters
  {0x000,}, -- Filter Masks
}

--
-- END OF USER CONFIGURATION OPTIONS
--

-- Set Tick Rate
setTickRate(1000)

-- Garbage Collection
local g_garbage = 0
local gc_interval = 1000

-- CAN Bus Filter Configuration Indexes
local gc_ext, gc_flt, gc_msk = 1, 2, 3

-- Initialize CAN Bus(es)
for i=1, #canEnable do

  -- Check CAN Bus Enable
  if canEnable[i] == true then

    -- Initialize CAN Bus
    initCAN(i-1, canBaud[i], canTerm[i])

    -- Log Addition of Bus Filters
    println(string.format("[CAN device] Adding Filters for CAN%d", i - 1))

    -- Create CAN Bus Message Filters
    for j=1, #canFilter[i][gc_ext] do 

        println(string.format("[CAN device] "
          ..
          (setCANfilter(i-1, j-1, canFilter[i][gc_ext][j], canFilter[i][gc_flt][j], canFilter[i][gc_msk][j]) == 1 and "Add Filter - " or "Add Fail - ") 
          .. 
          "BUS: [%d], ID: [%d], EXT: [%d], FLT: [0x%03X], MSK: [0x%03X]", i-1, j-1, canFilter[i][gc_ext][j], canFilter[i][gc_flt][j], canFilter[i][gc_msk][j]
        ))        
    end
  end
end

-- Receive Response Messages
function recvMessage(bus, timeout, limit)
  
  -- Define Message Processing Variables
  local count = 0
  local id, ext, data = nil, nil, nil

  -- Set Defaults for Optional Parameters
  if bus == nil then bus = 0 end
  if timeout == nil then timeout = 100 end
  if limit == nil then limit = 100 end

  -- Loop Through Buffer
  repeat 

    -- Retrieve Message From CAN Bus
    id, ext, data = rxCAN(bus, timeout)

    -- Increment Message Count
    count = count + 1

    -- Verify Message Received and Log CAN Messages if Logging is Enabled
    if id ~= nil then logCANData(bus, id, ext, message) end 

  -- Loop Threshold Condition
  until id == nil or count >= limit

end
   
-- Import Required Module
require (log_can)

-- Process Tick Events 
function onTick()

  -- Gollect Garbage
  if ((getUptime() - g_garbage) >= gc_interval) then collectgarbage() g_garbage = getUptime() end
  
  -- Log CAN Bus Messages
  for i=1, #canEnable do if canEnable[i] == true then recvMessage(i-1, canTimout[i], canLimit[i]) end end

end