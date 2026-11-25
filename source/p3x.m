#pragma mark - Extractor engine (JavaScriptCore, updatable)

static NSString *DefaultEngineURL = @"https://raw.githubusercontent.com/Jo0sef/Flow/main/extractors.js";
// Fallbacks tried in order when the first address fails. Only a file that passes every check is installed.
static NSArray<NSString *> *EngineMirrors(void) {
    NSMutableArray *a = [NSMutableArray array];
    NSString *c = [UD() stringForKey:@"engineurl"]; if (c.length) [a addObject:c];
    for (NSString *m in @[ DefaultEngineURL, @"https://cdn.jsdelivr.net/gh/Jo0sef/Flow@main/extractors.js", @"https://jo0sef.github.io/Flow/extractors.js" ]) if (![a containsObject:m]) [a addObject:m];
    return a;
}
// Bumped only when the app gains native abilities an extractor may rely on (an extractor can declare FLOW_MIN_NATIVE).
static const int kNativeLevel = 1;

@interface Engine : NSObject
@property(nonatomic, strong) JSContext *ctx;
@property(nonatomic) int version;
@property(nonatomic, strong) NSURLSession *session;
+ (Engine *)shared;

- (void)extract:(NSString *)url completion:(void (^)(NSDictionary *res, NSString *err))cb;
@property(nonatomic) BOOL pending, updating;
@property(nonatomic, strong) NSMutableArray *waiters;
- (void)updateWithCompletion:(void (^)(NSString *msg, BOOL ok))cb;
@end

@implementation Engine
+ (Engine *)shared { static Engine *e; static dispatch_once_t o; dispatch_once(&o, ^{ e = [Engine new]; [e load]; }); return e; }
- (NSString *)userScriptPath { return [SupportDir() stringByAppendingPathComponent:@"extractors.js"]; }
- (NSString *)bundledScript { NSString *p = [NSBundle.mainBundle pathForResource:@"extractors" ofType:@"js"]; return p ? [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil] : nil; }
- (JSContext *)makeContext:(NSString *)src {
    if (!src.length) return nil;
    @try { return [self makeContextUnsafe:src]; } @catch (NSException *e) { return nil; }
}
- (JSContext *)makeContextUnsafe:(NSString *)src {
    JSContext *c = [JSContext new];
    c.exceptionHandler = ^(JSContext *cx, JSValue *ex) { };
    c[@"__http"] = ^(JSValue *req, JSValue *cb) { [self http:[req toDictionary] callback:cb]; };
    c[@"__raw"] = ^(JSValue *req, JSValue *cb) { [self raw:[req toDictionary] callback:cb]; };
    c[@"__native"] = @(kNativeLevel);
    [c evaluateScript:@"function http(o){return new Promise(function(res,rej){__http(o,function(r){ if(r.error) rej(new Error(r.error)); else res(r); });});}"];
    [c evaluateScript:src];
    if (![c[@"flowExtract"] isObject]) return nil;
    return c;
}
- (int)versionOf:(JSContext *)c { return [c[@"FLOW_VERSION"] toInt32]; }
- (void)load {
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.timeoutIntervalForRequest = 20; cfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    self.session = [NSURLSession sessionWithConfiguration:cfg];
    JSContext *b = [self makeContext:[self bundledScript]];
    NSString *us = [NSString stringWithContentsOfFile:[self userScriptPath] encoding:NSUTF8StringEncoding error:nil];
    JSContext *u = us.length ? [self makeContext:us] : nil;
    if (u && (!b || [self versionOf:u] >= [self versionOf:b])) self.ctx = u; else self.ctx = b;
    self.version = self.ctx ? [self versionOf:self.ctx] : 0;
    self.pending = (self.ctx == u && u && [UD() integerForKey:@"engine_pending"] == self.version);
}
- (NSString *)prevPath { return [SupportDir() stringByAppendingPathComponent:@"extractors.prev.js"]; }
- (NSString *)statusText {
    NSDate *d = [UD() objectForKey:@"engine_updated"];
    NSString *when = L(@"built into the app", @"جاهزة مع التطبيق");
    if (d) { NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterShortStyle; if (IsAr()) f.locale = [NSLocale localeWithLocaleIdentifier:@"ar_EG"]; when = [f stringFromDate:d]; }
    return [NSString stringWithFormat:L(@"version %d, updated %@", @"نسخة %d، اتحدثت %@"), self.version, when];
}
// Run a candidate through the checks. Calls back on the main queue with a context or an error text.
- (void)validate:(NSString *)src done:(void (^)(JSContext *c, int ver, NSString *err))cb {
    JSContext *c = [self makeContext:src];
    if (!c) { cb(nil, 0, @"parse"); return; }
    int nv = [self versionOf:c];
    if (nv <= 0) { cb(nil, 0, @"no version"); return; }
    if ([c[@"FLOW_MIN_NATIVE"] toInt32] > kNativeLevel) { cb(nil, nv, @"needs newer app"); return; }
    JSValue *st = c[@"flowSelfTest"];
    if ([st isObject] && ![[st callWithArguments:@[]] toBool]) { cb(nil, nv, @"self-test"); return; }
    __block BOOL fired = NO;
    void (^fin)(NSString *) = ^(NSString *e) { if (fired) return; fired = YES; cb(e ? nil : c, nv, e); };
    JSValue *p = [c[@"flowExtract"] callWithArguments:@[ @"https://example.com/self-test.mp4" ]];
    if (!p || ![p isObject]) { fin(@"self-test"); return; }
    JSValue *ok = [JSValue valueWithObject:^(JSValue *v) { fin(([v isNull] || [v isUndefined]) ? nil : @"self-test"); } inContext:c];
    JSValue *bad = [JSValue valueWithObject:^(JSValue *v) { fin(@"self-test"); } inContext:c];
    [p invokeMethod:@"then" withArguments:@[ ok, bad ]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ fin(@"self-test timeout"); });
}
// Go back to the previous good copy (or the built-in one) and never re-adopt the version that failed.
- (BOOL)rollback {
    if (!self.pending) return NO;
    int bad = self.version; NSFileManager *fm = NSFileManager.defaultManager;
    [UD() setInteger:bad forKey:@"engine_bad"]; [UD() setInteger:0 forKey:@"engine_pending"]; self.pending = NO;
    NSString *ps = [NSString stringWithContentsOfFile:[self prevPath] encoding:NSUTF8StringEncoding error:nil];
    JSContext *pc = ps.length ? [self makeContext:ps] : nil;
    if (pc) { [ps writeToFile:[self userScriptPath] atomically:YES encoding:NSUTF8StringEncoding error:nil]; self.ctx = pc; }
    else { [fm removeItemAtPath:[self userScriptPath] error:nil]; self.ctx = [self makeContext:[self bundledScript]]; }
    self.version = self.ctx ? [self versionOf:self.ctx] : 0;
    return self.ctx != nil;
}
- (void)autoUpdateIfDue:(BOOL)force {
    if ([UD() objectForKey:@"autoengine"] && ![UD() boolForKey:@"autoengine"]) return;
    NSDate *last = [UD() objectForKey:@"engine_checked"];
    if (!force && last && -[last timeIntervalSinceNow] < 86400) return;
    [self updateWithCompletion:^(NSString *m, BOOL ok) { }];
}
- (void)http:(NSDictionary *)o callback:(JSValue *)cb {
    NSURL *u = [NSURL URLWithString:o[@"url"]];
    void (^reply)(NSDictionary *) = ^(NSDictionary *d) { dispatch_async(dispatch_get_main_queue(), ^{ [cb callWithArguments:@[ d ]]; }); };
    if (!u) { reply(@{ @"error": @"bad url" }); return; }
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u];
    r.HTTPMethod = [o[@"method"] isKindOfClass:NSString.class] ? o[@"method"] : @"GET";
    if ([o[@"headers"] isKindOfClass:NSDictionary.class]) for (NSString *k in o[@"headers"]) [r setValue:[NSString stringWithFormat:@"%@", o[@"headers"][k]] forHTTPHeaderField:k];
    if (![r valueForHTTPHeaderField:@"User-Agent"]) [r setValue:UA forHTTPHeaderField:@"User-Agent"];
    if ([o[@"timeout"] isKindOfClass:NSNumber.class] && [o[@"timeout"] doubleValue] > 0) r.timeoutInterval = [o[@"timeout"] doubleValue];
    if ([o[@"body"] isKindOfClass:NSString.class]) r.HTTPBody = [o[@"body"] dataUsingEncoding:NSUTF8StringEncoding];
    [[self.session dataTaskWithRequest:r completionHandler:^(NSData *d, NSURLResponse *resp, NSError *e) {
        if (e) { reply(@{ @"error": e.localizedDescription }); return; }
        NSHTTPURLResponse *h = (NSHTTPURLResponse *)resp;
        NSString *t = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] ?: [[NSString alloc] initWithData:d encoding:NSISOLatin1StringEncoding] ?: @"";
        reply(@{ @"status": @(h.statusCode), @"text": t, @"url": h.URL.absoluteString ?: @"", @"headers": h.allHeaderFields ?: @{} });
    }] resume];
}
// Raw TCP+TLS HTTP/1.1 probe with Network.framework: can force IPv4, IPv6 or the cellular interface. Diagnostics only.
- (void)raw:(NSDictionary *)o callback:(JSValue *)cb {
    NSString *host = o[@"host"], *path = o[@"path"], *fam = o[@"family"] ?: @"any", *ua = [o[@"ua"] isKindOfClass:NSString.class] ? o[@"ua"] : UA;
    BOOL range = [o[@"range"] boolValue]; double tmo = [o[@"timeout"] doubleValue] > 0 ? [o[@"timeout"] doubleValue] : 5;
    if (!host.length || !path.length) { dispatch_async(dispatch_get_main_queue(), ^{ [cb callWithArguments:@[ @{ @"error": @"bad request" } ]]; }); return; }
    double t0 = CFAbsoluteTimeGetCurrent();
    __block BOOL done = NO, ready = NO; __block NSString *addr = @"";
    nw_endpoint_t ep = nw_endpoint_create_host(host.UTF8String, "443");
    nw_parameters_t pr = nw_parameters_create_secure_tcp(NW_PARAMETERS_DEFAULT_CONFIGURATION, NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_protocol_stack_t st = nw_parameters_copy_default_protocol_stack(pr);
    nw_protocol_options_t ipo = nw_protocol_stack_copy_internet_protocol(st);
    if ([fam isEqualToString:@"4"]) nw_ip_options_set_version(ipo, nw_ip_version_4);
    else if ([fam isEqualToString:@"6"]) nw_ip_options_set_version(ipo, nw_ip_version_6);
    else if ([fam isEqualToString:@"cell"]) nw_parameters_set_required_interface_type(pr, nw_interface_type_cellular);
    nw_connection_t cn = nw_connection_create(ep, pr);
    void (^finish)(NSDictionary *) = ^(NSDictionary *d) {
        if (done) return; done = YES; nw_connection_cancel(cn);
        NSMutableDictionary *m = [d mutableCopy]; m[@"ms"] = @((int)((CFAbsoluteTimeGetCurrent() - t0) * 1000)); m[@"addr"] = addr;
        [cb callWithArguments:@[ m ]];
    };
    nw_connection_set_queue(cn, dispatch_get_main_queue());
    nw_connection_set_state_changed_handler(cn, ^(nw_connection_state_t state, nw_error_t error) {
        if (state == nw_connection_state_ready && !ready) {
            ready = YES;
            nw_path_t p = nw_connection_copy_current_path(cn); nw_endpoint_t re = p ? nw_path_copy_effective_remote_endpoint(p) : nil;
            if (re) { char *a = nw_endpoint_copy_address_string(re); if (a) { addr = [NSString stringWithUTF8String:a]; free(a); } }
            NSString *rq = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\nHost: %@\r\nUser-Agent: %@\r\n%@Accept: */*\r\nConnection: close\r\n\r\n", path, host, ua, range ? @"Range: bytes=0-1\r\n" : @""];
            NSData *rd = [rq dataUsingEncoding:NSUTF8StringEncoding];
            dispatch_data_t dd = dispatch_data_create(rd.bytes, rd.length, dispatch_get_main_queue(), DISPATCH_DATA_DESTRUCTOR_DEFAULT);
            nw_connection_send(cn, dd, NW_CONNECTION_DEFAULT_STREAM_CONTEXT, true, ^(nw_error_t e) { if (e) finish(@{ @"error": @"send failed" }); });
            nw_connection_receive(cn, 1, 2048, ^(dispatch_data_t content, nw_content_context_t ctx, bool complete, nw_error_t e) {
                if (content) {
                    NSData *d = (NSData *)content; NSString *s = [[NSString alloc] initWithData:d encoding:NSISOLatin1StringEncoding] ?: @"";
                    NSArray *parts = [[s componentsSeparatedByString:@"\r\n"].firstObject componentsSeparatedByString:@" "];
                    int code = parts.count > 1 ? [parts[1] intValue] : 0;
                    finish(code ? @{ @"status": @(code) } : @{ @"error": @"not HTTP" });
                } else finish(@{ @"error": e ? @"connection error" : @"closed without data" });
            });
        } else if (state == nw_connection_state_failed) finish(@{ @"error": [NSString stringWithFormat:@"connect failed (%d)", error ? (int)nw_error_get_error_code(error) : 0] });
        else if (state == nw_connection_state_waiting) addr = [addr length] ? addr : @"";
    });
    nw_connection_start(cn);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(tmo * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ finish(@{ @"error": ready ? @"no response (timeout)" : @"cannot connect (timeout)" }); });
}
- (void)extract:(NSString *)url completion:(void (^)(NSDictionary *, NSString *))cb { [self extract:url retried:NO completion:cb]; }
- (void)extract:(NSString *)url retried:(BOOL)retried completion:(void (^)(NSDictionary *, NSString *))cb {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.ctx) { cb(nil, L(@"The extractor engine could not start", @"محرك الاستخراج مشتغلش")); return; }
        __block BOOL fired = NO;
        void (^fin)(NSDictionary *, NSString *) = ^(NSDictionary *r, NSString *e) {
            if (fired) return; fired = YES;
            if (r && self.pending) { self.pending = NO; [UD() setInteger:0 forKey:@"engine_pending"]; }   // the new version worked once: keep it
            // A just-installed version that crashes with a code error (not a site error) is rolled back and the link is retried once.
            if (!r && e && !retried && self.pending && [e rangeOfString:@"(TypeError|ReferenceError|SyntaxError|is not a function|is not an object|undefined is not|null is not)" options:NSRegularExpressionSearch].location != NSNotFound && [self rollback]) { [self extract:url retried:YES completion:cb]; return; }
            cb(r, e); };
        JSValue *p = [self.ctx[@"flowExtract"] callWithArguments:@[ url ]];
        if (!p || ![p isObject]) { fin(nil, L(@"The extractor failed to run", @"أداة الاستخراج فشلت")); return; }
        JSValue *ok = [JSValue valueWithObject:^(JSValue *v) {
            if ([v isNull] || [v isUndefined]) { fin(nil, nil); return; }
            fin([v toDictionary], nil);
        } inContext:self.ctx];
        JSValue *bad = [JSValue valueWithObject:^(JSValue *v) {
            NSString *m = [[v isObject] ? [v valueForProperty:@"message"] : v toString];
            fin(nil, m.length ? m : L(@"Extraction failed", @"الاستخراج فشل"));
        } inContext:self.ctx];
        [p invokeMethod:@"then" withArguments:@[ ok, bad ]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 70 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ fin(nil, L(@"Timed out reading the link", @"الرابط أخد وقت كتير")); });
    });
}
- (void)updateWithCompletion:(void (^)(NSString *, BOOL))cb {
    if (!self.waiters) self.waiters = [NSMutableArray array];
    if (cb) [self.waiters addObject:[cb copy]];
    if (self.updating) return;
    self.updating = YES;
    NSArray *mirrors = EngineMirrors();
    __block NSString *lastErr = nil;
    void (^finish)(NSString *, BOOL) = ^(NSString *m, BOOL ok) {
        self.updating = NO; NSArray *w = [self.waiters copy]; [self.waiters removeAllObjects];
        for (void (^f)(NSString *, BOOL) in w) f(m, ok);
    };
    __block void (^tryAt)(NSUInteger);
    tryAt = ^(NSUInteger i) {
        if (i >= mirrors.count) { finish([NSString stringWithFormat:L(@"Could not get a valid update (%@). Your current version still works.", @"معرفتش أجيب تحديث سليم (%@). النسخة اللي معاك شغالة زي ما هي."), lastErr ?: @"?"], NO); tryAt = nil; return; }
        NSURL *u = [NSURL URLWithString:mirrors[i]];
        if (!u) { lastErr = @"address"; tryAt(i + 1); return; }
        NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:u]; rq.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData; rq.timeoutInterval = 15;
        [[self.session dataTaskWithRequest:rq completionHandler:^(NSData *d, NSURLResponse *resp, NSError *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger code = [(NSHTTPURLResponse *)resp statusCode];
                if (e || code != 200 || !d.length || d.length > 2000000) { lastErr = e ? @"network" : [NSString stringWithFormat:@"%ld", (long)code]; tryAt(i + 1); return; }
                NSString *src = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                [self validate:src done:^(JSContext *c, int nv, NSString *err) {
                    if (!c) { lastErr = err; tryAt(i + 1); return; }
                    [UD() setObject:[NSDate date] forKey:@"engine_checked"];
                    if (nv <= self.version || nv <= (int)[UD() integerForKey:@"engine_bad"]) { finish([NSString stringWithFormat:L(@"You already have the latest (version %d)", @"معاك أحدث نسخة (%d)"), self.version], YES); tryAt = nil; return; }
                    NSFileManager *fm = NSFileManager.defaultManager; NSString *cur = [self userScriptPath];
                    if (self.ctx && [fm fileExistsAtPath:cur]) { [fm removeItemAtPath:[self prevPath] error:nil]; [fm copyItemAtPath:cur toPath:[self prevPath] error:nil]; }
                    else [fm removeItemAtPath:[self prevPath] error:nil];
                    [src writeToFile:cur atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    self.ctx = c; self.version = nv; self.pending = YES;
                    [UD() setInteger:nv forKey:@"engine_pending"]; [UD() setObject:[NSDate date] forKey:@"engine_updated"];
                    finish([NSString stringWithFormat:L(@"Updated to version %d", @"اتحدث للنسخة %d"), nv], YES); tryAt = nil;
                }];
            });
        }] resume];
    };
    tryAt(0);
}
@end
