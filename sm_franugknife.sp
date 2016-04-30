#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>

#define MAX_KNIVES 50 //Not sure how many knives will eventually be in the game until its death.

enum KnifeList{
	String:Name[64],
	KnifeID
};

ArrayList KnivesArray;
char path_knives[PLATFORM_MAX_PATH];
knives[MAX_KNIVES][KnifeList];
int knifeCount = 0;


public Plugin:myinfo =
{
	name = "SM CS:GO Franug Knives",
	author = "Franc1sco franug",
	description = "",
	version = "1.2",
	url = "http://steamcommunity.com/id/franug"
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
	KnivesArray = new ArrayList(64);
	loadKnives();
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
	loadKnifeMenu(clientId, -1);
	return Plugin_Handled;
}

public void loadKnifeMenu(int clientId, int menuPosition)
{
	new Handle:menu = CreateMenu(DIDMenuHandler_h);
	SetMenuTitle(menu, "Choose you knife");
	
	char item[4];
	char test[4];
	for (int i = 1; i < knifeCount; ++i) {
		Format(item, 4, "%i", i);
		IntToString(knives[i][KnifeID], test, 4);
		AddMenuItem(menu, test, knives[i][Name], knife[clientId] == knives[i][KnifeID] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitButton(menu, true);
	
	if(menuPosition == -1){
		DisplayMenu(menu, clientId, 0);
	} else DisplayMenuAtItem(menu, clientId, menuPosition, 0);
	
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
		
		loadKnifeMenu(client, GetMenuSelectionPosition());
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

public void loadKnives()
{
	BuildPath(Path_SM, path_knives, sizeof(path_knives), "configs/csgo_knives.cfg");
	decl Handle:kv;
	kv = CreateKeyValues("Knives");
	knifeCount = 1;
	ClearArray(KnivesArray);
	FileToKeyValues(kv, path_knives);
	if (!KvGotoFirstSubKey(kv)) CloseHandle(kv);
	
	do {
		KvGetSectionName(kv, knives[knifeCount][Name], 64);
		knives[knifeCount][KnifeID] = KvGetNum(kv, "KnifeID", 0);
		PushArrayString(KnivesArray, knives[knifeCount][Name]);
		knifeCount++;
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
	for (int i=knifeCount; i<MAX_KNIVES; ++i) {
		knives[i][Name] = 0;
	}
}
