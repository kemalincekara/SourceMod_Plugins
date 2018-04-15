## Komut Kısaltma Eklentisi [SourceMod & Mani Admin Plugin]

**Açıklama:** Kendi Komutunuzu Kendiniz Kısaltın.

**Oyun:** Counter-Strike Source

**Yetki:** SourceMod Admin'i veya Mani Admin Plugin yetkisi bulunanlar eklentiyi kullanabilir.

**Zorunlu Yüklenmesi Gereken Eklenti:** [Çevrimiçi Admin Listesi](https://github.com/kemalincekara/SourceMod_Plugins/tree/master/%C3%87evrimi%C3%A7i%20Admin%20Listesi "sm_admins")

***

### Kullanılabilir Konsol Komutlar
- **Kayıtlı Tüm Komutları Listele**
```
say !komutlar
```
- **Yeni Komut Ekleme**
```
sm_komutekle "KısaKomut" "UygulanacakKomut"
```
- **Komut Silme**
```
say !komutsil "KısaKomut"
```
- **Komut Listesini Yenile**
```
say !komutlaryenile
say !ky
```

### Parametreli Komut Ekleme
Parametreli komut eklemek için * (yıldız) koyunuz.
```
!komutekle god ma_rcon sm_god * *
```
Çalıştırmak için say'dan y tuşu ile yazınız.
```
!god @all 1
```

#### Örnek Kullanım
Aşağıdaki komutu say'dan y tuşu ile yazınız.
```
!komutekle para ma_setcash #all 16000
```
Bu 'para' kısa komutu tanıtımını yaptıktan sonra aşağıdaki kısa komut ile herkese 16000$ para verilir.
```
!para
```