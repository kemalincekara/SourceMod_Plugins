#include <sourcemod>
#include "helpers/admin_helper.sp"

#pragma semicolon 1


new Handle:AdminListEnabled = INVALID_HANDLE;
new Handle:AdminListMode = INVALID_HANDLE;
new Handle:AdminListMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Adminleri Listele",
	author = "UniTy . TERMINATOR ☪",
	description = "Admin listesini gosterir",
	version = "1.0.0",
	url = "http://www.kemalincekara.tk"
}

public OnPluginStart()
{
	AdminListEnabled		= CreateConVar("sm_admins_on", "1", "Admin Listesini Görüntüle, 1=acik ,0=kapali");
	AdminListMode			= CreateConVar("sm_admins_mode", "1", "Listenin Görüntüleme Modu, 1=Menu, 2=Chat");
	RegConsoleCmd("sm_admins", Command_Admins, "Adminleri Listele");
	
	AutoExecConfig(true, "sm_admins");
}
public Action:Command_Admins(client, args)
{
	new count = 0;
	int cVarEnabled	= GetConVarInt(AdminListEnabled);
	int cVarMode	= GetConVarInt(AdminListMode);
	bool isAdminClient = IsAdminValid(client);
	if(isAdminClient)
		PrintToChat(client, "\x04sm_admins_on %d, sm_admins_mode %d", cVarEnabled, cVarMode);
	if(cVarEnabled == 1 || isAdminClient)
	{
		switch(cVarMode)
		{
			case 1:
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				AdminListMenu = CreateMenu(MenuListHandler);
				if(isAdminClient)
				{
					if (cVarEnabled == 1)
						AddMenuItem(AdminListMenu, "#menu1", "!admins Devredışı Bırak");
					else
						AddMenuItem(AdminListMenu, "#menu1", "!admins Etkinleştir");
					AddMenuItem(AdminListMenu, "#menu2", "!admins Görüntüleme Modu Değiştir\n ");
				}
				for(new i = 1; i <= GetMaxClients(); i++)
				{
					if(IsAdminValid(i))
					{
						AdminName = GetName(i);
						AddMenuItem(AdminListMenu, AdminName, AdminName, ITEMDRAW_DISABLED);
						count++;
					} 
				}
				SetMenuTitle(AdminListMenu, "Çevrimiçi Admin [%d]:", count);
				if(count == 0)
					AddMenuItem(AdminListMenu, "", "Çevrimiçi Admin Yok");
				SetMenuExitButton(AdminListMenu, true);
				DisplayMenu(AdminListMenu, client, 30);
			}
			case 2:
			{
				decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
				for(new i = 1 ; i <= GetMaxClients();i++)
				{
					if(IsAdminValid(i))
					{
						AdminNames[count] = GetName(i);
						count++;
					}
				}
				decl String:buffer[1024];
				ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer));
				PrintToChatAll("\x04Çevrimiçi Admin [%d]: %s", count, buffer);
			}
		}
	}
	ReplyToCommand(client, "");
	return Plugin_Continue;
}public MenuListHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if(IsAdminValid(client))
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (StrEqual(info, "#menu1"))
			{
				if(GetConVarInt(AdminListEnabled) == 1)
					SetConVarBool(AdminListEnabled, false);
				else
					SetConVarBool(AdminListEnabled, true);
				Command_Admins(client, 0);
			}
			else if (StrEqual(info, "#menu2"))
			{
				if(GetConVarInt(AdminListMode) == 1)
					SetConVarInt(AdminListMode, 2);
				else
					SetConVarInt(AdminListMode, 1);
			}
		}
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}