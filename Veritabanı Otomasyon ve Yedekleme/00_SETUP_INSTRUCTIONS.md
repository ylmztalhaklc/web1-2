# NORTHWIND YEDEKLEMESİ - KURULUM TALIMATLAR

## ÖN KOSULLAR

Aşağıdaki adımları SQL Server scriptlerini çalıştırmadan ÖNCE yapın:

### 1. Northwind Veritabanını Kurun
Northwind veritabanını kurmak için:
```sql
-- Dosya: 01_Kurulum\01_northwind_kurulum.sql
-- Bu dosyayı SSMS'de açıp çalıştırın
```

### 2. Yedek Dizinlerini Oluşturun

**PowerShell'de (Administrator) aşağıdaki komutları çalıştırın:**

```powershell
# Tam yedek dizini
New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Full" | Out-Null

# Diferansiyel yedek dizini
New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Diff" | Out-Null

# Oluşturulup oluşturulmadığını kontrol edin
Get-Item "C:\SQLBackups\Northwind\Full"
Get-Item "C:\SQLBackups\Northwind\Diff"
```

---

## SCRIPT ÇALIŞTIRMA SIRASI

SQL Server Management Studio (SSMS) veya Azure Data Studio'da **sırasıyla** aşağıdaki scripti çalıştırın:

| # | Dosya | Açıklama | Ön Koşul |
|---|-------|---------|----------|
| 1 | **01_prepare_environment.sql** | Ortamı kontrol et, tabloların varlığını doğrula | Northwind kurulu olmalı |
| 2 | **02_check_recovery_model.sql** | Mevcut kurtarma modelini kontrol et | - |
| 3 | **03_set_recovery_model.sql** | SIMPLE kurtarma modeline ayarla | - |
| 4 | **04_full_backup.sql** | Tam yedek al | Yedek dizini oluşturulmalı |
| 5 | **05_differential_backup.sql** | Diferansiyel yedek al | Tam yedek alınmış olmalı |
| 6 | **06_log_backup.sql** | T-Log yedeklerinin neden kullanılmadığını açıkla | - |
| 7 | **07_verify_backup_history.sql** | Yedekleri doğrula | - |
| 8 | **08_restore_test.sql** | Yedekten test veritabanına geri yükle | Tam yedek alınmış olmalı |
| 9 | **09_validation_queries.sql** | Geri yüklemenin doğruluğunu kontrol et | Test restore tamamlanmış olmalı |

---

## YAŞANABIALECK SORUNLAR VE ÇÖZÜMLERI

### Hata: "Dizin mevcut değil"
```
Msg 3201, Level 16, State 1, Server SQLSERVER, Line X
Cannot open backup device 'C:\SQLBackups\Northwind\Full\...'
```
**Çözüm:** Yedek dizinlerini PowerShell'de oluşturun (yukarıdaki adım 2)

### Hata: "Tam yedek bulunamadı"
```
Msg 50000, Level 16, State 1
HATA: Northwind icin tam yedek bulunamadi. Once 04_full_backup.sql calistirin.
```
**Çözüm:** Önce `04_full_backup.sql` dosyasını çalıştırın

### Hata: "Veritabanı açılmıyor"
```
Msg 3609, Level 16, State 2
Cannot drop database "Northwind" because it is currently in use.
```
**Çözüm:** SQL Server'i yeniden başlatın veya SSMS'teki tüm bağlantıları kapatın

---

## BACKUP DOSYALARI NEREDE?

Yedek dosyaları aşağıdaki yerlerde bulunur:
- **Tam yedekler:** `C:\SQLBackups\Northwind\Full\`
- **Diferansiyel yedekler:** `C:\SQLBackups\Northwind\Diff\`

---

## NOTLAR

- Tüm scriptler **Turkish** yorumlar içerir
- SIMPLE recovery modeli kullanılmıştır (T-Log yedekleri YOK)
- Test restore ayrı bir veritabanına yapılır (`Northwind_RestoreTest`)
- Orijinal Northwind veritabanı hiçbir zaman silinmez

✅ Hazır oldunuz! İlk script ile başlayın.
