local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Options = Fluent.Options

local tower = workspace.tower
local sections = tower.sections

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local player = Players.LocalPlayer
local character = player.Character
local humanoidRootPart = character.HumanoidRootPart
local Humanoid = character.Humanoid
local autoFarming = false

local passes, fails, undefined = 0, 0, 0
local running = 0

local function getGlobal(path)
	local value = getfenv(0)

	while value ~= nil and path ~= "" do
		local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
		value = value[name]
		path = nextValue
	end

	return value
end

local function test(name, aliases, callback)
	running += 1

	task.spawn(function()
		if not callback then
			print("⏺️ " .. name)
		elseif not getGlobal(name) then
			fails += 1
			Fluent:Notify({
                Title = "Warning",
                Content = identifyexecutor() .. " does not support getconnections() which may get you detected much easier.",
                Duration = 8
            })
		else
			local success, message = pcall(callback)
	
			if success then
				passes += 1
                -- g
			else
				fails += 1
				Fluent:Notify({
                    Title = "Warning",
                    Content = identifyexecutor() .. " does not support getconnections() which may get you detected much easier.",
                    Duration = 8
                })
			end
		end
	
		local undefinedAliases = {}
	
		for _, alias in ipairs(aliases) do
			if getGlobal(alias) == nil then
				table.insert(undefinedAliases, alias)
			end
		end
	
		if #undefinedAliases > 0 then
			undefined += 1
			warn("⚠️ " .. table.concat(undefinedAliases, ", "))
		end

		running -= 1
	end)
end

test("getconnections", {}, function()
	local types = {
		Enabled = "boolean",
		ForeignState = "boolean",
		LuaConnection = "boolean",
		Function = "function",
		Thread = "thread",
		Fire = "function",
		Defer = "function",
		Disconnect = "function",
		Disable = "function",
		Enable = "function",
	}
	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(function() end)
	local connection = getconnections(bindable.Event)[1]
	for k, v in pairs(types) do
		assert(connection[k] ~= nil, "Did not return a table with a '" .. k .. "' field")
		assert(type(connection[k]) == v, "Did not return a table with " .. k .. " as a " .. v .. " (got " .. type(connection[k]) .. ")")
	end
end)

local GC = getconnections or get_signal_cons
	if GC then
		for i,v in pairs(GC(player.Idled)) do
			if v["Disable"] then
				v["Disable"](v)
			elseif v["Disconnect"] then
				v["Disconnect"](v)
			end
		end
	else
		local VirtualUser = cloneref(game:GetService("VirtualUser"))
		player.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end

-- god mode

function godmode()
    local Cam = workspace.CurrentCamera
    local Pos = Cam.CFrame
    local Human = character and character:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    local nHuman = Human:Clone()
    nHuman.Parent = character
    nHuman:SetStateEnabled(15, false)
    nHuman:SetStateEnabled(1, false)
    nHuman:SetStateEnabled(0, false)
    nHuman.BreakJointsOnDeath = true
    Human:Destroy()
    
    -- Update camera subject to the new humanoid
    workspace.CurrentCamera.CameraSubject = nHuman
    Cam.CFrame = Pos
    
    nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled = true
        task.wait()
        animateScript.Disabled = false
    end
    nHuman.Health = nHuman.MaxHealth
end

function tweenToSection(i)
    for _, v in pairs(workspace.tower.sections:GetChildren()) do
        if(v.Name == "lobby" or v.Name == "finish") then
            -- do nothing
        else
            if(v.i.Value == i) then
                local targetPosition = v.start.CFrame -- Your target CFrame
                local offset = Vector3.new(0, humanoidRootPart.Size.Y, 0) -- Offset to stand on top
                local finalCFrame = CFrame.new(targetPosition.Position + offset) * CFrame.Angles(0, targetPosition.Rotation.Y, 0) -- Ensure upright orientation
                local goal = {CFrame = finalCFrame}

                local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
                tween:Play()

                tween.Completed:Wait()

            else
                print("section not found -- tweentosec")
            end
        end
    end
end

function finishTween()
    local targetPosition = workspace.tower.sections.finish.start.CFrame -- Your target CFrame
    local offset = Vector3.new(0, humanoidRootPart.Size.Y, 0) -- Offset to stand on top
    local finalCFrame = CFrame.new(targetPosition.Position + offset) * CFrame.Angles(0, targetPosition.Rotation.Y, 0) -- Ensure upright orientation
    local goal = {CFrame = finalCFrame}

    local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
    tween:Play()

    tween.Completed:Wait()
end

function finishGlowTween()
    local targetPosition = workspace.tower.sections.finish.FinishGlow.CFrame -- Your target CFrame
    local offset = Vector3.new(0, humanoidRootPart.Size.Y, 0) -- Offset to stand on top
    local finalCFrame = CFrame.new(targetPosition.Position) * CFrame.Angles(0, targetPosition.Rotation.Y, 0) -- Ensure upright orientation
    local goal = {CFrame = finalCFrame}

    local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
    tween:Play()

    tween.Completed:Wait()
end

player.PlayerGui.timer.timeLeft:GetPropertyChangedSignal("Text"):Connect(function(text)
    if(player.PlayerGui.timer.timeLeft.Text == "0:00") then
        task.wait(5)
        if(autoFarming == true) then
            Fluent:Notify({
                Title = "Auto farm",
                Content = "Auto farm has started, again.",
                Duration = 8
            })
            startAutoFarm()
        end
    end
end)

-- noob tower
function noobTower()
    godmode()
    task.wait(1)
    if(autoFarming == true) then
        tweenToSection(2)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(3)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(4)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(5)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(6)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(7)
    else
        return nil
    end
    if(autoFarming == true) then
        finishTween()
    else
        return nil
    end
    if(autoFarming == true) then
        finishGlowTween()
    else
        return nil
    end
    task.wait(0.5)
    if(autoFarming == true) then
        character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        return nil
    end
end

-- pro tower
function proTower()
    godmode()
    task.wait(1)
    if(autoFarming == true) then
        tweenToSection(2)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(3)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(4)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(5)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(6)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(7)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(8)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(9)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(10)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(11)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(12)
    else
        return nil
    end
    if(autoFarming == true) then
        tweenToSection(13)
    else
        return nil
    end
    if(autoFarming == true) then
        finishTween()
    else
        return nil
    end
    if(autoFarming == true) then
        finishGlowTween()
    else
        return nil
    end
    task.wait(0.5)
    if(autoFarming == true) then
        character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        return nil
    end
end

function startAutoFarm()
    autoFarming = true
    Fluent:Notify({
        Title = "Auto farm",
        Content = "Auto farm has started.",
        Duration = 8
    })
    if(game.PlaceId == 1962086868) then -- noob tower
        noobTower()
    elseif(game.PlaceId == 3582763398) then -- pro tower
        proTower()
    end
end

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    local newHumanoid = newCharacter:WaitForChild("Humanoid")
    workspace.CurrentCamera.CameraSubject = newHumanoid
    print("Camera subject updated on respawn")
end)

local Window

if(game.PlaceId == 1962086868) then -- noob tower
    Window = Fluent:CreateWindow({
        Title = "Timeless Hub - Tower Of Hell (Noob Towers)",
        SubTitle = "by Timeless Community",
        TabWidth = 160,
        Size = UDim2.fromOffset(600, 360),
        Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
    })
elseif(game.PlaceId == 3582763398) then
    Window = Fluent:CreateWindow({
        Title = "Timeless Hub - Tower Of Hell (Pro Towers)",
        SubTitle = "by Timeless Community",
        TabWidth = 160,
        Size = UDim2.fromOffset(600, 360),
        Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
    })
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Toggle = Tabs.Main:AddToggle("AutoFarm", {Title = "Auto farm", Default = false })

Toggle:OnChanged(function()
    if(Options.AutoFarm.Value == false) then
        autoFarming = false
        print("not autofarming")
    else
        print("autofarming")
        startAutoFarm()
    end
end)

local Slider = Tabs.Settings:AddSlider("Slider", {
    Title = "Auto farm speed",
    Description = "Going too fast may get you detected, be cautious (0 is recommended, 1 maybe)",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        if(Value == 0) then
            tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        elseif(Value == 1) then
            tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        elseif(Value == 2) then
            tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        elseif(Value == 4) then
            tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        elseif(Value == 5) then
            tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        end
    end
})

Window:SelectTab(1)

local function DisableSignal(signal, name)
    local successes = true
    for i, connection in next, getconnections(signal) do
        local success, err = pcall(connection.Disable)
        if success then
            print('successfully disconnected ' .. name .. '\'s #' .. tostring(i) .. ' connection')
        else
            if err then
                print('failed to disconnect ' .. name .. '\'s # ' .. tostring(i) .. 'connection due to ' .. err)
            end
            successes = false
        end
    end
    return successes
end

local localscript = game:GetService('Players').LocalPlayer.PlayerScripts.LocalScript
local localscript2 = game:GetService('Players').LocalPlayer.PlayerScripts.LocalScript2

local localscriptSignal = localscript.Changed
local localscript2Signal = localscript2.Changed

if DisableSignal(localscriptSignal, 'localscript') then
    localscript:Destroy()
end
if DisableSignal(localscript2Signal, 'localscript2') then
    localscript2:Destroy()
end
