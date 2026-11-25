#pragma mark - Settings (grouped pages)

static NSString *NotifRebuild = @"FlowRebuild";
static NSString *gReopen;

static NSArray<NSArray<NSString *> *> *DevLinks(void) {
    return @[ @[ @"Facebook", @"https://www.facebook.com/share/1BSuPxYGiZ/?mibextid=wwXIfr", @"f.cursive", @"#1877F2" ],
              @[ @"Instagram", @"https://www.instagram.com/jo0seff?dmpr=enE5d2hzdndibGth&utm_source=qr", @"camera.fill", @"#E1306C" ],
              @[ @"WhatsApp", @"copy:jo0seff", @"message.fill", @"#25D366" ],
              @[ @"GitHub", @"https://github.com/Jo0sef", @"chevron.left.forwardslash.chevron.right", @"#8E8E93" ] ];
}
static UIColor *HexColor(NSString *h) { unsigned v = 0; [[NSScanner scannerWithString:[h substringFromIndex:1]] scanHexInt:&v]; return [UIColor colorWithRed:((v >> 16) & 255) / 255.0 green:((v >> 8) & 255) / 255.0 blue:(v & 255) / 255.0 alpha:1]; }
static NSString *AppVersion(void) { return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0"; }
static void RebuildApp(NSString *reopen) { gReopen = reopen; [[NSNotificationCenter defaultCenter] postNotificationName:NotifRebuild object:nil]; }

// Row model: @{ icon, color, title, detail, kind: nav|switch|check|plain|action|danger|view, on, tap(block), toggle(block(BOOL)), view }
@interface PageVC : BaseVC
@property(nonatomic, copy) NSArray *(^build)(PageVC *p);
@property(nonatomic, strong) UIScrollView *sv;
@property(nonatomic, strong) UIStackView *stack;
@property(nonatomic) BOOL large;
- (void)rebuild;
@end

@interface RowButton : UIControl
@property(nonatomic, copy) void (^tap)(void);
@end
@implementation RowButton
- (void)setHighlighted:(BOOL)h { [super setHighlighted:h]; self.backgroundColor = h ? [UIColor colorWithWhite:0.5 alpha:0.18] : UIColor.clearColor; }
@end

@implementation PageVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.largeTitleDisplayMode = self.large ? UINavigationItemLargeTitleDisplayModeAlways : UINavigationItemLargeTitleDisplayModeNever;
    self.sv = [UIScrollView new]; self.sv.translatesAutoresizingMaskIntoConstraints = NO; self.sv.alwaysBounceVertical = YES; self.sv.showsVerticalScrollIndicator = NO; self.sv.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.sv];
    self.stack = [UIStackView new]; self.stack.axis = UILayoutConstraintAxisVertical; self.stack.spacing = 14; self.stack.translatesAutoresizingMaskIntoConstraints = NO; [self.sv addSubview:self.stack];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.sv.topAnchor constraintEqualToAnchor:g.topAnchor], [self.sv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [self.sv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.sv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:self.sv.contentLayoutGuide.topAnchor constant:8], [self.stack.leadingAnchor constraintEqualToAnchor:self.sv.frameLayoutGuide.leadingAnchor constant:16], [self.stack.trailingAnchor constraintEqualToAnchor:self.sv.frameLayoutGuide.trailingAnchor constant:-16],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.sv.contentLayoutGuide.bottomAnchor constant:-130] ]];
    [self rebuild];
}
- (void)themeChanged { [super themeChanged]; [self rebuild]; }
- (UIView *)rowView:(NSDictionary *)r {
    NSString *kind = r[@"kind"];
    if ([kind isEqualToString:@"view"]) return r[@"view"];
    RowButton *b = [RowButton new]; b.translatesAutoresizingMaskIntoConstraints = NO; b.tap = r[@"tap"];
    [b addTarget:self action:@selector(rowTapped:) forControlEvents:UIControlEventTouchUpInside];
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:56].active = YES;
    BOOL danger = [kind isEqualToString:@"danger"];
    UIColor *col = r[@"color"] ?: Theme.accent;
    UIView *tile = nil;
    if (r[@"icon"]) {
        tile = [UIView new]; tile.translatesAutoresizingMaskIntoConstraints = NO; tile.backgroundColor = danger ? [UIColor systemRedColor] : col; tile.layer.cornerRadius = 9; tile.layer.cornerCurve = kCACornerCurveContinuous; tile.userInteractionEnabled = NO;
        UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(r[@"icon"], 15, UIFontWeightSemibold)]; iv.tintColor = UIColor.whiteColor; iv.translatesAutoresizingMaskIntoConstraints = NO; [tile addSubview:iv];
        [NSLayoutConstraint activateConstraints:@[ [iv.centerXAnchor constraintEqualToAnchor:tile.centerXAnchor], [iv.centerYAnchor constraintEqualToAnchor:tile.centerYAnchor], [tile.widthAnchor constraintEqualToConstant:32], [tile.heightAnchor constraintEqualToConstant:32] ]];
        [b addSubview:tile];
    }
    UILabel *t = Label(r[@"title"], 16, UIFontWeightSemibold, danger ? [UIColor systemRedColor] : nil); t.userInteractionEnabled = NO; t.numberOfLines = 0;
    UILabel *d = Label(r[@"detail"] ?: @"", 14, UIFontWeightMedium, UIColor.secondaryLabelColor); d.userInteractionEnabled = NO; d.textAlignment = NSTextAlignmentRight; d.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [d setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [b addSubview:t]; [b addSubview:d];
    UIView *acc = nil;
    if ([kind isEqualToString:@"switch"]) {
        UISwitch *sw = [UISwitch new]; sw.translatesAutoresizingMaskIntoConstraints = NO; sw.on = [r[@"on"] boolValue]; sw.onTintColor = Theme.accent;
        void (^tg)(BOOL) = r[@"toggle"]; [sw addAction:[UIAction actionWithHandler:^(UIAction *a) { if (tg) tg(sw.on); }] forControlEvents:UIControlEventValueChanged];
        acc = sw; b.tap = nil;
    } else if ([kind isEqualToString:@"check"]) {
        UIImageView *c = [[UIImageView alloc] initWithImage:Sym(@"checkmark", 16, UIFontWeightBold)]; c.translatesAutoresizingMaskIntoConstraints = NO; c.tintColor = Theme.accent; c.hidden = ![r[@"on"] boolValue]; c.userInteractionEnabled = NO; acc = c;
    } else if ([kind isEqualToString:@"nav"]) {
        UIImageView *c = [[UIImageView alloc] initWithImage:Sym(IsAr() ? @"chevron.backward" : @"chevron.forward", 13, UIFontWeightBold)]; c.translatesAutoresizingMaskIntoConstraints = NO; c.tintColor = UIColor.tertiaryLabelColor; c.userInteractionEnabled = NO; acc = c;
    }
    if (acc) [b addSubview:acc];
    NSMutableArray *cs = [NSMutableArray array];
    NSLayoutXAxisAnchor *lead = b.leadingAnchor; CGFloat lc = 16;
    if (tile) { [cs addObjectsFromArray:@[ [tile.leadingAnchor constraintEqualToAnchor:b.leadingAnchor constant:14], [tile.centerYAnchor constraintEqualToAnchor:b.centerYAnchor] ]]; lead = tile.trailingAnchor; lc = 12; }
    [cs addObjectsFromArray:@[ [t.leadingAnchor constraintEqualToAnchor:lead constant:lc], [t.topAnchor constraintEqualToAnchor:b.topAnchor constant:14], [t.bottomAnchor constraintEqualToAnchor:b.bottomAnchor constant:-14] ]];
    NSLayoutXAxisAnchor *tr = b.trailingAnchor; CGFloat tc = -16;
    if (acc) { [cs addObjectsFromArray:@[ [acc.trailingAnchor constraintEqualToAnchor:b.trailingAnchor constant:-14], [acc.centerYAnchor constraintEqualToAnchor:b.centerYAnchor] ]]; tr = acc.leadingAnchor; tc = -8; }
    [cs addObjectsFromArray:@[ [d.trailingAnchor constraintEqualToAnchor:tr constant:tc], [d.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [d.leadingAnchor constraintGreaterThanOrEqualToAnchor:t.trailingAnchor constant:8] ]];
    [NSLayoutConstraint activateConstraints:cs];
    return b;
}
- (void)rowTapped:(RowButton *)b { if (b.tap) b.tap(); }
- (void)rebuild {
    for (UIView *v in [self.stack.arrangedSubviews copy]) { [self.stack removeArrangedSubview:v]; [v removeFromSuperview]; }
    for (NSDictionary *sec in self.build(self)) {
        if (sec[@"header"]) { UILabel *h = Label(sec[@"header"], 13, UIFontWeightBold, UIColor.secondaryLabelColor); h.numberOfLines = 0; [self.stack addArrangedSubview:h]; [self.stack setCustomSpacing:6 afterView:h]; }
        if (sec[@"free"]) { [self.stack addArrangedSubview:sec[@"free"]]; continue; }
        GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 22;
        UIStackView *s = [UIStackView new]; s.axis = UILayoutConstraintAxisVertical; s.translatesAutoresizingMaskIntoConstraints = NO; [g.content addSubview:s]; Pin(s, g.content, UIEdgeInsetsZero);
        NSArray *rows = sec[@"rows"];
        for (NSInteger i = 0; i < (NSInteger)rows.count; i++) {
            [s addArrangedSubview:[self rowView:rows[i]]];
            if (i < (NSInteger)rows.count - 1) {
                UIView *sp = [UIView new]; sp.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2]; sp.translatesAutoresizingMaskIntoConstraints = NO;
                UIView *w = [UIView new]; w.translatesAutoresizingMaskIntoConstraints = NO; [w addSubview:sp];
                [NSLayoutConstraint activateConstraints:@[ [sp.leadingAnchor constraintEqualToAnchor:w.leadingAnchor constant:58], [sp.trailingAnchor constraintEqualToAnchor:w.trailingAnchor], [sp.topAnchor constraintEqualToAnchor:w.topAnchor], [sp.bottomAnchor constraintEqualToAnchor:w.bottomAnchor], [w.heightAnchor constraintEqualToConstant:0.5] ]];
                [s addArrangedSubview:w];
            }
        }
        [self.stack addArrangedSubview:g];
        if (sec[@"footer"]) { UILabel *f = Label(sec[@"footer"], 12, UIFontWeightMedium, UIColor.secondaryLabelColor); f.numberOfLines = 0; [self.stack addArrangedSubview:f]; }
    }
}
@end

static NSDictionary *Row(NSString *icon, UIColor *col, NSString *title, NSString *detail, NSString *kind, void (^tap)(void)) {
    NSMutableDictionary *d = [@{ @"title": title, @"kind": kind } mutableCopy];
    if (icon) d[@"icon"] = icon;
    if (col) d[@"color"] = col;
    if (detail) d[@"detail"] = detail;
    if (tap) d[@"tap"] = [tap copy];
    return d;
}
static NSDictionary *CheckRow(NSString *icon, UIColor *col, NSString *title, BOOL on, void (^tap)(void)) {
    NSMutableDictionary *d = [Row(icon, col, title, nil, @"check", tap) mutableCopy]; d[@"on"] = @(on); return d;
}
static NSDictionary *SwitchRow(NSString *icon, UIColor *col, NSString *title, NSString *key, BOOL def, void (^extra)(BOOL)) {
    BOOL on = [UD() objectForKey:key] ? [UD() boolForKey:key] : def;
    void (^tg)(BOOL) = ^(BOOL v) { [UD() setBool:v forKey:key]; if (extra) extra(v); };
    return @{ @"icon": icon, @"color": col, @"title": title, @"kind": @"switch", @"on": @(on), @"toggle": [tg copy] };
}
static NSDictionary *Sec(NSString *header, NSArray *rows) { return header ? @{ @"header": header, @"rows": rows } : @{ @"rows": rows }; }
static NSDictionary *SecF(NSString *header, NSArray *rows, NSString *footer) { NSMutableDictionary *d = [Sec(header, rows) mutableCopy]; if (footer) d[@"footer"] = footer; return d; }
static NSDictionary *TextCard(NSString *text) {
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 22;
    UILabel *l = Label(text, 15, UIFontWeightMedium, nil); l.numberOfLines = 0; [g.content addSubview:l]; Pin(l, g.content, UIEdgeInsetsMake(16, 16, 16, 16));
    return @{ @"free": g };
}
static void Push(UIViewController *from, NSString *title, BOOL large, NSArray *(^build)(PageVC *)) {
    PageVC *p = [PageVC new]; p.title = title; p.large = large; p.build = build; [from.navigationController pushViewController:p animated:YES];
}
static void EditText(UIViewController *vc, NSString *title, NSString *cur, void (^done)(NSString *)) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) { f.text = cur; f.autocapitalizationType = UITextAutocapitalizationTypeNone; f.autocorrectionType = UITextAutocorrectionTypeNo; f.keyboardType = UIKeyboardTypeURL; }];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { done([a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]); }]];
    [vc presentViewController:a animated:YES completion:nil];
}
static UIView *SegmentCard(NSString *title, NSArray *items, NSInteger sel, void (^chg)(NSInteger)) {
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 22;
    UILabel *t = Label(title, 16, UIFontWeightSemibold, nil);
    UISegmentedControl *s = [[UISegmentedControl alloc] initWithItems:items]; s.translatesAutoresizingMaskIntoConstraints = NO; s.selectedSegmentIndex = sel;
    [s addAction:[UIAction actionWithHandler:^(UIAction *a) { chg(s.selectedSegmentIndex); }] forControlEvents:UIControlEventValueChanged];
    [g.content addSubview:t]; [g.content addSubview:s];
    [NSLayoutConstraint activateConstraints:@[ [t.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:16], [t.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:14],
        [s.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:16], [s.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-16], [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:10], [g.content.bottomAnchor constraintEqualToAnchor:s.bottomAnchor constant:16] ]];
    return g;
}
static UIImage *LogoImage(void) { return [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AppIcon60x60@3x" ofType:@"png"]]; }
static UIView *BrandHeader(void) {
    UIView *v = [UIView new]; v.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *lg = [[UIImageView alloc] initWithImage:LogoImage()]; lg.translatesAutoresizingMaskIntoConstraints = NO; lg.layer.cornerRadius = 18; lg.clipsToBounds = YES; lg.layer.cornerCurve = kCACornerCurveContinuous;
    UILabel *n = Label(@"Flow", 26, UIFontWeightHeavy, nil);
    UILabel *p = Label([NSString stringWithFormat:@"v%@", AppVersion()], 12, UIFontWeightBold, UIColor.whiteColor); p.textAlignment = NSTextAlignmentCenter; p.backgroundColor = Theme.accent; p.layer.cornerRadius = 10; p.clipsToBounds = YES;
    UILabel *s = Label(L(@"Free. For personal use.", @"مجاني. للاستخدام الشخصي."), 13, UIFontWeightMedium, UIColor.secondaryLabelColor);
    [v addSubview:lg]; [v addSubview:n]; [v addSubview:p]; [v addSubview:s];
    [NSLayoutConstraint activateConstraints:@[ [lg.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:4], [lg.topAnchor constraintEqualToAnchor:v.topAnchor], [lg.bottomAnchor constraintEqualToAnchor:v.bottomAnchor], [lg.widthAnchor constraintEqualToConstant:72], [lg.heightAnchor constraintEqualToConstant:72],
        [n.leadingAnchor constraintEqualToAnchor:lg.trailingAnchor constant:14], [n.topAnchor constraintEqualToAnchor:v.topAnchor constant:8],
        [p.leadingAnchor constraintEqualToAnchor:n.trailingAnchor constant:8], [p.centerYAnchor constraintEqualToAnchor:n.centerYAnchor], [p.widthAnchor constraintEqualToConstant:46], [p.heightAnchor constraintEqualToConstant:20],
        [s.leadingAnchor constraintEqualToAnchor:n.leadingAnchor], [s.topAnchor constraintEqualToAnchor:n.bottomAnchor constant:4] ]];
    return v;
}
static NSString *TempSizeText(void) { return FmtSize(SizeOf(TempRoot()) + (int64_t)[NSURLCache sharedURLCache].currentDiskUsage); }
static void OpenURLString(NSString *s) { NSURL *u = [NSURL URLWithString:s]; if (u) [UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil]; }

static void OpenSettingsPage(UIViewController *root, NSString *key);

static NSArray *AppearancePage(PageVC *p) {
    NSInteger ap = [UD() integerForKey:PrefAppearance];
    UIView *seg = SegmentCard(L(@"Background", @"الخلفية"), @[ L(@"Aurora", @"أورورا"), T(@"Light"), L(@"Pure black", @"أسود خالص") ], ap, ^(NSInteger i) { [UD() setInteger:i forKey:PrefAppearance]; RebuildApp(@"appearance"); });
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 22;
    UILabel *t = Label(T(@"Color theme"), 16, UIFontWeightSemibold, nil);
    UIStackView *grid = [UIStackView new]; grid.axis = UILayoutConstraintAxisVertical; grid.spacing = 14; grid.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger cur = [UD() integerForKey:PrefAccent];
    for (NSInteger r = 0; r < 3; r++) {
        UIStackView *row = [UIStackView new]; row.distribution = UIStackViewDistributionEqualSpacing;
        for (NSInteger c = 0; c < 3; c++) {
            NSInteger i = r * 3 + c;
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.translatesAutoresizingMaskIntoConstraints = NO; b.tag = i;
            [UD() setInteger:i forKey:PrefAccent]; UIColor *c1 = Theme.accent, *c2 = Theme.accent2; [UD() setInteger:cur forKey:PrefAccent];
            CAGradientLayer *gl = [CAGradientLayer layer]; gl.colors = @[ (id)c1.CGColor, (id)c2.CGColor ]; gl.frame = CGRectMake(0, 0, 64, 64); gl.cornerRadius = 32; gl.startPoint = CGPointMake(0, 0); gl.endPoint = CGPointMake(1, 1); [b.layer addSublayer:gl];
            b.layer.cornerRadius = 32; b.layer.borderColor = UIColor.whiteColor.CGColor; b.layer.borderWidth = (i == cur) ? 3 : 0;
            [b.widthAnchor constraintEqualToConstant:64].active = YES; [b.heightAnchor constraintEqualToConstant:64].active = YES;
            if (i == cur) { UIImageView *ck = [[UIImageView alloc] initWithImage:Sym(@"checkmark", 22, UIFontWeightBold)]; ck.tintColor = UIColor.whiteColor; ck.frame = CGRectMake(0, 0, 64, 64); ck.contentMode = UIViewContentModeCenter; [b addSubview:ck]; }
            [b addAction:[UIAction actionWithHandler:^(UIAction *a) { [UD() setInteger:i forKey:PrefAccent]; RebuildApp(@"appearance"); }] forControlEvents:UIControlEventTouchUpInside];
            [row addArrangedSubview:b];
        }
        [grid addArrangedSubview:row];
    }
    [g.content addSubview:t]; [g.content addSubview:grid];
    [NSLayoutConstraint activateConstraints:@[ [t.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:16], [t.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:14],
        [grid.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:24], [grid.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-24], [grid.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:14], [g.content.bottomAnchor constraintEqualToAnchor:grid.bottomAnchor constant:20] ]];
    return @[ @{ @"free": seg }, @{ @"free": g } ];
}
static NSArray *FolderPage(PageVC *p) {
    __weak PageVC *wp = p;
    NSString *cur = [UD() stringForKey:@"dlfolder"] ?: @"Downloads";
    NSMutableArray *rows = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray arrayWithObject:@"."];
    for (NSString *n in [NSFileManager.defaultManager contentsOfDirectoryAtPath:Docs() error:nil]) { NSString *f = [Docs() stringByAppendingPathComponent:n]; if (![n hasPrefix:@"."] && KindOf(f) == 0) [names addObject:n]; }
    if (![names containsObject:@"Downloads"]) [names insertObject:@"Downloads" atIndex:1];
    for (NSString *n in names) [rows addObject:CheckRow(@"folder.fill", [UIColor systemYellowColor], [n isEqualToString:@"."] ? T(@"Home") : n, [n isEqualToString:cur], ^{ [UD() setObject:n forKey:@"dlfolder"]; [wp rebuild]; })];
    return @[ SecF(nil, rows, L(@"New downloads are saved here. Make more folders from My Files.", @"التنزيلات الجديدة بتتحفظ هنا. اعمل مجلدات أكتر من ملفاتي.")) ];
}
static NSArray *DownloadsPage(PageVC *p) {
    __weak PageVC *wp = p;
    NSInteger cn = [UD() integerForKey:@"conns"]; if (cn < 2) cn = 6;
    NSInteger idx = cn <= 2 ? 0 : (cn <= 4 ? 1 : (cn <= 6 ? 2 : 3));
    UIView *seg = SegmentCard(L(@"Parallel connections", @"عدد الاتصالات المتوازية"), @[ @"2", @"4", @"6", @"8" ], idx, ^(NSInteger i) { NSInteger v[4] = { 2, 4, 6, 8 }; [UD() setInteger:v[i] forKey:@"conns"]; });
    NSString *folder = [UD() stringForKey:@"dlfolder"]; if (!folder.length) folder = @"Downloads"; if ([folder isEqualToString:@"."]) folder = T(@"Home");
    NSString *srcName = [UD() stringForKey:@"engineurl"].length ? L(@"Custom", @"مخصص") : L(@"GitHub (default)", @"GitHub (الافتراضي)");
    return @[ Sec(nil, @[ Row(@"folder.fill", [UIColor systemYellowColor], L(@"Download folder", @"مجلد التنزيل"), folder, @"nav", ^{ Push(wp, L(@"Download folder", @"مجلد التنزيل"), NO, ^NSArray *(PageVC *q) { return FolderPage(q); }); }),
                            SwitchRow(@"wifi", [UIColor systemBlueColor], L(@"Wi-Fi only", @"واي فاي بس"), @"wifionly", NO, nil) ]),
              @{ @"free": seg },
              SecF(L(@"Extractors (YouTube, Facebook, Instagram, TikTok, X)", @"أدوات الاستخراج (يوتيوب، فيسبوك، إنستجرام، تيك توك، X)"), @[
                    Row(@"puzzlepiece.extension.fill", [UIColor systemGreenColor], L(@"Extractors", @"أدوات الاستخراج"), [[Engine shared] statusText], @"plain", nil),
                    Row(@"arrow.triangle.2.circlepath", [UIColor systemBlueColor], L(@"Update now", @"حدّث دلوقتي"), nil, @"action", ^{
                        Busy *b = [Busy show:wp text:L(@"Checking for updates…", @"بشوف التحديثات…")];
                        [[Engine shared] updateWithCompletion:^(NSString *m, BOOL ok) { [b hide]; Alert(wp, ok ? @"Done" : @"Could not complete that.", m); [wp rebuild]; }]; }),
                    SwitchRow(@"clock.arrow.circlepath", [UIColor systemOrangeColor], L(@"Update automatically", @"تحديث تلقائي"), @"autoengine", YES, nil),
                    Row(@"link", [UIColor systemGrayColor], L(@"Update source", @"مصدر التحديث"), srcName, @"nav", ^{ EditText(wp, L(@"Extractor file address", @"عنوان ملف الاستخراج"), [UD() stringForKey:@"engineurl"].length ? [UD() stringForKey:@"engineurl"] : DefaultEngineURL, ^(NSString *s) { [UD() setObject:([s isEqualToString:DefaultEngineURL] ? @"" : s) forKey:@"engineurl"]; [wp rebuild]; }); }) ],
                  L(@"Sites change often. Flow checks for new extractors when it opens and once a day, quietly. A new version is only kept if it passes a self-check, otherwise the old one stays. Only public videos work.", @"المواقع بتتغير كتير. فلو بيدوّر على أدوات استخراج جديدة لما تفتحه ومرة كل يوم، من غير ما يزعجك. النسخة الجديدة بتتحفظ بس لو عدّت فحص ذاتي، وإلا القديمة بتفضل. الفيديوهات العامة بس هي اللي بتشتغل.")) ];
}
static BOOL gLockAuthBusy;
static void Authenticate(NSString *reason, void (^done)(BOOL ok)) {
    LAContext *c = [LAContext new]; NSError *e = nil;
    if (![c canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&e]) { dispatch_async(dispatch_get_main_queue(), ^{ done(YES); }); return; } // no passcode set: nothing to protect with
    [c evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:reason reply:^(BOOL ok, NSError *err) { dispatch_async(dispatch_get_main_queue(), ^{ done(ok); }); }];
}

static NSArray *SettingsPageByKey(NSString *key, PageVC *p) {
    __weak PageVC *wp = p;
    if ([key isEqualToString:@"about"]) {
        return @[ @{ @"free": BrandHeader() },
                  Sec(nil, @[ Row(@"number", [UIColor systemBlueColor], T(@"Version"), AppVersion(), @"plain", nil),
                              Row(@"puzzlepiece.extension.fill", [UIColor systemGreenColor], L(@"Extractor engine", @"محرك الاستخراج"), [NSString stringWithFormat:@"v%d", [Engine shared].version], @"plain", nil),
                              Row(@"chevron.left.forwardslash.chevron.right", [UIColor systemGrayColor], L(@"Source code", @"الكود المصدري"), @"GitHub", @"nav", ^{ OpenURLString(@"https://github.com/Jo0sef"); }) ]),
                  TextCard(L(@"Flow downloads files and public videos with several fast connections at once, keeps them in My Files, and has a few tools (convert, ringtone, background removal). It is free, has no ads, and is made for personal use.", @"فلو بيحمل الملفات والفيديوهات العامة بعدة اتصالات سريعة مع بعض، وبيحفظها في ملفاتي، وفيه أدوات (تحويل، نغمة رنين، وإزالة خلفية). مجاني، من غير إعلانات، ومعمول للاستخدام الشخصي.")) ];
    }
    if ([key isEqualToString:@"faq"]) {
        NSArray *qa = @[ @[ L(@"Which sites work?", @"إيه المواقع المدعومة؟"), L(@"YouTube, Facebook, Instagram, TikTok and X (public videos), plus any direct file link.", @"يوتيوب، فيسبوك، إنستجرام، تيك توك وX (الفيديوهات العامة)، وأي رابط ملف مباشر.") ],
                         @[ L(@"Why is YouTube limited to 1080p?", @"ليه يوتيوب لحد 1080p بس؟"), L(@"Higher qualities use VP9/AV1, which the iPhone cannot play or merge. Flow offers the H.264 qualities.", @"الجودات الأعلى بتستخدم VP9/AV1 واللي الآيفون مبيشغلهاش ولا بيدمجها. فلو بيعرض جودات H.264.") ],
                         @[ L(@"A link stopped working", @"رابط وقف يشتغل"), L(@"Open Settings > Downloads > Update extractors. Sites change often.", @"افتح الإعدادات > التنزيلات > تحديث أدوات الاستخراج. المواقع بتتغير كتير.") ],
                         @[ L(@"Where are my files?", @"فين ملفاتي؟"), L(@"In My Files, and also in the Files app under On My iPhone > Flow.", @"في ملفاتي، وكمان في تطبيق الملفات تحت On My iPhone > Flow.") ],
                         @[ L(@"Can downloads continue in the background?", @"التنزيل بيكمل في الخلفية؟"), L(@"iOS allows only about 30 seconds after you leave the app. Keep Flow open for large files.", @"iOS بيسمح بحوالي 30 ثانية بس بعد ما تخرج. سيب فلو مفتوح للملفات الكبيرة.") ],
                         @[ L(@"How do I use a ringtone?", @"أستخدم النغمة إزاي؟"), L(@"Make it in Tools > Ringtone, share the .m4r file, then add it to your iPhone with 3uTools or iTunes.", @"اعملها من أدوات > نغمة رنين، شارك ملف .m4r وضيفه للموبايل من 3uTools أو iTunes.") ] ];
        NSMutableArray *secs = [NSMutableArray array];
        for (NSArray *x in qa) {
            GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 20;
            UILabel *q = Label(x[0], 16, UIFontWeightBold, nil); q.numberOfLines = 0; UILabel *a = Label(x[1], 14, UIFontWeightMedium, UIColor.secondaryLabelColor); a.numberOfLines = 0;
            UIStackView *s = [[UIStackView alloc] initWithArrangedSubviews:@[ q, a ]]; s.axis = UILayoutConstraintAxisVertical; s.spacing = 6; s.translatesAutoresizingMaskIntoConstraints = NO; [g.content addSubview:s]; Pin(s, g.content, UIEdgeInsetsMake(14, 16, 14, 16));
            [secs addObject:@{ @"free": g }];
        }
        return secs;
    }
    if ([key isEqualToString:@"support"]) {
        GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 22;
        UILabel *dv = Label(T(@"Developer"), 12, UIFontWeightMedium, UIColor.secondaryLabelColor), *dn = Label(@"Youssef elbaheriy", 22, UIFontWeightHeavy, nil);
        UIStackView *s = [[UIStackView alloc] initWithArrangedSubviews:@[ dv, dn ]]; s.axis = UILayoutConstraintAxisVertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = NO; [g.content addSubview:s]; Pin(s, g.content, UIEdgeInsetsMake(16, 16, 16, 16));
        NSMutableArray *rows = [NSMutableArray array];
        for (NSArray *l in DevLinks()) {
            NSString *target = l[1];
            [rows addObject:Row(l[2], HexColor(l[3]), l[0], [target hasPrefix:@"copy:"] ? L(@"Copy username", @"نسخ اليوزر") : nil, @"nav", ^{
                if ([target hasPrefix:@"copy:"]) { NSString *v = [target substringFromIndex:5]; UIPasteboard.generalPasteboard.string = v; Alert(wp, @"Copied", [NSString stringWithFormat:@"%@%@", L(@"WhatsApp username: ", @"يوزر الواتساب: "), v]); }
                else OpenURLString(target); })];
        }
        return @[ @{ @"free": g }, Sec(nil, rows) ];
    }
    if ([key isEqualToString:@"appearance"]) return AppearancePage(p);
    if ([key isEqualToString:@"language"]) {
        BOOL ar = IsAr();
        return @[ Sec(nil, @[ CheckRow(@"textformat", [UIColor systemBlueColor], @"English", !ar, ^{ [UD() setBool:NO forKey:@"arabic"]; RebuildApp(@"language"); }),
                              CheckRow(@"textformat.abc", [UIColor systemGreenColor], @"العربية", ar, ^{ [UD() setBool:YES forKey:@"arabic"]; RebuildApp(@"language"); }) ]) ];
    }
    if ([key isEqualToString:@"home"]) {
        NSInteger cur = [UD() integerForKey:@"hometab"]; NSMutableArray *rows = [NSMutableArray array];
        NSArray *names = @[ T(@"Add"), T(@"Downloads"), T(@"Files") ], *icons = @[ @"plus.circle.fill", @"arrow.down.circle.fill", @"folder.fill" ];
        for (NSInteger i = 0; i < 3; i++) [rows addObject:CheckRow(icons[i], Theme.accent, names[i], i == cur, ^{ [UD() setInteger:i forKey:@"hometab"]; [wp rebuild]; })];
        return @[ SecF(nil, rows, L(@"The screen Flow opens on.", @"الشاشة اللي فلو بيفتح عليها.")) ];
    }
    if ([key isEqualToString:@"browser"]) {
        NSInteger eng = [UD() integerForKey:@"engine"]; NSMutableArray *rows = [NSMutableArray array];
        NSArray *en = @[ @"Google", @"Bing", @"DuckDuckGo" ];
        for (NSInteger i = 0; i < 3; i++) [rows addObject:CheckRow(@"magnifyingglass", [UIColor systemBlueColor], en[i], i == eng, ^{ [UD() setInteger:i forKey:@"engine"]; [wp rebuild]; })];
        NSString *home = [UD() stringForKey:@"browserhome"] ?: @"https://www.google.com";
        return @[ Sec(nil, @[ Row(@"house.fill", [UIColor systemOrangeColor], L(@"Home page", @"الصفحة الرئيسية"), [home stringByReplacingOccurrencesOfString:@"https://" withString:@""], @"nav", ^{ EditText(wp, L(@"Browser home page", @"الصفحة الرئيسية للمتصفح"), home, ^(NSString *s) { if (s.length && ![s hasPrefix:@"http"]) s = [@"https://" stringByAppendingString:s]; [UD() setObject:s forKey:@"browserhome"]; [wp rebuild]; }); }) ]),
                  Sec(L(@"Search engine", @"محرك البحث"), rows) ];
    }
    if ([key isEqualToString:@"downloads"]) return DownloadsPage(p);
    if ([key isEqualToString:@"filesettings"]) {
        NSInteger sort = [UD() integerForKey:@"sortby"]; NSMutableArray *rows = [NSMutableArray array];
        NSArray *n = @[ L(@"Name", @"الاسم"), L(@"Date modified", @"تاريخ التعديل"), L(@"Size", @"الحجم") ], *ic = @[ @"textformat", @"calendar", @"arrow.up.arrow.down" ];
        for (NSInteger i = 0; i < 3; i++) [rows addObject:CheckRow(ic[i], Theme.accent, n[i], i == sort, ^{ [UD() setInteger:i forKey:@"sortby"]; [wp rebuild]; })];
        return @[ Sec(L(@"Sort files by", @"ترتيب الملفات حسب"), rows), Sec(nil, @[ SwitchRow(@"folder.fill", [UIColor systemYellowColor], L(@"Folders first", @"المجلدات الأول"), @"foldersfirst", YES, nil) ]),
                 SecF(nil, @[ Row(@"trash.fill", [UIColor systemRedColor], L(@"Trash", @"سلة المحذوفات"), FmtSize(TrashSize()), @"nav", ^{ [wp.navigationController pushViewController:[TrashVC new] animated:YES]; }), SwitchRow(@"clock.arrow.circlepath", [UIColor systemOrangeColor], L(@"Empty Trash after 30 days", @"فضّي السلة بعد 30 يوم"), @"trashauto", NO, nil) ], L(@"Deleted files go to Trash first. Turn this on to remove items automatically after 30 days.", @"الملفات المحذوفة بتروح السلة الأول. فعّل ده عشان تتمسح لوحدها بعد 30 يوم.")) ];
    }
    if ([key isEqualToString:@"cloud"]) {
        return @[ TextCard(L(@"Flow does not have its own cloud. Your files are in the Files app under On My iPhone > Flow, so you can move them to iCloud Drive, Google Drive or any other storage that appears there.", @"فلو معندوش سحابة خاصة بيه. ملفاتك في تطبيق الملفات تحت On My iPhone > Flow، فتقدر تنقلها لـ iCloud Drive أو Google Drive أو أي تخزين تاني ظاهر هناك.")),
                  Sec(nil, @[ Row(@"folder.badge.gearshape", [UIColor systemBlueColor], L(@"Open in Files app", @"افتح في تطبيق الملفات"), nil, @"nav", ^{ OpenURLString([@"shareddocuments://" stringByAppendingString:Docs()]); }) ]) ];
    }
    if ([key isEqualToString:@"protection"]) {
        return @[ SecF(nil, @[ SwitchRow(@"faceid", [UIColor systemGreenColor], L(@"App lock", @"قفل التطبيق"), @"applock", NO, ^(BOOL v) {
                                   if (v) { gLockAuthBusy = YES; Authenticate(L(@"Turn on app lock", @"شغّل قفل التطبيق"), ^(BOOL ok) { gLockAuthBusy = NO; if (!ok) { [UD() setBool:NO forKey:@"applock"]; [wp rebuild]; } }); } }),
                               SwitchRow(@"lock.rotation", [UIColor systemOrangeColor], L(@"Lock when leaving the app", @"اقفل لما أخرج من التطبيق"), @"lockleave", YES, nil) ],
                      L(@"Uses Face ID, Touch ID or your iPhone passcode.", @"بيستخدم Face ID أو Touch ID أو رمز الموبايل.")) ];
    }
    if ([key isEqualToString:@"player"]) {
        float sp = [UD() floatForKey:@"playspeed"]; if (sp < 0.4) sp = 1; NSInteger si = sp <= 0.5 ? 0 : (sp <= 1 ? 1 : (sp <= 1.5 ? 2 : 3));
        UIView *seg = SegmentCard(L(@"Default speed", @"السرعة الافتراضية"), @[ @"0.5x", @"1x", @"1.5x", @"2x" ], si, ^(NSInteger i) { float v[4] = { 0.5f, 1.0f, 1.5f, 2.0f }; [UD() setFloat:v[i] forKey:@"playspeed"]; });
        return @[ Sec(nil, @[ SwitchRow(@"play.circle.fill", [UIColor systemPinkColor], L(@"Autoplay", @"تشغيل تلقائي"), @"autoplay", YES, nil), SwitchRow(@"repeat", [UIColor systemPurpleColor], L(@"Loop", @"تكرار"), @"loop", NO, nil) ]), @{ @"free": seg } ];
    }
    if ([key isEqualToString:@"legal"]) {
        return @[ TextCard(L(@"Personal use only. Download only content you own or have permission to download. You are responsible for following the terms of the sites you use and the laws where you live. Flow is not affiliated with YouTube, Facebook, Instagram, TikTok, X or any other site, and does not bypass logins, paywalls or DRM.", @"للاستخدام الشخصي فقط. حمّل بس المحتوى اللي تملكه أو مسموح لك تحمله. إنت المسؤول عن الالتزام بشروط المواقع اللي بتستخدمها وقوانين بلدك. فلو مالوش علاقة بيوتيوب أو فيسبوك أو إنستجرام أو تيك توك أو X أو أي موقع تاني، ومبيتخطاش تسجيل الدخول أو الاشتراكات أو الحماية DRM.")) ];
    }
    if ([key isEqualToString:@"storage"]) {
        int64_t all = SizeOf(Docs()), dl = SizeOf(DownloadDir()), cv = SizeOf([Docs() stringByAppendingPathComponent:@"Converted"]), tr = TrashSize(); all -= SizeOf(TrashDir()) > 0 ? SizeOf(TrashDir()) : 0; if (all < 0) all = 0;
        NSDictionary *fs = [NSFileManager.defaultManager attributesOfFileSystemForPath:Docs() error:nil];
        return @[ Sec(nil, @[ Row(@"internaldrive.fill", [UIColor systemBlueColor], L(@"All Flow files", @"كل ملفات فلو"), FmtSize(all), @"plain", nil),
                              Row(@"arrow.down.circle.fill", [UIColor systemGreenColor], L(@"Download folder", @"مجلد التنزيل"), FmtSize(dl), @"plain", nil),
                              Row(@"arrow.triangle.2.circlepath", [UIColor systemPurpleColor], L(@"Converted", @"المحوّلة"), FmtSize(cv), @"plain", nil),
                              Row(@"trash.fill", [UIColor systemRedColor], L(@"Trash", @"سلة المحذوفات"), FmtSize(tr), @"plain", nil),
                              Row(@"iphone", [UIColor systemGrayColor], L(@"Free on iPhone", @"المتاح على الموبايل"), FmtSize([fs[NSFileSystemFreeSize] longLongValue]), @"plain", nil) ]) ];
    }
    return @[];
}

static void OpenSettingsPage(UIViewController *root, NSString *key) {
    NSDictionary *titles = @{ @"about": T(@"About"), @"faq": @"FAQ", @"support": L(@"Support & developer", @"الدعم والمطور"), @"appearance": T(@"Appearance & theme"), @"language": T(@"Language"), @"home": L(@"Home page", @"الصفحة الرئيسية"), @"browser": T(@"Browser"), @"downloads": T(@"Downloads"), @"filesettings": L(@"File settings", @"إعدادات الملفات"), @"cloud": L(@"Cloud storage", @"التخزين السحابي"), @"protection": L(@"Protection", @"الحماية"), @"player": L(@"Player settings", @"إعدادات المشغّل"), @"legal": T(@"Legal"), @"storage": T(@"Storage") };
    Push(root, titles[key], NO, ^NSArray *(PageVC *p) { return SettingsPageByKey(key, p); });
}

static UIViewController *MakeSettingsRoot(void) {
    PageVC *root = [PageVC new]; root.title = @"Settings"; root.large = YES;
    __weak PageVC *wr = root;
    root.build = ^NSArray *(PageVC *p) {
        void (^go)(NSString *) = ^(NSString *k) { OpenSettingsPage(wr, k); };
        return @[ @{ @"free": BrandHeader() },
                  Sec(nil, @[ Row(@"info.circle.fill", [UIColor systemBlueColor], T(@"About"), nil, @"nav", ^{ go(@"about"); }),
                              Row(@"questionmark.circle.fill", [UIColor systemOrangeColor], @"FAQ", nil, @"nav", ^{ go(@"faq"); }),
                              Row(@"person.crop.circle.fill", [UIColor systemTealColor], L(@"Support & developer", @"الدعم والمطور"), nil, @"nav", ^{ go(@"support"); }) ]),
                  Sec(nil, @[ Row(@"paintpalette.fill", [UIColor systemPinkColor], T(@"Appearance & theme"), nil, @"nav", ^{ go(@"appearance"); }),
                              Row(@"globe", [UIColor systemIndigoColor], T(@"Language"), IsAr() ? @"العربية" : @"English", @"nav", ^{ go(@"language"); }),
                              Row(@"house.fill", [UIColor systemOrangeColor], L(@"Home page", @"الصفحة الرئيسية"), nil, @"nav", ^{ go(@"home"); }),
                              Row(@"safari.fill", [UIColor systemBlueColor], T(@"Browser"), nil, @"nav", ^{ go(@"browser"); }) ]),
                  Sec(nil, @[ Row(@"arrow.down.circle.fill", [UIColor systemGreenColor], T(@"Downloads"), nil, @"nav", ^{ go(@"downloads"); }),
                              Row(@"folder.fill", [UIColor systemYellowColor], L(@"File settings", @"إعدادات الملفات"), nil, @"nav", ^{ go(@"filesettings"); }),
                              Row(@"icloud.fill", [UIColor systemCyanColor], L(@"Cloud storage", @"التخزين السحابي"), nil, @"nav", ^{ go(@"cloud"); }),
                              Row(@"lock.fill", [UIColor systemGreenColor], L(@"Protection", @"الحماية"), [UD() boolForKey:@"applock"] ? L(@"On", @"شغال") : L(@"Off", @"مقفول"), @"nav", ^{ go(@"protection"); }),
                              Row(@"play.rectangle.fill", [UIColor systemPurpleColor], L(@"Player settings", @"إعدادات المشغّل"), nil, @"nav", ^{ go(@"player"); }) ]),
                  Sec(nil, @[ Row(@"doc.text.fill", [UIColor systemGrayColor], T(@"Legal"), nil, @"nav", ^{ go(@"legal"); }),
                              Row(@"internaldrive.fill", [UIColor systemBrownColor], T(@"Storage"), nil, @"nav", ^{ go(@"storage"); }) ]),
                  Sec(nil, @[ Row(@"trash.fill", nil, [NSString stringWithFormat:@"%@  (%@)", L(@"Clear temp files", @"مسح الملفات المؤقتة"), TempSizeText()], nil, @"danger", ^{
                                  [[NSFileManager defaultManager] removeItemAtPath:TempRoot() error:nil]; [NSURLCache.sharedURLCache removeAllCachedResponses]; [gThumbs removeAllObjects];
                                  Alert(wr, @"Cleared", nil); [wr rebuild]; }),
                              Row(@"clock.arrow.circlepath", nil, T(@"Clear download history"), nil, @"danger", ^{ [[Mgr shared] clearHistory]; Alert(wr, @"Cleared", nil); }) ]) ];
    };
    return root;
}

#pragma mark - Floating glass tab bar

@interface FlowTabs : UITabBarController
@property(nonatomic, strong) GlassView *bar;
@property(nonatomic, strong) UIView *capsule;
@property(nonatomic, strong) NSArray<UIButton *> *btns;
- (NSInteger)cur;
@end
@implementation FlowTabs
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBar.hidden = YES; self.view.backgroundColor = UIColor.clearColor;
    self.bar = [GlassView new]; self.bar.translatesAutoresizingMaskIntoConstraints = NO; self.bar.radius = 34; [self.view addSubview:self.bar];
    self.capsule = [UIView new]; self.capsule.layer.cornerRadius = 25; self.capsule.layer.cornerCurve = kCACornerCurveContinuous; [self.bar.content addSubview:self.capsule];
    NSArray *icons = @[ @"plus.circle", @"arrow.down.circle", @"folder", @"gearshape" ], *sel = @[ @"plus.circle.fill", @"arrow.down.circle.fill", @"folder.fill", @"gearshape.fill" ];
    NSArray *names = @[ T(@"Add"), T(@"Downloads"), T(@"Files"), T(@"Settings") ];
    NSMutableArray *bs = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.tag = i;
        UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(icons[i], 21, UIFontWeightSemibold)]; iv.tag = 101; iv.translatesAutoresizingMaskIntoConstraints = NO; iv.contentMode = UIViewContentModeCenter; iv.userInteractionEnabled = NO;
        UILabel *l = Label(names[i], 10, UIFontWeightBold, nil); l.tag = 102; l.textAlignment = NSTextAlignmentCenter; l.userInteractionEnabled = NO; l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.7;
        [b addSubview:iv]; [b addSubview:l];
        [NSLayoutConstraint activateConstraints:@[ [iv.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [iv.topAnchor constraintEqualToAnchor:b.topAnchor constant:9], [l.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [l.bottomAnchor constraintEqualToAnchor:b.bottomAnchor constant:-8], [l.leadingAnchor constraintEqualToAnchor:b.leadingAnchor constant:2], [l.trailingAnchor constraintEqualToAnchor:b.trailingAnchor constant:-2] ]];
        objc_setAssociatedObject(b, "sel", sel[i], OBJC_ASSOCIATION_RETAIN); objc_setAssociatedObject(b, "unsel", icons[i], OBJC_ASSOCIATION_RETAIN);
        [b addTarget:self action:@selector(tapTab:) forControlEvents:UIControlEventTouchUpInside];
        [self.bar.content addSubview:b]; [bs addObject:b];
    }
    self.btns = bs;
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18], [self.bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18], [self.bar.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-6], [self.bar.heightAnchor constraintEqualToConstant:68] ]];
    [self refreshTabs:NO];
}
- (NSInteger)cur { NSUInteger s = self.selectedIndex; return s < 4 ? (NSInteger)s : 0; }
- (void)tapTab:(UIButton *)b {
    if (b.tag == [self cur]) { UINavigationController *n = (UINavigationController *)self.selectedViewController; [n popToRootViewControllerAnimated:YES]; }
    self.selectedIndex = b.tag; [[UISelectionFeedbackGenerator new] selectionChanged];
}
- (void)setSelectedIndex:(NSUInteger)i { [super setSelectedIndex:i]; if (self.btns) [self refreshTabs:YES]; }
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.bar];
    CGFloat W = self.bar.bounds.size.width, w = (W - 12) / 4;
    BOOL rtl = self.view.effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft || IsAr();
    for (NSInteger i = 0; i < 4; i++) self.btns[i].frame = CGRectMake(6 + w * (rtl ? 3 - i : i), 4, w, 60);
    [self placeCapsule:NO];
}
- (void)placeCapsule:(BOOL)anim {
    if (!self.btns.count) return;
    CGRect f = CGRectInset(self.btns[[self cur]].frame, 4, 2);
    void (^b)(void) = ^{ self.capsule.frame = f; };
    if (anim) [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:b completion:nil]; else b();
}
- (void)refreshTabs:(BOOL)anim {
    self.capsule.backgroundColor = [Theme.accent colorWithAlphaComponent:0.30];
    for (UIButton *b in self.btns) {
        BOOL on = b.tag == [self cur];
        UIImageView *iv = (UIImageView *)[b viewWithTag:101]; UILabel *l = (UILabel *)[b viewWithTag:102];
        iv.image = Sym(objc_getAssociatedObject(b, on ? "sel" : "unsel"), 21, UIFontWeightSemibold);
        iv.tintColor = on ? Theme.accent : UIColor.secondaryLabelColor; l.textColor = on ? Theme.accent : UIColor.secondaryLabelColor;
    }
    [self placeCapsule:anim];
}
@end

#pragma mark - App

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) AuroraView *aurora;
@property(nonatomic, strong) UIView *cover;
@end
@implementation AppDelegate
- (UINavigationController *)nav:(UIViewController *)vc {
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:vc];
    UINavigationBarAppearance *ap = [UINavigationBarAppearance new]; [ap configureWithTransparentBackground];
    ap.largeTitleTextAttributes = @{ NSFontAttributeName: RFont(34, UIFontWeightHeavy) }; ap.titleTextAttributes = @{ NSFontAttributeName: RFont(17, UIFontWeightBold) };
    UINavigationBarAppearance *sa = [UINavigationBarAppearance new]; [sa configureWithDefaultBackground]; sa.backgroundColor = [UIColor clearColor]; sa.shadowColor = nil;
    sa.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]; sa.largeTitleTextAttributes = ap.largeTitleTextAttributes; sa.titleTextAttributes = ap.titleTextAttributes;
    n.navigationBar.standardAppearance = sa; n.navigationBar.compactAppearance = sa; n.navigationBar.scrollEdgeAppearance = ap; n.navigationBar.prefersLargeTitles = YES;
    n.view.backgroundColor = UIColor.clearColor;
    return n;
}
- (UIViewController *)safeNav:(UIViewController *(^)(void))mk name:(NSString *)nm {
    UIViewController *vc = nil;
    @try { Crumb([@"tab " stringByAppendingString:nm]); vc = mk(); (void)vc.view; } @catch (NSException *e) { RecordIssue([NSString stringWithFormat:@"%@: %@ %@", nm, e.name, e.reason]); vc = nil; }
    if (!vc) { vc = [UIViewController new]; vc.title = nm; vc.view.backgroundColor = UIColor.clearColor;
        UILabel *l = [UILabel new]; l.numberOfLines = 0; l.textAlignment = NSTextAlignmentCenter; l.textColor = UIColor.secondaryLabelColor; l.text = [@"This page could not load.\n" stringByAppendingString:nm]; l.frame = CGRectMake(20, 200, 300, 80); l.autoresizingMask = UIViewAutoresizingFlexibleWidth; [vc.view addSubview:l]; }
    UINavigationController *nv = [self nav:vc];
    NSDictionary *ic = @{ @"Add": @"plus.circle", @"Downloads": @"arrow.down.circle", @"Files": @"folder", @"Settings": @"gearshape" };
    nv.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(nm) image:[UIImage systemImageNamed:ic[nm] ?: @"circle"] tag:0];
    return nv;
}
- (void)buildRootSelecting:(NSInteger)idx reopen:(NSString *)reopen {
    @try { ApplyDirection(); } @catch (NSException *e) { RecordIssue([@"direction " stringByAppendingString:e.reason ?: @""]); }
    NSArray *navs = @[ [self safeNav:^{ return (UIViewController *)[AddVC new]; } name:@"Add"],
                       [self safeNav:^{ return (UIViewController *)[DownloadsVC new]; } name:@"Downloads"],
                       [self safeNav:^{ return (UIViewController *)[FilesVC new]; } name:@"Files"],
                       [self safeNav:^{ return MakeSettingsRoot(); } name:@"Settings"] ];
    if (idx < 0 || idx > 3) idx = 0;
    UITabBarController *tb = nil;
    @try { Crumb(@"tabs"); FlowTabs *ft = [FlowTabs new]; ft.viewControllers = navs; ft.selectedIndex = idx; (void)ft.view; tb = ft; }
    @catch (NSException *e) { RecordIssue([NSString stringWithFormat:@"tabs: %@ %@", e.name, e.reason]); tb = nil; }
    if (!tb) { tb = [UITabBarController new]; tb.viewControllers = navs; tb.selectedIndex = idx; }
    Crumb(@"aurora");
    @try { [self.aurora removeFromSuperview]; self.aurora = nil; } @catch (NSException *e) { RecordIssue([@"aurora " stringByAppendingString:e.reason ?: @""]); self.aurora = nil; }
    self.window.rootViewController = tb;
    if (self.aurora) [self.window insertSubview:self.aurora atIndex:0];
    @try {
        tb.view.tintColor = Theme.accent; self.window.tintColor = Theme.accent;
        self.window.semanticContentAttribute = IsAr() ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
        [Theme applyAppearance];
        if (reopen) { UINavigationController *n = (UINavigationController *)tb.viewControllers[3]; OpenSettingsPage(n.viewControllers.firstObject, reopen); }
    } @catch (NSException *e) { RecordIssue([@"theme " stringByAppendingString:e.reason ?: @""]); }
    if (self.cover) [self.window bringSubviewToFront:self.cover];
    Crumb(@"built");
}
- (void)showCover {
    if (self.cover || ![UD() boolForKey:@"applock"]) return;
    UIView *c = [[UIView alloc] initWithFrame:self.window.bounds]; c.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; c.backgroundColor = IsLightMode() ? UIColor.whiteColor : UIColor.blackColor;
    UIImageView *ic = [[UIImageView alloc] initWithImage:Sym(@"lock.fill", 54, UIFontWeightMedium)]; ic.tintColor = Theme.accent; ic.translatesAutoresizingMaskIntoConstraints = NO; [c addSubview:ic];
    UIButton *b = GlassButton(L(@"Unlock", @"فتح القفل"), self, @selector(unlock)); [c addSubview:b];
    [NSLayoutConstraint activateConstraints:@[ [ic.centerXAnchor constraintEqualToAnchor:c.centerXAnchor], [ic.centerYAnchor constraintEqualToAnchor:c.centerYAnchor constant:-40], [b.centerXAnchor constraintEqualToAnchor:c.centerXAnchor], [b.topAnchor constraintEqualToAnchor:ic.bottomAnchor constant:30], [b.widthAnchor constraintEqualToConstant:180] ]];
    self.cover = c; [self.window addSubview:c];
}
- (void)unlock {
    if (gLockAuthBusy) return; gLockAuthBusy = YES;
    Authenticate(L(@"Unlock Flow", @"افتح فلو"), ^(BOOL ok) { gLockAuthBusy = NO; if (ok) { [self.cover removeFromSuperview]; self.cover = nil; } });
}
- (void)applicationWillResignActive:(UIApplication *)a { if ([UD() boolForKey:@"applock"] && ([UD() objectForKey:@"lockleave"] == nil || [UD() boolForKey:@"lockleave"]) && !gLockAuthBusy) [self showCover]; }
- (void)applicationDidEnterBackground:(UIApplication *)a { Crumb(@"done"); }
- (void)applicationWillTerminate:(UIApplication *)a { Crumb(@"done"); }
- (void)applicationDidBecomeActive:(UIApplication *)a { if (self.cover) [self unlock]; @try { [[Engine shared] autoUpdateIfDue:NO]; } @catch (NSException *e) { } }
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)o {
    InstallCrashCatcher();
    @try { TrashAutoPurge(); } @catch (NSException *e) { }
    NSString *prev = PreviousCrash();
    Crumb(@"launch");
    @try { [UD() registerDefaults:@{ PrefAppearance: @0 }]; } @catch (NSException *e) { }
    @try { Crumb(@"localization"); SetupLocalization(); } @catch (NSException *e) { RecordIssue([@"loc " stringByAppendingString:e.reason ?: @""]); }
    @try { Crumb(@"manager"); [Mgr shared]; } @catch (NSException *e) { RecordIssue([@"mgr " stringByAppendingString:e.reason ?: @""]); }
    Crumb(@"window");
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.blackColor;
    [self buildRootSelecting:[UD() integerForKey:@"hometab"] reopen:nil];
    Crumb(@"visible");
    [self.window makeKeyAndVisible];
    @try { [self showCover]; if (self.cover) [self unlock]; } @catch (NSException *e) { RecordIssue([@"lock " stringByAppendingString:e.reason ?: @""]); }
    [[NSNotificationCenter defaultCenter] addObserverForName:NotifRebuild object:nil queue:nil usingBlock:^(NSNotification *n) {
        dispatch_async(dispatch_get_main_queue(), ^{ NSString *r = gReopen; gReopen = nil; [self buildRootSelecting:3 reopen:r]; });
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Crumb(@"engine");
        @try { [Engine shared]; [[Engine shared] autoUpdateIfDue:YES]; }
        @catch (NSException *e) { RecordIssue([@"engine " stringByAppendingString:e.reason ?: @""]); }
        Crumb(@"engine ok");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ Crumb(@"done"); });
    NSString *issues = IssueText();
    NSString *show = prev.length ? prev : issues;
    if (show.length) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ShowDiagnostics(self.window.rootViewController, show); });
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class)); }
}
