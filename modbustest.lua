-- rtu_client.lua
-- Sample Modbus RTU client using lua-libmodbus

local mb = require("libmodbus")
local socket = require("socket")

print("libmodbus runtime version:", mb.version())
print("lua-libmodbus compiled version:", mb.VERSION_STRING)

-- Serial configuration
local SERIAL_PORT = "/dev/ttyS3"   -- change as needed
local BAUDRATE    = 9600
local PARITY      = "N"            -- "N", "E", or "O"
local DATA_BITS   = 8
local STOP_BITS   = 1
local SLAVE_ID    = 1              -- Modbus slave/server ID

-- Register configuration
local START_ADDR  = 1              -- Modbus register address
local NUM_REGS    = 10--10

local function read_registers_loop(ctx, count, delay)
    local START_ADDR  = 1              -- Modbus register address
    local NUM_REGS    = 10--10

    local failures = 0
    for i = 1, count do
        local regs, err = ctx:read_registers(START_ADDR, NUM_REGS)

        if regs then
            print(i, "OK")
        else
            failures = failures + 1
            print(i, "FAIL", err)
        end

        socket.sleep(delay)
    end
    print("Count:", count, "Delay:", delay, "Failures:", failures)
end

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

--for k,v in pairs(getmetatable(ctx).__index) do
--	print(k,v)
--end

-- Optional debug output
ctx:set_debug(true)
--modbus_set_response_timeout(ctx, 0, 500000);

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
    ctx:rtu_set_rs485_mode(0)--0=HalfDuplex, 1=FullDuplex or mb.RTU_RS485_HALF
    --mode=ctx:rtu_get_serial_mode()
    --print("after serial mode:"..mode)
    print("Connected RS485, half duplex, termination enabled!")
end


print("Connected to Modbus RTU slave " .. SLAVE_ID)
socket.sleep(0.5)

print(ctx:get_response_timeout())
ctx:set_response_timeout(2, 0)
ctx:set_byte_timeout(0, 500000)

read_registers_loop(ctx,1000,0)
read_registers_loop(ctx,1000,0.1)
read_registers_loop(ctx,1000,0.5)

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

-- Disconnect and free context
ctx:close()
--ctx:free()

print("Done.")
