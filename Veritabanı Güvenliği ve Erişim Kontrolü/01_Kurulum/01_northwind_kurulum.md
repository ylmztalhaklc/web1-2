# Northwind Kurulum Rehberi (MSSQL)

## Gereksinimler
- SQL Server 2019 veya 2022 kurulu (Express ücretsiz — yeterli)
- SQL Server Management Studio (SSMS) kurulu
- Northwind kurulum scripti

---

## ADIM 1: SQL Server Express İndir (Kurulu değilse)

```
https://www.microsoft.com/tr-tr/sql-server/sql-server-downloads
```
- **Express** seçeneğini indir (ücretsiz, lokal proje için yeterli)
- Setup sırasında **"Basic"** kurulum tipini seç → otomatik kurar

---

## ADIM 2: SSMS İndir ve Kur

```
https://aka.ms/ssmsfullsetup
```
İndir, Next Next Finish ile kur. SSMS ayrı bir araç, SQL Server'dan bağımsız.

---

## ADIM 3: Northwind Script'ini İndir

Tarayıcıda şu adresi aç:
```
https://github.com/microsoft/sql-server-samples/blob/master/samples/databases/northwind-pubs/instnwnd.sql
```
Sağ üstte **"Raw"** butonuna tıkla → Ctrl+A (hepsini seç) → Ctrl+S ile kaydet.
Dosya adı: `instnwnd.sql` → Masaüstüne kaydet.

---

## ADIM 4: SSMS ile Bağlan ve Northwind'i Kur

1. **SSMS'i aç**
2. Bağlantı ekranında:
   - Server name: `localhost\SQLEXPRESS` veya sadece `localhost`
   - Authentication: **Windows Authentication** → Connect
3. **File → Open → File** → `instnwnd.sql` dosyasını aç
4. **F5** ile çalıştır (veya Execute butonu)
5. Sol panelde **Databases → Northwind** görünüyor olmalı

---

## ADIM 5: Northwind Tablolarını Doğrula

SSMS'de yeni query penceresi aç (Ctrl+N), şunu çalıştır:

```sql
USE Northwind;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
```

Şu tablolar görünmeli:
```
Customers, Employees, Orders, [Order Details], Products,
Categories, Suppliers, Shippers, Region, Territories, EmployeeTerritories
```

---

## ADIM 6: Proje SQL Dosyalarını Sırayla Çalıştır

SSMS'de her dosyayı **File → Open → File** ile aç, **F5** ile çalıştır.

```
Sıra:
1. 02_Erisim_Yonetimi\02_roller_ve_kullanicilar.sql
2. 02_Erisim_Yonetimi\03_yetkiler.sql
3. 03_Guvenli_Viewlar\04_guvenli_viewlar.sql
4. 04_Row_Level_Security\05_rls_politikalari.sql
5. 05_Sifreleme\06_veri_sifreleme.sql
6. 06_SQL_Injection\07_sql_injection_demo.sql
7. 07_Audit_Log\08_audit_log.sql
8. 08_Test_Senaryolari\09_test_senaryolari.sql
```

---

## Proje Kullanıcıları (Özet)

| Login | Kullanıcı | Rol | Şifre |
|---|---|---|---|
| db_admin_login | db_admin | db_admin_role | Admin@2024! |
| manager_login | store_manager | manager_role | Manager@2024! |
| ali_login | ali_sales | sales_role | Sales@2024! |
| ayse_login | ayse_sales | sales_role | Sales@2024! |
| report_login | readonly_report | report_role | Report@2024! |

---

## Kimlik Doğrulama Yöntemleri

| Yöntem | Açıklama |
|---|---|
| **SQL Server Authentication** | Kullanıcı adı + şifre ile giriş (proje boyunca bu kullanılıyor) |
| **Windows Authentication** | Windows oturum açmış kullanıcıyla otomatik giriş (SSMS'de varsayılan) |

SQL Server Authentication aktif değilse:
SSMS → Server'a sağ tık → Properties → Security → **SQL Server and Windows Authentication mode** seç → Restart server.
