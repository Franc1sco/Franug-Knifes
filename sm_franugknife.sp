#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define MAX_KNIVES 50 //Not sure how many knives will eventually be in the game until its death.

enum KnifeList{
	String:Name[64],
	KnifeID
};

ArrayList KnivesArray;
char path_knives[PLATFORM_MAX_PATH];
knives[MAX_KNIVES][KnifeList];
int knifeCount = 0;


public Plugin myinfo = {
	name = "SM CS:GO Franug Knives",
	author = "Franc1sco franug",
	description = "",
	version = "1.5",
	url = "http://steamcommunity.com/id/franug"
};

int knife[MAXPLAYERS+1];

Handle c_knife;

public void OnPluginStart() {
	c_knife = RegClientCookie("hknife", "", CookieAccess_Private);
	
	RegConsoleCmd("sm_knife", DID);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
	}
	KnivesArray = new ArrayList(64);
	loadKnives();
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquip, OnPostWeaponEquip);
}

public Action OnPostWeaponEquip(int client, int iWeapon) {
	char Classname[64];
	if(!GetEdictClassname(iWeapon, Classname, 64) || StrContains(Classname, "weapon_knife", false) != 0)
	{
		return;
	}
	
	if(knife[client] > 0)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", knife[client]);
	}

}

public Action DID(int clientId, int args) {
	loadKnifeMenu(clientId, -1);
	return Plugin_Handled;
}

public void loadKnifeMenu(int clientId, int menuPosition) {
	Menu menu = CreateMenu(DIDMenuHandler_h);
	menu.SetTitle("Choose you knife");
	
	char item[4];
	for (int i = 1; i < knifeCount; ++i) {
		Format(item, 4, "%i", knives[i][KnifeID]);
		menu.AddItem(item, knives[i][Name], knife[clientId] == knives[i][KnifeID] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitButton(menu, true);
	
	if(menuPosition == -1){
		menu.Display(clientId, 0);
	} else menu.DisplayAt(clientId, menuPosition, 0);
	
}

public int DIDMenuHandler_h(Menu menu, MenuAction action, int client, int itemNum) {
	switch(action){
		case MenuAction_Select:{
			char info[32];
		
			menu.GetItem(itemNum, info, sizeof(info));

			knife[client] = StringToInt(info);
		
			char cookie[8];
			IntToString(knife[client], cookie, 8);
			SetClientCookie(client, c_knife, cookie);
		
			DarKnife(client);
		
			loadKnifeMenu(client, GetMenuSelectionPosition());
		}
		case MenuAction_End: delete menu;
	}
}


public void OnClientCookiesCached(int client) {
	char value[16];
	GetClientCookie(client, c_knife, value, sizeof(value));
	if(strlen(value) > 0) knife[client] = StringToInt(value);
	else knife[client] = 0;
}

public void DarKnife(int client) {
	if(!IsPlayerAlive(client)) return;
	
	int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (iWeapon != -1) {
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
		
		GivePlayerItem(client, "weapon_knife");
	}
}

public void loadKnives() {
	BuildPath(Path_SM, path_knives, sizeof(path_knives), "configs/csgo_knives.cfg");
	KeyValues kv = new KeyValues("Knives");
	knifeCount = 1;
	ClearArray(KnivesArray);
	
	kv.ImportFromFile(path_knives);
	
	if (!kv.GotoFirstSubKey()){
		SetFailState("Knives Config not found: %s. Please install the cfg file in the addons/sourcemod/configs folder", path_knives);
		delete kv;
	}
	do {
		kv.GetSectionName(knives[knifeCount][Name], 64);
		knives[knifeCount][KnifeID] = kv.GetNum("KnifeID", 0);
		PushArrayString(KnivesArray, knives[knifeCount][Name]);
		knifeCount++;
	} while (kv.GotoNextKey());
	
	delete kv;
	for (int i=knifeCount; i<MAX_KNIVES; ++i) {
		knives[i][Name] = 0;
	}
}
