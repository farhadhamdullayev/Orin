# Orin Duel API — quraşdırma və deploy

## 1. Yerli test (VPS-siz, bu maşında)

Python "embeddable" runtime artıq bu serverdə qurulu (bax [[python-embeddable-runtime]] memory):
`C:\Users\hamdfav\AppData\Local\Programs\PythonEmbed312\python.exe`

```powershell
cd "C:\CC\0. Pre-requirements\Orin\server"
# kataloqu (söz+qrammatika cavab açarı) index.html-dən çıxar/yenilə:
C:\Users\hamdfav\AppData\Local\Programs\PythonEmbed312\python.exe export_catalog.py
# serveri işə sal:
C:\Users\hamdfav\AppData\Local\Programs\PythonEmbed312\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Sonra `web/index.html`-i brauzerdə aç (fayl birbaşa açıla bilər, `API_BASE` artıq `http://127.0.0.1:8000`-ə işarə edir) — Ana səhifədə **"Yarış"** kartına toxun.

İki nəfərlik test üçün: eyni brauzerdə 2 fərqli profil/incognito tab (hər birinin öz `localStorage`-ı, deməli öz `deviceId`-si olsun) və ya 2 fərqli cihaz, ikisi də `http://<bu-kompüterin-yerli-IP>:8000`-ə çıxış edə bilməlidir (uvicorn-u `--host 0.0.0.0` ilə işə sal ki, lokal şəbəkədən əlçatan olsun).

## 2. Kataloqu yeniləmə qaydası

`export_catalog.py` CONTENT (söz+rank) və GRAMMAR (drill sual/variant/cavab) massivlərini `index.html`-dən çıxarıb `catalog_items` cədvəlinə yazır — **heç bir tərcümə mətni saxlanmır**, ona görə 8 dilin hamısı eyni kataloqla işləyir. CONTENT/GRAMMAR-a yeni söz/mövzu əlavə olunanda (və ya say dəyişəndə) bu skripti yenidən işə sal:

```powershell
python.exe export_catalog.py
```

(idempotent — hər dəfə `catalog_items` təmizlənib yenidən doldurulur; `duels`/`users` cədvəllərinə TOXUNMUR, mövcud lider-bord xalları qalır.)

## 3. VPS-ə real deploy (siz server aldıqdan sonra)

1. VPS-də Docker qurulu olmalıdır (`curl -fsSL https://get.docker.com | sh` əksər Linux dağıtımlarında kifayətdir).
2. Bu `server/` qovluğunu VPS-ə köçür (scp/rsync/git).
3. ```bash
   cd server
   docker compose up -d --build
   ```
   Bu, API-ni `:8000` portunda daimi işə salır (restart:unless-stopped), `./data/orin.db` volume-da saxlanır (SQLite WAL mode).
4. **HTTPS lazımdır** (brauzerlər `http://` API-yə `https://` səhifədən sərbəst fetch icazə vermir — mixed-content bloklanır). Tövsiyə: Caddy reverse-proxy (avtomatik Let's Encrypt sertifikatı):
   ```
   # Caddyfile
   api.sizin-domeniniz.com {
     reverse_proxy localhost:8000
   }
   ```
   `caddy run` — bir dəfə DNS A-record domeni VPS IP-sinə göstərsin, Caddy avtomatik HTTPS sertifikatı alır.
5. Kataloqu VPS-də də doldur: konteynerin içində və ya VPS-də ayrıca Python quraşdırıb eyni `export_catalog.py`-ni işlət (yol `../web/index.html`-ə uyğunlaşdırılmalıdır — `index.html`-in bir nüsxəsini VPS-ə köçür).
6. **`web/index.html`-də `const API_BASE=...` sətrini** `https://api.sizin-domeniniz.com`-a dəyişdirib faylı yenidən yayımla (Artifact-a YOX — bu funksiya yalnız self-host `index.html`-dədir).
7. **VAPID açarını YERLİ generasiya edib VPS-ə köçür, VPS-də TƏKRAR generasiya ETMƏ** — `vapid_private.pem` artıq yerli mühitdə yaradılıb (`server/vapid_private.pem`). Bu faylı olduğu kimi VPS-ə köçür (məs. `scp vapid_private.pem user@vps:/path/server/`). Əgər VPS-də yenidən `generate_vapid.py` işlədilsə, ƏVVƏLKİ bütün push abunəçiləri (istifadəçilərin brauzer-tərəfli push subscription-ları) etibarsız olar — onlar Ayarlar-da bildirişi yenidən aktivləşdirməli olar. `vapid_private.pem`-i `.gitignore`-a əlavə et (məxfi açardır, versiya-nəzarətinə düşməməlidir).
8. **`web/sw.js` faylı `index.html` ilə EYNİ qovluqda, eyni originda serve olunmalıdır** (push bildirişləri üçün service worker scope tələbi) — VPS-ə köçürəndə unutma.

## 4. Push bildirişlər (unutma-nöqtəsi xatırlatması)

- Backend saatda bir dəfə (`PUSH_CHECK_INTERVAL_SEC`, `main.py`) yoxlayır: kimin real `due_count`-u (client-in özü göndərdiyi FSRS unutma sayı) var, push abunəliyi var, və son 20 saatda ("bax `PUSH_MIN_GAP_HOURS`) nə bildiriş almayıb, nə app-ı açmayıb — yalnız bu şərtlərin hamısı doğrudursa push göndərilir. Heç bir "fake təcililik" YOXDUR — bax [[orin-duel-backend]] memory qeydi.
- Client tərəfində: `Settings()`-də "Xatırlatma bildirişləri" toggle-ı istifadəçidən açıq icazə istəyir (Notification.requestPermission()), sonra VAPID public key-i `/api/push/vapid_public_key`-dən alıb brauzerin PushManager-inə abunə olur.
- **Bu sessiyada YALNIZ backend-in özü (subscribe/unsubscribe/activity-sync endpoint-ləri) test edilib — HƏQİQİ push çatdırılması (real brauzerə real bildiriş) test EDİLMƏYİB**, çünki bu mühitdə real brauzer icazəsi/push xidməti əlaqəsi yoxlana bilmədi. VPS-ə köçürəndən sonra öz telefonunuzda "Xatırlatma bildirişləri"-ni aktivləşdirib bir gün gözləyərək (və ya `due_count`-u süni artırıb) real test etməyiniz tövsiyə olunur.

## 5. Bilinən V1 məhdudiyyətləri (qəsdən sadələşdirilib)

- Yalnız `index.html` (self-host) — `app.html` (Artifact) Duel/Dostlar/Lider-bord/Push funksiyalarını göstərmir, çünki Artifact-ın sandbox mühiti xarici `fetch()`/service-worker-ə icazə vermir. (AWL/Yazı/Oxu-mətnləri kimi network-siz funksiyalar HƏR İKİ faylda var.)
- Yalnız MCQ (seçim), sərbəst-mətn duel-cavabı yoxdur (Yazı məşqində sərbəst mətn var, amma bu, Duel-dən ayrı funksiyadır).
- Açıq (cavabsız qalan) duel-lər 30 dəqiqədən sonra yeni uyğunlaşdırmada təklif olunmur, amma silinmir (DB-də qalır, zərərsizdir).
- Push bildirişlərin mətni yalnız 9 dildə (az+8) əvvəlcədən yazılmış qısa şablondur (`REMINDER_TEXT`, `main.py`) — tam UI-tərcümə sisteminə bağlı deyil.
