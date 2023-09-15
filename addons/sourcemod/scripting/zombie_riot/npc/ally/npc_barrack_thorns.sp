#pragma semicolon 1
#pragma newdecls required

int ThornsDecidedOnAttack[MAXENTITIES];
int ThornsAbilityAttackTimes[MAXENTITIES];
int ThornsAbilityActiveTimes[MAXENTITIES];
float ThornsAbilityActive[MAXENTITIES];
int ThornsLevelAt[MAXENTITIES];
float ThornsAttackedSince[MAXENTITIES];

static const char g_RangedAttackSounds[][] = {
	"weapons/bison_main_shot_01.wav",
	"weapons/bison_main_shot_02.wav",
};
static const char g_RangedAttackSoundsAbility[][] = {
	"weapons/bison_main_shot_crit.wav",
};
static const char g_RangedAttackSoundsAbilityActivate[][] = {
	"weapons/bison_main_shot.wav",
};
static const char g_ThornsSpawn[][] = {
	"items/spawn_item.wav",
};
static const char g_ThornsDeath[][] = {
	"ui/rd_2base_alarm.wav",
};

public void Barracks_Thorns()
{
	for (int i = 0; i < (sizeof(g_RangedAttackSounds));   i++)			{ PrecacheSound(g_RangedAttackSounds[i]);   }
	for (int i = 0; i < (sizeof(g_RangedAttackSoundsAbility));   i++)			{ PrecacheSound(g_RangedAttackSoundsAbility[i]);   }
	for (int i = 0; i < (sizeof(g_RangedAttackSoundsAbilityActivate));   i++)			{ PrecacheSound(g_RangedAttackSoundsAbilityActivate[i]);}
	for (int i = 0; i < (sizeof(g_ThornsSpawn));   i++)			{ PrecacheSound(g_ThornsSpawn[i]);   }
	for (int i = 0; i < (sizeof(g_ThornsDeath));   i++)			{ PrecacheSound(g_ThornsDeath[i]);   }
	
}

bool ThornsHasElite[MAXENTITIES];
bool ThornsHasMaxPot[MAXENTITIES];

float ThornsDelayTimerUpgrade[MAXENTITIES];
methodmap BarrackThorns < BarrackBody
{
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)],
		this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
	}
	public void PlayRangedSoundAbility() 
	{
		EmitSoundToAll(g_RangedAttackSoundsAbility[GetRandomInt(0, sizeof(g_RangedAttackSoundsAbility) - 1)],
		this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
	}
	public void PlayRangedSoundAbilitActivate() 
	{
		EmitSoundToAll(g_RangedAttackSoundsAbilityActivate[GetRandomInt(0, sizeof(g_RangedAttackSoundsAbilityActivate) - 1)],
		this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
	}
	public void PlayThornsSpawn() 
	{
		EmitSoundToAll(g_ThornsSpawn[GetRandomInt(0, sizeof(g_ThornsSpawn) - 1)],
		this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
	}
	public void PlayThornsDeath()
	{
		EmitSoundToAll(g_ThornsDeath[GetRandomInt(0, sizeof(g_ThornsDeath) - 1)],
		this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
	}
	public BarrackThorns(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		bool elite = view_as<bool>(Store_HasNamedItem(client, "Construction Master"));
		bool MaxPot = view_as<bool>(Store_HasNamedItem(client, "Construction Killer"));
		
		char healthSize[10];

		Format(healthSize, sizeof(healthSize), "1000");

		if(elite)
		{
			Format(healthSize, sizeof(healthSize), "2000");
		}

		if(MaxPot)
		{
			Format(healthSize, sizeof(healthSize), "3000");
		}

		BarrackThorns npc = view_as<BarrackThorns>(BarrackBody(client, vecPos, vecAng, healthSize,_,_,"0.75",_,"models/pickups/pickup_powerup_thorns.mdl"));

		ThornsLevelAt[npc.index] = 0;

		if(elite)
		{
			ThornsLevelAt[npc.index] = 1;
		}

		if(MaxPot)
		{
			ThornsLevelAt[npc.index] = 2;
		}
		ThornsHasElite[npc.index] = elite;
		ThornsHasMaxPot[npc.index] = MaxPot;

		ThornsDelayTimerUpgrade[npc.index] = GetGameTime() + 5.0;

		i_NpcInternalId[npc.index] = BARRACK_THORNS;
		i_NpcWeight[npc.index] = 2;
		
		SDKHook(npc.index, SDKHook_Think, BarrackThorns_ClotThink);
		npc.PlayThornsSpawn();

		npc.m_flSpeed = 250.0;

		if(elite)
			npc.BonusDamageBonus *= 1.5;

		ThornsDecidedOnAttack[npc.index] = 0;
		ThornsAbilityAttackTimes[npc.index] = 0;
		ThornsAbilityActiveTimes[npc.index] = 0;
		ThornsAbilityActive[npc.index] = 0.0;
		ThornsAttackedSince[npc.index] = 0.0;
		npc.m_bDissapearOnDeath = true;
		
		npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/workshop/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
		
		npc.m_iWearable2 = npc.EquipItem("weapon_bone", "models/player/items/demo/hwn_demo_hat.mdl");
		SetVariantString("1.15");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");

		SetEntityRenderMode(npc.m_iWearable1, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.m_iWearable1, 200, 255, 125, 255);


		SetVariantInt(12);
		AcceptEntityInput(npc.index, "SetBodyGroup");
		
		return npc;
	}
}

public void BarrackThorns_ClotThink(int iNPC)
{
	BarrackThorns npc = view_as<BarrackThorns>(iNPC);
	float GameTime = GetGameTime(iNPC);
	if(ThornsDelayTimerUpgrade[npc.index] < GetGameTime())
	{
		int owner = GetClientOfUserId(npc.OwnerUserId);
		if(IsValidClient(owner))
		{
			ThornsDelayTimerUpgrade[npc.index] = GetGameTime() + 5.0;
			if(!ThornsHasElite[npc.index])
			{
				ThornsHasElite[npc.index] = view_as<bool>(Store_HasNamedItem(owner, "Construction Master"));
				if(ThornsHasElite[npc.index])
				{
					ThornsLevelAt[npc.index] = 1;
					npc.BonusDamageBonus *= 1.5;
					SetEntProp(npc.index, Prop_Data, "m_iMaxHealth",GetEntProp(npc.index, Prop_Data, "m_iMaxHealth") * 2);
				}
			}
			if(!ThornsHasMaxPot[npc.index])
			{
				ThornsHasMaxPot[npc.index] = view_as<bool>(Store_HasNamedItem(owner, "Construction Killer"));
				if(ThornsHasMaxPot[npc.index])
				{
					ThornsLevelAt[npc.index] = 2;
					SetEntProp(npc.index, Prop_Data, "m_iMaxHealth", RoundToNearest(float(GetEntProp(npc.index, Prop_Data, "m_iMaxHealth")) * 1.5));
				}
			}
			if(ThornsLevelAt[npc.index] == 2)
			{
				ThornsDelayTimerUpgrade[npc.index] = FAR_FUTURE;
			}
		}
		else
		{
			ThornsDelayTimerUpgrade[npc.index] = FAR_FUTURE;
		}
	}
	if(npc.m_flDoingAnimation)
	{
		npc.m_flSpeed = 0.0;
		if(npc.m_flDoingAnimation < GetGameTime(npc.index))
		{
			npc.m_flDoingAnimation = 0.0;
			npc.StartPathing();
			npc.m_flSpeed = 250.0;
		}
	}
	else
	{
		npc.m_flSpeed = 250.0;
	}

	if(BarrackBody_ThinkStart(npc.index, GameTime))
	{
		int client = BarrackBody_ThinkTarget(npc.index, true, GameTime);
		int command = client ? (npc.CmdOverride == Command_Default ? Building_GetFollowerCommand(client) : npc.CmdOverride) : Command_Aggressive;
		bool retreating = (command == Command_Retreat || command == Command_RetreatPlayer);

		if(ThornsAttackedSince[npc.index] < GetGameTime(npc.index))
		{
			if(GetEntProp(npc.index, Prop_Data, "m_iHealth") < GetEntProp(npc.index, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(npc.index, Prop_Data, "m_iHealth", GetEntProp(npc.index, Prop_Data, "m_iHealth") + 10);
				if(GetEntProp(npc.index, Prop_Data, "m_iHealth") >= GetEntProp(npc.index, Prop_Data, "m_iMaxHealth"))
				{
					SetEntProp(npc.index, Prop_Data, "m_iHealth", GetEntProp(npc.index, Prop_Data, "m_iMaxHealth"));
				}
			}
		}
		float RangeLimit = 1200.0;

		if(retreating)
			RangeLimit = 100.0;

		//when retreating, he wont attack unless they are literally blocking him or something.

		int EnemyToAttack = GetClosestTarget(npc.index,
		false,
		RangeLimit,
		_,
		_,
		_, 
		_,
		true,
		_,
		_,
		true);

		if(EnemyToAttack > 0)
		{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(EnemyToAttack);
			float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);


			if(ThornsAbilityAttackTimes[npc.index] >= 15)
			{
				npc.PlayRangedSoundAbilitActivate();
				ThornsAbilityActiveTimes[npc.index] += 1;
				ThornsAbilityAttackTimes[npc.index] = 0;
				ThornsAbilityActive[npc.index] = GetGameTime(npc.index) + 30.0;
				float startPosition[3];
				GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", startPosition);
				if(ThornsAbilityActiveTimes[npc.index] > 1)
				{
					ThornsAbilityActive[npc.index] = FAR_FUTURE;
					npc.m_iWearable3 = ParticleEffectAt_Parent(startPosition, "utaunt_gifts_floorglow_brown", npc.index, "root", {0.0,0.0,0.0});

				}
				else
				{
					npc.m_iWearable3 = ParticleEffectAt_Parent(startPosition, "utaunt_gifts_floorglow_brown", npc.index, "root", {0.0,0.0,0.0});
					CreateTimer(30.0, Timer_RemoveEntity, EntIndexToEntRef(npc.m_iWearable3), TIMER_FLAG_NO_MAPCHANGE);
				}
			}


			if(ThornsAbilityActive[npc.index] > GetGameTime(npc.index) || ThornsDecidedOnAttack[npc.index] == 3)
			{
				if(flDistanceToTarget < (1200.0 * 1200.0) || ThornsDecidedOnAttack[npc.index] == 3)
				{
					ThornsBasicAttackM2Ability(npc,GetGameTime(npc.index),EnemyToAttack); 
				}
			}
			else
			{
				if(flDistanceToTarget < (800.0 * 800.0) && flDistanceToTarget > (100.0 * 100.0) || ThornsDecidedOnAttack[npc.index] == 1)
				{
					ThornsBasicAttackM1Ranged(npc,GetGameTime(npc.index),EnemyToAttack); 
				}
				if(flDistanceToTarget < (800.0 * 800.0) && flDistanceToTarget < (100.0 * 100.0) ||ThornsDecidedOnAttack[npc.index] == 2)
				{
					ThornsBasicAttackM1Melee(npc,GetGameTime(npc.index),EnemyToAttack); 
				}				
			}

		}
		if(npc.m_flDoingAnimation < GetGameTime(npc.index))
		{
			BarrackBody_ThinkMove(npc.index, 250.0, "ACT_THORNS_STAND", "ACT_THORNS_WALK");
		}
	}
}

void BarrackThorns_NPCDeath(int entity)
{
	BarrackThorns npc = view_as<BarrackThorns>(entity);
	BarrackBody_NPCDeath(npc.index);
	SDKUnhook(npc.index, SDKHook_Think, BarrackThorns_ClotThink);
	npc.PlayThornsDeath();
	
	int entity_death = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(entity_death))
	{
		BarrackThorns prop = view_as<BarrackThorns>(entity_death);
		float pos[3];
		float Angles[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", Angles);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(entity_death, pos, Angles, NULL_VECTOR);

		DispatchKeyValue(entity_death, "model", COMBINE_CUSTOM_MODEL);

		DispatchSpawn(entity_death);
		
		prop.m_iWearable1 = prop.EquipItem("weapon_bone", "models/workshop/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(prop.m_iWearable1, "SetModelScale");

		prop.m_iWearable2 = prop.EquipItem("weapon_bone", "models/player/items/demo/hwn_demo_hat.mdl");
		SetVariantString("1.15");
		AcceptEntityInput(prop.m_iWearable2, "SetModelScale");

		SetVariantInt(12);
		AcceptEntityInput(entity_death, "SetBodyGroup");

		SetEntPropFloat(entity_death, Prop_Send, "m_flModelScale", 0.75); 
		SetEntityCollisionGroup(entity_death, 2);
		SetVariantString("Thorns_Death");
		AcceptEntityInput(entity_death, "SetAnimation");
		
		CreateTimer(1.0, Timer_RemoveEntity, EntIndexToEntRef(entity_death), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_RemoveEntity, EntIndexToEntRef(prop.m_iWearable1), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_RemoveEntity, EntIndexToEntRef(prop.m_iWearable2), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ThornsBasicAttackM1Melee(BarrackThorns npc, float gameTime, int EnemyToAttack)
{
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < GetGameTime(npc.index))
		{
			npc.m_flAttackHappens = 0.0;
			ThornsDecidedOnAttack[npc.index] = 0;
			if(IsValidEnemy(npc.index, EnemyToAttack))
			{
				npc.FaceTowards(WorldSpaceCenter(EnemyToAttack), 15000.0);
				Handle swingTrace;
				npc.FaceTowards(WorldSpaceCenter(EnemyToAttack), 15000.0);
				if(npc.DoSwingTrace(swingTrace, EnemyToAttack, _, _, _, 1)) //Big range, but dont ignore buildings if somehow this doesnt count as a raid to be sure.
				{
								
					int target = TR_GetEntityIndex(swingTrace);	
					
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);
					
					if(target > 0) 
					{
						ThornsAbilityAttackTimes[npc.index] += 1;
						float damage = 2000.0;
						if(ThornsLevelAt[npc.index] == 2)
						{
							damage *= 2.5;
						}
						else if(ThornsLevelAt[npc.index] == 1)
						{
							damage *= 1.5;
						}
						SDKHooks_TakeDamage(target, npc.index, GetClientOfUserId(npc.OwnerUserId), Barracks_UnitExtraDamageCalc(npc.index, GetClientOfUserId(npc.OwnerUserId),damage, 0), DMG_CLUB, -1, _, vecHit);						

						npc.PlayMeleeHitSound();
					} 
				}
				delete swingTrace;
			}
		}
	}

	if(GetGameTime(npc.index) > npc.m_flNextMeleeAttack)
	{
		if(IsValidEnemy(npc.index, EnemyToAttack)) 
		{
			int Enemy_I_See;
									
			Enemy_I_See = Can_I_See_Enemy(npc.index, EnemyToAttack);
						
			if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
			{
				EnemyToAttack = Enemy_I_See;
				npc.AddGesture("ACT_THORNS_ATTACK_1");
				npc.PlaySwordSound();
				float Attackrate = (1.0 * npc.BonusFireRate);
				float AnimRate = 0.3;
				if(Attackrate <= 0.3)
				{
					AnimRate = Attackrate;
				}
				npc.m_flAttackHappens = gameTime + AnimRate;
				npc.m_flNextMeleeAttack = gameTime + Attackrate;
				npc.m_flDoingAnimation = gameTime + 1.0;
				NPC_StopPathing(npc.index);
				npc.m_flSpeed = 0.0;
				ThornsDecidedOnAttack[npc.index] = 2;
				ThornsAttackedSince[npc.index] = GetGameTime(npc.index) + 5.0;
				//make thorns not move when attacking.
			}
		}
	}
}



void ThornsBasicAttackM1Ranged(BarrackThorns npc, float gameTime, int EnemyToAttack)
{
	if(npc.m_flAttackHappens)
	{
		if(IsValidEnemy(npc.index, EnemyToAttack))
		{
			npc.FaceTowards(WorldSpaceCenter(EnemyToAttack), 15000.0);
		}
		if(npc.m_flAttackHappens < GetGameTime(npc.index))
		{
			npc.m_flAttackHappens = 0.0;
			ThornsDecidedOnAttack[npc.index] = 0;
			
			if(IsValidEnemy(npc.index, EnemyToAttack))
			{
				int Enemy_I_See;
										
				Enemy_I_See = Can_I_See_Enemy(npc.index, EnemyToAttack);
							
				if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
				{
					ThornsAbilityAttackTimes[npc.index] += 1;

					float damage = 1500.0;
					if(ThornsLevelAt[npc.index] == 2)
					{
						damage *= 2.5;
					}
					else if(ThornsLevelAt[npc.index] == 1)
					{
						damage *= 1.5;
					}
							
					float flPos[3]; // original
					float flAng[3]; // original
					GetAttachment(npc.index, "weapon_bone", flPos, flAng);
					float vecTarget[3];
					float speed = 2000.0;
					vecTarget = PredictSubjectPositionForProjectiles(npc, EnemyToAttack, speed);
					npc.m_flSpeed = 0.0;
					int rocket;
					rocket = npc.FireParticleRocket(vecTarget, Barracks_UnitExtraDamageCalc(npc.index, GetClientOfUserId(npc.OwnerUserId),damage, 1) , speed, 100.0 , "raygun_projectile_red_trail", _, false, true, flPos, _ , GetClientOfUserId(npc.OwnerUserId));
				//	npc.DispatchParticleEffect(npc.index, "utaunt_firework_shockwave", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, npc.FindAttachment("effect_hand_r"), PATTACH_POINT_FOLLOW, true);

					DataPack pack;
					CreateDataTimer(0.1, PerfectHomingShot, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					pack.WriteCell(EntIndexToEntRef(rocket)); //projectile
					pack.WriteCell(EntIndexToEntRef(EnemyToAttack));		//victim to annihilate :)
				}
			}
		}
	}

	if(GetGameTime(npc.index) > npc.m_flNextMeleeAttack)
	{
		if(IsValidEnemy(npc.index, EnemyToAttack)) 
		{
			int Enemy_I_See;
									
			Enemy_I_See = Can_I_See_Enemy(npc.index, EnemyToAttack);
						
			if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
			{
				EnemyToAttack = Enemy_I_See;
				npc.AddGesture("ACT_THORNS_ATTACK_1_RANGED");
				npc.PlaySwordSound();
				float Attackrate = (1.0 * npc.BonusFireRate);
				float AnimRate = 0.45;
				if(Attackrate <= 0.45)
				{
					AnimRate = Attackrate;
				}
				npc.m_flAttackHappens = gameTime + AnimRate;
				npc.m_flNextMeleeAttack = gameTime + Attackrate;
				npc.m_flDoingAnimation = gameTime + 1.0;
				NPC_StopPathing(npc.index);
				npc.m_flSpeed = 0.0;
				//make thorns not move when attacking.
				ThornsDecidedOnAttack[npc.index] = 1;
				ThornsAttackedSince[npc.index] = GetGameTime(npc.index) + 5.0;
			}
		}
	}
}



void ThornsBasicAttackM2Ability(BarrackThorns npc, float gameTime, int EnemyToAttack)
{
	if(npc.m_flAttackHappens)
	{
		if(IsValidEnemy(npc.index, EnemyToAttack))
		{
			npc.FaceTowards(WorldSpaceCenter(EnemyToAttack), 15000.0);
		}
		if(npc.m_flAttackHappens < GetGameTime(npc.index))
		{
			npc.m_flAttackHappens = 0.0;
			ThornsDecidedOnAttack[npc.index] = 0;
			
			if(IsValidEnemy(npc.index, EnemyToAttack))
			{
				int Enemy_I_See;
										
				Enemy_I_See = Can_I_See_Enemy(npc.index, EnemyToAttack);
							
				if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
				{
					npc.PlayRangedSoundAbility();

					float damage = 2000.0;

					if(ThornsAbilityActiveTimes[npc.index] > 1)
					{
						damage = 3000.0;
					}
					
					if(ThornsLevelAt[npc.index] == 2)
					{
						damage *= 3.5;
					}
					else if(ThornsLevelAt[npc.index] == 1)
					{
						damage *= 2.0;
					}
							
					float flPos[3]; // original
					float flAng[3]; // original
					GetAttachment(npc.index, "weapon_bone", flPos, flAng);
					float vecTarget[3];
					float speed = 2000.0;
					vecTarget = PredictSubjectPositionForProjectiles(npc, EnemyToAttack, speed);
					npc.m_flSpeed = 0.0;
					int rocket;
					rocket = npc.FireParticleRocket(vecTarget, Barracks_UnitExtraDamageCalc(npc.index, GetClientOfUserId(npc.OwnerUserId),damage, 1) , speed, 100.0 , "raygun_projectile_red_crit", _, false, true, flPos, _ , GetClientOfUserId(npc.OwnerUserId));
				
				//	npc.DispatchParticleEffect(npc.index, "utaunt_firework_shockwave", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, npc.FindAttachment("effect_hand_r"), PATTACH_POINT_FOLLOW, true);
					DataPack pack;
					CreateDataTimer(0.1, PerfectHomingShot, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					pack.WriteCell(EntIndexToEntRef(rocket)); //projectile
					pack.WriteCell(EntIndexToEntRef(EnemyToAttack));		//victim to annihilate :)
				
				}
			}
		}
	}

	if(GetGameTime(npc.index) > npc.m_flNextMeleeAttack)
	{
		if(IsValidEnemy(npc.index, EnemyToAttack)) 
		{
			int Enemy_I_See;
									
			Enemy_I_See = Can_I_See_Enemy(npc.index, EnemyToAttack);
						
			if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
			{
				EnemyToAttack = Enemy_I_See;
				if(ThornsAbilityActiveTimes[npc.index] > 1)
				{
					npc.AddGesture("ACT_THORNS_ATTACK_2_FAST");
					npc.PlaySwordSound();
					float Attackrate = (0.4 * npc.BonusFireRate);
					float AnimRate = 0.3;
					if(Attackrate <= 0.3)
					{
						AnimRate = Attackrate;
					}
					npc.m_flAttackHappens = gameTime + AnimRate;
					npc.m_flNextMeleeAttack = gameTime + Attackrate;
				}
				else
				{
					npc.AddGesture("ACT_THORNS_ATTACK_2");
					npc.PlaySwordSound();
					float Attackrate = (0.75 * npc.BonusFireRate);
					float AnimRate = 0.35;
					if(Attackrate <= 0.35)
					{
						AnimRate = Attackrate;
					}
					npc.m_flAttackHappens = gameTime + AnimRate;
					npc.m_flNextMeleeAttack = gameTime + Attackrate;
					npc.m_flDoingAnimation = gameTime + 0.75;					
				}
				NPC_StopPathing(npc.index);
				npc.m_flSpeed = 0.0;
				//make thorns not move when attacking.
				ThornsDecidedOnAttack[npc.index] = 3;
				ThornsAttackedSince[npc.index] = GetGameTime(npc.index) + 5.0;
			}
		}
	}
}