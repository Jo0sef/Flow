
#pragma mark - Storage helpers

static NSString *Docs(void) { return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject; }
// Orientation the app currently allows. Portrait everywhere except while the video player is in landscape mode.
static UIInterfaceOrientationMask gOrient = UIInterfaceOrientationMaskPortrait;
// Drops characters that draw as empty boxes (replacement characters, control and invisible format characters except direction marks).
static NSString *CleanTitle(NSString *s) {
    NSMutableString *m = [NSMutableString string];
    [s enumerateSubstringsInRange:NSMakeRange(0, s.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *sub, NSRange r, NSRange e, BOOL *stop) {
        unichar c = [sub characterAtIndex:0];
        if (c == 0xFFFD || c == 0xFFFC || (c < 0x20) || c == 0x7F || (c >= 0x80 && c < 0xA0)) return;
        if (c == 0x200B || c == 0xFEFF || c == 0x2060 || (c >= 0x202A && c <= 0x202E) || (c >= 0x2066 && c <= 0x2069)) return;
        [m appendString:sub];
    }];
    NSString *r = [m stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return r.length ? r : s;
}
static NSString *FmtSize(int64_t b) { return [NSByteCountFormatter stringFromByteCount:b countStyle:NSByteCountFormatterCountStyleFile]; }
static NSString *SafeName(NSString *s) {
    NSMutableString *m = [NSMutableString stringWithString:CleanTitle(s ?: @"")];
    for (NSString *bad in @[ @"/", @"\\", @":", @"?", @"*", @"\"", @"<", @">", @"|", @"\n", @"\r" ]) [m replaceOccurrencesOfString:bad withString:@"_" options:0 range:NSMakeRange(0, m.length)];
    NSString *r = [m stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    while ([r hasPrefix:@"."]) r = [r substringFromIndex:1];
    if (r.length > 120) { NSString *ext = r.pathExtension; r = [[r.stringByDeletingPathExtension substringToIndex:MIN(100, r.stringByDeletingPathExtension.length)] stringByAppendingPathExtension:ext]; }
    return r.length ? r : @"file";
}
static NSString *UniquePath(NSString *dir, NSString *name) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *base = name.stringByDeletingPathExtension, *ext = name.pathExtension;
    NSString *p = [dir stringByAppendingPathComponent:name];
    for (int i = 2; [fm fileExistsAtPath:p]; i++) {
        NSString *n = [NSString stringWithFormat:@"%@ (%d)", base, i];
        p = [dir stringByAppendingPathComponent:ext.length ? [n stringByAppendingPathExtension:ext] : n];
    }
    return p;
}
// 0 folder, 1 image, 2 video, 3 audio, 4 document, 5 archive, 6 other
static int KindOf(NSString *path) {
    BOOL dir = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&dir] && dir) return 0;
    NSString *ext = path.pathExtension.lowercaseString;
    if (!ext.length) return 6;
    UTType *t = [UTType typeWithFilenameExtension:ext];
    if (!t) return 6;
    if ([t conformsToType:UTTypeImage]) return 1;
    if ([t conformsToType:UTTypeMovie] || [t conformsToType:UTTypeVideo]) return 2;
    if ([t conformsToType:UTTypeAudio]) return 3;
    if ([t conformsToType:UTTypeArchive]) return 5;
    if ([t conformsToType:UTTypeText] || [t conformsToType:UTTypePDF] || [t conformsToType:UTTypeContent]) return 4;
    return 6;
}
static NSString *KindSymbol(int k) {
    NSArray *s = @[ @"folder.fill", @"photo", @"film", @"music.note", @"doc.text", @"archivebox", @"doc" ];
    return s[k];
}
static int64_t SizeOf(NSString *path) {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL dir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&dir]) return 0;
    if (!dir) return [[fm attributesOfItemAtPath:path error:nil] fileSize];
    int64_t t = 0;
    for (NSString *f in [fm enumeratorAtPath:path]) t += [[fm attributesOfItemAtPath:[path stringByAppendingPathComponent:f] error:nil] fileSize];
    return t;
}

#pragma mark - Quick Look preview

@interface PreviewSource : NSObject <QLPreviewControllerDataSource>
@property(nonatomic, strong) NSURL *url;
@end
@implementation PreviewSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)c { return 1; }
- (id<QLPreviewItem>)previewController:(QLPreviewController *)c previewItemAtIndex:(NSInteger)i { return self.url; }
@end
static PreviewSource *gPreviewSource;
static void Preview(UIViewController *from, NSString *path) {
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) return;
    gPreviewSource = [PreviewSource new];
    gPreviewSource.url = [NSURL fileURLWithPath:path];
    QLPreviewController *q = [QLPreviewController new];
    q.dataSource = gPreviewSource;
    [from presentViewController:q animated:YES completion:nil];
}
static void Alert(UIViewController *vc, NSString *title, NSString *msg) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:T(title) message:msg.length ? T(msg) : nil preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:a animated:YES completion:nil];
}


#pragma mark - Settings helpers

static NSUserDefaults *UD(void) { return NSUserDefaults.standardUserDefaults; }

#pragma mark - Launch safety
#include <execinfo.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
static NSMutableArray *gIssues;
static int gCrashFD = -1;
static NSString *LogDir(void) {
    NSString *p = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Flow"] stringByAppendingPathComponent:@"logs"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static void CleanOldLogs(void) {
    for (NSString *n in @[ @"Flow-launch-log.txt", @"Flow-crash-log.txt", @"Flow-crash-log-prev.txt" ]) [NSFileManager.defaultManager removeItemAtPath:[Docs() stringByAppendingPathComponent:n] error:nil];
}
static BOOL IsInternalName(NSString *n) { return [n hasPrefix:@"."] || [n isEqualToString:@"Flow-launch-log.txt"] || [n isEqualToString:@"Flow-crash-log.txt"] || [n isEqualToString:@"Flow-crash-log-prev.txt"]; }
static NSString *CrumbPath(void) { return [LogDir() stringByAppendingPathComponent:@"launch.txt"]; }
static NSString *CrashPath(void) { return [LogDir() stringByAppendingPathComponent:@"crash.txt"]; }
static void Crumb(NSString *s) { @try { [s writeToFile:CrumbPath() atomically:NO encoding:NSUTF8StringEncoding error:nil]; } @catch (NSException *e) { } }
static void RecordIssue(NSString *s) { if (!gIssues) gIssues = [NSMutableArray array]; [gIssues addObject:s ?: @"?"]; }
static NSString *IssueText(void) { return gIssues.count ? [gIssues componentsJoinedByString:@"\n"] : nil; }
static void SigHandler(int sig) {
    char b[64]; int n = snprintf(b, sizeof b, "\nSIGNAL %d\n", sig);
    if (gCrashFD >= 0) { write(gCrashFD, b, n); void *bt[40]; int c = backtrace(bt, 40); backtrace_symbols_fd(bt, c, gCrashFD); }
    signal(sig, SIG_DFL); raise(sig);
}
static void ExcHandler(NSException *e) {
    NSString *t = [NSString stringWithFormat:@"EXCEPTION %@\n%@\n%@\n", e.name, e.reason, [e.callStackSymbols componentsJoinedByString:@"\n"]];
    if (gCrashFD >= 0) write(gCrashFD, t.UTF8String, strlen(t.UTF8String));
}
static void InstallCrashCatcher(void) {
    @try {
        CleanOldLogs();
        NSString *p = CrashPath();
        NSString *old = [LogDir() stringByAppendingPathComponent:@"crash-prev.txt"];
        [[NSFileManager defaultManager] removeItemAtPath:old error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:p toPath:old error:nil];
        gCrashFD = open(p.fileSystemRepresentation, O_WRONLY | O_CREAT | O_APPEND, 0644);
        NSSetUncaughtExceptionHandler(&ExcHandler);
        int sigs[] = { SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGTRAP, SIGFPE };
        for (int i = 0; i < 6; i++) signal(sigs[i], SigHandler);
    } @catch (NSException *e) { }
}
// Returns text if the last run did not reach "done" (it crashed), else nil.
static NSString *PreviousCrash(void) {
    @try {
        NSString *last = [NSString stringWithContentsOfFile:CrumbPath() encoding:NSUTF8StringEncoding error:nil];
        NSString *old = [LogDir() stringByAppendingPathComponent:@"crash-prev.txt"];
        NSString *c = [NSString stringWithContentsOfFile:old encoding:NSUTF8StringEncoding error:nil];
        if (last.length && ![last isEqualToString:@"done"] && (c.length || !([@[ @"visible", @"engine", @"engine ok", @"built", @"aurora", @"tabs" ] containsObject:last]))) return [NSString stringWithFormat:@"Last launch stopped at step: %@\n%@", last, c.length ? c : @""];
    } @catch (NSException *e) { }
    return nil;
}
static void ShowDiagnostics(UIViewController *vc, NSString *text) {
    if (!vc) return;
    UIViewController *top = vc; while (top.presentedViewController) top = top.presentedViewController;
    NSString *shown = text.length > 1500 ? [text substringToIndex:1500] : text;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Flow diagnostics" message:shown preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { UIPasteboard.generalPasteboard.string = text; }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [top presentViewController:a animated:YES completion:nil];
}

static NSString *L(NSString *en, NSString *ar) { return IsAr() ? ar : en; }
static NSString *DownloadDir(void) {
    NSString *rel = [UD() stringForKey:@"dlfolder"]; if (!rel.length) rel = @"Downloads";
    NSString *p = [rel isEqualToString:@"."] ? Docs() : [Docs() stringByAppendingPathComponent:rel];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static NSString *TempRoot(void) {
    NSString *p = [NSTemporaryDirectory() stringByAppendingPathComponent:@"flowtmp"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static NSString *SupportDir(void) {
    NSString *p = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Flow"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static BOOL IsPlatformHost(NSString *h) {
    h = h.lowercaseString;
    for (NSString *d in @[ @"youtube.com", @"youtu.be", @"facebook.com", @"fb.watch", @"fb.com", @"instagram.com", @"tiktok.com", @"twitter.com", @"x.com", @"t.co" ]) {
        if ([h isEqualToString:d] || [h hasSuffix:[@"." stringByAppendingString:d]]) return YES;
    }
    return NO;
}
static NSString *FmtDur(double s) {
    int t = (int)s; if (t <= 0) return @"";
    return t >= 3600 ? [NSString stringWithFormat:@"%d:%02d:%02d", t / 3600, (t / 60) % 60, t % 60] : [NSString stringWithFormat:@"%d:%02d", t / 60, t % 60];
}
