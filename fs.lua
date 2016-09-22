local m = {}
package.loaded[...] = m

local lfs = require 'lfs'

setmetatable(m, mt)

local function _join(path, filename)
	if string.match(path, '[/\\]$') then
		return path .. filename
	else 
		return path .. '/' .. filename
	end
end

local function _dir_info(path)
	local iter, ud = lfs.dir(path)
	return {
		path = path, 
		iter = iter,
		ud = ud,
	}
end

--iterator of dir walker
function m.walk(root)
	local stack = {
		_dir_info(root)
	}

	local function _iter()
		local top = stack[#stack]
		if not top then return end
		local n = top.iter(top.ud)
		if not n then table.remove(stack, #stack) end
		if not n or n == '.' or n == '..' then 
			return _iter()
		end

		local path = _join(top.path, n)
		if m.is_dir(path) then 
			table.insert(stack, _dir_info(path)) 
		end
		return path
	end
	return _iter
end

function m.stat(path)
	local attr = lfs.attributes(path)
	return attr and {
		mtime = attr.modification,
		atime = attr.access,
		ctime = attr.change,
		is_dir = attr.mode == 'directory',
	}
end

function m.is_dir(path)
	local s = m.stat(path)
	return s and s.is_dir
end

function m.dir(path)
	local iter = lfs.dir(path)
	return function ()
		while true do
			local fname = iter()

			if not fname then return nil end

			if fname ~= '.' and fname ~= '..' then 
				return fname
			end
		end
	end
end

--列出目录下的所有目录和文件
function m.list(path)
	local arr = {}
	for kid in m.dir(path) do
		table.insert(arr, kid)
	end
	return arr
end

function m.read_all(path)
	local f, err = io.open(path, 'r')
	if not f then return nil end

	local s = f:read('a')
	f:close()

	return s
end

function m.write_all(path, str, mode)
	local f, err = io.open(path, mode or 'w+')
	assert(f, err)

	f:write(str)

	f:close()
end

m.open = io.open
m.close = io.close
m.read = io.read
m.write = io.write
m.remove = os.remove
m.rename = os.rename
m.exec = os.execute

m.mkdir = lfs.mkdir
m.rmdir = lfs.rmdir
m.dir = lfs.dir


function m.mkdirs(mkdir, exist, path)
	path = string.gsub(path, '[\\/]+', '/')
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
function m.mkdirs(path)
	path = string.gsub(path, '[\\/]+', '/')

	local i = 1
	local len = #path
	while i <= len do
		local s = string.find(path, '/', i, true)
		if not s then
			s = len + 1
		end

		local cpath = string.sub(path, 1, s - 1)

		if cpath ~= '' and not m.stat(cpath) then
			m.mkdir(cpath)
		end

		i = s + 1
	end
end
function m.rmdirs_force(path)
	if not m.is_dir(path) then return end

	local files = m.list(path)

	for kid in m.dir(path) do
		local fpath = path .. '/' .. kid
		if m.is_dir(fpath) then
			m.rmdirs_force(fpath)
		else
			m.remove(fpath)
		end
	end
	m.rmdir(path)
end
