#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "helpers/admin_helper.sp"

#define CONFIG_DOSYA "configs/sm_komutlar.cfg"
#define MAX_KOMUT_COUNT 100
#define MAX_KOMUT_LINE_LENGTH 255
#define MAX_KOMUT_LENGTH 255

new String:g_komutGorunumIsim[MAX_KOMUT_COUNT][MAX_KOMUT_LENGTH];
new String:g_komutUygula[MAX_KOMUT_COUNT][MAX_KOMUT_LINE_LENGTH];
new g_komutNum;

public Plugin:myinfo =
{
	name = "Komut Kisaltma Eklentisi",
	author = "UniTy . TERMINATOR ☪",
	description = "Komut Kisaltma Eklentisi",
	version = "1.2",
	url = "http://www.kemalincekara.tk/"
};
 
public void OnPluginStart()
{
	RegConsoleCmd("sm_komutlar", KOMUTLAR, "Kisaltilmis Komutlar", 0);
	RegConsoleCmd("sm_komutlaryenile", KOMUTYENILE, "Komutlari Yenile", 0);
	RegConsoleCmd("sm_ky", KOMUTYENILE, "Komutlari Yenile", 0);
	RegConsoleCmd("sm_komutekle", KOMUTEKLE, "Oyun Ici Komut Ekle", 0);
	RegConsoleCmd("sm_komutsil", KOMUTSIL, "Oyun Ici Komut Sil", 0);
	YukleKomutlar();
}

public YukleKomutlar()
{
	decl String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filename, sizeof(filename), CONFIG_DOSYA);
	new Handle:hFile = OpenFile(filename, "r");
	if (hFile)
	{
		g_komutNum = 0;
		decl String:line[MAX_KOMUT_LINE_LENGTH];
		new pos;
		while (g_komutNum < MAX_KOMUT_COUNT && !IsEndOfFile(hFile) && ReadFileLine(hFile, line, sizeof(line)))
		{
			if (line[0] != '/' && line[1] != '/')
			{
				decl String:buf;
				g_komutGorunumIsim[g_komutNum][0] = buf;
				g_komutUygula[g_komutNum][0] = buf;
				pos = BreakString(line, g_komutGorunumIsim[g_komutNum], MAX_KOMUT_LINE_LENGTH);
				if (strcmp(g_komutGorunumIsim[g_komutNum], "", true))
				{
					strcopy(g_komutUygula[g_komutNum], MAX_KOMUT_LINE_LENGTH, line[pos]);
					if (strcmp(g_komutUygula[g_komutNum], "", true))
					{
						TrimString(g_komutUygula[g_komutNum]);
						g_komutNum += 1;
					}
				}
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		PrintToServer("Dosya Bulunamadi : %s", CONFIG_DOSYA);
		//SetFailState("Dosya Bulunamadi : %s", CONFIG_DOSYA);
	}
}

public Action:KOMUTLAR(int client, int args)
{
	RequestFrame(KOMUTLAR_NextFrame, client);
	ReplyToCommand(client, "");
	return Plugin_Handled;
}

public void KOMUTLAR_NextFrame(any:client)
{
	if(IsAdminValid(client))
	{
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x01!komutlar");
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x01!komutekle \"KisaKomut\" \"UygulanacakKomut\"");
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x01!komutsil \"KisaKomut\"");
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x01!komutlaryenile veya !ky");

		new Handle:menu = CreateMenu(AdminSoundsMenuHandler, MENU_ACTIONS_DEFAULT);
		SetMenuTitle(menu, "Kısa Komutlar :");
		PrintToConsole(client, "Kısa Komutlar :");
		new i;
		while (i < g_komutNum)
		{
			AddMenuItem(menu, "Kısa Komutlar", g_komutGorunumIsim[i], 0);
			PrintToConsole(client, g_komutGorunumIsim[i]);
			i++;
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public AdminSoundsMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		KOMUTLAR(client, 0);
		if(StrContains(g_komutUygula[param2], "*", false) != -1)
		{
			PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] '%s' kısa komut için parametre belirtilmedi.", g_komutGorunumIsim[param2]);
			PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] Şablon: '%s'", g_komutUygula[param2]);
		}
		else
			KomutCalistir(client, GetName(client), g_komutGorunumIsim[param2], g_komutUygula[param2]);
	}
	else if (action == MenuAction_Cancel || action == MenuAction_End)
		CloseHandle(menu);
}

public Action:KOMUTEKLE(client, args)
{
	if (args <= 1)
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] !komutekle \"KisaKomut\" \"UygulanacakKomut\"");
	else if (args >= 2)
	{
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteCell(args);
		for(int i = 1; i <= args; i++)
		{
			new String:komut[MAX_KOMUT_LENGTH];
			GetCmdArg(i, komut, sizeof(komut));
			data.WriteString(komut);
		}
		RequestFrame(KOMUTEKLE_NextFrame, data);
	}
	ReplyToCommand(client, "");
	return Plugin_Handled;
}

public void KOMUTEKLE_NextFrame(any:data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	if(IsAdminValid(client))
	{
		int args = ReadPackCell(data);
		new String:komutlar[MAX_KOMUT_LINE_LENGTH];
		new String:kisakomut[MAX_KOMUT_LENGTH];
		new String:temp[MAX_KOMUT_LENGTH];
		ReadPackString(data, kisakomut, sizeof(kisakomut));
		Format(temp, sizeof(temp), "!%s", kisakomut);
		new i;
		while (i < g_komutNum)
		{
			if (StrEqual(temp, g_komutGorunumIsim[i], false))
			{
				PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x03Bu kısa komut daha önce eklenmiştir. Lütfen önce eskisini siliniz.");
				return;
			}
			i++;
		}
		komutlar = "";
		for(i = 2; i <= args; i++)
		{
			char komut[MAX_KOMUT_LENGTH];
			ReadPackString(data, komut, sizeof(komut));
			if(StrContains(komut, " ", false) != -1)
				Format(komutlar, sizeof(komutlar), "%s \"%s\"", komutlar, komut);
			else
				Format(komutlar, sizeof(komutlar), "%s %s", komutlar, komut);
		}
		//new String:tarih[52];
		//new String:saat[52];
		//FormatTime(tarih, 50, "%m/%d/%Y", -1);
		//FormatTime(saat, 50, "%H:%M:%S", -1);
		new String:configFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, configFile, sizeof(configFile), CONFIG_DOSYA);
		new Handle:file = OpenFile(configFile, "at+");
		//WriteFileLine(file, "");
		//WriteFileLine(file, "//Tarih : %s | Saat : %s | Bu Eklenti TERMINATOR ☪ Tarafindan UniTy Clani İcin Yapilmistir. ", tarih, saat);
		WriteFileLine(file, "\"!%s\" %s", kisakomut, komutlar);
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] Komut Eklendi.");
		CloseHandle(file);
		YukleKomutlar();
		FakeClientCommand(client, "sm_ky");
	}
	CloseHandle(data);
}


public Action:KOMUTSIL(client, args)
{
	if (args == 1)
	{
		decl String:KisaKomut[MAX_KOMUT_LENGTH];
		GetCmdArg(1, KisaKomut, MAX_KOMUT_LENGTH);
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteString(KisaKomut);
		RequestFrame(KOMUTSIL_NextFrame, data);
	}
	else
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] !komutsil \"KisaKomut\"");
	ReplyToCommand(client, "");
	return Plugin_Handled;
}

public void KOMUTSIL_NextFrame(any:data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	if(IsAdminValid(client))
	{		
		decl String:KisaKomut[MAX_KOMUT_LENGTH];
		ReadPackString(data, KisaKomut, sizeof(KisaKomut));
		char sLine[MAX_KOMUT_LINE_LENGTH], path[PLATFORM_MAX_PATH];
		int arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
		ArrayList array = new ArrayList(arraySize);
		BuildPath(Path_SM, path, sizeof(path), CONFIG_DOSYA);
		new Handle:hFile = OpenFile(path, "r");
		array.Clear();
		if (hFile)
		{
			while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, sizeof(sLine)))
			{
				bool found = false;
				TrimString(sLine);
				if (sLine[0] != '/' && sLine[1] != '/')
				{
					char komut[MAX_KOMUT_LENGTH];
					BreakString(sLine, komut, sizeof(komut));
					if (strcmp(komut, "", true))
					{
						char unlem[MAX_KOMUT_LENGTH];
						Format(unlem, sizeof(unlem), "!%s", KisaKomut);
						if(StrEqual(komut, unlem))
							found = true;
					}
				}
				if(!found)
					array.PushString(sLine);
			}
			CloseHandle(hFile);
		}
		hFile = OpenFile(path, "w");
		if (hFile)
		{
			for (int i = 0; i < array.Length; i++)
			{
				array.GetString(i, sLine, sizeof(sLine));
				WriteFileLine(hFile, sLine);
			}
			CloseHandle(hFile);
		}
		delete array;
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] Komut Silindi : !%s", KisaKomut);
		KOMUTYENILE_MESSAGE(client);
	}
	CloseHandle(data);
}


public Action:KOMUTYENILE(client, args)
{
	RequestFrame(KOMUTYENILE_NextFrame, client);
	ReplyToCommand(client, "");
	return Plugin_Handled;
}

public void KOMUTYENILE_NextFrame(any:client)
{
	if(IsAdminValid(client))
	{
		KOMUTYENILE_MESSAGE(client);
	}
}

public void KOMUTYENILE_MESSAGE(client)
{
	YukleKomutlar();
	PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] \x03Komutlar Yenilendi.");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	//PrintToChatAll("\x011\x022\x033\x044\x055\x066\x077\x088\x099\x0AA\x0BB\x0CC\x0DD\x0EE\x0FF");
	char kisaKomut[MAX_KOMUT_LENGTH];
	int len = BreakString(sArgs, kisaKomut, sizeof(kisaKomut));
	int i = 0;
	while (i < g_komutNum)
	{
		if (StrEqual(kisaKomut, g_komutGorunumIsim[i], false) && IsAdminValid(client))
		{
			char parametreKomutlar[50][MAX_KOMUT_LENGTH];
			int parametreKomutlarCount = 0;
			char calistir[MAX_KOMUT_LINE_LENGTH];
			calistir = g_komutUygula[i];
			TrimString(calistir);
			int kacYildiz = 0;
			if(StrContains(calistir, "*", false) != -1)
				for (int c = 0; c < strlen(calistir); c++)
					if (calistir[c] == '*')
						kacYildiz++;
			if(kacYildiz > 0)
			{
				int pos = len;
				while (pos != -1)
				{	
					pos = BreakString(sArgs[len], parametreKomutlar[parametreKomutlarCount], sizeof(parametreKomutlar[]));
					parametreKomutlarCount++;
					
					if (pos != -1)
						len += pos;
					else
						break;
				}
				if(parametreKomutlarCount != kacYildiz)
				{
					PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] Şablon: '%s'", calistir);
					PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] '%s' kısa komut için eksik parametre belirttiniz.", g_komutGorunumIsim[i]);
					return Plugin_Continue;
				}
				else
				{
					for (int j = 0; j < parametreKomutlarCount; j++)
					{
						TrimString(parametreKomutlar[j]);
						if(StrContains(parametreKomutlar[j], " ", false) != -1)
							ReplaceStringEx(calistir, sizeof(calistir), "*", "\"%s\"");
						else
							ReplaceStringEx(calistir, sizeof(calistir), "*", "%s");
						Format(calistir, sizeof(calistir), calistir, parametreKomutlar[j]);
					}
				}
			}
			KomutCalistir(client, GetName(client), g_komutGorunumIsim[i], calistir);
			return Plugin_Handled;
		}
		i++;
	}
	return Plugin_Continue;
}

public Action:KomutCalistir(int client, const char[] name, const char[] kisaltma, const char[] komut)
{
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteString(name);
	data.WriteString(kisaltma);
	data.WriteString(komut);
	RequestFrame(KomutCalistir_NextFrame, data);
	return Plugin_Continue;
}

public void KomutCalistir_NextFrame(any:data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	char name[MAX_NAME_LENGTH];
	char kisaltma[MAX_KOMUT_LENGTH];
	char komut[MAX_KOMUT_LINE_LENGTH];
	ReadPackString(data, name, sizeof(name));
	ReadPackString(data, kisaltma, sizeof(kisaltma));
	ReadPackString(data, komut, sizeof(komut));
	CloseHandle(data);
	
	if(IsAdminValid(client))
	{
		PrintToChat(client, "\x03[\x04SM KOMUTLAR\x03] Uygulandı: \x04%s", komut);
		ClientCommand(client, komut);
	}
}