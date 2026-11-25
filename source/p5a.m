#pragma mark - Thumbnails, player, pins

static NSCache *gThumbs;
static NSString *RelPath(NSString *p) { return p.length > Docs().length + 1 ? [p substringFromIndex:Docs().length + 1] : p; }
static NSString *ThumbPath(NSString *p) {
    NSString *dir = [SupportDir() stringByAppendingPathComponent:@"thumbs"];
    [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *k = [[[RelPath(p) dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    if (k.length > 100) k = [k substringFromIndex:k.length - 100];
    return [dir stringByAppendingPathComponent:[k stringByAppendingString:@".jpg"]];
}
static void ThumbFor(NSString *path, void (^cb)(UIImage *)) {
    if (!gThumbs) gThumbs = [NSCache new];
    NSString *key = [path stringByAppendingFormat:@"|%.0f|%.0f", [[[NSFileManager.defaultManager attributesOfItemAtPath:ThumbPath(path) error:nil] fileModificationDate] timeIntervalSince1970], [[[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil] fileModificationDate] timeIntervalSince1970]];
    UIImage *c = [gThumbs objectForKey:key]; if (c) { cb(c); return; }
    int k = KindOf(path);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        UIImage *img = nil;
        NSString *custom = ThumbPath(path);
        if ([NSFileManager.defaultManager fileExistsAtPath:custom]) img = [UIImage imageWithContentsOfFile:custom];
        else if (k == 3) {
            AVURLAsset *as = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            [as loadValuesAsynchronouslyForKeys:@[ @"commonMetadata", @"metadata" ] completionHandler:^{ dispatch_semaphore_signal(sem); }];
            dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC));
            AVMetadataItem *mi = [AVMetadataItem metadataItemsFromArray:as.commonMetadata filteredByIdentifier:AVMetadataCommonIdentifierArtwork].firstObject;
            if (!mi) mi = [AVMetadataItem metadataItemsFromArray:as.metadata filteredByIdentifier:AVMetadataIdentifieriTunesMetadataCoverArt].firstObject;
            if (!mi) mi = [AVMetadataItem metadataItemsFromArray:as.metadata filteredByIdentifier:AVMetadataIdentifierID3MetadataAttachedPicture].firstObject;
            NSData *d = mi.dataValue;
            if (d.length) {
                NSDictionary *o = @{ (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (id)kCGImageSourceThumbnailMaxPixelSize: @200, (id)kCGImageSourceCreateThumbnailWithTransform: @YES };
                CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)d, NULL);
                if (src) { CGImageRef cg = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)o); if (cg) { img = [UIImage imageWithCGImage:cg]; CGImageRelease(cg); } CFRelease(src); }
            }
        }
        else if (k == 1) {
            NSDictionary *o = @{ (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (id)kCGImageSourceThumbnailMaxPixelSize: @200, (id)kCGImageSourceCreateThumbnailWithTransform: @YES };
            CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
            if (src) { CGImageRef cg = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)o); if (cg) { img = [UIImage imageWithCGImage:cg]; CGImageRelease(cg); } CFRelease(src); }
        } else if (k == 2) {
            AVAssetImageGenerator *g = [[AVAssetImageGenerator alloc] initWithAsset:[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil]];
            g.appliesPreferredTrackTransform = YES; g.maximumSize = CGSizeMake(200, 200);
            CGImageRef cg = [g copyCGImageAtTime:CMTimeMakeWithSeconds(1, 600) actualTime:NULL error:nil];
            if (cg) { img = [UIImage imageWithCGImage:cg]; CGImageRelease(cg); }
        }
        if (img) { [gThumbs setObject:img forKey:key]; dispatch_async(dispatch_get_main_queue(), ^{ cb(img); }); }
    });
}
static NSMutableArray *Pins(void) { return [([UD() arrayForKey:@"pins"] ?: @[]) mutableCopy]; }
static BOOL IsPinned(NSString *p) { return [Pins() containsObject:RelPath(p)]; }
static void TogglePin(NSString *p) { NSMutableArray *a = Pins(); NSString *r = RelPath(p); if ([a containsObject:r]) [a removeObject:r]; else [a addObject:r]; [UD() setObject:a forKey:@"pins"]; }

static void ForceOrientation(UIViewController *vc, UIInterfaceOrientationMask mask, UIInterfaceOrientation fallback) {
    UIWindowScene *sc = vc.view.window.windowScene;
    if (!sc) for (UIScene *x in UIApplication.sharedApplication.connectedScenes) if ([x isKindOfClass:UIWindowScene.class]) { sc = (UIWindowScene *)x; break; }
    Class pc = NSClassFromString(@"UIWindowSceneGeometryPreferencesIOS");
    SEL rq = NSSelectorFromString(@"requestGeometryUpdateWithPreferences:errorHandler:");
    if (pc && sc && [sc respondsToSelector:rq]) {   // iOS 16 and later
        typedef id (*InitFn)(id, SEL, UIInterfaceOrientationMask);
        id obj = ((InitFn)objc_msgSend)([pc alloc], NSSelectorFromString(@"initWithInterfaceOrientations:"), mask);
        typedef void (*ReqFn)(id, SEL, id, void (^)(NSError *));
        ((ReqFn)objc_msgSend)(sc, rq, obj, ^(NSError *e) { });
        SEL up = NSSelectorFromString(@"setNeedsUpdateOfSupportedInterfaceOrientations");
        if ([vc respondsToSelector:up]) ((void (*)(id, SEL))objc_msgSend)(vc, up);
    } else {
        [UIDevice.currentDevice setValue:@(fallback) forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}
@interface PlayerVC : UIViewController <UIGestureRecognizerDelegate>
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) AVPlayerLayer *pl;
@property(nonatomic, strong) UIView *ui;
@property(nonatomic, strong) GlassView *top, *bot;
@property(nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) UILabel *tcur, *tend;
@property(nonatomic, strong) UIButton *playBtn, *spdBtn, *loopBtn, *rotBtn;
@property(nonatomic) BOOL landscape, minimized, started;
@property(nonatomic, strong) NSMutableArray *remoteTokens;
@property(nonatomic, strong) UIImageView *art;
@property(nonatomic, strong) id timeObs;
@property(nonatomic, strong) NSTimer *hideTimer;
@property(nonatomic) BOOL scrubbing, audio, loop, failedShown, closing;
@property(nonatomic) float speed;
- (void)fullStop;
- (void)togglePlay;
@end
@class PlayerVC;
static PlayerVC *gActivePlayer;   // the player that keeps going (full screen or minimized to the mini bar)
static void MiniShow(PlayerVC *p);
static void MiniHide(void);
static void MiniRefresh(void);

@implementation PlayerVC
- (BOOL)prefersStatusBarHidden { return self.landscape; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return gOrient; }
- (BOOL)shouldAutorotate { return YES; }
- (void)applyOrientation:(BOOL)land {
    self.landscape = land;
    gOrient = land ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskPortrait;
    UIInterfaceOrientation want = land ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
    ForceOrientation(self, gOrient, want);
    [self setNeedsStatusBarAppearanceUpdate];
    SetBtnContent(self.rotBtn, Sym(land ? @"arrow.down.right.and.arrow.up.left" : @"arrow.up.left.and.arrow.down.right", 19, UIFontWeightSemibold), nil, UIColor.whiteColor, 16, 21);
}
- (void)minimize {
    // Back to the list, sound keeps playing; the mini bar above the tab bar controls it.
    if (self.landscape) [self applyOrientation:NO]; else gOrient = UIInterfaceOrientationMaskPortrait;
    self.minimized = YES; gActivePlayer = self; if (self.pl) self.pl.player = nil;
    [self.hideTimer invalidate];
    [self dismissViewControllerAnimated:YES completion:^{ MiniShow(self); }];
}
- (void)fullStop { MiniHide(); gActivePlayer = nil; self.minimized = NO; [self.player pause]; [self cleanup]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; if (self.minimized) { self.minimized = NO; MiniHide(); if (self.pl && UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) self.pl.player = self.player; } gActivePlayer = self; }
- (void)toggleRotate { [self applyOrientation:!self.landscape]; [self scheduleHide]; }
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (UIButton *)iconBtn:(NSString *)sym size:(CGFloat)sz sel:(SEL)s {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.translatesAutoresizingMaskIntoConstraints = NO;
    SetBtnContent(b, Sym(sym, sz, UIFontWeightSemibold), nil, UIColor.whiteColor, 16, sz + 2);
    [b addTarget:self action:s forControlEvents:UIControlEventTouchUpInside];
    [b.widthAnchor constraintEqualToConstant:48].active = YES; [b.heightAnchor constraintEqualToConstant:48].active = YES;
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.audio = KindOf(self.path) == 3;
    float sp = [UD() floatForKey:@"playspeed"]; self.speed = sp < 0.4 ? 1 : sp;
    self.loop = [UD() boolForKey:@"loop"];
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.path]];
    [self setupBackgroundPlayback];
    UIColor *white = UIColor.whiteColor;
    if (self.audio) {
        AuroraView *a = [[AuroraView alloc] initWithFrame:self.view.bounds]; [self.view addSubview:a];
        GlassView *card = [GlassView new]; card.translatesAutoresizingMaskIntoConstraints = NO; card.radius = 44; [self.view addSubview:card];
        UIImageView *ic = [[UIImageView alloc] initWithImage:[Sym(@"music.note", 90, UIFontWeightLight) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]]; ic.tintColor = Theme.accent; ic.contentMode = UIViewContentModeScaleAspectFit; ic.translatesAutoresizingMaskIntoConstraints = NO;
        [card.content addSubview:ic];
        self.art = [UIImageView new]; self.art.translatesAutoresizingMaskIntoConstraints = NO; self.art.contentMode = UIViewContentModeScaleAspectFill; self.art.clipsToBounds = YES; [card.content addSubview:self.art];
        UILabel *nm = Label(CleanTitle(self.path.lastPathComponent.stringByDeletingPathExtension), 20, UIFontWeightHeavy, white); nm.textAlignment = NSTextAlignmentCenter; nm.numberOfLines = 2; [self.view addSubview:nm];
        [NSLayoutConstraint activateConstraints:@[
            [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-90],
            [card.widthAnchor constraintEqualToConstant:250], [card.heightAnchor constraintEqualToConstant:250],
            [ic.centerXAnchor constraintEqualToAnchor:card.content.centerXAnchor], [ic.centerYAnchor constraintEqualToAnchor:card.content.centerYAnchor], [ic.widthAnchor constraintEqualToConstant:110], [ic.heightAnchor constraintEqualToConstant:110],
            [self.art.leadingAnchor constraintEqualToAnchor:card.content.leadingAnchor], [self.art.trailingAnchor constraintEqualToAnchor:card.content.trailingAnchor], [self.art.topAnchor constraintEqualToAnchor:card.content.topAnchor], [self.art.bottomAnchor constraintEqualToAnchor:card.content.bottomAnchor],
            [nm.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:26], [nm.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:30], [nm.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-30] ]];
        AVAsset *as = self.player.currentItem.asset; __weak PlayerVC *ws = self;
        [as loadValuesAsynchronouslyForKeys:@[ @"commonMetadata" ] completionHandler:^{
            NSArray *items = [AVMetadataItem metadataItemsFromArray:as.commonMetadata filteredByIdentifier:AVMetadataCommonIdentifierArtwork];
            AVMetadataItem *mi = items.firstObject;
            if (!mi) { [as loadValuesAsynchronouslyForKeys:@[ @"metadata" ] completionHandler:nil]; mi = [AVMetadataItem metadataItemsFromArray:as.metadata filteredByIdentifier:AVMetadataIdentifieriTunesMetadataCoverArt].firstObject; }
            NSData *d = mi.dataValue; UIImage *im = d ? [UIImage imageWithData:d] : nil;
            if (!im) { NSString *sc = ThumbPath(ws.path); if ([NSFileManager.defaultManager fileExistsAtPath:sc]) im = [UIImage imageWithContentsOfFile:sc]; }
            if (im) dispatch_async(dispatch_get_main_queue(), ^{ ws.art.image = im; [ws updateNowPlaying]; if (gActivePlayer == ws) MiniRefresh(); });
        }];
    } else {
        self.pl = [AVPlayerLayer playerLayerWithPlayer:self.player]; self.pl.videoGravity = AVLayerVideoGravityResizeAspect; [self.view.layer addSublayer:self.pl];
    }
    self.ui = [UIView new]; self.ui.frame = self.view.bounds; self.ui.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; [self.view addSubview:self.ui];
    // top bar
    self.top = [GlassView new]; self.top.translatesAutoresizingMaskIntoConstraints = NO; self.top.radius = 26; [self.ui addSubview:self.top];
    UIButton *x = [self iconBtn:@"chevron.backward" size:19 sel:@selector(minimize)];
    UIButton *x2 = [self iconBtn:@"xmark" size:17 sel:@selector(close)];
    UILabel *tt = Label(CleanTitle(self.path.lastPathComponent), 15, UIFontWeightBold, white); tt.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.top.content addSubview:x]; [self.top.content addSubview:x2]; [self.top.content addSubview:tt];
    // bottom panel
    self.bot = [GlassView new]; self.bot.translatesAutoresizingMaskIntoConstraints = NO; self.bot.radius = 34; [self.ui addSubview:self.bot];
    self.slider = [UISlider new]; self.slider.translatesAutoresizingMaskIntoConstraints = NO; self.slider.minimumTrackTintColor = Theme.accent; self.slider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.25];
    [self.slider addTarget:self action:@selector(scrubStart) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(scrubMove) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(scrubEnd) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    self.tcur = Label(@"0:00", 12, UIFontWeightBold, [UIColor colorWithWhite:1 alpha:0.75]); self.tend = Label(@"0:00", 12, UIFontWeightBold, [UIColor colorWithWhite:1 alpha:0.75]);
    self.tcur.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightBold]; self.tend.font = self.tcur.font;
    self.spdBtn = [UIButton buttonWithType:UIButtonTypeCustom]; self.spdBtn.translatesAutoresizingMaskIntoConstraints = NO; [self.spdBtn addTarget:self action:@selector(cycleSpeed) forControlEvents:UIControlEventTouchUpInside];
    [self.spdBtn.widthAnchor constraintEqualToConstant:52].active = YES; [self.spdBtn.heightAnchor constraintEqualToConstant:48].active = YES;
    self.rotBtn = [self iconBtn:@"arrow.up.left.and.arrow.down.right" size:19 sel:@selector(toggleRotate)]; self.rotBtn.hidden = self.audio;
    UIButton *bk = [self iconBtn:@"gobackward.10" size:26 sel:@selector(skipBack)];
    UIButton *fw = [self iconBtn:@"goforward.10" size:26 sel:@selector(skipFwd)];
    GradButton *pb = [GradButton buttonWithType:UIButtonTypeCustom]; pb.translatesAutoresizingMaskIntoConstraints = NO; pb.layer.cornerRadius = 33;
    [pb.widthAnchor constraintEqualToConstant:66].active = YES; [pb.heightAnchor constraintEqualToConstant:66].active = YES; [pb addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    self.playBtn = pb;
    self.loopBtn = [UIButton buttonWithType:UIButtonTypeCustom]; self.loopBtn.translatesAutoresizingMaskIntoConstraints = NO; [self.loopBtn addTarget:self action:@selector(toggleLoop) forControlEvents:UIControlEventTouchUpInside];
    [self.loopBtn.widthAnchor constraintEqualToConstant:44].active = YES; [self.loopBtn.heightAnchor constraintEqualToConstant:48].active = YES;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ self.spdBtn, bk, pb, fw, self.loopBtn, self.rotBtn ]]; row.axis = UILayoutConstraintAxisHorizontal; row.alignment = UIStackViewAlignmentCenter; row.distribution = UIStackViewDistributionEqualSpacing; row.translatesAutoresizingMaskIntoConstraints = NO;
    for (UIView *v in @[ self.slider, self.tcur, self.tend, row ]) [self.bot.content addSubview:v];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.top.topAnchor constraintEqualToAnchor:g.topAnchor constant:8], [self.top.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:14], [self.top.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-14], [self.top.heightAnchor constraintEqualToConstant:56],
        [x.leadingAnchor constraintEqualToAnchor:self.top.content.leadingAnchor constant:4], [x.centerYAnchor constraintEqualToAnchor:self.top.content.centerYAnchor],
        [tt.leadingAnchor constraintEqualToAnchor:x.trailingAnchor constant:4], [tt.trailingAnchor constraintEqualToAnchor:x2.leadingAnchor constant:-4], [x2.trailingAnchor constraintEqualToAnchor:self.top.content.trailingAnchor constant:-4], [x2.centerYAnchor constraintEqualToAnchor:self.top.content.centerYAnchor], [tt.centerYAnchor constraintEqualToAnchor:self.top.content.centerYAnchor],
        [self.bot.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:14], [self.bot.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-14], [self.bot.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-12], [self.bot.heightAnchor constraintEqualToConstant:172],
        [self.slider.topAnchor constraintEqualToAnchor:self.bot.content.topAnchor constant:18], [self.slider.leadingAnchor constraintEqualToAnchor:self.bot.content.leadingAnchor constant:22], [self.slider.trailingAnchor constraintEqualToAnchor:self.bot.content.trailingAnchor constant:-22],
        [self.tcur.topAnchor constraintEqualToAnchor:self.slider.bottomAnchor constant:2], [self.tcur.leadingAnchor constraintEqualToAnchor:self.slider.leadingAnchor],
        [self.tend.topAnchor constraintEqualToAnchor:self.slider.bottomAnchor constant:2], [self.tend.trailingAnchor constraintEqualToAnchor:self.slider.trailingAnchor],
        [row.leadingAnchor constraintEqualToAnchor:self.bot.content.leadingAnchor constant:18], [row.trailingAnchor constraintEqualToAnchor:self.bot.content.trailingAnchor constant:-18], [row.bottomAnchor constraintEqualToAnchor:self.bot.content.bottomAnchor constant:-14] ]];
    UITapGestureRecognizer *dbl = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)]; dbl.numberOfTapsRequired = 2; dbl.delegate = self; [self.view addGestureRecognizer:dbl];
    UITapGestureRecognizer *one = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleUI)]; one.delegate = self; [one requireGestureRecognizerToFail:dbl]; [self.view addGestureRecognizer:one];
    [self refreshButtons];
    __weak PlayerVC *ws = self;
    self.timeObs = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 4) queue:dispatch_get_main_queue() usingBlock:^(CMTime t) { [ws tick]; }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ended) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    UIView *v = t.view; return !([v isKindOfClass:UIControl.class] || [v isDescendantOfView:self.bot] || [v isDescendantOfView:self.top]);
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; self.pl.frame = self.view.bounds; }
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a];
    BOOL first = !self.started; self.started = YES;
    if (first && ([UD() objectForKey:@"autoplay"] == nil || [UD() boolForKey:@"autoplay"])) { self.player.defaultRate = self.speed; [self.player playImmediatelyAtRate:self.speed]; }
    [self refreshButtons]; [self scheduleHide];
}
- (void)refreshButtons {
    BOOL playing = self.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    SetBtnContent(self.playBtn, Sym(playing ? @"pause.fill" : @"play.fill", 28, UIFontWeightBold), nil, UIColor.whiteColor, 16, 30);
    SetBtnContent(self.spdBtn, nil, [NSString stringWithFormat:@"%gx", self.speed], UIColor.whiteColor, 16, 0);
    SetBtnContent(self.loopBtn, Sym(@"repeat", 20, UIFontWeightBold), nil, self.loop ? Theme.accent : [UIColor colorWithWhite:1 alpha:0.6], 16, 22);
    [self updateNowPlaying]; if (gActivePlayer == self) MiniRefresh();
}
- (void)tick {
    AVPlayerItem *it = self.player.currentItem;
    if (it.status == AVPlayerItemStatusFailed && !self.failedShown) {
        self.failedShown = YES;
        UIAlertController *al = [UIAlertController alertControllerWithTitle:L(@"Can't play this file", @"مش قادر أشغل الملف ده") message:it.error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [al addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [self close]; }]];
        [self presentViewController:al animated:YES completion:nil]; return;
    }
    double dur = CMTimeGetSeconds(it.duration), cur = CMTimeGetSeconds(self.player.currentTime);
    if (!isfinite(dur) || dur <= 0) return;
    if (!self.scrubbing) { self.slider.maximumValue = dur; self.slider.value = cur; self.tcur.text = FmtDur(cur); }
    self.tend.text = [@"-" stringByAppendingString:FmtDur(MAX(0, dur - cur))];
    BOOL playing = self.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    static const void *k = &k; NSNumber *last = objc_getAssociatedObject(self, k);
    if (!last || last.boolValue != playing) { objc_setAssociatedObject(self, k, @(playing), OBJC_ASSOCIATION_RETAIN); [self refreshButtons]; }
}
- (void)setupBackgroundPlayback {
    // Keeps sound going when the app is left or the phone is locked (needs UIBackgroundModes audio, no special entitlement).
    AVAudioSession *as = [AVAudioSession sharedInstance];
    [as setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:0 error:nil];
    [as setActive:YES error:nil];
    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];
    self.remoteTokens = [NSMutableArray array];
    __weak PlayerVC *ws = self;
    cc.skipForwardCommand.preferredIntervals = @[ @10 ]; cc.skipBackwardCommand.preferredIntervals = @[ @10 ];
    for (MPRemoteCommand *c in @[ cc.playCommand, cc.pauseCommand, cc.togglePlayPauseCommand, cc.skipForwardCommand, cc.skipBackwardCommand, cc.changePlaybackPositionCommand ]) c.enabled = YES;
    cc.nextTrackCommand.enabled = NO; cc.previousTrackCommand.enabled = NO;
    [self.remoteTokens addObject:@[ cc.playCommand, [cc.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) { PlayerVC *s = ws; if (!s) return MPRemoteCommandHandlerStatusCommandFailed; s.player.defaultRate = s.speed; [s.player playImmediatelyAtRate:s.speed]; [s refreshButtons]; return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [self.remoteTokens addObject:@[ cc.pauseCommand, [cc.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) { PlayerVC *s = ws; if (!s) return MPRemoteCommandHandlerStatusCommandFailed; [s.player pause]; [s refreshButtons]; return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [self.remoteTokens addObject:@[ cc.togglePlayPauseCommand, [cc.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) { PlayerVC *s = ws; if (!s) return MPRemoteCommandHandlerStatusCommandFailed; [s togglePlay]; return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [self.remoteTokens addObject:@[ cc.skipForwardCommand, [cc.skipForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) { [ws seekBy:10]; return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [self.remoteTokens addObject:@[ cc.skipBackwardCommand, [cc.skipBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) { [ws seekBy:-10]; return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [self.remoteTokens addObject:@[ cc.changePlaybackPositionCommand, [cc.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *e) {
        PlayerVC *s = ws; if (!s) return MPRemoteCommandHandlerStatusCommandFailed;
        [s.player seekToTime:CMTimeMakeWithSeconds(((MPChangePlaybackPositionCommandEvent *)e).positionTime, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL f) { [s updateNowPlaying]; }];
        return MPRemoteCommandHandlerStatusSuccess; }] ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
}
// A video layer attached to the player makes iOS pause it in the background; detach it so only the sound continues.
- (void)appBackground { if (self.pl) self.pl.player = nil; [self updateNowPlaying]; }
- (void)appForeground { if (self.pl && !self.minimized) self.pl.player = self.player; [self refreshButtons]; }
- (void)audioInterrupted:(NSNotification *)n {
    if ([n.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue] == AVAudioSessionInterruptionTypeEnded && [n.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue] & AVAudioSessionInterruptionOptionShouldResume) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil]; self.player.defaultRate = self.speed; [self.player playImmediatelyAtRate:self.speed];
    }
    [self refreshButtons];
}
- (void)updateNowPlaying {
    AVPlayerItem *it = self.player.currentItem; double dur = CMTimeGetSeconds(it.duration), cur = CMTimeGetSeconds(self.player.currentTime);
    BOOL playing = self.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[MPMediaItemPropertyTitle] = CleanTitle(self.path.lastPathComponent.stringByDeletingPathExtension);
    d[MPMediaItemPropertyArtist] = @"Flow";
    if (isfinite(dur) && dur > 0) d[MPMediaItemPropertyPlaybackDuration] = @(dur);
    if (isfinite(cur)) d[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(cur);
    d[MPNowPlayingInfoPropertyPlaybackRate] = @(playing ? self.speed : 0);
    d[MPNowPlayingInfoPropertyDefaultPlaybackRate] = @(self.speed);
    UIImage *art = self.art.image;
    if (art) d[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:art.size requestHandler:^UIImage *(CGSize s) { return art; }];
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = d;
}
- (void)teardownBackgroundPlayback {
    for (NSArray *t in self.remoteTokens) [t[0] removeTarget:t[1]];
    self.remoteTokens = nil;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil]; });
}
- (void)togglePlay {
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
        double dur = CMTimeGetSeconds(self.player.currentItem.duration);
        if (isfinite(dur) && CMTimeGetSeconds(self.player.currentTime) >= dur - 0.3) [self.player seekToTime:kCMTimeZero];
        self.player.defaultRate = self.speed; [self.player playImmediatelyAtRate:self.speed]; [self scheduleHide];
    } else { [self.player pause]; [self.hideTimer invalidate]; }
    [self refreshButtons];
}
- (void)seekBy:(double)d {
    double dur = CMTimeGetSeconds(self.player.currentItem.duration); double t = CMTimeGetSeconds(self.player.currentTime) + d;
    t = MAX(0, isfinite(dur) && dur > 0 ? MIN(t, dur) : t);
    [self.player seekToTime:CMTimeMakeWithSeconds(t, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero]; [self tick]; [self updateNowPlaying];
}
- (void)skipBack { [self seekBy:-10]; [self scheduleHide]; }
- (void)skipFwd { [self seekBy:10]; [self scheduleHide]; }
- (void)doubleTap:(UITapGestureRecognizer *)g { [self seekBy:[g locationInView:self.view].x < self.view.bounds.size.width / 2 ? -10 : 10]; }
- (void)scrubStart { self.scrubbing = YES; [self.hideTimer invalidate]; }
- (void)scrubMove { self.tcur.text = FmtDur(self.slider.value); [self.player seekToTime:CMTimeMakeWithSeconds(self.slider.value, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero]; }
- (void)scrubEnd { self.scrubbing = NO; [self updateNowPlaying]; [self scheduleHide]; }
- (void)cycleSpeed {
    NSArray *s = @[ @0.5, @0.75, @1, @1.25, @1.5, @2 ]; NSInteger i = 2;
    for (NSInteger j = 0; j < (NSInteger)s.count; j++) if (fabsf([s[j] floatValue] - self.speed) < 0.01) i = j;
    self.speed = [s[(i + 1) % s.count] floatValue]; self.player.defaultRate = self.speed;
    if (self.player.timeControlStatus != AVPlayerTimeControlStatusPaused) self.player.rate = self.speed;
    [self refreshButtons]; [self scheduleHide];
}
- (void)toggleLoop { self.loop = !self.loop; [self refreshButtons]; }
- (void)ended {
    if (self.loop) { [self.player seekToTime:kCMTimeZero]; [self.player playImmediatelyAtRate:self.speed]; }
    else { [self.player pause]; [self.player seekToTime:kCMTimeZero]; [self refreshButtons]; [self showUI:YES]; }
}
- (void)showUI:(BOOL)on { [UIView animateWithDuration:0.25 animations:^{ self.ui.alpha = on ? 1 : 0; }]; self.ui.userInteractionEnabled = on; if (on) [self scheduleHide]; }
- (void)toggleUI { [self showUI:self.ui.alpha < 0.5]; }
- (void)scheduleHide {
    [self.hideTimer invalidate];
    if (self.audio) return;
    self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 repeats:NO block:^(NSTimer *t) {
        if (self.player.timeControlStatus != AVPlayerTimeControlStatusPaused && !self.scrubbing) { [UIView animateWithDuration:0.3 animations:^{ self.ui.alpha = 0; }]; self.ui.userInteractionEnabled = NO; }
    }];
}
- (void)cleanup {
    if (self.closing) return; self.closing = YES;
    [self.hideTimer invalidate]; if (self.timeObs) { [self.player removeTimeObserver:self.timeObs]; self.timeObs = nil; }
    [[NSNotificationCenter defaultCenter] removeObserver:self]; [self.player pause]; [self teardownBackgroundPlayback];
}
- (void)close {
    // Stop the sound and start dismissing right away; the slow teardown (audio session) happens afterwards on a background queue.
    [self.player pause]; MiniHide(); if (gActivePlayer == self) gActivePlayer = nil;
    if (self.landscape) [self applyOrientation:NO]; else gOrient = UIInterfaceOrientationMaskPortrait;
    [self dismissViewControllerAnimated:YES completion:nil];
    dispatch_async(dispatch_get_main_queue(), ^{ [self cleanup]; });
}
- (void)viewDidDisappear:(BOOL)a { [super viewDidDisappear:a]; if (self.minimized) return; if (self.isBeingDismissed || self.presentingViewController == nil) { [self cleanup]; if (gOrient != UIInterfaceOrientationMaskPortrait) { gOrient = UIInterfaceOrientationMaskPortrait; ForceOrientation(self, gOrient, UIInterfaceOrientationPortrait); } } }
@end
static void OpenFile(UIViewController *vc, NSString *path) {
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) return;
    int k = KindOf(path);
    if (k == 2 || k == 3) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil]; [[AVAudioSession sharedInstance] setActive:YES error:nil];
        @try {
            if (gActivePlayer) [gActivePlayer fullStop];
            PlayerVC *p = [PlayerVC new]; p.path = path; p.modalPresentationStyle = UIModalPresentationFullScreen; (void)p.view;
            [vc presentViewController:p animated:YES completion:nil];
        } @catch (NSException *e) {
            AVPlayerViewController *sp = [AVPlayerViewController new]; sp.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
            [vc presentViewController:sp animated:YES completion:^{ [sp.player play]; }];
        }
    } else Preview(vc, path);
}

#pragma mark - File action sheet

@interface ActionSheetVC : UIViewController
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSArray *tiles; // @[ icon, title, UIColor, block ]
@property(nonatomic, copy) NSArray *rows;  // @[ icon, title, block ]
@end
@implementation ActionSheetVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = IsLightMode() ? [UIColor colorWithWhite:0.95 alpha:1] : (IsBlackMode() ? [UIColor colorWithWhite:0.04 alpha:1] : [UIColor colorWithRed:0.06 green:0.08 blue:0.17 alpha:1]);
    UIScrollView *sv = [UIScrollView new]; sv.translatesAutoresizingMaskIntoConstraints = NO; sv.alwaysBounceVertical = YES; [self.view addSubview:sv];
    UIStackView *st = [UIStackView new]; st.axis = UILayoutConstraintAxisVertical; st.spacing = 14; st.translatesAutoresizingMaskIntoConstraints = NO; [sv addSubview:st];
    int k = KindOf(self.path);
    GlassView *hd = [GlassView new]; hd.translatesAutoresizingMaskIntoConstraints = NO; hd.radius = 22;
    UIImageView *ic = [[UIImageView alloc] initWithImage:Sym(KindSymbol(k), 24, UIFontWeightSemibold)]; ic.translatesAutoresizingMaskIntoConstraints = NO; ic.tintColor = KindColor(k); ic.contentMode = UIViewContentModeCenter; ic.backgroundColor = [KindColor(k) colorWithAlphaComponent:0.2]; ic.layer.cornerRadius = 14; ic.clipsToBounds = YES;
    UILabel *nm = Label(self.path.lastPathComponent, 16, UIFontWeightBold, nil); nm.numberOfLines = 2; nm.lineBreakMode = NSLineBreakByTruncatingMiddle;
    UILabel *sz = Label(FmtSize(SizeOf(self.path)), 13, UIFontWeightMedium, UIColor.secondaryLabelColor);
    [hd.content addSubview:ic]; [hd.content addSubview:nm]; [hd.content addSubview:sz];
    [NSLayoutConstraint activateConstraints:@[ [ic.leadingAnchor constraintEqualToAnchor:hd.content.leadingAnchor constant:14], [ic.centerYAnchor constraintEqualToAnchor:hd.content.centerYAnchor], [ic.widthAnchor constraintEqualToConstant:52], [ic.heightAnchor constraintEqualToConstant:52],
        [nm.leadingAnchor constraintEqualToAnchor:ic.trailingAnchor constant:12], [nm.trailingAnchor constraintEqualToAnchor:hd.content.trailingAnchor constant:-14], [nm.topAnchor constraintEqualToAnchor:hd.content.topAnchor constant:16], [sz.leadingAnchor constraintEqualToAnchor:nm.leadingAnchor], [sz.topAnchor constraintEqualToAnchor:nm.bottomAnchor constant:3],
        [hd.content.bottomAnchor constraintEqualToAnchor:sz.bottomAnchor constant:16], [hd.content.bottomAnchor constraintGreaterThanOrEqualToAnchor:ic.bottomAnchor constant:14] ]];
    [st addArrangedSubview:hd];
    UIStackView *tr = [UIStackView new]; tr.distribution = UIStackViewDistributionFillEqually; tr.spacing = 10;
    for (NSInteger i = 0; i < (NSInteger)self.tiles.count; i++) {
        NSArray *t = self.tiles[i];
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.tag = i; b.backgroundColor = [t[2] colorWithAlphaComponent:0.9]; b.layer.cornerRadius = 20; b.layer.cornerCurve = kCACornerCurveContinuous;
        UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(t[0], 24, UIFontWeightSemibold)]; iv.tintColor = UIColor.whiteColor; iv.contentMode = UIViewContentModeCenter; iv.userInteractionEnabled = NO; iv.translatesAutoresizingMaskIntoConstraints = NO;
        UILabel *l = Label(t[1], 13, UIFontWeightBold, UIColor.whiteColor); l.textAlignment = NSTextAlignmentCenter; l.userInteractionEnabled = NO;
        [b addSubview:iv]; [b addSubview:l];
        [NSLayoutConstraint activateConstraints:@[ [b.heightAnchor constraintEqualToConstant:84], [iv.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [iv.topAnchor constraintEqualToAnchor:b.topAnchor constant:14], [l.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [l.bottomAnchor constraintEqualToAnchor:b.bottomAnchor constant:-12], [l.leadingAnchor constraintGreaterThanOrEqualToAnchor:b.leadingAnchor constant:2], [l.trailingAnchor constraintLessThanOrEqualToAnchor:b.trailingAnchor constant:-2] ]];
        [b addTarget:self action:@selector(tileTap:) forControlEvents:UIControlEventTouchUpInside]; [tr addArrangedSubview:b];
    }
    [st addArrangedSubview:tr];
    GlassView *lg = [GlassView new]; lg.translatesAutoresizingMaskIntoConstraints = NO; lg.radius = 22;
    UIStackView *ls = [UIStackView new]; ls.axis = UILayoutConstraintAxisVertical; ls.translatesAutoresizingMaskIntoConstraints = NO; [lg.content addSubview:ls]; Pin(ls, lg.content, UIEdgeInsetsZero);
    for (NSInteger i = 0; i < (NSInteger)self.rows.count; i++) {
        NSArray *r = self.rows[i];
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.tag = i; [b.heightAnchor constraintEqualToConstant:54].active = YES;
        UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(r[0], 18, UIFontWeightSemibold)]; iv.tintColor = Theme.accent; iv.contentMode = UIViewContentModeCenter; iv.translatesAutoresizingMaskIntoConstraints = NO; iv.userInteractionEnabled = NO;
        UILabel *l = Label(r[1], 16, UIFontWeightSemibold, nil); l.userInteractionEnabled = NO;
        [b addSubview:iv]; [b addSubview:l];
        [NSLayoutConstraint activateConstraints:@[ [iv.leadingAnchor constraintEqualToAnchor:b.leadingAnchor constant:16], [iv.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [iv.widthAnchor constraintEqualToConstant:28], [l.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:10], [l.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [l.trailingAnchor constraintLessThanOrEqualToAnchor:b.trailingAnchor constant:-12] ]];
        [b addTarget:self action:@selector(rowTap:) forControlEvents:UIControlEventTouchUpInside]; [ls addArrangedSubview:b];
        if (i < (NSInteger)self.rows.count - 1) { UIView *sp = [UIView new]; sp.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2]; [sp.heightAnchor constraintEqualToConstant:0.5].active = YES; [ls addArrangedSubview:sp]; }
    }
    [st addArrangedSubview:lg];
    [NSLayoutConstraint activateConstraints:@[ [sv.topAnchor constraintEqualToAnchor:self.view.topAnchor], [sv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [sv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [sv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [st.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:26], [st.leadingAnchor constraintEqualToAnchor:sv.frameLayoutGuide.leadingAnchor constant:16], [st.trailingAnchor constraintEqualToAnchor:sv.frameLayoutGuide.trailingAnchor constant:-16], [st.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-30] ]];
}
- (void)runBlock:(void (^)(void))b { [self dismissViewControllerAnimated:YES completion:^{ if (b) b(); }]; }
- (void)tileTap:(UIButton *)b { [self runBlock:self.tiles[b.tag][3]]; }
- (void)rowTap:(UIButton *)b { [self runBlock:self.rows[b.tag][2]]; }
@end

#pragma mark - Files screen

static UIDocumentInteractionController *gDIC;

#pragma mark - Fetch missing covers (iTunes Search, Deezer fallback)

@interface CoverJob : NSObject
@property(atomic) BOOL cancel;
@property(atomic) NSInteger total, done, found;
@end
@implementation CoverJob @end

static NSData *EmbeddedArtData(NSString *path) {
    AVURLAsset *as = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [as loadValuesAsynchronouslyForKeys:@[ @"commonMetadata", @"metadata" ] completionHandler:^{ dispatch_semaphore_signal(sem); }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC));
    AVMetadataItem *mi = [AVMetadataItem metadataItemsFromArray:as.commonMetadata filteredByIdentifier:AVMetadataCommonIdentifierArtwork].firstObject;
    if (!mi) mi = [AVMetadataItem metadataItemsFromArray:as.metadata filteredByIdentifier:AVMetadataIdentifieriTunesMetadataCoverArt].firstObject;
    if (!mi) mi = [AVMetadataItem metadataItemsFromArray:as.metadata filteredByIdentifier:AVMetadataIdentifierID3MetadataAttachedPicture].firstObject;
    return mi.dataValue;
}
static BOOL TokIsAr(NSString *t) { for (NSUInteger i = 0; i < t.length; i++) { unichar c = [t characterAtIndex:i]; if (c >= 0x0600 && c <= 0x06FF) return YES; } return NO; }
static NSString *CoverNorm(NSString *s) {
    NSMutableString *m = [[s stringByFoldingWithOptions:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch locale:nil] mutableCopy];
    for (NSArray *p in @[ @[ @"أ", @"ا" ], @[ @"إ", @"ا" ], @[ @"آ", @"ا" ], @[ @"ٱ", @"ا" ], @[ @"ى", @"ي" ], @[ @"ة", @"ه" ], @[ @"ـ", @"" ], @[ @"ؤ", @"و" ], @[ @"ئ", @"ي" ] ]) [m replaceOccurrencesOfString:p[0] withString:p[1] options:0 range:NSMakeRange(0, m.length)];
    return m;
}
static NSArray<NSString *> *CoverTokens(NSString *s) {
    static NSSet *stop; if (!stop) stop = [NSSet setWithArray:@[ @"the", @"feat", @"ft", @"and", @"with", @"mp3", @"m4a", @"official", @"audio", @"video", @"lyrics", @"lyric", @"من", @"في" ]];
    NSMutableArray *r = [NSMutableArray array];
    for (NSString *t in [CoverNorm(s) componentsSeparatedByCharactersInSet:NSCharacterSet.alphanumericCharacterSet.invertedSet]) if (t.length >= 2 && ![stop containsObject:t]) [r addObject:t];
    return r;
}
static NSString *CoverCleanName(NSString *file) {
    NSString *s = CleanTitle(file.stringByDeletingPathExtension);
    for (NSString *pat in @[ @"\\[[^\\]]*\\]", @"\\([^)]*\\)", @"(?i)\\b(official|audio|video|lyrics?|music video|clip|hd|hq|mp3|m4a|\\d{2,3} ?k(bps)?)\\b", @"كليب|اوديو|أوديو|كلمات" ]) {
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pat options:0 error:nil];
        if (re) s = [re stringByReplacingMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@" "];
    }
    s = [[s stringByReplacingOccurrencesOfString:@"_" withString:@" "] stringByReplacingOccurrencesOfString:@"|" withString:@" "];
    return [[s componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet] componentsJoinedByString:@" "];
}
static NSData *CoverGET(NSString *url, NSInteger *status) {
    NSURL *u = [NSURL URLWithString:url]; if (!u) return nil;
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u]; r.timeoutInterval = 15;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0); __block NSData *out = nil; __block NSInteger st = 0;
    [[NSURLSession.sharedSession dataTaskWithRequest:r completionHandler:^(NSData *d, NSURLResponse *resp, NSError *e) {
        st = [resp isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)resp).statusCode : 0; if (!e && st == 200) out = d; dispatch_semaphore_signal(sem);
    }] resume];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));
    if (status) *status = st; return out;
}
// Conservative: the candidate's own words must be found in the file name (same script), and the artist must be present too.
static double CoverScore(NSArray *fileToks, NSString *title, NSString *artist) {
    NSArray *T = CoverTokens(title), *A = CoverTokens(artist);
    if (!T.count || !A.count) return 0;
    NSMutableArray *all = [NSMutableArray arrayWithArray:T]; [all addObjectsFromArray:A];
    NSInteger ar = 0; for (NSString *t in all) if (TokIsAr(t)) ar++;
    BOOL cAr = ar * 2 > (NSInteger)all.count;
    NSMutableSet *F = [NSMutableSet set]; for (NSString *t in fileToks) if (TokIsAr(t) == cAr) [F addObject:t];
    if (!F.count) return 0;
    NSInteger tHit = 0; for (NSString *t in T) if ([F containsObject:t]) tHit++;
    NSInteger aHit = 0; for (NSString *t in A) if ([F containsObject:t]) aHit++;
    double tc = (double)tHit / T.count;
    if (tc < 0.99 || aHit == 0) return 0;
    NSMutableSet *U = [NSMutableSet setWithArray:all]; NSInteger fHit = 0; for (NSString *t in F) if ([U containsObject:t]) fHit++;
    double fc = (double)fHit / F.count;
    return fc < 0.7 ? 0 : fc;
}
static NSData *CoverJPEG600(NSData *d) {
    if (!d.length) return nil;
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)d, NULL); if (!src) return nil;
    CGImageRef cg = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)@{ (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES, (id)kCGImageSourceThumbnailMaxPixelSize: @600, (id)kCGImageSourceCreateThumbnailWithTransform: @YES });
    CFRelease(src); if (!cg) return nil;
    UIImage *i = [UIImage imageWithCGImage:cg]; CGImageRelease(cg);
    if (i.size.width < 100) return nil;
    return UIImageJPEGRepresentation(i, 0.88);
}
// Returns JPEG data of the best confident match, or nil.
static NSData *CoverLookup(NSString *q, NSArray *fileToks, CoverJob *job) {
    NSString *enc = [q stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    // iTunes (about 20 requests a minute are allowed, so keep a gap)
    NSInteger st = 0;
    NSData *d = CoverGET([NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@&entity=song&limit=10", enc], &st);
    [NSThread sleepForTimeInterval:3.2];
    if (st == 403 || st == 429) [NSThread sleepForTimeInterval:15];
    if (job.cancel) return nil;
    NSString *best = nil; double bs = 0;
    NSDictionary *j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
    for (NSDictionary *r in [j[@"results"] isKindOfClass:NSArray.class] ? j[@"results"] : @[]) {
        double s = CoverScore(fileToks, r[@"trackName"] ?: @"", r[@"artistName"] ?: @"");
        NSString *art = r[@"artworkUrl100"]; if (s > bs && art.length) { bs = s; best = [art stringByReplacingOccurrencesOfString:@"100x100bb" withString:@"600x600bb"]; }
    }
    if (best) { NSData *img = CoverJPEG600(CoverGET(best, NULL)); if (img) return img; }
    if (job.cancel) return nil;
    // Deezer fallback
    d = CoverGET([NSString stringWithFormat:@"https://api.deezer.com/search?q=%@&limit=10", enc], &st);
    [NSThread sleepForTimeInterval:1.2];
    j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil; best = nil; bs = 0;
    for (NSDictionary *r in [j[@"data"] isKindOfClass:NSArray.class] ? j[@"data"] : @[]) {
        if (![r isKindOfClass:NSDictionary.class]) continue;
        NSString *art = r[@"album"][@"cover_xl"] ?: r[@"album"][@"cover_big"];
        double s = CoverScore(fileToks, r[@"title"] ?: @"", r[@"artist"][@"name"] ?: @"");
        if (s > bs && art.length) { bs = s; best = art; }
    }
    if (best) return CoverJPEG600(CoverGET(best, NULL));
    return nil;
}
static NSData *CoverFind(NSString *fileName, CoverJob *job) {
    NSString *clean = CoverCleanName(fileName);
    NSArray *ft = CoverTokens(clean);
    if (ft.count < 2) return nil;
    NSMutableArray *lat = [NSMutableArray array], *arb = [NSMutableArray array];
    for (NSString *w in [clean componentsSeparatedByString:@" "]) { NSArray *t = CoverTokens(w); if (!t.count) continue; [(TokIsAr(t[0]) ? arb : lat) addObject:w]; }
    NSMutableArray *qs = [NSMutableArray arrayWithObject:clean];
    NSString *ql = [lat componentsJoinedByString:@" "], *qa = [arb componentsJoinedByString:@" "];
    if (lat.count >= 2 && ![ql isEqualToString:clean]) [qs addObject:ql];
    if (arb.count >= 2 && ![qa isEqualToString:clean]) [qs addObject:qa];
    for (NSString *q in qs) { if (job.cancel) return nil; NSData *r = CoverLookup(q, ft, job); if (r) return r; }
    return nil;
}

@interface FilesVC : BaseVC <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIDocumentPickerDelegate>
@property(nonatomic, copy) NSString *dir;
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) NSArray<NSString *> *items;
@property(nonatomic, strong) UISegmentedControl *seg;
@property(nonatomic, strong) UISearchBar *search;
@property(nonatomic, strong) UIView *header, *empty, *emptyFilter;
@property(nonatomic, strong) NSLayoutConstraint *emptyTop, *emptyTop2;
@property(nonatomic, copy) NSString *listSig;
@property(nonatomic) BOOL selecting, loading, reloadAgain, endPull;
@property(nonatomic, strong) NSMutableSet<NSString *> *sel;
@end
@implementation FilesVC
- (UIView *)quickTile:(NSString *)icon title:(NSString *)title color:(UIColor *)col sel:(SEL)s {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.translatesAutoresizingMaskIntoConstraints = NO;
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 18; g.userInteractionEnabled = NO;
    UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(icon, 20, UIFontWeightSemibold)]; iv.tintColor = col; iv.contentMode = UIViewContentModeCenter; iv.translatesAutoresizingMaskIntoConstraints = NO;
    [g.content addSubview:iv]; [b addSubview:g];
    UILabel *l = Label(title, 10.5, UIFontWeightBold, nil); l.textAlignment = NSTextAlignmentCenter; l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.7; l.userInteractionEnabled = NO; [b addSubview:l];
    [NSLayoutConstraint activateConstraints:@[ [g.topAnchor constraintEqualToAnchor:b.topAnchor], [g.leadingAnchor constraintEqualToAnchor:b.leadingAnchor constant:4], [g.trailingAnchor constraintEqualToAnchor:b.trailingAnchor constant:-4], [g.heightAnchor constraintEqualToConstant:50],
        [iv.centerXAnchor constraintEqualToAnchor:g.content.centerXAnchor], [iv.centerYAnchor constraintEqualToAnchor:g.content.centerYAnchor],
        [l.topAnchor constraintEqualToAnchor:g.bottomAnchor constant:5], [l.leadingAnchor constraintEqualToAnchor:b.leadingAnchor], [l.trailingAnchor constraintEqualToAnchor:b.trailingAnchor] ]];
    [b addTarget:self action:s forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.dir) self.dir = Docs();
    self.sel = [NSMutableSet set];
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
    BOOL root = [self.dir isEqualToString:Docs()];
    self.title = root ? @"My Files" : self.dir.lastPathComponent;
    self.navigationItem.largeTitleDisplayMode = root ? UINavigationItemLargeTitleDisplayModeAlways : UINavigationItemLargeTitleDisplayModeNever;
    self.table = MakeTable(self); [self.view addSubview:self.table];
    AddPull(self.table, self);
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 206)];
    UIStackView *q = [UIStackView new]; q.distribution = UIStackViewDistributionFillEqually; q.translatesAutoresizingMaskIntoConstraints = NO; q.tag = 77;
    [q addArrangedSubview:[self quickTile:@"folder.badge.plus" title:T(@"New folder") color:[UIColor systemYellowColor] sel:@selector(newFolder)]];
    [q addArrangedSubview:[self quickTile:@"square.and.arrow.down" title:T(@"Import files") color:[UIColor systemBlueColor] sel:@selector(importFiles)]];
    [q addArrangedSubview:[self quickTile:@"photo.on.rectangle" title:T(@"From Photos") color:[UIColor systemPinkColor] sel:@selector(fromPhotos)]];
    [q addArrangedSubview:[self quickTile:@"wand.and.stars" title:L(@"Tools", @"أدوات") color:[UIColor systemPurpleColor] sel:@selector(openTools)]];
    [q addArrangedSubview:[self quickTile:@"checkmark.circle" title:T(@"Select") color:[UIColor systemGreenColor] sel:@selector(toggleSelect)]];
    [self.header addSubview:q];
    [NSLayoutConstraint activateConstraints:@[ [q.topAnchor constraintEqualToAnchor:self.header.topAnchor constant:4], [q.leadingAnchor constraintEqualToAnchor:self.header.leadingAnchor constant:10], [q.trailingAnchor constraintEqualToAnchor:self.header.trailingAnchor constant:-10], [q.heightAnchor constraintEqualToConstant:70] ]];
    self.search = [UISearchBar new]; self.search.searchBarStyle = UISearchBarStyleMinimal; self.search.placeholder = T(@"Search"); self.search.delegate = self; self.search.autocapitalizationType = UITextAutocapitalizationTypeNone; self.search.translatesAutoresizingMaskIntoConstraints = NO;
    self.seg = [[UISegmentedControl alloc] initWithItems:@[ T(@"All"), T(@"Folders"), T(@"Images"), T(@"Video"), T(@"Audio"), T(@"Documents") ]];
    self.seg.selectedSegmentIndex = 0; [self.seg addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.seg setTitleTextAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold] } forState:UIControlStateNormal];
    self.seg.translatesAutoresizingMaskIntoConstraints = NO;
    [self.header addSubview:self.search]; [self.header addSubview:self.seg];
    [NSLayoutConstraint activateConstraints:@[
        [self.search.topAnchor constraintEqualToAnchor:q.bottomAnchor constant:14], [self.search.leadingAnchor constraintEqualToAnchor:self.header.leadingAnchor constant:8], [self.search.trailingAnchor constraintEqualToAnchor:self.header.trailingAnchor constant:-8], [self.search.heightAnchor constraintEqualToConstant:52],
        [self.seg.topAnchor constraintEqualToAnchor:self.search.bottomAnchor constant:6], [self.seg.leadingAnchor constraintEqualToAnchor:self.header.leadingAnchor constant:16], [self.seg.trailingAnchor constraintEqualToAnchor:self.header.trailingAnchor constant:-16], [self.seg.heightAnchor constraintEqualToConstant:34] ]];
    self.table.tableHeaderView = self.header;
    self.empty = EmptyState(@"folder", T(@"This folder is empty"), T(@"Use + to add a folder or import files."));
    self.emptyFilter = EmptyState(@"magnifyingglass", L(@"Nothing here", @"مفيش حاجة هنا"), L(@"No items match this filter or search.", @"مفيش عناصر بتطابق الفلتر أو البحث ده."));
    // Empty states live inside the table's scroll content, directly under the header, so they move exactly with it (no lag while pulling).
    for (UIView *ev in @[ self.empty, self.emptyFilter ]) { ev.translatesAutoresizingMaskIntoConstraints = YES; ev.userInteractionEnabled = NO; [self.table addSubview:ev]; }
    self.emptyFilter.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NotifJobs object:nil];
    [self updateBar];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.table.bounds.size.width;
    for (UIView *ev in @[ self.empty, self.emptyFilter ]) {
        CGSize sz = [ev systemLayoutSizeFittingSize:CGSizeMake(MIN(280, w), 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        CGFloat cy = self.view.bounds.size.height / 2 + 90 - self.table.frame.origin.y;   // same resting spot as before: a bit below the middle of the screen
        ev.frame = CGRectMake(floor((w - sz.width) / 2), MAX(206 + 36, floor(cy - sz.height / 2)), sz.width, sz.height);
    }
    if (self.header.frame.size.width != w) {
        self.header.frame = CGRectMake(0, 0, w, 206);
        self.table.tableHeaderView = self.header;
    }
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; TrashAutoPurge(); [self updateBar]; [self reload]; }
- (void)themeChanged { [super themeChanged]; [self.table reloadData]; }
- (void)searchBar:(UISearchBar *)b textDidChange:(NSString *)t { [self reload]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)b { [b resignFirstResponder]; }
- (void)fetchCovers {
    NSString *dir = self.dir; CoverJob *job = [CoverJob new];
    UIAlertController *al = [UIAlertController alertControllerWithTitle:L(@"Fetching covers", @"بجيب الأغلفة") message:L(@"Scanning audio files...", @"بفحص ملفات الصوت...") preferredStyle:UIAlertControllerStyleAlert];
    [al addAction:[UIAlertAction actionWithTitle:L(@"Cancel", @"إلغاء") style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) { job.cancel = YES; }]];
    [self presentViewController:al animated:YES completion:nil];
    __weak FilesVC *ws = self; __weak UIAlertController *wal = al;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSMutableArray *todo = [NSMutableArray array];
        for (NSString *n in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:nil]) {
            if ([n hasPrefix:@"."]) continue;
            NSString *p = [dir stringByAppendingPathComponent:n];
            if (KindOf(p) != 3 || [NSFileManager.defaultManager fileExistsAtPath:ThumbPath(p)]) continue;
            if (EmbeddedArtData(p).length) continue;
            [todo addObject:n];
        }
        job.total = todo.count;
        for (NSString *n in todo) {
            if (job.cancel) break;
            dispatch_async(dispatch_get_main_queue(), ^{ wal.message = [NSString stringWithFormat:@"%@ %ld / %ld\n%@", L(@"Checked", @"اتفحص"), (long)job.done, (long)job.total, CleanTitle(n.stringByDeletingPathExtension)]; });
            NSData *img = CoverFind(n, job);
            if (img && !job.cancel) { [img writeToFile:ThumbPath([dir stringByAppendingPathComponent:n]) atomically:YES]; job.found++; }
            job.done++;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [gThumbs removeAllObjects]; [ws reload];
            void (^summary)(void) = ^{
                NSString *t = job.total == 0 ? L(@"Every audio file here already has a cover.", @"كل ملفات الصوت هنا عندها غلاف.")
                    : [NSString stringWithFormat:@"%@ %ld %@ %ld%@", job.cancel ? L(@"Stopped. Found", @"اتوقف. لقيت") : L(@"Found", @"لقيت"), (long)job.found, L(@"of", @"من"), (long)job.total, job.total ? L(@" files without a cover. Songs with no confident match were left alone.", @" ملف من غير غلاف. الأغاني اللي ملقتش ليها تطابق أكيد اتسابت زي ما هي.") : @""];
                UIAlertController *d = [UIAlertController alertControllerWithTitle:L(@"Covers", @"الأغلفة") message:t preferredStyle:UIAlertControllerStyleAlert];
                [d addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [ws presentViewController:d animated:YES completion:nil];
            };
            if (wal && wal.presentingViewController) [wal dismissViewControllerAnimated:YES completion:summary]; else if (job.cancel) summary();
        });
    });
}
- (UIMenu *)sortMenu {
    NSInteger cur = [UD() integerForKey:@"sortby"];
    NSArray *groups = @[
        @[ L(@"Date added", @"تاريخ الإضافة"), @[ @[ L(@"Oldest first (newest at the end)", @"الأقدم الأول (الأحدث في الآخر)"), @3 ], @[ L(@"Newest first", @"الأحدث الأول"), @1 ] ] ],
        @[ L(@"Name", @"الاسم"), @[ @[ L(@"A to Z", @"من أ إلى ي"), @0 ], @[ L(@"Z to A", @"من ي إلى أ"), @4 ] ] ],
        @[ L(@"Size", @"الحجم"), @[ @[ L(@"Largest first", @"الأكبر الأول"), @2 ], @[ L(@"Smallest first", @"الأصغر الأول"), @5 ] ] ] ];
    NSMutableArray *secs = [NSMutableArray array];
    for (NSArray *g in groups) {
        NSMutableArray *acts = [NSMutableArray array];
        for (NSArray *o in g[1]) {
            NSInteger v = [o[1] integerValue];
            UIAction *a = [UIAction actionWithTitle:o[0] image:nil identifier:nil handler:^(UIAction *x) { [UD() setInteger:v forKey:@"sortby"]; [self updateBar]; [self reload]; }];
            a.state = v == cur ? UIMenuElementStateOn : UIMenuElementStateOff; [acts addObject:a];
        }
        [secs addObject:[UIMenu menuWithTitle:g[0] image:nil identifier:nil options:UIMenuOptionsDisplayInline children:acts]];
    }
    UIAction *fc = [UIAction actionWithTitle:L(@"Fetch missing covers", @"هات الأغلفة الناقصة") image:[UIImage systemImageNamed:@"photo.on.rectangle.angled"] identifier:nil handler:^(UIAction *x) { [self fetchCovers]; }];
    [secs addObject:[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[ fc ]]];
    return [UIMenu menuWithTitle:L(@"Sort by", @"ترتيب حسب") children:secs];
}
- (void)updateBar {
    NSString *t = self.selecting ? (self.sel.count ? [NSString stringWithFormat:@"%@ (%lu)", T(@"Delete"), (unsigned long)self.sel.count] : T(@"Done ")) : nil;
    if (!t) {
        BOOL full = TrashItems().count > 0;
        UIBarButtonItem *tb = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:full ? @"trash.fill" : @"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(openTrash)];
        tb.accessibilityLabel = L(@"Trash", @"سلة المحذوفات"); tb.tintColor = Theme.accent;
        UIBarButtonItem *sb = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle"] menu:[self sortMenu]];
        sb.accessibilityLabel = L(@"Sort", @"ترتيب"); sb.tintColor = Theme.accent;
        self.navigationItem.rightBarButtonItems = @[ tb, sb ]; return; }
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:t style:UIBarButtonItemStylePlain target:self action:@selector(barTapped)];
    b.tintColor = self.sel.count ? [UIColor systemRedColor] : Theme.accent; self.navigationItem.rightBarButtonItem = b;
}
- (void)toggleSelect { self.selecting = !self.selecting; [self.sel removeAllObjects]; [self updateBar]; [self.table reloadData]; }
- (void)barTapped {
    if (self.sel.count) {
        NSArray *paths = self.sel.allObjects;
        UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Move to Trash?", @"تنقله لسلة المحذوفات؟") message:L(@"You can restore it later from Trash.", @"تقدر ترجعه بعدين من سلة المحذوفات.") preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:T(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
            for (NSString *p in paths) TrashMove(p);
            self.selecting = NO; [self.sel removeAllObjects]; [self updateBar]; [self reload]; [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil]; }]];
        [self presentViewController:a animated:YES completion:nil];
    } else [self toggleSelect];
}
// The folder is scanned and sorted on a background queue (big folders took seconds on the main thread and froze pull-to-refresh).
// Attributes are read once per file, not once per sort comparison.
- (void)reload {
    if (self.loading) { self.reloadAgain = YES; return; }
    self.loading = YES;
    NSString *dir = self.dir, *q = self.search.text ?: @""; NSInteger f = self.seg.selectedSegmentIndex;
    NSInteger sort = [UD() integerForKey:@"sortby"]; BOOL foldersFirst = [UD() objectForKey:@"foldersfirst"] == nil || [UD() boolForKey:@"foldersfirst"];
    BOOL sel = self.selecting; NSUInteger selN = self.sel.count; BOOL ar = IsAr();
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSFileManager *fm = NSFileManager.defaultManager;
        NSMutableArray *all = [NSMutableArray array]; NSMutableDictionary *info = [NSMutableDictionary dictionary];
        for (NSString *n in [fm contentsOfDirectoryAtPath:dir error:nil]) {
            if (IsInternalName(n)) continue;
            if ([n hasPrefix:@"."]) continue;
            NSString *p = [dir stringByAppendingPathComponent:n];
            int k = KindOf(p);
            if (f == 1 && k != 0) continue;
            if (f == 2 && k != 1) continue;
            if (f == 3 && k != 2) continue;
            if (f == 4 && k != 3) continue;
            if (f == 5 && !(k == 4 || k == 5 || k == 6)) continue;
            if (q.length && [n rangeOfString:q options:NSCaseInsensitiveSearch].location == NSNotFound) continue;
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(k == 0), @"folder", @(IsPinned(p)), @"pin", nil];
            if (sort == 1 || sort == 3) { NSDictionary *at = [fm attributesOfItemAtPath:p error:nil]; d[@"date"] = at.fileCreationDate ?: at.fileModificationDate ?: NSDate.distantPast; }
            if (sort == 2 || sort == 5) d[@"size"] = @(SizeOf(p));
            info[p] = d; [all addObject:p];
        }
        [all sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
            NSDictionary *ia = info[a], *ib = info[b];
            BOOL pa = [ia[@"pin"] boolValue], pb = [ib[@"pin"] boolValue]; if (pa != pb) return pa ? NSOrderedAscending : NSOrderedDescending;
            if (foldersFirst) { BOOL ka = [ia[@"folder"] boolValue], kb = [ib[@"folder"] boolValue]; if (ka != kb) return ka ? NSOrderedAscending : NSOrderedDescending; }
            if (sort == 1 || sort == 3) { NSComparisonResult r = [ia[@"date"] compare:ib[@"date"]]; if (r != NSOrderedSame) return sort == 1 ? -r : r; }
            if (sort == 2 || sort == 5) { int64_t sa = [ia[@"size"] longLongValue], sb = [ib[@"size"] longLongValue]; if (sa != sb) return (sa > sb) == (sort == 2) ? NSOrderedAscending : NSOrderedDescending; }
            if (sort == 4) return [b.lastPathComponent localizedStandardCompare:a.lastPathComponent];
            return [a.lastPathComponent localizedStandardCompare:b.lastPathComponent];
        }];
        NSString *sig = [NSString stringWithFormat:@"%@|%ld|%@|%d|%lu|%ld|%ld", [all componentsJoinedByString:@"\n"], (long)f, q, (int)sel, (unsigned long)selN, (long)(ar ? 1 : 0), (long)sort];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (![dir isEqualToString:self.dir]) return;
            BOOL filtered = self.search.text.length || self.seg.selectedSegmentIndex != 0;
            self.empty.hidden = all.count > 0 || filtered;
            self.emptyFilter.hidden = all.count > 0 || !filtered;
            // Only rebuild the table when the list really changed, otherwise the header jumps. Sizes of growing files refresh in place.
            BOOL same = self.listSig && [sig isEqualToString:self.listSig] && self.items.count == all.count;
            self.items = all; self.listSig = sig;
            if (same) { NSArray *vis = self.table.indexPathsForVisibleRows; if (vis.count) [UIView performWithoutAnimation:^{ [self.table reloadRowsAtIndexPaths:vis withRowAnimation:UITableViewRowAnimationNone]; }]; }
            else [self.table reloadData];
            if (self.endPull) { self.endPull = NO; EndPull(self.table); }
            if (self.reloadAgain) { self.reloadAgain = NO; [self reload]; }
        });
    });
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.items.count; }
- (NSString *)kindName:(int)k { return @[ L(@"Folder", @"مجلد"), L(@"Image", @"صورة"), L(@"Video", @"فيديو"), L(@"Audio", @"صوت"), L(@"Document", @"مستند"), L(@"Archive", @"أرشيف"), L(@"File", @"ملف") ][k]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"f"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"f"];
    NSString *p = self.items[ip.row]; int k = KindOf(p);
    c.title.text = CleanTitle(p.lastPathComponent); c.represent = p;
    [c setSymbol:KindSymbol(k) color:KindColor(k) ring:-1];
    [c setPillText:[self kindName:k] color:[KindColor(k) colorWithAlphaComponent:0.9]];
    NSString *pin = IsPinned(p) ? [NSString stringWithFormat:@"  ·  %@", L(@"Pinned", @"مثبت")] : @"";
    if (k == 0) {
        NSUInteger n = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:p error:nil] count];
        c.sub.text = [NSString stringWithFormat:@"%lu %@%@", (unsigned long)n, T(n == 1 ? @"item" : @"items"), pin];
    } else {
        NSDate *d = [[NSFileManager.defaultManager attributesOfItemAtPath:p error:nil] fileModificationDate];
        NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterNoStyle;
        if (IsAr()) f.locale = [NSLocale localeWithLocaleIdentifier:@"ar_EG"];
        c.sub.text = [NSString stringWithFormat:@"%@  ·  %@%@", FmtSize(SizeOf(p)), d ? [f stringFromDate:d] : @"", pin];
    }
    if (k == 1 || k == 2 || k == 3 || [NSFileManager.defaultManager fileExistsAtPath:ThumbPath(p)]) { __weak RowCell *w = c; ThumbFor(p, ^(UIImage *i) { if ([w.represent isEqualToString:p]) [w setThumbImage:i]; }); }
    c.more.menu = [self menuFor:p];
    [c setSelecting:self.selecting selected:[self.sel containsObject:p]];
    return c;
}
- (UIMenu *)menuFor:(NSString *)p {
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:[UIAction actionWithTitle:L(@"More options…", @"خيارات أكتر…") image:[UIImage systemImageNamed:@"slider.horizontal.3"] identifier:nil handler:^(UIAction *x) { [self openSheet:p]; }]];
    [a addObject:[UIAction actionWithTitle:T(@"Rename") image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(UIAction *x) { [self rename:p]; }]];
    [a addObject:[UIAction actionWithTitle:T(@"Move") image:[UIImage systemImageNamed:@"folder"] identifier:nil handler:^(UIAction *x) { [self move:p]; }]];
    if (KindOf(p) != 0) [a addObject:[UIAction actionWithTitle:T(@"Share") image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(UIAction *x) { Share(self, p); }]];
    UIAction *del = [UIAction actionWithTitle:T(@"Delete") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction *x) { [self confirmDelete:p]; }];
    del.attributes = UIMenuElementAttributesDestructive; [a addObject:del];
    return [UIMenu menuWithTitle:@"" children:a];
}
- (void)openSheet:(NSString *)p {
    int k = KindOf(p); BOOL folder = k == 0, media = (k == 2 || k == 3);
    ActionSheetVC *s = [ActionSheetVC new]; s.path = p;
    NSMutableArray *tiles = [NSMutableArray array];
    [tiles addObject:@[ @"folder.fill", T(@"Move"), [UIColor systemBlueColor], ^{ [self move:p]; } ]];
    if (!folder) [tiles addObject:@[ @"square.and.arrow.up", T(@"Share"), [UIColor systemGreenColor], ^{ Share(self, p); } ]];
    [tiles addObject:@[ @"pencil", T(@"Rename"), [UIColor systemOrangeColor], ^{ [self rename:p]; } ]];
    [tiles addObject:@[ @"trash.fill", T(@"Delete"), [UIColor systemRedColor], ^{ [self confirmDelete:p]; } ]];
    NSMutableArray *rows = [NSMutableArray array];
    if (!folder) [rows addObject:@[ @"arrow.up.forward.app", L(@"Open with…", @"فتح بواسطة…"), ^{ [self openWith:p]; } ]];
    [rows addObject:@[ IsPinned(p) ? @"pin.slash" : @"pin", IsPinned(p) ? L(@"Unpin", @"إلغاء التثبيت") : L(@"Pin to top", @"تثبيت في الأول"), ^{ TogglePin(p); [self reload]; } ]];
    [rows addObject:@[ @"plus.square.on.square", L(@"Duplicate", @"نسخة مكررة"), ^{ [self duplicate:p]; } ]];
    if (k == 2 || k == 1) [rows addObject:@[ @"rectangle.compress.vertical", L(@"Compress", @"ضغط"), ^{ [self compress:p]; } ]];
    [rows addObject:@[ @"info.circle", L(@"Info", @"معلومات"), ^{ [self info:p]; } ]];
    if (media) [rows addObject:@[ @"bell.badge", L(@"Convert to ringtone", @"تحويل لنغمة رنين"), ^{ OpenRingtone(self, p); } ]];
    if (media) [rows addObject:@[ @"arrow.triangle.2.circlepath", L(@"Convert…", @"تحويل…"), ^{ ConvertMenu(self, p); } ]];
    if (k == 1) [rows addObject:@[ @"person.crop.circle.badge.minus", L(@"Remove background (people)", @"إزالة الخلفية (أشخاص)"), ^{ RemoveBGPath(self, p); } ]];
    if (k == 1 || k == 2) [rows addObject:@[ @"photo.on.rectangle.angled", L(@"Save to Photos", @"حفظ في الصور"), ^{ [self saveToPhotos:p]; } ]];
    if (!folder) [rows addObject:@[ @"photo.badge.plus", L(@"Change thumbnail", @"تغيير الصورة المصغرة"), ^{ [self changeThumb:p]; } ]];
    s.tiles = tiles; s.rows = rows;
    if (@available(iOS 15.0, *)) { s.modalPresentationStyle = UIModalPresentationPageSheet; s.sheetPresentationController.detents = @[ UISheetPresentationControllerDetent.largeDetent ]; s.sheetPresentationController.prefersGrabberVisible = YES; }
    [self presentViewController:s animated:YES completion:nil];
}
- (void)openWith:(NSString *)p {
    gDIC = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:p]];
    if (![gDIC presentOpenInMenuFromRect:CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1) inView:self.view animated:YES]) Share(self, p);
}
- (void)duplicate:(NSString *)p {
    NSString *base = p.lastPathComponent.stringByDeletingPathExtension, *ext = p.pathExtension;
    NSString *nn = [base stringByAppendingString:L(@" copy", @" نسخة")]; if (ext.length) nn = [nn stringByAppendingPathExtension:ext];
    NSString *dst = UniquePath(p.stringByDeletingLastPathComponent, nn);
    if (![NSFileManager.defaultManager copyItemAtPath:p toPath:dst error:nil]) Alert(self, @"Could not complete that.", nil);
    [self reload];
}
- (void)compress:(NSString *)p {
    int k = KindOf(p);
    if (k == 2) { ToolConvert(self, p, 3); return; }
    UIImage *i = [UIImage imageWithContentsOfFile:p]; if (!i) { Alert(self, @"Could not complete that.", nil); return; }
    NSData *d = UIImageJPEGRepresentation(Upright(i), 0.55);
    NSString *out = UniquePath(p.stringByDeletingLastPathComponent, [[p.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:L(@" small", @" صغير")] stringByAppendingPathExtension:@"jpg"]);
    [d writeToFile:out atomically:YES]; [self reload];
    Alert(self, @"Done", [NSString stringWithFormat:@"%@ → %@", FmtSize(SizeOf(p)), FmtSize(d.length)]);
}
- (void)info:(NSString *)p {
    NSDictionary *at = [NSFileManager.defaultManager attributesOfItemAtPath:p error:nil];
    NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterShortStyle; if (IsAr()) f.locale = [NSLocale localeWithLocaleIdentifier:@"ar_EG"];
    NSString *m = [NSString stringWithFormat:@"%@: %@\n%@: %@\n%@: %@\n%@: %@", L(@"Type", @"النوع"), [self kindName:KindOf(p)], L(@"Size", @"الحجم"), FmtSize(SizeOf(p)), L(@"Modified", @"آخر تعديل"), at.fileModificationDate ? [f stringFromDate:at.fileModificationDate] : @"-", L(@"Location", @"المكان"), RelPath(p.stringByDeletingLastPathComponent).length < Docs().length && [p.stringByDeletingLastPathComponent isEqualToString:Docs()] ? T(@"Home") : RelPath(p.stringByDeletingLastPathComponent)];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:p.lastPathComponent message:m preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)saveToPhotos:(NSString *)p {
    int k = KindOf(p);
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:^(PHAuthorizationStatus st) {
        if (st != PHAuthorizationStatusAuthorized && st != PHAuthorizationStatusLimited) { dispatch_async(dispatch_get_main_queue(), ^{ Alert(self, @"Could not complete that.", L(@"Photos permission is off. Enable it in iPhone Settings > Flow.", @"إذن الصور مقفول. شغله من إعدادات الموبايل > Flow.")); }); return; }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSURL *u = [NSURL fileURLWithPath:p];
            if (k == 2) [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:u]; else [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:u];
        } completionHandler:^(BOOL ok, NSError *e) { dispatch_async(dispatch_get_main_queue(), ^{ if (ok) Alert(self, @"Done", L(@"Saved to Photos", @"اتحفظ في الصور")); else Alert(self, @"Could not complete that.", e.localizedDescription); }); }];
    }];
}
- (void)changeThumb:(NSString *)p {
    PickPhoto(self, NO, ^(UIImage *img, NSString *n) {
        NSData *d = UIImageJPEGRepresentation(Upright(img), 0.8); [d writeToFile:ThumbPath(p) atomically:YES];
        [gThumbs removeAllObjects]; [self reload];
    }, nil);
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSString *p = self.items[ip.row];
    if (self.selecting) { if ([self.sel containsObject:p]) [self.sel removeObject:p]; else [self.sel addObject:p]; [self updateBar]; [t reloadRowsAtIndexPaths:@[ ip ] withRowAnimation:UITableViewRowAnimationNone]; return; }
    if (KindOf(p) == 0) { FilesVC *v = [FilesVC new]; v.dir = p; [self.navigationController pushViewController:v animated:YES]; }
    else OpenFile(self, p);
}
- (void)openTrash { [self.navigationController pushViewController:[TrashVC new] animated:YES]; }
- (void)openTools { [self.navigationController pushViewController:[ToolsVC new] animated:YES]; }
- (void)fromPhotos {
    PickPhoto(self, YES, nil, ^(NSArray<NSURL *> *urls) {
        for (NSURL *u in urls) { NSString *dst = UniquePath(self.dir, SafeName(u.lastPathComponent)); [NSFileManager.defaultManager copyItemAtPath:u.path toPath:dst error:nil]; }
        [self reload]; });
}
- (void)newFolder {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:T(@"New folder") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) { f.placeholder = T(@"Folder name"); }];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSString *n = SafeName(a.textFields.firstObject.text);
        NSString *p = [self.dir stringByAppendingPathComponent:n];
        if ([NSFileManager.defaultManager fileExistsAtPath:p]) { Alert(self, @"Could not complete that.", @"A file with that name already exists."); return; }
        [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil]; [self reload]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)importFiles {
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ UTTypeItem ] asCopy:YES];
    p.allowsMultipleSelection = YES; p.delegate = self; [self presentViewController:p animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *u in urls) { NSString *dst = UniquePath(self.dir, SafeName(u.lastPathComponent)); [NSFileManager.defaultManager copyItemAtPath:u.path toPath:dst error:nil]; }
    [self reload];
}
- (void)rename:(NSString *)p {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:T(@"Rename") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) { f.text = p.lastPathComponent; f.placeholder = T(@"Name"); }];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSString *n = SafeName(a.textFields.firstObject.text);
        NSString *dst = [p.stringByDeletingLastPathComponent stringByAppendingPathComponent:n];
        if ([dst isEqualToString:p]) return;
        NSError *e = nil;
        if ([NSFileManager.defaultManager fileExistsAtPath:dst] || ![NSFileManager.defaultManager moveItemAtPath:p toPath:dst error:&e]) { Alert(self, @"Could not complete that.", @"A file with that name already exists."); return; }
        [self reload]; [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)allFolders:(NSString *)dir into:(NSMutableArray *)out exclude:(NSString *)ex {
    for (NSString *n in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:nil]) {
        if ([n hasPrefix:@"."]) continue;
        NSString *p = [dir stringByAppendingPathComponent:n];
        if (KindOf(p) != 0 || [p isEqualToString:ex]) continue;
        [out addObject:p]; [self allFolders:p into:out exclude:ex];
    }
}
- (void)move:(NSString *)p {
    NSMutableArray *f = [NSMutableArray arrayWithObject:Docs()]; [self allFolders:Docs() into:f exclude:p];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:T(@"Move to") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *d in f) {
        if ([d isEqualToString:p.stringByDeletingLastPathComponent]) continue;
        NSString *rel = [d isEqualToString:Docs()] ? T(@"Home") : [d substringFromIndex:Docs().length + 1];
        [a addAction:[UIAlertAction actionWithTitle:rel style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
            NSString *dst = UniquePath(d, p.lastPathComponent);
            if (![NSFileManager.defaultManager moveItemAtPath:p toPath:dst error:nil]) Alert(self, @"Could not complete that.", nil);
            [self reload]; [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil]; }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = self.view; a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1);
    [self presentViewController:a animated:YES completion:nil];
}
- (void)confirmDelete:(NSString *)p {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Move to Trash?", @"تنقله لسلة المحذوفات؟") message:L(@"You can restore it later from Trash.", @"تقدر ترجعه بعدين من سلة المحذوفات.") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
        TrashMove(p); [self updateBar]; [self reload]; [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSString *p = self.items[ip.row];
    UIContextualAction *d = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:T(@"Delete") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) { [self confirmDelete:p]; h(YES); }];
    return [UISwipeActionsConfiguration configurationWithActions:@[ d ]];
}
- (void)pullRefresh { self.listSig = nil; self.endPull = YES; [self updateBar]; [self reload]; EndPull(self.table); }
@end
