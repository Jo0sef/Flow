@interface Theme : NSObject
+ (NSInteger)accentIndex;
+ (UIColor *)accent;
+ (UIColor *)accent2;
+ (NSArray<NSString *> *)accentNames;
+ (void)applyAppearance;
@end

@implementation Theme
+ (NSInteger)accentIndex { return [[NSUserDefaults standardUserDefaults] integerForKey:PrefAccent]; }
+ (NSArray *)palette {
    return @[ @[ @0x0A84FF, @0x5E5CE6 ],  // Ocean
              @[ @0xBF5AF2, @0xFF375F ],  // Violet
              @[ @0x30D158, @0x0A84FF ],  // Mint
              @[ @0xFF9F0A, @0xFF375F ],  // Sunset
              @[ @0xFF2D55, @0xFF6482 ],  // Rose
              @[ @0xFF453A, @0xFF9F0A ],  // Crimson
              @[ @0xFFD60A, @0xFF9F0A ],  // Gold
              @[ @0x00E5FF, @0x00FF9C ],  // Cyber
              @[ @0x8E8E93, @0xC7C7CC ]   // Graphite
    ];
}
+ (NSArray<NSString *> *)accentNames { return @[ @"Ocean", @"Violet", @"Mint", @"Sunset", @"Rose", @"Crimson", @"Gold", @"Cyber", @"Graphite" ]; }
+ (UIColor *)hex:(NSInteger)h { return [UIColor colorWithRed:((h >> 16) & 255) / 255.0 green:((h >> 8) & 255) / 255.0 blue:(h & 255) / 255.0 alpha:1]; }
+ (UIColor *)accent { return [self hex:[[self palette][self.accentIndex % 9][0] integerValue]]; }
+ (UIColor *)accent2 { return [self hex:[[self palette][self.accentIndex % 9][1] integerValue]]; }
+ (void)applyAppearance {
    NSInteger a = [[NSUserDefaults standardUserDefaults] integerForKey:PrefAppearance];
    UIUserInterfaceStyle st = a == 1 ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class]) for (UIWindow *w in ((UIWindowScene *)s).windows) w.overrideUserInterfaceStyle = st;
    }
    for (UIWindow *w in UIApplication.sharedApplication.windows) w.overrideUserInterfaceStyle = st;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifTheme object:nil];
}
@end

#pragma mark - Glass UI

static UIFont *RFont(CGFloat size, UIFontWeight w) {
    UIFont *f = [UIFont systemFontOfSize:size weight:w];
    UIFontDescriptor *d = [f.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return d ? [UIFont fontWithDescriptor:d size:size] : f;
}
static BOOL IsBlackMode(void) { return [[NSUserDefaults standardUserDefaults] integerForKey:PrefAppearance] == 2; }
static BOOL IsLightMode(void) { return [[NSUserDefaults standardUserDefaults] integerForKey:PrefAppearance] == 1; }

// Window-level aurora background: gradient base plus slowly drifting glowing orbs. Glass cards blur this.
@interface AuroraView : UIView
@property(nonatomic, strong) CAGradientLayer *base;
@property(nonatomic, strong) NSArray<CAGradientLayer *> *orbs;
@end
@implementation AuroraView
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.userInteractionEnabled = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        BOOL black = IsBlackMode(), light = IsLightMode();
        self.backgroundColor = black ? UIColor.blackColor : (light ? [UIColor colorWithRed:0.93 green:0.95 blue:1 alpha:1] : [UIColor colorWithRed:0.02 green:0.03 blue:0.09 alpha:1]);
        if (black) return self;
        self.base = [CAGradientLayer layer];
        self.base.colors = light ? @[ (id)[UIColor colorWithRed:0.90 green:0.93 blue:1 alpha:1].CGColor, (id)[UIColor colorWithRed:0.99 green:0.96 blue:1 alpha:1].CGColor ]
                                 : @[ (id)[UIColor colorWithRed:0.04 green:0.06 blue:0.16 alpha:1].CGColor, (id)[UIColor colorWithRed:0.01 green:0.01 blue:0.05 alpha:1].CGColor ];
        [self.layer addSublayer:self.base];
        UIColor *a = Theme.accent, *b = Theme.accent2;
        CGFloat h, s, v, al; [a getHue:&h saturation:&s brightness:&v alpha:&al];
        UIColor *c3 = [UIColor colorWithHue:fmod(h + 0.18, 1.0) saturation:MAX(0.55, s) brightness:1 alpha:1];
        NSArray *cols = @[ a, b, c3, a ];
        NSMutableArray *os = [NSMutableArray array];
        CGFloat al0 = light ? 0.40 : 0.62;
        for (int i = 0; i < 4; i++) {
            CAGradientLayer *o = [CAGradientLayer layer];
            o.type = kCAGradientLayerRadial; o.startPoint = CGPointMake(0.5, 0.5); o.endPoint = CGPointMake(1, 1);
            o.colors = @[ (id)[cols[i] colorWithAlphaComponent:al0].CGColor, (id)[cols[i] colorWithAlphaComponent:0].CGColor ];
            [self.layer addSublayer:o]; [os addObject:o];
        }
        self.orbs = os;
    }
    return self;
}
// Only animate while on screen, and not in Low Power Mode / Reduce Motion.
- (void)didMoveToWindow {
    [super didMoveToWindow];
    BOOL calm = NSProcessInfo.processInfo.isLowPowerModeEnabled || UIAccessibilityIsReduceMotionEnabled();
    BOOL run = self.window != nil && !calm;
    for (CAGradientLayer *o in self.orbs) {
        if (run && o.speed == 0) { CFTimeInterval paused = o.timeOffset; o.speed = 1; o.timeOffset = 0; o.beginTime = 0; o.beginTime = [o convertTime:CACurrentMediaTime() fromLayer:nil] - paused; }
        else if (!run && o.speed != 0) { o.timeOffset = [o convertTime:CACurrentMediaTime() fromLayer:nil]; o.speed = 0; }
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height;
    self.base.frame = self.bounds;
    CGFloat sz = MAX(W, H) * 0.95;
    CGPoint pos[4] = { CGPointMake(W * 0.15, H * 0.12), CGPointMake(W * 0.95, H * 0.42), CGPointMake(W * 0.1, H * 0.78), CGPointMake(W * 0.85, H * 0.95) };
    CGFloat dx[4] = { 70, -60, 80, -70 }, dy[4] = { 60, -80, -50, -60 };
    for (int i = 0; i < (int)self.orbs.count; i++) {
        CAGradientLayer *o = self.orbs[i];
        CGFloat r = sz * (i == 1 ? 0.62 : 0.55);
        o.bounds = CGRectMake(0, 0, r, r); o.position = pos[i];
        if (![o animationForKey:@"drift"]) {
            CABasicAnimation *an = [CABasicAnimation animationWithKeyPath:@"position"];
            an.fromValue = [NSValue valueWithCGPoint:pos[i]]; an.toValue = [NSValue valueWithCGPoint:CGPointMake(pos[i].x + dx[i], pos[i].y + dy[i])];
            an.duration = 14 + i * 4; an.autoreverses = YES; an.repeatCount = HUGE_VALF; an.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [o addAnimation:an forKey:@"drift"];
        }
    }
}
@end

@interface GlassView : UIView
@property(nonatomic, strong) UIVisualEffectView *blur;
@property(nonatomic, strong) CAGradientLayer *sheen;
@property(nonatomic) CGFloat radius;
@end
@implementation GlassView
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.radius = 26;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.clipsToBounds = YES;
        self.layer.borderWidth = 1;
        self.blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
        self.blur.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.blur];
        [NSLayoutConstraint activateConstraints:@[
            [self.blur.leadingAnchor constraintEqualToAnchor:self.leadingAnchor], [self.blur.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.blur.topAnchor constraintEqualToAnchor:self.topAnchor], [self.blur.bottomAnchor constraintEqualToAnchor:self.bottomAnchor] ]];
        self.sheen = [CAGradientLayer layer];
        self.sheen.startPoint = CGPointMake(0, 0); self.sheen.endPoint = CGPointMake(1, 1);
        [self.blur.contentView.layer insertSublayer:self.sheen atIndex:0];
        [self updateBorder];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = MIN(self.radius, self.bounds.size.height / 2);
    self.sheen.frame = self.bounds;
}
- (void)updateBorder {
    BOOL light = IsLightMode();
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:light ? 0.85 : 0.22].CGColor;
    self.sheen.colors = light ? @[ (id)[UIColor colorWithWhite:1 alpha:0.55].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.12].CGColor ]
                              : @[ (id)[UIColor colorWithWhite:1 alpha:0.16].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.02].CGColor ];
}
- (void)traitCollectionDidChange:(UITraitCollection *)t { [super traitCollectionDidChange:t]; [self updateBorder]; }
- (UIView *)content { return self.blur.contentView; }
@end

static UILabel *Label(NSString *t, CGFloat size, UIFontWeight w, UIColor *c) {
    UILabel *l = [UILabel new];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.text = t; l.font = RFont(size, w); l.textColor = c ?: UIColor.labelColor;
    return l;
}

// Button with an accent gradient fill
@interface GradButton : UIButton
@property(nonatomic, strong) CAGradientLayer *grad;
@end
@implementation GradButton
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.grad = [CAGradientLayer layer]; self.grad.startPoint = CGPointMake(0, 0); self.grad.endPoint = CGPointMake(1, 1);
        self.grad.colors = @[ (id)Theme.accent.CGColor, (id)Theme.accent2.CGColor ];
        [self.layer insertSublayer:self.grad atIndex:0];
        self.clipsToBounds = YES; self.layer.cornerCurve = kCACornerCurveContinuous;
    }
    return self;
}
- (void)layoutSubviews { [super layoutSubviews]; self.grad.frame = self.bounds; if (self.layer.cornerRadius > self.bounds.size.height / 2) self.layer.cornerRadius = self.bounds.size.height / 2; }
@end


// Draws icon and/or title with our own subviews so layout never depends on UIButton's internal image/title placement.
static void SetBtnContent(UIButton *b, UIImage *img, NSString *title, UIColor *col, CGFloat font, CGFloat isz) {
    [[b viewWithTag:9001] removeFromSuperview];
    [b setTitle:nil forState:UIControlStateNormal]; [b setImage:nil forState:UIControlStateNormal];
    UIStackView *st = [UIStackView new]; st.tag = 9001; st.axis = UILayoutConstraintAxisHorizontal; st.alignment = UIStackViewAlignmentCenter; st.spacing = 7; st.userInteractionEnabled = NO; st.translatesAutoresizingMaskIntoConstraints = NO;
    if (img) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]]; iv.tintColor = col; iv.contentMode = UIViewContentModeScaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = NO;
        [iv.widthAnchor constraintEqualToConstant:isz].active = YES; [iv.heightAnchor constraintEqualToConstant:isz].active = YES; [st addArrangedSubview:iv];
    }
    if (title.length) { UILabel *l = [UILabel new]; l.text = title; l.font = RFont(font, UIFontWeightBold); l.textColor = col; [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal]; [st addArrangedSubview:l]; }
    [b addSubview:st];
    [NSLayoutConstraint activateConstraints:@[ [st.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [st.centerYAnchor constraintEqualToAnchor:b.centerYAnchor] ]];
}

static UIButton *GlassButton(NSString *title, id target, SEL sel) {
    GradButton *b = [GradButton buttonWithType:UIButtonTypeCustom];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = RFont(16, UIFontWeightBold);
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.layer.cornerRadius = 18;
    [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    [b.heightAnchor constraintEqualToConstant:48].active = YES;
    return b;
}

// Gradient disc with a glowing shadow
@interface GradCircle : UIView
@property(nonatomic, strong) CAGradientLayer *grad;
@end
@implementation GradCircle
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.grad = [CAGradientLayer layer]; self.grad.startPoint = CGPointMake(0, 0); self.grad.endPoint = CGPointMake(1, 1);
        self.grad.colors = @[ (id)Theme.accent.CGColor, (id)Theme.accent2.CGColor ];
        [self.layer addSublayer:self.grad];
        self.layer.shadowColor = Theme.accent.CGColor; self.layer.shadowOpacity = 0.7; self.layer.shadowRadius = 26; self.layer.shadowOffset = CGSizeMake(0, 10);
    }
    return self;
}
- (void)layoutSubviews { [super layoutSubviews]; self.grad.frame = self.bounds; self.grad.cornerRadius = self.bounds.size.height / 2; }
@end

@interface BaseVC : UIViewController
- (void)themeChanged;
@end
@implementation BaseVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = IsLightMode() ? [UIColor colorWithRed:0.93 green:0.95 blue:1 alpha:1] : (IsBlackMode() ? UIColor.blackColor : [UIColor colorWithRed:0.02 green:0.03 blue:0.09 alpha:1]);
    AuroraView *au = [[AuroraView alloc] initWithFrame:self.view.bounds]; au.tag = 7001; [self.view insertSubview:au atIndex:0];
}
- (void)themeChanged { self.view.tintColor = Theme.accent; }
@end

// Empty state: big glass disc with an icon, a title and a hint
static UIView *EmptyState(NSString *symbol, NSString *title, NSString *sub) {
    GlassView *disc = [GlassView new]; disc.translatesAutoresizingMaskIntoConstraints = NO; disc.radius = 55;
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:44 weight:UIFontWeightMedium]]];
    iv.translatesAutoresizingMaskIntoConstraints = NO; iv.tintColor = Theme.accent; iv.contentMode = UIViewContentModeCenter;
    [disc.content addSubview:iv];
    [NSLayoutConstraint activateConstraints:@[ [disc.widthAnchor constraintEqualToConstant:110], [disc.heightAnchor constraintEqualToConstant:110],
        [iv.centerXAnchor constraintEqualToAnchor:disc.content.centerXAnchor], [iv.centerYAnchor constraintEqualToAnchor:disc.content.centerYAnchor] ]];
    UILabel *t = Label(title, 20, UIFontWeightBold, nil), *s = Label(sub, 14, UIFontWeightMedium, UIColor.secondaryLabelColor);
    t.textAlignment = s.textAlignment = NSTextAlignmentCenter; s.numberOfLines = 0;
    UIStackView *st = [[UIStackView alloc] initWithArrangedSubviews:@[ disc, t, s ]];
    st.axis = UILayoutConstraintAxisVertical; st.spacing = 10; st.alignment = UIStackViewAlignmentCenter; st.translatesAutoresizingMaskIntoConstraints = NO;
    [st setCustomSpacing:18 afterView:disc];
    [s.widthAnchor constraintLessThanOrEqualToConstant:260].active = YES;
    return st;
}

// Circular progress ring with an icon in the middle
@interface RingView : UIView
@property(nonatomic, strong) CAShapeLayer *track, *prog;
@property(nonatomic, strong) UIImageView *icon;
@property(nonatomic) CGFloat progress; // <0: no ring, show a tinted rounded tile
@property(nonatomic, strong) UIColor *tile;
@end
@implementation RingView
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.track = [CAShapeLayer layer]; self.prog = [CAShapeLayer layer];
        for (CAShapeLayer *l in @[ self.track, self.prog ]) { l.fillColor = nil; l.lineWidth = 4; l.lineCap = kCALineCapRound; [self.layer addSublayer:l]; }
        self.track.strokeColor = [UIColor colorWithWhite:0.5 alpha:0.25].CGColor;
        self.icon = [UIImageView new]; self.icon.contentMode = UIViewContentModeCenter; self.icon.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.icon];
        [NSLayoutConstraint activateConstraints:@[ [self.icon.centerXAnchor constraintEqualToAnchor:self.centerXAnchor], [self.icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor] ]];
        self.layer.cornerCurve = kCACornerCurveContinuous;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect r = CGRectInset(self.bounds, 3, 3);
    UIBezierPath *p = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r)) radius:r.size.width / 2 startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    self.track.path = p.CGPath; self.prog.path = p.CGPath;
    self.track.frame = self.prog.frame = self.bounds;
}
- (void)setProgress:(CGFloat)v {
    _progress = v;
    BOOL ring = v >= 0;
    self.track.hidden = self.prog.hidden = !ring;
    self.prog.strokeColor = Theme.accent.CGColor;
    [CATransaction begin]; [CATransaction setDisableActions:YES]; self.prog.strokeEnd = MAX(0.02, MIN(1, v)); [CATransaction commit];
    self.layer.cornerRadius = ring ? self.bounds.size.height / 2 : 16;
    self.backgroundColor = ring ? [UIColor colorWithWhite:1 alpha:0.06] : (self.tile ?: [Theme.accent colorWithAlphaComponent:0.2]);
}
@end

