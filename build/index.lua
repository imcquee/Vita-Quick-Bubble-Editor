local white = Color.new(255, 255, 255);
local green = Color.new(0, 255, 0);
local red = Color.new(255, 0, 0);
local blue = Color.new(25,102,255);
local orange = Color.new(255,204,153);
local oldpad = SCE_CTRL_CROSS;

local start = 0;
local change = 0;
local db = 0;
local status = 0;
local results = 0;
clock = Timer.new();

-- Store titles
apptable = {};

-- Init a index
local i = 1;

local first = 1;  
local last = 25;

-- Confirm Message to save database
function confirm(msg)
	System.setMessage(msg, false, BUTTON_YES_NO);
	while true do
		Graphics.initBlend();
		Screen.clear();
		Graphics.termBlend();
		Screen.flip();
		local state = System.getMessageState();
		if state == FINISHED then
			return true;
		elseif state == CANCELED then
			return false;
		end
	end
end

function getData()
	db = Database.open("ur0:shell/db/app.db");
	results = Database.execQuery(db, "SELECT title FROM tbl_appinfo_icon WHERE type = 0");
	local value
	for y, app in ipairs(results) do
		value = {
			title = results[y].title;
			type = 1;
			init = results[y].title;
		}
		table.insert(apptable, value);
	end
	table.sort(apptable, function(a,b) return a.title < b.title end);
end



-- Preliminary Tasks
getData();
if System.doesDirExist("ux0:/data/QBE") == false then
	System.createDirectory("ux0:/data/QBE");
end


-- Main loop
while true do

	local y = 40;
	local x = 5;

	-- Write title and instructions
	Graphics.initBlend();
	Screen.clear();
	Graphics.debugPrint(5, 5, "Quick Bubble Editor", orange);
	Graphics.debugPrint(808, 400, "X   Rename", orange);
	Graphics.debugPrint(805, 430, "◯   Remove", orange);
	Graphics.debugPrint(805, 460, "△   Reset", orange);	
	Graphics.debugPrint(780, 490, "← →   Fast Scroll", orange);	
	Graphics.debugPrint(770, 520, "Start   Save", orange);		
	
	-- Write visible menu entries
	for j=first, last do
		local print = string.gsub(apptable[j].title, "\n", " ");
		if i == j then
			Graphics.debugPrint(x,y,'> ' .. print,green);
		elseif apptable[j].title ~= apptable[j].init then
			Graphics.debugPrint(x,y,print,blue);	
		elseif apptable[j].type == -1 then
			Graphics.debugPrint(x, y, print, red);
		else 
			Graphics.debugPrint(x, y, print, white);
		end	
		y = y + 20;
	end	
	Graphics.termBlend();


	
	-- Check for input
	pad = Controls.read();
	if Controls.check(pad, SCE_CTRL_START) and not Controls.check(oldpad, SCE_CTRL_START) then
		local flag = confirm("Save changes and reboot system?");
		if flag then 
			local handle = System.openFile("ur0:/shell/db/app.db", FREAD);
			local data = System.readFile(handle, System.sizeFile(handle));
			local out = System.openFile("ux0:/data/QBE/app.db", FCREATE);
			System.writeFile(out, data, System.sizeFile(handle));
			System.closeFile(handle);
			System.closeFile(out);
			for i, app in ipairs(apptable) do
				if apptable[i].type == -1 then
					db = Database.open("ur0:shell/db/app.db");
					Database.execQuery(db,"DELETE FROM tbl_appinfo_icon WHERE title =".."'"..apptable[i].title.."'");
				end
				if apptable[i].title ~= apptable[i].init then
					db = Database.open("ur0:shell/db/app.db");
					Database.execQuery(db,"UPDATE tbl_appinfo_icon SET title = ".."'"..apptable[i].title.."'".."WHERE title =".."'"..apptable[i].init.."'");
				end
			end
			Database.close(db);
			System.reboot();
		end
    elseif Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		if i>first then i=i-1
		elseif first-1>=1 then
			first,i,last=first-1,i-1,last-1
		end
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		if i<last then i=i+1
		elseif last+1<=#apptable then
			first,i,last=first+1,i+1,last+1
		end
	elseif Controls.check(pad, SCE_CTRL_RIGHT) then

		if Timer.getTime(clock) >= 30 then
			if i<last then i=i+1
			elseif last+1<=#apptable then
				first,i,last=first+1,i+1,last+1
			end	
			Timer.reset(clock);
		end
	elseif Controls.check(pad, SCE_CTRL_LEFT) then
		if Timer.getTime(clock) >= 30 then
			if i>first then i=i-1
			elseif first-1>=1 then
				first,i,last=first-1,i-1,last-1
			end
			Timer.reset(clock);
		end
	elseif Controls.check(pad, SCE_CTRL_SELECT) and not Controls.check(oldpad, SCE_CTRL_SELECT) then
		Database.close(db);	
		System.exit();
	elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) then
		if Keyboard.getState() ~= RUNNING then
			if apptable[i].type ~= -1 then apptable[i].type = -1;
			else apptable[i].type = 1;
			end
		end
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS) then
		change = i;
		Keyboard.clear();
		Keyboard.show("Change Title", apptable[i].title);
	elseif Controls.check(pad, SCE_CTRL_TRIANGLE) then
		break;
	end

	if Keyboard.getState() == FINISHED then
		Keyboard.clear();
		apptable[change].title = Keyboard.getInput();
		Keyboard.clear();
	end
	
	-- Update oldpad and flip screen
	oldpad = pad;
	Database.close(db);
	Screen.flip();
	
	
end