static BOOL TrashMove(NSString *path);
#pragma mark - Download engine (parallel ranged downloads, chunked, merge)

@interface Part : NSObject
@property(nonatomic) int64_t start, end, done;
@property(nonatomic) int tries;
@property(nonatomic) BOOL started;
@property(nonatomic, strong) NSURLSessionDataTask *task;
@end
@implementation Part @end

@interface Job : NSObject
@property(nonatomic, copy) NSString *url, *name, *path, *err, *absDir, *thumbURL, *note;
@property(nonatomic) int state; // 0 starting, 1 running, 2 done, 3 failed, 4 canceled, 5 merging
@property(nonatomic) int64_t total, got, lastGot, knownSize, chunk;
@property(nonatomic) double speed;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic) int fd;
@property(nonatomic) BOOL ranged, hidden;
@property(nonatomic, copy) NSDictionary *headers;
@property(nonatomic) BOOL retriedDenied, extractAudio;
@property(nonatomic) int mode; // 0 ranged header, 2 ranged query, 1 single plain, 3 single fresh
@property(nonatomic, copy) NSString *clientInfo, *proto;
@property(nonatomic, strong) NSMutableString *diag;
@property(nonatomic, strong) NSMutableArray<Part *> *parts;
@property(nonatomic, strong) NSURLSessionDataTask *single, *probe;
@property(nonatomic, strong) Job *vJob, *aJob; // for merged downloads
@property(nonatomic, copy) NSString *finalName, *step;
@property(nonatomic) int64_t stallGot; @property(nonatomic) double stallAt;
@end
@implementation Job @end

@interface Mgr : NSObject <NSURLSessionDataDelegate>
@property(nonatomic, strong) NSMutableArray<Job *> *jobs;
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray *> *map;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, Job *> *owner;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) UIBackgroundTaskIdentifier bgTask;
@property(nonatomic) BOOL cellular;
+ (Mgr *)shared;
- (Job *)add:(NSString *)url;
- (Job *)addFormat:(NSDictionary *)fmt title:(NSString *)title thumb:(NSString *)thumb;
- (void)cancel:(Job *)j;
- (void)retry:(Job *)j;
- (void)remove:(Job *)j deleteFile:(BOOL)del;
- (void)clearHistory;
- (NSString *)diagnostics:(Job *)j;
- (void)restart:(Job *)j;
@end

static NSString *UA = @"Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1";

static NSString *NameFromDisposition(NSString *cd) {
    if (!cd.length) return nil;
    NSRange r = [cd rangeOfString:@"filename*=" options:NSCaseInsensitiveSearch];
    if (r.location != NSNotFound) {
        NSString *v = [cd substringFromIndex:r.location + r.length];
        NSRange e = [v rangeOfString:@";"]; if (e.location != NSNotFound) v = [v substringToIndex:e.location];
        NSRange q = [v rangeOfString:@"''"]; if (q.location != NSNotFound) v = [v substringFromIndex:q.location + 2];
        NSString *d = [v stringByRemovingPercentEncoding]; if (d.length) return [d stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    }
    r = [cd rangeOfString:@"filename=" options:NSCaseInsensitiveSearch];
    if (r.location != NSNotFound) {
        NSString *v = [cd substringFromIndex:r.location + r.length];
        NSRange e = [v rangeOfString:@";"]; if (e.location != NSNotFound) v = [v substringToIndex:e.location];
        v = [v stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \""]];
        if (v.length) return v;
    }
    return nil;
}

@implementation Mgr
+ (Mgr *)shared { static Mgr *m; static dispatch_once_t o; dispatch_once(&o, ^{ m = [Mgr new]; [m setup]; }); return m; }
- (int)conns { NSInteger c = [UD() integerForKey:@"conns"]; return c < 2 ? 6 : (c > 8 ? 8 : (int)c); }
- (void)setup {
    self.jobs = [NSMutableArray array]; self.map = [NSMutableDictionary dictionary]; self.owner = [NSMutableDictionary dictionary];
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.HTTPMaximumConnectionsPerHost = 10; cfg.timeoutIntervalForRequest = 25; cfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSOperationQueue *q = [NSOperationQueue new]; q.maxConcurrentOperationCount = 1;
    self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:q];
    nw_path_monitor_t mon = nw_path_monitor_create();
    nw_path_monitor_set_queue(mon, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    nw_path_monitor_set_update_handler(mon, ^(nw_path_t path) {
        self.cellular = nw_path_uses_interface_type(path, nw_interface_type_cellular) && !nw_path_uses_interface_type(path, nw_interface_type_wifi);
    });
    nw_path_monitor_start(mon);
    for (NSDictionary *d in [UD() arrayForKey:@"history"] ?: @[]) {
        NSString *p = [Docs() stringByAppendingPathComponent:d[@"rel"]];
        if (![NSFileManager.defaultManager fileExistsAtPath:p]) continue;
        Job *j = [Job new]; j.url = d[@"url"]; j.name = p.lastPathComponent; j.path = p; j.state = 2;
        j.total = j.got = [d[@"size"] longLongValue]; j.date = [NSDate dateWithTimeIntervalSince1970:[d[@"ts"] doubleValue]];
        [self.jobs addObject:j];
    }
}
- (void)notify { dispatch_async(dispatch_get_main_queue(), ^{ [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil]; }); }
- (void)persist {
    NSMutableArray *a = [NSMutableArray array];
    for (Job *j in self.jobs) if (j.state == 2 && j.path.length > Docs().length + 1) [a addObject:@{ @"url": j.url ?: @"", @"rel": [j.path substringFromIndex:Docs().length + 1], @"size": @(j.total), @"ts": @(j.date.timeIntervalSince1970) }];
    [UD() setObject:a forKey:@"history"];
}
- (Job *)makeJob:(NSString *)url name:(NSString *)name {
    Job *j = [Job new]; j.url = url; j.date = [NSDate date]; j.fd = -1; j.name = name;
    return j;
}
- (Job *)add:(NSString *)url {
    Job *j = [self makeJob:url name:nil];
    NSURL *u = [NSURL URLWithString:url];
    j.name = SafeName([u.lastPathComponent stringByRemovingPercentEncoding]);
    if (!u.lastPathComponent.length || [u.lastPathComponent isEqualToString:@"/"]) j.name = SafeName(u.host);
    return [self launch:j];
}
- (Job *)launch:(Job *)j {
    if (!j.hidden) [self.jobs insertObject:j atIndex:0];
    if ([UD() boolForKey:@"wifionly"] && self.cellular) {
        j.state = 3; j.err = L(@"Wi-Fi only is on and you are on mobile data", @"وضع الواي فاي بس شغال وإنت على داتا الموبايل");
        [self notify]; return j;
    }
    [self beginBackground];
    if (j.knownSize > 0) [self begin:j total:j.knownSize ranged:YES]; else [self probe:j];
    [self notify];
    return j;
}
- (Job *)addFormat:(NSDictionary *)f title:(NSString *)title thumb:(NSString *)thumb {
    NSString *ext = f[@"ext"] ?: @"mp4";
    NSString *base = SafeName(title.length ? title : @"Flow");
    if ([f[@"kind"] isEqualToString:@"audio"] && ![f[@"label"] isEqualToString:@"M4A"]) base = [base stringByAppendingString:@""];
    BOOL xa = [f[@"extractAudio"] boolValue];
    NSString *fname = [base stringByAppendingPathExtension:xa ? @"mp4" : ext];
    NSString *ci = [NSString stringWithFormat:@"%@ (probe %@)%@", f[@"client"] ?: @"-", f[@"probe"] ?: @"-", [f[@"probelog"] length] ? [@"\nclient tries: " stringByAppendingString:f[@"probelog"]] : @""];
    NSDictionary *au = f[@"audio"];
    if (![au isKindOfClass:NSDictionary.class]) {
        Job *j = [self makeJob:f[@"url"] name:fname];
        j.headers = f[@"headers"]; j.chunk = [f[@"chunk"] longLongValue]; j.knownSize = [f[@"size"] longLongValue]; j.thumbURL = thumb; j.clientInfo = ci; j.extractAudio = xa;
        return [self launch:j];
    }
    // video + audio: two hidden downloads, merged when both finish
    NSString *tmp = [TempRoot() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    [NSFileManager.defaultManager createDirectoryAtPath:tmp withIntermediateDirectories:YES attributes:nil error:nil];
    Job *p = [self makeJob:f[@"url"] name:fname]; p.finalName = fname; p.thumbURL = thumb; p.state = 1;
    Job *v = [self makeJob:f[@"url"] name:@"video.mp4"]; v.hidden = YES; v.clientInfo = ci; v.absDir = tmp; v.headers = f[@"headers"]; v.chunk = [f[@"chunk"] longLongValue]; v.knownSize = ([f[@"size"] longLongValue] > [au[@"size"] longLongValue] && [au[@"size"] longLongValue] > 0) ? [f[@"size"] longLongValue] - [au[@"size"] longLongValue] : 0;
    Job *a = [self makeJob:au[@"url"] name:@"audio.m4a"]; a.hidden = YES; a.clientInfo = ci; a.absDir = tmp; a.headers = au[@"headers"]; a.chunk = [au[@"chunk"] longLongValue]; a.knownSize = MAX(0, [au[@"size"] longLongValue]);
    p.vJob = v; p.aJob = a; p.total = v.knownSize + a.knownSize; p.absDir = tmp;
    [self.jobs insertObject:p atIndex:0];
    if ([UD() boolForKey:@"wifionly"] && self.cellular) {
        p.state = 3; p.err = L(@"Wi-Fi only is on and you are on mobile data", @"وضع الواي فاي بس شغال وإنت على داتا الموبايل"); [self notify]; return p;
    }
    [self beginBackground]; [self startTimer];
    [self launch:v]; [self launch:a];
    [self notify];
    return p;
}
- (void)beginBackground {
    if (self.bgTask != UIBackgroundTaskInvalid && self.bgTask != 0) return;
    self.bgTask = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^{ [UIApplication.sharedApplication endBackgroundTask:self.bgTask]; self.bgTask = UIBackgroundTaskInvalid; }];
}
- (void)endBackgroundIfIdle {
    for (Job *j in self.jobs) if (j.state < 2 || j.state == 5) return;
    if (self.bgTask != UIBackgroundTaskInvalid && self.bgTask != 0) { [UIApplication.sharedApplication endBackgroundTask:self.bgTask]; self.bgTask = UIBackgroundTaskInvalid; }
    dispatch_async(dispatch_get_main_queue(), ^{ [self.timer invalidate]; self.timer = nil; });
}
static NSString *StepText(int mode) {
    switch (mode) {
        case 0: return L(@"Step 1/5: normal request", @"خطوة 1/5: طلب عادي");
        case 2: return L(@"Step 2/5: range in the link", @"خطوة 2/5: النطاق في الرابط");
        case 1: return L(@"Step 3/5: single request", @"خطوة 3/5: طلب واحد");
        case 3: return L(@"Step 4/5: fresh connection", @"خطوة 4/5: اتصال جديد");
        default: return L(@"Step 5/5: other Google server", @"خطوة 5/5: سيرفر جوجل تاني");
    }
}
- (void)logLine:(Job *)j fmt:(NSString *)line {
    if (!j.diag) j.diag = [NSMutableString string];
    if (j.diag.length > 7000) return;
    [j.diag appendFormat:@"[%@] %@\n", [NSDateFormatter localizedStringFromDate:NSDate.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle], line];
}
static BOOL IsGV(NSString *u) { return [[NSURL URLWithString:u ?: @""].host hasSuffix:@"googlevideo.com"]; }
// -1 when every way has been tried
- (int)nextMode:(Job *)j {
    int m;
    switch (j.mode) { case 0: m = 2; break; case 2: m = 1; break; case 1: m = 3; break; case 3: m = IsGV(j.url) ? 4 : -1; break; default: m = -1; }
    if (m == 2 && j.total <= 0) m = 1;
    return m;
}
// No bytes for 20 s: move to the next way of asking, and say so.
- (void)watch:(Job *)j {
    if (j.state != 1) { j.stallAt = 0; return; }
    double now = CFAbsoluteTimeGetCurrent();
    if (j.stallAt == 0 || j.got != j.stallGot) { j.stallGot = j.got; j.stallAt = now; return; }
    if (now - j.stallAt < 20) return;
    j.stallAt = now;
    [self logLine:j fmt:[NSString stringWithFormat:@"no data for 20 s (got %lld of %lld, mode %d, %@)", j.got, j.total, j.mode, j.proto ?: @"protocol ?"]];
    int nm = [self nextMode:j];
    if (nm < 0) { [self fail:j msg:L(@"No data came back from the server for 20 seconds, even after trying every method. Tap Details and send the text.", @"السيرفر مردش بأي بيانات 20 ثانية حتى بعد كل المحاولات. افتح التفاصيل وابعت النص.")]; return; }
    j.mode = nm; j.step = StepText(j.mode);
    [self restartJob:j];
}
- (void)restart:(Job *)j {
    if (j.vJob) { [self resetSub:j.vJob]; [self resetSub:j.aJob]; j.step = nil; [self notify]; return; }
    if (j.state >= 2 && j.state != 5) return;
    if (j.path) [NSFileManager.defaultManager removeItemAtPath:j.path error:nil];
    [self resetSub:j]; [self notify];
}
- (void)resetSub:(Job *)j {
    if (j.state >= 2) return;
    [self stopTasks:j];
    for (NSNumber *k in [self.map allKeys]) if ([self.map[k] firstObject] == j) [self.map removeObjectForKey:k];
    [self closeFile:j];
    j.mode = 0; j.diag = nil; j.proto = nil; j.state = 0; j.err = nil; j.got = 0; j.lastGot = 0; j.parts = nil; j.single = nil; j.fd = -1; j.stallAt = 0; j.step = StepText(0);
    if (j.knownSize > 0) [self begin:j total:j.knownSize ranged:YES]; else [self probe:j];
}
- (void)startTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) return;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *t) {
            for (Job *j in [self.jobs copy]) {
                if (j.vJob) [self tickMerged:j];
                else if (j.state == 1) { [self watch:j]; double inst = (j.got - j.lastGot) / 0.5; j.speed = j.speed * 0.5 + inst * 0.5; j.lastGot = j.got; } else j.speed = 0;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil];
        }];
    });
}
- (void)tickMerged:(Job *)p {
    if (p.state != 1) { p.speed = 0; return; }
    Job *v = p.vJob, *a = p.aJob;
    [self watch:v]; [self watch:a];
    p.step = v.mode >= a.mode && v.mode != 0 ? v.step : (a.mode != 0 ? a.step : (v.step ?: a.step));
    if (v.state == 3 || a.state == 3) { Job *bad = v.state == 3 ? v : a; p.diag = bad.diag; p.url = bad.url; p.mode = bad.mode; p.clientInfo = bad.clientInfo; p.chunk = bad.chunk; p.knownSize = bad.knownSize; p.proto = bad.proto; [self fail:p msg:bad.err]; return; }
    int64_t got = v.got + a.got; double inst = (got - p.lastGot) / 0.5; p.speed = p.speed * 0.5 + inst * 0.5; p.lastGot = got; p.got = got;
    int64_t t = (v.total ?: v.knownSize) + (a.total ?: a.knownSize); if (t > 0) p.total = t;
    if (v.state == 2 && a.state == 2) [self merge:p];
}
- (void)merge:(Job *)p {
    p.state = 5; p.speed = 0; [self notify];
    AVURLAsset *va = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:p.vJob.path] options:nil];
    AVURLAsset *aa = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:p.aJob.path] options:nil];
    NSString *dir = DownloadDir();
    NSString *out = UniquePath(dir, p.finalName);
    AVMutableComposition *comp = [AVMutableComposition composition];
    AVAssetTrack *vt = [va tracksWithMediaType:AVMediaTypeVideo].firstObject, *at = [aa tracksWithMediaType:AVMediaTypeAudio].firstObject;
    NSError *err = nil;
    if (vt) { AVMutableCompositionTrack *c = [comp addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; [c insertTimeRange:CMTimeRangeMake(kCMTimeZero, va.duration) ofTrack:vt atTime:kCMTimeZero error:&err]; c.preferredTransform = vt.preferredTransform; }
    if (at && !err) { AVMutableCompositionTrack *c = [comp addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; [c insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMinimum(aa.duration, va.duration)) ofTrack:at atTime:kCMTimeZero error:&err]; }
    AVAssetExportSession *ex = (!vt || !at || err) ? nil : [[AVAssetExportSession alloc] initWithAsset:comp presetName:AVAssetExportPresetPassthrough];
    if (!ex) { [self mergeFallback:p]; return; }
    ex.outputURL = [NSURL fileURLWithPath:out]; ex.outputFileType = AVFileTypeMPEG4; ex.shouldOptimizeForNetworkUse = YES;
    [ex exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ex.status == AVAssetExportSessionStatusCompleted) {
                p.path = out; p.name = out.lastPathComponent; p.total = SizeOf(out); p.got = p.total; p.state = 2; p.date = [NSDate date];
                [NSFileManager.defaultManager removeItemAtPath:p.absDir error:nil];
                [self persist]; [self notify]; [self endBackgroundIfIdle];
            } else { [NSFileManager.defaultManager removeItemAtPath:out error:nil]; [self mergeFallback:p]; }
        });
    }];
}
// If merging fails, keep both parts so nothing is lost.
- (void)mergeFallback:(Job *)p {
    NSString *dir = DownloadDir();
    NSString *base = p.finalName.stringByDeletingPathExtension;
    NSString *vp = UniquePath(dir, [base stringByAppendingString:@" (video).mp4"]);
    NSString *ap = UniquePath(dir, [base stringByAppendingString:@" (audio).m4a"]);
    [NSFileManager.defaultManager moveItemAtPath:p.vJob.path toPath:vp error:nil];
    [NSFileManager.defaultManager moveItemAtPath:p.aJob.path toPath:ap error:nil];
    [NSFileManager.defaultManager removeItemAtPath:p.absDir error:nil];
    p.path = vp; p.name = vp.lastPathComponent; p.total = p.got = SizeOf(vp); p.state = 2; p.date = [NSDate date];
    p.note = L(@"Could not merge video and audio, saved as two files", @"معرفتش أدمج الصوت مع الفيديو، اتحفظوا ملفين");
    [self persist]; [self notify]; [self endBackgroundIfIdle];
}
- (NSMutableURLRequest *)req:(Job *)j method:(NSString *)m {
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:j.url]];
    if (j.mode == 4) { NSURLComponents *rc = [NSURLComponents componentsWithString:j.url]; rc.host = @"redirector.googlevideo.com"; if (rc.URL) r.URL = rc.URL; }
    r.HTTPMethod = m; [r setValue:UA forHTTPHeaderField:@"User-Agent"];
    if (j.mode >= 3) { r.HTTPShouldHandleCookies = NO; if (@available(iOS 14.5, *)) r.assumesHTTP3Capable = NO; [r setValue:@"*/*" forHTTPHeaderField:@"Accept"]; }
    else [r setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    for (NSString *k in j.headers) [r setValue:[NSString stringWithFormat:@"%@", j.headers[k]] forHTTPHeaderField:k];
    return r;
}
- (void)probe:(Job *)j {
    NSMutableURLRequest *r = [self req:j method:@"HEAD"]; r.timeoutInterval = 12;
    j.probe = [self.session dataTaskWithRequest:r completionHandler:^(NSData *d, NSURLResponse *resp, NSError *e) {
        if (j.state == 4) return;
        NSHTTPURLResponse *h = [resp isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)resp : nil;
        BOOL ok = !e && h && h.statusCode >= 200 && h.statusCode < 300;
        int64_t len = ok ? h.expectedContentLength : 0; if (len < 0) len = 0;
        NSString *ar = [[h valueForHTTPHeaderField:@"Accept-Ranges"] lowercaseString];
        NSString *nm = NameFromDisposition([h valueForHTTPHeaderField:@"Content-Disposition"]);
        if (!nm.length && ok) { NSString *l = [h.URL.lastPathComponent stringByRemovingPercentEncoding]; if (l.length && l.pathExtension.length) nm = l; }
        if (nm.length) j.name = SafeName(nm);
        if (!j.name.pathExtension.length && ok) {
            NSString *ct = [[h valueForHTTPHeaderField:@"Content-Type"] componentsSeparatedByString:@";"].firstObject;
            UTType *t = ct.length ? [UTType typeWithMIMEType:ct] : nil;
            if (t.preferredFilenameExtension.length) j.name = [j.name stringByAppendingPathExtension:t.preferredFilenameExtension];
        }
        BOOL ranged = ok && len > 2 * 1024 * 1024 && [ar containsString:@"bytes"];
        [self begin:j total:len ranged:ranged];
    }];
    [j.probe resume];
}
- (void)begin:(Job *)j total:(int64_t)total ranged:(BOOL)ranged {
    NSString *dir = j.absDir ?: DownloadDir();
    [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    j.path = j.absDir ? [dir stringByAppendingPathComponent:j.name] : UniquePath(dir, j.name); j.name = j.path.lastPathComponent;
    j.fd = open(j.path.fileSystemRepresentation, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (j.fd < 0) { [self fail:j msg:@"Could not create the file"]; return; }
    j.total = total; j.got = 0; j.lastGot = 0; j.ranged = ranged; j.state = 1; j.stallAt = 0; j.step = StepText(j.mode);
    [self startTimer];
    if (ranged) {
        ftruncate(j.fd, total);
        int64_t chunk;
        if (j.chunk > 0) chunk = j.chunk;
        else { int n = total > 64 * 1024 * 1024 ? 8 : (total > 16 * 1024 * 1024 ? 6 : 4); chunk = (total + n - 1) / n; }
        j.parts = [NSMutableArray array];
        for (int64_t s = 0; s < total; s += chunk) { Part *p = [Part new]; p.start = s; p.end = MIN(total - 1, s + chunk - 1); [j.parts addObject:p]; }
        [self pump:j];
    } else {
        NSURLSessionDataTask *t = [self.session dataTaskWithRequest:[self req:j method:@"GET"]];
        j.single = t; self.owner[@(t.taskIdentifier)] = j; self.map[@(t.taskIdentifier)] = @[ j, [NSNull null] ]; [t resume];
    }
    [self notify];
}
- (void)pump:(Job *)j {
    if (j.state != 1 || !j.parts) return;
    int active = 0; for (Part *p in j.parts) if (p.started && p.start + p.done <= p.end) active++;
    int limit = [self conns]; if (IsGV(j.url) && limit > 3) limit = 3;
    for (Part *p in j.parts) {
        if (active >= limit) break;
        if (!p.started) { p.started = YES; active++; [self startPart:p job:j]; }
    }
}
- (void)startPart:(Part *)p job:(Job *)j {
    NSMutableURLRequest *r = [self req:j method:@"GET"];
    if (j.mode == 2) {
        NSString *u = [j.url stringByAppendingFormat:@"%@range=%lld-%lld", [j.url containsString:@"?"] ? @"&" : @"?", p.start + p.done, p.end];
        r.URL = [NSURL URLWithString:u];
    } else [r setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", p.start + p.done, p.end] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *t = [self.session dataTaskWithRequest:r];
    p.task = t; self.owner[@(t.taskIdentifier)] = j; self.map[@(t.taskIdentifier)] = @[ j, p ]; [t resume];
}
- (void)fail:(Job *)j msg:(NSString *)m {
    if (j.state == 2 || j.state == 3 || j.state == 4) return;
    j.state = 3; j.err = m; j.speed = 0;
    [self stopTasks:j]; [self closeFile:j]; if (j.path && !j.vJob) [NSFileManager.defaultManager removeItemAtPath:j.path error:nil];
    if (j.vJob) { [self cancelSub:j.vJob]; [self cancelSub:j.aJob]; [NSFileManager.defaultManager removeItemAtPath:j.absDir error:nil]; }
    [self notify]; [self endBackgroundIfIdle];
}
- (void)cancelSub:(Job *)s { if (s.state < 2) { s.state = 4; [self stopTasks:s]; [self closeFile:s]; } }
- (void)stopTasks:(Job *)j {
    [j.probe cancel]; [j.single cancel];
    for (Part *p in j.parts) [p.task cancel];
}
- (void)closeFile:(Job *)j { if (j.fd >= 0) { close(j.fd); j.fd = -1; } }
- (void)finish:(Job *)j {
    if (j.state >= 2) return;
    if (j.extractAudio && !j.hidden && j.state == 1) { [self extractAudioFor:j]; return; }
    [self closeFile:j]; j.state = 2; j.speed = 0; if (!j.ranged) j.total = j.got;
    j.date = [NSDate date];
    if (!j.hidden) [self persist];
    [self notify]; if (!j.hidden) [self endBackgroundIfIdle];
}
- (void)extractAudioFor:(Job *)j {
    [self closeFile:j]; j.state = 5; j.speed = 0; [self notify];
    NSString *src = j.path; NSString *dst = UniquePath(src.stringByDeletingLastPathComponent, [src.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"m4a"]);
    AVURLAsset *as = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:src] options:nil];
    AVAssetExportSession *ex = [[AVAssetExportSession alloc] initWithAsset:as presetName:AVAssetExportPresetAppleM4A];
    if (!ex) { j.state = 2; j.note = L(@"Could not extract audio, saved as video", @"معرفتش أطلّع الصوت، اتحفظ فيديو"); [self persist]; [self notify]; [self endBackgroundIfIdle]; return; }
    ex.outputURL = [NSURL fileURLWithPath:dst]; ex.outputFileType = AVFileTypeAppleM4A;
    [ex exportAsynchronouslyWithCompletionHandler:^{ dispatch_async(dispatch_get_main_queue(), ^{
        if (ex.status == AVAssetExportSessionStatusCompleted) {
            [NSFileManager.defaultManager removeItemAtPath:src error:nil];
            j.path = dst; j.name = dst.lastPathComponent; j.total = j.got = SizeOf(dst);
        } else { [NSFileManager.defaultManager removeItemAtPath:dst error:nil]; j.note = L(@"Could not extract audio, saved as video", @"معرفتش أطلّع الصوت، اتحفظ فيديو"); j.total = j.got = SizeOf(src); }
        j.state = 2; j.date = [NSDate date]; [self persist]; [self notify]; [self endBackgroundIfIdle];
    }); }];
}
- (void)cancel:(Job *)j {
    if (j.state >= 2 && j.state != 5) return;
    j.state = 4; j.speed = 0; [self stopTasks:j]; [self closeFile:j];
    if (j.vJob) { [self cancelSub:j.vJob]; [self cancelSub:j.aJob]; [NSFileManager.defaultManager removeItemAtPath:j.absDir error:nil]; }
    else if (j.path) [NSFileManager.defaultManager removeItemAtPath:j.path error:nil];
    [self notify]; [self endBackgroundIfIdle];
}
- (void)retry:(Job *)j {
    if (j.state < 3) return;
    if (j.vJob) { [self.jobs removeObject:j]; return; } // merged jobs are re-added from the picker
    j.retriedDenied = NO; j.mode = 0; j.diag = nil; j.proto = nil; j.state = 0; j.err = nil; j.got = 0; j.lastGot = 0; j.parts = nil; j.single = nil; j.fd = -1;
    j.date = [NSDate date]; [self beginBackground];
    if (j.knownSize > 0) [self begin:j total:j.knownSize ranged:YES]; else [self probe:j];
    [self notify];
}
- (void)remove:(Job *)j deleteFile:(BOOL)del {
    if (j.state < 2 || j.state == 5) [self cancel:j];
    if (del && j.path && !j.vJob) { if (j.state == 2 && [NSFileManager.defaultManager fileExistsAtPath:j.path] && TrashMove(j.path)) { } else [NSFileManager.defaultManager removeItemAtPath:j.path error:nil]; }
    [self.jobs removeObject:j]; [self persist]; [self notify];
}
- (void)clearHistory {
    for (Job *j in [self.jobs copy]) if (j.state >= 2 && j.state != 5) [self.jobs removeObject:j];
    [self persist]; [self notify];
}
- (void)restartJob:(Job *)j {
    [self stopTasks:j];
    for (NSNumber *k in [self.map allKeys]) if ([self.map[k] firstObject] == j) [self.map removeObjectForKey:k];
    j.parts = nil; j.single = nil; j.got = 0; j.lastGot = 0;
    if (j.fd >= 0) ftruncate(j.fd, 0);
    if (j.mode == 2 && j.total > 0) {
        j.ranged = YES; ftruncate(j.fd, j.total);
        int64_t chunk = j.chunk > 0 ? j.chunk : 8 * 1024 * 1024;
        j.parts = [NSMutableArray array];
        for (int64_t s = 0; s < j.total; s += chunk) { Part *p = [Part new]; p.start = s; p.end = MIN(j.total - 1, s + chunk - 1); [j.parts addObject:p]; }
        [self pump:j];
    } else {
        j.ranged = NO;
        NSURLSessionDataTask *nt = [self.session dataTaskWithRequest:[self req:j method:@"GET"]];
        j.single = nt; self.owner[@(nt.taskIdentifier)] = j; self.map[@(nt.taskIdentifier)] = @[ j, [NSNull null] ]; [nt resume];
    }
}
- (void)logAttempt:(Job *)j task:(NSURLSessionTask *)t resp:(NSHTTPURLResponse *)r {
    if (!j.diag) j.diag = [NSMutableString string];
    if (j.diag.length > 6000) return;
    NSMutableDictionary *rq = [NSMutableDictionary dictionaryWithDictionary:t.currentRequest.allHTTPHeaderFields ?: @{}];
    for (NSString *k in rq.allKeys) { NSString *l = k.lowercaseString; if ([l isEqualToString:@"cookie"] || [l containsString:@"authorization"] || [l containsString:@"token"]) rq[k] = @"(hidden)"; }
    NSString *u = t.currentRequest.URL.absoluteString ?: @"";
    NSString *range = [u containsString:@"range="] ? @" +range-in-url" : @"";
    [j.diag appendFormat:@"-- attempt mode %d%@ -> HTTP %ld, %@\n", j.mode, range, (long)r.statusCode, j.proto ?: @"protocol ?"];
    [j.diag appendFormat:@"sent: %@\n", rq];
    [j.diag appendFormat:@"got: %@\n", r.allHeaderFields];
}
- (NSString *)diagnostics:(Job *)j {
    if (j.vJob && j.state != 3) return [NSString stringWithFormat:@"%@\n=== VIDEO stream ===\n%@\n=== AUDIO stream ===\n%@", [NSString stringWithFormat:@"state %d, %lld / %lld bytes, step: %@", j.state, j.got, j.total, j.step ?: @"-"], [self diagnostics:j.vJob], [self diagnostics:j.aJob]];
    NSURL *u = [NSURL URLWithString:j.url ?: @""];
    NSMutableString *o = [NSMutableString stringWithFormat:@"Flow %@ diagnostics\niOS %@, %@\n", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], UIDevice.currentDevice.systemVersion, self.cellular ? @"mobile data" : @"Wi-Fi/other"];
    [o appendFormat:@"state: %d, got %lld of %lld bytes, step: %@\n", j.state, j.got, j.total, j.step ?: @"-"];
    [o appendFormat:@"error: %@\nhost: %@\npath: %@\nclient: %@\nchunk: %lld, known size: %lld, final mode: %d\n", j.err ?: @"-", u.host ?: @"-", u.path.length > 40 ? [u.path substringToIndex:40] : (u.path ?: @""), j.clientInfo ?: @"-", j.chunk, j.knownSize, j.mode];
    NSURLComponents *cc = [NSURLComponents componentsWithString:j.url ?: @""];
    NSMutableArray *q = [NSMutableArray array];
    NSSet *show = [NSSet setWithObjects:@"c", @"ip", @"itag", @"expire", @"mime", @"clen", @"ratebypass", @"source", @"id", @"ei", @"requiressl", nil];
    for (NSURLQueryItem *it in cc.queryItems) {
        if ([it.name isEqualToString:@"ip"] || [show containsObject:it.name]) { if (![it.name isEqualToString:@"id"] && ![it.name isEqualToString:@"ei"]) [q addObject:[NSString stringWithFormat:@"%@=%@", it.name, it.value]]; }
        else [q addObject:it.name];
    }
    [o appendFormat:@"url params: %@\n", [q componentsJoinedByString:@" "]];
    [o appendString:j.diag ?: @"(no response received)\n"];
    [o appendFormat:@"protocol: %@\n", j.proto ?: @"?"];
    return o;
}
#pragma mark session delegate
- (void)URLSession:(NSURLSession *)s dataTask:(NSURLSessionDataTask *)t didReceiveResponse:(NSURLResponse *)r completionHandler:(void (^)(NSURLSessionResponseDisposition))h {
    NSArray *m = self.map[@(t.taskIdentifier)]; Job *j = m.firstObject;
    NSInteger c = [(NSHTTPURLResponse *)r statusCode];
    if (!j || j.state != 1) { h(NSURLSessionResponseCancel); return; }
    if (c < 200 || c >= 300) [self logAttempt:j task:t resp:(NSHTTPURLResponse *)r];
    else if (j.diag.length < 2500) [self logLine:j fmt:[NSString stringWithFormat:@"mode %d -> HTTP %ld, length %lld", j.mode, (long)c, r.expectedContentLength]];
    if ((c == 403 || c == 410) && [self nextMode:j] >= 0) {
        // try the next way of asking: ranged header -> ranged query -> single plain -> single fresh
        h(NSURLSessionResponseCancel);
        j.mode = [self nextMode:j]; j.step = StepText(j.mode); j.stallAt = 0;
        [self restartJob:j];
        return;
    }
    if (c < 200 || c >= 300) {
        h(NSURLSessionResponseCancel);
        NSString *msg = (c == 403 || c == 410)
            ? [NSString stringWithFormat:L(@"The site refused the download (error %ld). Try another quality, or update extractors in Settings > Downloads.", @"الموقع رفض التحميل (خطأ %ld). جرب جودة تانية، أو حدّث المستخرجات من الإعدادات > التحميلات."), (long)c]
            : [NSString stringWithFormat:L(@"Server error %ld", @"خطأ من السيرفر %ld"), (long)c];
        [self fail:j msg:msg]; return;
    }
    if (m[1] != NSNull.null && !j.ranged) { h(NSURLSessionResponseCancel); return; }
    if (m[1] != NSNull.null && c != 206 && !(j.mode == 2 && c == 200)) {
        // server ignored the range request: restart as one plain download
        h(NSURLSessionResponseCancel);
        j.ranged = NO; [self stopTasks:j]; j.parts = nil; j.got = 0; j.lastGot = 0; ftruncate(j.fd, 0);
        NSURLSessionDataTask *nt = [self.session dataTaskWithRequest:[self req:j method:@"GET"]];
        j.single = nt; self.owner[@(nt.taskIdentifier)] = j; self.map[@(nt.taskIdentifier)] = @[ j, [NSNull null] ]; [nt resume];
        return;
    }
    if (m[1] == NSNull.null && j.total == 0 && r.expectedContentLength > 0) j.total = r.expectedContentLength;
    h(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)s task:(NSURLSessionTask *)t didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)mt {
    NSArray *m = self.map[@(t.taskIdentifier)]; Job *j = m.firstObject ?: self.owner[@(t.taskIdentifier)]; if (!j) return;
    NSURLSessionTaskTransactionMetrics *tm = mt.transactionMetrics.lastObject;
    if (!j.proto && m) j.proto = tm.networkProtocolName;
    NSString *ra = tm.remoteAddress ?: @"?";
    NSString *fam = [ra isEqualToString:@"?"] ? @"?" : ([ra containsString:@":"] ? @"IPv6" : @"IPv4");
    #define MS(a, b) ((a) && (b) ? (int)([(b) timeIntervalSinceDate:(a)] * 1000) : -1)
    [self logLine:j fmt:[NSString stringWithFormat:@"task %lu: %@ %@ %@, dns %d connect %d tls %d first-byte %d ms, reused %d, %@", (unsigned long)t.taskIdentifier, fam, ra, tm.networkProtocolName ?: @"?", MS(tm.domainLookupStartDate, tm.domainLookupEndDate), MS(tm.connectStartDate, tm.connectEndDate), MS(tm.secureConnectionStartDate, tm.secureConnectionEndDate), MS(tm.requestStartDate, tm.responseStartDate), (int)tm.isReusedConnection, t.error ? [NSString stringWithFormat:@"error %ld", (long)t.error.code] : @"ok"]];
    [self.owner removeObjectForKey:@(t.taskIdentifier)];
}
- (void)URLSession:(NSURLSession *)s dataTask:(NSURLSessionDataTask *)t didReceiveData:(NSData *)d {
    NSArray *m = self.map[@(t.taskIdentifier)]; Job *j = m.firstObject; if (!j || j.state != 1 || j.fd < 0) return;
    Part *p = m[1] == NSNull.null ? nil : m[1];
    [d enumerateByteRangesUsingBlock:^(const void *bytes, NSRange range, BOOL *stop) {
        int64_t off = p ? p.start + p.done : j.got;
        ssize_t w = pwrite(j.fd, bytes, range.length, off);
        if (w < 0) { *stop = YES; return; }
        if (p) p.done += w;
        j.got += w;
    }];
}
- (void)URLSession:(NSURLSession *)s task:(NSURLSessionTask *)t didCompleteWithError:(NSError *)e {
    NSArray *m = self.map[@(t.taskIdentifier)]; if (!m) return;
    [self.map removeObjectForKey:@(t.taskIdentifier)];
    Job *j = m.firstObject; if (!j || j.state != 1) return;
    Part *p = m[1] == NSNull.null ? nil : m[1];
    if (p) {
        if (p.task != t) return;
        BOOL complete = (p.start + p.done > p.end);
        if (e && !complete) {
            if (e.code == NSURLErrorCancelled) return;
            [self logLine:j fmt:[NSString stringWithFormat:@"part %lld error %ld %@", p.start, (long)e.code, e.localizedDescription]];
            if (++p.tries <= 4) { [self startPart:p job:j]; return; }
            [self fail:j msg:e.localizedDescription]; return;
        }
        for (Part *q in j.parts) if (q.start + q.done <= q.end) { [self pump:j]; return; }
        [self finish:j];
    } else {
        if (j.single != t) return;
        if (e) { if (e.code == NSURLErrorCancelled) return; [self logLine:j fmt:[NSString stringWithFormat:@"error %ld %@", (long)e.code, e.localizedDescription]]; [self fail:j msg:e.localizedDescription]; return; }
        [self finish:j];
    }
}
@end
