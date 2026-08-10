# Orin — Sosial & Motivasiya Qatı (Dizayn Sənədi)

> Bu, §01-STRATEGY-nin davamıdır. İstifadəçi sosial/gamification funksiyaları istədi: reyting, dostları follow, söz oyunları, gündəlik xallar, aylıq/uzunmüddətli reyting, top 100, gün sonu səviyyə statusu, kontakt sinxronizasiyası.
>
> **Əsas prinsip (qırmızı xətt):** Bu qat missiyaya — *real fayda, saxta proqres yox* — sadiq qalmalıdır. Ona görə **xallar həcimdən/vaxtdan yox, real dəqiqlik və mənimsəmədən** gəlir. Duolingo-nun "vaxt-farming"inə qayıtmırıq.

---

## 0. Dürüstlük çərçivəsi (niyə vacibdir)

Araşdırma (§1, §3) göstərdi: leaderboard/XP/streak **engagement**-i artırır, amma **çox vaxt real öyrənmə ilə əlaqəsizdir** — Duolingo-nun tənqidi elə budur. Sənin ilk qayən reklam-gudmə yox, faydadır.

→ **Həll:** gamification-i **saxlamırıq deyə rədd etmirik** — onu *dürüst* edirik:
- Xal = **ilk-cəhd dəqiqliyi + möhkəm mənimsəmə** (retrieval accuracy, mastered items). "Asan sessiyanı 10 dəfə təkrarlayıb XP yığmaq" mümkün olmamalı.
- Reyting = **real bilik artımı**, təkcə aktivlik yox.
- Gün-sonu status = **real CEFR trayektoriyası** (uydurma rəqəm yox).

---

## 1. Gün-sonu səviyyə statusu (honest, İNDİ mümkün — backend'siz)

Hər günün sonunda: *"Bu gün: A2.3 → A2.4. +18 möhkəm söz, dəqiqlik 91%."*
- **Mənbə:** artıq mövcud metriklər — mastered items (stability≥21), recall accuracy, aktiv lüğət, coverage səviyyəsi.
- **CEFR təxmini:** aktiv söz ailəsi + coverage-ə əsaslanan honest xəritə (A1≈0.5-1k, A2≈1.5-2.5k, B1≈3-4k, B2≈5-6k — §1.4-B rəqəmləri ilə). "Təxmini" etiketi ilə.
- ⚠️ **Dürüst ol:** bir gündə CEFR bandı nadir hallarda dəyişir — mikro-proqres göstər (band içi %), şişirtmə.
- **Bu, client-side'dır** → PWA-da indi əlavə oluna bilər, server lazım deyil.

## 2. Xal modeli (anti-farming)

| Fəaliyyət | Xal | Qayda |
|---|---|---|
| İlk-cəhd düzgün retrieval | +bal | Yalnız **ilk cəhd** sayılır (təkrar-farming yox) |
| Yeni item mastery (stability≥21) | +bonus | Bir dəfə, item başına |
| Söz oyununda qazanma | +bal | Rəqibin səviyyəsinə görə çəkili |
| Gündəlik "keyfiyyət" hədəfi | +bal | Vaxt yox — **dəqiqlik≥X%** olan sessiya |

- **Streak varsa** yalnız yumşaq vərdiş-dəstəyi kimi, əsas metrik yox.
- **Anti-cheat:** xal serverdə hesablanır (client göndərdiyi xala güvənilmir); oyun nəticələri serverdə yoxlanılır.

## 3. Söz oyunu (1v1, follow edənlər arası)

**Mexanika:** söz/ifadə **ana dildə** verilir → oyunçu ya (a) ingiliscə **yazır**, ya da (b) **variantlardan seçir** (§ retrieval elmi ilə uyğun — aktiv istehsal).
- **Format:** növbəli (turn-based) — real-time şərt deyil (backend sadələşir). Hər raund N söz, hər ikisi eyni sözləri alır, düzgünlük + sürət xal verir.
- **Ədalət:** sözlər **hər iki oyunçunun səviyyəsinə uyğun** frekans bandından seçilir.
- **Öyrənmə dəyəri:** oyun elə **retrieval practice**-dir — yəni gamification həm də real öyrənmədir (missiyaya uyğun). Uduzulan sözlər öz SRS-inə əlavə olunur.

## 4. Follow & kontakt sinxronizasiyası (məxfilik-həssas)

**Follow sistemi:** istifadəçilər bir-birini axtarıb follow edir; qarşılıqlı follow → oyun oynaya bilər.

**Kontakt sinxronizasiyası — DİQQƏT (məxfilik):**
- iOS-da **yalnız native app** kontaktlara çıxa bilər (web yox) → bu funksiya native-i məcbur edir.
- **Opt-in məcburi:** istifadəçi açıq razılıq verməlidir; heç vaxt avtomatik yükləmə yox.
- **Privacy-preserving matching:** kontakt nömrələri **cihazda hash-lanır** (məs. SHA-256 + salt), yalnız hash-lar serverə gedir; server qeydiyyatlı istifadəçilərin hash-ları ilə tutuşdurur. **Xam nömrələr serverdə saxlanmır.**
- **Şəffaflıq:** "filan dostun Orin-dədir" təklifi yalnız qarşılıqlı razılıqla.
- Bu, GDPR/məxfilik baxımından həssasdır — düzgün siyasət + razılıq ekranı lazımdır.

## 5. Reytinq (leaderboard)

- **Aylıq reyting:** hər ay sıfırlanan xal (motivasiya, təzə start).
- **Uzunmüddətli (all-time):** ümumi yığılmış xal — "filan istifadəçi #N reytingdə".
- **Top 100:** qlobal maksimum + dostlar arası (follow) mini-leaderboard (daha mənalı motivasiya).
- **Honest sıralama:** xal real-mənimsəmədən gəldiyi üçün reyting "kim daha çox öyrənib"i əks etdirir, "kim daha çox vaxt itirib"i yox.

---

## 6. Memarlıq — nə lazımdır (böyük sıçrayış)

Bu qat **static PWA-nı aşır.** Lazım olanlar:

| Komponent | Nə üçün |
|---|---|
| **Backend API** (server) | Hesablar, xal hesablama, oyun məntiqi, leaderboard |
| **Verilənlər bazası** | İstifadəçi, xal, follow qrafiki, oyun tarixçəsi, SRS state (bulud sinxron) |
| **Autentifikasiya** | Hesab (Apple Sign-in tövsiyə — məxfilik), sessiya |
| **Turn-based oyun servisi** | Oyun növbələri, nəticə yoxlama (anti-cheat) |
| **Native iOS app** | Yalnız kontakt sinxronizasiyası üçün (web bacarmır) |
| **Push bildiriş** | "Rəqibin növbə etdi", gün-sonu status — motivasiya |

**Texnologiya təklifi (sonra dəqiqləşdirilər):** managed backend (məs. Supabase/Firebase — auth+DB+realtime hazır, sürətli MVP) → sonra öz serverinə köçmə. Frontend: PWA (əsas öyrənmə) + native (kontakt/push).

---

## 7. Fazalı plan

1. **Faza 1 (indi, backend'siz):** Gün-sonu **honest səviyyə statusu** + lokal xal (client-side) → PWA-ya əlavə. Motivasiyanı missiyaya sadiq başlat.
2. **Faza 2 (backend):** Hesablar + bulud sinxron + **aylıq/all-time leaderboard** (əvvəl fərdi, sonra qlobal).
3. **Faza 3 (sosial):** **Follow** + **turn-based söz oyunu** + dostlar-leaderboard.
4. **Faza 4 (native + kontakt):** Native app-da kontakt matching (məxfilik-qoruyucu) + push. Ən həssas, ən sonda.

> **Qeyd:** Faza 2+ real infrastruktur (server, DB, xərc) və çox güman native app tələb edir. Bu, "static web-app" mərhələsindən "full-stack sosial məhsul"a keçiddir — planlaşdırılmış qərar olmalıdır.

---
*Sənəd versiyası 1.0. Növbəti: Faza 1 (honest gün-sonu status) PWA-ya, sonra backend memarlıq qərarı.*
