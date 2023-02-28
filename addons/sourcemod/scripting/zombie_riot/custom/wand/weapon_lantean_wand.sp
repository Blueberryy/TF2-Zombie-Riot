#pragma semicolon 1
#pragma newdecls required

static int lantean_Wand_Drone_Count[MAXPLAYERS+1]={0, ...};
static float fl_hud_timer[MAXPLAYERS+1]={0.0, ...};
static float fl_overcharge[MAXENTITIES]={0.0, ...};

static float fl_lantean_Wand_Drone_Life[MAXENTITIES] = { 0.0, ... };

static int i_drone_targets_penetrated[MAXENTITIES] = { 0, ... };

static char particle_type[MAXPLAYERS + 1][200];

static bool bl_penetrate[MAXPLAYERS + 1] = { false, ... };


static float ability_cooldown[MAXPLAYERS+1]={0.0, ...};

#define DRONE_MAX_PENETRATION 5	//how many npc's the drone will penetrate before commiting die


public void Weapon_lantean_Wand_ClearAll()
{
	Zero(ability_cooldown);
	Zero(fl_hud_timer);
	Zero(fl_lantean_Wand_Drone_Life);
}

#define LANTEAN_WAND_SHOT_1 	"weapons/physcannon/energy_sing_flyby1.wav"
#define LANTEAN_WAND_SHOT_2 	"weapons/physcannon/energy_sing_flyby2.wav"

void Weapon_lantean_Wand_Map_Precache()
{
	PrecacheSound(LANTEAN_WAND_SHOT_1);
	PrecacheSound(LANTEAN_WAND_SHOT_2);
	
}
public void Weapon_lantean_Wand_m1(int client, int weapon, bool crit, int slot)
{
	particle_type[client]="flaregun_energyfield_red";
	bl_penetrate[client] = false;
	Weapon_lantean_Wand(client, weapon);
}

public void Weapon_lantean_Wand_pap_m1(int client, int weapon, bool crit, int slot)
{
	particle_type[client]="flaregun_energyfield_blue";
	bl_penetrate[client] = true;
	Weapon_lantean_Wand(client, weapon);
}

public void Weapon_lantean_Wand_m2(int client, int weapon, bool crit, int slot)
{
	int mana_cost;
	Address address = TF2Attrib_GetByDefIndex(weapon, 733);
	if(address != Address_Null)
		mana_cost = RoundToCeil(TF2Attrib_GetValue(address));
	
	mana_cost *= 7;
	if(mana_cost <= Current_Mana[client])
	{
		if (Ability_Check_Cooldown(client, slot) < 0.0)
		{
			Ability_Apply_Cooldown(client, slot, 30.0);
	
			particle_type[client]="scorchshot_trail_crit_red";
			bl_penetrate[client] = false;
			Current_Mana[client] -= mana_cost / 5;
			for(int i=1 ; i<=5 ; i++)
			{
				Weapon_lantean_Wand(client, weapon);
			}
		}
		else
		{
			float Ability_CD = Ability_Check_Cooldown(client, slot);
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
		}
	}
	else
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
	}
}

public void Weapon_lantean_Wand_pap_m2(int client, int weapon, bool crit, int slot)
{
	int mana_cost;
	Address address = TF2Attrib_GetByDefIndex(weapon, 733);
	if(address != Address_Null)
		mana_cost = RoundToCeil(TF2Attrib_GetValue(address));
	
	mana_cost *= 12;
	if(mana_cost <= Current_Mana[client])
	{
		if (Ability_Check_Cooldown(client, slot) < 0.0)
		{
			Ability_Apply_Cooldown(client, slot, 30.0);
	
			particle_type[client]="scorchshot_trail_crit_blue";
			bl_penetrate[client] = true;
			Current_Mana[client] -= mana_cost / 10;
			for(int i=1 ; i<=10 ; i++)
			{
				Weapon_lantean_Wand(client, weapon);
			}
		}
		else
		{
			float Ability_CD = Ability_Check_Cooldown(client, slot);
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
		}
	}
	else
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
	}
}

static void Weapon_lantean_Wand(int client, int weapon)
{
	int mana_cost;
	Address address = TF2Attrib_GetByDefIndex(weapon, 733);
	if(address != Address_Null)
		mana_cost = RoundToCeil(TF2Attrib_GetValue(address));

	if(mana_cost <= Current_Mana[client])
	{
		float damage = 65.0;
		address = TF2Attrib_GetByDefIndex(weapon, 410);
		if(address != Address_Null)
			damage *= TF2Attrib_GetValue(address);
		
		Mana_Regen_Delay[client] = GetGameTime() + 1.0;
		Mana_Hud_Delay[client] = 0.0;
		
		Current_Mana[client] -= mana_cost;
		
		delay_hud[client] = 0.0;
			
		float speed = 1100.0;
		address = TF2Attrib_GetByDefIndex(weapon, 103);
		if(address != Address_Null)
			speed *= TF2Attrib_GetValue(address);
	
		address = TF2Attrib_GetByDefIndex(weapon, 104);
		if(address != Address_Null)
			speed *= TF2Attrib_GetValue(address);
	
		address = TF2Attrib_GetByDefIndex(weapon, 475);
		if(address != Address_Null)
			speed *= TF2Attrib_GetValue(address);
	
	
		float time = 500.0/speed;
		address = TF2Attrib_GetByDefIndex(weapon, 101);
		if(address != Address_Null)
			time *= TF2Attrib_GetValue(address);
	
		address = TF2Attrib_GetByDefIndex(weapon, 102);
		if(address != Address_Null)
			time *= TF2Attrib_GetValue(address);
			
			
		int projectile = Wand_Projectile_Spawn(client, speed, 100.0, damage, WEAPON_LANTEAN, weapon, particle_type[client]);
		
		lantean_Wand_Drone_Count[client]++;
		fl_lantean_Wand_Drone_Life[projectile] = GetGameTime()+time;
		i_drone_targets_penetrated[projectile] = 0;
	
		Handle swingTrace;
		float vecSwingForward[3] , vec[3];
		DoSwingTrace_Custom(swingTrace, client, vecSwingForward, 9999.9, false, 45.0, false); //infinite range, and (doesn't)ignore walls!
				
		TR_GetEndPosition(vec, swingTrace);
		delete swingTrace;
		
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				EmitSoundToAll(LANTEAN_WAND_SHOT_1, client, _, 65, _, 0.35, 160);
			}
			case 2:
			{
				EmitSoundToAll(LANTEAN_WAND_SHOT_2, client, _, 65, _, 0.35, 160);
			}
		}
		
		Lantean_HomingProjectile_TurnToTarget(vec, projectile);
		
		DataPack pack;
		CreateDataTimer(0.1, Lantean_PerfectHomingShot, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		pack.WriteCell(EntIndexToEntRef(projectile)); //projectile
		pack.WriteCell(EntIndexToEntRef(client));		//so rather than a victim, we send the client to use for trace's

	}
	else
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
	}
}

public void lantean_Wand_Touch(int entity, int target)
{
	int owner = EntRefToEntIndex(i_WandOwner[entity]);
	int particle = EntRefToEntIndex(i_WandParticle[entity]);
	if (target > 0 && IsValidClient(owner))	
	{
		//Code to do damage position and ragdolls
		static float angles[3];
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		float vecForward[3];
		GetAngleVectors(angles, vecForward, NULL_VECTOR, NULL_VECTOR);
		static float Entity_Position[3];
		Entity_Position = WorldSpaceCenter(target);

		int weapon = EntRefToEntIndex(i_WandWeapon[entity]);
		
		i_drone_targets_penetrated[entity]++;
		
		SDKHooks_TakeDamage(target, entity, owner, f_WandDamage[entity]/i_drone_targets_penetrated[entity], DMG_PLASMA, weapon, CalculateDamageForce(vecForward, 10000.0), Entity_Position);	// 2048 is DMG_NOGIB?
	
		
		if(IsValidEntity(particle) && (!bl_penetrate[owner] || i_drone_targets_penetrated[entity] >= DRONE_MAX_PENETRATION))
		{
			RemoveEntity(particle);
		}
		switch(GetRandomInt(1,5)) 
		{
			case 1:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_FLESH_1, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 2:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_FLESH_2, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 3:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_FLESH_3, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 4:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_FLESH_4, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 5:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_FLESH_5, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
	   	}
	   	if(i_drone_targets_penetrated[entity] >= DRONE_MAX_PENETRATION || !bl_penetrate[owner])
	   	{
	   		RemoveEntity(entity);
	   		lantean_Wand_Drone_Count[owner]--;
	   	}
	}
	else if(target == 0)
	{
		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		switch(GetRandomInt(1,4)) 
		{
			case 1:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_CONCRETE_1, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 2:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_CONCRETE_2, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 3:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_CONCRETE_3, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 4:EmitSoundToAll(SOUND_AUTOAIM_IMPACT_CONCRETE_4, entity, SNDCHAN_STATIC, 80, _, 0.9);
		}
		RemoveEntity(entity);
		lantean_Wand_Drone_Count[owner]--;
	}
}

public Action Lantean_PerfectHomingShot(Handle timer, DataPack pack)
{
	pack.Reset();
	int Projectile = EntRefToEntIndex(pack.ReadCell());
	int Client = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(Client))
	{
		return Plugin_Handled;
	}
	int weapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(Projectile) && IsPlayerAlive(Client) && fl_lantean_Wand_Drone_Life[Projectile] > GetGameTime() && i_CustomWeaponEquipLogic[weapon]==WEAPON_LANTEAN)	//if drone is beyond its lifetime, it loses homing and crashes and burns 
	{
		if(fl_overcharge[Projectile] < GetGameTime())
		{
			if(lantean_Wand_Drone_Count[Client]>10)
			{
				fl_overcharge[Projectile] = GetGameTime() + lantean_Wand_Drone_Count[Client] / 10.0 - 1.0;	//if drones are over 10, the homing update becomes delayed making them harder to control/hopefuly less resource intensive
			}
			Handle swingTrace;
			float vecSwingForward[3] , vec[3];
			DoSwingTrace_Custom(swingTrace, Client, vecSwingForward, 9999.9, false, 45.0, false); //infinite range, and (doesn't)ignore walls!
						
			TR_GetEndPosition(vec, swingTrace);
			delete swingTrace;
			Lantean_HomingProjectile_TurnToTarget(vec, Projectile);
		}
		if(fl_hud_timer[Client] < GetGameTime())
		{
			Lantean_Wand_Hud(Client);
			fl_hud_timer[Client] = GetGameTime() + 0.5;
		}
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

static void Lantean_Wand_Hud(int client)
{
	if(lantean_Wand_Drone_Count[client]<11)
	{
		PrintHintText(client,"Drone Count: %i", lantean_Wand_Drone_Count[client]);
	}
	else
	{
		PrintHintText(client,"Drone Overcharge!: %i", lantean_Wand_Drone_Count[client]);
	}
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
}
static void Lantean_HomingProjectile_TurnToTarget(float Vec[3], int Projectile)
{
	float flTargetPos[3];
	flTargetPos = Vec;	//Well this works ig
	float flRocketPos[3];
	GetEntPropVector(Projectile, Prop_Data, "m_vecAbsOrigin", flRocketPos);

	float flInitialVelocity[3];
	GetEntPropVector(Projectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
	float flSpeedInit = GetVectorLength(flInitialVelocity);
	
	
	float flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	float flAng[3];
	GetVectorAngles(flNewVec, flAng);
	
	ScaleVector(flNewVec, flSpeedInit);
	TeleportEntity(Projectile, NULL_VECTOR, flAng, flNewVec, true);
}