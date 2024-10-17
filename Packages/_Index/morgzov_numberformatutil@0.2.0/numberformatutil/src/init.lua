local NumberFormatUtil = {}

NumberFormatUtil.defaultPowers = {
	k = 3,
	m = 6,
	b = 9,
	t = 12,
}
NumberFormatUtil.defaultSF = 3

function NumberFormatUtil.comma(value: number, custom: string)
	custom = custom or ","
	local str = tostring(math.floor(value))
	local result = ""

	while #str > 3 do
		result = custom .. string.sub(str, #str - 2, #str) .. result
		str = string.sub(str, 1, #str - 3)
	end

	result = str .. result
	return result
end

function NumberFormatUtil.sigFigs(value: number, digits: number, roundOff: boolean)
	digits = digits or NumberFormatUtil.defaultSF
	if value == 0 then
		return 0
	end
	roundOff = roundOff or false

	local base = 10 ^ (math.floor(math.log10(value)) + 1 - digits)
	value = value / base
	if roundOff then
		value += 0.5
	end

	return base * math.floor(value)
end

function NumberFormatUtil.short(value: number, sf: number, powers: table)
	powers = powers or NumberFormatUtil.defaultPowers

	if value == 0 then
		return "0"
	end
	if value < 0 then
		return NumberFormatUtil.short(value, sf, powers)
	end

	sf = sf or NumberFormatUtil.defaultSF
	value = NumberFormatUtil.sigFigs(value, sf)

	local log = math.floor(math.log10(value))

	local highestBase = 0
	local letter = ""

	for k, v in powers do
		if v <= highestBase then
			continue
		end
		if value <= 10 ^ v then
			continue
		end
		highestBase = v
		letter = k
	end

	local base = 10 ^ highestBase
	return (value / base) .. letter
end

return NumberFormatUtil
