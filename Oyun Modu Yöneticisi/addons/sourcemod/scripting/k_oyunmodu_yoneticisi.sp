#include <sourcemod>
#include <k_sm_admins>

#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo = 
{
	name = "Oyun Modu Yoneticisi",
	author = "ℂ⋆İSTİKLAL|TERMINATOR",
	description = "Cok modlu bir sunucuda oyun modunu otomatiklestirmek icin bir eklenti.",
	version = "1.3.0",
	url = "http://www.kemalincekara.tk"
};

new Handle:hGlobalConfig;
new Handle:hAdminMenu = INVALID_HANDLE;
new bool:bDebug;
new String:etkinOyunMod[255];

public OnPluginStart()
{
	new Handle:hDebug = CreateConVar("sm_oyunmod_debug", "0", "hata ayiklamayi ve islem gunlugunu acar", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(hDebug, ToggleDebugging);
	RegConsoleCmd("sm_oyunmod_yenile", Event_OyunMod_Yenile, "Oyun modlarini yapilandirmadan yeniden yukle");
	RegConsoleCmd("sm_setoyunmod", Event_SetOyunMod, "Bir sonraki haritanin oyun modunu ogren/ayarla");
	RegConsoleCmd("sm_oyunmod", Event_OyunMod, "Bir sonraki haritanin oyun modunu secmek icin bir menu acilir");
	AyarlariGetir();
}
 
public void OnAllPluginsLoaded()
{
	if (!LibraryExists("k_sm_admins"))
		SetFailState("[SM OYUNMOD] k_sm_admins.smx PLUGIN GEREKLI");
	if (LibraryExists("adminmenu") && hAdminMenu != GetAdminTopMenu())
	{
		hAdminMenu = GetAdminTopMenu();
		AdminMenu_Ekle();
	}
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public void OnAdminMenuReady(Handle topmenu)
{
	hAdminMenu = topmenu;
	AdminMenu_Ekle();
}

public int Menu_OyunMod(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sSelectedGamemode[255];
			GetMenuItem(menu, param2, sSelectedGamemode, sizeof(sSelectedGamemode));
			SetEvent_SetOyunMod(param1, sSelectedGamemode);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

public Event_AdminMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Oyun Modunu Sec");
	else if (action == TopMenuAction_SelectOption)
		Event_OyunMod(param, 0);
}

public void ToggleDebugging(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bDebug = StringToInt(newValue) != 0;
}

public Action Event_OyunMod_Yenile(int client, int args)
{
	if(!IsAdminValid(client))
		return Plugin_Continue;
	AyarlariGetir();
	ReplyToCommand(client, "Oyun modlari listesi yenilendi");
	return Plugin_Handled;
}

public Action Event_SetOyunMod(int client, int args)
{
	if(!IsAdminValid(client))
		return Plugin_Continue;
	if (args == 0)
	{
		ReplyToCommand(client, "Bir sonraki harita icin oyun modu '%s'.", etkinOyunMod);	
		return Plugin_Handled;
	}
	else
	{
		char cOyunmodu[255];
		GetCmdArg(1, cOyunmodu, sizeof(cOyunmodu));
		SetEvent_SetOyunMod(client, cOyunmodu);
		return Plugin_Handled;
	}
}

public Action Event_OyunMod(int client, int args)
{
	if(!IsAdminValid(client))
		return Plugin_Continue;
	new Handle:hMenu = CreateMenu(Menu_OyunMod, MenuAction_Select | MenuAction_End);
	new Handle:hConfig = CloneHandle(Handle:hGlobalConfig);
	KvRewind(hConfig);
	KvGotoFirstSubKey(hConfig);
	char restartGerekenler[255];
	restartGerekenler[0] = '\0';
	do
	{
		char cOyunmoduSection[255];
		char modeName[255];
		KvGetSectionName(hConfig, cOyunmoduSection, sizeof(cOyunmoduSection));
		KvGetString(hConfig, "name", modeName, sizeof(modeName));
		if(StrEqual(etkinOyunMod, cOyunmoduSection, false))
			Format(modeName, sizeof(modeName), "* %s", modeName);
		AddMenuItem(hMenu, cOyunmoduSection, modeName);
		if(KvGetNum(hConfig, "restart", 0) == 1)
			Format(restartGerekenler, sizeof(restartGerekenler), "%s%s%s", restartGerekenler, !strcmp(restartGerekenler, "", true) ? "" : ", ", modeName);
	} while (KvGotoNextKey(hConfig));
	KvRewind(hConfig);
	CloseHandle(hConfig);
	
	if(strcmp(restartGerekenler, "", true))
		SetMenuTitle(hMenu, "Oyun Modunu Secin\n\n%s için\nSunucunun yeniden başlatılması gereklidir.\n\n-----------------------------", restartGerekenler);
	else
		SetMenuTitle(hMenu, "Oyun Modunu Secin");
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 0);
	return Plugin_Handled;
}

public void OnAutoConfigsBuffered()
{
	if(!hGlobalConfig)
		AyarlariGetir();
	new Handle:hConfig = CloneHandle(Handle:hGlobalConfig);
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, etkinOyunMod))
		KeyValuesCommandHelper(hConfig, "server.cfg");
	KvRewind(hConfig);
	CloseHandle(hConfig);
}

void AyarlariGetir()
{
	char sConfigPath[PLATFORM_MAX_PATH];
	BuildPath(PathType:FileType_File, sConfigPath, sizeof(sConfigPath), "configs/k_oyunmodu_yoneticisi.cfg");
	if(hGlobalConfig)
		CloseHandle(hGlobalConfig);
	hGlobalConfig = CreateKeyValues("sm_oyunmod");
	KvSetEscapeSequences(hGlobalConfig, true);
	if (!FileToKeyValues(hGlobalConfig, sConfigPath))
		SetFailState("Ayarlar yuklenemedi!");
	else
	{
		KvGetString(hGlobalConfig, "etkinmod", etkinOyunMod, sizeof(etkinOyunMod));
		if (bDebug)
			LogMessage("Oyun modu yapilandirildi.");
	}
}

void AyarlariKaydet()
{
	char sConfigPath[PLATFORM_MAX_PATH];
	BuildPath(PathType:FileType_File, sConfigPath, sizeof(sConfigPath), "configs/k_oyunmodu_yoneticisi.cfg");
	KvRewind(hGlobalConfig);
	KvSetString(hGlobalConfig, "etkinmod", etkinOyunMod);
	KeyValuesToFile(hGlobalConfig, sConfigPath);
}

void AdminMenu_Ekle()
{
	if (hAdminMenu != INVALID_HANDLE)
	{		
		new TopMenuObject:tmoServerCommands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		if (tmoServerCommands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu, "Oyun Modu Yoneticisi", TopMenuObject_Item, Event_AdminMenu, tmoServerCommands, "sm_oyunmod", ADMFLAG_CONFIG);
			if (bDebug)
				LogMessage("Yonetici menusu eklendi.");
		}
	}
}

void SetEvent_SetOyunMod(int client, const char[] cOyunmodu)
{
	new Handle:hConfig = CloneHandle(Handle:hGlobalConfig);
	KvRewind(hConfig);
	
	if (!KvJumpToKey(hConfig, cOyunmodu))
	{
		ReplyToCommand(client, "Oyunmod '%s' yapilandirmada bulunamadi!", etkinOyunMod);
		if (bDebug)
			LogMessage("Oyunmod '%s' yapilandirmada bulunamadi!", etkinOyunMod);
		KvRewind(hConfig);
		CloseHandle(hConfig);
		return;
	}
	else
	{
		char modeName[255];
		KvGetString(hConfig, "name", modeName, sizeof(modeName));
		strcopy(etkinOyunMod, sizeof(etkinOyunMod), cOyunmodu);
		PrintToChatAll("OYUN MODU : '%s'.", modeName);
		ReplyToCommand(client, "OYUN MODU : '%s'.", modeName);
		if (bDebug)
			LogMessage("OYUN MODU : '%s'.", modeName);
	}
	KvRewind(hConfig);
	CloseHandle(hConfig);
	
	AyarlariKaydet();
	OyunModEtkinlestir(etkinOyunMod);
	
	char harita[100];
	GetCurrentMap(harita, sizeof(harita));
	ForceChangeLevel(harita, "OYUN MODU DEGISTI");
}

void OyunModEtkinlestir(const char[] cOyunmodu)
{
	new Handle:hConfig = CloneHandle(Handle:hGlobalConfig);
	KvRewind(hConfig);
	KvGotoFirstSubKey(hConfig);
	do
	{
		char cOyunmoduSection[255];
		KvGetSectionName(hConfig, cOyunmoduSection, sizeof(cOyunmoduSection));
		if (!StrEqual(cOyunmodu, cOyunmoduSection, false))
		{
			if (bDebug)
				LogMessage("Oyun modu kaldiriliyor : %s", cOyunmoduSection);
			KeyValuesCommandHelper(hConfig, "server.cfg-disabled");
			KeyValuesPluginHelper(hConfig, "plugins", false);
			KeyValuesPluginHelper(hConfig, "plugins-disabled", true);
			KeyValuesAddonsHelper(hConfig, "addons", false);
			KeyValuesAddonsHelper(hConfig, "addons-disabled", true);
		}
	} while (KvGotoNextKey(hConfig));
	KvGoBack(hConfig);
	if (KvJumpToKey(hConfig, cOyunmodu))
	{
		if (bDebug)
			LogMessage("Oyun modu yukleniyor : %s", cOyunmodu);
		KeyValuesPluginHelper(hConfig, "plugins", true);
		KeyValuesPluginHelper(hConfig, "plugins-disabled", false);
		KeyValuesAddonsHelper(hConfig, "addons", true);
		KeyValuesAddonsHelper(hConfig, "addons-disabled", false);
	}
	KvRewind(hConfig);
	CloseHandle(hConfig);
}

public void KeyValuesAddonsHelper(const Handle hConfig, const char[] key, bool IsEnabled)
{
	char sAddons[PLATFORM_MAX_PATH];
	char sAddonsPath[PLATFORM_MAX_PATH];
	char sDisabledAddonsPath[PLATFORM_MAX_PATH];
	if (KvJumpToKey(hConfig, key))
	{
		KvGotoFirstSubKey(hConfig, false);
		do
		{
			if (KvGetDataType(hConfig, NULL_STRING) == KvData_String)
			{
				if(!DirExists("addons/disabled"))
					CreateDirectory("addons/disabled", 755);
				if(!DirExists("addons/disabled/metamod"))
					CreateDirectory("addons/disabled/metamod", 755);
				KvGetString(hConfig, NULL_STRING, sAddons, sizeof(sAddons));
				Format(sAddonsPath, sizeof(sAddonsPath), "addons/%s", sAddons);
				Format(sDisabledAddonsPath, sizeof(sDisabledAddonsPath), "addons/disabled/%s", sAddons);
				if (!IsEnabled && FileExists(sAddonsPath))
					RenameFile(sDisabledAddonsPath, sAddonsPath);
				else if (IsEnabled && FileExists(sDisabledAddonsPath))
					RenameFile(sAddonsPath, sDisabledAddonsPath);
			}
		} while (KvGotoNextKey(hConfig, false));
		KvGoBack(hConfig);
		KvGoBack(hConfig);
	}
}

public void KeyValuesPluginHelper(const Handle hConfig, const char[] key, bool IsEnabled)
{
	char sPlugin[PLATFORM_MAX_PATH];
	char sPluginPath[PLATFORM_MAX_PATH];
	char sDisabledPluginPath[PLATFORM_MAX_PATH];
	if (KvJumpToKey(hConfig, key))
	{
		KvGotoFirstSubKey(hConfig, false);
		do
		{
			if (KvGetDataType(hConfig, NULL_STRING) == KvData_String)
			{
				KvGetString(hConfig, NULL_STRING, sPlugin, sizeof(sPlugin));
				BuildPath(PathType:FileType_File, sPluginPath, sizeof(sPluginPath), "plugins/%s", sPlugin);
				BuildPath(PathType:FileType_File, sDisabledPluginPath, sizeof(sDisabledPluginPath), "plugins/disabled/%s", sPlugin);
				if (!IsEnabled && FileExists(sPluginPath))
				{
					ServerCommand("sm plugins unload %s", sPlugin);
					RenameFile(sDisabledPluginPath, sPluginPath);
				}
				else if (IsEnabled)
				{
					if (FileExists(sDisabledPluginPath))
						RenameFile(sPluginPath, sDisabledPluginPath);
					ServerCommand("sm plugins load %s", sPlugin);
				}
			}
		} while (KvGotoNextKey(hConfig, false));
		KvGoBack(hConfig);
		KvGoBack(hConfig);
	}
}

public void KeyValuesCommandHelper(const Handle hConfig, const char[] key)
{
	if (KvJumpToKey(hConfig, key))
	{
		KvGotoFirstSubKey(hConfig, false);
		do
		{
			if (KvGetDataType(hConfig, NULL_STRING) == KvData_String)
			{
				char sCommand[255];
				KvGetString(hConfig, NULL_STRING, sCommand, sizeof(sCommand));
				ServerCommand("%s", sCommand);
			}
		} while (KvGotoNextKey(hConfig, false));
		KvGoBack(hConfig);
		KvGoBack(hConfig);
	}
}