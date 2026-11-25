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
    NSString *key = [path stringByAppendingFormat:@"|%.0f", [[[NSFileManager.defaultManager attributesOfItemAtPath:ThumbPath(path) error:nil] fileModificationDate] timeIntervalSince1970]];
    UIImage *c = [gThumbs objectForKey:key]; if (c) { cb(c); return; }
    int k = KindOf(path);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        UIImage *img = nil;
        NSString *custom = ThumbPath(path);
        if ([NSFileManager.defaultManager fileExistsAtPath:custom]) img = [UIImage imageWithContentsOfFile:custom];
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

@interface PlayerVC : UIViewController <UIGestureRecognizerDelegate>
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) AVPlayerLayer *pl;
@property(nonatomic, strong) UIView *ui;
@property(nonatomic, strong) GlassView *top, *bot;
@property(nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) UILabel *tcur, *tend;
@property(nonatomic, strong) UIButton *playBtn, *spdBtn, *loopBtn;
@property(nonatomic, strong) UIImageView *art;
@property(nonatomic, strong) id timeObs;
@property(nonatomic, strong) NSTimer *hideTimer;
@property(nonatomic) BOOL scrubbing, audio, loop, failedShown, closing;
@property(nonatomic) float speed;
@end
@implementation PlayerVC
- (BOOL)prefersStatusBarHidden { return NO; }
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
    UIColor *white = UIColor.whiteColor;
    if (self.audio) {
        AuroraView *a = [[AuroraView alloc] initWithFrame:self.view.bounds]; [self.view addSubview:a];
        GlassView *card = [GlassView new]; card.translatesAutoresizingMaskIntoConstraints = NO; card.radius = 44; [self.view addSubview:card];
        UIImageView *ic = [[UIImageView alloc] initWithImage:[Sym(@"music.note", 90, UIFontWeightLight) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]]; ic.tintColor = Theme.accent; ic.contentMode = UIViewContentModeScaleAspectFit; ic.translatesAutoresizingMaskIntoConstraints = NO;
        [card.content addSubview:ic];
        self.art = [UIImageView new]; self.art.translatesAutoresizingMaskIntoConstraints = NO; self.art.contentMode = UIViewContentModeScaleAspectFill; self.art.clipsToBounds = YES; [card.content addSubview:self.art];
        UILabel *nm = Label(self.path.lastPathComponent.stringByDeletingPathExtension, 20, UIFontWeightHeavy, white); nm.textAlignment = NSTextAlignmentCenter; nm.numberOfLines = 2; [self.view addSubview:nm];
        [NSLayoutConstraint activateConstraints:@[
            [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-90],
            [card.widthAnchor constraintEqualToConstant:250], [card.heightAnchor constraintEqualToConstant:250],
            [ic.centerXAnchor constraintEqualToAnchor:card.content.centerXAnchor], [ic.centerYAnchor constraintEqualToAnchor:card.content.centerYAnchor], [ic.widthAnchor constraintEqualToConstant:110], [ic.heightAnchor constraintEqualToConstant:110],
            [self.art.leadingAnchor constraintEqualToAnchor:card.content.leadingAnchor], [self.art.trailingAnchor constraintEqualToAnchor:card.content.trailingAnchor], [self.art.topAnchor constraintEqualToAnchor:card.content.topAnchor], [self.art.bottomAnchor constraintEqualToAnchor:card.content.bottomAnchor],
            [nm.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:26], [nm.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:30], [nm.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-30] ]];
        AVAsset *as = self.player.currentItem.asset; __weak PlayerVC *ws = self;
        [as loadValuesAsynchronouslyForKeys:@[ @"commonMetadata" ] completionHandler:^{
            NSArray *items = [AVMetadataItem metadataItemsFromArray:as.commonMetadata filteredByIdentifier:AVMetadataCommonIdentifierArtwork];
            AVMetadataItem *mi = items.firstObject; NSData *d = mi.dataValue; UIImage *im = d ? [UIImage imageWithData:d] : nil;
            if (im) dispatch_async(dispatch_get_main_queue(), ^{ ws.art.image = im; });
        }];
    } else {
        self.pl = [AVPlayerLayer playerLayerWithPlayer:self.player]; self.pl.videoGravity = AVLayerVideoGravityResizeAspect; [self.view.layer addSublayer:self.pl];
    }
    self.ui = [UIView new]; self.ui.frame = self.view.bounds; self.ui.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; [self.view addSubview:self.ui];
    // top bar
    self.top = [GlassView new]; self.top.translatesAutoresizingMaskIntoConstraints = NO; self.top.radius = 26; [self.ui addSubview:self.top];
    UIButton *x = [self iconBtn:@"xmark" size:17 sel:@selector(close)];
    UILabel *tt = Label(self.path.lastPathComponent, 15, UIFontWeightBold, white); tt.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.top.content addSubview:x]; [self.top.content addSubview:tt];
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
    UIButton *bk = [self iconBtn:@"gobackward.10" size:26 sel:@selector(skipBack)];
    UIButton *fw = [self iconBtn:@"goforward.10" size:26 sel:@selector(skipFwd)];
    GradButton *pb = [GradButton buttonWithType:UIButtonTypeCustom]; pb.translatesAutoresizingMaskIntoConstraints = NO; pb.layer.cornerRadius = 33;
    [pb.widthAnchor constraintEqualToConstant:66].active = YES; [pb.heightAnchor constraintEqualToConstant:66].active = YES; [pb addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    self.playBtn = pb;
    self.loopBtn = [UIButton buttonWithType:UIButtonTypeCustom]; self.loopBtn.translatesAutoresizingMaskIntoConstraints = NO; [self.loopBtn addTarget:self action:@selector(toggleLoop) forControlEvents:UIControlEventTouchUpInside];
    [self.loopBtn.widthAnchor constraintEqualToConstant:52].active = YES; [self.loopBtn.heightAnchor constraintEqualToConstant:48].active = YES;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ self.spdBtn, bk, pb, fw, self.loopBtn ]]; row.axis = UILayoutConstraintAxisHorizontal; row.alignment = UIStackViewAlignmentCenter; row.distribution = UIStackViewDistributionEqualSpacing; row.translatesAutoresizingMaskIntoConstraints = NO;
    for (UIView *v in @[ self.slider, self.tcur, self.tend, row ]) [self.bot.content addSubview:v];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.top.topAnchor constraintEqualToAnchor:g.topAnchor constant:8], [self.top.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14], [self.top.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14], [self.top.heightAnchor constraintEqualToConstant:56],
        [x.leadingAnchor constraintEqualToAnchor:self.top.content.leadingAnchor constant:4], [x.centerYAnchor constraintEqualToAnchor:self.top.content.centerYAnchor],
        [tt.leadingAnchor constraintEqualToAnchor:x.trailingAnchor constant:4], [tt.trailingAnchor constraintEqualToAnchor:self.top.content.trailingAnchor constant:-18], [tt.centerYAnchor constraintEqualToAnchor:self.top.content.centerYAnchor],
        [self.bot.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14], [self.bot.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14], [self.bot.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-12], [self.bot.heightAnchor constraintEqualToConstant:172],
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
    if ([UD() objectForKey:@"autoplay"] == nil || [UD() boolForKey:@"autoplay"]) { self.player.defaultRate = self.speed; [self.player playImmediatelyAtRate:self.speed]; }
    [self refreshButtons]; [self scheduleHide];
}
- (void)refreshButtons {
    BOOL playing = self.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    SetBtnContent(self.playBtn, Sym(playing ? @"pause.fill" : @"play.fill", 28, UIFontWeightBold), nil, UIColor.whiteColor, 16, 30);
    SetBtnContent(self.spdBtn, nil, [NSString stringWithFormat:@"%gx", self.speed], UIColor.whiteColor, 16, 0);
    SetBtnContent(self.loopBtn, Sym(@"repeat", 20, UIFontWeightBold), nil, self.loop ? Theme.accent : [UIColor colorWithWhite:1 alpha:0.6], 16, 22);
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
    [self.player seekToTime:CMTimeMakeWithSeconds(t, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero]; [self tick];
}
- (void)skipBack { [self seekBy:-10]; [self scheduleHide]; }
- (void)skipFwd { [self seekBy:10]; [self scheduleHide]; }
- (void)doubleTap:(UITapGestureRecognizer *)g { [self seekBy:[g locationInView:self.view].x < self.view.bounds.size.width / 2 ? -10 : 10]; }
- (void)scrubStart { self.scrubbing = YES; [self.hideTimer invalidate]; }
- (void)scrubMove { self.tcur.text = FmtDur(self.slider.value); [self.player seekToTime:CMTimeMakeWithSeconds(self.slider.value, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero]; }
- (void)scrubEnd { self.scrubbing = NO; [self scheduleHide]; }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self]; [self.player pause];
}
- (void)close { [self cleanup]; [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)viewDidDisappear:(BOOL)a { [super viewDidDisappear:a]; if (self.isBeingDismissed || self.presentingViewController == nil) [self cleanup]; }
@end
static void OpenFile(UIViewController *vc, NSString *path) {
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) return;
    int k = KindOf(path);
    if (k == 2 || k == 3) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil]; [[AVAudioSession sharedInstance] setActive:YES error:nil];
        @try {
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

@interface FilesVC : BaseVC <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIDocumentPickerDelegate>
@property(nonatomic, copy) NSString *dir;
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) NSArray<NSString *> *items;
@property(nonatomic, strong) UISegmentedControl *seg;
@property(nonatomic, strong) UISearchBar *search;
@property(nonatomic, strong) UIView *header, *empty;
@property(nonatomic, copy) NSString *listSig;
@property(nonatomic) BOOL selecting;
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
    [self.view addSubview:self.empty];
    NSLayoutConstraint *ecy = [self.empty.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:90]; ecy.priority = UILayoutPriorityDefaultHigh;
    // always below the header (quick tiles, search, filter chips), never on top of it
    [NSLayoutConstraint activateConstraints:@[ [self.empty.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], ecy, [self.empty.topAnchor constraintGreaterThanOrEqualToAnchor:g.topAnchor constant:206 + 24], [self.empty.widthAnchor constraintLessThanOrEqualToConstant:280] ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NotifJobs object:nil];
    [self updateBar];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.table.bounds.size.width;
    if (self.header.frame.size.width != w) {
        self.header.frame = CGRectMake(0, 0, w, 206);
        self.table.tableHeaderView = self.header;
    }
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; TrashAutoPurge(); [self updateBar]; [self reload]; }
- (void)themeChanged { [super themeChanged]; [self.table reloadData]; }
- (void)searchBar:(UISearchBar *)b textDidChange:(NSString *)t { [self reload]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)b { [b resignFirstResponder]; }
- (void)updateBar {
    NSString *t = self.selecting ? (self.sel.count ? [NSString stringWithFormat:@"%@ (%lu)", T(@"Delete"), (unsigned long)self.sel.count] : T(@"Done ")) : nil;
    if (!t) {
        BOOL full = TrashItems().count > 0;
        UIBarButtonItem *tb = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:full ? @"trash.fill" : @"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(openTrash)];
        tb.accessibilityLabel = L(@"Trash", @"سلة المحذوفات"); tb.tintColor = Theme.accent; self.navigationItem.rightBarButtonItem = tb; return; }
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
- (void)reload {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableArray *all = [NSMutableArray array];
    for (NSString *n in [fm contentsOfDirectoryAtPath:self.dir error:nil]) {
        if (IsInternalName(n)) continue;
        if ([n hasPrefix:@"."]) continue;
        NSString *p = [self.dir stringByAppendingPathComponent:n];
        int k = KindOf(p); NSInteger f = self.seg.selectedSegmentIndex;
        if (f == 1 && k != 0) continue;
        if (f == 2 && k != 1) continue;
        if (f == 3 && k != 2) continue;
        if (f == 4 && k != 3) continue;
        if (f == 5 && !(k == 4 || k == 5 || k == 6)) continue;
        NSString *q = self.search.text;
        if (q.length && [n rangeOfString:q options:NSCaseInsensitiveSearch].location == NSNotFound) continue;
        [all addObject:p];
    }
    NSInteger sort = [UD() integerForKey:@"sortby"]; BOOL foldersFirst = [UD() objectForKey:@"foldersfirst"] == nil || [UD() boolForKey:@"foldersfirst"];
    [all sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        BOOL pa = IsPinned(a), pb = IsPinned(b); if (pa != pb) return pa ? NSOrderedAscending : NSOrderedDescending;
        if (foldersFirst) { int ka = KindOf(a) == 0, kb = KindOf(b) == 0; if (ka != kb) return ka ? NSOrderedAscending : NSOrderedDescending; }
        if (sort == 1) { NSDate *da = [[NSFileManager.defaultManager attributesOfItemAtPath:a error:nil] fileModificationDate], *db = [[NSFileManager.defaultManager attributesOfItemAtPath:b error:nil] fileModificationDate]; return [db compare:da ?: NSDate.distantPast]; }
        if (sort == 2) { int64_t sa = SizeOf(a), sb = SizeOf(b); return sa == sb ? NSOrderedSame : (sa > sb ? NSOrderedAscending : NSOrderedDescending); }
        return [a.lastPathComponent localizedStandardCompare:b.lastPathComponent];
    }];
    self.empty.hidden = all.count > 0 || self.search.text.length || self.seg.selectedSegmentIndex != 0;
    // The download timer calls reload twice a second. Only rebuild the table when the list really changed,
    // otherwise the header is re-laid out and jumps. Sizes of growing files are refreshed in place.
    NSString *sig = [NSString stringWithFormat:@"%@|%ld|%@|%d|%lu|%ld", [all componentsJoinedByString:@"\n"], (long)self.seg.selectedSegmentIndex, self.search.text ?: @"", (int)self.selecting, (unsigned long)self.sel.count, (long)(IsAr() ? 1 : 0)];
    BOOL same = self.listSig && [sig isEqualToString:self.listSig] && self.items.count == all.count;
    self.items = all; self.listSig = sig;
    if (same) { NSArray *vis = self.table.indexPathsForVisibleRows; if (vis.count) [UIView performWithoutAnimation:^{ [self.table reloadRowsAtIndexPaths:vis withRowAnimation:UITableViewRowAnimationNone]; }]; return; }
    [self.table reloadData];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.items.count; }
- (NSString *)kindName:(int)k { return @[ L(@"Folder", @"مجلد"), L(@"Image", @"صورة"), L(@"Video", @"فيديو"), L(@"Audio", @"صوت"), L(@"Document", @"مستند"), L(@"Archive", @"أرشيف"), L(@"File", @"ملف") ][k]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"f"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"f"];
    NSString *p = self.items[ip.row]; int k = KindOf(p);
    c.title.text = p.lastPathComponent; c.represent = p;
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
    if (k == 1 || k == 2 || [NSFileManager.defaultManager fileExistsAtPath:ThumbPath(p)]) { __weak RowCell *w = c; ThumbFor(p, ^(UIImage *i) { if ([w.represent isEqualToString:p]) [w setThumbImage:i]; }); }
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
@end
