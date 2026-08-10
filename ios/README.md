# Orin — iOS Prototip

Bu, [strategiya sənədindəki](../docs/01-STRATEGY.md) **nüvə öyrənmə döngəsini** göstərən işləyən SwiftUI prototipidir:

```
Anla (Input) → Xatırla (Retrieval) → Danış (Output) → Nəticə (Metrics)
```

Fərqləndirici: **streak/XP yoxdur** — yalnız real-mənimsəmə metrikaları (xatırlama dəqiqliyi, möhkəm bilinən elementlər, aktiv lüğət).

## Nə göstərir

| Ekran | Elmi əsas |
|---|---|
| **Anla** | Comprehensible input — açılışda **coverage-graded reader**: öyrənənin səviyyəsinə uyğun passage seçilir, coverage % və naməlum sözlər göstərilir (95%/98% həddi, Hu & Nation 2000). Sonra sözlər kontekstdə, TTS audio ilə (dual-coding) |
| **Xatırla** | Retrieval practice (🟢 ən güclü sübut) — cavabı açmadan əvvəl aktiv xatırlama, sonra self-grade |
| **Danış** | Output + shadowing, on-device ASR ilə **təxmini** tələffüz siqnalı (dürüst çərçivə) |
| **Nəticə** | Real metriklər (dəqiqlik, möhkəm item, **~söz ailəsi**, oxu-coverage) + virtual "növbəti gün" |

**Coverage mühərriki (yeni):** `CoverageEngine` mətnin çətinliyini öyrənənin bildiyi sözlərin faizi (lexical coverage) ilə ölçür və graded kitabxanadan **öyrənmə zonasına (95–98%)** düşən passage seçir. Öyrənən söz öyrəndikcə `knownWords` böyüyür və daha çətin passage-lar açılır — tezlik onurğası ilə birləşir (Nation 2006: ~3000 söz ailəsi = 95% coverage).

Planlama: `FSRSScheduler` — sadiq (amma sadələşdirilmiş) **FSRS-4.5 / DSR modeli**: Difficulty, Stability, Retrievability + power-law unutma əyrisi, FSRS-4.5 default çəkiləri ilə. Data üzərində refit edilməyib (production-da `ts-fsrs`/`py-fsrs` istifadə et — onlar fitlənmiş parametrlərlə gəlir və istifadəçiyə görə fərdiləşir). Yoxlanılıb: "Good" təkrarı → stability 2.4→10→39d (mastery), interval-lar məntiqli genişlənir.

## Qurulum (Mac + Xcode lazımdır — Windows-da işləməz)

Bu server Windows-dur, ona görə kod burada kompilyasiya olunmayıb. Mac-də:

1. Xcode → **New Project → iOS → App**
   - Product Name: `Orin`
   - Interface: **SwiftUI**, Language: **Swift**
   - Minimum deployment: **iOS 17.0** (kod `@Observable`/`@Bindable`/SwiftData istifadə edir)
2. Yaradılan `ContentView.swift` və `OrinApp.swift` fayllarını sil (bu qovluqdakılarla əvəz olunacaq).
3. Bu qovluqdakı `Orin/` altındakı bütün `.swift` fayllarını (Models, Persistence, ViewModels, Views, Speech qovluqları ilə) layihəyə **Add Files** et.
4. `Resources/Content/vocab.json`-u da **Add Files** et — Xcode-un fayl seçim dialoqunda **"Create folder references"** seç (mavi qovluq işarəsi, sarı "group" yox), çünki `ContentStore` faylı `subdirectory:"Content"` altında axtarır. (Səhvən "group" kimi əlavə etsən də kod hələ işləyəcək — `ContentStore.loadVocab()` subdirectory-siz axtarışa da fallback edir.)
5. **Info.plist icazələri** (App target → Info tab → əlavə et):
   - `Privacy - Speech Recognition Usage Description` → `Tələffüzünüzü qiymətləndirmək üçün nitq tanıma istifadə olunur.`
   - `Privacy - Microphone Usage Description` → `Səsli təkrar (shadowing) üçün mikrofon lazımdır.`
6. Danışıq funksiyası **real cihazda** işləyir (simulyatorda mikrofon məhduddur). Qalan hər şey simulyatorda işləyir.
7. Run (⌘R). İlk açılışda 3828 sözün hamısı yüklənməlidir (Ana səhifədə "N element hazırdır" göstərilir).

**Checkpoint (Faza 1):** tam sessiya keç (Anla→Xatırla→Danış→Nəticə), app-ı force-quit edib yenidən aç — xal/təkrar tarixçəsi qalmalıdır (SwiftData). Ayarlar-da dili dəyişdikdə söz izahları (gloss) dərhal yenilənməlidir (relaunch lazım deyil).

## Fayl strukturu

```
Orin/
├── OrinApp.swift                # Giriş nöqtəsi: SwiftData container + store-lar + tab kökü
├── Models/
│   ├── LearningItem.swift       # Runtime vahid (məzmun+schedule) + RecallGrade
│   ├── VocabItem.swift          # Statik JSON-content struct + ContentStore (bundle-dan yüklənir)
│   ├── LocalizationStore.swift  # Aktiv lüğət dili + tərcümə-dict həll etmə
│   ├── FSRSScheduler.swift      # Sadiq (sadələşdirilmiş) FSRS-4.5 / DSR modeli
│   ├── LearningStore.swift      # @Observable — vahid mənbə + metriklər + SwiftData persistensiyası
│   ├── CoverageEngine.swift     # Lexical coverage + passage seçimi (95/98%)
│   ├── ReadingPassage.swift     # Graded reader kitabxanası (hələ nümunə, Faza 3-də əvəzlənəcək)
│   └── SampleContent.swift      # base known vocabulary (FSRS "artıq bilinən sözlər" bazası)
├── Persistence/
│   ├── VocabProgress.swift      # @Model — hər sözün FSRS vəziyyəti (yalnız baxılmış sözlər)
│   └── UserProfile.swift        # @Model — tək sətir: xal/streak/virtualDay/dil/hədəf
├── Resources/Content/
│   └── vocab.json               # export_ios_content.py çıxışı — 3828 söz, 9 dil
├── ViewModels/
│   └── SessionViewModel.swift   # Bir döngə keçidini idarə edir
├── Speech/
│   ├── SpeechRecognizer.swift   # On-device ASR (Output mərhələsi)
│   └── Speaker.swift            # TTS (Input mərhələsi)
└── Views/
    ├── OrinTabView.swift        # Kök: Öyrən/İrəliləyiş/Ayarlar tab-ları
    ├── ContentView.swift        # "Öyrən" tab: ana səhifə + mərhələ zolağı
    ├── SettingsView.swift       # Dil seçimi + hədəf
    ├── ReadingView.swift        # Coverage-graded reader (naməlum sözlər işıqlanır)
    ├── InputStageView.swift
    ├── RetrievalStageView.swift
    ├── OutputStageView.swift
    └── MetricsDashboardView.swift  # Metriklər + Nəticə ekranı
```

Məzmun yeniləmə: `Orin/tools/export_ios_content.py` (Windows-da işlədilir, `PythonEmbed312\python.exe export_ios_content.py`) `web/index.html`-dən CONTENT + 8 LP.<lang>.vocab paketini çıxarıb `vocab.json`-u yenidən yazır — söz sayı/tərcümə dəyişəndə təkrar işlət və Xcode-da faylı yenilə.

## Bilərəkdən sadələşdirilmiş (növbəti fazalar — bax layihə planı)

- **Virtual saat:** əsl tarixlər yox, "gün" sayğacı — bu, DEMO qısaltması deyil, **veb appın özünün production dizaynı** ilə eynidir (`state.virtualDay`/`advanceDay()`, bax `01-STRATEGY.md` §7) — qəsdən dəyişdirilməyib.
- **Planlayıcı:** FSRS-4.5 struktur sadiqdir, amma default çəkilərlə (data üzərində refit yox) — production-da `ts-fsrs`/`py-fsrs` istifadə et, desired-retention istifadəçiyə açıq knob kimi.
- **Məzmun:** yalnız Lüğət (vocab) tam miqyaslıdır (3828 söz, 9 dil, persistensiya ilə). Qrammatika/Dinləmə/Vizual/Oxu/Yazı/AWL/İmtahan hazırlığı və Duel/Dostlar/Lider-bord/Push hələ Faza 2-5-dədir (bax `C:\Users\hamdfav\.claude\plans\mossy-tinkering-dove.md`).
- **ASR balı:** söz-üstüstədüşmə (crude). Real appda daha yaxşı tələffüz modeli, amma **həmişə "təxmini" çərçivədə** (araşdırma: avtomatik qiymətləndirmə hələ insan səviyyəsində deyil).
- **Davamlılıq (persistence):** SwiftData ilə əlavə olundu (yalnız `VocabProgress`+`UserProfile` — statik məzmun heç vaxt yazılmır).

---
*Strategiya: [01-STRATEGY.md](../docs/01-STRATEGY.md) · Araşdırma: deep-research 3 tur (wf_5ec637bc + wf_7d5eb4d2 + wf_7c328ad9) — retrieval/spacing, comprehensible input, tezlik-coverage, FSRS yoxlanılıb; tələffüz-AI hələ açıq.*
