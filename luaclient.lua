-- rtu_client.lua
-- Sample Modbus RTU client using lua-libmodbus

local mb = require("libmodbus")

print("libmodbus runtime version:", mb.version())
print("lua-libmodbus compiled version:", mb.VERSION_STRING)

-- Serial configuration
local SERIAL_PORT = "/dev/ttyS3"   -- change as needed
local BAUDRATE    = 115200
local PARITY      = "N"            -- "N", "E", or "O"
local DATA_BITS   = 8
local STOP_BITS   = 1
local SLAVE_ID    = 1              -- Modbus slave/server ID

-- Register configuration
local START_ADDR  = 1--0              -- Modbus register address
local NUM_REGS    = 10--10

-- Create RTU context
local ctx, err = mb.new_rtu(
    SERIAL_PORT,
    BAUDRATE,
    PARITY,
    DATA_BITS,
    STOP_BITS
)

if not ctx then
    error("Failed to create RTU context: " .. tostring(err))
end

-- Optional debug output
ctx:set_debug(true)

-- Set slave ID
assert(ctx:set_slave(SLAVE_ID))

-- Connect to serial port
local ok, connect_err = ctx:connect()
if not ok then
    error("Failed to connect to " .. SERIAL_PORT .. ": " .. tostring(connect_err))
end

-- For RS-485 half duplex, enable this if supported by your binding/system.
-- On some embedded systems, RS-485 mode must be configured outside libmodbus.
-- pcall prevents script failure if the binding does not expose this function.
--pcall(function()
--    ctx:rtu_set_serial_mode(mb.RTU_RS485)
--end)

if ctx.rtu_set_serial_mode then
    --mode=ctx:rtu_get_serial_mode()
    --print("before serial mode:"..mode)
    ctx:rtu_set_serial_mode(mb.RTU_RS485)
    ctx:rtu_set_rs485_mode(0)--0=HalfDuplex, 1=FullDuplex
    --mode=ctx:rtu_get_serial_mode()
    --print("after serial mode:"..mode)
    print("Connected RS485")
end


print("Connected to Modbus RTU slave " .. SLAVE_ID)

-- Read holding registers
local regs, read_err = ctx:read_registers(START_ADDR, NUM_REGS)

if not regs then
    print("Read failed:", read_err or mb.strerror())
else
    print("Holding registers:")
    for i, value in ipairs(regs) do
        local addr = START_ADDR + i - 1
        print(string.format("  HR[%d] = %d", addr, value))
    end
end

-- Optional: write one holding register
local WRITE_ADDR = 3
local WRITE_VALUE = 5678

local write_ok, write_err = ctx:write_register(WRITE_ADDR, WRITE_VALUE)

if not write_ok then
    print("Write failed:", write_err or mb.strerror())
else
    print(string.format("Wrote HR[%d] = %d", WRITE_ADDR, WRITE_VALUE))
end

-- Disconnect and free context
ctx:close()
--ctx:free()

print("Done.")
