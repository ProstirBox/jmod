﻿-- Jackarunda 2021 - AdventureBoots 2023
AddCSLuaFile()
SWEP.Base = "wep_jack_gmod_ezmeleebase"
SWEP.PrintName = "EZ Pickaxe"
SWEP.Author = "Jackarunda, AdventureBoots"
SWEP.Purpose = ""
JMod.SetWepSelectIcon(SWEP, "entities/ent_jack_gmod_ezpickaxe")
SWEP.ViewModel = "models/weapons/HL2meleepack/v_pickaxe.mdl"
SWEP.WorldModel = "models/props_mining/pickaxe01.mdl"
SWEP.BodyHolsterModel = "models/props_mining/pickaxe01.mdl"
SWEP.BodyHolsterSlot = "back"
SWEP.BodyHolsterAng = Angle(-93, 0, 10)
SWEP.BodyHolsterAngL = Angle(-93, 0, 0)
SWEP.BodyHolsterPos = Vector(3, -24, -3)
SWEP.BodyHolsterPosL = Vector(4, -24, 3)
SWEP.BodyHolsterScale = .75
SWEP.ViewModelFOV = 50
SWEP.Slot = 1
SWEP.SlotPos = 7

SWEP.VElements = {
}

SWEP.WElements = {
	["pickaxe"] = {
		type = "Model",
		model = "models/props_mining/pickaxe01.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(3.4, .4, 8),
		angle = Angle(180, -10, 6),
		size = Vector(0.75, 0.75, 0.75),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}
--
SWEP.DropEnt = "ent_jack_gmod_ezpickaxe"
--
SWEP.HitDistance		= 50
SWEP.HitInclination		= 5
SWEP.HitPushback		= 1000
SWEP.MaxSwingAngle		= 120
SWEP.SwingSpeed 		= 1.3
SWEP.SwingPullback 		= 150
SWEP.PrimaryAttackSpeed = 1.2
SWEP.SecondaryAttackSpeed 	= 1
SWEP.DoorBreachPower 	= 0.5
--
SWEP.SprintCancel 	= true
SWEP.StrongSwing 	= false
--
SWEP.SwingSound 	= Sound( "Weapon_Crowbar.Single" )
SWEP.HitSoundWorld 	= Sound( "Canister.ImpactHard" )
SWEP.HitSoundBody 	= Sound( "Flesh.ImpactHard" )
SWEP.PushSoundBody 	= Sound( "Flesh.ImpactSoft" )
--
SWEP.IdleHoldType 	= "melee2"
SWEP.SprintHoldType = "melee2"
--
SWEP.BlacklistedResources = {JMod.EZ_RESOURCE_TYPES.WATER, JMod.EZ_RESOURCE_TYPES.OIL, JMod.EZ_RESOURCE_TYPES.SAND, "geothermal"}

function SWEP:CustomSetupDataTables()
	self:NetworkVar("Float", 1, "TaskProgress")
	self:NetworkVar("String", 0, "ResourceType")
end

function SWEP:CustomInit()
	self:SetHoldType("melee2")
	self:SetTaskProgress(0)
	self:SetResourceType("")
	self.NextTaskTime = 0
end

function SWEP:CustomThink()
	local Time = CurTime()

	if self.NextTaskTime < Time then
		self:SetTaskProgress(0)
		self.NextTaskTime = Time + 3
	end

	if CLIENT then
		if self.ScanResults then
			self.LastScanTime = self.LastScanTime or Time
			if self.LastScanTime < (Time - 30) then
				self.ScanResults = nil
				self.LastScanTime = nil
			end
		end
	end
end

function SWEP:OnHit(swingProgress, tr)
	local Owner = self:GetOwner()
	--local SwingCos = math.cos(math.rad(swingProgress))
	--local SwingSin = math.sin(math.rad(swingProgress))
	local SwingAng = Owner:EyeAngles()
	local SwingPos = Owner:GetShootPos()
	local StrikeVector = tr.HitNormal
	local StrikePos = (SwingPos - (SwingAng:Up() * 15))

	if IsValid(tr.Entity) then
		local PickDam = DamageInfo()
		PickDam:SetAttacker(self.Owner)
		PickDam:SetInflictor(self)
		PickDam:SetDamagePosition(StrikePos)
		PickDam:SetDamageType(DMG_SLASH)
		PickDam:SetDamage(math.random(30, 50))
		PickDam:SetDamageForce(StrikeVector:GetNormalized() * 300)
		tr.Entity:TakeDamageInfo(PickDam)

	elseif tr.Entity:IsWorld() then
		local Message = JMod.EZprogressTask(self, tr.HitPos, self.Owner, "mining", JMod.GetPlayerStrength(self.Owner) ^ .25)

		if Message then
			self:Msg(Message)
			self:SetTaskProgress(0)
			self:SetResourceType("")
		else
			sound.Play("snds_jack_gmod/ez_tools/hit.wav", tr.HitPos + VectorRand(), 75, math.random(50, 70))
			self:SetTaskProgress(self:GetNW2Float("EZminingProgress", 0))
		end

		if (math.random(1, 1000) == 1) then 
			local Deposit = JMod.GetDepositAtPos(nil, tr.HitPos, 1.5) 
			if ((tr.MatType == MAT_SAND) or (JMod.NaturalResourceTable[Deposit] and JMod.NaturalResourceTable[Deposit].typ == JMod.EZ_RESOURCE_TYPES.SAND)) then
				timer.Simple(math.Rand(1, 2), function() 
					local npc = ents.Create("npc_antlion")
					npc:SetPos(tr.HitPos + Vector(0, 0, 30))
					npc:SetAngles(Angle(0, math.random(0, 360), 0))
					npc:SetKeyValue("startburrowed","1")
					npc:Spawn()
					npc:Activate()
					npc:Fire("unburrow", "", 0)
				end)
			end
		end
	else
		sound.Play("Canister.ImpactHard", tr.HitPos, 10, math.random(75, 100), 1)
		JMod.Hint(self.Owner, "prospecting")
	end
end

function SWEP:FinishSwing(swingProgress)
	if swingProgress >= self.MaxSwingAngle then
		self:SetTaskProgress(0)
	else
		self.NextTaskTime = CurTime() + 3
	end
end

--[[local Anims = {"misscenter1", "hitcenter1"}

function SWEP:Pawnch(hit)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	local vm = self.Owner:GetViewModel()
	if hit then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("hitcenter1"))
	else
		vm:SendViewModelMatchingSequence(vm:LookupSequence("misscenter1"))
	end
	self:UpdateNextIdle()
end--]]


if CLIENT then
	local LastProg = 0

	function SWEP:DrawHUD()
		if GetConVar("cl_drawhud"):GetBool() == false then return end
		local Ply = self.Owner
		if Ply:ShouldDrawLocalPlayer() then return end
		local W, H = ScrW(), ScrH()

		if self.GetTaskProgress == nil then return end
		local Prog = self:GetTaskProgress()

		if Prog > 0 then
			draw.SimpleTextOutlined("Mining... "..self:GetResourceType(), "Trebuchet24", W * .5, H * .45, Color(255, 255, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, 50))
			draw.RoundedBox(10, W * .3, H * .5, W * .4, H * .05, Color(0, 0, 0, 100))
			draw.RoundedBox(10, W * .3 + 5, H * .5 + 5, W * .4 * LastProg / 100 - 10, H * .05 - 10, Color(255, 255, 255, 100))
		end

		LastProg = Lerp(FrameTime() * 5, LastProg, Prog)
	end
end