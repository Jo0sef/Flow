// Flow - media downloader with a glass UI (iOS 14+)
// Own code and design. Personal use; download only content you own or have permission to download.
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <WebKit/WebKit.h>
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/Photos.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Network/Network.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>

#pragma mark - Localization (English / Arabic)

static NSString *NotifLang = @"FlowLangChanged";
static BOOL IsAr(void) { return [[NSUserDefaults standardUserDefaults] boolForKey:@"arabic"]; }

static NSDictionary *ArExact(void) {
    static NSDictionary *d;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        d = @{
            @"Add": @"إضافة", @"Downloads": @"التنزيلات", @"Files": @"الملفات", @"Settings": @"الإعدادات",
            @"Paste a link": @"الصق الرابط هنا", @"Paste": @"لصق", @"Download": @"تحميل", @"Clipboard is empty.": @"الحافظة فاضية.",
            @"Direct links": @"الروابط المباشرة", @"Paste a direct link to a file (video, audio, image, PDF, zip...) and Flow downloads it with several fast connections at once. Files go to My Files and show in the Files app.": @"الصق رابط مباشر لأي ملف (فيديو، صوت، صورة، PDF، zip...) وفلو بيحمله بعدة اتصالات سريعة مع بعض. الملفات بتتحفظ في ملفاتي وبتظهر في تطبيق الملفات.",
            @"Coming next": @"جاي في التحديث الجاي", @"YouTube, Facebook, TikTok, X and Instagram links are not supported in this first version. They arrive in the next update, with extractors that update from inside the app.": @"روابط يوتيوب وفيسبوك وتيك توك وX وإنستجرام مش مدعومة في النسخة الأولى دي. هتيجي في التحديث الجاي، بأدوات استخراج بتتحدث من جوا التطبيق.",
            @"Not supported yet": @"مش مدعوم لسه", @"This site needs the extractor update. Direct file links work now.": @"الموقع ده محتاج تحديث أداة الاستخراج. الروابط المباشرة شغالة دلوقتي.",
            @"That does not look like a link.": @"ده مش شكل رابط.", @"Added to Downloads": @"اتضاف للتنزيلات",
            @"Starting…": @"جاري البدء…", @"Downloading": @"جاري التحميل", @"Done": @"اكتمل", @"Failed": @"فشل", @"Canceled": @"اتلغى",
            @"No downloads yet": @"مفيش تنزيلات لسه", @"Paste a link in the Add tab to start.": @"الصق رابط في تبويب إضافة عشان تبدأ.",
            @"Cancel": @"إلغاء", @"Retry": @"إعادة المحاولة", @"Delete": @"حذف", @"Share": @"مشاركة", @"Rename": @"تغيير الاسم", @"Move": @"نقل",
            @"Open": @"فتح", @"OK": @"حسنًا", @"Save": @"حفظ", @"Copied": @"تم النسخ", @"Cleared": @"تم المسح",
            @"My Files": @"ملفاتي", @"All": @"الكل", @"Folders": @"مجلدات", @"Images": @"صور", @"Video": @"فيديو", @"Audio": @"صوت", @"Documents": @"مستندات",
            @"Search": @"بحث", @"New folder": @"مجلد جديد", @"Import files": @"استيراد ملفات", @"Folder name": @"اسم المجلد", @"Name": @"الاسم",
            @"This folder is empty": @"المجلد فاضي", @"Use + to add a folder or import files.": @"استخدم + لإضافة مجلد أو استيراد ملفات.",
            @"Move to": @"نقل إلى", @"Home": @"الرئيسية", @"Delete this item?": @"تحذف العنصر ده؟", @"This cannot be undone.": @"مينفعش التراجع عن ده.",
            @"Could not complete that.": @"معرفتش أكمل العملية.", @"A file with that name already exists.": @"فيه ملف بنفس الاسم.",
            @"Appearance": @"المظهر", @"Automatic": @"تلقائي", @"Light": @"فاتح", @"Black": @"أسود", @"Color theme": @"لون التطبيق", @"Language": @"اللغة",
            @"Developer": @"المطور", @"Clear download history": @"مسح سجل التنزيلات",
            @"Speed": @"السرعة", @"item": @"عنصر", @"items": @"عناصر",
            @"Aurora": @"أورورا", @"Browser": @"المتصفح", @"Select": @"تحديد", @"Done ": @"تم", @"From Photos": @"من الصور", @"New": @"جديد",
            @"About": @"عن التطبيق", @"Legal": @"الاستخدام والقانون", @"Storage": @"المساحة", @"Version": @"الإصدار",
            @"Paste a link, get your file.": @"الصق الرابط واحصل على ملفك.", @"Fast": @"سريع", @"Organized": @"منظم", @"Free": @"مجاني",
            @"Search or enter a web address": @"ابحث أو اكتب عنوان موقع", @"Download this link": @"حمّل الرابط ده", @"Close": @"إغلاق",
            @"Delete selected": @"حذف المحدد", @"Search the web": @"ابحث في الويب", @"Appearance & theme": @"المظهر والألوان", @"Back": @"رجوع",
            @"Personal use only. Download only content you own or have permission to download. You are responsible for following the terms of the sites you use.": @"للاستخدام الشخصي فقط. حمّل بس المحتوى اللي تملكه أو مسموح لك تحمله. إنت المسؤول عن الالتزام بشروط المواقع اللي بتستخدمها.",
            @"Files are saved on your iPhone": @"الملفات بتتحفظ على موبايلك",
            @"Open links in the browser; direct file links start downloading automatically.": @"افتح الروابط في المتصفح، وروابط الملفات المباشرة بتبدأ تتحمل لوحدها.",
            @"Direct file links start downloading.": @"روابط الملفات المباشرة بتبدأ تتحمل.",
            @"Selected": @"محدد", @"Used": @"مستخدم",
            @"M4A (taken from the video)": @"M4A (مأخوذ من الفيديو)", @"AAC audio": @"صوت AAC", @"MP4 (H.264 + AAC)": @"MP4 (فيديو + صوت)", @"MP4 (video + audio)": @"MP4 (فيديو + صوت)",
            @"MP4 (no sound)": @"MP4 (من غير صوت)", @"Original sound (M4A/MP3)": @"الصوت الأصلي (M4A/MP3)", @"Original": @"الأصلي", @"Sound": @"صوت", @"Standard": @"عادي",
            @"MP4 · may include the TikTok watermark": @"MP4 · ممكن فيه علامة تيك توك المائية", @"MP4 · no watermark (if the site offers it)": @"MP4 · من غير علامة مائية (لو الموقع بيوفرها)",
            @"Instagram gives one video quality for public posts.": @"إنستجرام بيدي جودة فيديو واحدة للمنشورات العامة.",
            @"Could not create the file": @"معرفتش أعمل الملف", @"Crimson": @"قرمزي", @"Cyber": @"سايبر", @"Graphite": @"جرافيت", @"Ocean": @"محيط", @"Sunset": @"غروب", @"Violet": @"بنفسجي",
            @"Size unknown": @"الحجم مجهول"
        };
    });
    return d;
}
static NSString *T(NSString *s) {
    if (!IsAr() || !s.length) return s;
    NSString *hit = ArExact()[s];
    if (hit) return hit;
    if ([s hasPrefix:@"YouTube is blocking this connection"]) { NSRange r = [s rangeOfString:@" ["]; return [@"يوتيوب بيمنع الاتصال ده: سيرفر الفيديو مش بيرد من شبكتك. جرّب داتا الموبايل أو VPN." stringByAppendingString:r.location != NSNotFound ? [s substringFromIndex:r.location] : @""]; }
    if ([s hasPrefix:@"Facebook: no public video"]) return @"فيسبوك: مفيش فيديو عام في الرابط ده. الفيديوهات الخاصة أو اللي محتاجة تسجيل دخول مش مدعومة.";
    if ([s hasPrefix:@"Instagram: no public video"]) return @"إنستجرام: مفيش فيديو عام في الرابط ده. الحسابات الخاصة أو اللي محتاجة تسجيل دخول مش مدعومة.";
    if ([s hasPrefix:@"Photo "]) return [@"صورة " stringByAppendingString:[s substringFromIndex:6]];
    if ([s hasPrefix:@"Higher qualities up to "]) { NSScanner *sc = [NSScanner scannerWithString:[s substringFromIndex:23]]; int n = 0; [sc scanInt:&n]; return [NSString stringWithFormat:@"فيه جودات أعلى لحد %dp بس بتستخدم VP9/AV1 واللي الآيفون مش بيشغله. فلو بيعرض لحد 1080p.", n]; }
    if ([s hasPrefix:@"Flow 0."]) return @"Flow 0.1\nبرنامج تحميل بواجهة زجاجية. بيحمل الملفات من الروابط المباشرة بعدة اتصالات سريعة، وبيدير ملفاتك. للاستخدام الشخصي: حمّل بس المحتوى اللي تملكه أو مسموح لك تحمله.";
    return s;
}

static void SwizzleSetter(Class c, SEL orig, SEL repl) { method_exchangeImplementations(class_getInstanceMethod(c, orig), class_getInstanceMethod(c, repl)); }

@interface UILabel (NSLoc) @end
@implementation UILabel (NSLoc) - (void)ns_setText:(NSString *)t { [self ns_setText:T(t)]; } @end
@interface UITextView (NSLoc) @end
@implementation UITextView (NSLoc) - (void)ns_setText:(NSString *)t { [self ns_setText:T(t)]; } @end
@interface UIButton (NSLoc) @end
@implementation UIButton (NSLoc) - (void)ns_setTitle:(NSString *)t forState:(UIControlState)s { [self ns_setTitle:T(t) forState:s]; } @end
@interface UIViewController (NSLoc) @end
@implementation UIViewController (NSLoc) - (void)ns_setTitle:(NSString *)t { [self ns_setTitle:T(t)]; } @end

static void SetupLocalization(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        SwizzleSetter(UILabel.class, @selector(setText:), @selector(ns_setText:));
        SwizzleSetter(UITextView.class, @selector(setText:), @selector(ns_setText:));
        SwizzleSetter(UIButton.class, @selector(setTitle:forState:), @selector(ns_setTitle:forState:));
        SwizzleSetter(UIViewController.class, @selector(setTitle:), @selector(ns_setTitle:));
    });
}
static void ApplyDirection(void) {
    UISemanticContentAttribute a = IsAr() ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
    [UIView appearance].semanticContentAttribute = a;
    [UINavigationBar appearance].semanticContentAttribute = a;
    [UITabBar appearance].semanticContentAttribute = a;
    [UITableView appearance].semanticContentAttribute = a;
    [UISegmentedControl appearance].semanticContentAttribute = a;
    [UISearchBar appearance].semanticContentAttribute = a;
    [UITextField appearance].semanticContentAttribute = a;
}

static NSString *PrefAccent = @"accent";
static NSString *PrefAppearance = @"appearance";
static NSString *NotifTheme = @"FlowThemeChanged";
static NSString *NotifJobs = @"FlowJobsChanged";
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

static NSString *ThumbPath(NSString *p);
static void FetchCover(NSString *url, void (^cb)(NSData *)) {
    NSURL *u = url.length ? [NSURL URLWithString:url] : nil; if (!u) { cb(nil); return; }
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u]; r.timeoutInterval = 10;
    [[NSURLSession.sharedSession dataTaskWithRequest:r completionHandler:^(NSData *d, NSURLResponse *resp, NSError *e) {
        UIImage *i = d.length ? [UIImage imageWithData:d] : nil;
        NSData *j = i ? UIImageJPEGRepresentation(i, 0.85) : nil;
        dispatch_async(dispatch_get_main_queue(), ^{ cb(j); });
    }] resume];
}
static void SaveCoverSidecar(NSString *path, NSData *jpg) { if (jpg.length && path.length) [jpg writeToFile:ThumbPath(path) atomically:YES]; }
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
    if (!j.hidden && j.thumbURL.length && j.path.length && KindOf(j.path) == 3) { NSString *pp = j.path; FetchCover(j.thumbURL, ^(NSData *d) { SaveCoverSidecar(pp, d); if (d) [self notify]; }); }
}
- (void)extractAudioFor:(Job *)j {
    [self closeFile:j]; j.state = 5; j.speed = 0; [self notify];
    FetchCover(j.thumbURL, ^(NSData *cover) {
    NSString *src = j.path; NSString *dst = UniquePath(src.stringByDeletingLastPathComponent, [src.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"m4a"]);
    AVURLAsset *as = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:src] options:nil];
    AVAssetExportSession *ex = [[AVAssetExportSession alloc] initWithAsset:as presetName:AVAssetExportPresetAppleM4A];
    if (!ex) { j.state = 2; j.note = L(@"Could not extract audio, saved as video", @"معرفتش أطلّع الصوت، اتحفظ فيديو"); [self persist]; [self notify]; [self endBackgroundIfIdle]; return; }
    ex.outputURL = [NSURL fileURLWithPath:dst]; ex.outputFileType = AVFileTypeAppleM4A;
    if (cover.length) { AVMutableMetadataItem *mi = [AVMutableMetadataItem new]; mi.identifier = AVMetadataIdentifieriTunesMetadataCoverArt; mi.dataType = (NSString *)kCMMetadataBaseDataType_JPEG; mi.value = cover; ex.metadata = @[ mi ]; }
    [ex exportAsynchronouslyWithCompletionHandler:^{ dispatch_async(dispatch_get_main_queue(), ^{
        if (ex.status == AVAssetExportSessionStatusCompleted) {
            [NSFileManager.defaultManager removeItemAtPath:src error:nil];
            j.path = dst; j.name = dst.lastPathComponent; j.total = j.got = SizeOf(dst); SaveCoverSidecar(dst, cover);
        } else { [NSFileManager.defaultManager removeItemAtPath:dst error:nil]; j.note = L(@"Could not extract audio, saved as video", @"معرفتش أطلّع الصوت، اتحفظ فيديو"); j.total = j.got = SizeOf(src); }
        j.state = 2; j.date = [NSDate date]; [self persist]; [self notify]; [self endBackgroundIfIdle];
    }); }];
    });
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

#pragma mark - UI helpers

static void Pin(UIView *v, UIView *p, UIEdgeInsets i) {
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [v.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:i.left], [v.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-i.right],
        [v.topAnchor constraintEqualToAnchor:p.topAnchor constant:i.top], [v.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-i.bottom] ]];
}
static UIImage *Sym(NSString *name, CGFloat size, UIFontWeight w) {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:size weight:w];
    return [UIImage systemImageNamed:name withConfiguration:c] ?: [UIImage systemImageNamed:@"doc" withConfiguration:c];
}
@interface FlowTable : UITableView
@end
@implementation FlowTable
@end
static void AddPull(UITableView *t, id target) {
    UIRefreshControl *rc = [UIRefreshControl new]; rc.tintColor = UIColor.whiteColor;
    [rc addTarget:target action:NSSelectorFromString(@"pullRefresh") forControlEvents:UIControlEventValueChanged];
    t.refreshControl = rc;
}
// Closes the spinner reliably: waits for the finger to lift (ending while dragging leaves the list stuck), but never longer than ~4 s.
static void EndPull(UITableView *t) {
    __block int tries = 0; __block void (^step)(void);
    step = ^{
        if ((t.isDragging || t.isTracking) && tries++ < 12) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), step); return; }
        [t.refreshControl endRefreshing]; step = nil;
    };
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), step);
}
static UITableView *MakeTable(id owner) {
    UITableView *t = [[FlowTable alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    t.translatesAutoresizingMaskIntoConstraints = NO; t.backgroundColor = UIColor.clearColor; t.separatorStyle = UITableViewCellSeparatorStyleNone;
    t.dataSource = owner; t.delegate = owner; t.contentInset = UIEdgeInsetsMake(0, 0, 110, 0); t.verticalScrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 70, 0);
    t.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic; t.showsVerticalScrollIndicator = NO;
    return t;
}
static UIColor *KindColor(int k) {
    switch (k) { case 0: return Theme.accent; case 1: return [UIColor systemPinkColor]; case 2: return [UIColor systemPurpleColor]; case 3: return [UIColor systemOrangeColor];
        case 4: return [UIColor systemTealColor]; case 5: return [UIColor systemYellowColor]; default: return [UIColor systemGrayColor]; }
}
static void Share(UIViewController *vc, NSString *path) {
    UIActivityViewController *v = [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL fileURLWithPath:path] ] applicationActivities:nil];
    v.popoverPresentationController.sourceView = vc.view;
    v.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height / 2, 1, 1);
    [vc presentViewController:v animated:YES completion:nil];
}

#pragma mark - Row cell (Downloads and Files)

@interface RowCell : UITableViewCell
@property(nonatomic, strong) GlassView *card;
@property(nonatomic, strong) RingView *ring;
@property(nonatomic, strong) UILabel *title, *sub, *pill;
@property(nonatomic, strong) UIStackView *meta;
@property(nonatomic, strong) UIButton *more;
@property(nonatomic, strong) UIImageView *check, *thumb;
@property(nonatomic, copy) NSString *represent;
@end
@implementation RowCell
- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    if ((self = [super initWithStyle:st reuseIdentifier:rid])) {
        self.backgroundColor = UIColor.clearColor; self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.card = [GlassView new]; self.card.translatesAutoresizingMaskIntoConstraints = NO; self.card.radius = 24; [self.contentView addSubview:self.card];
        Pin(self.card, self.contentView, UIEdgeInsetsMake(6, 16, 6, 16));
        self.ring = [RingView new]; self.ring.translatesAutoresizingMaskIntoConstraints = NO;
        self.title = Label(@"", 16, UIFontWeightBold, nil); self.title.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.sub = Label(@"", 13, UIFontWeightMedium, UIColor.secondaryLabelColor);
        self.pill = Label(@"", 11, UIFontWeightBold, UIColor.whiteColor); self.pill.textAlignment = NSTextAlignmentCenter;
        self.pill.layer.cornerRadius = 10; self.pill.clipsToBounds = YES;
        self.meta = [[UIStackView alloc] initWithArrangedSubviews:@[ self.pill, self.sub ]]; self.meta.spacing = 8; self.meta.alignment = UIStackViewAlignmentCenter; self.meta.translatesAutoresizingMaskIntoConstraints = NO;
        self.more = [UIButton buttonWithType:UIButtonTypeCustom]; self.more.translatesAutoresizingMaskIntoConstraints = NO;
        [self.more setImage:Sym(@"ellipsis", 15, UIFontWeightBold) forState:UIControlStateNormal]; self.more.tintColor = UIColor.labelColor;
        self.more.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.22]; self.more.layer.cornerRadius = 18;
        self.more.showsMenuAsPrimaryAction = YES;
        self.thumb = [UIImageView new]; self.thumb.translatesAutoresizingMaskIntoConstraints = NO; self.thumb.contentMode = UIViewContentModeScaleAspectFill; self.thumb.clipsToBounds = YES; self.thumb.layer.cornerRadius = 16; self.thumb.hidden = YES; self.thumb.layer.cornerCurve = kCACornerCurveContinuous;
        self.check = [UIImageView new]; self.check.translatesAutoresizingMaskIntoConstraints = NO; self.check.contentMode = UIViewContentModeCenter; self.check.hidden = YES;
        UIView *c = self.card.content;
        for (UIView *v in @[ self.ring, self.thumb, self.title, self.meta, self.more, self.check ]) [c addSubview:v];
        [NSLayoutConstraint activateConstraints:@[ [self.thumb.leadingAnchor constraintEqualToAnchor:self.ring.leadingAnchor], [self.thumb.trailingAnchor constraintEqualToAnchor:self.ring.trailingAnchor], [self.thumb.topAnchor constraintEqualToAnchor:self.ring.topAnchor], [self.thumb.bottomAnchor constraintEqualToAnchor:self.ring.bottomAnchor] ]];
        [NSLayoutConstraint activateConstraints:@[
            [self.ring.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:14], [self.ring.centerYAnchor constraintEqualToAnchor:c.centerYAnchor],
            [self.ring.widthAnchor constraintEqualToConstant:52], [self.ring.heightAnchor constraintEqualToConstant:52],
            [self.more.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12], [self.more.centerYAnchor constraintEqualToAnchor:c.centerYAnchor],
            [self.more.widthAnchor constraintEqualToConstant:36], [self.more.heightAnchor constraintEqualToConstant:36],
            [self.check.centerXAnchor constraintEqualToAnchor:self.more.centerXAnchor], [self.check.centerYAnchor constraintEqualToAnchor:self.more.centerYAnchor],
            [self.title.leadingAnchor constraintEqualToAnchor:self.ring.trailingAnchor constant:12], [self.title.trailingAnchor constraintEqualToAnchor:self.more.leadingAnchor constant:-10],
            [self.title.topAnchor constraintEqualToAnchor:c.topAnchor constant:16],
            [self.meta.leadingAnchor constraintEqualToAnchor:self.title.leadingAnchor], [self.meta.trailingAnchor constraintLessThanOrEqualToAnchor:self.more.leadingAnchor constant:-8],
            [self.meta.topAnchor constraintEqualToAnchor:self.title.bottomAnchor constant:7],
            [self.pill.heightAnchor constraintEqualToConstant:20], [self.pill.widthAnchor constraintGreaterThanOrEqualToConstant:64],
            [c.bottomAnchor constraintEqualToAnchor:self.meta.bottomAnchor constant:16] ]];
    }
    return self;
}
- (void)setSymbol:(NSString *)n color:(UIColor *)col ring:(CGFloat)p {
    self.ring.icon.image = Sym(n, 22, UIFontWeightSemibold); self.ring.icon.tintColor = col;
    self.ring.tile = [col colorWithAlphaComponent:0.2]; self.ring.progress = p; self.thumb.hidden = YES; self.thumb.image = nil;
}
- (void)prepareForReuse { [super prepareForReuse]; self.thumb.hidden = YES; self.thumb.image = nil; self.represent = nil; }
- (void)setThumbImage:(UIImage *)i { self.thumb.image = i; self.thumb.hidden = i == nil; }
- (void)setPillText:(NSString *)t color:(UIColor *)c { self.pill.hidden = t.length == 0; self.pill.text = T(t); self.pill.backgroundColor = c; }
- (void)setSelecting:(BOOL)sel selected:(BOOL)on {
    self.more.hidden = sel; self.check.hidden = !sel;
    self.check.image = Sym(on ? @"checkmark.circle.fill" : @"circle", 24, UIFontWeightRegular);
    self.check.tintColor = on ? Theme.accent : UIColor.tertiaryLabelColor;
}
@end


static void OpenFile(UIViewController *vc, NSString *path);
#pragma mark - Tools (convert, ringtone, background removal)

@interface Busy : UIView
@property(nonatomic, strong) UILabel *lab;
@end
@implementation Busy
+ (Busy *)show:(UIViewController *)vc text:(NSString *)t {
    UIView *host = vc.view.window ?: vc.view;
    Busy *b = [[Busy alloc] initWithFrame:host.bounds]; b.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    b.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 24; [b addSubview:g];
    UIActivityIndicatorView *sp = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge]; sp.translatesAutoresizingMaskIntoConstraints = NO; [sp startAnimating]; sp.color = UIColor.whiteColor;
    b.lab = Label(t, 15, UIFontWeightSemibold, UIColor.whiteColor); b.lab.textAlignment = NSTextAlignmentCenter; b.lab.numberOfLines = 0;
    [g.content addSubview:sp]; [g.content addSubview:b.lab];
    [NSLayoutConstraint activateConstraints:@[
        [g.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [g.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [g.widthAnchor constraintEqualToConstant:220],
        [sp.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:24], [sp.centerXAnchor constraintEqualToAnchor:g.content.centerXAnchor],
        [b.lab.topAnchor constraintEqualToAnchor:sp.bottomAnchor constant:14], [b.lab.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:16], [b.lab.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-16],
        [g.content.bottomAnchor constraintEqualToAnchor:b.lab.bottomAnchor constant:22] ]];
    [host addSubview:b];
    return b;
}
- (void)hide { [self removeFromSuperview]; }
@end

static NSString *ToolsOutDir(void) {
    NSString *p = [Docs() stringByAppendingPathComponent:@"Converted"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static void ToolDone(UIViewController *vc, NSString *out, NSString *err) {
    if (!out) { Alert(vc, @"Could not complete that.", err ?: @""); return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Done", @"تم") message:[NSString stringWithFormat:L(@"Saved in My Files > Converted:\n%@", @"اتحفظ في ملفاتي > Converted:\n%@"), out.lastPathComponent] preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { Share(vc, out); }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleCancel handler:nil]];
    [vc presentViewController:a animated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil];
}
static void ExportAsset(AVAsset *asset, NSString *preset, AVFileType type, CMTimeRange range, NSString *out, void (^done)(NSString *out, NSString *err)) {
    AVAssetExportSession *ex = [[AVAssetExportSession alloc] initWithAsset:asset presetName:preset];
    if (!ex) { done(nil, L(@"This file cannot be exported with this option", @"الملف ده ميتحولش بالاختيار ده")); return; }
    [NSFileManager.defaultManager removeItemAtPath:out error:nil];
    ex.outputURL = [NSURL fileURLWithPath:out]; ex.outputFileType = type;
    if (CMTIMERANGE_IS_VALID(range) && !CMTIMERANGE_IS_EMPTY(range)) ex.timeRange = range;
    [ex exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ex.status == AVAssetExportSessionStatusCompleted) done(out, nil);
            else { [NSFileManager.defaultManager removeItemAtPath:out error:nil]; done(nil, ex.error.localizedDescription); }
        });
    }];
}
// kind: 0 mp4 720p, 1 mp4 1080p, 2 m4a audio, 3 compress (medium)
static void ToolConvert(UIViewController *vc, NSString *path, int mode) {
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    NSString *base = path.lastPathComponent.stringByDeletingPathExtension;
    NSString *preset, *ext; AVFileType type;
    switch (mode) {
        case 0: preset = AVAssetExportPreset1280x720; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" 720p"]; break;
        case 1: preset = AVAssetExportPreset1920x1080; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" 1080p"]; break;
        case 2: preset = AVAssetExportPresetAppleM4A; ext = @"m4a"; type = AVFileTypeAppleM4A; break;
        default: preset = AVAssetExportPresetMediumQuality; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" small"]; break;
    }
    NSString *out = UniquePath(ToolsOutDir(), [base stringByAppendingPathExtension:ext]);
    Busy *b = [Busy show:vc text:L(@"Converting…", @"بحوّل…")];
    ExportAsset(a, preset, type, kCMTimeRangeInvalid, out, ^(NSString *o, NSString *e) { [b hide]; ToolDone(vc, o, e); });
}
static void ToolRingtone(UIViewController *vc, NSString *path, double start) {
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    double dur = CMTimeGetSeconds(a.duration); double len = MIN(30.0, MAX(1.0, dur - start));
    NSString *out = UniquePath(ToolsOutDir(), [[path.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@" ringtone"] stringByAppendingPathExtension:@"m4r"]);
    NSString *tmp = [TempRoot() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    tmp = [tmp stringByAppendingPathExtension:@"m4a"];
    Busy *b = [Busy show:vc text:L(@"Making ringtone…", @"بعمل نغمة…")];
    ExportAsset(a, AVAssetExportPresetAppleM4A, AVFileTypeAppleM4A, CMTimeRangeMake(CMTimeMakeWithSeconds(start, 600), CMTimeMakeWithSeconds(len, 600)), tmp, ^(NSString *o, NSString *e) {
        [b hide];
        if (!o) { ToolDone(vc, nil, e); return; }
        [NSFileManager.defaultManager moveItemAtPath:o toPath:out error:nil];
        ToolDone(vc, out, nil);
    });
}
static UIImage *Upright(UIImage *img) {
    if (img.imageOrientation == UIImageOrientationUp) return img;
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:img.size];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)]; }];
}
static void ToolRemoveBG(UIViewController *vc, UIImage *src, NSString *name) {
    Busy *b = [Busy show:vc text:L(@"Removing background…", @"بشيل الخلفية…")];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *err = nil; NSString *out = nil;
        @autoreleasepool {
            UIImage *img = Upright(src);
            if (MAX(img.size.width, img.size.height) * img.scale > 3000) {
                CGFloat k = 3000.0 / (MAX(img.size.width, img.size.height) * img.scale);
                UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(img.size.width * k * img.scale, img.size.height * k * img.scale)];
                img = [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [img drawInRect:CGRectMake(0, 0, img.size.width * k * img.scale, img.size.height * k * img.scale)]; }];
            }
            CIImage *ci = [[CIImage alloc] initWithCGImage:img.CGImage];
            VNGeneratePersonSegmentationRequest *req = [VNGeneratePersonSegmentationRequest new];
            req.qualityLevel = VNGeneratePersonSegmentationRequestQualityLevelAccurate; req.outputPixelFormat = kCVPixelFormatType_OneComponent8;
            VNImageRequestHandler *h = [[VNImageRequestHandler alloc] initWithCIImage:ci options:@{}];
            NSError *e = nil;
            if (![h performRequests:@[ req ] error:&e] || !req.results.count) err = e.localizedDescription ?: L(@"No person found in the picture", @"مفيش شخص ظاهر في الصورة");
            else {
                VNPixelBufferObservation *o = req.results.firstObject;
                CIImage *mask = [CIImage imageWithCVPixelBuffer:o.pixelBuffer];
                mask = [mask imageByApplyingTransform:CGAffineTransformMakeScale(ci.extent.size.width / mask.extent.size.width, ci.extent.size.height / mask.extent.size.height)];
                CIFilter *f = [CIFilter filterWithName:@"CIBlendWithMask"];
                [f setValue:ci forKey:kCIInputImageKey]; [f setValue:[CIImage emptyImage] forKey:kCIInputBackgroundImageKey]; [f setValue:mask forKey:kCIInputMaskImageKey];
                CIContext *cx = [CIContext contextWithOptions:nil];
                CGImageRef cg = [cx createCGImage:f.outputImage fromRect:ci.extent];
                if (!cg) err = L(@"Rendering failed", @"الرسم فشل");
                else {
                    NSData *png = UIImagePNGRepresentation([UIImage imageWithCGImage:cg]); CGImageRelease(cg);
                    out = UniquePath(ToolsOutDir(), [[name.stringByDeletingPathExtension stringByAppendingString:@" cutout"] stringByAppendingPathExtension:@"png"]);
                    [png writeToFile:out atomically:YES];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ [b hide]; ToolDone(vc, out, err); });
    });
}
// Ringtone screen: pick the 30 second window
@interface RingtoneVC : UIViewController
@property(nonatomic, copy) NSString *path;
@property(nonatomic) double dur;
@property(nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) UILabel *info;
@property(nonatomic, strong) AVPlayer *player;
@end
@implementation RingtoneVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.path] options:nil]; self.dur = CMTimeGetSeconds(a.duration);
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 28; [self.view addSubview:g];
    UILabel *t = Label(L(@"Ringtone", @"نغمة رنين"), 22, UIFontWeightBold, nil);
    UILabel *n = Label(self.path.lastPathComponent, 14, UIFontWeightMedium, UIColor.secondaryLabelColor); n.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.info = Label(@"", 15, UIFontWeightSemibold, nil);
    self.slider = [UISlider new]; self.slider.translatesAutoresizingMaskIntoConstraints = NO; self.slider.minimumValue = 0; self.slider.maximumValue = MAX(0.0, self.dur - 30.0);
    self.slider.enabled = self.dur > 31; self.slider.tintColor = Theme.accent;
    [self.slider addTarget:self action:@selector(moved) forControlEvents:UIControlEventValueChanged];
    UIButton *pv = GlassButton(L(@"Preview", @"سماع"), self, @selector(preview));
    UIButton *mk = GlassButton(L(@"Create .m4r", @"اعمل .m4r"), self, @selector(make));
    UILabel *h = Label(L(@"The ringtone is the 30 seconds starting at the slider. After creating it, share the .m4r file and add it to your iPhone with 3uTools (Ringtones) or iTunes.", @"النغمة هي 30 ثانية من مكان السلايدر. بعد ما تتعمل، شارك ملف .m4r وضيفه للموبايل من 3uTools (Ringtones) أو iTunes."), 13, UIFontWeightRegular, UIColor.secondaryLabelColor); h.numberOfLines = 0;
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem]; x.translatesAutoresizingMaskIntoConstraints = NO; [x setImage:Sym(@"xmark.circle.fill", 26, UIFontWeightRegular) forState:UIControlStateNormal]; x.tintColor = UIColor.secondaryLabelColor; [x addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    for (UIView *v in @[ t, n, self.info, self.slider, pv, mk, h, x ]) [g.content addSubview:v];
    UILayoutGuide *sg = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [g.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16], [g.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16], [g.topAnchor constraintEqualToAnchor:sg.topAnchor constant:24],
        [t.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:20], [t.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:20],
        [x.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-14], [x.centerYAnchor constraintEqualToAnchor:t.centerYAnchor],
        [n.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [n.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [n.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:6],
        [self.info.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [self.info.topAnchor constraintEqualToAnchor:n.bottomAnchor constant:20],
        [self.slider.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [self.slider.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [self.slider.topAnchor constraintEqualToAnchor:self.info.bottomAnchor constant:10],
        [pv.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [pv.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [pv.topAnchor constraintEqualToAnchor:self.slider.bottomAnchor constant:18],
        [mk.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [mk.trailingAnchor constraintEqualToAnchor:pv.trailingAnchor], [mk.topAnchor constraintEqualToAnchor:pv.bottomAnchor constant:10],
        [h.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [h.trailingAnchor constraintEqualToAnchor:pv.trailingAnchor], [h.topAnchor constraintEqualToAnchor:mk.bottomAnchor constant:14],
        [g.content.bottomAnchor constraintEqualToAnchor:h.bottomAnchor constant:20] ]];
    [self moved];
}
- (void)moved {
    double s = self.slider.value, e = MIN(self.dur, s + 30);
    self.info.text = [NSString stringWithFormat:@"%@ %@  →  %@   (%.0f s)", L(@"From", @"من"), FmtDur(s) ?: @"0:00", FmtDur(e), e - s];
    if (s < 1) self.info.text = [NSString stringWithFormat:@"%@ 0:00  →  %@   (%.0f s)", L(@"From", @"من"), FmtDur(e), e - s];
}
- (void)preview {
    [self.player pause];
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.path]];
    [self.player seekToTime:CMTimeMakeWithSeconds(self.slider.value, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.player play];
    __weak RingtoneVC *w = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [w.player pause]; });
}
- (void)make { [self.player pause]; UIViewController *p = self.presentingViewController ?: self; double s = self.slider.value; NSString *path = self.path; [self dismissViewControllerAnimated:YES completion:^{ ToolRingtone(p, path, s); }]; }
- (void)close { [self.player pause]; [self dismissViewControllerAnimated:YES completion:nil]; }
@end

static void OpenRingtone(UIViewController *vc, NSString *path) {
    RingtoneVC *r = [RingtoneVC new]; r.path = path;
    r.modalPresentationStyle = UIModalPresentationOverFullScreen; r.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIView *dim = [[UIView alloc] init]; (void)dim;
    [vc presentViewController:r animated:YES completion:nil];
}

// Choose a file from My Files
@interface FilePickVC : UITableViewController
@property(nonatomic, copy) NSArray<NSString *> *items;
@property(nonatomic, copy) void (^pick)(NSString *path);
@property(nonatomic, copy) NSArray<NSNumber *> *kinds;
@end
@implementation FilePickVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"Choose a file", @"اختار ملف");
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    NSMutableArray *all = [NSMutableArray array];
    for (NSString *f in [NSFileManager.defaultManager enumeratorAtPath:Docs()]) {
        if ([f hasPrefix:@"."] || [f containsString:@"/."]) continue;
        NSString *p = [Docs() stringByAppendingPathComponent:f];
        if ([self.kinds containsObject:@(KindOf(p))]) [all addObject:p];
    }
    self.items = all;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:T(@"Close") style:UIBarButtonItemStylePlain target:self action:@selector(close)];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return MAX(1, self.items.count); }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    if (!self.items.count) { c.textLabel.text = L(@"No matching files in My Files", @"مفيش ملفات مناسبة في ملفاتي"); c.textLabel.textColor = UIColor.secondaryLabelColor; return c; }
    NSString *p = self.items[ip.row];
    c.textLabel.text = p.lastPathComponent; c.detailTextLabel.text = FmtSize(SizeOf(p)); c.imageView.image = Sym(KindSymbol(KindOf(p)), 20, UIFontWeightRegular); c.imageView.tintColor = KindColor(KindOf(p));
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if (!self.items.count) return;
    NSString *p = self.items[ip.row]; void (^cb)(NSString *) = self.pick;
    [self dismissViewControllerAnimated:YES completion:^{ if (cb) cb(p); }];
}
@end
static void PickFile(UIViewController *vc, NSArray<NSNumber *> *kinds, void (^pick)(NSString *)) {
    FilePickVC *f = [[FilePickVC alloc] initWithStyle:UITableViewStyleInsetGrouped]; f.kinds = kinds; f.pick = pick;
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:f];
    [vc presentViewController:n animated:YES completion:nil];
}

// Photo picker helper (used by: remove background, change thumbnail, import)
@interface PhotoHelper : NSObject <PHPickerViewControllerDelegate>
@property(nonatomic, copy) void (^onImage)(UIImage *img, NSString *name);
@property(nonatomic, copy) void (^onFiles)(NSArray<NSURL *> *urls);
@end
@implementation PhotoHelper
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    for (PHPickerResult *r in results) {
        NSItemProvider *p = r.itemProvider;
        if (self.onImage && [p canLoadObjectOfClass:UIImage.class]) {
            [p loadObjectOfClass:UIImage.class completionHandler:^(id obj, NSError *e) { if ([obj isKindOfClass:UIImage.class]) dispatch_async(dispatch_get_main_queue(), ^{ self.onImage(obj, p.suggestedName ?: @"photo"); }); }];
        } else if (self.onFiles) {
            NSString *type = p.registeredTypeIdentifiers.firstObject; if (!type) continue;
            [p loadFileRepresentationForTypeIdentifier:type completionHandler:^(NSURL *u, NSError *e) {
                if (!u) return;
                NSString *tmp = [TempRoot() stringByAppendingPathComponent:u.lastPathComponent];
                [NSFileManager.defaultManager removeItemAtPath:tmp error:nil]; [NSFileManager.defaultManager copyItemAtPath:u.path toPath:tmp error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{ self.onFiles(@[ [NSURL fileURLWithPath:tmp] ]); });
            }];
        }
    }
}
@end
static PhotoHelper *gPhoto;
static void PickPhoto(UIViewController *vc, BOOL files, void (^onImage)(UIImage *, NSString *), void (^onFiles)(NSArray<NSURL *> *)) {
    PHPickerConfiguration *c = [[PHPickerConfiguration alloc] init];
    c.selectionLimit = files ? 0 : 1; c.filter = files ? nil : [PHPickerFilter imagesFilter];
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:c];
    gPhoto = [PhotoHelper new]; gPhoto.onImage = onImage; gPhoto.onFiles = onFiles; p.delegate = gPhoto;
    [vc presentViewController:p animated:YES completion:nil];
}

// Tools menu
static void ConvertMenu(UIViewController *vc, NSString *path) {
    int k = KindOf(path);
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Convert", @"تحويل") message:path.lastPathComponent preferredStyle:UIAlertControllerStyleActionSheet];
    if (k == 2) {
        [a addAction:[UIAlertAction actionWithTitle:L(@"MP4 video 720p", @"فيديو MP4 بجودة 720p") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 0); }]];
        [a addAction:[UIAlertAction actionWithTitle:L(@"MP4 video 1080p", @"فيديو MP4 بجودة 1080p") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 1); }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:L(@"Audio only (M4A)", @"صوت بس (M4A)") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 2); }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = vc.view; a.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height - 40, 1, 1);
    [vc presentViewController:a animated:YES completion:nil];
}
static void RemoveBGPath(UIViewController *vc, NSString *path) {
    UIImage *i = [UIImage imageWithContentsOfFile:path];
    if (!i) { Alert(vc, @"Could not complete that.", nil); return; }
    ToolRemoveBG(vc, i, path.lastPathComponent);
}

@interface ToolsVC : BaseVC <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@end
@implementation ToolsVC
- (NSArray *)rows {
    return @[ @[ @"arrow.triangle.2.circlepath", L(@"Convert", @"تحويل"), L(@"Video to MP4 or audio (M4A)", @"فيديو لـ MP4 أو صوت (M4A)"), @0 ],
              @[ @"bell.fill", L(@"Ringtone", @"نغمة رنين"), L(@"Cut 30 seconds and make a .m4r file", @"قص 30 ثانية واعمل ملف .m4r"), @1 ],
              @[ @"person.crop.circle.badge.minus", L(@"Remove background (people)", @"إزالة الخلفية (أشخاص)"), L(@"Keeps people only. Objects and animals are not supported.", @"بيسيب الأشخاص بس. الأشياء والحيوانات مش مدعومة."), @2 ] ];
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = L(@"Tools", @"أدوات");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.table = MakeTable(self); [self.view addSubview:self.table];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return 3; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"t"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"t"];
    NSArray *r = [self rows][ip.row];
    UIColor *col = @[ [UIColor systemBlueColor], [UIColor systemOrangeColor], [UIColor systemPinkColor] ][ip.row];
    [c setSymbol:r[0] color:col ring:-1]; c.title.text = r[1]; c.sub.text = r[2]; c.sub.numberOfLines = 2; c.pill.hidden = YES; c.more.hidden = YES; c.check.hidden = NO;
    c.check.image = Sym(IsAr() ? @"chevron.backward" : @"chevron.forward", 14, UIFontWeightBold); c.check.tintColor = UIColor.tertiaryLabelColor;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSInteger rw = ip.row;
    if (rw == 0) { PickFile(self, @[ @2, @3 ], ^(NSString *p) { ConvertMenu(self, p); }); }
    else if (rw == 1) { PickFile(self, @[ @2, @3 ], ^(NSString *p) { OpenRingtone(self, p); }); }
    else {
            UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [a addAction:[UIAlertAction actionWithTitle:T(@"From Photos") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { PickPhoto(self, NO, ^(UIImage *i, NSString *n) { ToolRemoveBG(self, i, n); }, nil); }]];
            [a addAction:[UIAlertAction actionWithTitle:L(@"From My Files", @"من ملفاتي") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { PickFile(self, @[ @1 ], ^(NSString *p) { RemoveBGPath(self, p); }); }]];
            [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
            a.popoverPresentationController.sourceView = self.view; a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - 40, 1, 1);
            [self presentViewController:a animated:YES completion:nil]; }
}
@end
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
    AddPull(self.table, self);
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
- (void)pullRefresh { [self.table reloadData]; [self reload]; EndPull(self.table); }
@end
#pragma mark - Trash (recycle bin)

static NSString *TrashDir(void) {
    NSString *p = [Docs() stringByAppendingPathComponent:@".FlowTrash"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static NSString *TrashIndexPath(void) { return [TrashDir() stringByAppendingPathComponent:@".index.plist"]; }
static NSMutableDictionary *TrashIndex(void) { return [NSMutableDictionary dictionaryWithContentsOfFile:TrashIndexPath()] ?: [NSMutableDictionary dictionary]; }
static void TrashSaveIndex(NSDictionary *d) { [d writeToFile:TrashIndexPath() atomically:YES]; }
// Items whose folder is missing or whose index entry is missing are dropped from the index only (never deletes user data).
static NSArray<NSDictionary *> *TrashItems(void) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableDictionary *idx = TrashIndex(); NSMutableArray *out = [NSMutableArray array]; BOOL changed = NO;
    for (NSString *k in idx.allKeys) {
        NSDictionary *e = idx[k]; NSString *name = e[@"name"]; if (![name isKindOfClass:NSString.class]) { [idx removeObjectForKey:k]; changed = YES; continue; }
        NSString *p = [[TrashDir() stringByAppendingPathComponent:k] stringByAppendingPathComponent:name];
        if (![fm fileExistsAtPath:p]) { [idx removeObjectForKey:k]; [fm removeItemAtPath:[TrashDir() stringByAppendingPathComponent:k] error:nil]; changed = YES; continue; }
        [out addObject:@{ @"id": k, @"name": name, @"path": p, @"orig": e[@"orig"] ?: @"", @"date": e[@"date"] ?: [NSDate date] }];
    }
    if (changed) TrashSaveIndex(idx);
    [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [b[@"date"] compare:a[@"date"]]; }];
    return out;
}
static int64_t TrashSize(void) { int64_t n = 0; for (NSDictionary *e in TrashItems()) n += SizeOf(e[@"path"]); return n; }
static BOOL TrashMove(NSString *path) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *k = NSUUID.UUID.UUIDString; NSString *box = [TrashDir() stringByAppendingPathComponent:k];
    [fm createDirectoryAtPath:box withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *dst = [box stringByAppendingPathComponent:path.lastPathComponent];
    if (![fm moveItemAtPath:path toPath:dst error:nil]) { [fm removeItemAtPath:box error:nil]; return NO; }
    NSString *rel = path.stringByDeletingLastPathComponent;
    rel = [rel hasPrefix:Docs()] ? [rel substringFromIndex:Docs().length] : @"";
    NSMutableDictionary *idx = TrashIndex();
    idx[k] = @{ @"name": path.lastPathComponent, @"orig": rel, @"date": [NSDate date] };
    TrashSaveIndex(idx);
    return YES;
}
static NSString *TrashRestore(NSDictionary *e) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [Docs() stringByAppendingString:e[@"orig"]]; BOOL isd = NO;
    if (![fm fileExistsAtPath:dir isDirectory:&isd] || !isd) dir = Docs();
    NSString *dst = UniquePath(dir, e[@"name"]);
    if (![fm moveItemAtPath:e[@"path"] toPath:dst error:nil]) return nil;
    NSMutableDictionary *idx = TrashIndex(); [idx removeObjectForKey:e[@"id"]]; TrashSaveIndex(idx);
    [fm removeItemAtPath:[TrashDir() stringByAppendingPathComponent:e[@"id"]] error:nil];
    return dst;
}
static void TrashPurge(NSDictionary *e) {
    NSMutableDictionary *idx = TrashIndex(); [idx removeObjectForKey:e[@"id"]]; TrashSaveIndex(idx);
    [NSFileManager.defaultManager removeItemAtPath:[TrashDir() stringByAppendingPathComponent:e[@"id"]] error:nil];
}
static void TrashAutoPurge(void) {
    if (![UD() boolForKey:@"trashauto"]) return;
    NSDate *lim = [NSDate dateWithTimeIntervalSinceNow:-30 * 86400];
    for (NSDictionary *e in TrashItems()) if ([e[@"date"] compare:lim] == NSOrderedAscending) TrashPurge(e);
}

@interface TrashVC : BaseVC <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UIView *empty;
@property(nonatomic, strong) NSArray<NSDictionary *> *items;
@end
@implementation TrashVC
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = L(@"Trash", @"سلة المحذوفات");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.table = MakeTable(self); [self.view addSubview:self.table];
    AddPull(self.table, self);
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
    self.empty = EmptyState(@"trash", L(@"Trash is empty", @"السلة فاضية"), L(@"Deleted files stay here until you remove them.", @"الملفات اللي بتحذفها بتفضل هنا لحد ما تمسحها."));
    [self.view addSubview:self.empty];
    [NSLayoutConstraint activateConstraints:@[ [self.empty.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [self.empty.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-20], [self.empty.widthAnchor constraintLessThanOrEqualToConstant:280] ]];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; TrashAutoPurge(); [self reload]; }
- (void)themeChanged { [super themeChanged]; [self.table reloadData]; }
- (void)reload {
    self.items = TrashItems(); self.empty.hidden = self.items.count > 0;
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:L(@"Empty Trash", @"فضّي السلة") style:UIBarButtonItemStylePlain target:self action:@selector(emptyAll)];
    b.tintColor = [UIColor systemRedColor]; self.navigationItem.rightBarButtonItem = self.items.count ? b : nil;
    [self.table reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil];
}
- (void)emptyAll {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Empty Trash?", @"تفضّي السلة؟") message:L(@"All items will be deleted forever. This cannot be undone.", @"كل العناصر هتتمسح نهائي. مينفعش التراجع.") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Empty Trash", @"فضّي السلة") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { for (NSDictionary *e in TrashItems()) TrashPurge(e); [self reload]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)restore:(NSDictionary *)e {
    if (!TrashRestore(e)) Alert(self, @"Could not complete that.", nil);
    [self reload];
}
- (void)purge:(NSDictionary *)e {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Delete forever?", @"تمسحه نهائي؟") message:L(@"This cannot be undone.", @"مينفعش التراجع عن ده.") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { TrashPurge(e); [self reload]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.items.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"tr"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tr"];
    NSDictionary *e = self.items[ip.row]; int k = KindOf(e[@"path"]);
    c.title.text = e[@"name"]; c.represent = e[@"path"];
    [c setSymbol:KindSymbol(k) color:KindColor(k) ring:-1];
    c.pill.hidden = YES; c.check.hidden = YES;
    NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterNoStyle;
    if (IsAr()) f.locale = [NSLocale localeWithLocaleIdentifier:@"ar_EG"];
    c.sub.text = [NSString stringWithFormat:@"%@  ·  %@ %@", FmtSize(SizeOf(e[@"path"])), L(@"Deleted", @"اتحذف"), [f stringFromDate:e[@"date"]]];
    c.more.hidden = NO;
    UIAction *r = [UIAction actionWithTitle:L(@"Restore", @"استرجاع") image:[UIImage systemImageNamed:@"arrow.uturn.backward"] identifier:nil handler:^(UIAction *x) { [self restore:e]; }];
    UIAction *d = [UIAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction *x) { [self purge:e]; }];
    d.attributes = UIMenuElementAttributesDestructive;
    c.more.menu = [UIMenu menuWithTitle:@"" children:@[ r, d ]]; c.more.showsMenuAsPrimaryAction = YES;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *e = self.items[ip.row];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:e[@"name"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Restore", @"استرجاع") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [self restore:e]; }]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { [self purge:e]; }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = self.view; a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - 40, 1, 1);
    [self presentViewController:a animated:YES completion:nil];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *e = self.items[ip.row];
    UIContextualAction *d = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:L(@"Delete forever", @"مسح نهائي") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) { [self purge:e]; h(YES); }];
    return [UISwipeActionsConfiguration configurationWithActions:@[ d ]];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *e = self.items[ip.row];
    UIContextualAction *r = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:L(@"Restore", @"استرجاع") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) { [self restore:e]; h(YES); }];
    r.backgroundColor = [UIColor systemGreenColor];
    return [UISwipeActionsConfiguration configurationWithActions:@[ r ]];
}
- (void)pullRefresh { TrashAutoPurge(); [self reload]; EndPull(self.table); }
@end
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
        NSArray *opts = @[ @[ L(@"Date added, oldest first", @"تاريخ الإضافة، الأقدم الأول"), @3, @"calendar" ], @[ L(@"Date added, newest first", @"تاريخ الإضافة، الأحدث الأول"), @1, @"calendar" ], @[ L(@"Name, A to Z", @"الاسم، من أ إلى ي"), @0, @"textformat" ], @[ L(@"Name, Z to A", @"الاسم، من ي إلى أ"), @4, @"textformat" ], @[ L(@"Size, largest first", @"الحجم، الأكبر الأول"), @2, @"arrow.up.arrow.down" ], @[ L(@"Size, smallest first", @"الحجم، الأصغر الأول"), @5, @"arrow.up.arrow.down" ] ];
        for (NSArray *o in opts) { NSInteger v = [o[1] integerValue]; [rows addObject:CheckRow(o[2], Theme.accent, o[0], v == sort, ^{ [UD() setInteger:v forKey:@"sortby"]; [wp rebuild]; })]; }
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
#pragma mark - Mini player bar (shown above the tab bar while a minimized player keeps playing)
static GlassView *gMiniBar; static UIButton *gMiniPlay; static UIImageView *gMiniIc;
static void MiniRefresh(void) {
    if (!gMiniBar || !gActivePlayer) return;
    BOOL playing = gActivePlayer.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    UIImage *cov = gActivePlayer.art.image;
    if (cov && gMiniIc) { gMiniIc.image = cov; gMiniIc.contentMode = UIViewContentModeScaleAspectFill; gMiniIc.clipsToBounds = YES; gMiniIc.layer.cornerRadius = 8; gMiniIc.tintColor = nil; }
    SetBtnContent(gMiniPlay, Sym(playing ? @"pause.fill" : @"play.fill", 19, UIFontWeightBold), nil, UIColor.whiteColor, 16, 21);
}
static FlowTabs *MiniHost(void);
static void MiniInset(CGFloat b) {
    FlowTabs *h = MiniHost(); if (!h) return;
    for (UIViewController *vc in h.viewControllers) { UIEdgeInsets i = vc.additionalSafeAreaInsets; if (i.bottom != b) { i.bottom = b; vc.additionalSafeAreaInsets = i; } }
}
static void MiniHide(void) { [gMiniBar removeFromSuperview]; gMiniBar = nil; gMiniPlay = nil; gMiniIc = nil; MiniInset(0); }
static FlowTabs *MiniHost(void) {
    for (UIWindow *w in UIApplication.sharedApplication.windows) if ([w.rootViewController isKindOfClass:FlowTabs.class]) return (FlowTabs *)w.rootViewController;
    return nil;
}
static void MiniShow(PlayerVC *p) {
    FlowTabs *ft = MiniHost(); if (!ft || !p) return;
    MiniHide();
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 24; gMiniBar = g;
    [ft.view addSubview:g];
    UIButton *open = [UIButton buttonWithType:UIButtonTypeCustom]; open.translatesAutoresizingMaskIntoConstraints = NO;
    [open addAction:[UIAction actionWithHandler:^(UIAction *a) {
        PlayerVC *pv = gActivePlayer; FlowTabs *h = MiniHost(); if (!pv || !h) return;
        UIViewController *top = h; while (top.presentedViewController) top = top.presentedViewController;
        if ([top isKindOfClass:PlayerVC.class]) return;
        pv.modalPresentationStyle = UIModalPresentationFullScreen; [top presentViewController:pv animated:YES completion:nil];
    }] forControlEvents:UIControlEventTouchUpInside];
    UIImageView *ic = [[UIImageView alloc] initWithImage:Sym(p.audio ? @"music.note" : @"film", 18, UIFontWeightSemibold)]; ic.tintColor = Theme.accent; ic.contentMode = UIViewContentModeCenter; ic.translatesAutoresizingMaskIntoConstraints = NO; ic.userInteractionEnabled = NO; gMiniIc = ic;
    UILabel *t = Label(CleanTitle(p.path.lastPathComponent.stringByDeletingPathExtension), 14, UIFontWeightBold, UIColor.whiteColor); t.lineBreakMode = NSLineBreakByTruncatingTail; t.userInteractionEnabled = NO;
    UIButton *pl = [UIButton buttonWithType:UIButtonTypeCustom]; pl.translatesAutoresizingMaskIntoConstraints = NO; gMiniPlay = pl;
    [pl addAction:[UIAction actionWithHandler:^(UIAction *a) { [gActivePlayer togglePlay]; MiniRefresh(); }] forControlEvents:UIControlEventTouchUpInside];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom]; x.translatesAutoresizingMaskIntoConstraints = NO;
    SetBtnContent(x, Sym(@"xmark", 15, UIFontWeightBold), nil, [UIColor colorWithWhite:1 alpha:0.75], 16, 17);
    [x addAction:[UIAction actionWithHandler:^(UIAction *a) { [gActivePlayer fullStop]; }] forControlEvents:UIControlEventTouchUpInside];
    for (UIView *v in @[ open, ic, t, pl, x ]) [g.content addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [g.leadingAnchor constraintEqualToAnchor:ft.view.leadingAnchor constant:18], [g.trailingAnchor constraintEqualToAnchor:ft.view.trailingAnchor constant:-18],
        [g.bottomAnchor constraintEqualToAnchor:ft.bar.topAnchor constant:-8], [g.heightAnchor constraintEqualToConstant:56],
        [open.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor], [open.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor], [open.topAnchor constraintEqualToAnchor:g.content.topAnchor], [open.bottomAnchor constraintEqualToAnchor:g.content.bottomAnchor],
        [ic.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:14], [ic.centerYAnchor constraintEqualToAnchor:g.content.centerYAnchor], [ic.widthAnchor constraintEqualToConstant:38], [ic.heightAnchor constraintEqualToConstant:38],
        [x.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-6], [x.centerYAnchor constraintEqualToAnchor:g.content.centerYAnchor], [x.widthAnchor constraintEqualToConstant:44], [x.heightAnchor constraintEqualToConstant:44],
        [pl.trailingAnchor constraintEqualToAnchor:x.leadingAnchor], [pl.centerYAnchor constraintEqualToAnchor:g.content.centerYAnchor], [pl.widthAnchor constraintEqualToConstant:44], [pl.heightAnchor constraintEqualToConstant:44],
        [t.leadingAnchor constraintEqualToAnchor:ic.trailingAnchor constant:8], [t.trailingAnchor constraintEqualToAnchor:pl.leadingAnchor constant:-6], [t.centerYAnchor constraintEqualToAnchor:g.content.centerYAnchor] ]];
    MiniInset(64); [ft.view layoutIfNeeded];
    MiniRefresh();
}


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
    gMiniBar = nil; gMiniPlay = nil; gMiniIc = nil;
    if (gActivePlayer && gActivePlayer.minimized) MiniShow(gActivePlayer);
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
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window { return gOrient; }
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
