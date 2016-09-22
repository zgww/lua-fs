#!/usr/bin/lua

local fs = require 'fs'



function tos(v)
	if type(v) == 'string' then
		return "'" .. string.gsub(v, "'", "\\'") .. "'"
	end
	return tostring(v)
end
function dump(tbl, key, tabs)
	local sf = tabs and ',' or ''
	tabs = tabs or ''

	if type(tbl) == 'table' then
		if key then
			print(tabs .. key .. ' = {')
		else
			print(tabs .. '{')
		end
		for k, v in pairs(tbl) do
			if type(k) == 'number' then
				dump(v, nil, tabs .. '    ')
			else
				dump(v, k, tabs .. '    ')
			end
		end
		print(tabs .. '}' .. sf)
	else
		if key then
			print(tabs .. key .. ' = ' .. tos(tbl) .. sf)
		else
			print(tabs .. tos(tbl) .. sf)
		end
	end
end

dump(fs.list('.'))
dump(fs.stat('test.lua'))

print('----------')
for fname in fs.walk('.') do
	print(fname)
end

print('----------')
print('----------')


fs.mkdirs('src/xx')
fs.write_all('src/xx/hi.md', '# title')
print(fs.read_all('src/xx/hi.md'))

print('----------')
for fname in fs.dir('src') do
	print(fname)
end

print('---------- src is dir ', fs.is_dir('src'),
	'test.lua is dir', fs.is_dir('test.lua'))

fs.rename('src/xx/hi.md', 'src/xx/hello.md')
fs.copy('src/xx/hello.md', 'src/xx/hi2.md')
fs.remove('src/xx/hello.md')

fs.rmdirs_force('src')

print(fs.pexec('ls'))
