#pragma semicolon 1
#pragma newdecls required

//If i see any of you using this on any bvb hale i will kill you and turn you into a kebab.
//This shit is so fucking unfair for the targeted.


#define IRENE_JUDGEMENT_MAX_HITS_NEEDED 64 	//Double the amount because we do double hits.
#define IRENE_JUDGEMENT_MAXRANGE 350.0 		
#define IRENE_JUDGEMENT_EXPLOSION_RANGE 75.0 		

#define IRENE_BOSS_AIRTIME 0.75		
#define IRENE_AIRTIME 1.75		

#define IRENE_MAX_HITUP 10

#define IRENE_EXPLOSION_1 "mvm/giant_common/giant_common_explodes_01.wav"
#define IRENE_EXPLOSION_2 "mvm/giant_common/giant_common_explodes_02.wav"

#define IRENE_KICKUP_1 "mvm/giant_soldier/giant_soldier_rocket_shoot.wav"

Handle h_TimerIreneManagement[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
static float f_Irenehuddelay[MAXTF2PLAYERS];
static int i_IreneHitsDone[MAXTF2PLAYERS];
static float f_WeaponAttackSpeedModified[MAXENTITIES];
static int i_IreneTargetsAirborn[MAXTF2PLAYERS][IRENE_MAX_HITUP];
static float f_TargetAirtime[MAXENTITIES];
static float f_TargetAirtimeDelayHit[MAXENTITIES];
static float f_TimeSinceLastStunHit[MAXENTITIES];
static bool b_IreneNpcWasShotUp[MAXENTITIES];
static int i_RefWeaponDelete[MAXTF2PLAYERS];
static float f_WeaponDamageCalculated[MAXTF2PLAYERS];

static int LaserSprite;
#define SPRITE_SPRITE	"materials/sprites/laserbeam.vmt"

void Npc_OnTakeDamage_Iberia(int attacker, int damagetype)
{
	if(damagetype & DMG_CLUB) //We only count normal melee hits.
	{
		i_IreneHitsDone[attacker] += 1;
		if(i_IreneHitsDone[attacker] > IRENE_JUDGEMENT_MAX_HITS_NEEDED) //We do not go above this, no double charge.
		{
			i_IreneHitsDone[attacker] = IRENE_JUDGEMENT_MAX_HITS_NEEDED;
		}
	}
}

bool Npc_Is_Targeted_In_Air(int entity) //Anything that needs to be precaced like sounds or something.
{
	if(f_TargetAirtime[entity] > GetGameTime(entity))
	{
		return true;
	}
	return false;
}

void Irene_Map_Precache() //Anything that needs to be precaced like sounds or something.
{
	PrecacheSound(IRENE_KICKUP_1);
	PrecacheSound(IRENE_EXPLOSION_1);
	PrecacheSound(IRENE_EXPLOSION_2);
	PrecacheSound("vo/taunts/scout_taunts06.mp3");
	PrecacheSound("vo/taunts/soldier_taunts17.mp3");
	PrecacheSound("vo/taunts/sniper_taunts22.mp3");
	PrecacheSound("vo/taunts/demoman_taunts11.mp3");
	PrecacheSound("vo/taunts/medic_taunts13.mp3");
	PrecacheSound("vo/pyro_laughevil01.mp3");
	PrecacheSound("vo/taunts/heavy_taunts16.mp3");
	PrecacheSound("vo/taunts/spy_taunts12.mp3");
	PrecacheSound("vo/taunts/engineer_taunts04.mp3");

	LaserSprite = PrecacheModel(SPRITE_SPRITE, false);
}

void Reset_stats_Irene_Global()
{
	Zero(f_TimeSinceLastStunHit);
	Zero(h_TimerIreneManagement);
	Zero(f_Irenehuddelay); //Only needs to get reset on map change, not disconnect.
	Zero(i_IreneHitsDone); //This only ever gets reset on map change or player reset
	Zero(f_TargetAirtime); //what.
}

void Reset_stats_Irene_Singular(int client) //This is on disconnect/connect
{
	h_TimerIreneManagement[client] = INVALID_HANDLE;
	i_IreneHitsDone[client] = 0;
}

void Reset_stats_Irene_Singular_Weapon(int client, int weapon) //This is on weapon remake. cannot set to 0 outright.
{
	f_WeaponAttackSpeedModified[weapon] = Attributes_FindOnWeapon(client, weapon, 6, true, 1.0);
}

public void Weapon_Irene_DoubleStrike(int client, int weapon, bool crit, int slot)
{
	Enable_Irene(client, weapon);
	//Show the timer, this is purely for looks and doesnt do anything.
//	float cooldown = 0.65 * Attributes_FindOnWeapon(client, weapon, 6, true, 1.0);

	//We wish to do a double attack.
	//Delay it abit extra!

	
	/*
	LAZY WAY:
	DataPack pack;
	CreateDataTimer(0.25, Timer_Do_Melee_Attack, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(EntIndexToEntRef(weapon));
	pack.WriteString("tf_weapon_knife"); //We will hardcode this to tf_weapon_knife because i am lazy as fuck. 
	*/
	/* 
		PRO WAY:
		So that animations display properly, we wish to accelerate the attackspeed massively by 1
		Issue: players can just delay the double attack
		Fix for this would be just just reset back to the original attack speed if they dont attack.
		This is annoying but this is really cool instead of the above LAZY method!

	*/
	//We save this onto the weapon if the modified attackspeed is not modified.

	float attackspeed = Attributes_FindOnWeapon(client, weapon, 6, true, 1.0);
	if(attackspeed > 0.15) //The attackspeed is right now not modified, lets save it for later and then apply our faster attackspeed.
	{
		TF2Attrib_SetByDefIndex(weapon, 6, (attackspeed * 0.15));
	}
	else
	{
		TF2Attrib_SetByDefIndex(weapon, 6, (attackspeed / 0.15)); //Make it really fast for 1 hit!
	}
}

public void Enable_Irene(int client, int weapon) // Enable management, handle weapons change but also delete the timer if the client have the max weapon
{
	if (h_TimerIreneManagement[client] != INVALID_HANDLE)
		return;
		
	if(i_CustomWeaponEquipLogic[weapon] == 6) //6 is for irene.
	{
		DataPack pack;
		h_TimerIreneManagement[client] = CreateDataTimer(0.1, Timer_Management_Irene, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
	else
	{
		Kill_Timer_Irene(client);
	}
}



public Action Timer_Management_Irene(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if(IsValidClient(client))
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				Irene_Cooldown_Logic(client, EntRefToEntIndex(pack.ReadCell()));
			}
			else
				Kill_Timer_Irene(client);
		}
		else
			Kill_Timer_Irene(client);
	}
	else
		Kill_Timer_Irene(client);
		
	return Plugin_Continue;
}


public void Irene_Cooldown_Logic(int client, int weapon)
{
	if (!IsValidMulti(client))
		return;
		
	if(IsValidEntity(weapon))
	{
		if(i_CustomWeaponEquipLogic[weapon] == 6) //Double check to see if its good or bad :(
		{	
			if(f_Irenehuddelay[client] < GetGameTime())
			{
				if(i_IreneHitsDone[client] < IRENE_JUDGEMENT_MAX_HITS_NEEDED)
				{
					PrintHintText(client,"Judgemet Of Iberia [%i%/%i]", i_IreneHitsDone[client], IRENE_JUDGEMENT_MAX_HITS_NEEDED);
				}
				else
				{
					PrintHintText(client,"Judgemet Of Iberia [READY!]");
				}
				
				StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
				f_Irenehuddelay[client] = GetGameTime() + 0.5;
			}
		}
		else
		{
			Kill_Timer_Irene(client);
		}
	}
	else
	{
		Kill_Timer_Irene(client);
	}
}

public void Kill_Timer_Irene(int client)
{
	if (h_TimerIreneManagement[client] != INVALID_HANDLE)
	{
		KillTimer(h_TimerIreneManagement[client]);
		h_TimerIreneManagement[client] = INVALID_HANDLE;
	}
}

public void Weapon_Irene_Judgement(int client, int weapon, bool crit, int slot)
{
	//This ability has no cooldown in itself, it just relies on hits you do.
	if(i_IreneHitsDone[client] >= IRENE_JUDGEMENT_MAX_HITS_NEEDED || CvarInfiniteCash.BoolValue)
	{
		i_IreneHitsDone[client] = 0;
		//Sucess! You have enough charges.
		//Heavy logic incomming.
		float UserLoc[3], VicLoc[3];
		GetClientAbsOrigin(client, UserLoc);


		//Attackspeed wont affect this calculation.

		float damage = 40.0;
		Address address = TF2Attrib_GetByDefIndex(weapon, 2);
		if(address != Address_Null)
			damage *= RoundToCeil(TF2Attrib_GetValue(address));

		f_WeaponDamageCalculated[client] = damage;

		bool raidboss_active = false;
		if(IsValidEntity(EntRefToEntIndex(RaidBossActive)))
		{
			raidboss_active = true;
		}
		//Reset all airborn targets.
		for (int enemy = 1; enemy < IRENE_MAX_HITUP; enemy++)
		{
			i_IreneTargetsAirborn[client][enemy] = false;
		}

		int weapon_new = Store_GiveSpecificItem(client, "Irene's Handcannon");
		i_RefWeaponDelete[client] = EntIndexToEntRef(weapon_new);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon_new);

		ViewChange_Switch(client, weapon_new, "tf_weapon_revolver");

		//We want to lag compensate this.
		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(client);

		for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)
		{
			int target = EntRefToEntIndex(i_ObjectsNpcs[entitycount]);
			if(IsValidEntity(target) && !b_NpcHasDied[target])
			{
				VicLoc = WorldSpaceCenter(target);
				
				if (GetVectorDistance(UserLoc, VicLoc,true) <= Pow(IRENE_JUDGEMENT_MAXRANGE, 2.0))
				{
					bool Hitlimit = true;
					for(int i=1; i <= (MAX_TARGETS_HIT -1 ); i++)
					{
						if(!i_IreneTargetsAirborn[client][i])
						{
							i_IreneTargetsAirborn[client][i] = target;
							Hitlimit = false;
							break;
						}
					}
					if(Hitlimit)
					{
						break;
					}
					if(GetGameTime() > f_TargetAirtime[target]) //Do not shoot up again once already dome.
					{
						b_IreneNpcWasShotUp[target] = true;
					}

					if (b_thisNpcIsABoss[target] || raidboss_active)
					{
						f_TankGrabbedStandStill[target] = GetGameTime(target) + IRENE_BOSS_AIRTIME;
						f_TargetAirtime[target] = GetGameTime() + IRENE_BOSS_AIRTIME; //Kick up for way less time.
					}
					else
					{
						f_TankGrabbedStandStill[target] = GetGameTime(target) + IRENE_AIRTIME;
						f_TargetAirtime[target] = GetGameTime() + IRENE_AIRTIME; //Kick up for the full skill duration.
					}
					spawnRing_Vectors(VicLoc, 0.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 200, 1, 0.25, 6.0, 2.1, 1, IRENE_JUDGEMENT_EXPLOSION_RANGE * 0.5);	
					SDKUnhook(target, SDKHook_Think, Npc_Irene_Launch);
					SDKHook(target, SDKHook_Think, Npc_Irene_Launch);
					//For now, there is no limit.
				}
			}
		}
		FinishLagCompensation_Base_boss();
		EmitSoundToAll(IRENE_KICKUP_1, client, _, 75, _, 0.60);

		spawnRing(client, IRENE_JUDGEMENT_MAXRANGE * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 255, 1, 0.25, 6.0, 6.1, 1);
		spawnRing(client, IRENE_JUDGEMENT_MAXRANGE * 2.0, 0.0, 0.0, 25.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 255, 1, 0.17, 6.0, 6.1, 1);
		spawnRing(client, IRENE_JUDGEMENT_MAXRANGE * 2.0, 0.0, 0.0, 35.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 255, 1, 0.11, 6.0, 6.1, 1);
		spawnRing_Vectors(UserLoc, 0.0, 0.0, 5.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 200, 1, 0.25, 12.0, 6.1, 1, IRENE_JUDGEMENT_MAXRANGE * 2.0);	
		if(!b_IsPlayerNiko[client])
		{
			switch(view_as<int>(CurrentClass[client]))
			{
				case 1:
				{
					EmitSoundToAll("vo/taunts/scout_taunts06.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 2:
				{
					EmitSoundToAll("vo/taunts/soldier_taunts17.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 3:
				{
					EmitSoundToAll("vo/taunts/sniper_taunts22.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 4:
				{
					EmitSoundToAll("vo/taunts/demoman_taunts11.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 5:
				{
					EmitSoundToAll("vo/taunts/medic_taunts13.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 6:
				{
					EmitSoundToAll("vo/pyro_laughevil01.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 7:
				{
					EmitSoundToAll("vo/taunts/heavy_taunts16.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 8:
				{
					EmitSoundToAll("vo/taunts/spy_taunts12.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
				case 9:
				{
					EmitSoundToAll("vo/taunts/engineer_taunts04.mp3", client, SNDCHAN_VOICE, 90, _, 1.0);
				}
			}
		}
		f_TargetAirtime[client] = GetGameTime() + 2.0;
		f_TargetAirtimeDelayHit[client] = GetGameTime() + 0.25;
		SDKHook(client, SDKHook_PreThink, Npc_Irene_Launch_client);
		//End of logic, everything done regarding getting all enemies effected by this effect.
	}
	else
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255, 1, 0.1, 0.1, 0.1);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "Your Weapon is not charged enough.");
	}
}
public void Npc_Irene_Launch_client(int client)
{
	if(GetGameTime() > f_TargetAirtime[client])
	{
		Store_RemoveSpecificItem(client, "Irene's Handcannon");
		//We are Done, kill think.
		int TemomaryGun = EntRefToEntIndex(i_RefWeaponDelete[client]);
		if(IsValidEntity(TemomaryGun))
		{
			TF2_RemoveItem(client, TemomaryGun);
			FakeClientCommand(client, "use tf_weapon_knife");
		}
		SDKUnhook(client, SDKHook_PreThink, Npc_Irene_Launch_client);
	}	
	else if(GetGameTime() > f_TargetAirtimeDelayHit[client])
	{
		int TemomaryGun = EntRefToEntIndex(i_RefWeaponDelete[client]);
		if(!IsValidEntity(TemomaryGun))
		{
			Store_RemoveSpecificItem(client, "Irene's Handcannon");
			SDKUnhook(client, SDKHook_PreThink, Npc_Irene_Launch_client);
		}
		i_ExplosiveProjectileHexArray[TemomaryGun] = EP_DEALS_CLUB_DAMAGE;

		f_TargetAirtimeDelayHit[client] = GetGameTime() + 0.15;

		//Gather all allive airborn-ed entities.
		int count;
		int targets[MAX_TARGETS_HIT];
		for(int i=1; i <= (MAX_TARGETS_HIT -1 ); i++)
		{
			// Check if it's a valid target
			if(i_IreneTargetsAirborn[client][i] && IsValidEntity(i_IreneTargetsAirborn[client][i]) && !b_NpcHasDied[i_IreneTargetsAirborn[client][i]])
			{
				// Add it to our list, increase count by 1
				targets[count++] = i_IreneTargetsAirborn[client][i];
			}
		}
		
		//All have died, we now shoot random stuff instead.
		if(!count)
		{
			float UserLoc[3], VicLoc[3];
			GetClientAbsOrigin(client, UserLoc);
			//We want to lag compensate this.
			b_LagCompNPC_No_Layers = true;
			StartLagCompensation_Base_Boss(client);	

			for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)
			{
				int enemy = EntRefToEntIndex(i_ObjectsNpcs[entitycount]);
				if(IsValidEntity(enemy) && !b_NpcHasDied[enemy])
				{
					VicLoc = WorldSpaceCenter(enemy);
					
					if (GetVectorDistance(UserLoc, VicLoc,true) <= Pow(IRENE_JUDGEMENT_MAXRANGE, 2.0)) //respect max range.
					{
						if(count < MAX_TARGETS_HIT)
						{
							targets[count++] = enemy;
						}
						else
						{
							break;
						}
					}
				}
			}
			FinishLagCompensation_Base_boss();
		}

		if(count)
		{
			// Choosen a random one in our list
			int target = targets[GetRandomInt(0, count - 1)];

			float VicLoc[3];

			//poisition of the enemy we random decide to shoot.
			VicLoc = WorldSpaceCenter(target);

			LookAtTarget(client, target);

			//This can hit upto 10 targets in range.
			//We dont do more otherwise it will be super god damn op.
			//Damage will be multiplied by 2 because it can double hit, and 50% more extra because its an ability.
			float damage = (f_WeaponDamageCalculated[client] * 3.0);

			damage *= 1.1; //Abit extra.
			
			CClotBody npc = view_as<CClotBody>(target);
			if(!npc.IsOnGround())
			{
				damage *= 1.5; //if the enemy is in the air, then we will do 50% more damage. This will apply to any surrounding targets too beacuse im lazy.
			}

			SpawnSmallExplosion(VicLoc);
			//Reuse terroriser stuff for now.
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					EmitSoundToAll(IRENE_EXPLOSION_1, target, _, 85, _, 0.5);
				}
				case 2:
				{
					EmitSoundToAll(IRENE_EXPLOSION_2, target, _, 85, _, 0.5);
				}
			}

			//Cause a bunch of effects on the targeted enemy.

			int color[4];
			color[0] = 255;
			color[1] = 255;
			color[2] = 255;
			color[3] = 255;
			float amp = 0.3;
			float life = 0.1;			
			float GunPos[3];
			float GunAng[3];
			GetAttachment(client, "effect_hand_R", GunPos, GunAng);
			TE_Particle("wrenchmotron_teleport_glow_big", GunPos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
			TE_SetupBeamPoints(GunPos, VicLoc, LaserSprite, 0, 0, 0, life, 1.0, 1.2, 1, amp, color, 0);
			TE_SendToAll();

			spawnRing_Vectors(VicLoc, 0.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 255, 255, 200, 1, 0.25, 12.0, 6.1, 1, IRENE_JUDGEMENT_EXPLOSION_RANGE);	
			Explode_Logic_Custom(damage, client, TemomaryGun, TemomaryGun, VicLoc, IRENE_JUDGEMENT_EXPLOSION_RANGE,_,_,false);
		}
		else
		{
			//Do nothing. Just look into random directions?
		}
	}
}

public void Npc_Irene_Launch(int iNPC)
{
	CClotBody npc = view_as<CClotBody>(iNPC);
	//Do their fly logic.

	if(b_IreneNpcWasShotUp[iNPC])
	{
		float VicLoc[3];
		VicLoc = WorldSpaceCenter(iNPC);
		VicLoc[2] += 250.0; //Jump up.
		PluginBot_Jump(iNPC, VicLoc);
	}
	b_IreneNpcWasShotUp[iNPC] = false;
	
	bool raidboss_active = false;
	float time_stay_In_sky;
	if(IsValidEntity(EntRefToEntIndex(RaidBossActive)))
	{
		raidboss_active = true;
	}
	if (b_thisNpcIsABoss[iNPC] || raidboss_active)
	{
		time_stay_In_sky = 0.55;
	}
	else
	{
		time_stay_In_sky = 1.55;
	}

	if(GetGameTime() > f_TargetAirtime[iNPC])
	{
		//We are Done, kill think.
		SDKUnhook(iNPC, SDKHook_Think, Npc_Irene_Launch);
	}	
	else if(GetGameTime() + time_stay_In_sky > f_TargetAirtime[iNPC])
	{
		//After 0.5 seconds they stop accending to heaven, we also reset their velocity ontop of resetting their gravtiy
		npc.SetVelocity({ 0.0, 0.0, 0.0 });
	}
}