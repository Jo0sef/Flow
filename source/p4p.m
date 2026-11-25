#pragma mark - Format picker

static NSCache *gImgCache;
static void LoadImage(NSString *url, void (^cb)(UIImage *)) {
    if (!gImgCache) gImgCache = [NSCache new];
    UIImage *c = url ? [gImgCache objectForKey:url] : nil; if (c) { cb(c); return; }
    NSURL *u = url.length ? [NSURL URLWithString:url] : nil; if (!u) return;
    [[NSURLSession.sharedSession dataTaskWithURL:u completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        UIImage *i = d ? [UIImage imageWithData:d] : nil; if (!i) return;
        [gImgCache setObject:i forKey:url]; dispatch_async(dispatch_get_main_queue(), ^{ cb(i); });
    }] resume];
}

@interface PickerVC : UIViewController
@property(nonatomic, copy) NSDictionary *info;
@property(nonatomic, copy) NSArray<NSDictionary *> *fmts;
@property(nonatomic) NSInteger sel;
@property(nonatomic, strong) NSMutableArray<GlassView *> *cards;
@property(nonatomic, weak) UITabBarController *tabs;
@end
@implementation PickerVC
- (NSString *)sizeText:(NSDictionary *)f { int64_t s = [f[@"size"] longLongValue]; return s > 0 ? [@"~" stringByAppendingString:FmtSize(s)] : L(@"Size unknown", @"الحجم مجهول"); }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = IsLightMode() ? [UIColor colorWithWhite:0.95 alpha:1] : (IsBlackMode() ? UIColor.blackColor : [UIColor colorWithRed:0.05 green:0.07 blue:0.16 alpha:1]);
    NSMutableArray *vids = [NSMutableArray array], *auds = [NSMutableArray array];
    for (NSDictionary *f in self.info[@"formats"]) { if ([f[@"kind"] isEqualToString:@"audio"]) [auds addObject:f]; else [vids addObject:f]; }
    [vids sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [b[@"height"] compare:a[@"height"]]; }];
    self.fmts = [vids arrayByAddingObjectsFromArray:auds]; self.sel = 0; self.cards = [NSMutableArray array];
    UIScrollView *sv = [UIScrollView new]; sv.translatesAutoresizingMaskIntoConstraints = NO; sv.alwaysBounceVertical = YES; [self.view addSubview:sv];
    UIView *top = [UIView new]; top.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:top];
    UIImageView *th = [UIImageView new]; th.translatesAutoresizingMaskIntoConstraints = NO; th.contentMode = UIViewContentModeScaleAspectFill; th.clipsToBounds = YES; th.layer.cornerRadius = 20; th.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.25];
    LoadImage(self.info[@"thumb"], ^(UIImage *i) { th.image = i; });
    UILabel *ti = Label(self.info[@"title"] ?: @"", 18, UIFontWeightBold, nil); ti.numberOfLines = 2;
    NSString *up = self.info[@"uploader"] ?: @""; NSString *du = FmtDur([self.info[@"duration"] doubleValue]);
    UILabel *su = Label([[up length] && du.length ? [NSString stringWithFormat:@"%@  ·  %@", up, du] : [up stringByAppendingString:du]  copy], 13, UIFontWeightMedium, UIColor.secondaryLabelColor);
    UIStackView *st = [UIStackView new]; st.axis = UILayoutConstraintAxisVertical; st.spacing = 10; st.translatesAutoresizingMaskIntoConstraints = NO;
    [st addArrangedSubview:th]; [st addArrangedSubview:ti]; [st addArrangedSubview:su];
    [th.heightAnchor constraintEqualToAnchor:th.widthAnchor multiplier:9.0 / 16.0].active = YES;
    [st setCustomSpacing:14 afterView:th];
    UILabel *hd = Label(L(@"Choose quality", @"اختار الجودة"), 14, UIFontWeightBold, UIColor.secondaryLabelColor);
    [st addArrangedSubview:hd];
    for (NSInteger i = 0; i < (NSInteger)self.fmts.count; i++) {
        NSDictionary *f = self.fmts[i]; BOOL au = [f[@"kind"] isEqualToString:@"audio"];
        GlassView *c = [GlassView new]; c.translatesAutoresizingMaskIntoConstraints = NO; c.radius = 20; c.tag = i; c.layer.borderWidth = 2;
        UIImageView *ic = [[UIImageView alloc] initWithImage:Sym(au ? @"music.note" : @"play.rectangle.fill", 22, UIFontWeightSemibold)]; ic.translatesAutoresizingMaskIntoConstraints = NO; ic.tintColor = au ? [UIColor systemOrangeColor] : Theme.accent; ic.contentMode = UIViewContentModeCenter;
        UILabel *l1 = Label(f[@"label"], 19, UIFontWeightHeavy, nil);
        UILabel *l2 = Label(f[@"detail"], 12, UIFontWeightMedium, UIColor.secondaryLabelColor);
        UILabel *l3 = Label([self sizeText:f], 14, UIFontWeightBold, nil); l3.textAlignment = NSTextAlignmentRight;
        NSMutableArray *badges = [NSMutableArray array];
        if (!au) { int h = [f[@"height"] intValue]; if (h >= 1080) [badges addObject:@"HD"]; if ([f[@"kind"] isEqualToString:@"video"]) [badges addObject:L(@"+ Audio", @"+ صوت")]; }
        else [badges addObject:L(@"Audio only", @"صوت بس")];
        UIStackView *bs = [UIStackView new]; bs.spacing = 6; bs.translatesAutoresizingMaskIntoConstraints = NO;
        for (NSString *b in badges) { UILabel *bl = Label(b, 10, UIFontWeightBold, UIColor.whiteColor); bl.textAlignment = NSTextAlignmentCenter; bl.backgroundColor = [Theme.accent colorWithAlphaComponent:0.9]; bl.layer.cornerRadius = 8; bl.clipsToBounds = YES; [bl.widthAnchor constraintGreaterThanOrEqualToConstant:42].active = YES; [bl.heightAnchor constraintEqualToConstant:16].active = YES; [bs addArrangedSubview:bl]; }
        for (UIView *v in @[ ic, l1, l2, l3, bs ]) [c.content addSubview:v];
        [NSLayoutConstraint activateConstraints:@[
            [c.heightAnchor constraintEqualToConstant:68],
            [ic.leadingAnchor constraintEqualToAnchor:c.content.leadingAnchor constant:14], [ic.centerYAnchor constraintEqualToAnchor:c.content.centerYAnchor], [ic.widthAnchor constraintEqualToConstant:36],
            [l1.leadingAnchor constraintEqualToAnchor:ic.trailingAnchor constant:8], [l1.topAnchor constraintEqualToAnchor:c.content.topAnchor constant:12],
            [l2.leadingAnchor constraintEqualToAnchor:l1.leadingAnchor], [l2.bottomAnchor constraintEqualToAnchor:c.content.bottomAnchor constant:-12],
            [l3.trailingAnchor constraintEqualToAnchor:c.content.trailingAnchor constant:-16], [l3.topAnchor constraintEqualToAnchor:c.content.topAnchor constant:14],
            [bs.trailingAnchor constraintEqualToAnchor:c.content.trailingAnchor constant:-16], [bs.bottomAnchor constraintEqualToAnchor:c.content.bottomAnchor constant:-12] ]];
        [c addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCard:)]];
        [self.cards addObject:c]; [st addArrangedSubview:c];
    }
    NSString *note = self.info[@"note"];
    if (note.length) { UILabel *n = Label(note, 12, UIFontWeightMedium, UIColor.secondaryLabelColor); n.numberOfLines = 0; [st addArrangedSubview:n]; }
    [sv addSubview:st];
    GlassView *bar = [GlassView new]; bar.translatesAutoresizingMaskIntoConstraints = NO; bar.radius = 30; [self.view addSubview:bar];
    UIButton *go = GlassButton(T(@"Download"), self, @selector(go)); SetBtnContent(go, Sym(@"arrow.down.circle.fill", 20, UIFontWeightBold), T(@"Download"), UIColor.whiteColor, 16, 22);
    [bar.content addSubview:go];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem]; x.translatesAutoresizingMaskIntoConstraints = NO; [x setImage:Sym(@"xmark.circle.fill", 28, UIFontWeightRegular) forState:UIControlStateNormal]; x.tintColor = UIColor.secondaryLabelColor; [x addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:x];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide; (void)top;
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:self.view.topAnchor], [sv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [sv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [sv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [st.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:28], [st.leadingAnchor constraintEqualToAnchor:sv.frameLayoutGuide.leadingAnchor constant:18], [st.trailingAnchor constraintEqualToAnchor:sv.frameLayoutGuide.trailingAnchor constant:-18],
        [st.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-120],
        [x.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10], [x.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14],
        [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18], [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18], [bar.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-8], [bar.heightAnchor constraintEqualToConstant:72],
        [go.leadingAnchor constraintEqualToAnchor:bar.content.leadingAnchor constant:12], [go.trailingAnchor constraintEqualToAnchor:bar.content.trailingAnchor constant:-12], [go.centerYAnchor constraintEqualToAnchor:bar.content.centerYAnchor] ]];
    [self refresh];
}
- (void)refresh {
    for (GlassView *c in self.cards) c.layer.borderColor = (c.tag == self.sel ? Theme.accent : [UIColor colorWithWhite:1 alpha:0.2]).CGColor;
}
- (void)tapCard:(UITapGestureRecognizer *)g { self.sel = g.view.tag; [[UISelectionFeedbackGenerator new] selectionChanged]; [self refresh]; }
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)go {
    NSDictionary *f = self.fmts[self.sel];
    [[Mgr shared] addFormat:f title:self.info[@"title"] thumb:self.info[@"thumb"]];
    UITabBarController *tb = self.tabs;
    [self dismissViewControllerAnimated:YES completion:^{ tb.selectedIndex = 1; }];
}
@end

// Entry point for every pasted link. Supported sites go through the extractor, anything else downloads directly.
static void StartLinkEx(UIViewController *vc, NSString *s, void (^direct)(void), BOOL retried);
static void StartLink(UIViewController *vc, NSString *s, void (^direct)(void)) { StartLinkEx(vc, s, direct, NO); }
static void StartLinkEx(UIViewController *vc, NSString *s, void (^direct)(void), BOOL retried) {
    NSURL *u = [NSURL URLWithString:s];
    if (!IsPlatformHost(u.host)) { [[Mgr shared] add:s]; if (direct) direct(); return; }
    Busy *b = [Busy show:vc text:L(@"Reading the link…", @"بقرا الرابط…")];
    [[Engine shared] extract:s completion:^(NSDictionary *res, NSString *err) {
        [b hide];
        if (!res) {
            if (!err) { [[Mgr shared] add:s]; if (direct) direct(); return; }
            UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Could not read this link", @"معرفتش أقرا الرابط ده") message:[err stringByAppendingString:L(@"\n\nIf this site changed recently, try Settings > Downloads > Update extractors.", @"\n\nلو الموقع اتغير قريب، جرب الإعدادات > التنزيلات > تحديث أدوات الاستخراج.")] preferredStyle:UIAlertControllerStyleAlert];
            if (!retried) [a addAction:[UIAlertAction actionWithTitle:L(@"Try updating extractors", @"جرّب تحدّث أدوات الاستخراج") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
                Busy *ub = [Busy show:vc text:L(@"Updating extractors…", @"بحدّث أدوات الاستخراج…")];
                [[Engine shared] updateWithCompletion:^(NSString *m, BOOL ok) { [ub hide]; StartLinkEx(vc, s, direct, YES); }]; }]];
            [a addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleCancel handler:nil]];
            [vc presentViewController:a animated:YES completion:nil]; return;
        }
        PickerVC *p = [PickerVC new]; p.info = res; p.tabs = vc.tabBarController ?: vc.presentingViewController.tabBarController;
        if (@available(iOS 15.0, *)) {
            p.modalPresentationStyle = UIModalPresentationPageSheet;
            UISheetPresentationController *sh = p.sheetPresentationController; sh.detents = @[ UISheetPresentationControllerDetent.largeDetent ]; sh.prefersGrabberVisible = YES;
        }
        [vc presentViewController:p animated:YES completion:nil];
    }];
}
