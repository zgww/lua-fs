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
	local iter, ud = lfs.dir(path)
	return function ()
		while true do
			local fname = iter(ud)

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
m.remove = os.remove
m.rename = os.rename
m.exec = os.execute --只执行，返回成功，exit, signal(0 defa)

--这是可以取得命令结果的
--mode cant be nil
function m.pexec(cmd, mode)
	local t = io.popen(cmd)
	local a = t:read('a')
	t:close()
	return a
end

m.mkdir = lfs.mkdir
m.rmdir = lfs.rmdir

function m.read(f, mode)
	return f:read(mode)
end
function m.write(f, ...)
	local succ, err = f:write(...)
	if not succ then
		error(string.format('write failed. err : %s', err))
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

function m.copy(fpath, tpath)
	local ff = m.open(fpath, 'r')
	assert(ff, 'copy failed. no fpath ' .. fpath)

	local tf = m.open(tpath, 'w+')
	assert(tf, 'copy failed. no tpath ' .. tpath)

	while true do
		local s = m.read(ff, 20480) --一次读取20k
		if not s then break end

		m.write(tf, s)
	end
	m.close(ff)
	m.close(tf)
end
