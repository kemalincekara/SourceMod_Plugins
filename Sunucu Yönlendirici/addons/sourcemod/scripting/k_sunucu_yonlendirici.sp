#include <sourcemod>
#include <sdktools>
#include <k_sm_admins>
#include <colors>

#define PLUGIN_VERSION "1.0.0"
#define MAX_SERVERS 10
#define MAX_STR_LEN 160
#define MAX_INFO_LEN 200

new serverCount = 0;
new String:serverName[MAX_SERVERS][MAX_STR_LEN];
new String:serverAddress[MAX_SERVERS][MAX_STR_LEN];
new serverPort[MAX_SERVERS];

public Plugin:myinfo =
{
  name = "Sunucu Yönlendirici",
  author = "☪İSTİKLAL☪|TERMINATOR",
  description = "Birden fazla sunucunuz varsa oyuncular F3 basarak diğer sunuculara bağlanmasını sağlar.",
  version = PLUGIN_VERSION,
  url = "https://www.github.com/kemalincekara"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_servers", Command_Servers, "Sunucuları Listele");
	RegConsoleCmd("sm_sunucu", Command_Servers, "Sunucuları Listele");
	RegConsoleCmd("sm_servers_yenile", Command_Servers_Yenile, "Sunucuları Liste Yenile");
	RegConsoleCmd("sm_sunucu_yenile", Command_Servers_Yenile, "Sunucuları Liste Yenile");
	SunucuCfgYukle();
}

public Action Command_Servers_Yenile(int client, int args)
{
	if(!IsAdminValid(client))
		return Plugin_Continue;
	SunucuCfgYukle();
	ReplyToCommand(client, "Sunucu Listesi Yenilendi.");
	return Plugin_Handled;
}

public Action Command_Servers(int client, int args)
{
	SunucularMenuAc_Client(client);
	ReplyToCommand(client, "Sunucular Menusu Acildi.");
	return Plugin_Handled;
}

public void SunucularMenuAc_Client(int client)
{
	new Handle:menu = CreateMenu(MenuHandler_Client, MenuAction_Select);
	char serverNumStr[MAX_STR_LEN];
	SetMenuTitle(menu, "Sunucular\n - Bağlanmak istediğiniz sunucuyu seçiniz.\n - F3'e basarak kabul ediniz.");

	if(IsAdminValid(client))
		AddMenuItem(menu, "sm_servers_admin", "Tüm Oyuncuları Yönlendir \n -----------------------------");
	for (new i = 0; i < serverCount; i++)
	{
		if (strlen(serverName[i]) > 0 )
		{
			IntToString(i, serverNumStr, sizeof(serverNumStr));
			AddMenuItem(menu, serverNumStr, serverName[i]);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public void SunucularMenuAc_Admin(int client)
{
	new Handle:menu = CreateMenu(MenuHandler_Admin, MenuAction_Select);
	char serverNumStr[MAX_STR_LEN];
	SetMenuTitle(menu, "Sunucular\n - Tüm oyuncuları sunucuya yönlendirmek için seçim yapınız.\n - Seçiminizi yaptıktan sonra herkese F3'e basmalarını söyleyiniz.");

	AddMenuItem(menu, "sm_servers_client", "Sadece Siz Bağlanın \n -----------------------------");
	for (new i = 0; i < serverCount; i++)
	{
		if (strlen(serverName[i]) > 0 )
		{
			IntToString(i, serverNumStr, sizeof(serverNumStr));
			AddMenuItem(menu, serverNumStr, serverName[i]);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Client(Handle menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		new String:item[MAX_STR_LEN];
		GetMenuItem(menu, position, item, sizeof(item));
		if (StrEqual(item, "sm_servers_admin"))
			SunucularMenuAc_Admin(client);
		else
		{
			int serverNum = StringToInt(item);
			ShowDialog(client, serverNum);
			CPrintToChatAllEx(client, "{green}[SUNUCU] {teamcolor}%s {default}OYUNCU {green}'%s' {default}SUNUCUYA BAĞLANDI.", GetName(client), serverName[serverNum]);
		}
	}
	return 0;
}

public int MenuHandler_Admin(Handle menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		new String:item[MAX_STR_LEN];
		GetMenuItem(menu, position, item, sizeof(item));
		if (StrEqual(item, "sm_servers_client"))
			SunucularMenuAc_Client(client);
		else
		{
			int serverNum = StringToInt(item);
			for(int i = 1; i <= MaxClients; i++)
				if(IsClientValid(i))
					ShowDialog(i, serverNum);
			//CPrintToChatAll("{green}[SUNUCU] {lightgreen}'%s' {green}SUNUCUYA BAGLANMAK iCiN {lightgreen}F3{green}'E BASINIZ.", serverName[serverNum]);
			CPrintToChatAllEx(client, "{green}[SUNUCU] {teamcolor}'%s' {green}SUNUCUYA BAGLANMAK iCiN {teamcolor}F3{green}'E BASINIZ.", serverName[serverNum]);
		}
	}
	return 0;
}

public void ShowDialog(int client, int serverNum)
{
	new Handle:kvheader = CreateKeyValues("header");
	KvSetString(kvheader, "title", "F3 BASARAK SUNUCU BAGLANTISINI KABUL EDIN.");
	KvSetColor(kvheader, "color", 255, 255, 0, 255); // Yesil
	KvSetString(kvheader, "time", "30");
	KvSetNum(kvheader, "level", 1);
	CreateDialog(client, kvheader, DialogType_Msg);
	CloseHandle(kvheader);

	new String:address[MAX_STR_LEN];
	Format(address, MAX_STR_LEN, "%s:%i", serverAddress[serverNum], serverPort[serverNum]);
	new Handle:kv = CreateKeyValues("menu");
	KvSetString(kv, "title", address);
	KvSetString(kv, "time", "30");
	CreateDialog(client, kv, DialogType_AskConnect);
	CloseHandle(kv);
}


public void SunucuCfgYukle()
{
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/k_sunucu_yonlendirme.cfg" );
	KeyValues kv = new KeyValues("Sunucular");
	if (!kv.ImportFromFile(path) || !kv.GotoFirstSubKey())
	{
		LogToGame("Sunucu Listesi Yuklenemedi");
		delete kv;
		return;
	}
	serverCount = 0;
	do {
		kv.GetString("name", serverName[serverCount], MAX_STR_LEN);
		kv.GetString("ip", serverAddress[serverCount], MAX_STR_LEN);
		serverPort[serverCount] = kv.GetNum("port", 27015);
		serverCount++;
	} while (kv.GotoNextKey());
	delete kv;
}