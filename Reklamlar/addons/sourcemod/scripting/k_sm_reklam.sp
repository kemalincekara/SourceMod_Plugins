//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <adminmenu>
#include <k_sm_admins>

#define REKLAMACIK GetConVarBool(reklam_acik)

new Handle:undo = INVALID_HANDLE;
new Handle:g_SQL = INVALID_HANDLE;
new Handle:TopM = INVALID_HANDLE;
new Handle:g_hMenu = INVALID_HANDLE;
new Handle:pack = INVALID_HANDLE;
new Handle:pack2 = INVALID_HANDLE;
new bool:InChatName[MAXPLAYERS+1];

ConVar reklam_acik;


public Plugin:myinfo = 
{
	name = "Reklamlar",
	author = "ℂ⋆İSTİKLAL|TERMINATOR",
	description = "Reklamlar",
	version = "1.5",
	url = "http://www.kemalincekara.tk"
}

public OnPluginStart() 
{
	reklam_acik = CreateConVar("sm_reklam_acik", "1", "Reklamlar Acik = 1, Kapali = 1", FCVAR_NOTIFY|FCVAR_REPLICATED);
	AutoExecConfig(true, "k_sm_reklam");
	AddCommandListener(Say, "say"); 
	AddCommandListener(Say, "say_team");
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	OnAdminMenuReady(GetAdminTopMenu());
	LoadTranslations("k_sm_reklam.phrases");
	InitDB();
	
	RegConsoleCmd("sm_reklam", Command_Reklam, "Reklam Yonetimi");
	HookConVarChange(reklam_acik, Reklam_Acik_Changed);
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("k_sm_admins"))
		SetFailState("[SM REKLAMLAR] k_sm_admins.smx PLUGIN GEREKLI");
}

public void Reklam_Acik_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(StringToInt(newValue) == 1)
		ReklamGoster();
	else
		CPrintToChatAll("%t", "ReklamGizlenecekBilgi");
}

public OnMapStart()
{
	GlobalMenu();
}

public OnMapEnd()
{
	ClearUndo();
}

public Action:RoundStart(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	if(REKLAMACIK)
		ReklamGoster();
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(InChatName[iClient])
		InChatName[iClient] = false;
	ClearUndo();
	return Plugin_Continue;
}

public void ReklamGoster()
{
	decl String:query[256], String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	Format(query, sizeof(query), "SELECT * FROM reklamlar WHERE mapname = '%s'", mapname);
	SQL_TQuery(g_SQL, SQL_PopulateMap, query, _, DBPrio_High);
}

public SQL_PopulateMap(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Query Error: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
	new Float:pos[3];
	decl String:sModel[128];
	while (SQL_FetchRow(hndl))
	{
		pos[0] = SQL_FetchFloat(hndl, 1);
		pos[1] = SQL_FetchFloat(hndl, 2);
		pos[2] = SQL_FetchFloat(hndl, 3);
		SQL_FetchString(hndl, 4, sModel, 128);
		Createreklamlar(pos, sModel, false);
	}
}

InitDB()
{
	if(SQL_CheckConfig("reklamlar"))
	{
		decl String:error[255];
		g_SQL = SQL_Connect("reklamlar", false, error, sizeof(error));
		if (g_SQL != INVALID_HANDLE)
		{
			CreateTable();
		}
		else
		{
			SetFailState("Could not connect to database, reason: %s", error);
		}
	}
	else
	{
		SetFailState("Could not connect to database, reason: no config entry found for 'reklamlar' in databases.cfg");
	}
}

CreateTable() 
{
	if(g_SQL == INVALID_HANDLE)
	{
		SetFailState("Could not create the table, reason: Unable to connect the database");
		return;
	}
	decl String:query[256];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS reklamlar (mapname VARCHAR(64),first REAL, second REAL, third REAL, models_vmt VARCHAR(128), reklam_name VARCHAR(128))");
	SQL_TQuery(g_SQL, CallBackCreateTable, query, _, DBPrio_High);
}

public CallBackCreateTable(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Could not create the table, reason: %s", error);
		return;
	}
}

ClearAllBD(client)
{
	decl String:query[256], String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	Format(query, sizeof(query), "DELETE FROM reklamlar WHERE mapname = '%s'", mapname);
	SQL_TQuery(g_SQL, SQL_DoNothing, query, _, DBPrio_High);
	CPrintToChat(client, "%t", "Delete_All_On_Map");
}

public SQL_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query errors: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
}

Save(client)
{
	if (IsStackEmpty(undo))
	{
		CPrintToChat(client, "%t", "Round_Reload");
		return;
	}
	new index;
	new Float:position[3];
	decl String:sModel[128], String:reklam_name[128], String:mapname[32], String:query[256];
	ResetPack(pack);
	ResetPack(pack2); 
	ReadPackString(pack, sModel, 128);
	ReadPackString(pack2, reklam_name, 128);
	GetCurrentMap(mapname, sizeof(mapname));
	while (!IsStackEmpty(undo))
	{
		PopStackCell(undo, index);
		if (IsValidEdict(index))
		{
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", position);
			Format(query, sizeof(query), "INSERT INTO reklamlar (mapname, first, second, third, models_vmt, reklam_name) VALUES (\"%s\", \"%f\", \"%f\", \"%f\", \"%s\", \"%s\");", mapname, position[0], position[1], position[2], sModel, reklam_name);
			SQL_TQuery(g_SQL, SQL_DoNothing, query, _, DBPrio_High);
		}
	}
	CPrintToChat(client, "%t", "Save");
}

Undo(client)
{
	if (IsStackEmpty(undo))
	{
		CPrintToChat(client, "%t", "Round_Reload");
		return;
	}
	new index;
	while (!IsStackEmpty(undo))
	{
		PopStackCell(undo, index);
		if (IsValidEdict(index))
		{
			AcceptEntityInput(index, "Kill");
		}
	}
	CPrintToChat(client, "%t", "Delete");
}

ClearUndo()
{
	if (undo == INVALID_HANDLE)
	{
		undo = CreateStack(1);
	}
	else
	{
		while(!IsStackEmpty(undo))
		{
			PopStack(undo);
		}
	}
}

public OnAdminMenuReady(Handle:topme)
{
	if (topme == INVALID_HANDLE || topme == TopM) return;
	TopM = topme;
	new TopMenuObject:mn = AddToTopMenu(topme, "sm_reklamlar", TopMenuObject_Category, TopMenuCallBack, INVALID_TOPMENUOBJECT, _, ADMFLAG_ROOT);
	AddToTopMenu(topme, "sm_reklamlar_create", TopMenuObject_Item, MenuCallBack1, mn, _, ADMFLAG_ROOT);
	AddToTopMenu(topme, "sm_reklamlar_reset", TopMenuObject_Item, MenuCallBack2, mn, _, ADMFLAG_ROOT);
	AddToTopMenu(topme, "sm_reklamlar_resetmap", TopMenuObject_Item, MenuCallBack3, mn, _, ADMFLAG_ROOT);
	AddToTopMenu(topme, "sm_reklamlar_acik", TopMenuObject_Item, MenuCallBack4, mn, _, ADMFLAG_ROOT);
}

public TopMenuCallBack(Handle:topme, TopMenuAction:action, TopMenuObject:object_id, iClient, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", "MainMenu1");
			FormatEx(buffer, maxlength, sText);
		}
		case TopMenuAction_DisplayTitle:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", "MainMenu1");
			FormatEx(buffer, maxlength, sText);
		}
	}
}

public MenuCallBack1(Handle:topme, TopMenuAction:action, TopMenuObject:object_id, iClient, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", "MainMenu2");
			FormatEx(buffer, maxlength, sText);
		}
		case TopMenuAction_SelectOption: DisplayMenu(g_hMenu, iClient, MENU_TIME_FOREVER);
	}
}

public MenuCallBack2(Handle:topme, TopMenuAction:action, TopMenuObject:object_id, iClient, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", "MainMenu3");
			FormatEx(buffer, maxlength, sText);
		}
		case TopMenuAction_SelectOption: SelectClearreklamlar(iClient);
	}
}

public MenuCallBack3(Handle:topme, TopMenuAction:action, TopMenuObject:object_id, iClient, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", "MainMenu4");
			FormatEx(buffer, maxlength, sText);
		}
		case TopMenuAction_SelectOption: SilmeOnayMenuAc(iClient);
	}
}
public MenuCallBack4(Handle:topme, TopMenuAction:action, TopMenuObject:object_id, iClient, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			decl String:sText[36];
			Format(sText, sizeof(sText), "%t", !REKLAMACIK ? "ReklamlarEtkinlestir" : "ReklamlarDevredisi");
			FormatEx(buffer, maxlength, sText);
		}
		case TopMenuAction_SelectOption:
		{
			if(!REKLAMACIK)
				reklam_acik.SetBool(true, true, true);
			else
				reklam_acik.SetBool(false, true, true);
		}
	}
}

public SelectClearreklamlar(client)
{
	decl String:query[256], String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	FormatEx(query, sizeof(query), "SELECT * FROM reklamlar WHERE mapname = '%s'", mapname);
	SQL_TQuery(g_SQL, ShowSelectClearMenu, query, client);
	return true;
}

public ShowSelectClearMenu(Handle:owner, Handle:hndl, const String:error[], any:client) 
{ 
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Query Error: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
	
	new count = SQL_GetRowCount(hndl);
	if (count == 0)
	{
		CPrintToChat(client, "%t", "No_Point");
		return;
	}
	
	new Handle:menu = CreateMenu(ShowSelectClearMenu_Handler);
	SetMenuTitle(menu, "%t", "menu_title");
	new Float:pos[3];
	decl String:display[128], String:sBuffer[128], String:reklam_name[128], String:sModel[128];
	while (SQL_FetchRow(hndl))
	{
		pos[0] = SQL_FetchFloat(hndl, 1);
		pos[1] = SQL_FetchFloat(hndl, 2);
		pos[2] = SQL_FetchFloat(hndl, 3);
		SQL_FetchString(hndl, 4, sModel, 128);
		SQL_FetchString(hndl, 5, reklam_name, 128);
		FormatEx(display, sizeof(display), "%s", reklam_name);
		FormatEx(sBuffer, sizeof(sBuffer), "%f:%f:%f:%s:%s", pos[0], pos[1], pos[2], sModel, reklam_name);
		AddMenuItem(menu, sBuffer, display);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public ShowSelectClearMenu_Handler(Handle:menu, MenuAction:action, client, Item)
{
	if(action == MenuAction_Select)
	{
		new Float:pos[3];
		decl String:sInfo[PLATFORM_MAX_PATH], String:sBuffers[5][64], String:reklam_name[128], String:sModel[128], String:sBuffer[128];
		GetMenuItem(menu, Item, sInfo, sizeof(sInfo));
		ExplodeString(sInfo, ":", sBuffers, 5, 64);
		pos[0] = StringToFloat(sBuffers[0]);
		pos[1] = StringToFloat(sBuffers[1]);
		pos[2] = StringToFloat(sBuffers[2]);
		strcopy(sModel, sizeof(sModel), sBuffers[3]);
		strcopy(reklam_name, sizeof(reklam_name), sBuffers[4]);
		FormatEx(sBuffer, sizeof(sBuffer), "%f:%f:%f:%s:%s", pos[0], pos[1], pos[2], sModel, reklam_name);
		decl Handle:menu777;
		decl String:Delete_Text[36], String:Teleport_Text[36];
		menu777 = CreateMenu(MainMenu777);
		SetMenuExitBackButton(menu777, true);
		Format(Teleport_Text, sizeof(Teleport_Text), "%t", "MenuItem2_1");
		Format(Delete_Text, sizeof(Delete_Text), "%t", "MenuItem2_2");
		SetMenuTitle(menu777, "%t", "menu_title2", reklam_name, pos[0], pos[1], pos[2], sModel);
		AddMenuItem(menu777, sBuffer, Teleport_Text);
		AddMenuItem(menu777, sBuffer, Delete_Text);
		DisplayMenu(menu777, client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(Item == MenuCancel_ExitBack)
			Command_Reklam(client, 0);
	}
}

public MainMenu777(Handle:menu, MenuAction:action, client, Item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(Item)
			{
				case 0:
				{
					if(IsPlayerAlive(client))
					{
						new Float:pos[3];
						decl String:sInfo[PLATFORM_MAX_PATH], String:sBuffers[3][64];
						GetMenuItem(menu, Item, sInfo, sizeof(sInfo));
						ExplodeString(sInfo, ":", sBuffers, 3, 64);
						pos[0] = StringToFloat(sBuffers[0]);
						pos[1] = StringToFloat(sBuffers[1]);
						pos[2] = StringToFloat(sBuffers[2]);
						TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
						CPrintToChat(client, "%t", "Success_Teleport");
					}
					else CPrintToChat(client, "%t", "Deny_Teleport");
				}
				case 1:
				{
					new Float:pos[3];
					decl String:query[256], String:sInfo[PLATFORM_MAX_PATH], String:sBuffers[5][64], String:reklam_name[128], String:sModel[128];
					GetMenuItem(menu, Item, sInfo, sizeof(sInfo));
					ExplodeString(sInfo, ":", sBuffers, 5, 64);
					pos[0] = StringToFloat(sBuffers[0]);
					pos[1] = StringToFloat(sBuffers[1]);
					pos[2] = StringToFloat(sBuffers[2]);
					strcopy(sModel, sizeof(sModel), sBuffers[3]);
					strcopy(reklam_name, sizeof(reklam_name), sBuffers[4]);
					Format(query, sizeof(query), "DELETE FROM reklamlar WHERE first = '%f'", pos[0]);
					SQL_TQuery(g_SQL, SQL_DoNothing, query, _, DBPrio_High);
					CPrintToChat(client, "%t", "Success_Delete");
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) SelectClearreklamlar(client);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

reklamlarMenuEnd(iClient)
{
	if (iClient == 0 || (!IsClientInGame(iClient)))
	{
		return;
	}
	decl String:Save_Text[36], String:Cancel_Text[36];
	new Handle:menu = CreateMenu(reklamlarMenuHandler);
	SetMenuTitle(menu, "%t", "ReklamEksen");
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	Format(Save_Text, sizeof(Save_Text), "%t", "MenuItem3_1");
	Format(Cancel_Text, sizeof(Cancel_Text), "%t", "MenuItem3_2");
	AddMenuItem(menu, "+X", "+X");
	AddMenuItem(menu, "-X", "-X");
	AddMenuItem(menu, "+Y", "+Y");
	AddMenuItem(menu, "-Y", "-Y");
	AddMenuItem(menu, "+Z", "+Z");
	AddMenuItem(menu, "-Z", "-Z\n -----------------------------");
	AddMenuItem(menu, "save", Save_Text);
	AddMenuItem(menu, "cancel", Cancel_Text);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

public reklamlarMenuHandler(Handle:menu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(Item)
			{
				case 0, 1, 2, 3, 4, 5:
				{
					// KEMAL
					new index;
					if(!IsStackEmpty(undo) && PopStackCell(undo, index))
					{
						if (IsValidEdict(index))
						{
							new Float:position[3];
							GetEntPropVector(index, Prop_Send, "m_vecOrigin", position);
							switch(Item)
							{
								case 0: position[0] = position[0] + 10;
								case 1: position[0] = position[0] - 10;
								case 2: position[1] = position[1] + 10;
								case 3: position[1] = position[1] - 10;
								case 4: position[2] = position[2] + 10;
								case 5: position[2] = position[2] - 10;
							}
							SetEntPropVector(index, Prop_Send, "m_vecOrigin", position);
							PushStackCell(undo, index);
							reklamlarMenuEnd(iClient);
						}
					}
				}
				case 6:
				{
					InChatName[iClient] = true;
					CPrintToChat(iClient, "%t", "Print_Name_In_Chat");
				}
				case 7:
				{
					Undo(iClient);
					DisplayMenu(g_hMenu, iClient, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayMenu(g_hMenu, iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

GlobalMenu()
{
	new Handle:kv = CreateKeyValues("sm_reklam");
	if (!FileToKeyValues(kv, "addons/sourcemod/configs/k_sm_reklam.cfg")) 
	{
		PrintToServer("Dosya yuklenemedi addons/sourcemod/configs/k_sm_reklam.cfg");
	}
	
	if (g_hMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hMenu);
	}
	
	g_hMenu = CreateMenu(GlobalMenuHandler);
	SetMenuTitle(g_hMenu, "%t", "menu_title3");
	SetMenuExitBackButton(g_hMenu, true);
	if (KvGotoFirstSubKey(kv) == true)
	{
		decl String:ItemName[32], String:model_vmt[128], String:model_vtf[128];
		do
		{
			if (KvGetSectionName(kv, ItemName, 32) == true)
			{
				KvGetString(kv, "name", ItemName, 32);
				KvGetString(kv, "vmt", model_vmt, 128);
				KvGetString(kv, "vtf", model_vtf, 128);
				AddFileToDownloadsTable(model_vmt);
				AddFileToDownloadsTable(model_vtf);
				PrecacheModel(model_vmt);
				AddMenuItem(g_hMenu, model_vmt, ItemName);
			}
		}
		while (KvGotoNextKey(kv, true));
	}
	else
		LogError("addons/sourcemod/configs/k_sm_reklam.cfg hata olustu");

	CloseHandle(kv);
}

public GlobalMenuHandler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	if(action == MenuAction_Select)
	{
		decl String:sModel[128];
		GetMenuItem(g_hMenu, Item, sModel, sizeof(sModel));
		new Float:position[3];
		ClearUndo();
		TraceEye(iClient, position);
		Createreklamlar(position, sModel);
		reklamlarMenuEnd(iClient);
		pack = CreateDataPack(); 
		WritePackString(pack, sModel);
	}
	else if(action == MenuAction_Cancel)
	{
		if(Item == MenuCancel_ExitBack)
			Command_Reklam(iClient, 0);
	}
}

Createreklamlar(Float:position[3],const String:sModel[], bool:pushstack=true)
{
    new sprite = CreateEntityByName("env_sprite");
    if(sprite != -1)
    {
		DispatchKeyValue(sprite, "classname", "env_sprite");
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "scale", "0.5");
		DispatchKeyValue(sprite, "rendermode", "1");
		DispatchKeyValue(sprite, "rendercolor", "255 255 255");
		DispatchKeyValue(sprite, "model", sModel);
		DispatchSpawn(sprite);
		//position[2] = position[2] + 50.0;
		TeleportEntity(sprite, position, NULL_VECTOR, NULL_VECTOR);
		
		if (pushstack)
		{
			PushStackCell(undo, sprite);
		}
	}
}

TraceEye(client, Float:pos[3])
{
	decl Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
	pos[2] = pos[2] + 100;
	return;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

public OnClientConnected(iClient)
{
	InChatName[iClient] = false;
}

public OnClientDisconnect(iClient)
{
	InChatName[iClient] = false;
}

public Action:Say(iClient, const String:command[], args) 
{ 
	if((!iClient || !IsClientInGame(iClient)) && !InChatName[iClient]) return Plugin_Continue; 
	decl String:sText[192]; 
	GetCmdArgString(sText, sizeof(sText)); 
	if(InChatName[iClient]) 
	{
		StripQuotes(sText); 
		TrimString(sText); 
		if (strlen(sText) <= 3)
		{
			CPrintToChat(iClient, "%t", "Check_Size");
			return Plugin_Handled;
		}
		pack2 = CreateDataPack(); 
		WritePackString(pack2, sText);
		Save(iClient);
		InChatName[iClient] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue; 
}


public Action Command_Reklam(int client, int args)
{
	if(!IsAdminValid(client)) return;
	new Handle:menu = CreateMenu(sm_reklam_menu_handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "%t", "MainMenu1");

	AddMenuItem(menu, "reklamolustur", "Reklam Oluştur");
	AddMenuItem(menu, "listedensil", "Listeden Sil");
	AddMenuItem(menu, "tumunusilharitadan", "Tümünü Sil Haritadan");
	if(!REKLAMACIK)
		AddMenuItem(menu, "etkindevredisi", "Reklamları Etkinleştir");
	else
		AddMenuItem(menu, "etkindevredisi", "Reklamları Devredışı Bırak");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	ReplyToCommand(client, "");
}

public sm_reklam_menu_handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is item

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "reklamolustur"))
				DisplayMenu(g_hMenu, param1, MENU_TIME_FOREVER);
			else if (StrEqual(item, "listedensil"))
				SelectClearreklamlar(param1);
			else if (StrEqual(item, "tumunusilharitadan"))
				SilmeOnayMenuAc(param1);
			else if (StrEqual(item, "etkindevredisi"))
			{
				if(!REKLAMACIK)
					reklam_acik.SetBool(true, true, true);
				else
					reklam_acik.SetBool(false, true, true);
			}
		}

		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);

		}

		case MenuAction_DisplayItem:
		{
			//param1 is client, param2 is item

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "reklamolustur"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", "MainMenu2", param1);
				return RedrawMenuItem(translation);
			}
			else if (StrEqual(item, "listedensil"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", "MainMenu3", param1);
				return RedrawMenuItem(translation);
			}
			else if (StrEqual(item, "tumunusilharitadan"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", "MainMenu4", param1);
				return RedrawMenuItem(translation);
			}
			else if (StrEqual(item, "etkindevredisi"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", !REKLAMACIK ? "ReklamlarEtkinlestir" : "ReklamlarDevredisi", param1);
				return RedrawMenuItem(translation);
			}
		}

	}
	return 0;
}


public void SilmeOnayMenuAc(int client)
{
	new Handle:menu = CreateMenu(Silme_Onay_Menu_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "%t", "SilenecekUyari");

	AddMenuItem(menu, "evet", "Evet");
	AddMenuItem(menu, "hayir", "Hayır");

	DisplayMenu(menu, client, 10);
}

public Silme_Onay_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "evet"))
				ClearAllBD(param1);
			Command_Reklam(param1, 0);
		}
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_DisplayItem:
		{
			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "evet"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", "Evet", param1);
				return RedrawMenuItem(translation);
			}
			else if (StrEqual(item, "hayir"))
			{
				new String:translation[128];
				Format(translation, sizeof(translation), "%T", "Hayir", param1);
				return RedrawMenuItem(translation);
			}
		}
	}
	return 0;
}
