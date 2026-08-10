# Orin — Elmi Strategiya Sənədi

> Ad: **Orin** (uydurma, sahib olunan; mövcudluq-skrininqdən keçib). iOS ingilis dili öyrənmə appı.
> Prinsip: **əvvəl insana real fayda, sonra gəlir.** Metriklərimiz həqiqi dil mənimsəməsini ölçür — engagement-i yox.
> Bu sənəd `deep-research` araşdırmasının (23 mənbə, 25 iddia adversarial yoxlanılıb) nəticəsinə əsaslanır. Hər iddianın yanında **sübut gücü** göstərilib.

---

## 0. Bir cümlədə

Duolingo-nun səhvi metod deyil — **ölçdüyü şeydir**. O, "app-da keçirilən vaxtı" optimallaşdırır; biz **dəqiqliyi və proqres səviyyəsini** optimallaşdıracağıq. Elm deyir: sürətli və davamlı öyrənmə iki mexanizmə söykənir — **retrieval practice (aktiv xatırlama)** və **spaced repetition (intervallı təkrar)** — üstəlik **çoxlu kontakt saatı + real istehsal (danışıq/yazı)**. App bunların hamısını qura bilər, yalnız "kontakt saatı"nı qismən əvəz edə bilər.

---

## 1. Elmi Təməl — nə işləyir (sübutla)

### 1.1 Ən güclü sübut (birbaşa app-a qurula bilər)

| Mexanizm | Effekt | Sübut gücü | App-a nə deyir |
|---|---|---|---|
| **Retrieval practice** (aktiv xatırlama / test effekti) | Təkrar-oxumaqdan güclü üstün: g≈0.51 (vs restudy), g≈0.93 (vs heç nə). 272 effekt, 188 eksperiment | 🟢 Çox güclü (3-0) | Passiv baxış YOX. Hər element **yadda saxlama testi** kimi verilməli — "gördüm" yox, "xatırladım" |
| **Spaced repetition** (intervallı təkrar) | Massed-dən g=0.74 güclü. **Genişlənən (expanding) intervallar bərabər intervaldan yaxşı DEYİL** (g=0.034, əhəmiyyətsiz) | 🟢 Çox güclü (3-0) | Sadə, dürüst SRS kifayətdir. Mürəkkəb "sehrli" alqoritm reklamı lazım deyil — FSRS/SM-2 nüvəsi + sadə intervallar |
| **SRS real L2-də işləyir** (Anki, 62 tələbə, İspan) | Çox Anki istifadəsi = yüksək nəticə (baza qabiliyyət, motivasiya nəzarətdə) | 🟢 Güclü (3-0), amma korrelyativ | SRS işləyir — **AMMA** eyni tədqiqat: istifadəçilər onu **sevmir** ("acı dərman"). Adherence = əsas dizayn problemi |

**Kritik nəticə:** SRS + retrieval işləyir, amma **darıxdırıcıdır və istifadəçilər tərk edir.** Bizim əsl mühəndislik problemi: *elmi metodu istifadəçinin gözü qarşısında saxlamaq* — onu şəkərləyib boşaltmadan.

### 1.2 Sübutu zəif / qarışıq olan (ehtiyatla)

- **Mobil söz app-larının effekti şişirdilib.** Reklam "d=1.28" iddiası **RƏDD edildi** (publication bias). Düzəlişdən sonra g=0.74 — hələ də mənalı, amma marketinq rəqəmləri deyil. → **Öz iddialarımızda dürüst və təvazökar ol.**
- **Danışıq/tələffüz texnologiyası (ASR/CAPT):** ASR + peer düzəliş böyük qazanc verdi (comprehensibility partial η²=0.251, böyük effekt) — 🟢 amma tək kiçik tədqiqat (N=61), ASR-ı peer düzəlişlə qarışdırır. **Avtomatik tələffüz qiymətləndirməsi hələ insan səviyyəsindən uzaqdır** (30 CAPT tədqiqatı icmalı) və çox vaxt "yenilik oyuncağı" kimi əlavə edilir. → Danışıq funksiyası qur, amma **avtomatik balı "təxmini" kimi çərçivələ**, pedaqoji dizayn et, gimmick etmə.

### 1.3 Araşdırmada TƏSDİQLƏNMƏYƏN (brief-də istənilib, amma sübut tapılmadı)

Bunlar **yanlış demək deyil** — sadəcə bu araşdırma turunda yoxlanmış sübut çıxmadı. Dizayn qərarında "elmlə sübutlanıb" demə, "geniş qəbul edilən praktika" de:

- Krashen comprehensible input / i+1 (qeyd: bir mənbə "input **lazımdır amma kifayət deyil**" dedi — Lightbown 2002; yazı+danışıq əlavə edən qruplar yalnız input alanları üstələdi)
- Swain output hypothesis
- Ebbinghaus əyrisi, SM-2/FSRS spesifikasiyaları
- Interleaving, dual coding, phonological loop
- Critical period / böyük yaşda neyroplastika
- Chunking / collocations / formulaic sequences
- Shadowing, yuxu-konsolidasiyası

> **Qeyd:** Comprehensible input və tezlik-Pareto **ikinci turda təsdiqləndi** — bax §1.4. Qalan boşluqlar §8-də.

### 1.4 İkinci tur — təsdiqlənmiş (konkret dizayn rəqəmləri)

İkinci `deep-research` turu (24 mənbə, 25 iddia — hamısı 3-0 təsdiqləndi) iki təməl sualı **ölçülə bilən rəqəmlərlə** bağladı:

**A) Comprehensible input — işləyir, amma Krashen-in dəqiq "i+1"-i yox** 🟢
- Krashen-in **i+1 mexanizmi empirik cəhətdən zəifdir** və "qeyri-təstiqlənə bilən/qeyri-dəqiq" kimi tənqid olunur (Gregg 1984, McLaughlin 1987). Input **lazımdır, amma kifayət deyil** — istehsal + qarşılıqlı əlaqə (Long, Swain) lazımdır. Bu, bizim hibrid döngəni (input **+** output) təsdiqləyir.
- **Extensive reading işləyir, amma orta effektlə:** Nakanishi (2015) meta-analiz, d=0.46 (qruplararası). "Sehr" deyil, sabit fayda.
- **Əməli operasionallaşdırma — lexical coverage:** mətnin çətinliyini öyrənənin bildiyi sözlərin faizi ilə ölç:
  - **~95% coverage** = minimal/dəstəklənmiş anlama (Laufer 1989)
  - **~98% coverage** = adekvat/müstəqil anlama (Hu & Nation 2000; 50 sözdən 1-i naməlum)
  - ⚠️ **Heç bir həddi hamı üçün zəmanət vermir** (Kremmel et al. 2023 replikasiyası 98%-i tam təkrarlaya bilmədi) — fon bilik, oxu bacarığı, mətn tipi də rol oynayır. → coverage-i **fərdiləşdir**.

**B) Tezlik-Pareto — empirik cəhətdən möhkəm** 🟢 (Nation 2006, Laufer & Ravenhorst-Kalovski 2010, Rodgers & Webb 2022)

| Söz ailəsi (word family) | Yazılı mətn coverage | Danışıq coverage |
|---|---|---|
| İlk 1,000 | ~78-81% | — |
| İlk 2,000 | ~88-90% | ~90% (qeyri-rəsmi danışıq) |
| ~3,000 (+xüsusi isimlər) | **~95%** | 95% (scripted dialog) |
| 4,000-5,000 | 95%+ | 98% (scripted dialog) |
| 6,000-7,000 | — | **98%** (danışıq) |
| 8,000-9,000 | **98%** | — |

- **Praktik nəticə:** İlk **~3,000 söz ailəsi = 95% coverage** — bu, appın **A1→B1 onurğası** olmalı. 98% müstəqillik üçün 8-9k lazımdır (uzunmüddətli hədəf).
- **Media asandır:** film/serial üçün 95% cəmi 2,000-3,000 sözdə çatılır → **graded video/audio məzmun** güclü giriş nöqtəsidir.
- ⚠️ **Sayma vahidi mübahisəlidir:** word family vs lemma vs flemma — mütləq rəqəmləri dəyişir (Nation BNC/COCA Level 6 vs Level 3). App bir vahid seçib ardıcıl saymalıdır (§8-ə köçdü).

### 1.5 Tələffüz / danışıq AI — dördüncü tur (nəhayət təsdiqləndi 🟢)

Standart benchmark **Speechocean762** (5000 ifadə, Mandarin-L1 danışanlar, yarısı uşaq — ona görə **aksent/yaş meyli** qeydi var). Avtomatik qiymətləndirmənin insan qiymətçiləri ilə uyğunluğu (PCC) **nəyi ölçdüyündən çox asılıdır** — bu, dizaynın açarıdır:

| Nə ölçülür | İnsan-uyğunluq (PCC) | Etibarlılıq |
|---|---|---|
| **Cümlə-səviyyə fluency/prosody** | ~0.75–0.78 (ən yaxşı SSL ~0.82) | 🟢 Yaxşı (amma mükəmməl yox) |
| **Fonem-səviyyə (segmental)** | ~0.61, ən yaxşı ~0.69 | 🟡 Orta |
| **Söz vurğusu (suprasegmental)** | ~0.15–0.33 | 🔴 Zəif |
| Klassik GOP (köhnə metod) | ~0.25–0.45 | 🔴 Zəif |

**Kritik nəticələr app üçün:**
1. **Ən etibarlı tier = ümumi fluency/comprehensibility** (cümlə səviyyə). Feedback-i buna yönəlt — "başa düşülən danışdın" tipli.
2. **Vurğu/intonasiya balına GÜVƏNMƏ** — maşınlar burada zəifdir (yarı və ya az korrelyasiya). Suprasegmental "bal" vermə; ən çoxu **nümunə ilə müqayisə/shadowing** təklif et.
3. **Ümumi LLM-lər (GPT-4o) hələ ixtisaslaşmış scorer-i əvəz etmir** — fonem PCC ~0.21-0.24, ~48% qiymətləndirilməmiş. AI söhbət partnyoru **məzmun/danışıq təcrübəsi** üçün əla, amma dəqiq tələffüz balı üçün yox.
4. **Kommersiya API-ləri belə (Azure) yalnız orta korrelyasiya** verir (Won 2025, müstəqil tədqiqat); Kaldi GOP praktiki əlaqəsiz. Vendor reklamına inanma.
5. **iOS reallığı:** Apple `SFSpeechRecognizer` yalnız **transkripsiya** edir — daxili fonem/tələffüz balı YOX. Real tələffüz balı **cloud API** (Azure və s.) tələb edir. Prototipdəki söz-tanıma yanaşması **transkripsiya-əsaslıdır** (tələffüz keyfiyyəti yox, "sözlər başa düşüldümü").

➡️ **Prototipdəki "təxmini bal" çərçivəsi düzgündür və elmi cəhətdən təsdiqləndi.** Avtomatik bal öyrənənə **təxmini istiqamət kimi** verilməli, "hökm" kimi yox.

---

## 2. Elit Proqramlardan Dərslər (FSI / DLI / Middlebury)

Əsas kəşf: **"gizli metod" yoxdur.** Elit sürət = **kontakt saatı + tam hədəf-dil immersiyası + çətinliyə uyğun templə**.

- **DLI (ABŞ Müdafiə Dil İnstitutu):** həftədə 5 gün, **gündə 7 saat** dərs + gecə 2-3 saat ev tapşırığı. Dil çətinliyinə görə 36-64 həftə (Ərəb/Mandarin/Koreya = 64, Rus = 48). 🟢 (3-0). *Diqqət:* "DLI izolyasiya edilmiş, ingiliscə qadağan facility" iddiası **RƏDD edildi (0-3)** — DLI-nin leveri intensivlik/saatdır, "language pledge" deyil.
- **Middlebury:** imzalanmış **Language Pledge** — 7-8 həftə boyu yalnız hədəf dildə ünsiyyət (dərsdən kənar da). "1 illik universitet təhsilinə bərabər" iddiası yalnız 2-1 keçdi → **öz daxili qiymətləndirmələri**, müstəqil ölçmə yox. Atribusiya et, "sübut" demə.
- **FSI (kontekst, journal-dan):** Kateqoriya I dillər (İspan/Fransız) ≈ 575-600 saat → "Professional Working Proficiency" (ILR S-3/R-3 ≈ CEFR B2/C1). İngilis dilində-analoq: **B2-yə real çatmaq yüzlərlə saat tələb edir** — heç bir app "30 saatda axıcı" vəd etməməlidir.

**App-a tərcümə:** Dominant lever **time-on-task**-dır. Deməli app-ın işi istifadəçini *daha çox keyfiyyətli saat* toplamağa çəkməkdir — amma "vaxt" metrikasını **məqsəd** yox, **nəticənin girişi** kimi görmək (aşağı §5).

---

## 3. Duolingo Tənqidi — nə ETMƏMƏLİ

- **~27 saat İspan → yalnız ACTFL Novice-Mid → Novice-High** (ən aşağı bant). 🟢 (3-0, n=48). Yəni saatlarla oynamaq az mütləq nəticə verir.
- **Həftəlik app-vaxtı nəticəni proqnozlaşdırmadı; sessiya dəqiqliyi proqnozlaşdırdı.** Səbəb: istifadəçilər asan XP toplamaq üçün sessiyaları təkrarlayır. 🟢 (3-0). → **Vanity-metrik problemi sübutlu.**
- Gamified app-lar **əsasən başlanğıc lüğət + reseptiv (oxu/dinləmə) üçün** yaxşıdır; **istehsal (danışıq/yazı) və yüksək səviyyə üçün zəif**, çünki real, mənalı ünsiyyət yoxdur. 🟢 (3-0).
- Duolingo-nun effektivlik ədəbiyyatı **nazik və alət-mərkəzlidir** (nəticə deyil, feature ölçür). 🟢 (3-0).

**Fərqləndiricimiz aydınlaşır:**
1. Streak/XP əsas metrik OLMAYACAQ.
2. Real istehsal (danışıq/yazı) başlanğıcdan nüvədə olacaq — bu Duolingo-nun ən böyük boşluğudur.
3. İddialarımız təvazökar və dürüst olacaq.

---

## 4. Nüvə Öyrənmə Döngəsi (Hibrid Loop)

İstifadəçi qərarı: **hamısı vacib** (comprehensible input + danışıq/AI + SRS/tezlik). Elm bunları bir döngədə birləşdirməyi dəstəkləyir — hər biri digərinin boşluğunu doldurur:

```
        ┌─────────────────────────────────────────────┐
        │  1. INPUT (Anla)                            │
        │  Səviyyəyə uyğun (i+1) qısa audio+mətn      │
        │  hekayə/dialoq. Dual-coding: səs + vizual.  │
        └───────────────┬─────────────────────────────┘
                        ▼
        ┌─────────────────────────────────────────────┐
        │  2. RETRIEVAL (Xatırla)  ← ən güclü sübut   │
        │  Yeni söz/ifadələr aktiv xatırlama testi    │
        │  kimi. "Tanı" yox, "istehsal et".           │
        └───────────────┬─────────────────────────────┘
                        ▼
        ┌─────────────────────────────────────────────┐
        │  3. OUTPUT (Danış/Yaz)  ← Duolingo boşluğu  │
        │  Şadowing + ASR tələffüz + AI söhbət        │
        │  partnyoru ilə mənalı istehsal. Bal təxmini.│
        └───────────────┬─────────────────────────────┘
                        ▼
        ┌─────────────────────────────────────────────┐
        │  4. SCHEDULE (Planla)  ← ikinci güclü sübut │
        │  FSRS nüvəsi hər elementi düzgün intervalda │
        │  geri gətirir. Sadə intervallar kifayət.    │
        └───────────────┬─────────────────────────────┘
                        │  (növbəti gün / interval)
                        └──────────► 1-ə qayıt
```

**Vahid "element" modeli:** hər lüğət/ifadə/qrammatika bir *item*-dir və eyni FSRS cədvəlində yaşayır. İstər input-da görünsün, istər danışıqda çıxsın — hər uğurlu retrieval onun intervalını uzadır. Bu, dörd fəaliyyəti **bir yaddaş sisteminə** bağlayır (parçalanmış "dərslər" deyil).

---

## 5. Metriklər — real mənimsəmə vs vanity

Bu, appın əxlaqi və elmi nüvəsidir. Araşdırma birbaşa göstərir: **dəqiqlik nəticəni proqnozlaşdırır, vaxt/XP yox.**

| ❌ Vanity (rədd) | ✅ Real mənimsəmə (qəbul) |
|---|---|
| Gündəlik streak | **Retrieval dəqiqliyi** (ilk cəhddə düzgün xatırlama %) |
| Ümumi XP | **Möhkəm bilinən element sayı** (uzun intervala çatmış item-lər) |
| App-da keçən vaxt | **Aktiv lüğət** (istehsal edə bildiyin sözlər, tanıdığın yox) |
| Tamamlanmış dərs sayı | **Təxmini CEFR/ILR trayektoriyası** (dürüst, ölçülmüş) |
| | **Danışıq comprehensibility** (ASR, "təxmini" etiketi ilə) |

> Streak **tam qadağan deyil** — amma yalnız *vərdiş dəstəyi* kimi, arxa planda. Heç vaxt "uğur"un tərifi olmayacaq. İstifadəçi öz **real biliyini** görəcək, saxta proqres illüziyasını yox.

---

## 6. Curriculum Strukturu

1. **Tezlik-əsaslı onurğa (təsdiqləndi 🟢):** ən çox işlənən söz ailələrindən başla. Konkret hədəflər (Nation 2006):
   - **İlk ~3,000 söz ailəsi = 95% coverage** → appın **A1→B1 nüvəsi**. Bu, "əsas gündəlik ingiliscə"ni açan Pareto zonasıdır.
   - **8,000-9,000 = 98%** (müstəqil oxu) → uzunmüddətli B2→C1 hədəfi.
   - Hər söz **kontekst içində**, tək-tək yox (collocations/chunks).
2. **Graded comprehensible input (təsdiqləndi 🟢):** məzmunu **lexical coverage** ilə səviyyələ:
   - Öyrənənin bildiyi sözlərə görə mətn seç: **95% coverage = dəstəklənmiş**, **98% = müstəqil** anlama.
   - **Media asandır** (film/serial 95% cəmi 2-3k sözdə) → graded video/audio güclü başlanğıc.
   - Coverage-i **fərdiləşdir** — tək həd hamı üçün işləmir (Kremmel 2023).
3. **SRS nüvəsi — FSRS (tur 3-də təsdiqləndi 🟢):** production-da **FSRS** seç (DSR modeli: Difficulty, Stability, Retrievability). Benchmark-də (727M təkrar, 10k istifadəçi) FSRS **istifadəçilərin 99.6%-ində SM-2-dən daha yaxşı kalibrləşir**. ⚠️ **Dürüstlük:** (a) bütün sübut layihənin **öz benchmark**-ıdır, müstəqil peer-review yoxdur — istiqamət möhkəm, dəqiq marjlar metodologiyadan asılı; (b) "20-30% az təkrar" rəqəmi **simulyasiyadır, canlı A/B deyil** — modelləşdirilmiş təxmin kimi təqdim et; (c) FSRS-in üstünlüyü **hər kartın vaxtının düzgün kalibrləşməsindəndir, "genişlənən interval sehri"ndən deyil** — bu, tur 1 tapıntısı ilə (expanding ≈ uniform) uyğundur. İcra: hazır açıq mənbə kitabxana (`ts-fsrs`, `py-fsrs`, `rs-fsrs`). Prototipdəki SM-2-vari scheduler yalnız demo üçün.
4. **İstehsal mərhələləri:** hər input bloku danışıq/yazı çıxışı ilə bağlanır (input **lazımdır amma kifayət deyil** — təsdiqləndi 🟢).
5. **Dürüst səviyyə xəritəsi:** CEFR A1→B2, hər səviyyə üçün real saat gözləntisi (FSI reallığı: yüzlərlə saat).

---

## 7. MVP Əhatəsi (Prototip — Addım 3)

Növbəti addımda quracağımız **SwiftUI prototipi** tam appı yox, **bir öyrənmə döngəsini** ekranda canlandıracaq:

- Bir "item" seti üzərində **Input → Retrieval → (sadə) Output → Schedule** döngəsi
- İşləyən **FSRS-vari planlama** (sadələşdirilmiş)
- **Real-mənimsəmə metrik paneli** (dəqiqlik, möhkəm item-lər) — streak/XP YOX
- Danışıq: iOS `Speech` framework (on-device ASR) ilə bir shadowing/tələffüz ekranı — bal "təxmini" etiketli

Məqsəd: **konsepsiyanı əldə hiss etmək** və hibrid döngənin təbii olub-olmadığını görmək.

---

## 8. Açıq Suallar

✅ **BAĞLANDI:** Comprehensible input / i+1 (§1.4-A), Tezlik-Pareto (§1.4-B) — tur 2. **FSRS vs SM-2** (§6.3) — tur 3. **Tələffüz/danışıq AI** (§1.5) — tur 4: PCC rəqəmləri, iOS reallığı, "təxmini bal" çərçivəsi təsdiqləndi.

⏳ **Hələ açıq (ikinci dərəcəli):**

1. **SpeechAce / ELSA müstəqil dəqiqliyi** — yalnız Azure üçün müstəqil PCC var; digər kommersiya sistemlərinin vendor-dan kənar rəqəmi tapılmadı.
2. **Cross-accent / real-cihaz robustluğu** — bütün rəqəmlər Mandarin-L1 (yarısı uşaq) oxu-korpusundandır; başqa aksentlər, böyüklər, səs-küylü audio üçün kəmiyyət yoxdur.
3. **LLM danışıq tutorlarının ölçülmüş öyrənmə qazancı** — scoring dəqiqliyi məlumdur, amma kontrollu learning-gain nəticələri (təkcə qavrayış yox) hələ təsdiqlənməyib.
4. **FSRS müstəqil A/B** — canlı sınaq (simulyasiya yox) hələ yoxdur; "20-30%" modelləşdirilmiş qalır.
5. **FSRS interval formula/default** — dəqiq formula iddiası tur 3-də rədd edildi; kitabxana istifadə etsək, bu həll olunur.
6. **Sayma vahidi** (word family vs lemma) və **coverage fərdiləşdirmə** (Kremmel 2023) — mühəndislik qərarları.

---

## 9. Mənbələr (yoxlanılmış, primary üstünlüklə)

- Adesope, Trevisan & Sundararajan (2017), *Review of Educational Research* 87(3) — retrieval practice meta-analiz
- Latimier, Peyre & Ramus (2020), *Educational Psychology Review* — spacing meta-analiz
- Seibert Hanson & Brown (2020), *CALL* 33(1-2) — Anki L2 tədqiqatı
- Smith, Jiang & Peters (2024), *Language Learning & Technology* 28(1) — Duolingo nəticə tədqiqatı
- Loewen et al. (2021), *CALL* — Duolingo ədəbiyyat icmalı
- Fitriani (2024), *Curricula* 3(2) — gamified app sistematik icmal
- Middlebury Language Schools — Language Pledge (rəsmi)
- DLIFLC.edu — DLI proqram sənədləri (rəsmi)
- CAPT sistematik icmal (2024), *ReCALL*/Cambridge
- ASR+peer tədqiqatı (2023), *Frontiers in Psychology* / PMC10469312
- Mobil lüğət meta-analiz, *ReCALL*/Cambridge (publication bias düzəlişi)

**İkinci tur (input & tezlik):**
- Nakanishi (2015), *TESOL Quarterly* 49(1) — extensive reading meta-analiz (d=0.46)
- Hu & Nation (2000), *Reading in a Foreign Language* — 98% coverage həddi
- Kremmel et al. (2023), *Language Learning* 73(4) — Hu & Nation replikasiyası
- Nation (2006), *Canadian Modern Language Review* 63(1) — vocabulary size / coverage
- Laufer & Ravenhorst-Kalovski (2010) — 95%/98% coverage bantları
- Rodgers & Webb (2022), PMC8899723 — media/scripted dialog coverage
- Nguyen & Doan (2025), *Frontiers in Psychology* — i+1 tənqidi
- Nation BNC/COCA list documentation (Victoria U. Wellington) — word family tərifi

**Üçüncü tur (FSRS & scheduler):**
- open-spaced-repetition / srs-benchmark (GitHub) — 727M təkrar benchmark (layihənin öz benchmark-ı)
- open-spaced-repetition / free-spaced-repetition-scheduler, fsrs4anki wiki — DSR modeli
- supermemo.guru — üç-komponentli yaddaş modeli (Wozniak)
- Karpicke & Roediger (2007), *J. Exp. Psychol. LMC* — expanding vs equal intervals
- Kang et al. (2014), *Psychonomic Bulletin & Review* — 8-həftəlik expanding=equal ekvivalentlik

**Dördüncü tur (tələffüz/danışıq AI):**
- Zhang et al. (2021), Interspeech — Speechocean762 benchmark korpusu
- Gong et al. (GOPT, 2022), arXiv 2205.03432 — transformer pronunciation scoring (fonem PCC 0.612)
- Kim et al. (2022), Interspeech / arXiv 2204.03863 — SSL (HuBERT/wav2vec2) utterance scoring
- Chao et al. (2023), Interspeech — ən yaxşı fonem PCC ~0.69
- arXiv 2503.11229 — GPT-4o pronunciation scoring (ixtisaslaşmışdan zəif)
- Won (2025), *Journal of Second Language Pronunciation* — Azure vs insan (müstəqil)

---

*Sənəd versiyası 1.3 — deep-research 4 tur (wf_5ec637bc + wf_7d5eb4d2 + wf_7c328ad9 + wf_3013c3e7). SwiftUI prototip: coverage-graded reader + tezlik onurğası + sadiq FSRS scheduler (`../ios/`). Əsas elmi suallar bağlandı; qalan açıqlar ikinci dərəcəlidir (§8).*
