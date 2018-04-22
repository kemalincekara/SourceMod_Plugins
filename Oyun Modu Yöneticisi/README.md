## Oyun Modu Yöneticisi

**Açıklama:** Bir sunucuda birden fazla modu yükleyip adminlik menüsünden seçiminize göre oynayabilirsiniz.

**Yetki:** SourceMod Admin'i veya Mani Admin Plugin yetkisi bulunanlar eklentiyi kullanabilir.

**Zorunlu Yüklenmesi Gereken Eklenti:** [Çevrimiçi Admin Listesi](https://github.com/kemalincekara/SourceMod_Plugins/tree/master/%C3%87evrimi%C3%A7i%20Admin%20Listesi "sm_admins")

***

### Yapılandırma
"k_oyunmodu_yoneticisi.cfg" dosyası her oyun moduna göre ayarlanmalı.

### Kullanılabilir Konsol Komutlar
- **Oyun modlarını yapılandırmasını yenile**
```
sm_oyunmod_yenile
```
- **Oyun modunu öğren/ayarla**
```
sm_setoyunmod varsayilan
```
- **Oyun modunu seçmek icin bir menü acilir**
```
sm_oyunmod
```
- **CVars Debug**
```
sm_cvar sm_oyunmod_debug 0
```