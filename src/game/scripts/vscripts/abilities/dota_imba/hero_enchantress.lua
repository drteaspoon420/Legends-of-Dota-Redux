-- Copyright (C) 2019  The Dota IMBA Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- Creator:
--	   AltiV, January 17th, 2019
--  Editor:
--     Elfansoer, 16.07.2019


if IsClient() then
    require('lib/util_imba_client')
end

CreateEmptyTalents("enchantress")
-----------------
-- Untouchable --
-----------------

LinkLuaModifier("modifier_imba_enchantress_untouchable", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_untouchable_slow", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_untouchable_peace_on_earth", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)

imba_enchantress_untouchable				= class({})

function imba_enchantress_untouchable:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

function imba_enchantress_untouchable:GetIntrinsicModifierName() 
	return "modifier_imba_enchantress_untouchable"
end

function imba_enchantress_untouchable:OnSpellStart()
	local caster					= self:GetCaster()
	local peace_on_earth_duration 	= self:GetSpecialValueFor("peace_on_earth_duration")
	local responses					= {"enchantress_ench_cast_02", "enchantress_ench_move_18", "enchantress_ench_move_19", "enchantress_ench_move_20", "enchantress_ench_laugh_06", "enchantress_ench_rare_01"}
	
	local enemies
	
	if caster:HasScepter() then
		enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	else
		enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	end
	
	for _, enemy in pairs(enemies) do
		if not enemy:IsCourier() then
			if not (enemy:GetCurrentActiveAbility() and (enemy:GetCurrentActiveAbility():GetName() == "item_tpscroll" or string.find(enemy:GetCurrentActiveAbility():GetName(), "item_travel_boots"))) then
				enemy:Stop()
			end
			
			enemy:AddNewModifier(caster, self, "modifier_imba_enchantress_untouchable_peace_on_earth", {duration = peace_on_earth_duration})
		end
	end
	
	caster:AddNewModifier(caster, self, "modifier_imba_enchantress_untouchable_peace_on_earth", {duration = peace_on_earth_duration})
	
	-- TODO: Add a good global / client sound effect for this
	EmitGlobalSound(responses[RandomInt(1, #responses)])
	EmitGlobalSound("DOTA_Item.HeavensHalberd.Activate")
end

--------------------------
-- UNTOUCHABLE MODIFIER --
--------------------------

modifier_imba_enchantress_untouchable		= class({})

function modifier_imba_enchantress_untouchable:IsHidden()		return true end
function modifier_imba_enchantress_untouchable:IsPurgable()		return false end
function modifier_imba_enchantress_untouchable:RemoveOnDeath()	return false end

function modifier_imba_enchantress_untouchable:OnCreated()
	-- elfansoer: fix generic intrinsic problem
	if IsServer() then
		if self:GetAbility():GetLevel()<1 then
			self:Destroy()
			return
		end
	end

	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()
	
	self.regret_stacks	= self.ability:GetSpecialValueFor("regret_stacks")
end

function modifier_imba_enchantress_untouchable:OnRefresh()
	self.regret_stacks	= self.ability:GetSpecialValueFor("regret_stacks")
end

function modifier_imba_enchantress_untouchable:DeclareFunctions()
    local decFuncs = {
        MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_HERO_KILLED -- IMBAfication: Regret
    }

    return decFuncs
end

function modifier_imba_enchantress_untouchable:OnAttackStart(keys)
	if not IsServer() then return end
	
    if self.caster == keys.target and not self.caster:PassivesDisabled() and not keys.attacker:IsMagicImmune() and not keys.attacker:IsBuilding() then
		keys.attacker:AddNewModifier(self.caster, self.ability, "modifier_imba_enchantress_untouchable_slow", {})
    end
end

function modifier_imba_enchantress_untouchable:OnHeroKilled(keys)
	if not IsServer() then return end

    if self.caster == keys.target and not self.caster:PassivesDisabled() and not self.caster:IsIllusion() and self.caster ~= keys.attacker and not keys.attacker:IsMagicImmune() and not keys.attacker:IsBuilding() then
		keys.attacker:AddNewModifier(self.caster, self.ability, "modifier_imba_enchantress_untouchable_slow", {}):SetStackCount(self.regret_stacks)
    end
end

-------------------------------
-- UNTOUCHABLE MODIFIER SLOW --
-------------------------------

modifier_imba_enchantress_untouchable_slow	= class({})

function modifier_imba_enchantress_untouchable_slow:OnCreated()
	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()
	
	-- AbilitySpecials
	self.slow_attack_speed 			= self.ability:GetSpecialValueFor("slow_attack_speed") + self.caster:FindTalentValue("special_bonus_imba_enchantress_5")
	--self.slow_duration 			= self.ability:GetSpecialValueFor("slow_duration")
	self.stopgap_bat_increase 		= self.ability:GetSpecialValueFor("stopgap_bat_increase")
end

function modifier_imba_enchantress_untouchable_slow:GetEffectName()
	return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_imba_enchantress_untouchable_slow:GetStatusEffectName()
	return "particles/status_fx/status_effect_enchantress_untouchable.vpcf"
end

function modifier_imba_enchantress_untouchable_slow:DeclareFunctions()
    local decFuncs = {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, -- IMBAfication: Stopgap
		MODIFIER_EVENT_ON_ATTACK
    }

    return decFuncs
end

-- elfansoer: fix untouchable still slowing even though attack was cancelled
function modifier_imba_enchantress_untouchable_slow:OnAttackStart( keys )
	if self:GetStackCount()<1 then
		if self.parent==keys.attacker and keys.target~=self:GetCaster() then
			self:Destroy()
		end
	end
end

function modifier_imba_enchantress_untouchable_slow:GetModifierAttackSpeedBonus_Constant()
	return self.slow_attack_speed
end

function modifier_imba_enchantress_untouchable_slow:GetModifierBaseAttackTimeConstant()
	return self.stopgap_bat_increase
end

-- After the attack is complete, remove the slow after a short delay
function modifier_imba_enchantress_untouchable_slow:OnAttack(keys)
	if self.parent == keys.attacker then
		-- Wait frame time to check if the target is not Enchantress or if she was not killed to properly apply Regret stacks
		Timers:CreateTimer(FrameTime(), function()
			if keys.target ~= self.caster or self.caster:IsAlive() then
				if self:GetStackCount() > 1 then
					self:DecrementStackCount()
				else 
					self:SetDuration(keys.attacker:GetAttackAnimationPoint(), false) -- Probably not the right function to call but w/e
				end
			end
		end)
	end
end

-----------------------------------------
-- UNTOUCHABLE PEACE ON EARTH MODIFIER --
-----------------------------------------

modifier_imba_enchantress_untouchable_peace_on_earth	= class({})

function modifier_imba_enchantress_untouchable_peace_on_earth:IsDebuff()		return true end
function modifier_imba_enchantress_untouchable_peace_on_earth:IgnoreTenacity()	return self:GetCaster():HasTalent("special_bonus_imba_enchantress_5") end

function modifier_imba_enchantress_untouchable_peace_on_earth:OnCreated()
	self.parent	= self:GetParent()

	if not IsServer() then return end

	-- elfansoer: fix untouchable crash (caused by missing particles)
	-- self.particle = ParticleManager:CreateParticle("particles/item/angelic_alliance/angelic_alliance_disarm.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
	-- ParticleManager:SetParticleControl(self.particle, 0, self.parent:GetAbsOrigin())
	-- self:AddParticle(self.particle, false, false, -1, false, false)
	
	self.particle2 = ParticleManager:CreateParticle("particles/units/unit_greevil/loot_greevil_tgt_end_sparks.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particle2, 3, self.parent:GetAbsOrigin())
	self:AddParticle(self.particle2, false, false, -1, false, false)
	
	self.particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_enchantress/enchantress_natures_attendants_test.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	for wisp = 1, 4 do
		ParticleManager:SetParticleControlEnt(self.particle3, wisp, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	end
	self:AddParticle(self.particle3, false, false, -1, false, false)
end

function modifier_imba_enchantress_untouchable_peace_on_earth:OnRefresh()
	self:OnCreated()
end

function modifier_imba_enchantress_untouchable_peace_on_earth:CheckState(keys)
	local state = {
	[MODIFIER_STATE_DISARMED] = true
	}

	return state
end

-------------
-- Enchant --
-------------

-- LinkLuaModifier("modifier_imba_enchantress_enchant", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_enchant_controlled", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_enchant_slow", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)

imba_enchantress_enchant						= class({})

function imba_enchantress_enchant:GetAbilityTargetTeam() 
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function imba_enchantress_enchant:CastFilterResultTarget(target)
	if not IsServer() then return end
	
	local caster = self:GetCaster()

	if target:IsAncient() and caster:GetLevel() < 20 then
		return UF_FAIL_CUSTOM
	end
	
	if target:GetTeam() == caster:GetTeam() and not target:HasModifier("modifier_imba_enchantress_enchant_controlled") then
		return UF_FAIL_FRIENDLY
	end

	local nResult = UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), self:GetCaster():GetTeamNumber() )
	return nResult
end

function imba_enchantress_enchant:GetCustomCastErrorTarget(target)
	return "Ability Can't Target Ancients Until Level 20"
end

function imba_enchantress_enchant:OnSpellStart()
	self.caster	= self:GetCaster()
	self.target	= self:GetCursorTarget()
	
	-- AbilitySpecials
	self.dominate_duration		= self:GetSpecialValueFor("dominate_duration")
	self.slow_movement_speed	= self:GetSpecialValueFor("slow_movement_speed")
	self.tooltip_duration 		= self:GetSpecialValueFor("tooltip_duration") + self.caster:FindTalentValue("special_bonus_imba_enchantress_6")
	
	if self.caster:HasTalent("special_bonus_imba_enchantress_6") then
		self.dominate_duration	= self.dominate_duration * self.caster:FindTalentValue("special_bonus_imba_enchantress_6")
	end
	
	-- Blocked by Linkens
	if self.target:TriggerSpellAbsorb(self) then
		return nil
	end
	
	self.caster:EmitSound("Hero_Enchantress.EnchantCast")
	
	-- Elfansoer: Fix missing IsRoshan function
	print("unit is creep",(not self.target:IsConsideredHero() or self.target:IsIllusion()), self.target:GetUnitName(), self.target:GetUnitName()~="npc_dota_roshan" )

	if (not self.target:IsConsideredHero() or self.target:IsIllusion()) and self.target:GetUnitName()~="npc_dota_roshan" then
		-- Basic dispel (buffs and debuffs)
		self.target:Purge(true, true, false, false, false)
		
		-- SUPER JANK LANE CREEP SWITCHAROO TO BYPASS LANE AI
		if string.find(self.target:GetUnitName(), "guys_") then
			local lane_creep_name = self.target:GetUnitName()
			
			local new_lane_creep = CreateUnitByName(self.target:GetUnitName(), self.target:GetAbsOrigin(), false, self.caster, self.caster, self.caster:GetTeamNumber())
			-- Copy the relevant stats over to the creep
			new_lane_creep:SetBaseMaxHealth(self.target:GetMaxHealth())
			new_lane_creep:SetHealth(self.target:GetHealth())
			new_lane_creep:SetBaseDamageMin(self.target:GetBaseDamageMin())
			new_lane_creep:SetBaseDamageMax(self.target:GetBaseDamageMax())
			new_lane_creep:SetMinimumGoldBounty(self.target:GetGoldBounty())
			new_lane_creep:SetMaximumGoldBounty(self.target:GetGoldBounty())
			UTIL_Remove(self.target)
			self.target = new_lane_creep
		end

		self.target:SetOwner(self.caster)
		self.target:SetTeam(self.caster:GetTeam())
		self.target:SetControllableByPlayer(self.caster:GetPlayerID(), false)
		self.target:AddNewModifier(self.caster, self, "modifier_imba_enchantress_enchant_controlled", {duration = self.dominate_duration})
		--self.target:AddNewModifier(self.caster, self, "modifier_dominated", {duration = self.dominate_duration}) -- This didn't work for me
		self.target:AddNewModifier(self.caster, self, "modifier_kill", {duration = self.dominate_duration})

		if self.caster:GetName() == "npc_dota_hero_enchantress" then
			self.caster:EmitSound("enchantress_ench_ability_enchant_0"..math.random(1,3))
		end
	else
		-- Basic dispel (just buffs)
		self.target:Purge(true, false, false, false, false)
		
		self.target:AddNewModifier(self.caster, self, "modifier_imba_enchantress_enchant_slow", {duration = self.tooltip_duration})
	
		if self.caster:GetName() == "npc_dota_hero_enchantress" then
			self.caster:EmitSound("enchantress_ench_ability_enchant_0"..math.random(4,6))
		end
	end
end

----------------------
-- ENCHANT MODIFIER --
----------------------

-- modifier_imba_enchantress_enchant				= class({})

---------------------------------
-- ENCHANT CONTROLLED MODIFIER --
---------------------------------

modifier_imba_enchantress_enchant_controlled	= class({})

function modifier_imba_enchantress_enchant_controlled:IsHidden() 	return true end
function modifier_imba_enchantress_enchant_controlled:IsPurgable() 	return false end

function modifier_imba_enchantress_enchant_controlled:OnCreated()
	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()
	
	if not IsServer() then return end
	
	self.remaining_hp	= 	self.parent:GetHealth()
	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_enchantress/enchantress_enchant.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particle, 0, self.parent:GetAbsOrigin())
	self:AddParticle(self.particle, false, false, -1, false, false)
	
	-- Don't need to destroy this at end because sound byte is short and modifier outlasts it by magnitudes (also it errors if I try to anyways)
	self.parent:EmitSound("Hero_Enchantress.EnchantCreep")
end

function modifier_imba_enchantress_enchant_controlled:CheckState()
	local state = {
	[MODIFIER_STATE_DOMINATED] = true
	}

	return state
end

function modifier_imba_enchantress_enchant_controlled:DeclareFunctions()
    local decFuncs = {
		MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE, -- Talent 4
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return decFuncs
end

function modifier_imba_enchantress_enchant_controlled:GetBonusVisionPercentage(keys)
	return self:GetCaster():FindTalentValue("special_bonus_imba_enchantress_4")
end

-- IMBAfication: Instant Karma
function modifier_imba_enchantress_enchant_controlled:OnTakeDamage(keys)
	if not IsServer() then return end

    if keys.unit == self:GetParent() then
		if keys.unit:IsAlive() then
			self.remaining_hp = keys.unit:GetHealth()
		else
			-- Set overkill damage as the amount of damage attacker did over the victim's remaining health within one attack
			local overkill_damage = keys.damage - self.remaining_hp
			
			-- Don't trigger Instant Karma on buildings...
			if keys.attacker:IsBuilding() then return end
			
			local damageTable = {
				victim 			= keys.attacker,
				damage 			= overkill_damage,
				damage_type		= DAMAGE_TYPE_PURE,
				damage_flags 	= DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
				attacker 		= self.caster,
				ability 		= self.ability
			}
								
			ApplyDamage(damageTable)
			
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, keys.attacker, overkill_damage, nil)
		end
	end
end

---------------------------
-- ENCHANT SLOW MODIFIER --
---------------------------

modifier_imba_enchantress_enchant_slow			= class({})

function modifier_imba_enchantress_enchant_slow:GetStatusEffectName()
	return "particles/status_fx/status_effect_enchantress_enchant_slow.vpcf"
end

function modifier_imba_enchantress_enchant_slow:OnCreated()
	self.ability	= self:GetAbility()
	self.parent		= self:GetParent()
	
	self.slow_movement_speed	= self.ability:GetSpecialValueFor("slow_movement_speed")
	
	if not IsServer() then return end
	
	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_enchantress/enchantress_enchant_slow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particle, 0, self.parent:GetAbsOrigin())
	self:AddParticle(self.particle, false, false, -1, false, false)
	
	self.parent:EmitSound("Hero_Enchantress.EnchantHero")
end

function modifier_imba_enchantress_enchant_slow:OnDestroy()
	if not IsServer() then return end

	self.parent:StopSound("Hero_Enchantress.EnchantHero")
end

function modifier_imba_enchantress_enchant_slow:DeclareFunctions()
    local decFuncs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION -- IMBAfication: Enchant provides vision of affected enemies
    }

    return decFuncs
end

function modifier_imba_enchantress_enchant_slow:GetModifierMoveSpeedBonus_Percentage()
    return self.slow_movement_speed
end

function modifier_imba_enchantress_enchant_slow:GetModifierProvidesFOWVision()
    return 1
end

-------------------------
-- Nature's Attendants --
-------------------------

LinkLuaModifier("modifier_imba_enchantress_natures_attendants", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_natures_attendants_mini", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)

imba_enchantress_natures_attendants				= class({})

function imba_enchantress_natures_attendants:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

function imba_enchantress_natures_attendants:OnSpellStart()
	self.caster		= self:GetCaster()
	self.duration	= self:GetDuration()

	self.caster:AddNewModifier(self.caster, self, "modifier_imba_enchantress_natures_attendants", {duration = self.duration})

	if self.caster:GetName() == "npc_dota_hero_enchantress" then
		self.caster:EmitSound("enchantress_ench_ability_nature_0"..math.random(1,6))
	end
end

----------------------------------
-- NATURE'S ATTENDANTS MODIFIER --
----------------------------------

modifier_imba_enchantress_natures_attendants	= class({})

function modifier_imba_enchantress_natures_attendants:IsPurgable()		return false end
function modifier_imba_enchantress_natures_attendants:RemoveOnDeath()	return false end

function modifier_imba_enchantress_natures_attendants:OnCreated()
	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()

	-- AbilitySpecials
	self.heal_interval 	= self.ability:GetSpecialValueFor("heal_interval")
	self.heal 			= self.ability:GetSpecialValueFor("heal")
	self.radius 		= self.ability:GetSpecialValueFor("radius")
	self.wisp_count 	= self.ability:GetSpecialValueFor("wisp_count")

	self.critical_health_pct		= self.ability:GetSpecialValueFor("critical_health_pct")
	self.base_damage_reduction_pct	= self.ability:GetSpecialValueFor("base_damage_reduction_pct")
	self.cyan_mana_restore			= self.ability:GetSpecialValueFor("cyan_mana_restore")
	self.green_heal_amp				= self.ability:GetSpecialValueFor("green_heal_amp")
	self.orange_day_vision			= self.ability:GetSpecialValueFor("orange_day_vision")
	self.orange_night_vision		= self.ability:GetSpecialValueFor("orange_night_vision")
	self.pink_movespeed_pct			= self.ability:GetSpecialValueFor("pink_movespeed_pct")

	-- Sprites' Attraction Talent (multiply a bunch of values..)
	if self.caster:HasTalent("special_bonus_imba_enchantress_8") then
		self.multiplier		= self.caster:FindTalentValue("special_bonus_imba_enchantress_8")
	
		self.heal 						= self.heal 						* self.multiplier
		self.wisp_count 				= self.wisp_count 					* self.multiplier
		self.critical_health_pct		= self.critical_health_pct 			* self.multiplier
		self.base_damage_reduction_pct	= self.base_damage_reduction_pct 	* self.multiplier
		self.cyan_mana_restore			= self.cyan_mana_restore 			* self.multiplier
		self.green_heal_amp				= self.green_heal_amp 				* self.multiplier
		self.orange_day_vision			= self.orange_day_vision 			* self.multiplier
		self.orange_night_vision		= self.orange_night_vision 			* self.multiplier
		self.pink_movespeed_pct			= self.pink_movespeed_pct 			* self.multiplier
	end

	self.level			= self.ability:GetLevel()
	
	if not IsServer() then return end
	
	-- IMBAfication: Fundamental's Essence
	-- 1 Base: Reduces all incoming damage by 10%
    -- 2 Cyan: Every wisp heal also grants X mana
	-- 3 Green: Amplifies all sources of healing by 20%
	-- 4 Orange: Increase day/night vision by 250/750 respectively 
	-- 5 Pink: Increases move speed by 5% and grants flying movement
	self:SetStackCount(RandomInt(1, 5))
	
	-- PARTICLESSSS
	-- 3/5/7/9 wisps based on level
	-- 3-5/7/9/11 for the wisp control points
	-- CP60 for colour, CP61 Vector(1, 0, 0) to activate it
	self.particle_name = "particles/units/heroes/hero_enchantress/enchantress_natures_attendants_lvl"..self.level..".vpcf"
	
	self.particle = ParticleManager:CreateParticle(self.particle_name, PATTACH_ABSORIGIN_FOLLOW, self.parent)
	
	for wisp = 3, 3 + (self.level * 2) do
		ParticleManager:SetParticleControlEnt(self.particle, wisp, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	end
	
	if self:GetStackCount() == 1 then
		
	else
		ParticleManager:SetParticleControl(self.particle, 61, Vector(1, 0, 0))
			
		if self:GetStackCount() == 2 then
			ParticleManager:SetParticleControl(self.particle, 60, Vector(0, 255, 255))
		elseif self:GetStackCount() == 3 then
			ParticleManager:SetParticleControl(self.particle, 60, Vector(50, 255, 50))
		elseif self:GetStackCount() == 4 then
			ParticleManager:SetParticleControl(self.particle, 60, Vector(255, 140, 0))
		elseif self:GetStackCount() == 5 then
			ParticleManager:SetParticleControl(self.particle, 60, Vector(255, 105, 180))
		end
	end
	
	self:AddParticle(self.particle, false, false, -1, false, false)
	
	self.caster:EmitSound("Hero_Enchantress.NaturesAttendantsCast")
	
	self:StartIntervalThink(self.heal_interval)
end

function modifier_imba_enchantress_natures_attendants:OnIntervalThink()
	if not IsServer() then return end
	
	-- This is probably pretty inefficient...
	
	-- Establish empty table of allies that will need healing
	local hurt_allies = {}
	
	-- Find all allies in radius
	local allies = FindUnitsInRadius(self.caster:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS,
		FIND_ANY_ORDER,
		false)
	
	-- Populate hurt allies array with those that do not have full health
	for _, ally in pairs(allies) do
		-- Deal damage to each
		if ally:GetHealthPercent() < 100 then
			table.insert(hurt_allies, ally)
		end
	end
	
	if #hurt_allies == 0 then
		-- If everyone's full health, bring all the wisps back to Enchantress
		for wisp = 3, 3 + (self.level * 2) do
			ParticleManager:SetParticleControlEnt(self.particle, wisp, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
		end
	else
		-- Each wisp picks a random valid target to attach to and heal
		for wisp = 1, self.wisp_count do
			local selected_unit = RandomInt(1, #hurt_allies)
			
			-- Reminder that particle only has 3/5/7/9 wisps and 3 to 5/7/9/11 for CP so if you want to add more wisps either edit the particle or accept it'll look weird
			ParticleManager:SetParticleControlEnt(self.particle, math.min(wisp + 2, 3 + (self.level * 2)), hurt_allies[selected_unit], PATTACH_POINT_FOLLOW, "attach_hitloc", hurt_allies[selected_unit]:GetAbsOrigin(), true)
			
			-- Each wisp heals for a separate instance
			hurt_allies[selected_unit]:Heal(self.heal, self.caster)
			
			-- Cyan: Every wisp heal also grants 5/6/7/8 mana
			if self:GetStackCount() == 2 then
				hurt_allies[selected_unit]:GiveMana(self.cyan_mana_restore)			
			end
			
			-- TODO: Rest for the Weary
			if hurt_allies[selected_unit]:GetHealthPercent() < self.critical_health_pct and not hurt_allies[selected_unit]:HasModifier("modifier_imba_enchantress_natures_attendants_mini") then
				hurt_allies[selected_unit]:AddNewModifier(self.caster, self.ability, "modifier_imba_enchantress_natures_attendants_mini", {duration = self.ability.duration})
			end
		end
	end
end

function modifier_imba_enchantress_natures_attendants:OnDestroy()
	if not IsServer() then return end
	
	self.caster:StopSound("Hero_Enchantress.NaturesAttendantsCast")
end

function modifier_imba_enchantress_natures_attendants:CheckState()
	if self:GetStackCount() == 5 then
		return {[MODIFIER_STATE_FLYING] = true} -- * Pink: Increases move speed by 5% and grants flying movement
	end
end

function modifier_imba_enchantress_natures_attendants:DeclareFunctions()
    local decFuncs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, 	-- * Base: Reduces all incoming damage by 10%
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,	-- * Green: Amplifies all sources of healing by 20%
		MODIFIER_PROPERTY_BONUS_DAY_VISION,				-- * Orange: Increase day/night vision by 250/750 respectively 
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,			-- * Orange: Increase day/night vision by 250/750 respectively 
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	-- * Pink: Increases move speed by 5% and grants flying movement
    }
	
	return decFuncs
end

function modifier_imba_enchantress_natures_attendants:GetModifierIncomingDamage_Percentage()
	if self:GetStackCount() == 1 then
		return self.base_damage_reduction_pct
	else
		return 0
	end
end

function modifier_imba_enchantress_natures_attendants:GetModifierHPRegenAmplify_Percentage()
	if self:GetStackCount() == 3 then
		return self.green_heal_amp
	else
		return 0
	end
end

function modifier_imba_enchantress_natures_attendants:GetBonusDayVision()
	if self:GetStackCount() == 4 then
		return self.orange_day_vision
	else
		return 0
	end
end

function modifier_imba_enchantress_natures_attendants:GetBonusNightVision()
	if self:GetStackCount() == 4 then
		return self.orange_night_vision
	else
		return 0
	end
end

function modifier_imba_enchantress_natures_attendants:GetModifierMoveSpeedBonus_Percentage()
	if self:GetStackCount() == 5 then
		return self.pink_movespeed_pct
	else
		return 0
	end
end

---------------------------------------
-- NATURE'S ATTENDANTS MINI MODIFIER --
---------------------------------------

modifier_imba_enchantress_natures_attendants_mini	= class({})

function modifier_imba_enchantress_natures_attendants_mini:OnCreated()
	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()

	-- AbilitySpecials
	self.heal_interval 		= self.ability:GetSpecialValueFor("heal_interval")
	self.heal 				= self.ability:GetSpecialValueFor("heal")
	self.wisp_count_mini	= self.ability:GetSpecialValueFor("wisp_count_mini")
	
	if not IsServer() then return end
	
	self.particle_name 	= "particles/units/heroes/hero_enchantress/enchantress_natures_attendants_lvl1.vpcf"
	self.particle 		= ParticleManager:CreateParticle(self.particle_name, PATTACH_ABSORIGIN_FOLLOW, self.parent)
	
	for wisp = 3, 5 do
		ParticleManager:SetParticleControlEnt(self.particle, wisp, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	end
	
	self:AddParticle(self.particle, false, false, -1, false, false)
	
	self.parent:EmitSound("Hero_Enchantress.NaturesAttendantsCast")
	
	self:StartIntervalThink(self.heal_interval)
end

function modifier_imba_enchantress_natures_attendants_mini:OnIntervalThink()
	if not IsServer() then return end
	
	for wisp = 1, self.wisp_count_mini do
		-- Each wisp heals for a separate instance
		self.parent:Heal(self.heal, self.caster)
	end
end

function modifier_imba_enchantress_natures_attendants_mini:OnDestroy()
	if not IsServer() then return end
	
	self.parent:StopSound("Hero_Enchantress.NaturesAttendantsCast")
end

------------------
-- Natura Shift --
------------------
LinkLuaModifier("modifier_imba_enchantress_natura_shift", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)

imba_enchantress_natura_shift					= class({})

-- Elfansoer: Set Natura Shift to be instantly leveled
function imba_enchantress_natura_shift:OnHeroCalculateStatBonus()
	if self.once then return end
	self.once = true

	self:SetLevel( 1 )
end

function imba_enchantress_natura_shift:IsInnateAbility()	return true end
function imba_enchantress_natura_shift:IsStealable()		return false end

function imba_enchantress_natura_shift:GetIntrinsicModifierName() 
	return "modifier_imba_enchantress_natura_shift"
end

function imba_enchantress_natura_shift:OnSpellStart()
	self.modifier	=	self:GetCaster():FindModifierByName("modifier_imba_enchantress_natura_shift")

	if not self.modifier or self.modifier:GetStackCount() == 1 then
		self.modifier:SetStackCount(2)
	elseif self.modifier:GetStackCount() == 2 then
		self.modifier:SetStackCount(3)
	elseif self.modifier:GetStackCount() == 3 then
		self.modifier:SetStackCount(1)
	end
end

function imba_enchantress_natura_shift:GetAbilityTextureName()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_imba_enchantress_natura_shift") then
		local state = caster:GetModifierStackCount("modifier_imba_enchantress_natura_shift", caster)
		
		if state == 1 then
			return "custom/natura_shift_inactive"
		elseif state == 2 then
			return "custom/natura_shift_fast"
		elseif state == 3 then
			return "custom/natura_shift_slow"
		else
			return "custom/natura_shift_inactive"
		end
	end
end

modifier_imba_enchantress_natura_shift			= class({})

function modifier_imba_enchantress_natura_shift:IsHidden()	return true end

function modifier_imba_enchantress_natura_shift:OnCreated()
	-- elfansoer: fix generic intrinsic problem
	if IsServer() then
		if self:GetAbility():GetLevel()<1 then
			self:Destroy()
			return
		end
	end

	self:SetStackCount(1)
end

function modifier_imba_enchantress_natura_shift:DeclareFunctions()
    local decFuncs = {
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS
    }

    return decFuncs
end

function modifier_imba_enchantress_natura_shift:GetModifierProjectileSpeedBonus()
    self.ability	= self:GetAbility()
	
	self.speed_fast		= self.ability:GetSpecialValueFor("speed_fast")
	self.speed_slow		= self.ability:GetSpecialValueFor("speed_slow")
	
	if self:GetStackCount() == 1 then
		return 0
	elseif self:GetStackCount() == 2 then
		return self.speed_fast
	elseif self:GetStackCount() == 3 then
		return self.speed_slow
	else
		return 0
	end
end

-------------
-- Impetus --
-------------

LinkLuaModifier("modifier_imba_enchantress_impetus", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_enchantress_impetus_huntmastery_timer", "abilities/dota_imba/hero_enchantress.lua", LUA_MODIFIER_MOTION_NONE)

imba_enchantress_impetus						= class({})

function imba_enchantress_impetus:IsStealable()	return false end

function imba_enchantress_impetus:GetIntrinsicModifierName() 
	return "modifier_imba_enchantress_impetus"
end

----------------------
-- IMPETUS MODIFIER --
----------------------

modifier_imba_enchantress_impetus				= class({})

function modifier_imba_enchantress_impetus:OnCreated()
	-- elfansoer: fix generic intrinsic problem
	if IsServer() then
		if self:GetAbility():GetLevel()<1 then
			self:Destroy()
			return
		end
	end


	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
	self.parent		= self:GetParent()
	
	-- Use this boolean to track if Impetus is manually cast
	self.impetus_orb	= false

	-- elfansoer: fix overriding base attack projectile
	-- self.base_attack	= "particles/units/heroes/hero_enchantress/enchantress_base_attack.vpcf"
	self.base_attack	= self.parent:GetRangedProjectileName() or ""

	--self.impetus_attack	= "particles/econ/items/enchantress/enchantress_virgas/ench_impetus_virgas.vpcf"
	self.impetus_attack	= "particles/units/heroes/hero_enchantress/enchantress_impetus.vpcf"
	self.attack_queue	= {} -- Gonna try my own jank way to deal with impetus attacks at extreme speeds
	--self.impetus_start	= "Hero_Enchantress.Impetus.Immortal"
	self.impetus_start	= "Hero_Enchantress.Impetus"
	--self.impetus_damage	= "Hero_Enchantress.ImpetusDamage.Immortal"
	self.impetus_damage	= "Hero_Enchantress.ImpetusDamage"
	
	-- AbilitySpecials
	self.distance_damage_pct 			= self.ability:GetSpecialValueFor("distance_damage_pct")
	--self.distance_cap 				= self.ability:GetSpecialValueFor("distance_cap")
	self.bonus_attack_range_scepter 	= self.ability:GetSpecialValueFor("bonus_attack_range_scepter")
	self.attack_cast_stack				= self.ability:GetSpecialValueFor("attack_cast_stack")
	self.huntmastery_grace_period		= self.ability:GetSpecialValueFor("huntmastery_grace_period")
end

function modifier_imba_enchantress_impetus:OnRefresh()
	self.distance_damage_pct 			= self.ability:GetSpecialValueFor("distance_damage_pct")
	self.bonus_attack_range_scepter 	= self.ability:GetSpecialValueFor("bonus_attack_range_scepter")
	self.attack_cast_stack				= self.ability:GetSpecialValueFor("attack_cast_stack")
	self.huntmastery_grace_period		= self.ability:GetSpecialValueFor("huntmastery_grace_period")
end

function modifier_imba_enchantress_impetus:DeclareFunctions()
    local decFuncs = {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_ORDER
    }

    return decFuncs
end

function modifier_imba_enchantress_impetus:GetModifierCastRangeBonusStacking()
	local cast_range = self:GetStackCount() * self.attack_cast_stack

	if self.parent:HasScepter() then
		cast_range = cast_range + self.bonus_attack_range_scepter
	end
	
	return cast_range
end

function modifier_imba_enchantress_impetus:GetModifierAttackRangeBonus()
	local attack_range = self:GetStackCount() * self.attack_cast_stack

    if self.parent:HasScepter() then
		attack_range = attack_range + self.bonus_attack_range_scepter
	end
	
	return attack_range
end

function modifier_imba_enchantress_impetus:OnAttackStart( keys )
    if not IsServer() then return end

	if keys.attacker == self.caster and self.ability:IsFullyCastable() and not self.caster:IsSilenced() and not keys.target:IsBuilding() and not keys.target:IsOther() and (self.ability:GetAutoCastState() or self.impetus_orb) then
		self.parent:SetRangedProjectileName(self.impetus_attack)
	else
		self.parent:SetRangedProjectileName(self.base_attack)
	end
end

function modifier_imba_enchantress_impetus:OnAttack( keys )
    if not IsServer() then return end
	
	if keys.attacker == self.caster then
		if not self.caster:IsIllusion() and self.ability:IsFullyCastable() and not self.caster:IsSilenced() and not keys.target:IsBuilding() and not keys.target:IsOther() and (self.ability:GetAutoCastState() or self.impetus_orb) then
			table.insert(self.attack_queue, true)
			self.ability:UseResources(true, false, false)
			self.caster:EmitSound(self.impetus_start)
			self.impetus_orb = false
		else
			table.insert(self.attack_queue, false)
		end
	end
end

function modifier_imba_enchantress_impetus:OnAttackLanded( keys )
    if not IsServer() then return end
	
	if keys.attacker == self.caster and #self.attack_queue > 0 then
		
		-- If the attack is flagged as Impetus, apply the effects
		if self.attack_queue[1] and not keys.target:IsBuilding() and keys.target:IsAlive() then
		
			-- IMBAfication: Huntmastery
			keys.target:AddNewModifier(self.caster, self.ability, "modifier_imba_enchantress_impetus_huntmastery_timer", {duration = self.huntmastery_grace_period})
			
			-- Remove distance cap on damage
			-- Note that CalcDistanceBetweenEntityOBB(self.caster, keys.target) actually gives different / "wrong" results...
			--local distance 			= math.min(CalcDistanceBetweenEntityOBB(self.caster, keys.target), self.distance_cap)
			local distance 			= (self.caster:GetAbsOrigin() - keys.target:GetAbsOrigin()):Length()
			local impetus_damage	= distance * ((self.distance_damage_pct + self.caster:FindTalentValue("special_bonus_imba_enchantress_9")) / 100)
			
			local damageTable = {victim = keys.target,
								damage = impetus_damage,
								damage_type = DAMAGE_TYPE_PURE,
								damage_flags = DOTA_DAMAGE_FLAG_NONE,
								attacker = self.caster,
								ability = self.ability
								}
								
			ApplyDamage(damageTable)
			
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, impetus_damage, nil)
			
			keys.target:EmitSound(self.impetus_damage)
			
			-- Armament Equivalency
			if self.caster:HasTalent("special_bonus_imba_enchantress_7") then
				if not self.armament_spell_amp_pct or not self.armament_attack_dmg_pct then
					self.armament_spell_amp_pct		= self.caster:FindTalentValue("special_bonus_imba_enchantress_7", "spell_amp_pct") / 100
					self.armament_attack_dmg_pct 	= self.caster:FindTalentValue("special_bonus_imba_enchantress_7", "attack_dmg_pct") / 100
				end
			
				local phys_damage	= impetus_damage * keys.target:GetSpellAmplification(false) * self.armament_spell_amp_pct
				local magic_damage	= impetus_damage * (keys.target:GetAverageTrueAttackDamage(self.caster) / 100) * self.armament_attack_dmg_pct

				-- First apply the extra physical damage...
				damageTable.damage 		= phys_damage
				damageTable.damage_type	= DAMAGE_TYPE_PHYSICAL
				
				ApplyDamage(damageTable)
				
				-- Let's stagger the damage numbers a bit so they're easier to see
				Timers:CreateTimer(0.2, function()
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, phys_damage, nil)
				end)
				
				-- ...then apply the extra magical damage
				damageTable.damage 		= magic_damage
				damageTable.damage_type	= DAMAGE_TYPE_MAGICAL
								
				ApplyDamage(damageTable)
				
				Timers:CreateTimer(0.4, function()				
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, magic_damage, nil)
				end)
			end
			
			-- IMBAfication: Huntmastery (deprecated to now allow a small grace period with modifier modifier_imba_enchantress_impetus_huntmastery_timer but leaving this for reference
			-- Gotta wait a bit before potential kills are registered
			-- Timers:CreateTimer(FrameTime(), function()
				-- if not keys.target:IsAlive() and keys.target:IsRealHero() and (keys.target.IsReincarnating and not keys.target:IsReincarnating()) then
					-- self:IncrementStackCount()
					
					-- if self.caster:GetName() == "npc_dota_hero_enchantress" then
						-- self.caster:EmitSound("enchantress_ench_ability_impetus_0"..math.random(1,7))
					-- end
				-- end
			-- end)
		end
		
		table.remove(self.attack_queue, 1)
	end
end

function modifier_imba_enchantress_impetus:OnAttackFail( keys )
    if not IsServer() then return end
	
	if keys.attacker == self.caster and #self.attack_queue > 0 then
		table.remove(self.attack_queue, 1)
	end
end

-- Handle Impetus orb flag by checking if it is manually cast
function modifier_imba_enchantress_impetus:OnOrder(keys)
	if keys.unit == self.caster then
		if keys.order_type == DOTA_UNIT_ORDER_CAST_TARGET and keys.ability:GetName() == self.ability:GetName() then
			self.impetus_orb = true
		else
			self.impetus_orb = false
		end
	end
end

----------------------------------------
-- IMPETUS HUNTMASTERY TIMER MODIFIER --
----------------------------------------

modifier_imba_enchantress_impetus_huntmastery_timer	= class({})

function modifier_imba_enchantress_impetus_huntmastery_timer:IgnoreTenacity()	return true end
function modifier_imba_enchantress_impetus_huntmastery_timer:IsHidden() 		return true end
function modifier_imba_enchantress_impetus_huntmastery_timer:IsPurgable()		return false end
function modifier_imba_enchantress_impetus_huntmastery_timer:RemoveOnDeath()	return false end -- Destroys itself rather promptly

function modifier_imba_enchantress_impetus_huntmastery_timer:DeclareFunctions()
    local decFuncs = {
		MODIFIER_EVENT_ON_DEATH
    }

    return decFuncs
end

function modifier_imba_enchantress_impetus_huntmastery_timer:OnDeath(keys)
	if keys.unit == self:GetParent() and keys.unit:IsRealHero() and (keys.unit.IsReincarnating and not keys.unit:IsReincarnating()) then
		self.caster	= self:GetCaster()
		
		local impetus_modifier	= self.caster:FindModifierByName("modifier_imba_enchantress_impetus")
		
		if impetus_modifier then
			impetus_modifier:IncrementStackCount()
			
			if self.caster:GetName() == "npc_dota_hero_enchantress" then
				self.caster:EmitSound("enchantress_ench_ability_impetus_0"..math.random(1,7))
			end
		end
	end
end

---------------------
-- TALENT HANDLERS --
---------------------

-- # Talents
-- * Level 10: +25 Movement Speed Aura | +15% Magic Resistance Aura (Aura radius is equal to Enchantress's attack range)
-- * Level 15: +300% Bonus Vision on Charmed Units | +50 Damage, +10% Spell Amp
-- * Level 20: +3s/3x Enchant Slow/Charm Duration | Peace Was Always An Option (+125 Untouchable Slow; Peace on Earth now bypasses status resistance)
-- * Level 25: Sprites' Attraction (2x Nature's Attendants wisps, heal amount, Rest for the Weary health threshold, and Fundemental's Essence values) | Armament Equivalency (Impetus deals additional physical and magical damage based on the target's spell amp and damage respectively.)

-- Client-side helper functions --

LinkLuaModifier("modifier_special_bonus_imba_enchantress_1", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_1_aura", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_2", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_2_aura", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_3", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_4", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_5", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_6", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_7", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_8", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_imba_enchantress_9", "abilities/dota_imba/hero_enchantress", LUA_MODIFIER_MOTION_NONE)

modifier_special_bonus_imba_enchantress_2_aura	= class({})
modifier_special_bonus_imba_enchantress_3		= class({})
modifier_special_bonus_imba_enchantress_4		= class({})
modifier_special_bonus_imba_enchantress_5		= class({})
modifier_special_bonus_imba_enchantress_6		= class({})
modifier_special_bonus_imba_enchantress_7		= class({})
modifier_special_bonus_imba_enchantress_8		= class({})
modifier_special_bonus_imba_enchantress_9		= class({})

-----------------------
-- TALENT 1 MODIFIER --
-----------------------
-- Magic Resistance Aura
modifier_special_bonus_imba_enchantress_1		= class({})

function modifier_special_bonus_imba_enchantress_1:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_1:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_1:RemoveOnDeath() 		return false end

function modifier_special_bonus_imba_enchantress_1:IsAura() 				return true end
function modifier_special_bonus_imba_enchantress_1:IsAuraActiveOnDeath() 	return false end

function modifier_special_bonus_imba_enchantress_1:GetAuraRadius()			return self:GetParent():Script_GetAttackRange() end
function modifier_special_bonus_imba_enchantress_1:GetAuraSearchFlags()		return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_special_bonus_imba_enchantress_1:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_special_bonus_imba_enchantress_1:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_special_bonus_imba_enchantress_1:GetModifierAura()		return "modifier_special_bonus_imba_enchantress_1_aura" end

----------------------------
-- TALENT 1 MODIFIER AURA --
----------------------------

modifier_special_bonus_imba_enchantress_1_aura	= class({})

function modifier_special_bonus_imba_enchantress_1_aura:GetTexture()
	return "enchantress_enchant"
end

function modifier_special_bonus_imba_enchantress_1_aura:OnCreated()
	self.value = self:GetCaster():FindTalentValue("special_bonus_imba_enchantress_1")
end

function modifier_special_bonus_imba_enchantress_1_aura:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}

  	return decFuncs
end

function modifier_special_bonus_imba_enchantress_1_aura:GetModifierMagicalResistanceBonus()
  	return self.value
end

-----------------------
-- TALENT 2 MODIFIER --
-----------------------
-- Movement Speed Aura
modifier_special_bonus_imba_enchantress_2		= class({})

function modifier_special_bonus_imba_enchantress_2:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_2:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_2:RemoveOnDeath() 		return false end

function modifier_special_bonus_imba_enchantress_2:IsAura() 				return true end
function modifier_special_bonus_imba_enchantress_2:IsAuraActiveOnDeath() 	return false end

function modifier_special_bonus_imba_enchantress_2:GetAuraRadius()			return self:GetParent():Script_GetAttackRange() end
function modifier_special_bonus_imba_enchantress_2:GetAuraSearchFlags()		return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_special_bonus_imba_enchantress_2:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_special_bonus_imba_enchantress_2:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_special_bonus_imba_enchantress_2:GetModifierAura()		return "modifier_special_bonus_imba_enchantress_2_aura" end

----------------------------
-- TALENT 2 MODIFIER AURA --
----------------------------

modifier_special_bonus_imba_enchantress_2_aura	= class({})

function modifier_special_bonus_imba_enchantress_2_aura:GetTexture()
	return "enchantress_enchant"
end

function modifier_special_bonus_imba_enchantress_2_aura:OnCreated()
	self.value = self:GetCaster():FindTalentValue("special_bonus_imba_enchantress_2")
end

function modifier_special_bonus_imba_enchantress_2_aura:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}

  	return decFuncs
end

function modifier_special_bonus_imba_enchantress_2_aura:GetModifierMoveSpeedBonus_Constant ()
  	return self.value
end

-----------------------
-- TALENT 3 MODIFIER --
-----------------------
-- Damage and Spell Amp
function modifier_special_bonus_imba_enchantress_3:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_3:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_3:RemoveOnDeath() 		return false end

function modifier_special_bonus_imba_enchantress_3:OnCreated()
	self.damage		= self:GetCaster():FindTalentValue("special_bonus_imba_enchantress_3", "damage")
	self.spell_amp	= self:GetCaster():FindTalentValue("special_bonus_imba_enchantress_3", "spell_amp")
end

function modifier_special_bonus_imba_enchantress_3:DeclareFunctions()
	local decFuncs = {
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}

  	return decFuncs
end

function modifier_special_bonus_imba_enchantress_3:GetModifierPreAttack_BonusDamage()
  	return self.damage
end

function modifier_special_bonus_imba_enchantress_3:GetModifierSpellAmplify_Percentage()
  	return self.spell_amp
end

-----------------------
-- TALENT 4 MODIFIER --
-----------------------
-- Massive Bonus Vision on Charmed Units
function modifier_special_bonus_imba_enchantress_4:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_4:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_4:RemoveOnDeath() 		return false end

-----------------------
-- TALENT 5 MODIFIER --
-----------------------
-- Untouchable Boost and Peace on Earth Status Resist Bypass
function modifier_special_bonus_imba_enchantress_5:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_5:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_5:RemoveOnDeath() 		return false end

-----------------------
-- TALENT 6 MODIFIER --
-----------------------
-- Enchant duration increase
function modifier_special_bonus_imba_enchantress_6:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_6:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_6:RemoveOnDeath() 		return false end

-----------------------
-- TALENT 7 MODIFIER --
-----------------------
-- Impetus Conditional Bonus Damage
function modifier_special_bonus_imba_enchantress_7:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_7:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_7:RemoveOnDeath() 		return false end

-----------------------
-- TALENT 8 MODIFIER --
-----------------------
-- Nature's Attendants doubling
function modifier_special_bonus_imba_enchantress_8:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_8:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_8:RemoveOnDeath() 		return false end

-----------------------
-- TALENT 9 MODIFIER --
-----------------------
-- +X% Impetus Damage
function modifier_special_bonus_imba_enchantress_9:IsHidden() 			return true end
function modifier_special_bonus_imba_enchantress_9:IsPurgable() 		return false end
function modifier_special_bonus_imba_enchantress_9:RemoveOnDeath() 		return false end

-- Since modifiers can't be applied on a dead unit, make sure they get slapped onto Enchantress on respawn if she skills a talent while dead
-- Let's do this by just attaching all the modifiers to respective abilities (and default to Untouchable if the talent isn't related to an ability)
-- Hopefully people don't go skilling zero abilities and only all talents while dead and then complaining that it doesn't work...
function imba_enchantress_untouchable:OnOwnerSpawned()
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_1") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_1") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_1"), "modifier_special_bonus_imba_enchantress_1", {})
	end

	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_2") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_2") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_2"), "modifier_special_bonus_imba_enchantress_2", {})
	end
	
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_3") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_3") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_3"), "modifier_special_bonus_imba_enchantress_3", {})
	end
	
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_5") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_5") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_5"), "modifier_special_bonus_imba_enchantress_5", {})
	end
end

function imba_enchantress_enchant:OnOwnerSpawned()
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_4") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_4") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_4"), "modifier_special_bonus_imba_enchantress_4", {})
	end
		
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_6") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_6") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_6"), "modifier_special_bonus_imba_enchantress_6", {})
	end
end

function imba_enchantress_natures_attendants:OnOwnerSpawned()
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_8") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_8") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_4"), "modifier_special_bonus_imba_enchantress_4", {})
	end
		
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_8") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_8") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_8"), "modifier_special_bonus_imba_enchantress_8", {})
	end
end

function imba_enchantress_impetus:OnOwnerSpawned()
	if self:GetCaster():HasTalent("special_bonus_imba_enchantress_7") and not self:GetCaster():HasModifier("modifier_special_bonus_imba_enchantress_7") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetCaster():FindAbilityByName("special_bonus_imba_enchantress_7"), "modifier_special_bonus_imba_enchantress_7", {})
	end
end
