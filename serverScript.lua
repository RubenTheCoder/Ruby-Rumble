Players = game.Players
MineRemote = game.ReplicatedStorage.MineRemote
MiningDoneRemote = game.ReplicatedStorage.MiningDoneRemote
ServerStorage = game.ServerStorage
OreInfo = game.ReplicatedStorage.OreInfo
Ores = game.ReplicatedStorage.Ores
MineAir = {}
MineFolder = workspace.MineFolder
MineCover = workspace.MineCover
CaveGenBorder = workspace.CaveGenBorder
OreChanceTable = {}

local CreateNewMine
CarvesDone = {}
NumberOfStone = 0
AlreadyMakingCave = false
JustMadeCave = 0

OreSize = 5
MineDepth = 8000

for Layer = 0,24 do
	OreChanceTable["Layer"..Layer..""] = {}
	local LayerTable = OreChanceTable["Layer"..Layer..""]
	LayerTable["Common"] = {}
	LayerTable["Uncommon"] = {}
	LayerTable["Rare"] = {}
	LayerTable["Epic"] = {}
	LayerTable["Legend"] = {}
	LayerTable["Ultra"] = {}
end

for index,Ore in pairs(OreInfo:GetChildren()) do
	if Ore.Name ~= "Stone" then
		for index,Object in pairs(Ore:GetChildren()) do
			if Object:IsA("StringValue") and string.sub(Object.Name,1,5) == "Layer" then
				local LayerTable = OreChanceTable[Object.Name]
				local TierTable = LayerTable[Object.Value]
				table.insert(TierTable,1,Ore.Name)
			end
		end
	end
end



function GenerateRandomRock(Y)
	local Winner
	local Layer = "Layer" ..math.ceil(((MineDepth * OreSize) - 200 - Y) / 300) + 1 ..""
	if Y == 32000 then
		Layer = "Layer0"
	end
	local Tier = "Stone"
	local RandomTier = math.random(1,1000000)
	if RandomTier > 900000 then
		Tier = "Common"
	end
	if RandomTier > 990000 then
		Tier = "Uncommon"
	end
	if RandomTier > 999000 then
		Tier = "Rare"
	end
	if RandomTier > 999900 then
		Tier = "Epic"
	end
	if RandomTier > 999990 then
		Tier = "Legend"
	end
	if RandomTier == 1000000 then
		Tier = "Ultra"
	end
	if Tier == "Stone" then
		Winner = "Stone"
	else
		local LayerTable = OreChanceTable[Layer]
		local TierTable = LayerTable[Tier]
		if #TierTable > 0 then
			Winner = TierTable[math.random(1,#TierTable)]
		else
			Winner = "Stone"
		end
	end
	--local Winner = Ores[OreChanceTable["Layer"..Layer..""][math.random(1,#OreChanceTable["Layer"..Layer..""])]]
	return Winner
end



local CarveCave



function PlaceStone(X,Y,Z,FromCave)
	if not MineAir["X"..X.."Y"..Y.."Z"..Z..""]
		and not MineFolder:FindFirstChild("X"..X.."Y"..Y.."Z"..Z.."")
		and Y <= OreSize * MineDepth then
		local Rock = GenerateRandomRock(Y)
		Rock = Ores[Rock]:Clone()
		Rock.Position = Vector3.new(X,Y,Z)
		Rock.Name = "X"..X.."Y"..Y.."Z"..Z..""
		Rock.Parent = MineFolder
		NumberOfStone += 1
		if NumberOfStone >= 100000 then
			--Do the rest here
			CreateNewMine()
		end
		if AlreadyMakingCave and not FromCave then
			if 
				table.find(CarvesDone,Vector3.new(X+OreSize,Y,Z)) or
				table.find(CarvesDone,Vector3.new(X-OreSize,Y,Z)) or
				table.find(CarvesDone,Vector3.new(X,Y,Z)) or
				table.find(CarvesDone,Vector3.new(X,Y+OreSize,Z)) or
				table.find(CarvesDone,Vector3.new(X,Y-OreSize,Z)) or
				table.find(CarvesDone,Vector3.new(X,Y,Z+OreSize)) or
				table.find(CarvesDone,Vector3.new(X,Y,Z-OreSize)) then
				local CaveBorderStone = game.ReplicatedStorage.CaveBorderStone:Clone()
				CaveBorderStone.Position = Vector3.new(X,Y,Z)
				CaveBorderStone.Parent = CaveGenBorder
			end
		end
		if math.random(1,1000) == 1 and Y < OreSize * MineDepth - (5 * OreSize) and not AlreadyMakingCave and not FromCave then
			local CaveRoutine = coroutine.create(function()
				CarveCave(Vector3.new(X + (OreSize * math.random(-OreSize,OreSize)),Y - (OreSize * math.random(OreSize,16)),Z + (OreSize * math.random(-OreSize,OreSize))))
			end)
			coroutine.resume(CaveRoutine)
		end
	end
end





function CarveCave(StartPos)
	AlreadyMakingCave = true
	--The bounds of the cave maximum
	local MaxGeneration = math.random(1,16000)
	local Generation = 0
	--The randomness factor that makes it more likely to not generate new CaveAir the further it is from the origin
	local LikelyhoodFactor = 45 / MaxGeneration
	local Likelyhood = 5
	--Tables with new carves to perform
	local CarveList = {}
	local NewCarvs = {}
	--Creates the first step
	table.insert(CarveList,StartPos)
	--Generates new air blocks and randomly stops that until there is no more
	while Generation <= MaxGeneration and #CarveList > 0 do
		Generation += 1
		local Waiter = 0
		for index,Carve in pairs(CarveList) do
			Waiter += 1
			local X = Carve.X
			local Y = Carve.Y
			local Z = Carve.Z
			if not MineFolder:FindFirstChild("X".. X .."Y".. Y .."Z".. Y .."") and not MineAir["X".. X .."Y".. Y .."Z".. Z ..""] then
				MineAir["X".. X .."Y".. Y .."Z".. Z ..""] = true
			end
			local function SpawnCaveAir(CarvePos)
				if math.random(1,50) > Likelyhood then
					if not table.find(NewCarvs,CarvePos) then
						table.insert(NewCarvs,CarvePos)
					end
				else
					if not table.find(CarvesDone,CarvePos) then
						table.insert(CarvesDone,CarvePos)
					end
					--if not MineFolder:FindFirstChild("X".. X .."Y".. Y .."Z".. Y .."") then
					--	MineAir["X"..CarvePos.X .."Y"..CarvePos.Y .."Z".. CarvePos.Z ..""] = true -- ?
					--end
				end
			end
			SpawnCaveAir(Carve + Vector3.new(OreSize,0,0))
			SpawnCaveAir(Carve + Vector3.new(-1 * OreSize,0,0))
			SpawnCaveAir(Carve + Vector3.new(0,OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(0,-1 * OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(0,0,OreSize))
			SpawnCaveAir(Carve + Vector3.new(0,0,-1 * OreSize))
			SpawnCaveAir(Carve + Vector3.new(OreSize,OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(OreSize,-1 * OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(-1 * OreSize,OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(-1 * OreSize,-1 * OreSize,0))
			SpawnCaveAir(Carve + Vector3.new(0,OreSize,OreSize))
			SpawnCaveAir(Carve + Vector3.new(0,OreSize,-1 * OreSize))
			SpawnCaveAir(Carve + Vector3.new(0,-1 * OreSize,OreSize))
			SpawnCaveAir(Carve + Vector3.new(0,-1 * OreSize,-1 * OreSize))
			SpawnCaveAir(Carve + Vector3.new(OreSize,0,OreSize))
			SpawnCaveAir(Carve + Vector3.new(-1 * OreSize,0,OreSize))
			SpawnCaveAir(Carve + Vector3.new(OreSize,0,-1 * OreSize))
			SpawnCaveAir(Carve + Vector3.new(-1 * OreSize,0,-1 * OreSize))
			Likelyhood += LikelyhoodFactor
			if Waiter == 100 then
				Waiter = 0
				wait()
			end
		end
		CarveList = NewCarvs
		NewCarvs = {}
		wait()	
	end
	--Now its gonna create a wall for the cave
	local Waiter = 0
	for index,CaveAir in pairs(CarvesDone) do
		Waiter += 1
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y,CaveAir.Z,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y,CaveAir.Z,true)
		PlaceStone(CaveAir.X,CaveAir.Y+OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X,CaveAir.Y-OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X,CaveAir.Y,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X,CaveAir.Y,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y+OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y-OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y+OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y-OreSize,CaveAir.Z,true)
		PlaceStone(CaveAir.X,CaveAir.Y+OreSize,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X,CaveAir.Y+OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X,CaveAir.Y-OreSize,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X,CaveAir.Y-OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y+OreSize,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y+OreSize,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y-OreSize,CaveAir.Z+OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y+OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y-OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X+OreSize,CaveAir.Y-OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y+OreSize,CaveAir.Z-OreSize,true)
		PlaceStone(CaveAir.X-OreSize,CaveAir.Y-OreSize,CaveAir.Z+OreSize,true)
		if Waiter == 100 then
			Waiter = 0
			wait()
		end
	end
	CarvesDone = {}
	CaveGenBorder:ClearAllChildren()
	wait(5)
	AlreadyMakingCave = false
end



function CreateNewMine()
	MineCover.Transparency = 0
	MineCover.CanCollide = true
	MineAir = {}
	if #MineFolder:GetChildren() ~= 0 then
		MineFolder:GetChildren():Destroy()
	end
	for X = 0,15 do
		for Z = 0,15 do
			PlaceStone(X * OreSize,OreSize * MineDepth,Z * OreSize,false)

			MineAir["X".. X * OreSize .."Y".. (OreSize * MineDepth) + OreSize .."Z".. Z * OreSize ..""] = true
		end
		wait()
	end
	for X = 0,15 do
		MineAir["X".. X * OreSize .."Y".. (OreSize * MineDepth) .."Z".. (-1 * OreSize) ..""] = true
		MineAir["X".. X * OreSize .."Y".. ((OreSize * MineDepth) - OreSize) .."Z".. (-1 * OreSize) ..""] = true
		wait()
	end
	for X = 0,15 do
		MineAir["X".. X * OreSize .."Y".. OreSize * MineDepth .."Z".. OreSize * 16 ..""] = true
		MineAir["X".. X * OreSize .."Y".. ((OreSize * MineDepth) - OreSize) .."Z".. OreSize * 16 ..""] = true
		wait()
	end
	for Z = 0,15 do
		MineAir["X".. (-1 * OreSize) .."Y".. OreSize * MineDepth .."Z".. Z * OreSize ..""] = true
		MineAir["X".. (-1 * OreSize) .."Y".. ((OreSize * MineDepth) - OreSize) .."Z".. Z * OreSize ..""] = true
		wait()
	end
	for Z = 0,15 do
		MineAir["X".. OreSize * 16 .."Y".. OreSize * MineDepth .."Z".. Z * OreSize ..""] = true
		MineAir["X".. OreSize * 16 .."Y".. ((OreSize * MineDepth) - OreSize) .."Z".. Z * OreSize ..""] = true
		wait()
	end
	MineCover.Transparency = 1
	MineCover.CanCollide = false
end



function MiningStatusChange(Player,Object,Status,PickaxeDelay)
	if Status == "Begin" then
		local Lock = Instance.new("StringValue")
		Lock.Name = "Occupied"
		Lock.Value = Player.Name
		Lock.Parent = Object
		local Char = workspace:FindFirstChild(Player.Name)
		local PickaxeSound
		if Char then
			if not Char:FindFirstChild("PickaxeSound") then
				PickaxeSound = script.PickaxeSound:Clone()
				PickaxeSound.Parent = workspace:WaitForChild(Player.Name)
			else
				PickaxeSound = Char:FindFirstChild("PickaxeSound")
			end
		end
		PickaxeSound.PlaybackSpeed = PickaxeSound.TimeLength / PickaxeDelay
		PickaxeSound.Playing = true
	end
	if Status == "End" then
		if workspace.MinePlatforms:FindFirstChild(Player.Name) then
			workspace.MinePlatforms:FindFirstChild(Player.Name):Destroy()
		end
		if Object:FindFirstChild("Occupied") then
			if Object:FindFirstChild("Occupied").Value == Player.Name then
				Object:FindFirstChild("Occupied"):Destroy()
			end
		end
		local Char = workspace:FindFirstChild(Player.Name)
		if Char then
			if Char:FindFirstChild("PickaxeSound") then
				Char:FindFirstChild("PickaxeSound"):Stop()
			end
		end
		if Object:FindFirstChild("PickaxeSound") then
			Object:FindFirstChild("PickaxeSound"):Destroy()
		end
	end
end



function MineRequest(Player,Object)
	local PlayerFolder = ServerStorage.PlayerFolders:WaitForChild(Player.UserId)
	if PlayerFolder then
		local Inventory = PlayerFolder:WaitForChild("Inventory")
		local OreToGive = Object:WaitForChild("RealName").Value
		if Object then
			if Inventory:FindFirstChild(OreToGive) then
				Inventory:FindFirstChild(OreToGive).Value += 1
			else
				local NewValue = Instance.new("IntValue")
				NewValue.Name = OreToGive
				NewValue.Value = 1
				NewValue.Parent = Inventory
			end
		end
		local ObjectX = Object.Position.X
		local ObjectY = Object.Position.Y
		local ObjectZ = Object.Position.Z
		MineAir["X"..ObjectX.."Y"..ObjectY.."Z"..ObjectZ..""] = true
		Object:Destroy()
		PlaceStone(ObjectX,ObjectY - (OreSize * 2),ObjectZ,false)
		PlaceStone(ObjectX,ObjectY - OreSize,ObjectZ,false)
		PlaceStone(ObjectX + OreSize,ObjectY,ObjectZ,false)
		PlaceStone(ObjectX - OreSize,ObjectY,ObjectZ,false)
		PlaceStone(ObjectX,ObjectY + OreSize,ObjectZ,false)
		PlaceStone(ObjectX + OreSize,ObjectY + OreSize,ObjectZ,false)
		PlaceStone(ObjectX - OreSize,ObjectY + OreSize,ObjectZ,false)
		PlaceStone(ObjectX,ObjectY - OreSize,ObjectZ,false)
		PlaceStone(ObjectX + OreSize,ObjectY - OreSize,ObjectZ,false)
		PlaceStone(ObjectX - OreSize,ObjectY - OreSize,ObjectZ,false)
		PlaceStone(ObjectX,ObjectY,ObjectZ + OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY,ObjectZ + OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY,ObjectZ + OreSize,false)
		PlaceStone(ObjectX,ObjectY + OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY + OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY + OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX,ObjectY - OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY - OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY - OreSize,ObjectZ + OreSize,false)
		PlaceStone(ObjectX,ObjectY,ObjectZ - OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY,ObjectZ - OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY,ObjectZ - OreSize,false)
		PlaceStone(ObjectX,ObjectY + OreSize,ObjectZ - OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY + OreSize,ObjectZ - OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY + OreSize,ObjectZ - OreSize,false)
		PlaceStone(ObjectX,ObjectY - OreSize,ObjectZ - OreSize,false)
		PlaceStone(ObjectX + OreSize,ObjectY - OreSize,ObjectZ - OreSize,false)
		PlaceStone(ObjectX - OreSize,ObjectY - OreSize,ObjectZ - OreSize,false)
	end
end



function PlayerJoined(Player)
	local PlayerFolder = script.PlayerFolder:Clone()
	PlayerFolder.Name = Player.UserId
	PlayerFolder.Parent = ServerStorage.PlayerFolders
	local Char = workspace:WaitForChild(Player.Name,30)
	if Char then
	end
end



Players.PlayerAdded:Connect(PlayerJoined)
MineRemote.OnServerEvent:Connect(MiningStatusChange)
MiningDoneRemote.OnServerEvent:Connect(MineRequest)
CreateNewMine()
