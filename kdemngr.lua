#!/usr/bin/env lua
package.path = ";./?.lua";
require('sh');

local KDE_paths = {
	".config/plasma-org.kde.plasma.desktop-appletsrc",
	".config/kdeglobals",
	".local/share/plasma/",
	".config/kglobalshortcutsrc",
	".config/khotkeysrc",
	".config/kwinrc",
	".config/kwinrulesrc",
	".config/ksmserverrc",
	".config/autostart",
	".local/share/color-schemes/",
	".local/share/fonts/",
	".local/share/kwin/scripts",
}


local function backup_generate(paths)
	log("\n>>\n>>backup_generate START\n>>")

	local function check_foldername(name, index)
		if index == nil then index = 0 end

		local new_name = name..'-'..index
		if sh('ls | grep -Po "^'..new_name..'$"').status ~= 0 then
			return new_name
		end
		return check_foldername(name, index+1)
	end

	local backup_folder_name = check_foldername('kde_backup.'..sh('echo "$HOSTNAME@$USER"').out)
	sh('mkdir "'..backup_folder_name..'"')

	local dirname
	local check_syslink
	for _, path in ipairs(paths) do

		dirname = sh('dirname '..backup_folder_name..'/'..path).out
		sh('mkdir -p '..dirname)

		check_syslink = sh('if [ -L ~/"'..path..'" ]; then echo "t";  fi').out

		if check_syslink  == "t" then
			log('>> target path is a system link\n>> link path will be followed and copied')
			local syslink_path = sh('readlink ~/'..path).out
			sh('cp -r '..syslink_path..' "$(pwd)/'..dirname..'"')
		else
			sh('cp -r ~/'..path..' "$(pwd)/'..dirname..'"')
		end
	end -- FOR
	log("\n>>\n>>backup_generate END\n>>")
end -- BACKUP GENERATE




local function copy_restore(operation, paths)
	log("\n>>\n>>copy_restore START\n>>")
	local home_expanded=sh("echo ~").out..'/'

	local function copy(home_expanded, dirname, path, i)

			sh('mkdir -p '..dirname)
			local root_name = home_expanded..path

			if sh_syslink_check(root_name) then
				path = sh('readlink '..root_name).out
				sh("cp -r "..path.." "..dirname)
				return
			end

			sh("cp -r "..home_expanded..path.." "..dirname)
			log("item "..i)
	end
	local function paste(home_expanded, dirname, path, i)
		
			sh('mkdir -p '..home_expanded..dirname)
			sh("cp -r "..path.." "..home_expanded..dirname)
			log("item "..i)
	end

	for i, path in ipairs(paths) do

		local dirname = sh('dirname '..path).out

		if operation then
			copy(home_expanded,dirname,path,i)
		else
			paste(home_expanded,dirname,path,i)
		end

	end

	log("\n>>\n>>copy_restore END\n>>")
end


local actions = {
	copy = function()
		sh_q_enable_logs()
		copy_restore(true, KDE_paths)
	end,
	paste = function()
		sh_q_enable_logs()
		copy_restore(false, KDE_paths)
	end,
	backup = function()
		sh_q_enable_logs()
		backup_generate(KDE_paths)
	end
}

if actions[arg[1]] == nil then
	print("\nNo valid arguments provided\n>> args: copy; paste;backup")

print('\n'..[[
All available arguments:

copy    -> copies local files to this folder
paste   -> pastes files on this folder to their respective folders on this comptuer
backup  -> creates a backup of local files
]])
	os.exit()
end

actions[arg[1]]()


