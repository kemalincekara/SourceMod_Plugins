## Komut Kısaltma Eklentisi [SourceMod & Mani Admin Plugin]

**Açıklama:** Kendi Komutunuzu Kendiniz Kısaltın.

**Oyun:** Counter-Strike Source

**Gereklilik:** SourceMod Admin'i veya Mani Admin Plugin yetkisi bulunanlar eklentiyi kullanabilir.
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