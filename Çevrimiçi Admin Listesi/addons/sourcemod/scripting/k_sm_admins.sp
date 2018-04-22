#include <sourcemod>
#include <k_sm_admins>

//#pragma semicolon 1

#define MANI_ADMIN_CLIENTS_TXT "cfg/mani_admin_plugin/clients.txt"

methodmap AdminInfo < StringMap
{
    public AdminInfo() { return view_as<AdminInfo>(new StringMap()); }

    public void Oku(const char[] key, char[] buffer, int maxlength)
    {
        this.GetString(key, buffer, maxlength);
    }
    public void Yaz(const char[] key, const char[] value)
    {
        this.SetString(key, value);
    }
};

StringMap maniAdminlikler;
new Handle:AdminListEnabled = INVALID_HANDLE;
new Handle:AdminListMode = INVALID_HANDLE;
new Handle:AdminListMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Adminleri Listele",
	author = "ℂ⋆İSTİKLAL|TERMINATOR",
	description = "Admin listesini gosterir",
	version = PLUGIN_VERSION_CORE,
	url = "http://www.kemalincekara.tk"
}

public OnPluginStart()
{
	AdminListEnabled		= CreateConVar("sm_admins_on", "1", "Admin Listesini Görüntüle, 1=acik ,0=kapali");
	AdminListMode			= CreateConVar("sm_admins_mode", "1", "Listenin Görüntüleme Modu, 1=Menu, 2=Chat");
	RegConsoleCmd("sm_admins", Command_Admins, "Adminleri Listele");
	
	AutoExecConfig(true, "sm_admins");
}
public Action Command_Admins(int client, int args)
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
						AddMenuItem(AdminListMenu, "#menu1", "!admins Devredışı Bırak\n -----------------------------");
					else
						AddMenuItem(AdminListMenu, "#menu1", "!admins Etkinleştir\n -----------------------------");
					// AddMenuItem(AdminListMenu, "#menu2", "!admins Görüntüleme Modu Değiştir\n -----------------------------");
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
	else if (action == MenuAction_Cancel || action == MenuAction_End)
		CloseHandle(menu);
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	/**
	Register natives for other plugins
	*/
	CreateNative("IsAdminValid", Native_IsAdminValid);
	CreateNative("IsSMAdmin", Native_IsSMAdmin);
	CreateNative("IsManiAdmin", Native_IsManiAdmin);
	RegPluginLibrary("k_sm_admins");
	return APLRes_Success;
}

public OnMapStart()
{
	AdminCacheClear();
}

public OnMapEnd()
{
	AdminCacheClear();
}

public void AdminCacheClear()
{
	if(maniAdminlikler)
		maniAdminlikler.Clear();
}

public int Native_IsAdminValid(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool serverAllow = GetNativeCell(2);
	return (serverAllow && client == 0) || (IsClientValid(client) && (IsSMAdmin(client) || IsManiAdmin(client)));
}

public int Native_IsSMAdmin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC || GetUserFlagBits(client) & ADMFLAG_ROOT);
}

public int Native_IsManiAdmin(Handle plugin, int numParams)
{
	if(!FileExists(MANI_ADMIN_CLIENTS_TXT, true))
		return false;
	int client = GetNativeCell(1);
	char nickNameClient[MAX_NAME_LENGTH];
	char passwordClient[50];
	char steamClient[32];
	char ipAdresiClient[32];
	
	char nickNameMani[MAX_NAME_LENGTH];
	char passwordMani[50];
	char steamMani[32];
	char ipAdresiMani[32];

	char tempStr[10];

	bool steamValid = false;
	bool ipAdresiValid = false;
	
	nickNameClient = GetName(client);
	passwordClient = GetPassword(client);
	GetClientAuthId(client, AuthId_Engine, steamClient, sizeof(steamClient));
	GetClientIP(client, ipAdresiClient, sizeof(ipAdresiClient));
	
	if(!maniAdminlikler)
		maniAdminlikler = new StringMap();
	else
	{
		AdminInfo info;
		if(maniAdminlikler.GetValue(steamClient, info))
		{
			info.Oku("NickName", nickNameMani, sizeof(nickNameMani));
			info.Oku("Password", passwordMani, sizeof(passwordMani));
			info.Oku("Steam", steamMani, sizeof(steamMani));
			info.Oku("IpAdresi", ipAdresiMani, sizeof(ipAdresiMani));
			if(StrEqual(nickNameMani, nickNameClient) && StrEqual(passwordMani, passwordClient) && StrEqual(steamMani, steamClient) && StrEqual(ipAdresiMani, ipAdresiClient))
				return true;
			else
			{
				maniAdminlikler.Remove(steamClient);
				nickNameMani = "";
				passwordMani = "";
				steamMani = "";
				ipAdresiMani = "";
			}
		}
	}

	KeyValues kv = new KeyValues("clients.txt");
	if (!kv.ImportFromFile(MANI_ADMIN_CLIENTS_TXT) || !kv.JumpToKey("players"))
	{
		delete kv;
		return false;
	}
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("password", passwordMani, sizeof(passwordMani), "");
			
			if(kv.GetDataType("nick") == KvData_String)
				kv.GetString("nick", nickNameMani, sizeof(nickNameMani), "");
			else if(kv.GetDataType("nick") == KvData_None && kv.JumpToKey("nick"))
			{
				for(int i = 0; i <= 10; i++)
				{
					Format(tempStr, sizeof(tempStr), "nick%d", i);
					kv.GetString(tempStr, nickNameMani, sizeof(nickNameMani), "");
					if (StrEqual(nickNameMani, nickNameClient, false))
						break;
				}
				kv.GoBack();
			}
			
			if(kv.GetDataType("steam") == KvData_String)
				kv.GetString("steam", steamMani, sizeof(steamMani), "");
			else if(kv.GetDataType("steam") == KvData_None && kv.JumpToKey("steam"))
			{
				for(int i = 0; i <= 10; i++)
				{
					Format(tempStr, sizeof(tempStr), "steam%d", i);
					kv.GetString(tempStr, steamMani, sizeof(steamMani), "");
					if (StrEqual(steamMani, steamClient, false))
						break;
				}
				kv.GoBack();
			}
			
			if(kv.GetDataType("ip") == KvData_String)
				kv.GetString("ip", ipAdresiMani, sizeof(ipAdresiMani), "");
			else if(kv.GetDataType("ip") == KvData_None && kv.JumpToKey("ip"))
			{
				for(int i = 0; i <= 10; i++)
				{
					Format(tempStr, sizeof(tempStr), "ip%d", i);
					kv.GetString(tempStr, ipAdresiMani, sizeof(ipAdresiMani), "");
					if (StrEqual(ipAdresiMani, ipAdresiClient, false))
						break;
				}
				kv.GoBack();
			}
			
			int dogrula = 0;
			if(strlen(nickNameMani) > 0 && StrEqual(nickNameMani, nickNameClient, false))
				dogrula++;
			if(strlen(passwordMani) > 0 && StrEqual(passwordMani, passwordClient, false))
				dogrula++;
			if(strlen(ipAdresiMani) > 0 && StrEqual(ipAdresiMani, ipAdresiClient, false))
			{
				ipAdresiValid = true;
				dogrula++;
			}
			if(strlen(steamMani) > 0 && StrEqual(steamMani, steamClient, false))
			{
				steamValid = true;
				dogrula++;
			}
			if((dogrula == 1 && (steamValid || ipAdresiValid)) || dogrula >= 2)
			{
				AdminInfo info = new AdminInfo();
				info.Yaz("NickName", nickNameClient);
				info.Yaz("Password", passwordClient);
				info.Yaz("Steam", steamClient);
				info.Yaz("IpAdresi", ipAdresiClient);
				maniAdminlikler.SetValue(steamClient, info, true);
				delete kv;
				return true;
			}
		} while (kv.GotoNextKey());
	}
	delete kv;
	return false;
}