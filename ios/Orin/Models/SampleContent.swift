import Foundation

enum SampleContent {
    /// The vocabulary a beginner is assumed to already know — roughly the
    /// highest-frequency function and everyday content words (the "first ~1,000
    /// families" band). Coverage of graded passages is measured against this.
    /// Deliberately EXCLUDES the harder content words the graded readers hinge
    /// on (quiet, catch, although, figure, schedule, postpone, compromise, …)
    /// so the CoverageEngine produces a real easy→hard gradient.
    static func baseKnownWords() -> Set<String> {
        Set("""
        i you he she it we they me him her us them my your his its our their
        a an the this that these those here there
        am is are was were be been being do does did have has had will would can could
        get got make made go went come came see saw look looked want wanted like liked
        keep kept walk walked leave left reach reached decide decided
        and or but so because if when while as of to in on at by for with from up out
        not no yes very still just too also then now soon early late long time day
        morning street window house coffee bus stop way meeting plan side everyone
        """.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init))
    }
}
