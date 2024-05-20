#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2attributes>

#define VERSION "1.0"

public Plugin myinfo =
{
	name = "Wrangler Resistance Modifier",
	author = "brokenphilip",
	description = "Allows you to modify the resistance of the Wrangler's shield on the fly",
	version = VERSION,
	url = "https://steamcommunity.com/id/brokenphilip"
};

Handle cvarDamage;

public OnPluginStart()
{
	cvarDamage = CreateConVar("sm_wrangler_dmg_modifier", "0.33", "The % of damage a shielded sentry takes (ie. 0.33 (default) = 66% resistance)", FCVAR_NONE, true, 0.0);

	AutoExecConfig(true, "wrangler_res_mod");

	int ent = -1;

	// Hook already existing sentries
	while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
		if (IsValidEntity(ent))
			SDKHook(ent, SDKHook_OnTakeDamage, OnSentryTakeDamage);
}

public Action OnSentryTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	int shieldLevel = GetEntProp(victim, Prop_Send, "m_nShieldLevel");
	bool hasSapper = view_as<bool>(GetEntProp(victim, Prop_Send, "m_bHasSapper"));
	bool isPlasmaDisabled = view_as<bool>(GetEntProp(victim, Prop_Send, "m_bPlasmaDisable"));
		
	// Wrangler shield is active if the following conditions are met (from tf_obj_sentrygun.cpp)
	if (shieldLevel > 0 && !hasSapper && !isPlasmaDisabled) 
	{
		if (IsValidEntity(weapon))
		{
			int index = GetItemDefIndexSafe(weapon);
			Address adrPierceStat = TF2Attrib_GetByName(weapon, "mod_pierce_resists_absorbs");
				
			// This weapon has a resistance piercing stat, so it will be skipped
			// NOTE: does not account for static attributes!
			if (adrPierceStat != Address_Null) 
			{
				float value = TF2Attrib_GetValue(adrPierceStat);
				if (value == 1.0) return Plugin_Continue;
			}

			// The Enforcer pierces resistances by default, so it will be skipped
			// If the address is NOT null, that means the resistance stat is on the weapon, but not set to 1, ie. won't pierce resistances
			if (index == 460 && adrPierceStat == Address_Null) return Plugin_Continue;
		}

		damage = (damage / 0.33) * GetConVarFloat(cvarDamage);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public OnEntityCreated(entity, const char[] classname)
{    
	if (StrEqual(classname, "obj_sentrygun", false)) SDKHook(entity, SDKHook_OnTakeDamage, OnSentryTakeDamage);
}

stock int GetItemDefIndexSafe(entity)
{
	return HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") ? GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") : -1;
}
