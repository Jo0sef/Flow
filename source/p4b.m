#pragma mark - Browser

@interface BrowserVC : UIViewController <WKNavigationDelegate, UITextFieldDelegate>
@property(nonatomic, strong) WKWebView *web;
@property(nonatomic, strong) UITextField *field;
@property(nonatomic, strong) UIButton *back, *fwd;
@property(nonatomic, strong) UILabel *toast;
@end
@implementation BrowserVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.web = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    self.web.translatesAutoresizingMaskIntoConstraints = NO; self.web.navigationDelegate = self; self.web.allowsBackForwardNavigationGestures = YES;
    self.web.customUserAgent = UA;
    [self.view addSubview:self.web];
    GlassView *top = [GlassView new]; top.translatesAutoresizingMaskIntoConstraints = NO; top.radius = 22; [self.view addSubview:top];
    GlassView *bot = [GlassView new]; bot.translatesAutoresizingMaskIntoConstraints = NO; bot.radius = 28; [self.view addSubview:bot];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem]; x.translatesAutoresizingMaskIntoConstraints = NO;
    [x setImage:Sym(@"xmark", 16, UIFontWeightBold) forState:UIControlStateNormal]; x.tintColor = UIColor.labelColor; [x addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    self.field = [UITextField new]; self.field.translatesAutoresizingMaskIntoConstraints = NO; self.field.delegate = self; self.field.placeholder = T(@"Search or enter a web address");
    self.field.keyboardType = UIKeyboardTypeWebSearch; self.field.autocapitalizationType = UITextAutocapitalizationTypeNone; self.field.autocorrectionType = UITextAutocorrectionTypeNo;
    self.field.returnKeyType = UIReturnKeyGo; self.field.clearButtonMode = UITextFieldViewModeWhileEditing; self.field.font = RFont(15, UIFontWeightMedium);
    UIButton *rl = [UIButton buttonWithType:UIButtonTypeSystem]; rl.translatesAutoresizingMaskIntoConstraints = NO;
    [rl setImage:Sym(@"arrow.clockwise", 16, UIFontWeightBold) forState:UIControlStateNormal]; rl.tintColor = UIColor.labelColor; [rl addTarget:self.web action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    for (UIView *v in @[ x, self.field, rl ]) [top.content addSubview:v];
    self.back = [UIButton buttonWithType:UIButtonTypeSystem]; self.fwd = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *dl = [UIButton buttonWithType:UIButtonTypeCustom];
    NSArray *bs = @[ self.back, dl, self.fwd ];
    [self.back setImage:Sym(@"chevron.backward", 20, UIFontWeightSemibold) forState:UIControlStateNormal]; [self.fwd setImage:Sym(@"chevron.forward", 20, UIFontWeightSemibold) forState:UIControlStateNormal];
    [self.back addTarget:self.web action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside]; [self.fwd addTarget:self.web action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    SetBtnContent(dl, Sym(@"arrow.down", 20, UIFontWeightBold), nil, UIColor.whiteColor, 16, 22);
    GradCircle *gc = [GradCircle new]; gc.translatesAutoresizingMaskIntoConstraints = NO; gc.userInteractionEnabled = NO; gc.layer.shadowRadius = 12;
    [dl addTarget:self action:@selector(downloadCurrent) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *bar = [[UIStackView alloc] initWithArrangedSubviews:bs]; bar.distribution = UIStackViewDistributionEqualCentering; bar.alignment = UIStackViewAlignmentCenter; bar.translatesAutoresizingMaskIntoConstraints = NO;
    for (UIButton *b in @[ self.back, self.fwd ]) { b.tintColor = UIColor.labelColor; [b.widthAnchor constraintEqualToConstant:60].active = YES; }
    [bot.content addSubview:bar]; [bot.content insertSubview:gc belowSubview:bar];
    [dl.widthAnchor constraintEqualToConstant:50].active = YES; [dl.heightAnchor constraintEqualToConstant:50].active = YES;
    [NSLayoutConstraint activateConstraints:@[ [gc.centerXAnchor constraintEqualToAnchor:dl.centerXAnchor], [gc.centerYAnchor constraintEqualToAnchor:dl.centerYAnchor], [gc.widthAnchor constraintEqualToConstant:50], [gc.heightAnchor constraintEqualToConstant:50] ]];
    self.toast = Label(@"Added to Downloads", 14, UIFontWeightBold, UIColor.whiteColor); self.toast.textAlignment = NSTextAlignmentCenter; self.toast.backgroundColor = Theme.accent;
    self.toast.layer.cornerRadius = 17; self.toast.clipsToBounds = YES; self.toast.alpha = 0; [self.view addSubview:self.toast];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [top.topAnchor constraintEqualToAnchor:g.topAnchor constant:6], [top.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12], [top.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12], [top.heightAnchor constraintEqualToConstant:48],
        [x.leadingAnchor constraintEqualToAnchor:top.content.leadingAnchor constant:6], [x.centerYAnchor constraintEqualToAnchor:top.content.centerYAnchor], [x.widthAnchor constraintEqualToConstant:40], [x.heightAnchor constraintEqualToConstant:40],
        [rl.trailingAnchor constraintEqualToAnchor:top.content.trailingAnchor constant:-6], [rl.centerYAnchor constraintEqualToAnchor:top.content.centerYAnchor], [rl.widthAnchor constraintEqualToConstant:40], [rl.heightAnchor constraintEqualToConstant:40],
        [self.field.leadingAnchor constraintEqualToAnchor:x.trailingAnchor constant:4], [self.field.trailingAnchor constraintEqualToAnchor:rl.leadingAnchor constant:-4], [self.field.centerYAnchor constraintEqualToAnchor:top.content.centerYAnchor],
        [self.web.topAnchor constraintEqualToAnchor:top.bottomAnchor constant:6], [self.web.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.web.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [self.web.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [bot.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40], [bot.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40], [bot.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-8], [bot.heightAnchor constraintEqualToConstant:64],
        [bar.leadingAnchor constraintEqualToAnchor:bot.content.leadingAnchor constant:14], [bar.trailingAnchor constraintEqualToAnchor:bot.content.trailingAnchor constant:-14], [bar.centerYAnchor constraintEqualToAnchor:bot.content.centerYAnchor],
        [self.toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [self.toast.bottomAnchor constraintEqualToAnchor:bot.topAnchor constant:-12], [self.toast.heightAnchor constraintEqualToConstant:34], [self.toast.widthAnchor constraintGreaterThanOrEqualToConstant:190] ]];
    [self load:[UD() stringForKey:@"browserhome"] ?: @"https://www.google.com"];
}
- (void)load:(NSString *)s {
    NSURL *u = [NSURL URLWithString:s];
    if (u) [self.web loadRequest:[NSURLRequest requestWithURL:u]];
}
- (BOOL)textFieldShouldReturn:(UITextField *)f {
    [f resignFirstResponder];
    NSString *s = [f.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!s.length) return YES;
    if ([s.lowercaseString hasPrefix:@"http://"] || [s.lowercaseString hasPrefix:@"https://"]) [self load:s];
    else if ([s containsString:@"."] && ![s containsString:@" "]) [self load:[@"https://" stringByAppendingString:s]];
    else [self load:[@[ @"https://www.google.com/search?q=", @"https://www.bing.com/search?q=", @"https://duckduckgo.com/?q=" ][MAX(0, MIN(2, (int)[UD() integerForKey:@"engine"]))] stringByAppendingString:[s stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]];
    return YES;
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)flash {
    self.toast.text = T(@"Added to Downloads");
    [UIView animateWithDuration:0.2 animations:^{ self.toast.alpha = 1; } completion:^(BOOL f) { [UIView animateWithDuration:0.3 delay:1.6 options:0 animations:^{ self.toast.alpha = 0; } completion:nil]; }];
}
- (void)downloadCurrent {
    NSURL *u = self.web.URL; if (!u) return;
    [[UIImpactFeedbackGenerator new] impactOccurred];
    StartLink(self, u.absoluteString, ^{ [self flash]; });
}
- (void)webView:(WKWebView *)w didFinishNavigation:(WKNavigation *)n { self.field.text = w.URL.absoluteString; self.back.enabled = w.canGoBack; self.fwd.enabled = w.canGoForward; }
- (void)webView:(WKWebView *)w didCommitNavigation:(WKNavigation *)n { self.field.text = w.URL.absoluteString; self.back.enabled = w.canGoBack; self.fwd.enabled = w.canGoForward; }
- (void)webView:(WKWebView *)w decidePolicyForNavigationResponse:(WKNavigationResponse *)r decisionHandler:(void (^)(WKNavigationResponsePolicy))h {
    if (!r.canShowMIMEType && r.response.URL) { h(WKNavigationResponsePolicyCancel); [[Mgr shared] add:r.response.URL.absoluteString]; [self flash]; return; }
    h(WKNavigationResponsePolicyAllow);
}
@end

#pragma mark - Add (link) screen

@interface AddVC : BaseVC <UITextFieldDelegate>
@property(nonatomic, strong) UITextField *field;
@property(nonatomic, strong) UILabel *toast;
@end
@implementation AddVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Flow";
    UIScrollView *sv = [UIScrollView new]; sv.translatesAutoresizingMaskIntoConstraints = NO; sv.alwaysBounceVertical = YES; sv.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    sv.contentInset = UIEdgeInsetsMake(0, 0, 110, 0); sv.showsVerticalScrollIndicator = NO; [self.view addSubview:sv];
    UIView *cv = [UIView new]; cv.translatesAutoresizingMaskIntoConstraints = NO; [sv addSubview:cv];
    // big link field
    GlassView *in = [GlassView new]; in.translatesAutoresizingMaskIntoConstraints = NO; in.radius = 24; [cv addSubview:in];
    UIImageView *lk = [[UIImageView alloc] initWithImage:Sym(@"link", 20, UIFontWeightSemibold)]; lk.translatesAutoresizingMaskIntoConstraints = NO; lk.tintColor = UIColor.secondaryLabelColor; lk.contentMode = UIViewContentModeScaleAspectFit; [lk setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal]; [lk setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    self.field = [UITextField new]; self.field.translatesAutoresizingMaskIntoConstraints = NO; self.field.delegate = self; self.field.font = RFont(17, UIFontWeightMedium);
    self.field.placeholder = T(@"Paste a link"); self.field.keyboardType = UIKeyboardTypeURL; self.field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.field.autocorrectionType = UITextAutocorrectionTypeNo; self.field.returnKeyType = UIReturnKeyGo; self.field.clearButtonMode = UITextFieldViewModeWhileEditing;
    GradButton *go = [GradButton buttonWithType:UIButtonTypeCustom]; go.translatesAutoresizingMaskIntoConstraints = NO;
    SetBtnContent(go, Sym(@"arrow.down", 24, UIFontWeightBold), nil, UIColor.whiteColor, 16, 26);
    [go addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeCustom]; pasteBtn.translatesAutoresizingMaskIntoConstraints = NO;
    SetBtnContent(pasteBtn, Sym(@"doc.on.clipboard", 18, UIFontWeightSemibold), nil, Theme.accent, 16, 22);
    [pasteBtn addTarget:self action:@selector(pasteTapped) forControlEvents:UIControlEventTouchUpInside];
    for (UIView *v in @[ lk, self.field, pasteBtn, go ]) [in.content addSubview:v];
    // browser pill
    GradButton *br = [GradButton buttonWithType:UIButtonTypeCustom]; br.translatesAutoresizingMaskIntoConstraints = NO;
    SetBtnContent(br, Sym(@"safari.fill", 18, UIFontWeightSemibold), T(@"Browser"), UIColor.whiteColor, 16, 20);
    br.tintColor = UIColor.whiteColor; [br setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; br.layer.cornerRadius = 25;
    
    [br addTarget:self action:@selector(openBrowser) forControlEvents:UIControlEventTouchUpInside];
    [cv addSubview:br];
    // hero
    GradCircle *hero = [GradCircle new]; hero.translatesAutoresizingMaskIntoConstraints = NO; [cv addSubview:hero];
    UIImageView *hi = [[UIImageView alloc] initWithImage:Sym(@"arrow.down", 44, UIFontWeightHeavy)]; hi.translatesAutoresizingMaskIntoConstraints = NO; hi.tintColor = UIColor.whiteColor; [hero addSubview:hi];
    UILabel *hs = Label(@"Paste a link, get your file.", 16, UIFontWeightSemibold, UIColor.secondaryLabelColor); hs.textAlignment = NSTextAlignmentCenter; [cv addSubview:hs];
    // feature strip
    GlassView *fs = [GlassView new]; fs.translatesAutoresizingMaskIntoConstraints = NO; [cv addSubview:fs];
    UIStackView *cols = [UIStackView new]; cols.axis = UILayoutConstraintAxisHorizontal; cols.distribution = UIStackViewDistributionFillEqually; cols.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *feats = @[ @[ @"bolt.fill", @"Fast" ], @[ @"folder.fill", @"Organized" ], @[ @"sparkles", @"Free" ] ];
    for (NSArray *f in feats) {
        UIImageView *i = [[UIImageView alloc] initWithImage:Sym(f[0], 22, UIFontWeightSemibold)]; i.tintColor = Theme.accent; i.contentMode = UIViewContentModeCenter;
        UILabel *l = Label(f[1], 13, UIFontWeightBold, nil); l.textAlignment = NSTextAlignmentCenter;
        UIStackView *c = [[UIStackView alloc] initWithArrangedSubviews:@[ i, l ]]; c.axis = UILayoutConstraintAxisVertical; c.spacing = 6; c.alignment = UIStackViewAlignmentCenter;
        [cols addArrangedSubview:c];
    }
    [fs.content addSubview:cols];
    GlassView *g1 = [GlassView new]; g1.translatesAutoresizingMaskIntoConstraints = NO; [cv addSubview:g1];
    UIImageView *i1 = [[UIImageView alloc] initWithImage:Sym(@"link.circle.fill", 26, UIFontWeightRegular)]; i1.translatesAutoresizingMaskIntoConstraints = NO; i1.tintColor = Theme.accent;
    UILabel *h1 = Label(@"Direct links", 16, UIFontWeightBold, nil);
    UILabel *b1 = Label(@"Paste a direct link to a file (video, audio, image, PDF, zip...) and Flow downloads it with several fast connections at once. Files go to My Files and show in the Files app.", 14, UIFontWeightMedium, UIColor.secondaryLabelColor); b1.numberOfLines = 0;
    for (UIView *v in @[ i1, h1, b1 ]) [g1.content addSubview:v];
    GlassView *g2 = [GlassView new]; g2.translatesAutoresizingMaskIntoConstraints = NO; [cv addSubview:g2];
    UIImageView *i2 = [[UIImageView alloc] initWithImage:Sym(@"checkmark.seal.fill", 26, UIFontWeightRegular)]; i2.translatesAutoresizingMaskIntoConstraints = NO; i2.tintColor = [UIColor systemOrangeColor];
    UILabel *h2 = Label(L(@"Supported sites", @"المواقع المدعومة"), 16, UIFontWeightBold, nil);
    UILabel *b2 = Label(L(@"Paste a YouTube, Facebook, Instagram, TikTok or X link and pick a quality. Only public videos work. The extractors can be updated from Settings > Downloads when a site changes.", @"الصق رابط يوتيوب أو فيسبوك أو إنستجرام أو تيك توك أو X واختار الجودة. الفيديوهات العامة بس هي اللي بتشتغل. أدوات الاستخراج بتتحدث من الإعدادات > التنزيلات لما الموقع يتغير."), 14, UIFontWeightMedium, UIColor.secondaryLabelColor); b2.numberOfLines = 0;
    for (UIView *v in @[ i2, h2, b2 ]) [g2.content addSubview:v];
    self.toast = Label(@"Added to Downloads", 14, UIFontWeightBold, UIColor.whiteColor); self.toast.textAlignment = NSTextAlignmentCenter; self.toast.backgroundColor = Theme.accent;
    self.toast.layer.cornerRadius = 17; self.toast.clipsToBounds = YES; self.toast.alpha = 0; [self.view addSubview:self.toast];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:g.topAnchor], [sv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [sv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [cv.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor], [cv.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor],
        [cv.leadingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.leadingAnchor], [cv.trailingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.trailingAnchor],
        [cv.widthAnchor constraintEqualToAnchor:sv.frameLayoutGuide.widthAnchor], [cv.bottomAnchor constraintEqualToAnchor:g2.bottomAnchor constant:20],
        [in.topAnchor constraintEqualToAnchor:cv.topAnchor constant:8], [in.leadingAnchor constraintEqualToAnchor:cv.leadingAnchor constant:16], [in.trailingAnchor constraintEqualToAnchor:cv.trailingAnchor constant:-16],
        [in.heightAnchor constraintEqualToConstant:68],
        [lk.leadingAnchor constraintEqualToAnchor:in.content.leadingAnchor constant:18], [lk.centerYAnchor constraintEqualToAnchor:in.content.centerYAnchor], [lk.widthAnchor constraintEqualToConstant:24], [lk.heightAnchor constraintEqualToConstant:24],
        [self.field.leadingAnchor constraintEqualToAnchor:lk.trailingAnchor constant:10], [self.field.trailingAnchor constraintEqualToAnchor:pasteBtn.leadingAnchor constant:-4], [self.field.centerYAnchor constraintEqualToAnchor:in.content.centerYAnchor],
        [pasteBtn.trailingAnchor constraintEqualToAnchor:go.leadingAnchor constant:-4], [pasteBtn.centerYAnchor constraintEqualToAnchor:in.content.centerYAnchor], [pasteBtn.widthAnchor constraintEqualToConstant:44], [pasteBtn.heightAnchor constraintEqualToConstant:44],
        [go.trailingAnchor constraintEqualToAnchor:in.content.trailingAnchor], [go.topAnchor constraintEqualToAnchor:in.content.topAnchor], [go.bottomAnchor constraintEqualToAnchor:in.content.bottomAnchor], [go.widthAnchor constraintEqualToConstant:72],
        [br.topAnchor constraintEqualToAnchor:in.bottomAnchor constant:18], [br.centerXAnchor constraintEqualToAnchor:cv.centerXAnchor], [br.widthAnchor constraintEqualToConstant:170], [br.heightAnchor constraintEqualToConstant:50],
        [hero.topAnchor constraintEqualToAnchor:br.bottomAnchor constant:34], [hero.centerXAnchor constraintEqualToAnchor:cv.centerXAnchor], [hero.widthAnchor constraintEqualToConstant:104], [hero.heightAnchor constraintEqualToConstant:104],
        [hi.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor], [hi.centerYAnchor constraintEqualToAnchor:hero.centerYAnchor],
        [hs.topAnchor constraintEqualToAnchor:hero.bottomAnchor constant:20], [hs.leadingAnchor constraintEqualToAnchor:cv.leadingAnchor constant:24], [hs.trailingAnchor constraintEqualToAnchor:cv.trailingAnchor constant:-24],
        [fs.topAnchor constraintEqualToAnchor:hs.bottomAnchor constant:22], [fs.leadingAnchor constraintEqualToAnchor:in.leadingAnchor], [fs.trailingAnchor constraintEqualToAnchor:in.trailingAnchor], [fs.heightAnchor constraintEqualToConstant:84],
        [cols.leadingAnchor constraintEqualToAnchor:fs.content.leadingAnchor constant:8], [cols.trailingAnchor constraintEqualToAnchor:fs.content.trailingAnchor constant:-8], [cols.centerYAnchor constraintEqualToAnchor:fs.content.centerYAnchor],
        [g1.topAnchor constraintEqualToAnchor:fs.bottomAnchor constant:14], [g1.leadingAnchor constraintEqualToAnchor:in.leadingAnchor], [g1.trailingAnchor constraintEqualToAnchor:in.trailingAnchor],
        [i1.leadingAnchor constraintEqualToAnchor:g1.content.leadingAnchor constant:16], [i1.topAnchor constraintEqualToAnchor:g1.content.topAnchor constant:16],
        [h1.leadingAnchor constraintEqualToAnchor:i1.trailingAnchor constant:10], [h1.centerYAnchor constraintEqualToAnchor:i1.centerYAnchor],
        [b1.leadingAnchor constraintEqualToAnchor:i1.leadingAnchor], [b1.trailingAnchor constraintEqualToAnchor:g1.content.trailingAnchor constant:-16], [b1.topAnchor constraintEqualToAnchor:i1.bottomAnchor constant:10],
        [g1.content.bottomAnchor constraintEqualToAnchor:b1.bottomAnchor constant:16],
        [g2.topAnchor constraintEqualToAnchor:g1.bottomAnchor constant:12], [g2.leadingAnchor constraintEqualToAnchor:in.leadingAnchor], [g2.trailingAnchor constraintEqualToAnchor:in.trailingAnchor],
        [i2.leadingAnchor constraintEqualToAnchor:g2.content.leadingAnchor constant:16], [i2.topAnchor constraintEqualToAnchor:g2.content.topAnchor constant:16],
        [h2.leadingAnchor constraintEqualToAnchor:i2.trailingAnchor constant:10], [h2.centerYAnchor constraintEqualToAnchor:i2.centerYAnchor],
        [b2.leadingAnchor constraintEqualToAnchor:i2.leadingAnchor], [b2.trailingAnchor constraintEqualToAnchor:g2.content.trailingAnchor constant:-16], [b2.topAnchor constraintEqualToAnchor:i2.bottomAnchor constant:10],
        [g2.content.bottomAnchor constraintEqualToAnchor:b2.bottomAnchor constant:16],
        [self.toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [self.toast.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-110],
        [self.toast.heightAnchor constraintEqualToConstant:34], [self.toast.widthAnchor constraintGreaterThanOrEqualToConstant:190] ]];
}
- (BOOL)textFieldShouldReturn:(UITextField *)f { [self start]; return YES; }
- (void)openBrowser {
    BrowserVC *b = [BrowserVC new]; b.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:b animated:YES completion:nil];
}
- (void)pasteTapped {
    NSString *s = UIPasteboard.generalPasteboard.string;
    if (!s.length) { [self flash:@"Clipboard is empty."]; return; }
    self.field.text = [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
- (void)flash:(NSString *)m {
    self.toast.text = T(m);
    [UIView animateWithDuration:0.2 animations:^{ self.toast.alpha = 1; } completion:^(BOOL f) {
        [UIView animateWithDuration:0.3 delay:1.6 options:0 animations:^{ self.toast.alpha = 0; } completion:nil]; }];
}
- (void)start {
    [self.field resignFirstResponder];
    NSString *s = [self.field.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!s.length) { [self pasteTapped]; return; }
    if (![s.lowercaseString hasPrefix:@"http://"] && ![s.lowercaseString hasPrefix:@"https://"] && [s containsString:@"."] && ![s containsString:@" "]) s = [@"https://" stringByAppendingString:s];
    NSURL *u = [NSURL URLWithString:s];
    if (!u.host.length || !([u.scheme isEqualToString:@"http"] || [u.scheme isEqualToString:@"https"])) { Alert(self, @"Not supported yet", @"That does not look like a link."); return; }
    BOOL plat = IsPlatformHost(u.host);
    [[UIImpactFeedbackGenerator new] impactOccurred];
    StartLink(self, s, ^{ self.field.text = @""; [self flash:@"Added to Downloads"]; self.tabBarController.selectedIndex = 1; });
    if (plat) self.field.text = @"";
}
@end

#pragma mark - Downloads screen

@interface DownloadsVC : BaseVC <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UIView *empty;
@property(nonatomic) BOOL selecting;
@property(nonatomic, strong) NSMutableSet<NSValue *> *sel;
@end
@implementation DownloadsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Downloads"; self.sel = [NSMutableSet set];
    self.table = MakeTable(self); [self.view addSubview:self.table];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
    self.empty = EmptyState(@"arrow.down.circle", T(@"No downloads yet"), T(@"Paste a link in the Add tab to start."));
    [self.view addSubview:self.empty];
    [NSLayoutConstraint activateConstraints:@[ [self.empty.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [self.empty.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-30], [self.empty.widthAnchor constraintLessThanOrEqualToConstant:300] ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NotifJobs object:nil];
    [self updateBar]; [self reload];
}
- (void)updateBar {
    if (![Mgr shared].jobs.count) { self.navigationItem.rightBarButtonItem = nil; return; }
    NSString *t = self.selecting ? (self.sel.count ? [NSString stringWithFormat:@"%@ (%lu)", T(@"Delete"), (unsigned long)self.sel.count] : T(@"Done ")) : T(@"Select");
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:t style:UIBarButtonItemStylePlain target:self action:@selector(barTapped)];
    b.tintColor = (self.selecting && self.sel.count) ? [UIColor systemRedColor] : Theme.accent;
    self.navigationItem.rightBarButtonItem = b;
}
- (void)barTapped {
    if (self.selecting && self.sel.count) {
        for (NSValue *v in [self.sel copy]) [[Mgr shared] remove:v.nonretainedObjectValue deleteFile:YES];
        [self.sel removeAllObjects]; self.selecting = NO;
    } else { self.selecting = !self.selecting; [self.sel removeAllObjects]; }
    [self updateBar]; [self.table reloadData];
}
- (void)themeChanged { [super themeChanged]; [self.table reloadData]; }
- (void)reload {
    self.empty.hidden = [Mgr shared].jobs.count > 0;
    [self updateBar];
    NSArray *vis = self.table.indexPathsForVisibleRows;
    if (vis.count && vis.count <= (NSUInteger)[Mgr shared].jobs.count && self.table.numberOfSections && [self.table numberOfRowsInSection:0] == (NSInteger)[Mgr shared].jobs.count) {
        for (NSIndexPath *ip in vis) [self fill:(RowCell *)[self.table cellForRowAtIndexPath:ip] job:[Mgr shared].jobs[ip.row]];
    } else [self.table reloadData];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [Mgr shared].jobs.count; }
- (UIMenu *)menuFor:(Job *)j {
    NSMutableArray *a = [NSMutableArray array];
    if (j.state == 2 && j.path) [a addObject:[UIAction actionWithTitle:T(@"Open") image:[UIImage systemImageNamed:@"eye"] identifier:nil handler:^(UIAction *x) { OpenFile(self, j.path); }]];
    if (j.state == 2) [a addObject:[UIAction actionWithTitle:T(@"Share") image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(UIAction *x) { Share(self, j.path); }]];
    if (j.state == 3 || j.state < 2 || j.state == 5) [a addObject:[UIAction actionWithTitle:L(@"Details", @"التفاصيل") image:[UIImage systemImageNamed:@"info.circle"] identifier:nil handler:^(UIAction *x) { [self showDetails:j]; }]];
    if (j.state >= 3) [a addObject:[UIAction actionWithTitle:T(@"Retry") image:[UIImage systemImageNamed:@"arrow.clockwise"] identifier:nil handler:^(UIAction *x) { [[Mgr shared] retry:j]; }]];
    else if (j.state < 2) [a addObject:[UIAction actionWithTitle:L(@"Restart", @"ابدأ من الأول") image:[UIImage systemImageNamed:@"arrow.clockwise"] identifier:nil handler:^(UIAction *x) { [[Mgr shared] restart:j]; }]];
    UIAction *del = [UIAction actionWithTitle:T(j.state < 2 ? @"Cancel" : @"Delete") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction *x) { [[Mgr shared] remove:j deleteFile:YES]; }];
    del.attributes = UIMenuElementAttributesDestructive; [a addObject:del];
    return [UIMenu menuWithTitle:@"" children:a];
}
- (void)fill:(RowCell *)c job:(Job *)j {
    if (!c) return;
    c.title.text = j.name;
    NSString *st; UIColor *pc = Theme.accent;
    switch (j.state) {
        case 0: st = @"Starting…"; break;
        case 1: st = @"Downloading"; break;
        case 2: st = @"Done"; pc = [UIColor systemGreenColor]; break;
        case 3: st = @"Failed"; pc = [UIColor systemRedColor]; break;
        case 5: st = L(@"Merging…", @"بدمج…"); pc = [UIColor systemOrangeColor]; break;
        default: st = @"Canceled"; pc = [UIColor systemGrayColor]; break;
    }
    [c setPillText:st color:pc];
    NSString *sub;
    if (j.state == 1) {
        NSString *sp = j.speed > 1 ? [NSString stringWithFormat:@"%@/s", FmtSize((int64_t)j.speed)] : @"";
        sub = j.total > 0 ? [NSString stringWithFormat:@"%@ / %@  ·  %@", FmtSize(j.got), FmtSize(j.total), sp] : [NSString stringWithFormat:@"%@  ·  %@", FmtSize(j.got), sp];
        if (j.step.length && j.got == 0) sub = j.step;
    } else if (j.state == 2) sub = FmtSize(j.total);
    else if (j.state == 3) sub = j.err ?: @"";
    else if (j.state == 5) sub = FmtSize(j.total);
    else sub = @"";
    c.sub.text = sub;
    if (j.state == 5) [c setSymbol:@"film" color:[UIColor systemOrangeColor] ring:1];
    else if (j.state < 2) [c setSymbol:@"arrow.down" color:Theme.accent ring:(j.total > 0 ? (CGFloat)j.got / (CGFloat)j.total : 0.02)];
    else if (j.state == 2) [c setSymbol:KindSymbol(KindOf(j.path)) color:KindColor(KindOf(j.path)) ring:-1];
    else [c setSymbol:@"exclamationmark.triangle.fill" color:(j.state == 3 ? [UIColor systemRedColor] : [UIColor systemGrayColor]) ring:-1];
    c.more.menu = [self menuFor:j];
    [c setSelecting:self.selecting selected:[self.sel containsObject:[NSValue valueWithNonretainedObject:j]]];
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"d"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"d"];
    [self fill:c job:[Mgr shared].jobs[ip.row]];
    return c;
}
- (void)showDetails:(Job *)j {
    NSString *full = [[Mgr shared] diagnostics:j];
    NSString *shown = full.length > 1500 ? [[full substringToIndex:1500] stringByAppendingString:@"\n..."] : full;
    UIAlertController *al = [UIAlertController alertControllerWithTitle:(j.state == 3 ? L(@"Download failed", @"التحميل فشل") : L(@"Download details", @"تفاصيل التحميل")) message:[NSString stringWithFormat:@"%@\n\n%@", j.err ?: @"", shown] preferredStyle:UIAlertControllerStyleAlert];
    [al addAction:[UIAlertAction actionWithTitle:L(@"Copy details", @"انسخ التفاصيل") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { UIPasteboard.generalPasteboard.string = full; }]];
    [al addAction:[UIAlertAction actionWithTitle:(j.state < 2 ? L(@"Restart", @"ابدأ من الأول") : T(@"Retry")) style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { if (j.state < 2) [[Mgr shared] restart:j]; else [[Mgr shared] retry:j]; }]];
    [al addAction:[UIAlertAction actionWithTitle:L(@"Close", @"إغلاق") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:al animated:YES completion:nil];
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    Job *j = [Mgr shared].jobs[ip.row];
    if (self.selecting) {
        NSValue *v = [NSValue valueWithNonretainedObject:j];
        if ([self.sel containsObject:v]) [self.sel removeObject:v]; else [self.sel addObject:v];
        [self updateBar]; [t reloadRowsAtIndexPaths:@[ ip ] withRowAnimation:UITableViewRowAnimationNone]; return;
    }
    if (j.state == 2) OpenFile(self, j.path); else if (j.state == 3) [self showDetails:j]; else if (j.state >= 3) [[Mgr shared] retry:j];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    Job *j = [Mgr shared].jobs[ip.row];
    UIContextualAction *d = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:T(j.state < 2 ? @"Cancel" : @"Delete") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) {
        [[Mgr shared] remove:j deleteFile:YES]; h(YES); }];
    return [UISwipeActionsConfiguration configurationWithActions:@[ d ]];
}
@end
