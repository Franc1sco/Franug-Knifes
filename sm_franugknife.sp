#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "SM Knifes",
	author = "Franc1sco franug",
	description = "",
	version = "1.1",
	url = "http://www.zeuszombie.com"
};

new knife[MAXPLAYERS+1];

new Handle:c_knife;

public OnPluginStart() 
{
	c_knife = RegClientCookie("hknife", "", CookieAccess_Private);
	
	RegConsoleCmd("sm_knife", DID);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnPostWeaponEquip);
}

public Action:OnPostWeaponEquip(client, iWeapon)
{
	decl String:Classname[64];
	if(!GetEdictClassname(iWeapon, Classname, 64) || StrContains(Classname, "weapon_knife", false) != 0)
	{
		return;
	}
	
	if(knife[client] > 0)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", knife[client]);
	}

}

public Action:DID(clientId, args) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler_h);
	SetMenuTitle(menu, "Choose you knife");
	
	AddMenuItem(menu, "0", "Default knife");
	AddMenuItem(menu, "516", "Push");
	AddMenuItem(menu, "509", "Huntsman");
	AddMenuItem(menu, "507", "Karambit");
	AddMenuItem(menu, "506", "Gut");
	AddMenuItem(menu, "505", "Flip");
	AddMenuItem(menu, "508", "M9 Bayonet");
	AddMenuItem(menu, "500", "Bayonet");
	AddMenuItem(menu, "515", "Butterfly");
	AddMenuItem(menu, "512", "Falchion");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 0);
	
	return Plugin_Handled;
}

public DIDMenuHandler_h(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));

		knife[client] = StringToInt(info);
		
		new String:cookie[8];
		IntToString(knife[client], cookie, 8);
		SetClientCookie(client, c_knife, cookie);
		
		DarKnife(client);
		
		DID(client, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public OnClientCookiesCached(client)
{
	new String:value[16];
	GetClientCookie(client, c_knife, value, sizeof(value));
	if(strlen(value) > 0) knife[client] = StringToInt(value);
	else knife[client] = 0;
}

/* public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast) 
{
	decl String:sWeapon[64];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	if (StrEqual(sWeapon, "knife", false)) 
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if (iWeapon != -1) 
		{
			if(ZR_IsClientZombie(client)) 
			{
				if(zrknife[client] < 1)
				{
					new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
					if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 507);
				}
				else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", zrknife[client]);
				
			}
			else
			{
				if(knife[client] < 1)
				{
					new weaponindex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
					if (weaponindex == 42 || weaponindex == 59) SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 509);
				}
				else SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", knife[client]);
				
			}
			//PrintToChatAll("fijado %s", manos[client]);
		}
	}

	return Plugin_Continue;
}  */

DarKnife(client)
{
	if(!IsPlayerAlive(client)) return;
	
	new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (iWeapon != -1) 
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
		
		GivePlayerItem(client, "weapon_knife");
	}
}
	