## Reklam Yönetimi

**Açıklama:** VTF resimlerinizi reklam olarak haritaya ekleyebilirsiniz.

**Oyun:** Counter-Strike Source

**Yetki:** SourceMod Admin'i veya Mani Admin Plugin yetkisi bulunanlar eklentiyi kullanabilir.

**Zorunlu Yüklenmesi Gereken Eklenti:** [Çevrimiçi Admin Listesi](https://github.com/kemalincekara/SourceMod_Plugins/tree/master/%C3%87evrimi%C3%A7i%20Admin%20Listesi "sm_admins")

### Kullanılabilir Konsol Komutlar

- Yönetim Paneli
```
sm_reklam
```

- CVAR Reklamlar Etkin/Devredışı
```
sm_cvar sm_reklam_acik 1 / 0
```

### Kurulum
Öncelikle yetki kontrolünün sağlanması için zorunlu olan eklenti yüklenmesi gerekmektedir.
Oyun klasörünün aşağıdaki dosyaya veritabanı eklenmesi gereklidir. İsteğe göre SQLite veya MySQL kullanabilirsiniz.
> addons\sourcemod\configs\databases.cfg

- SQLite
```
"reklamlar"
{
	"driver"	"sqlite"
	"database"	"reklamlar-sqlite"
}
```

- MySQL
```
"reklamlar"
{
	"driver"	"mysql"
	"host"		"localhost"
	"database"	"sourcemod"
	"user"		"root"
	"pass"		""
	//"timeout"	"0"
	//"port"	"0"
}
```