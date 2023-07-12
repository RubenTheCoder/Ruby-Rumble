--Services
RPST = game.ReplicatedStorage
Players = game.Players
UIS = game:GetService("UserInputService")
Lighting = game.Lighting

--Remotes
MineRemote = RPST:WaitForChild("MineRemote")
MiningDoneRemote = RPST:WaitForChild("MiningDoneRemote")

--Player Objects
Player = Players.LocalPlayer
Char = workspace:WaitForChild(Player.Name)
Humanoid = Char:WaitForChild("Humanoid")
HRP = Char:WaitForChild("HumanoidRootPart")
Animator = Humanoid:WaitForChild("Animator")
Camera = workspace.CurrentCamera
Feet = Char:WaitForChild("LeftFoot")
PlayerLight = script.PlayerLight:Clone()
PlayerLight.Parent = HRP
Device = "PC"
PlayerDepth = 0
if UIS.TouchEnabled and not UIS.MouseEnabled then
	Device = "Phone"
end

--Animations
MiningAnimation = Animator:LoadAnimation(script:WaitForChild("MiningAnimation"))

--GUI
if Device == "Phone" then
	ScreenGui = script.Parent.Phone
else
	ScreenGui = script.Parent.PC
end
ErrorLabel = ScreenGui:WaitForChild("ErrorLabel")
LayerLabel = ScreenGui:WaitForChild("Layer")
DepthLabel = ScreenGui:WaitForChild("Depth")
MiningInfoGui = ScreenGui:WaitForChild("MiningInfo")
MiningInfoBar = MiningInfoGui:WaitForChild("BarFrame"):WaitForChild("BarBG"):WaitForChild("Bar")
MiningInfoSymbol = MiningInfoGui:WaitForChild("Symbol")
MiningInfoOreName = MiningInfoGui:WaitForChild("OreName")

--Variables for User Input
CursorInput = false
CursorPosition = nil

--Variables for errors
AlreadyMining = false
E_Freefalling = false
E_OreOccupied = false

--Variables for Pickaxe
RealPickaxe = script:WaitForChild("Pickaxe")
PickaxePower = 0
PickaxeDelay = 0
PickaxeRange = 0
HoldingPickaxe = false
SelectionBox = script:WaitForChild("SelectionBox")

--Variables during mining
OreSize = 5
OreInfo = RPST:WaitForChild("OreInfo")
TapInWorld = false
ProcessedTapInWorld = false
MiningCooldown = false

--RaycastParams
RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Whitelist
RayParams.FilterDescendantsInstances = {
	workspace.MineFolder,
	workspace.Map,
	workspace.MineCover,
	workspace.CaveGenBorder}



function GetObjectHit(Position)
	local Ray = Camera:ScreenPointToRay(Position.X,Position.Y,0)
	local RayLine = workspace:Raycast(Ray.Origin,Ray.Direction * (16 * OreSize),RayParams)
	local Result = nil
	if RayLine then
		if RayLine.Instance then
			Result = RayLine.Instance
		end
	end
	return Result
end



function Click()
	if HoldingPickaxe and CursorInput and not MiningCooldown then
		while HoldingPickaxe and CursorInput and not MiningCooldown  do
			wait()
			local ObjectHit = GetObjectHit(CursorPosition)
			if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall 
				and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping 
				and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead 
				and Humanoid:GetState() ~= Enum.HumanoidStateType.Flying
				and Humanoid.FloorMaterial then
				E_Freefalling = false
				if not E_OreOccupied then
					ErrorLabel.Visible = false
				end
				if ObjectHit then
					if ObjectHit.Parent.Name == "MineFolder" then
						if (ObjectHit.Position - HRP.Position).Magnitude <= OreSize * PickaxeRange then
							if not ObjectHit:FindFirstChild("Occupied") then
								MiningCooldown = true
								Humanoid.WalkSpeed = 0
								Humanoid.JumpHeight = 0
								HRP.Anchored = true
								SelectionBox.Adornee = ObjectHit
								local ThisOreInfo = OreInfo:WaitForChild(ObjectHit:WaitForChild("RealName").Value)
								MiningInfoGui.Visible = true
								MiningInfoBar.Parent.Parent.Visible = true
								MiningInfoBar.Size = UDim2.new(0, 0,1, 0)
								MiningInfoBar.BackgroundColor3 = ThisOreInfo:WaitForChild("OreColor").Value
								MiningInfoOreName.TextColor3 = ThisOreInfo:WaitForChild("OreColor").Value
								MiningInfoSymbol.Image = "rbxassetid://"..ThisOreInfo:WaitForChild("OreSymbol").Value..""
								MiningInfoOreName.Text = ThisOreInfo:WaitForChild("ItemName").Value
								MineRemote:FireServer(ObjectHit,"Begin",PickaxeDelay)
								MiningAnimation:Play()
								MiningAnimation:AdjustSpeed(1 / PickaxeDelay)
								local ObjectPower = OreInfo:WaitForChild(ObjectHit:WaitForChild("RealName").Value):WaitForChild("Strength").Value
								local PercentageTop = ObjectPower
								repeat
									wait(PickaxeDelay * 0.1)
									local Percentage = 1 - ((ObjectPower / PercentageTop))
									MiningInfoBar.Size = UDim2.new(Percentage, 0,1, 0)
									ObjectPower -= PickaxePower * 0.1
									SelectionBox.Color3 = Color3.fromRGB(
										150 - (150 * Percentage),
										250,
										250 - (100 * Percentage))
									SelectionBox.SurfaceColor3 = Color3.fromRGB(
										250 - (150 * Percentage),
										250,
										250 - (100 * Percentage))
									SelectionBox.SurfaceTransparency = 1 - (Percentage / 4)
								until ObjectPower <= 0 or GetObjectHit(CursorPosition) ~= ObjectHit or CursorInput == false
								MiningAnimation:Stop()
								SelectionBox.Color3 = Color3.fromRGB(150, 250, 250)
								SelectionBox.SurfaceTransparency = 1		
								if GetObjectHit(CursorPosition) == ObjectHit and CursorInput then
									if ObjectHit:WaitForChild("RealName").Value ~= "Stone" then
										script.Collect:Play()
									end
									MiningDoneRemote:FireServer(ObjectHit)
									SelectionBox.Adornee = nil
									AlreadyMining = true
									while workspace.MineFolder:FindFirstChild(ObjectHit.Name) do
										wait()
									end
								else
									AlreadyMining = false
								end
								Humanoid.WalkSpeed = 16
								Humanoid.JumpHeight = 10
								HRP.Anchored = false
								MiningInfoGui.Visible = false
								MiningInfoBar.Parent.Parent.Visible = false
								MiningInfoBar.Size = UDim2.new(0, 0,1, 0)
								MineRemote:FireServer(ObjectHit,"End",PickaxeDelay)
								wait(PickaxeDelay)
								MiningCooldown = false
							else
								--Occupied
							end
						end
					end
				end
			else
				if not E_OreOccupied  and not AlreadyMining then
					E_Freefalling = true
					ErrorLabel.Visible = true
					ErrorLabel.Text = "You can't mine ores while not standing properly on top of something!"
				end
			end
		end
		if not E_OreOccupied then
			ErrorLabel.Visible = false
		end
	else

		--Place alternatives here
	end
end


function EquipPickaxe()
	local Pickaxe
	if not HoldingPickaxe then
		HoldingPickaxe = true
		Pickaxe = RealPickaxe:Clone()
		Pickaxe.Parent = Char
		Pickaxe.CFrame = Char:WaitForChild("RightHand").CFrame
		Char.RightHand:WaitForChild("Grip").Part1 = Pickaxe
		PickaxePower = Pickaxe:WaitForChild("Power").Value -- + power increase
		PickaxeDelay = Pickaxe:WaitForChild("Delay").Value
		PickaxeRange = Pickaxe:WaitForChild("Range").Value	
	else
		HoldingPickaxe = false
		if Char:FindFirstChild("Pickaxe") then
			Char:FindFirstChild("Pickaxe"):Destroy()
		end
		Char.RightHand:WaitForChild("Grip").Part1 = nil
	end
end



function InputStarted(InputObject,HittingGui)
	if 
		InputObject.UserInputType == Enum.UserInputType.MouseButton1 or
		InputObject.UserInputType == Enum.UserInputType.Touch then
		if not HittingGui then
			CursorInput = true
			Click()
		end
	end
end



function InputUpdate(InputObject,HittingGui)
	if not HittingGui then
		if 
			InputObject.UserInputType == Enum.UserInputType.MouseButton1 or
			InputObject.UserInputType == Enum.UserInputType.MouseMovement or
			InputObject.UserInputType == Enum.UserInputType.Touch then
			CursorPosition = Vector2.new(InputObject.Position.X,InputObject.Position.Y)
			local ObjectHit = GetObjectHit(CursorPosition)
			if ObjectHit and HoldingPickaxe then
				if ObjectHit.Parent.Name == "MineFolder" then
					if (ObjectHit.Position - HRP.Position).Magnitude <= OreSize * PickaxeRange then
						SelectionBox.Adornee = ObjectHit
						if ObjectHit:FindFirstChild("Occupied") and not E_Freefalling then
							if ObjectHit:FindFirstChild("Occupied").Value ~= Player.Name then
								ErrorLabel.Visible = true
								ErrorLabel.Text = "This ore is already being mined by "..ObjectHit:FindFirstChild("Occupied").Value.."!"
							else
								if not E_Freefalling then
									ErrorLabel.Visible = false
								end
							end
						else
							if not E_Freefalling then
								ErrorLabel.Visible = false
								local ThisOreInfo = OreInfo:WaitForChild(ObjectHit:WaitForChild("RealName").Value)
								MiningInfoGui.Visible = true
								MiningInfoBar.BackgroundColor3 = ThisOreInfo:WaitForChild("OreColor").Value
								MiningInfoOreName.TextColor3 = ThisOreInfo:WaitForChild("OreColor").Value
								MiningInfoSymbol.Image = "rbxassetid://"..ThisOreInfo:WaitForChild("OreSymbol").Value..""
								MiningInfoOreName.Text = ThisOreInfo:WaitForChild("ItemName").Value
							end
						end
					else
						SelectionBox.Adornee = nil
						MiningInfoGui.Visible = false
					end
				else if ObjectHit:FindFirstChild("SelectionBoxTarget") then
					else
						SelectionBox.Adornee = nil
						MiningInfoGui.Visible = false
					end
				end
			else
				SelectionBox.Adornee = nil
				MiningInfoGui.Visible = false
			end
		end
	end
end



function InputEnded(InputObject,HittingGui)
	if 
		InputObject.UserInputType == Enum.UserInputType.MouseButton1 or
		InputObject.UserInputType == Enum.UserInputType.Touch then
		if not HittingGui then
			CursorInput = false
		end
	end
end



local MoveLoop = coroutine.create(function()
	while true do
		wait()
		PlayerDepth = 4001 - math.round(HRP.Position.Y / OreSize)
		DepthLabel.Text = ""..PlayerDepth.." meters below the surface"
		if PlayerDepth < 1 then
			DepthLabel.Visible = false
			LayerLabel.Visible = false
		else
			DepthLabel.Visible = true
			LayerLabel.Visible = true
		end
		if PlayerDepth >= 1 and PlayerDepth < 200 then
			LayerLabel.Text = "Surface"
			Lighting.Ambient = Color3.fromRGB(200,200,200)
		end
		if PlayerDepth >= 200 and PlayerDepth < 500 then
			LayerLabel.Text = "Shallow zone"
			Lighting.Ambient = Color3.fromRGB(190,190,190)
		end
		if PlayerDepth >= 500 and PlayerDepth < 800 then
			LayerLabel.Text = "Light zone"
			Lighting.Ambient = Color3.fromRGB(180,180,180)
		end
		if PlayerDepth >= 800 and PlayerDepth < 1100 then
			LayerLabel.Text = "Silver zone"
			Lighting.Ambient = Color3.fromRGB(170,170,170)
		end
		if PlayerDepth >= 1100 and PlayerDepth < 1400 then
			LayerLabel.Text = "Cave zone"
			Lighting.Ambient = Color3.fromRGB(160,160,160)
		end
		if PlayerDepth >= 1400 and PlayerDepth < 1700 then
			LayerLabel.Text = "Gorge zone"
			Lighting.Ambient = Color3.fromRGB(150,150,150)
		end
		if PlayerDepth >= 1700 and PlayerDepth < 2000 then
			LayerLabel.Text = "Darkened zone"
			Lighting.Ambient = Color3.fromRGB(140,140,140)
		end
		if PlayerDepth >= 2000 and PlayerDepth < 2300 then
			LayerLabel.Text = "Gulf zone"
			Lighting.Ambient = Color3.fromRGB(130,130,130)
		end
		if PlayerDepth >= 2300 and PlayerDepth < 2600 then
			LayerLabel.Text = "Backlit zone"
			Lighting.Ambient = Color3.fromRGB(120,120,120)
		end
		if PlayerDepth >= 2600 and PlayerDepth < 2900 then
			LayerLabel.Text = "Far zone"
			Lighting.Ambient = Color3.fromRGB(110,110,110)
		end
		if PlayerDepth >= 2900 and PlayerDepth < 3200 then
			LayerLabel.Text = "Tumble zone"
			Lighting.Ambient = Color3.fromRGB(100,100,100)
		end
		if PlayerDepth >= 3200 and PlayerDepth < 3500 then
			LayerLabel.Text = "Abyss zone"
			Lighting.Ambient = Color3.fromRGB(90,90,90)
		end
		if PlayerDepth >= 3500 and PlayerDepth < 3800 then
			LayerLabel.Text = "Shadow zone"
			Lighting.Ambient = Color3.fromRGB(80,80,90)
		end
		if PlayerDepth >= 3800 and PlayerDepth < 4100 then
			LayerLabel.Text = "Deep zone"
			Lighting.Ambient = Color3.fromRGB(70,70,70)
		end
		if PlayerDepth >= 4100 and PlayerDepth < 4400 then
			LayerLabel.Text = "Grey zone"
			Lighting.Ambient = Color3.fromRGB(60,60,60)
		end
		if PlayerDepth >= 4400 and PlayerDepth < 4700 then
			LayerLabel.Text = "Chasm zone"
			Lighting.Ambient = Color3.fromRGB(50,50,50)
		end
		if PlayerDepth >= 5000 and PlayerDepth < 5300 then
			LayerLabel.Text = "Dark zone"
			Lighting.Ambient = Color3.fromRGB(40,40,40)
		end
		if PlayerDepth >= 5300 and PlayerDepth < 5600 then
			LayerLabel.Text = "Really dark zone"
			Lighting.Ambient = Color3.fromRGB(30,30,30)
		end
		if PlayerDepth >= 5600 and PlayerDepth < 5900 then
			LayerLabel.Text = "Black zone"
			Lighting.Ambient = Color3.fromRGB(20,20,20)
		end
		if PlayerDepth >= 5900 and PlayerDepth < 6200 then
			LayerLabel.Text = "Pitch black zone"
			Lighting.Ambient = Color3.fromRGB(10,10,10)
		end
		if PlayerDepth >= 6200 and PlayerDepth < 6500 then
			LayerLabel.Text = "Darkest zone"
			Lighting.Ambient = Color3.fromRGB(0,0,0)
		end
		if PlayerDepth >= 6500 and PlayerDepth < 6800 then
			LayerLabel.Text = "Blue zone"
			Lighting.Ambient = Color3.fromRGB(0,0,50)
		end
		if PlayerDepth >= 6800 and PlayerDepth < 7100 then
			LayerLabel.Text = "Sinister zone"
			Lighting.Ambient = Color3.fromRGB(50,0,100)
		end
		if PlayerDepth >= 7100 and PlayerDepth < 7400 then
			LayerLabel.Text = "Purple zone"
			Lighting.Ambient = Color3.fromRGB(100,50,200)
		end
		if PlayerDepth >= 7400 and PlayerDepth < 7700 then
			LayerLabel.Text = "Core zone"
			Lighting.Ambient = Color3.fromRGB(150,100,150)
		end
		if PlayerDepth >= 7700 and PlayerDepth < 8150 then
			LayerLabel.Text = "Twisted zone"
			Lighting.Ambient = Color3.fromRGB(200,50,100)
			Lighting.ColorCorrection.Saturation = -2.25
		end
		if PlayerDepth >= 8000 then
			HRP.Anchored = true
			Char:SetPrimaryPartCFrame(HRP.CFrame + workspace.SpawnLocation.Position + Vector3.new(0,10,0))
		end
		if PlayerDepth >= 200 and PlayerDepth < 7700 then
			Lighting.ColorCorrection.Saturation = 0.25
		end
	end
end)
coroutine.resume(MoveLoop)



UIS.InputBegan:Connect(InputStarted)
UIS.InputChanged:Connect(InputUpdate)
UIS.InputEnded:Connect(InputEnded)

ScreenGui:WaitForChild("EquipPickaxe").Activated:Connect(EquipPickaxe)
