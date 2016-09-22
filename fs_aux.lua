local m = {}
package.loaded[...] = m

require 'sys.base'
local sys = require 'sys'

function m.mkdirs(mkdir, exist, path)
	path = sys.path.nml(path)
	local parts = sys.str.split(path, '/')

	local dir = nil
	for _, part in ipairs(parts) do
		if dir then
			dir = dir .. '/' .. part
		else
			dir = part
		end

		if not exist(dir) then
			print('mkdir ', dir)
			mkdir(dir)
		end
	end
end
