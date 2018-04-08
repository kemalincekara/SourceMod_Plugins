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

public bool IsAdminValid(int client)
{
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		if(IsSMAdmin(client) || IsManiAdmin(client))
			return true;
	return false;
}

public bool IsSMAdmin(int client)
{
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		if ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC || GetUserFlagBits(client) & ADMFLAG_ROOT)
			return true;
	return false;
}

public bool IsManiAdmin(int client)
{
	if(!FileExists(MANI_ADMIN_CLIENTS_TXT, true))
		return false;
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

stock char GetName(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	return name;
}

stock char GetPassword(int client)
{
	decl String:info[50]; 
	info[0] = '\0'; 
	GetClientInfo(client, "_password", info, sizeof(info));
	return info;
}