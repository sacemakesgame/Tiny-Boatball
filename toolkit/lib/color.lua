local color = {}

function color.hex_to_rgb(hex)
    local hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)) / 255, tonumber("0x"..hex:sub(3,4)) / 255, tonumber("0x"..hex:sub(5,6)) / 255}
end


color.sass = {
    blue = color.hex_to_rgb('0d6efd'),
    indigo = color.hex_to_rgb('6610f2'),
    purple = color.hex_to_rgb('#8082a3'),
    pink = color.hex_to_rgb('d63384'),
    red = color.hex_to_rgb('dc3545'),
    orange = color.hex_to_rgb('fd7e14'),
    yellow = color.hex_to_rgb('ffc107'),
    green = color.hex_to_rgb('198754'),
    teal = color.hex_to_rgb('20c997'),
    cyan = color.hex_to_rgb('0dcaf0'),
    gray = color.hex_to_rgb('adb5bd'),
    lgray = color.hex_to_rgb('E8ECEF'),
    dgray = color.hex_to_rgb('353A40'),
    black = color.hex_to_rgb('000000'),
    white = color.hex_to_rgb('FFFFFF'),
}



for k, v in pairs(color.sass) do
    color[k] = function(alpha)
        color.sass[k][4] = alpha or 1
        return color.sass[k]
    end
end

function color.lerp(from, to, weight)
    local r, g, b
    r = math.lerp(from[1], to[1], weight)
    g = math.lerp(from[2], to[2], weight)
    b = math.lerp(from[3], to[3], weight)
    return {r, g, b}
end


color.palette = {
    ally = color.hex_to_rgb('#778fe8'),
    opponent = color.hex_to_rgb('#ff7aa8'),
    yellow = color.hex_to_rgb('#ffdc81'),
    dark = color.hex_to_rgb('#335d8e'),
    light = color.hex_to_rgb('#fff3ca'),
    water = color.hex_to_rgb('#8bf0e0'),
    floor = color.hex_to_rgb('#85b7d0'),
    wall = color.hex_to_rgb('#b9e9aa'),
}

for k, v in pairs(color.palette) do
    color[k] = function(alpha)
        color.palette[k][4] = alpha or 1
        return color.palette[k]
    end
end


return color
